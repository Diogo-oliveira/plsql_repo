/*-- Last Change Revision: $Rev: 2027557 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_protocol IS

    /**
    *  Convert date strings to date format
    *
    * @param C_DATE                     String of date
    *
    * @return     DATE
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION convert_to_date(c_date VARCHAR2) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_date TIMESTAMP WITH TIME ZONE;
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
    * @param C_PROTOCOL                     ID of protocol
    * @param C_PROTOCOL_CRITERIA_TYPE       Criteria Type
    *
    * @return     PIPELINED type t_coll_protocol_generic
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_other_criteria
    (
        c_protocol               protocol.id_protocol%TYPE,
        c_protocol_criteria_type protocol_criteria.criteria_type%TYPE
    ) RETURN t_coll_protocol_generic
        PIPELINED IS
        rec_out t_rec_protocol_generic;
    
    BEGIN
    
        FOR rec IN c_generic_link(c_protocol, c_protocol_criteria_type)
        LOOP
            rec_out := t_rec_protocol_generic(rec.id_protocol_criteria_link,
                                              rec.id_link_other_criteria,
                                              rec.id_link_other_criteria_type);
            PIPE ROW(rec_out);
        END LOOP;
    
        RETURN;
    END get_other_criteria;

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
        i_task_type IN protocol_action_category.task_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_results PLS_INTEGER;
        l_market        market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
    BEGIN
    
        g_error := 'CHECK TASK TYPE SOFT INST';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- verify if the type of task is available for this software and institution
        SELECT COUNT(1)
          INTO l_count_results
          FROM (SELECT flg_available
                  FROM (SELECT flg_available
                          FROM protocol_item_soft_inst
                         WHERE id_institution IN (g_all_institution, i_prof.institution)
                           AND id_software IN (g_all_software, i_prof.software)
                           AND id_market IN (g_all_markets, l_market)
                           AND flg_item_type = g_protocol_item_tasks
                           AND item = i_task_type
                         ORDER BY id_institution DESC, id_software DESC, flg_available)
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
    *  Check permissions of a task type
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE  Task type to check permissions
    *
    * @return     BOOLEAN
    * @author     Tiago Silva
    * @version    1.0
    * @since      2009/09/30
    */
    FUNCTION check_task_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN protocol_action_category.task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_count_results PLS_INTEGER;
    BEGIN
    
        g_error := 'CHECK TASK TYPE PERMISSIONS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT COUNT(1)
          INTO l_count_results
          FROM (SELECT first_value(prot_ac.flg_available) over(PARTITION BY prot_ac.id_action ORDER BY(prot_ac.id_profile_template + prot_ac.task_type) DESC, prot_ac.flg_available) AS flg_avail
                  FROM protocol_action_category prot_ac, action act
                 WHERE prot_ac.id_category = (SELECT pc.id_category
                                                FROM prof_cat pc
                                               WHERE pc.id_professional = i_prof.id
                                                 AND pc.id_institution = i_prof.institution)
                   AND prot_ac.id_profile_template IN (SELECT ppt.id_profile_template
                                                         FROM prof_profile_template ppt
                                                        WHERE ppt.id_professional = i_prof.id
                                                          AND ppt.id_institution = i_prof.institution
                                                          AND ppt.id_software = i_prof.software
                                                       UNION ALL
                                                       SELECT g_all_profile_template AS id_profile_template
                                                         FROM dual)
                   AND prot_ac.task_type IN (i_task_type, g_all_tasks)
                   AND prot_ac.id_action = act.id_action
                   AND act.subject = g_action_protocol_tasks)
         WHERE flg_avail = g_available;
    
        -- check result        
        IF (l_count_results = 0)
        THEN
            RETURN g_not_available;
        END IF;
    
        RETURN g_available;
    
    END check_task_permissions;

    /**
    *  Returns string with specific link type content separated by defined separator
    *
    * @param I_LANG                 Language
    * @param I_PROF                 Professional structure
    * @param I_ID_PROTOCOL         protocol
    * @param I_LINK_TYPE            Type of Link
    * @param I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_link_id_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_link_type   IN protocol_link.link_type%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT id_protocol,
                   id_protocol_link,
                   id_link,
                   decode(link_type,
                          g_protocol_link_pathol,
                          pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_diagnosis => id_link,
                                                     i_code         => code,
                                                     i_flg_other    => flag,
                                                     i_flg_std_diag => pk_alert_constant.g_yes),
                          g_protocol_link_envi,
                          pk_translation.get_translation(i_lang, code),
                          g_protocol_link_prof,
                          pk_translation.get_translation(i_lang, code),
                          g_protocol_link_spec,
                          decode(i_prof.software,
                                 pk_alert_constant.g_soft_primary_care,
                                 pk_translation.get_translation(i_lang, code),
                                 pk_translation.get_translation(i_lang, code)),
                          g_protocol_link_type,
                          pk_translation.get_translation(i_lang, code),
                          g_protocol_link_edit_prof,
                          pk_translation.get_translation(i_lang, code),
                          g_protocol_link_chief_compl,
                          pk_translation.get_translation(i_lang, code),
                          g_unknown_link_type) AS str_desc
              FROM (
                    -- PROT_TYPE              
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            prot_typ.code_protocol_type AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN protocol_type prot_typ
                        ON prot_typ.id_protocol_type = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND g_protocol_link_type = i_link_type
                    UNION ALL
                    -- DIAGNOSIS
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            diag.code_icd             AS code,
                            diag.flg_other            AS flag
                      FROM protocol_link prot_lnk
                      JOIN diagnosis diag
                        ON diag.id_diagnosis = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND g_protocol_link_pathol = i_link_type
                    UNION ALL
                    -- CATEGORY
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            prof.code_category AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN category prof
                        ON prof.id_category = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND g_protocol_link_prof = i_link_type
                    UNION ALL
                    -- DEPT
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            env.code_dept AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN dept env
                        ON env.id_dept = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND env.id_institution = i_prof.institution
                       AND g_protocol_link_envi = i_link_type
                    UNION ALL
                    -- SPECIALITY
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            spec.code_speciality AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN speciality spec
                        ON spec.id_speciality = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND i_prof.software != pk_alert_constant.g_soft_primary_care
                       AND g_protocol_link_spec = i_link_type
                    UNION ALL
                    -- CLINICAL SERVICE
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            cs.code_clinical_service AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND i_prof.software = pk_alert_constant.g_soft_primary_care
                       AND g_protocol_link_spec = i_link_type
                    UNION ALL
                    -- COMPLAINT
                    SELECT prot_lnk.id_protocol,
                            prot_lnk.id_protocol_link,
                            prot_lnk.id_link,
                            prot_lnk.link_type,
                            c.code_complaint AS code,
                            '' AS flag
                      FROM protocol_link prot_lnk
                      JOIN complaint c
                        ON c.id_complaint = prot_lnk.id_link
                     WHERE prot_lnk.id_protocol = i_id_protocol
                       AND prot_lnk.link_type = i_link_type
                       AND g_protocol_link_chief_compl = i_link_type)
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
    *  Returns string with the details of an item (protocol task or criteria) 
    *  between brackets and separated by defined separator
    *
    * @param  I_LANG          Language
    * @param  I_PROF          Professional structure
    * @param  I_TYPE_ITEM     Type of the protocol item (C)riteria or (T)ask
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
        i_type_item IN protocol_adv_input_value.flg_type%TYPE,
        i_id_item   IN protocol_adv_input_value.id_adv_input_link%TYPE,
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
              FROM (SELECT prot_adv_input_val.id_advanced_input_field,
                           pk_translation.get_translation(i_lang, aif.code_advanced_input_field) AS field_desc,
                           decode(prot_adv_input_val.value_type,
                                  g_protocol_n_type,
                                  to_char(prot_adv_input_val.nvalue),
                                  g_protocol_d_type,
                                  to_char(prot_adv_input_val.dvalue),
                                  g_protocol_v_type,
                                  to_char(prot_adv_input_val.vvalue)) AS field_value
                      FROM protocol_adv_input_value prot_adv_input_val, advanced_input_field aif
                     WHERE prot_adv_input_val.flg_type = i_type_item
                       AND prot_adv_input_val.id_adv_input_link = i_id_item
                       AND prot_adv_input_val.id_advanced_input_field = aif.id_advanced_input_field
                       AND decode(prot_adv_input_val.value_type,
                                  g_protocol_n_type,
                                  to_char(prot_adv_input_val.nvalue),
                                  g_protocol_d_type,
                                  to_char(prot_adv_input_val.dvalue),
                                  g_protocol_v_type,
                                  prot_adv_input_val.vvalue) != to_char(g_detail_any)) field,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_adv_input_freq
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available) freq,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_allergy_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                       AND val NOT IN (pk_problems.g_pat_probl_cancel)) allergy_status,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND code_domain = g_domain_allergy_type) allergy_type,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_nature
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available) diagnosis_nature,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                       AND val NOT IN (g_pat_probl_not_capable, pk_problems.g_pat_probl_cancel)) diagnosis_status,
                   
                   (SELECT val AS data, desc_val AS label
                      FROM sys_domain
                     WHERE code_domain = g_domain_nurse_diag_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND val IN (g_nurse_active, g_nurse_solved)
                       AND flg_available = g_available) nurse_diag_status
            
             WHERE field.field_value = field.field_value
               AND field.field_value = freq.data(+)
               AND field.field_value = allergy_status.data(+)
               AND field.field_value = allergy_type.data(+)
               AND field.field_value = diagnosis_nature.data(+)
               AND field.field_value = diagnosis_status.data(+)
               AND field.field_value = nurse_diag_status.data(+);
    
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
    * @param  I_ID_PROTOCOL                Protocol
    * @param  I_CRIT_TYPE                  Type of Criteria: Inclusion or Exclusion
    * @param  I_ID_CRIT_OTHER_TYPE         ID of other type of criteria
    * @param  I_BULLET                     Bullet for the criteria list
    * @param  I_SEPARATOR                  Separator between criteria
    * @param  I_FLG_DETAILS                Define if details should appear    
    * @param  I_ID_LINK_OTHER_CRITERIA     ID of other criteria
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_criteria_link_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_protocol            IN protocol.id_protocol%TYPE,
        i_crit_type              IN protocol_criteria.criteria_type%TYPE,
        i_id_crit_other_type     IN protocol_criteria_link.id_link_other_criteria_type%TYPE,
        i_bullet                 IN VARCHAR2,
        i_separator              IN VARCHAR2,
        i_flg_details            IN VARCHAR2,
        i_id_link_other_criteria IN protocol_criteria_link.id_link_other_criteria%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT prot.id_protocol,
                   prot_crit.id_protocol_criteria,
                   prot_crit_lnk.id_protocol_criteria_link,
                   decode(prot_crit_lnk.id_link_other_criteria_type,
                          g_protocol_allergies,
                          pk_translation.get_translation(i_lang, alerg.code_allergy),
                          g_protocol_analysis,
                          pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', asys.code_analysis, NULL),
                          g_protocol_diagnosis,
                          pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_id_diagnosis => diag.id_diagnosis,
                                                     i_code         => diag.code_icd,
                                                     i_flg_other    => diag.flg_other,
                                                     i_flg_std_diag => pk_alert_constant.g_yes),
                          g_protocol_exams,
                          pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam),
                          g_protocol_drug,
                          g_protocol_other_exams,
                          pk_exams_api_db.get_alias_translation(i_lang, i_prof, exother.code_exam),
                          g_protocol_diagnosis_nurse,
                          pk_translation.get_translation(i_lang, ic.code_icnp_composition),
                          g_unknown_link_type) AS str_desc
              FROM protocol               prot,
                   protocol_criteria      prot_crit,
                   protocol_criteria_link prot_crit_lnk,
                   --
                   allergy          alerg,
                   analysis         asys,
                   diagnosis        diag,
                   exam             ex,
                   exam             exother,
                   icnp_composition ic
             WHERE prot.id_protocol = i_id_protocol
               AND prot.id_protocol = prot_crit.id_protocol
               AND prot_crit.criteria_type = i_crit_type
               AND prot_crit.id_protocol_criteria = prot_crit_lnk.id_protocol_criteria
               AND prot_crit_lnk.id_link_other_criteria =
                   nvl(i_id_link_other_criteria, prot_crit_lnk.id_link_other_criteria)
               AND prot_crit_lnk.id_link_other_criteria_type = i_id_crit_other_type
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = alerg.id_allergy(+)
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = asys.id_analysis(+)
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = diag.id_diagnosis(+)
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = ex.id_exam(+)
               AND ex.flg_type(+) = g_exam_only_img
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(prot_crit_lnk.id_link_other_criteria) = ic.id_composition(+)
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
                                                           rec.id_protocol_criteria_link,
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
    * Returns string with specific task ID content
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_TYPE            Type of task
    * @param  I_TASK_CODIFICATION    Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_task_id_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task           IN protocol_task.id_task_link%TYPE,
        i_task_type         IN protocol_task.task_type%TYPE,
        i_task_codification IN protocol_task.task_codification%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT i_id_task,
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
                          decode(prot_task.column_value,
                                 -1,
                                 pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                                 pk_translation.get_translation(i_lang, appoint.code_clinical_service)),
                          -- Patient education       
                          g_task_patient_education,
                          CASE prot_task.column_value
                              WHEN '-1' THEN
                               NULL --prot_proc_task.task_notes,
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.column_value)
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
              FROM TABLE(table_varchar(i_id_task)) prot_task,
                   analysis asys, -- Analises
                   (SELECT dcs.id_dep_clin_serv, cs.id_clinical_service, cs.code_clinical_service
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE cs.id_clinical_service = dcs.id_clinical_service) appoint,
                   --icnp_composition enf, -- Ensinos de enfermagem
                   exam             img, -- Imagem
                   vaccine          vac, -- Imunizações
                   icnp_composition enfint, --Intervenções de enfermagem
                   exam             exother, -- Outros exames
                   speciality       par, -- Pareceres
                   intervention     interv, -- Procedimentos                  
                   vital_sign       monit_vs -- Monitorizacoes
             WHERE prot_task.column_value = i_id_task
               AND safe_to_number(prot_task.column_value) = asys.id_analysis(+)
               AND safe_to_number(prot_task.column_value) = appoint.id_dep_clin_serv(+)
               AND safe_to_number(prot_task.column_value) = img.id_exam(+)
               AND img.flg_type(+) = g_exam_only_img
               AND safe_to_number(prot_task.column_value) = vac.id_vaccine(+)
               AND safe_to_number(prot_task.column_value) = enfint.id_composition(+)
               AND safe_to_number(prot_task.column_value) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(prot_task.column_value) = par.id_speciality(+)
               AND safe_to_number(prot_task.column_value) = interv.id_intervention(+)
               AND safe_to_number(prot_task.column_value) = monit_vs.id_vital_sign(+)
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
    *  Returns string with specifictask content separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_element_type         Type of task
    * @param  I_SEPARATOR            Separator between diferent elements of string
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_CODIFICATION    Task codification    
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_task_id_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_task_type         IN protocol_task.task_type%TYPE,
        i_separator         IN VARCHAR2,
        i_id_task           IN protocol_task.id_task_link%TYPE DEFAULT NULL,
        i_task_codification IN protocol_task.task_codification%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT prot_elem.id_protocol,
                   prot_task.id_protocol_task,
                   decode(prot_task.task_type,
                          -- Analysis
                          g_task_analysis,
                          pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', asys.code_analysis, NULL) ||
                          -- analysis codification              
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM analysis_codification ac, codification c
                             WHERE prot_task.task_codification IS NOT NULL
                               AND ac.id_analysis_codification = prot_task.task_codification
                               AND ac.id_codification = c.id_codification),
                          -- Appointments     
                          g_task_appoint,
                          decode(prot_task.id_task_link,
                                 '-1',
                                 pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                                 pk_translation.get_translation(i_lang, appoint.code_clinical_service)),
                          -- Patient education
                          g_task_patient_education,
                          CASE prot_task.id_task_link
                              WHEN '-1' THEN
                               prot_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.id_task_link)
                          END,
                          -- Image
                          g_task_img,
                          pk_exams_api_db.get_alias_translation(i_lang, i_prof, img.code_exam) ||
                          -- image exam codification              
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM exam_codification ec, codification c
                             WHERE prot_task.task_codification IS NOT NULL
                               AND ec.id_exam_codification = prot_task.task_codification
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
                             WHERE prot_task.task_codification IS NOT NULL
                               AND ec.id_exam_codification = prot_task.task_codification
                               AND ec.id_codification = c.id_codification),
                          g_task_spec,
                          pk_translation.get_translation(i_lang, par.code_speciality) ||
                          decode(prot_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach),
                                      ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach) || ')',
                                      NULL)),
                          -- Procedure
                          g_task_proc,
                          pk_procedures_api_db.get_alias_translation(i_lang, i_prof, interv.code_intervention, NULL) ||
                          -- procedure codification
                           (SELECT ' (' || pk_translation.get_translation(i_lang, c.code_codification) || ')'
                              FROM interv_codification ec, codification c
                             WHERE prot_task.task_codification IS NOT NULL
                               AND ec.id_interv_codification = prot_task.task_codification
                               AND ec.id_codification = c.id_codification),
                          -- Monitoring
                          g_task_monitorization,
                          pk_translation.get_translation(i_lang, monit_vs.code_vital_sign),
                          g_unknown_link_type) AS str_desc
              FROM protocol_task    prot_task,
                   protocol_element prot_elem,
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
             WHERE prot_elem.id_protocol = i_id_protocol
               AND prot_elem.id_element = prot_task.id_group_task
               AND prot_task.task_type = i_task_type
               AND prot_task.id_task_link = nvl(i_id_task, prot_task.id_task_link)
               AND nvl(prot_task.task_codification, -1) =
                   nvl(i_task_codification, nvl(prot_task.task_codification, -1))
               AND safe_to_number(prot_task.id_task_link) = asys.id_analysis(+)
               AND safe_to_number(prot_task.id_task_link) = appoint.id_dep_clin_serv(+)
               AND safe_to_number(prot_task.id_task_link) = img.id_exam(+)
               AND img.flg_type(+) = g_exam_only_img
               AND safe_to_number(prot_task.id_task_link) = vac.id_vaccine(+)
               AND safe_to_number(prot_task.id_task_link) = enfint.id_composition(+)
               AND safe_to_number(prot_task.id_task_link) = exother.id_exam(+)
               AND exother.flg_type(+) != g_exam_only_img
               AND safe_to_number(prot_task.id_task_link) = par.id_speciality(+)
               AND safe_to_number(prot_task.id_task_link) = interv.id_intervention(+)
               AND safe_to_number(prot_task.id_task_link) = monit_vs.id_vital_sign(+)
               AND i_task_type NOT IN (g_task_drug_ext, g_task_drug);
    
        l_return_desc VARCHAR2(4000);
    BEGIN
        FOR rec IN c_get_descriptions
        LOOP
            l_return_desc := l_return_desc || rec.str_desc || i_separator;
        END LOOP;
    
        l_return_desc := substr(l_return_desc, 1, length(l_return_desc) - length(i_separator));
        RETURN l_return_desc;
    END get_task_id_str;

    /**
    *  Returns string with picture name separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_image_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT img_desc AS str_desc
              FROM protocol_context_image prot_ctx_img
             WHERE prot_ctx_img.id_protocol = i_id_protocol
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
    *  returns string with author of a specified protocol
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_context_author_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_author IS
            SELECT first_name || ' ' || last_name || g_separator || title AS str_desc
              FROM protocol_context_author prot_ctx_auth
             WHERE prot_ctx_auth.id_protocol = i_id_protocol;
    
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
    *  returns string with specific criteria_type
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_CRITERIA_TYPE     Criteria type ID
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_criteria_type_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_criteria_type IN protocol_criteria_type.id_protocol_criteria_type%TYPE
    ) RETURN VARCHAR2 IS
    
        CURSOR c_get_descriptions IS
            SELECT pk_translation.get_translation(i_lang, code_protocol_criteria_type) AS str_desc
              FROM protocol_criteria_type
             WHERE id_protocol_criteria_type = i_id_criteria_type;
    
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
    * Function. returns sequence ID for protocol
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_seq;

    -- protocol Criteria
    /**
    * Function. returns sequence ID for protocol criteria
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_criteria_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_criteria.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_criteria_seq;

    -- protocol_link
    /**
    * Function. returns sequence ID for protocol link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_link_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_link.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_link_seq;

    -- protocol criteria link
    /**
    * Function. returns sequence ID for protocol criteria link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_crit_lnk_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_criteria_link.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_crit_lnk_seq;

    -- Task Link
    /**
    * Function. returns sequence ID for protocol task link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_id_protocol_element_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_element.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_id_protocol_element_seq;
    /**
    * Function. returns sequence ID for protocol task ID
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_id_protocol_task_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_task.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_id_protocol_task_seq;
    -- Task Link
    /**
    * Function. returns sequence ID for protocol relation
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_relation_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_relation.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_relation_seq;
    /**
    * Function. returns sequence ID for protocol connector
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_connector_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_connector.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_connector_seq;

    /**
    * Function. returns sequence ID for protocol element ID
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_id_element_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_element_elem.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_id_element_seq;

    /**
    * Function. returns sequence ID for protocol author
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_ctx_author_seq RETURN NUMBER IS
    
        l_seq_num NUMBER;
    BEGIN
        SELECT seq_protocol_context_author.nextval
          INTO l_seq_num
          FROM dual;
    
        RETURN l_seq_num;
    END get_protocol_ctx_author_seq;

    /**
    *  Create specific protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               Object (ID of professional, ID of institution, ID of software)
    * @param      I_DUPLICATE_FLG              Duplicate protocol (Y/N)
    
    * @param      O_ID_PROTOCOL               identifier of protocol created
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION create_protocol
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        i_duplicate_flg IN VARCHAR2,
        ---
        o_id_protocol OUT protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_protocol              protocol%ROWTYPE;
        l_protocol_criteria_inc protocol_criteria%ROWTYPE;
        l_protocol_criteria_exc protocol_criteria%ROWTYPE;
    
        TYPE t_protocol_criteria_link IS TABLE OF protocol_criteria_link%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_crit_link_inc t_protocol_criteria_link;
        ibt_protocol_crit_link_exc t_protocol_criteria_link;
    
        TYPE t_protocol_link IS TABLE OF protocol_link%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_link t_protocol_link;
    
        TYPE t_protocol_context_image IS TABLE OF protocol_context_image%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_context_image t_protocol_context_image;
    
        TYPE t_protocol_context_author IS TABLE OF protocol_context_author%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_context_author t_protocol_context_author;
    
        TYPE t_protocol_adv_input_value IS TABLE OF protocol_adv_input_value%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_adv_input_value t_protocol_adv_input_value;
    
        -- connectors part
        TYPE t_protocol_element IS TABLE OF protocol_element%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_element t_protocol_element;
    
        TYPE t_protocol_relation IS TABLE OF protocol_relation%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_relation t_protocol_relation;
    
        TYPE t_protocol_connector IS TABLE OF protocol_connector%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_connector t_protocol_connector;
    
        TYPE t_protocol_text IS TABLE OF protocol_text%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_text t_protocol_text;
    
        TYPE t_protocol_question IS TABLE OF protocol_question%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_question t_protocol_question;
    
        TYPE t_protocol_task IS TABLE OF protocol_task%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_task t_protocol_task;
    
        TYPE t_protocol_protocol IS TABLE OF protocol_protocol%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_protocol t_protocol_protocol;
    
        ----------------
        flg_new BOOLEAN := FALSE;
    
        CURSOR c_protocol(in_id_protocol NUMBER) IS
            SELECT *
              FROM protocol
             WHERE id_protocol = in_id_protocol;
    
        CURSOR c_protocol_criteria
        (
            in_id_protocol   NUMBER,
            in_criteria_type VARCHAR2
        ) IS
            SELECT *
              FROM protocol_criteria
             WHERE id_protocol = in_id_protocol
               AND criteria_type = in_criteria_type;
    
        -----------------
    
        CURSOR c_protocol_link
        (
            in_id_protocol     NUMBER,
            in_id_protocol_new NUMBER
        ) IS
            SELECT seq_protocol_link.nextval AS id_protocol_link, in_id_protocol_new AS id_protocol, id_link, link_type
              FROM protocol_link
             WHERE id_protocol = in_id_protocol;
    
        CURSOR c_protocol_criteria_link
        (
            in_id_protocol          NUMBER,
            in_id_protocol_crit_new NUMBER,
            in_criteria_type        protocol_criteria.criteria_type%TYPE
        ) IS
            SELECT seq_protocol_criteria_link.nextval AS id_protocol_criteria_link_new,
                   a.id_protocol_criteria_link        AS id_protocol_criteria_link,
                   in_id_protocol_crit_new            AS id_protocol_criteria,
                   --a.ID_PROTOCOL_CRITERIA,
                   a.id_link_other_criteria,
                   a.id_link_other_criteria_type
              FROM protocol_criteria_link a, protocol_criteria b
             WHERE b.id_protocol = in_id_protocol
               AND a.id_protocol_criteria = b.id_protocol_criteria
               AND b.criteria_type = in_criteria_type;
        l_protocol_criteria_link_inc c_protocol_criteria_link%ROWTYPE;
        l_protocol_criteria_link_exc c_protocol_criteria_link%ROWTYPE;
    
        CURSOR c_protocol_context_image
        (
            in_id_protocol     NUMBER,
            in_id_protocol_new NUMBER
        ) IS
            SELECT seq_protocol_context_image.nextval AS id_protocol_context_image,
                   in_id_protocol_new                 AS id_protocol,
                   file_name,
                   img_desc,
                   dt_img,
                   img,
                   img_thumbnail,
                   flg_status
              FROM protocol_context_image
             WHERE id_protocol = in_id_protocol;
    
        CURSOR c_protocol_context_author
        (
            in_id_protocol     NUMBER,
            in_id_protocol_new NUMBER
        ) IS
            SELECT seq_protocol_context_author.nextval AS id_protocol_context_author,
                   in_id_protocol_new                  AS id_protocol,
                   first_name,
                   last_name,
                   title
              FROM protocol_context_author prot_ctx_auth
             WHERE prot_ctx_auth.id_protocol = in_id_protocol;
    
        CURSOR c_protocol_adv_input_value
        (
            in_flg_type              VARCHAR2,
            in_id_adv_input_link     NUMBER,
            in_id_adv_input_link_new NUMBER
        ) IS
            SELECT seq_protocol_adv_input_value.nextval AS id_protocol_adv_input_value,
                   in_id_adv_input_link_new             AS id_adv_input_link,
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
              FROM protocol_adv_input_value
             WHERE flg_type = in_flg_type
               AND id_adv_input_link = in_id_adv_input_link;
    
        --l_PROTOCOL_adv_input_value c_PROTOCOL_adv_input_value%ROWTYPE;
    
        -----------------
        CURSOR c_protocol_relation
        (
            in_id_protocol     NUMBER,
            in_id_protocol_new NUMBER
        ) IS
            SELECT seq_protocol_relation.nextval  AS id_protocol_relation_new,
                   id_protocol_relation,
                   in_id_protocol_new             AS id_protocol_new,
                   in_id_protocol                 AS id_protocol,
                   id_protocol_element_parent,
                   seq_protocol_connector.nextval AS id_protocol_connector_new,
                   id_protocol_connector,
                   id_protocol_element,
                   desc_relation,
                   flg_available
              FROM protocol_relation
             WHERE id_protocol = in_id_protocol;
        l_protocol_relation c_protocol_relation%ROWTYPE;
    
        CURSOR c_protocol_element
        (
            in_id_protocol     NUMBER,
            in_id_protocol_new NUMBER
        ) IS
            SELECT get_id_protocol_element_seq       AS id_protocol_element_new,
                   id_protocol_element,
                   in_id_protocol_new                AS id_protocol_new,
                   id_protocol,
                   seq_protocol_element_elem.nextval AS id_element_new,
                   id_element,
                   element_type,
                   desc_element,
                   x_coordinate,
                   y_coordinate,
                   flg_available
              FROM protocol_element
             WHERE id_protocol = in_id_protocol;
        l_protocol_element c_protocol_element%ROWTYPE;
    
        CURSOR c_protocol_connector
        (
            in_id_protocol_connector     NUMBER,
            in_id_protocol_connector_new NUMBER
        ) IS
            SELECT in_id_protocol_connector_new AS id_protocol_connector_new,
                   id_protocol_connector,
                   desc_protocol_connector,
                   flg_desc_protocol_connector,
                   flg_available
              FROM protocol_connector
             WHERE id_protocol_connector = in_id_protocol_connector;
        l_protocol_connector c_protocol_connector%ROWTYPE;
    
        CURSOR c_protocol_task
        (
            in_id_group_task NUMBER,
            id_element_new   NUMBER
        ) IS
            SELECT seq_protocol_task.nextval AS id_protocol_task_new,
                   id_protocol_task,
                   id_element_new            AS id_group_task_new,
                   id_group_task,
                   desc_protocol_task,
                   id_task_link,
                   task_type,
                   task_notes,
                   id_task_attach,
                   task_codification
              FROM protocol_task
             WHERE id_group_task = in_id_group_task;
        l_protocol_task c_protocol_task%ROWTYPE;
    
        CURSOR c_protocol_question
        (
            in_id_protocol_question NUMBER,
            id_element_new          NUMBER
        ) IS
            SELECT id_element_new AS id_protocol_question_new, id_protocol_question, desc_protocol_question
              FROM protocol_question
             WHERE id_protocol_question = in_id_protocol_question;
        l_protocol_question c_protocol_question%ROWTYPE;
    
        CURSOR c_protocol_text
        (
            in_id_protocol_text NUMBER,
            id_element_new      NUMBER
        ) IS
            SELECT id_element_new AS id_protocol_text_new, id_protocol_text, desc_protocol_text, protocol_text_type
              FROM protocol_text
             WHERE id_protocol_text = in_id_protocol_text;
        l_protocol_text c_protocol_text%ROWTYPE;
    
        CURSOR c_protocol_protocol
        (
            in_id_protocol_protocol NUMBER,
            id_element_new          NUMBER
        ) IS
            SELECT id_element_new AS id_protocol_protocol_new,
                   id_protocol_protocol,
                   desc_protocol_protocol,
                   id_nested_protocol
              FROM protocol_protocol
             WHERE id_protocol_protocol = in_id_protocol_protocol;
        l_protocol_protocol c_protocol_protocol%ROWTYPE;
    
        TYPE r_protocol_element_map IS RECORD(
            id_protocol_element_new NUMBER);
    
        TYPE t_record_prot_elem_map IS TABLE OF r_protocol_element_map INDEX BY BINARY_INTEGER;
        ibt_prot_elem_map t_record_prot_elem_map;
    
        -----------------
        l_seq_protocol_id          NUMBER;
        l_seq_protocol_crit_inc_id NUMBER;
        l_seq_protocol_crit_exc_id NUMBER;
        l_sysdate                  TIMESTAMP WITH TIME ZONE := current_timestamp;
    
        l_counter NUMBER;
    BEGIN
        g_error := 'NEW OR EDITING';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- New or editing
        IF (i_id_protocol IS NULL)
        THEN
            -- new id protocol
            flg_new := TRUE;
        ELSE
            -- Protocol equal to previous, so we are editing
            flg_new := FALSE;
        END IF;
    
        g_error := 'GET IDS';
        pk_alertlog.log_debug(g_error, g_package_name);
        -- Get protocol basic IDs
        l_seq_protocol_id          := get_protocol_seq;
        l_seq_protocol_crit_inc_id := get_protocol_criteria_seq;
        l_seq_protocol_crit_exc_id := get_protocol_criteria_seq;
    
        -- Output protocol id created
        o_id_protocol := l_seq_protocol_id;
    
        IF (flg_new) -- new protocol
        THEN
            g_error := 'NEW PROTOCOL SET VARIABLES';
            pk_alertlog.log_debug(g_error, g_package_name);
            l_protocol.id_protocol                  := l_seq_protocol_id;
            l_protocol.id_protocol_previous_version := NULL;
            l_protocol.dt_protocol                  := l_sysdate;
            l_protocol.flg_status                   := g_protocol_temp;
            l_protocol.id_context_language          := i_lang;
            l_protocol.id_professional              := i_prof.id;
            l_protocol.id_institution               := i_prof.institution;
            l_protocol.id_software                  := i_prof.software;
            l_protocol.flg_type_recommendation      := g_default_type_rec;
            -- Inclusion Criteria
            l_protocol_criteria_inc.id_protocol_criteria := l_seq_protocol_crit_inc_id;
            l_protocol_criteria_inc.id_protocol          := l_seq_protocol_id;
            l_protocol_criteria_inc.criteria_type        := g_criteria_type_inc;
            -- Exclusion Criteria
            l_protocol_criteria_exc.id_protocol_criteria := l_seq_protocol_crit_exc_id;
            l_protocol_criteria_exc.id_protocol          := l_seq_protocol_id;
            l_protocol_criteria_exc.criteria_type        := g_criteria_type_exc;
        ELSE
            -- editing
        
            g_error := 'EDIT PROTOCOL SET VARIABLES';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Fetches parent protocol info
            OPEN c_protocol(i_id_protocol);
        
            FETCH c_protocol
                INTO l_protocol;
        
            CLOSE c_protocol;
        
            g_error := 'GET CRITERIA INC';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Criteria Inclusion
            OPEN c_protocol_criteria(i_id_protocol, g_criteria_type_inc);
        
            FETCH c_protocol_criteria
                INTO l_protocol_criteria_inc;
        
            CLOSE c_protocol_criteria;
        
            g_error := 'GET CRITERIA EXC';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Criteria Exclusion
            OPEN c_protocol_criteria(i_id_protocol, g_criteria_type_exc);
        
            FETCH c_protocol_criteria
                INTO l_protocol_criteria_exc;
        
            CLOSE c_protocol_criteria;
        
            g_error := 'GET IDS FOR OTHER TABLES';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            --  Parent ID as we are editing
            l_protocol.id_protocol                  := l_seq_protocol_id;
            l_protocol.id_protocol_previous_version := i_id_protocol;
            l_protocol.dt_protocol                  := l_sysdate;
            l_protocol.flg_status                   := g_protocol_temp;
            l_protocol.id_professional              := i_prof.id;
            l_protocol.id_institution               := i_prof.institution;
            l_protocol.id_software                  := i_prof.software;
            l_protocol.dt_cancel                    := NULL;
            l_protocol.id_prof_cancel               := NULL;
        
            -- In case of duplication the link to the previous protocol and id_content column value must be deleted
            IF (i_duplicate_flg = g_yes)
            THEN
                l_protocol.id_protocol_previous_version := NULL;
                l_protocol.id_content                   := NULL;
            END IF;
        
            g_error := 'GET TASK LINKS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Inclusion Criteria
            l_protocol_criteria_inc.id_protocol          := l_seq_protocol_id;
            l_protocol_criteria_inc.id_protocol_criteria := l_seq_protocol_crit_inc_id;
            -- Exclusion Criteria
            l_protocol_criteria_exc.id_protocol          := l_seq_protocol_id;
            l_protocol_criteria_exc.id_protocol_criteria := l_seq_protocol_crit_exc_id;
        
            -- Get data from previous protocol -------------------------------------------------------------
            g_error := 'GET LINKS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR rec IN c_protocol_link(i_id_protocol, l_seq_protocol_id)
            LOOP
                l_counter := ibt_protocol_link.count + 1;
                ibt_protocol_link(l_counter).id_protocol_link := rec.id_protocol_link;
                ibt_protocol_link(l_counter).id_protocol := rec.id_protocol;
                ibt_protocol_link(l_counter).id_link := rec.id_link;
                ibt_protocol_link(l_counter).link_type := rec.link_type;
            END LOOP;
        
            g_error := 'GET CONTEXT IMAGE';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR rec IN c_protocol_context_image(i_id_protocol, l_seq_protocol_id)
            LOOP
                l_counter := ibt_protocol_context_image.count + 1;
                ibt_protocol_context_image(l_counter).id_protocol_context_image := rec.id_protocol_context_image;
                ibt_protocol_context_image(l_counter).id_protocol := rec.id_protocol;
                ibt_protocol_context_image(l_counter).file_name := rec.file_name;
                ibt_protocol_context_image(l_counter).img_desc := rec.img_desc;
                ibt_protocol_context_image(l_counter).dt_img := rec.dt_img;
                ibt_protocol_context_image(l_counter).img := rec.img;
                ibt_protocol_context_image(l_counter).img_thumbnail := rec.img_thumbnail;
                ibt_protocol_context_image(l_counter).flg_status := rec.flg_status;
            END LOOP;
        
            g_error := 'GET CONTEXT AUTHOR';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR rec IN c_protocol_context_author(i_id_protocol, l_seq_protocol_id)
            LOOP
                l_counter := ibt_protocol_context_author.count + 1;
                ibt_protocol_context_author(l_counter).id_protocol_context_author := rec.id_protocol_context_author;
                ibt_protocol_context_author(l_counter).id_protocol := rec.id_protocol;
                ibt_protocol_context_author(l_counter).first_name := rec.first_name;
                ibt_protocol_context_author(l_counter).last_name := rec.last_name;
                ibt_protocol_context_author(l_counter).title := rec.title;
            END LOOP;
        
            g_error := 'GET CRITERIA LINKS EXC';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Criteria Link
            FOR l_protocol_criteria_link_exc IN c_protocol_criteria_link(i_id_protocol,
                                                                         l_seq_protocol_crit_exc_id,
                                                                         g_criteria_type_exc)
            LOOP
                l_counter := ibt_protocol_crit_link_exc.count + 1;
                ibt_protocol_crit_link_exc(l_counter).id_protocol_criteria_link := l_protocol_criteria_link_exc.id_protocol_criteria_link_new;
                ibt_protocol_crit_link_exc(l_counter).id_protocol_criteria := l_protocol_criteria_link_exc.id_protocol_criteria;
                ibt_protocol_crit_link_exc(l_counter).id_link_other_criteria := l_protocol_criteria_link_exc.id_link_other_criteria;
                ibt_protocol_crit_link_exc(l_counter).id_link_other_criteria_type := l_protocol_criteria_link_exc.id_link_other_criteria_type;
            
                -- related advanced input values
                FOR rec_adv_input IN c_protocol_adv_input_value(g_adv_input_type_criterias,
                                                                l_protocol_criteria_link_exc.id_protocol_criteria_link,
                                                                l_protocol_criteria_link_exc.id_protocol_criteria_link_new)
                LOOP
                    l_counter := ibt_protocol_adv_input_value.count + 1;
                    ibt_protocol_adv_input_value(l_counter).id_protocol_adv_input_value := rec_adv_input.id_protocol_adv_input_value;
                    ibt_protocol_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                    ibt_protocol_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                    ibt_protocol_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                    ibt_protocol_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                    ibt_protocol_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                    ibt_protocol_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                    ibt_protocol_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                    ibt_protocol_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                END LOOP;
            END LOOP;
        
            g_error := 'GET CRITERIA LINKS INC';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR l_protocol_criteria_link_inc IN c_protocol_criteria_link(i_id_protocol,
                                                                         l_seq_protocol_crit_inc_id,
                                                                         g_criteria_type_inc)
            LOOP
                l_counter := ibt_protocol_crit_link_inc.count + 1;
                ibt_protocol_crit_link_inc(l_counter).id_protocol_criteria_link := l_protocol_criteria_link_inc.id_protocol_criteria_link_new;
                ibt_protocol_crit_link_inc(l_counter).id_protocol_criteria := l_protocol_criteria_link_inc.id_protocol_criteria;
                ibt_protocol_crit_link_inc(l_counter).id_link_other_criteria := l_protocol_criteria_link_inc.id_link_other_criteria;
                ibt_protocol_crit_link_inc(l_counter).id_link_other_criteria_type := l_protocol_criteria_link_inc.id_link_other_criteria_type;
            
                -- related advanced input values
                FOR rec_adv_input IN c_protocol_adv_input_value(g_adv_input_type_criterias,
                                                                l_protocol_criteria_link_inc.id_protocol_criteria_link,
                                                                l_protocol_criteria_link_inc.id_protocol_criteria_link_new)
                LOOP
                    l_counter := ibt_protocol_adv_input_value.count + 1;
                    ibt_protocol_adv_input_value(l_counter).id_protocol_adv_input_value := rec_adv_input.id_protocol_adv_input_value;
                    ibt_protocol_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                    ibt_protocol_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                    ibt_protocol_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                    ibt_protocol_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                    ibt_protocol_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                    ibt_protocol_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                    ibt_protocol_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                    ibt_protocol_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                    ibt_protocol_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                END LOOP;
            END LOOP;
        
            -----------------------------------
            g_error := 'GET PROTOCOL ELEMENTS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- create protocol elements  
            FOR l_protocol_element IN c_protocol_element(i_id_protocol, l_seq_protocol_id)
            LOOP
            
                l_counter := ibt_protocol_element.count + 1;
                ibt_protocol_element(l_counter).id_protocol_element := l_protocol_element.id_protocol_element_new;
                ibt_protocol_element(l_counter).id_protocol := l_protocol_element.id_protocol_new;
                ibt_protocol_element(l_counter).id_element := l_protocol_element.id_element_new;
                ibt_protocol_element(l_counter).element_type := l_protocol_element.element_type;
                ibt_protocol_element(l_counter).desc_element := l_protocol_element.desc_element;
                ibt_protocol_element(l_counter).x_coordinate := l_protocol_element.x_coordinate;
                ibt_protocol_element(l_counter).y_coordinate := l_protocol_element.y_coordinate;
                ibt_protocol_element(l_counter).flg_available := l_protocol_element.flg_available;
            
                ibt_prot_elem_map(l_protocol_element.id_protocol_element).id_protocol_element_new := l_protocol_element.id_protocol_element_new;
            
                IF (l_protocol_element.element_type = g_element_task)
                THEN
                    -- Open task
                    FOR l_protocol_task IN c_protocol_task(l_protocol_element.id_element,
                                                           l_protocol_element.id_element_new)
                    LOOP
                    
                        l_counter := ibt_protocol_task.count + 1;
                        ibt_protocol_task(l_counter).id_protocol_task := l_protocol_task.id_protocol_task_new;
                        ibt_protocol_task(l_counter).id_group_task := l_protocol_task.id_group_task_new;
                        ibt_protocol_task(l_counter).desc_protocol_task := l_protocol_task.desc_protocol_task;
                        ibt_protocol_task(l_counter).id_task_link := l_protocol_task.id_task_link;
                        ibt_protocol_task(l_counter).task_type := l_protocol_task.task_type;
                        ibt_protocol_task(l_counter).task_notes := l_protocol_task.task_notes;
                        ibt_protocol_task(l_counter).task_codification := l_protocol_task.task_codification;
                    
                        -- related advanced input values
                        FOR rec_adv_input IN c_protocol_adv_input_value(g_adv_input_type_tasks,
                                                                        l_protocol_task.id_protocol_task,
                                                                        l_protocol_task.id_protocol_task_new)
                        LOOP
                            l_counter := ibt_protocol_adv_input_value.count + 1;
                            ibt_protocol_adv_input_value(l_counter).id_protocol_adv_input_value := rec_adv_input.id_protocol_adv_input_value;
                            ibt_protocol_adv_input_value(l_counter).id_adv_input_link := rec_adv_input.id_adv_input_link;
                            ibt_protocol_adv_input_value(l_counter).flg_type := rec_adv_input.flg_type;
                            ibt_protocol_adv_input_value(l_counter).value_type := rec_adv_input.value_type;
                            ibt_protocol_adv_input_value(l_counter).nvalue := rec_adv_input.nvalue;
                            ibt_protocol_adv_input_value(l_counter).dvalue := rec_adv_input.dvalue;
                            ibt_protocol_adv_input_value(l_counter).vvalue := rec_adv_input.vvalue;
                            ibt_protocol_adv_input_value(l_counter).value_desc := rec_adv_input.value_desc;
                            ibt_protocol_adv_input_value(l_counter).criteria_value_type := rec_adv_input.criteria_value_type;
                            ibt_protocol_adv_input_value(l_counter).id_advanced_input := rec_adv_input.id_advanced_input;
                            ibt_protocol_adv_input_value(l_counter).id_advanced_input_field := rec_adv_input.id_advanced_input_field;
                            ibt_protocol_adv_input_value(l_counter).id_advanced_input_field_det := rec_adv_input.id_advanced_input_field_det;
                        END LOOP;
                    END LOOP;
                
                ELSIF (l_protocol_element.element_type = g_element_question)
                THEN
                    -- Open question
                    FOR l_protocol_question IN c_protocol_question(l_protocol_element.id_element,
                                                                   l_protocol_element.id_element_new)
                    LOOP
                        l_counter := ibt_protocol_question.count + 1;
                        ibt_protocol_question(l_counter).id_protocol_question := l_protocol_question.id_protocol_question_new;
                        ibt_protocol_question(l_counter).desc_protocol_question := l_protocol_question.desc_protocol_question;
                    
                    END LOOP;
                
                ELSIF (l_protocol_element.element_type = g_element_warning OR
                      l_protocol_element.element_type = g_element_instruction OR
                      l_protocol_element.element_type = g_element_header)
                THEN
                    -- Open text                            
                    FOR l_protocol_text IN c_protocol_text(l_protocol_element.id_element,
                                                           l_protocol_element.id_element_new)
                    LOOP
                        l_counter := ibt_protocol_text.count + 1;
                        ibt_protocol_text(l_counter).id_protocol_text := l_protocol_text.id_protocol_text_new;
                        ibt_protocol_text(l_counter).desc_protocol_text := l_protocol_text.desc_protocol_text;
                        ibt_protocol_text(l_counter).protocol_text_type := l_protocol_text.protocol_text_type;
                    
                    END LOOP;
                ELSIF (l_protocol_element.element_type = g_element_protocol)
                THEN
                    -- Open protocol                            
                    FOR l_protocol_protocol IN c_protocol_protocol(l_protocol_element.id_element,
                                                                   l_protocol_element.id_element_new)
                    LOOP
                        l_counter := ibt_protocol_protocol.count + 1;
                        ibt_protocol_protocol(l_counter).id_protocol_protocol := l_protocol_protocol.id_protocol_protocol_new;
                        ibt_protocol_protocol(l_counter).desc_protocol_protocol := l_protocol_protocol.desc_protocol_protocol;
                        ibt_protocol_protocol(l_counter).id_nested_protocol := l_protocol_protocol.id_nested_protocol;
                    
                    END LOOP;
                END IF;
            END LOOP;
        
            g_error := 'GET RELATIONS AND ASSOCIATED CONNECTORS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR l_protocol_relation IN c_protocol_relation(i_id_protocol, l_seq_protocol_id)
            LOOP
            
                l_counter := ibt_protocol_relation.count + 1;
            
                ibt_protocol_relation(l_counter).id_protocol_relation := l_protocol_relation.id_protocol_relation_new;
                ibt_protocol_relation(l_counter).id_protocol := l_protocol_relation.id_protocol_new;
                ibt_protocol_relation(l_counter).id_protocol_element_parent := ibt_prot_elem_map(l_protocol_relation.id_protocol_element_parent).id_protocol_element_new;
                ibt_protocol_relation(l_counter).id_protocol_connector := l_protocol_relation.id_protocol_connector_new;
                ibt_protocol_relation(l_counter).id_protocol_element := ibt_prot_elem_map(l_protocol_relation.id_protocol_element).id_protocol_element_new;
                ibt_protocol_relation(l_counter).desc_relation := l_protocol_relation.desc_relation;
                ibt_protocol_relation(l_counter).flg_available := l_protocol_relation.flg_available;
            
                -- Open connector
                FOR l_protocol_connector IN c_protocol_connector(l_protocol_relation.id_protocol_connector,
                                                                 l_protocol_relation.id_protocol_connector_new)
                LOOP
                    l_counter := ibt_protocol_connector.count + 1;
                    ibt_protocol_connector(l_counter).id_protocol_connector := l_protocol_connector.id_protocol_connector_new;
                    ibt_protocol_connector(l_counter).desc_protocol_connector := l_protocol_connector.desc_protocol_connector;
                    ibt_protocol_connector(l_counter).flg_desc_protocol_connector := l_protocol_connector.flg_desc_protocol_connector;
                    ibt_protocol_connector(l_counter).flg_available := l_protocol_connector.flg_available;
                
                END LOOP;
            
            END LOOP;
        
            --------------------------------------    
            -- When we want to duplicate we delete the link to another protocol
            IF (i_duplicate_flg = g_yes)
            THEN
                l_protocol.id_protocol_previous_version := NULL;
            END IF;
        
            -- Get data from previous protocol -------------------------------------------------------------
        END IF;
    
        g_error := 'INSERT PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Set protocol
        INSERT INTO protocol
        VALUES l_protocol;
    
        g_error := 'INSERT CRITERIA INC';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Set Criteria
        INSERT INTO protocol_criteria
        VALUES l_protocol_criteria_inc;
    
        g_error := 'INSERT PROTOCOL EXC';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        INSERT INTO protocol_criteria
        VALUES l_protocol_criteria_exc;
    
        IF (NOT flg_new)
        THEN
            -- Set Criteria Link
            BEGIN
                g_error := 'INSERT CRITERIA LINK INC';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_crit_link_inc.count > 0)
                THEN
                    FORALL i IN ibt_protocol_crit_link_inc.first .. ibt_protocol_crit_link_inc.last
                        INSERT INTO protocol_criteria_link
                        VALUES ibt_protocol_crit_link_inc
                            (i);
                
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            BEGIN
                g_error := 'INSERT CRITERIA LINK EXC';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_crit_link_exc.count > 0)
                THEN
                    FORALL i IN ibt_protocol_crit_link_exc.first .. ibt_protocol_crit_link_exc.last
                        INSERT INTO protocol_criteria_link
                        VALUES ibt_protocol_crit_link_exc
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Context Image
            BEGIN
                g_error := 'INSERT CONTEXT IMAGE';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_context_image.count > 0)
                THEN
                    FORALL i IN ibt_protocol_context_image.first .. ibt_protocol_context_image.last
                        INSERT INTO protocol_context_image
                        VALUES ibt_protocol_context_image
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Context Author
            BEGIN
                g_error := 'INSERT CONTEXT AUTHOR';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_context_author.count > 0)
                THEN
                    FORALL i IN ibt_protocol_context_author.first .. ibt_protocol_context_author.last
                        INSERT INTO protocol_context_author
                        VALUES ibt_protocol_context_author
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set Link
            BEGIN
                g_error := 'INSERT LINK';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_link.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_link.first .. ibt_protocol_link.last
                        INSERT INTO protocol_link
                        VALUES ibt_protocol_link
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            BEGIN
                g_error := 'INSERT ADV INPUT VALUES';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_adv_input_value.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_adv_input_value.first .. ibt_protocol_adv_input_value.last
                        INSERT INTO protocol_adv_input_value
                        VALUES ibt_protocol_adv_input_value
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- ALl connector topics
            -- Set Task Link
            BEGIN
                g_error := 'INSERT TASK';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_task.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_task.first .. ibt_protocol_task.last
                        INSERT INTO protocol_task
                        VALUES ibt_protocol_task
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            -- Set question 
            BEGIN
                g_error := 'INSERT QUESTION';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_question.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_question.first .. ibt_protocol_question.last
                        INSERT INTO protocol_question
                        VALUES ibt_protocol_question
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
            -- Set Text
            BEGIN
                g_error := 'INSERT TEXT';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_text.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_text.first .. ibt_protocol_text.last
                        INSERT INTO protocol_text
                        VALUES ibt_protocol_text
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
            -- Set Nested Protocol
            BEGIN
                g_error := 'INSERT NESTED PROTOCOL';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_protocol.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_protocol.first .. ibt_protocol_protocol.last
                        INSERT INTO protocol_protocol
                        VALUES ibt_protocol_protocol
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
            -- Set Element
            BEGIN
                g_error := 'INSERT ELEMENT';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_element.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_element.first .. ibt_protocol_element.last
                        INSERT INTO protocol_element
                        VALUES ibt_protocol_element
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
            -- Set Connector
            BEGIN
                g_error := 'INSERT CONNECTOR';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_connector.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_connector.first .. ibt_protocol_connector.last
                        INSERT INTO protocol_connector
                        VALUES ibt_protocol_connector
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
            -- Set Relation
            BEGIN
                g_error := 'INSERT RELATION';
                pk_alertlog.log_debug(g_error, g_package_name);
                IF (ibt_protocol_relation.count > 0)
                THEN
                
                    FORALL i IN ibt_protocol_relation.first .. ibt_protocol_relation.last
                        INSERT INTO protocol_relation
                        VALUES ibt_protocol_relation
                            (i);
                END IF;
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_protocol;

    /**
    *  Set specific protocol main attributes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_protocol                protocol ID
    * @param      I_PROTOCOL_DESC              protocol description
    * @param      I_ID_PROTOCOL_TYPE           protocol Type
    * @param      I_LINK_ENVIRONMENT           protocol environment link
    * @param      I_LINK_SPECIALTY             protocol specialty link
    * @param      I_LINK_PROFESSIONAL          protocol professional link
    * @param      I_LINK_EDIT_PROF             protocol edit professional link
    * @param      I_TYPE_RECOMMEDNATION        protocol type of recommendation
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_main
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
        i_protocol_desc       IN protocol.protocol_desc%TYPE,
        i_link_type           IN table_number,
        i_link_environment    IN table_number,
        i_link_specialty      IN table_number,
        i_link_professional   IN table_number,
        i_link_edit_prof      IN table_number,
        i_type_recommendation IN protocol.flg_type_recommendation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_protocol_link IS TABLE OF protocol_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_protocol_link t_protocol_link;
        counter           PLS_INTEGER;
    
        l_ins_link BOOLEAN := FALSE;
        error_undefined_status EXCEPTION;
    BEGIN
        g_error := 'UPDATE PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE protocol
           SET flg_type_recommendation = i_type_recommendation, protocol_desc = i_protocol_desc
         WHERE id_protocol = i_id_protocol
           AND flg_status = g_protocol_temp;
    
        IF (SQL%ROWCOUNT = 0)
        THEN
            RAISE error_undefined_status;
        END IF;
    
        counter := 0;
        g_error := 'CREATE RECORDS TYPE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_type.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_type.first .. i_link_type.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := i_link_type(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_type;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS ENVIRONMENT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_environment.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_environment.first .. i_link_environment.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := i_link_environment(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_envi;
                counter := counter + 1;
            END LOOP;
        END IF;
        g_error := 'CREATE RECORDS SPECIALTY';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_specialty.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_specialty.first .. i_link_specialty.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := i_link_specialty(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_spec;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS PROFESSIONAL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_professional.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_professional.first .. i_link_professional.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := i_link_professional(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_prof;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'CREATE RECORDS EDIT PROFESSIONAL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_edit_prof.count != 0)
        THEN
            l_ins_link := TRUE;
            FOR i IN i_link_edit_prof.first .. i_link_edit_prof.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := i_link_edit_prof(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_edit_prof;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'DELETE PROTOCOL LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_link
         WHERE id_protocol = i_id_protocol
           AND link_type NOT IN (g_protocol_link_pathol, g_protocol_link_chief_compl); -- pathology and chief complaints are being taken care of in another function           
    
        g_error := 'INSERT PROTOCOL LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
        
            IF (l_ins_link)
            THEN
                FORALL i IN ibt_protocol_link.first .. ibt_protocol_link.last SAVE EXCEPTIONS
                    INSERT INTO protocol_link
                    VALUES ibt_protocol_link
                        (i);
            END IF;
        EXCEPTION
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined_status THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / UNDEFINED STATE FOR PROTOCOL',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_main;

    /**
    *  Set specific protocol main pathology
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                  protocol ID
    * @param      I_LINK_PATHOLOGY             Pathology link ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_main_pathology
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_link_pathology IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_protocol_link IS TABLE OF protocol_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_protocol_link t_protocol_link;
        counter           PLS_INTEGER;
    
        l_ins_link       BOOLEAN := FALSE;
        l_link_pathology table_number;
        error_undefined_status EXCEPTION;
    BEGIN
    
        counter := 0;
    
        g_error := 'CREATE RECORDS PATHOLOGY';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_link_pathology.count != 0)
        THEN
            l_link_pathology := SET(i_link_pathology);
            l_ins_link       := TRUE;
            FOR i IN l_link_pathology.first .. l_link_pathology.last
            LOOP
                ibt_protocol_link(counter).id_protocol_link := get_protocol_link_seq;
                ibt_protocol_link(counter).id_protocol := i_id_protocol;
                ibt_protocol_link(counter).id_link := l_link_pathology(i);
                ibt_protocol_link(counter).link_type := g_protocol_link_pathol;
                counter := counter + 1;
            END LOOP;
        END IF;
    
        g_error := 'DELETE PROTOCOL LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_link
         WHERE id_protocol = i_id_protocol
           AND link_type = g_protocol_link_pathol;
    
        g_error := 'INSERT PROTOCOL LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
        
            IF (l_ins_link)
            THEN
                FORALL i IN ibt_protocol_link.first .. ibt_protocol_link.last SAVE EXCEPTIONS
                    INSERT INTO protocol_link
                    VALUES ibt_protocol_link
                        (i);
            END IF;
        EXCEPTION
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined_status THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / UNDEFINED STATE FOR PROTOCOL',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN_PATHOLOGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN_PATHOLOGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_MAIN_PATHOLOGY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_main_pathology;

    /** 
    *  Get protocol available criteria, to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_CRITS     List of criteria to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/29
    */
    FUNCTION get_protocol_avail_criteria
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_crits OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET PROTOCOL AVAILABLE CRITERIA';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_crits FOR
            SELECT DISTINCT item
              FROM (SELECT item,
                           first_value(prot_item.flg_available) over(PARTITION BY prot_item.item ORDER BY prot_item.id_market DESC, prot_item.id_institution DESC, prot_item.id_software DESC, prot_item.flg_available) AS flg_avail
                      FROM protocol_item_soft_inst prot_item
                     WHERE prot_item.id_institution IN (g_all_institution, i_prof.institution)
                       AND prot_item.id_software IN (g_all_software, i_prof.software)
                       AND prot_item.id_market IN (g_all_markets, l_market)
                       AND prot_item.flg_item_type = g_protocol_item_criteria
                       AND prot_item.item NOT IN (SELECT id_protocol_criteria_type
                                                    FROM protocol_criteria_type)) -- without other criteria
             WHERE flg_avail = g_available;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_AVAIL_CRITERIA',
                                              o_error);
            pk_types.open_my_cursor(o_crits);
            RETURN FALSE;
    END get_protocol_avail_criteria;

    /**
    *  Get protocol main attributes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_MAIN             protocol main attributes cursor
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_main
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_main OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_edit_permissions VARCHAR2(1000 CHAR) := get_link_id_str(i_lang,
                                                                       i_prof,
                                                                       i_id_protocol,
                                                                       g_protocol_link_edit_prof,
                                                                       g_separator);
    BEGIN
        g_error := 'GET PROTOCOL MAIN';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_main FOR
            SELECT prot.id_protocol,
                   prot.flg_status,
                   prot.protocol_desc,
                   nvl((SELECT g_available
                         FROM protocol_link
                        WHERE id_protocol = i_id_protocol
                          AND link_type = g_protocol_link_pathol
                          AND rownum = 1),
                       g_not_available) AS exist_pathologies,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator2) pathology_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_type, g_separator) type_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_envi, g_separator) environment_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_spec, g_separator) speciality_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_prof, g_separator) professional_desc,
                   pk_message.get_message(i_lang, g_message_protocol_authors) ||
                   decode(l_desc_edit_permissions, '', '', g_separator) || l_desc_edit_permissions AS edit_professional_desc,
                   prot.flg_type_recommendation AS flg_type_rec,
                   pk_sysdomain.get_domain(g_domain_flg_type_rec, prot.flg_type_recommendation, i_lang) AS desc_recommendation,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_chief_compl, g_separator) AS desc_chief_complaint
              FROM protocol prot
             WHERE prot.id_protocol = i_id_protocol;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_MAIN',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_main);
            RETURN FALSE;
    END get_protocol_main;

    /**
    *  Obtain all protocol by title
    *
    * @param      I_LANG                 Prefered language ID for this professional
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE                Value to search for
    * @param      I_ID_PATIENT           Patient ID
    * @param      O_PROTOCOL             Cursor with all protocol
    * @param      O_ERROR                error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_by_title
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        i_id_patient IN protocol_process.id_patient%TYPE,
        o_protocol   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol FOR
        
            SELECT prot.id_protocol AS id_protocol,
                   prot.protocol_desc AS protocol_title,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator) pathology_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_type, g_separator) type_desc,
                   check_history_protocol(prot.id_protocol, i_id_patient) AS flg_already_protocol
              FROM protocol          prot,
                   protocol_link     prot_lnk,
                   protocol_criteria prot_crit_inc,
                   protocol_criteria prot_crit_exc
             WHERE prot.flg_status = g_protocol_finished
                  -- Protocols created in Alert Care should not appear in the other softwares
                  --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND prot.id_software = pk_alert_constant.g_soft_primary_care) OR
                  --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND prot.id_software != pk_alert_constant.g_soft_primary_care))
                  -- professional category
               AND prot_lnk.id_protocol = prot.id_protocol
               AND prot_lnk.link_type = g_protocol_link_prof
               AND prot_lnk.id_link = (SELECT pc.id_category
                                         FROM prof_cat pc
                                        WHERE pc.id_professional = i_prof.id
                                          AND pc.id_institution = i_prof.institution)
                  -- department/environment
               AND i_prof.software IN (SELECT sd.id_software
                                         FROM software_dept sd, protocol_link prot_lnk3
                                        WHERE prot_lnk3.id_protocol = prot.id_protocol
                                          AND prot_lnk3.link_type = g_protocol_link_envi
                                          AND prot_lnk3.id_link = sd.id_dept)
               AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                            column_value
                                             FROM TABLE(l_institutions) inst)
               AND prot.flg_type_recommendation != g_type_rec_automatic
                  -- search for value
               AND ((translate(upper(prot.protocol_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
                  -- check patient gender
               AND prot_crit_inc.id_protocol = prot.id_protocol
               AND prot_crit_inc.criteria_type = g_criteria_type_inc
               AND nvl(prot_crit_inc.gender, l_pat_gender) = l_pat_gender
               AND prot_crit_exc.id_protocol = prot.id_protocol
               AND prot_crit_exc.criteria_type = g_criteria_type_exc
               AND ((l_pat_gender != prot_crit_exc.gender AND prot_crit_exc.gender IS NOT NULL) OR
                   prot_crit_exc.gender IS NULL)
             ORDER BY upper(protocol_title);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_BY_TITLE',
                                              o_error);
            pk_types.open_my_cursor(o_protocol);
            RETURN FALSE;
    END get_protocol_by_title;

    /**
    *  Get all protocol types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_TYPE             Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_type_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_type FOR
            SELECT prot_typ.id_protocol_type,
                   1 rank,
                   pk_translation.get_translation(i_lang, prot_typ.code_protocol_type) desc_protocol_type
              FROM protocol_type prot_typ
             WHERE prot_typ.flg_available = g_available
            UNION ALL
            SELECT g_protocol_type_any id_protocol_type,
                   2 rank,
                   pk_message.get_message(i_lang, g_message_any) desc_protocol_type
              FROM dual
             ORDER BY rank, desc_protocol_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TYPE_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_type);
            RETURN FALSE;
    END get_protocol_type_all;

    /**
    *  Get pathologies of a specific type of protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_TYPE          ID of protocol type
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_PROTOCOL_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.4
    * @since      2007/07/13
    */
    FUNCTION get_protocol_pathologies
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol_type IN NUMBER,
        i_id_patient       IN protocol_process.id_patient%TYPE,
        o_protocol_pathol  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_pathol   NUMBER(6);
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'COUNT PATHOLOGIES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT COUNT(1)
          INTO l_num_pathol
          FROM protocol          prot,
               protocol_link     prot_lnk,
               protocol_link     prot_lnk2,
               protocol_link     prot_lnk3,
               protocol_criteria prot_crit_inc,
               protocol_criteria prot_crit_exc
         WHERE prot.flg_status = g_protocol_finished
           AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                        column_value
                                         FROM TABLE(l_institutions) inst)
              --AND prot.id_software = i_prof.software
           AND prot.flg_type_recommendation != g_type_rec_automatic
              -- professional category
           AND prot_lnk3.id_protocol = prot.id_protocol
           AND prot_lnk3.link_type = g_protocol_link_prof
           AND prot_lnk3.id_link = (SELECT pc.id_category
                                      FROM prof_cat pc
                                     WHERE pc.id_professional = i_prof.id
                                       AND pc.id_institution = i_prof.institution)
              
              -- department/environment
           AND i_prof.software IN (SELECT sd.id_software
                                     FROM software_dept sd, protocol_link prot_lnk4
                                    WHERE prot_lnk4.id_protocol = prot.id_protocol
                                      AND prot_lnk4.link_type = g_protocol_link_envi
                                      AND prot_lnk4.id_link = sd.id_dept)
              
           AND prot_lnk.id_protocol = prot.id_protocol
           AND prot_lnk.link_type = g_protocol_link_pathol
           AND prot_lnk2.id_protocol = prot.id_protocol
           AND prot_lnk2.link_type = g_protocol_link_type
           AND prot_lnk2.id_link =
               decode(i_id_protocol_type, g_protocol_type_any, prot_lnk2.id_link, i_id_protocol_type)
              --           AND prot.id_protocol NOT IN
              --               (SELECT id_protocol
              --                  FROM protocol_process
              --                 WHERE id_patient = i_id_patient
              --                   AND flg_status IN (g_process_running, g_process_pending, g_process_recommended))
              -- check patient gender
           AND prot_crit_inc.id_protocol = prot.id_protocol
           AND prot_crit_inc.criteria_type = g_criteria_type_inc
           AND nvl(prot_crit_inc.gender, l_pat_gender) = l_pat_gender
           AND prot_crit_exc.id_protocol = prot.id_protocol
           AND prot_crit_exc.criteria_type = g_criteria_type_exc
           AND ((l_pat_gender != prot_crit_exc.gender AND prot_crit_exc.gender IS NOT NULL) OR
               prot_crit_exc.gender IS NULL);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF l_num_pathol != 0
        THEN
        
            OPEN o_protocol_pathol FOR
                SELECT id_pathol, rank, desc_pathol, i_id_protocol_type
                  FROM (SELECT pathol.id_link AS id_pathol,
                               1 rank,
                               pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_id_diagnosis => diag.id_diagnosis,
                                                          i_code         => diag.code_icd,
                                                          i_flg_other    => diag.flg_other,
                                                          i_flg_std_diag => pk_alert_constant.g_yes) AS desc_pathol
                        
                          FROM (SELECT DISTINCT prot_lnk.id_link
                                  FROM protocol          prot,
                                       protocol_link     prot_lnk,
                                       protocol_link     prot_lnk2,
                                       protocol_link     prot_lnk3,
                                       protocol_criteria prot_crit_inc,
                                       protocol_criteria prot_crit_exc
                                 WHERE prot.flg_status = g_protocol_finished
                                   AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                                column_value
                                                                 FROM TABLE(l_institutions) inst)
                                      --AND prot.id_software = i_prof.software
                                   AND prot_lnk3.id_protocol = prot.id_protocol
                                   AND prot_lnk3.link_type = g_protocol_link_prof
                                   AND prot_lnk3.id_link =
                                       (SELECT pc.id_category
                                          FROM prof_cat pc
                                         WHERE pc.id_professional = i_prof.id
                                           AND pc.id_institution = i_prof.institution)
                                      -- department/environment
                                   AND i_prof.software IN (SELECT sd.id_software
                                                             FROM software_dept sd, protocol_link prot_lnk4
                                                            WHERE prot_lnk4.id_protocol = prot.id_protocol
                                                              AND prot_lnk4.link_type = g_protocol_link_envi
                                                              AND prot_lnk4.id_link = sd.id_dept)
                                      
                                   AND prot_lnk.id_protocol = prot.id_protocol
                                   AND prot_lnk.link_type = g_protocol_link_pathol
                                   AND prot_lnk2.id_protocol = prot.id_protocol
                                   AND prot_lnk2.link_type = g_protocol_link_type
                                   AND prot_lnk2.id_link = decode(i_id_protocol_type,
                                                                  g_protocol_type_any,
                                                                  prot_lnk2.id_link,
                                                                  i_id_protocol_type)
                                      --                                   AND prot.id_protocol NOT IN
                                      --                                       (SELECT id_protocol
                                      --                                          FROM protocol_process
                                      --                                         WHERE id_patient = i_id_patient
                                      --                                           AND flg_status IN (g_process_running, g_process_pending, g_process_recommended))
                                      -- check patient gender
                                   AND prot_crit_inc.id_protocol = prot.id_protocol
                                   AND prot_crit_inc.criteria_type = g_criteria_type_inc
                                   AND nvl(prot_crit_inc.gender, l_pat_gender) = l_pat_gender
                                   AND prot_crit_exc.id_protocol = prot.id_protocol
                                   AND prot_crit_exc.criteria_type = g_criteria_type_exc
                                   AND ((l_pat_gender != prot_crit_exc.gender AND prot_crit_exc.gender IS NOT NULL) OR
                                       prot_crit_exc.gender IS NULL)) pathol,
                               diagnosis diag -- pathology
                         WHERE pathol.id_link = diag.id_diagnosis
                        
                        UNION ALL
                        
                        SELECT g_protocol_pathol_any AS id_pathol,
                               2 rank,
                               pk_message.get_message(i_lang, g_message_any) AS desc_pathol
                          FROM dual
                         WHERE l_num_pathol > 1)
                 ORDER BY rank, desc_pathol;
        ELSE
            pk_types.open_my_cursor(o_protocol_pathol);
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
                                              'GET_PROTOCOL_PATHOLOGIES',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_pathol);
            RETURN FALSE;
    END get_protocol_pathologies;

    /**
    *  Get all protocol by type and pathology
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_TYPE          ID of protocol type
    * @param      I_ID_PROTOCOL_PATHO         ID of protocol pathology
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_PROTOCOL_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_by_type_patho
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol_type   IN NUMBER,
        i_id_protocol_pathol IN NUMBER,
        i_id_patient         IN protocol_process.id_patient%TYPE,
        o_protocol           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol FOR
            SELECT id_protocol,
                   protocol_title,
                   check_history_protocol(id_protocol, i_id_patient) AS flg_already_recommended
              FROM (SELECT DISTINCT (prot.id_protocol), prot.protocol_desc AS protocol_title
                      FROM protocol          prot,
                           protocol_link     prot_lnk,
                           protocol_link     prot_lnk2,
                           protocol_link     prot_lnk3,
                           protocol_criteria prot_crit_inc,
                           protocol_criteria prot_crit_exc
                     WHERE prot.flg_status = g_protocol_finished
                       AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                    column_value
                                                     FROM TABLE(l_institutions) inst)
                          -- Protocols created in Alert Care should not appear in the other softwares
                          --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND prot.id_software = pk_alert_constant.g_soft_primary_care) OR
                          --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND prot.id_software != pk_alert_constant.g_soft_primary_care))
                       AND prot.flg_type_recommendation != g_type_rec_automatic
                          -- professional category                      
                       AND prot_lnk3.id_protocol = prot.id_protocol
                       AND prot_lnk3.link_type = g_protocol_link_prof
                       AND prot_lnk3.id_link = (SELECT pc.id_category
                                                  FROM prof_cat pc
                                                 WHERE pc.id_professional = i_prof.id
                                                   AND pc.id_institution = i_prof.institution)
                          -- department/environment
                       AND i_prof.software IN (SELECT sd.id_software
                                                 FROM software_dept sd, protocol_link prot_lnk4
                                                WHERE prot_lnk4.id_protocol = prot.id_protocol
                                                  AND prot_lnk4.link_type = g_protocol_link_envi
                                                  AND prot_lnk4.id_link = sd.id_dept)
                          
                       AND prot_lnk.id_protocol = prot.id_protocol
                       AND prot_lnk.link_type = g_protocol_link_pathol
                       AND ((i_id_protocol_pathol != g_protocol_pathol_any AND prot_lnk.id_link = i_id_protocol_pathol) OR
                           i_id_protocol_pathol = g_protocol_pathol_any)
                       AND prot_lnk2.id_protocol = prot.id_protocol
                       AND prot_lnk2.link_type = g_protocol_link_type
                       AND ((i_id_protocol_type != g_protocol_type_any AND prot_lnk2.id_link = i_id_protocol_type) OR
                           i_id_protocol_type = g_protocol_type_any)
                          -- check patient gender
                       AND prot_crit_inc.id_protocol = prot.id_protocol
                       AND prot_crit_inc.criteria_type = g_criteria_type_inc
                       AND nvl(prot_crit_inc.gender, l_pat_gender) = l_pat_gender
                       AND prot_crit_exc.id_protocol = prot.id_protocol
                       AND prot_crit_exc.criteria_type = g_criteria_type_exc
                       AND ((l_pat_gender != prot_crit_exc.gender AND prot_crit_exc.gender IS NOT NULL) OR
                           prot_crit_exc.gender IS NULL))
             ORDER BY upper(protocol_title);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_BY_TYPE_PATHO',
                                              o_error);
            pk_types.open_my_cursor(o_protocol);
            RETURN FALSE;
    END get_protocol_by_type_patho;

    /**
    *  Obtain all protocol by pathology
    *
    * @param      I_LANG               Prefered languagie ID for this professional
    * @param      I_PROF               object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE              Value to search for
    * @param      O_PROTOCOL         cursor with all protocol classified by type
    * @param      O_ERROR              error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_by_pathology
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_value    IN VARCHAR2,
        o_protocol OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions table_number;
    
    BEGIN
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol FOR
            SELECT prot.id_protocol,
                   prot.protocol_desc,
                   decode(prot.flg_status, g_protocol_deleted, g_cancelled, g_not_cancelled) AS flg_cancel,
                   -- protocol cannot be edited or duplicated when it was created in other than professional's institution
                   decode(prot.id_institution,
                           i_prof.institution,
                           -- grants for professional
                           CASE
                               WHEN prot.id_content IS NULL THEN
                                decode(nvl((
                                           -- grants by author history
                                           SELECT g_available
                                             FROM protocol grants_prot
                                            WHERE id_professional = i_prof.id
                                              AND rownum = 1
                                            START WITH grants_prot.id_protocol = prot.id_protocol
                                           CONNECT BY PRIOR grants_prot.id_protocol = grants_prot.id_protocol_previous_version
                                           UNION
                                           -- grants by professional category
                                           SELECT g_available
                                             FROM protocol_link prot_lnk, prof_cat pc
                                            WHERE prot_lnk.id_protocol = prot.id_protocol
                                              AND prot_lnk.link_type = g_protocol_link_edit_prof
                                              AND pc.id_professional = i_prof.id
                                              AND pc.id_institution = i_prof.institution
                                              AND prot_lnk.id_link = pc.id_category),
                                           g_not_available),
                                       g_available,
                                       decode(prot.flg_status, g_protocol_deleted, NULL, g_protocol_editable),
                                       NULL)
                               ELSE
                                NULL -- if this protocol has an id_content, then edit option should not be possible
                           END || '|' || g_protocol_duplicable || '|' || g_protocol_viewable,
                           g_protocol_viewable) AS flg_edit_options,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator) pathology_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_type, g_separator) type_desc,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional),
                       pk_message.get_message(i_lang, g_message_na)) || chr(10) ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, prot.dt_protocol, i_prof.institution, i_prof.software) author_date_desc,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional),
                       pk_message.get_message(i_lang, g_message_na)) author,
                   pk_date_utils.date_send_tsz(i_lang, prot.dt_protocol, i_prof) AS dt_protocol
              FROM protocol prot
              LEFT OUTER JOIN professional prof
                ON (prot.id_professional = prof.id_professional)
            -- protocol_type prot_type
             WHERE
            -- AND prot.id_protocol_type = prot_type.id_protocol_type(+)
             prot.flg_status != g_protocol_temp -- gets all protocols status except temp and deprecated
             AND prot.flg_status != g_protocol_deprecated
             AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                      column_value
                                       FROM TABLE(l_institutions) inst)
            -- Protocols created in Alert Care should not appear in the other softwares
            --AND ((i_prof.software = pk_alert_constant.g_soft_primary_care AND prot.id_software = pk_alert_constant.g_soft_primary_care) OR
            --    (i_prof.software != pk_alert_constant.g_soft_primary_care AND prot.id_software != pk_alert_constant.g_soft_primary_care))
            -- search for value
             AND ((translate(upper(get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator) ||
                               prot.protocol_desc),
                         'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                         'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
             '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
             i_value IS NOT NULL) OR i_value IS NULL)
             ORDER BY flg_cancel, upper(prot.protocol_desc);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_BY_PATHOLOGY',
                                              o_error);
            pk_types.open_my_cursor(o_protocol);
            RETURN FALSE;
    END get_protocol_by_pathology;

    /**
    *  Get a list of possible nested protocols for a given protocol
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL       ID of protocol.
    * @param      I_VALUE             Value to search for
    * @param      O_NESTED_PROTOCOLS  List of possible nested protocols
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/09/28
    */
    FUNCTION get_nested_protocols
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        i_value            IN VARCHAR2,
        o_nested_protocols OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_protocol_parent protocol.id_protocol%TYPE;
    BEGIN
    
        g_error := 'GET PROTOCOL PARENT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT id_protocol_previous_version
          INTO l_protocol_parent
          FROM protocol
         WHERE id_protocol = i_id_protocol;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_nested_protocols FOR
            SELECT prot.id_protocol,
                   prot.protocol_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator) pathology_desc,
                   get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_type, g_separator) type_desc,
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional),
                       pk_message.get_message(i_lang, g_message_na)) || chr(10) ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, prot.dt_protocol, i_prof.institution, i_prof.software) author_date_desc,
                   pk_date_utils.date_send_tsz(i_lang, prot.dt_protocol, i_prof) AS dt_protocol
              FROM protocol prot
              LEFT OUTER JOIN professional prof
                ON (prot.id_professional = prof.id_professional)
             WHERE prot.flg_status = g_protocol_finished
               AND prot.id_institution = i_prof.institution
               AND ((l_protocol_parent IS NOT NULL AND prot.id_protocol != l_protocol_parent) OR
                   l_protocol_parent IS NULL)
                  -- exclude nested protocol cycles
               AND prot.id_protocol NOT IN
                   (SELECT prot_elem.id_protocol
                      FROM protocol_element prot_elem, protocol_protocol prot_prot
                     WHERE prot_elem.element_type = g_element_protocol
                       AND prot_elem.id_element = prot_prot.id_protocol_protocol
                       AND (l_protocol_parent IS NOT NULL AND prot_prot.id_nested_protocol = l_protocol_parent))
                  -- AND prot.id_software = i_prof.software
                  -- search for value
               AND ((translate(upper(get_link_id_str(i_lang,
                                                     i_prof,
                                                     prot.id_protocol,
                                                     g_protocol_link_pathol,
                                                     g_separator) || prot.protocol_desc),
                               'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                               'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
             ORDER BY prot.protocol_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NESTED_PROTOCOLS',
                                              o_error);
            pk_types.open_my_cursor(o_nested_protocols);
            RETURN FALSE;
    END get_nested_protocols;

    /**
    *  Gets protocol pathology ids
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PATHOLOGY_ID               protocol pathology ids
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_pathology_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_pathology_id OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROTOCOL MAIN';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_pathology_id FOR
            SELECT prot.id_protocol, prot_lnk.id_link
              FROM protocol prot, protocol_link prot_lnk
             WHERE prot.id_protocol = i_id_protocol
               AND prot_lnk.id_protocol = prot.id_protocol
               AND prot_lnk.link_type = g_protocol_link_pathol;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATHOLOGY_ID',
                                              o_error);
            pk_types.open_my_cursor(o_pathology_id);
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
                                           first_value(pisi.flg_available) over(PARTITION BY pisi.item, pisi.flg_item_type ORDER BY pisi.id_market DESC, pisi.id_institution DESC, pisi.id_software DESC, pisi.flg_available) AS flg_avail
                                      FROM protocol_item_soft_inst pisi
                                     WHERE pisi.id_institution IN (g_all_institution, i_prof.institution)
                                       AND pisi.id_software IN (g_all_software, i_prof.software)
                                       AND pisi.id_market IN (g_all_markets, l_market)
                                       AND flg_item_type = g_protocol_item_tasks
                                       AND item IN (g_task_appoint, g_task_specialty_appointment))
                             WHERE (item = g_task_specialty_appointment AND flg_avail = g_not_available)
                                OR (item = g_task_appoint AND flg_avail = g_not_available))
                       AND EXISTS
                     (SELECT 1
                              FROM professional prf, prof_dep_clin_serv pdcs, prof_func pf
                             WHERE prf.flg_state = g_prof_active
                               AND prf.id_professional != i_prof.id
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_APPOINTMENTS',
                                              o_error);
            pk_types.open_my_cursor(o_specs);
            RETURN FALSE;
    END get_appointments;

    /**
    *  Set protocol criteria
    *
    * @param      I_LANG                         Prefered languagie ID for this professional
    * @param      I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                 protocol ID
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
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_criteria
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_protocol                 IN protocol.id_protocol%TYPE,
        i_criteria_type               IN protocol_criteria.criteria_type%TYPE,
        i_gender                      IN protocol_criteria.gender%TYPE,
        i_min_age                     IN protocol_criteria.min_age%TYPE,
        i_max_age                     IN protocol_criteria.max_age%TYPE,
        i_min_weight                  IN protocol_criteria.min_weight%TYPE,
        i_max_weight                  IN protocol_criteria.max_weight%TYPE,
        i_id_weight_unit_measure      IN protocol_criteria.id_weight_unit_measure%TYPE,
        i_min_height                  IN protocol_criteria.min_height%TYPE,
        i_max_height                  IN protocol_criteria.max_height%TYPE,
        i_id_height_unit_measure      IN protocol_criteria.id_height_unit_measure%TYPE,
        i_imc_min                     IN protocol_criteria.imc_min%TYPE,
        i_imc_max                     IN protocol_criteria.imc_max%TYPE,
        i_id_blood_press_unit_measure IN protocol_criteria.id_blood_pressure_unit_measure%TYPE,
        i_min_blood_pressure_s        IN protocol_criteria.min_blood_pressure_s%TYPE,
        i_max_blood_pressure_s        IN protocol_criteria.max_blood_pressure_s%TYPE,
        i_min_blood_pressure_d        IN protocol_criteria.min_blood_pressure_d%TYPE,
        i_max_blood_pressure_d        IN protocol_criteria.max_blood_pressure_d%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE PROTOCOL CRITERIA';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Update protocol criteria
        UPDATE protocol_criteria
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
         WHERE id_protocol = i_id_protocol
           AND criteria_type = i_criteria_type;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CRITERIA',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_criteria;
    /** 
    *  Set protocol other criteria
    *
    * @param      I_LANG                        Prefered languagie ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                 Protocol ID
    * @param      I_CRITERIA_TYPE               Criteria Type: Inclusion / Exclusion
    * @param      I_ID_LINK_OTHER_CRITERIA      Other criterias link
    * @param      I_ID_LINK_OTHER_CRITERIA_TYPE Type of other criteria link
    * @param      O_ID_PROT_CRITERIA_LINK       New ID of each criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/18
    */

    FUNCTION set_protocol_criteria_other
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_protocol                 IN protocol.id_protocol%TYPE,
        i_criteria_type               IN protocol_criteria.criteria_type%TYPE,
        i_id_link_other_criteria      IN table_varchar,
        i_id_link_other_criteria_type IN table_number,
        o_id_prot_criteria_link       OUT table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_protocol_criteria_link IS TABLE OF protocol_criteria_link%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_protocol_criteria_link  t_protocol_criteria_link;
        l_id_protocol_criteria      protocol_criteria_link.id_protocol_criteria%TYPE;
        l_link_crit                 BOOLEAN := FALSE;
        l_id_protocol_criteria_link protocol_criteria_link.id_protocol_criteria_link%TYPE;
    BEGIN
        g_error := 'GET PROTOCOL CRITERIA ID';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT id_protocol_criteria
          INTO l_id_protocol_criteria
          FROM protocol_criteria
         WHERE id_protocol = i_id_protocol
           AND criteria_type = i_criteria_type;
    
        -- Delete old protocol_adv_input_value associated to criterias
        g_error := 'DELETE OLD ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_adv_input_value
         WHERE flg_type = g_adv_input_type_criterias
           AND id_adv_input_link IN
               (SELECT prot_crit_lnk.id_protocol_criteria_link
                  FROM protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                 WHERE prot_crit.id_protocol = i_id_protocol
                   AND prot_crit.criteria_type = i_criteria_type
                   AND prot_crit.id_protocol_criteria = prot_crit_lnk.id_protocol_criteria);
    
        -- Delete old criterias
        g_error := 'DELETE OLD PROTOCOL CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_criteria_link
         WHERE id_protocol_criteria_link IN
               (SELECT prot_crit_lnk.id_protocol_criteria_link
                  FROM protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                 WHERE prot_crit.id_protocol = i_id_protocol
                   AND prot_crit.criteria_type = i_criteria_type
                   AND prot_crit.id_protocol_criteria = prot_crit_lnk.id_protocol_criteria);
    
        g_error := 'SETUP NEW PROTOCOL CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        o_id_prot_criteria_link := table_number();
    
        -- Setup new criterias
        IF (i_id_link_other_criteria.count != 0)
        THEN
            l_link_crit := TRUE;
            FOR i IN i_id_link_other_criteria.first .. i_id_link_other_criteria.last
            LOOP
                l_id_protocol_criteria_link := get_protocol_crit_lnk_seq;
                o_id_prot_criteria_link.extend;
                o_id_prot_criteria_link(o_id_prot_criteria_link.last) := l_id_protocol_criteria_link;
                ibt_protocol_criteria_link(i).id_protocol_criteria_link := l_id_protocol_criteria_link;
                ibt_protocol_criteria_link(i).id_protocol_criteria := l_id_protocol_criteria;
                ibt_protocol_criteria_link(i).id_link_other_criteria := i_id_link_other_criteria(i);
                ibt_protocol_criteria_link(i).id_link_other_criteria_type := i_id_link_other_criteria_type(i);
            END LOOP;
        END IF;
        g_error := 'INSERT NEW PROTOCOL CRITERIA LINK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Insert new criterias
        BEGIN
            IF (l_link_crit)
            THEN
                FORALL i IN ibt_protocol_criteria_link.first .. ibt_protocol_criteria_link.last SAVE EXCEPTIONS
                    INSERT INTO protocol_criteria_link
                    VALUES ibt_protocol_criteria_link
                        (i);
            END IF;
        EXCEPTION
            WHEN dml_errors THEN
                RAISE dml_errors;
        END;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CRITERIA_OTHER',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CRITERIA_OTHER',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_criteria_other;
    /**
    *  Get protocol criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_CRITERIA_TYPE              Criteria Type: Inclusion / Exclusion
    
    * @param      O_PROTOCOL_CRITERIA         Cursor for protocol criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_criteria
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_criteria_type     IN protocol_criteria.criteria_type%TYPE,
        o_protocol_criteria OUT pk_types.cursor_type,
        o_error             OUT t_error_out
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
    
        l_height_um        c_unit_measure%ROWTYPE;
        l_weight_um        c_unit_measure%ROWTYPE;
        l_blood_press_s_um c_unit_measure%ROWTYPE;
        l_blood_press_d_um c_unit_measure%ROWTYPE;
    BEGIN
        g_error := 'GET DEFAULT UNIT MEASURES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
    
        g_error := 'GET PROTOCOL CRITERIA';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_criteria FOR
            SELECT prot_crit.criteria_type,
                   prot_crit.gender,
                   pk_sysdomain.get_domain(g_domain_gender, prot_crit.gender, i_lang) AS gender_desc,
                   
                   prot_crit.min_age min_age,
                   prot_crit.max_age max_age,
                   
                   l_weight_um.id_unit_measure AS unit_measure_weight_id,
                   l_weight_um.val_min AS val_min_weight,
                   l_weight_um.val_max AS val_max_weight,
                   l_weight_um.format_num AS format_num_weight,
                   l_weight_um.desc_unit_measure AS desc_weight,
                   decode(prot_crit.id_weight_unit_measure,
                          l_weight_um.id_unit_measure,
                          prot_crit.min_weight,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.min_weight,
                                                                  prot_crit.id_weight_unit_measure,
                                                                  l_weight_um.id_unit_measure)) AS min_weight,
                   
                   decode(prot_crit.id_weight_unit_measure,
                          l_weight_um.id_unit_measure,
                          prot_crit.max_weight,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.max_weight,
                                                                  prot_crit.id_weight_unit_measure,
                                                                  l_weight_um.id_unit_measure)) AS max_weight,
                   
                   prot_crit.imc_min,
                   prot_crit.imc_max,
                   
                   l_height_um.id_unit_measure AS unit_measure_height_id,
                   l_height_um.val_min AS val_min_height,
                   l_height_um.val_max AS val_max_height,
                   l_height_um.format_num AS format_num_height,
                   l_height_um.desc_unit_measure AS desc_height,
                   decode(prot_crit.id_height_unit_measure,
                          l_height_um.id_unit_measure,
                          prot_crit.min_height,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.min_height,
                                                                  prot_crit.id_height_unit_measure,
                                                                  l_height_um.id_unit_measure)) AS min_height,
                   decode(prot_crit.id_height_unit_measure,
                          l_height_um.id_unit_measure,
                          prot_crit.max_height,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.max_height,
                                                                  prot_crit.id_height_unit_measure,
                                                                  l_height_um.id_unit_measure)) AS max_height,
                   
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_allergies) AS allergies_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_allergies,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_allergies,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_analysis) AS analysis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_analysis,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_analysis,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_diagnosis) AS diagnosis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_diagnosis,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_diagnosis,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_diagnosis_nurse) AS nurse_diagnosis_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_diagnosis_nurse,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_nurse_diagnosis,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_exams) AS exams_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_exams,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_exams,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_drug) AS drug_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_drug,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_drug,
                   get_criteria_type_desc(i_lang, i_prof, g_protocol_other_exams) AS other_exams_desc,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            g_protocol_other_exams,
                                            g_bullet,
                                            g_separator2,
                                            g_available) AS desc_other_exams,
                   -- blood pressure
                   -- systolic blood pressure
                   l_blood_press_s_um.id_unit_measure AS unit_mea_blood_pressure_s_id,
                   l_blood_press_s_um.val_min AS val_min_blood_pressure_s,
                   l_blood_press_s_um.val_max AS val_max_blood_pressure_s,
                   l_blood_press_s_um.format_num AS format_num_blood_pressure_s,
                   l_blood_press_s_um.desc_unit_measure AS desc_blood_pressure_s,
                   decode(prot_crit.id_blood_pressure_unit_measure,
                          l_blood_press_s_um.id_unit_measure,
                          prot_crit.max_blood_pressure_s,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.max_blood_pressure_s,
                                                                  prot_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_s_um.id_unit_measure)) AS max_blood_pressure_s,
                   decode(prot_crit.id_blood_pressure_unit_measure,
                          l_blood_press_s_um.id_unit_measure,
                          prot_crit.min_blood_pressure_s,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.min_blood_pressure_s,
                                                                  prot_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_s_um.id_unit_measure)) AS min_blood_pressure_s,
                   -- diastolic blood pressure
                   l_blood_press_d_um.id_unit_measure AS unit_mea_blood_pressure_d_id,
                   l_blood_press_d_um.val_min AS val_min_blood_pressure_d,
                   l_blood_press_d_um.val_max AS val_max_blood_pressure_d,
                   l_blood_press_d_um.format_num AS format_num_blood_pressure_d,
                   l_blood_press_d_um.desc_unit_measure AS desc_blood_pressure_d,
                   decode(prot_crit.id_blood_pressure_unit_measure,
                          l_blood_press_d_um.id_unit_measure,
                          prot_crit.max_blood_pressure_d,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.max_blood_pressure_d,
                                                                  prot_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_d_um.id_unit_measure)) AS max_blood_pressure_d,
                   
                   decode(prot_crit.id_blood_pressure_unit_measure,
                          l_blood_press_d_um.id_unit_measure,
                          prot_crit.min_blood_pressure_d,
                          pk_unit_measure.get_unit_mea_conversion(prot_crit.min_blood_pressure_d,
                                                                  prot_crit.id_blood_pressure_unit_measure,
                                                                  l_blood_press_d_um.id_unit_measure)) AS min_blood_pressure_d
            
              FROM protocol_criteria prot_crit
             WHERE prot_crit.criteria_type = nvl(i_criteria_type, prot_crit.criteria_type)
               AND prot_crit.id_protocol = i_id_protocol;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_CRITERIA',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_criteria);
            RETURN FALSE;
    END get_protocol_criteria;
    /**
    *  Get protocol criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_CRITERIA         Cursor for protocol criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_criteria_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_criteria_all OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROTOCOL CRITERIA ALL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_criteria_all FOR
            SELECT prot_crit_lnk.id_protocol_criteria_link,
                   prot_crit.id_protocol,
                   prot_crit.criteria_type,
                   prot_crit_lnk.id_link_other_criteria,
                   prot_crit_lnk.id_link_other_criteria_type,
                   get_criteria_link_id_str(i_lang,
                                            i_prof,
                                            prot_crit.id_protocol,
                                            prot_crit.criteria_type,
                                            prot_crit_lnk.id_link_other_criteria_type,
                                            NULL,
                                            g_separator2,
                                            g_not_available,
                                            prot_crit_lnk.id_link_other_criteria) AS desc_link_other_criteria,
                   pk_translation.get_translation(i_lang, prot_crit_type.code_protocol_criteria_type) AS crit_type_desc
              FROM protocol_criteria_link prot_crit_lnk,
                   protocol_criteria      prot_crit,
                   protocol_criteria_type prot_crit_type
             WHERE id_protocol = i_id_protocol
               AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
               AND prot_crit_lnk.id_link_other_criteria_type = prot_crit_type.id_protocol_criteria_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_CRITERIA_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_criteria_all);
            RETURN FALSE;
    END get_protocol_criteria_all;

    /**
    *  Get protocol tasks
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_element_type               Task type list wanted
    * @param      O_PROTOCOL_TASK              Cursor for protocol tasks
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_task_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_element_type      IN protocol_task.task_type%TYPE,
        o_protocol_task_all OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET PROTOCOL TASK ALL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_task_all FOR
            SELECT prot_task_lnk.id_task_link,
                   get_task_id_str(i_lang,
                                   i_prof,
                                   prot_elem.id_protocol,
                                   prot_task_lnk.task_type,
                                   g_separator2,
                                   prot_task_lnk.id_task_link,
                                   prot_task_lnk.task_codification) AS desc_task,
                   prot_task_lnk.task_type,
                   pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_task_lnk.task_type, 0) AS desc_type,
                   prot_task_lnk.task_notes,
                   prot_task_lnk.id_task_attach,
                   prot_task_lnk.task_codification
              FROM protocol_task prot_task_lnk, protocol_element prot_elem
             WHERE prot_elem.id_protocol = i_id_protocol
               AND prot_task_lnk.id_group_task = prot_elem.id_element
               AND prot_elem.element_type = g_element_task
               AND prot_task_lnk.task_type = nvl(i_element_type, prot_task_lnk.task_type);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TASK_ALL',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_task_all);
            RETURN FALSE;
    END get_protocol_task_all;

    -------------------------------------------------------------
    /**
    *  set protocol element/relation
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_ELEMENT                    Element lists
    * @param      I_ELEMENT_DETAIL             Element lists
    * @param      I_ELEMENT_RELATION           Element relation lists
    * @param      O_ID_PROT_TASK               Task list
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_structure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        i_element          IN table_table_varchar,
        i_element_detail   IN table_table_varchar,
        i_element_relation IN table_table_varchar,
        o_id_prot_task     OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_protocol_element IS TABLE OF protocol_element%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_element t_protocol_element;
    
        TYPE t_protocol_relation IS TABLE OF protocol_relation%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_relation t_protocol_relation;
    
        TYPE t_protocol_connector IS TABLE OF protocol_connector%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_connector t_protocol_connector;
    
        TYPE t_protocol_text IS TABLE OF protocol_text%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_text t_protocol_text;
    
        TYPE t_protocol_question IS TABLE OF protocol_question%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_question t_protocol_question;
    
        TYPE t_protocol_task IS TABLE OF protocol_task%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_task t_protocol_task;
    
        TYPE t_protocol_protocol IS TABLE OF protocol_protocol%ROWTYPE INDEX BY BINARY_INTEGER;
        ibt_protocol_protocol t_protocol_protocol;
    
        TYPE r_record_relation IS RECORD(
            id_app NUMBER,
            id_db  NUMBER);
    
        TYPE t_record_relation IS TABLE OF r_record_relation INDEX BY BINARY_INTEGER;
        ibt_record_relation t_record_relation;
    
        l_counter_task NUMBER := 0;
        l_counter      NUMBER := 0;
    
        --        l_counter NUMBER;
    
        CURSOR c_protocol_connector(in_id_protocol NUMBER) IS
            SELECT id_protocol_connector
              FROM protocol_relation
             WHERE id_protocol = in_id_protocol;
    
        ibt_protocol_connector_aux table_number;
    
    BEGIN
    
        -- Inicialização de estrutura
        o_id_prot_task := table_number();
        -- Delete old task links
        g_error := 'DELETE OLD PROTOCOL TEXT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_text
         WHERE id_protocol_text IN
               (SELECT id_element
                  FROM protocol_element prot_elem
                 WHERE prot_elem.id_protocol = i_id_protocol
                   AND prot_elem.element_type IN (g_element_instruction, g_element_warning, g_element_header));
    
        g_error := 'DELETE OLD PROTOCOL QUESTION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_question
         WHERE id_protocol_question IN (SELECT id_element
                                          FROM protocol_element prot_elem
                                         WHERE prot_elem.id_protocol = i_id_protocol
                                           AND prot_elem.element_type = g_element_question);
    
        -- Delete old protocol_adv_input_value associated to tasks
        g_error := 'DELETE OLD ADVANCED INPUT DATA';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_adv_input_value
         WHERE flg_type = g_adv_input_type_tasks
           AND id_adv_input_link IN (SELECT prot_task.id_protocol_task
                                       FROM protocol_element prot_elem, protocol_task prot_task
                                      WHERE prot_elem.id_protocol = i_id_protocol
                                        AND prot_elem.element_type = g_element_task
                                        AND prot_task.id_group_task = prot_elem.id_element);
    
        g_error := 'DELETE OLD PROTOCOL TASK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_task
         WHERE id_group_task IN (SELECT id_element
                                   FROM protocol_element prot_elem
                                  WHERE prot_elem.id_protocol = i_id_protocol
                                    AND prot_elem.element_type = g_element_task);
    
        g_error := 'GET OLD PROTOCOL CONNECTOR IDS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Get all ID_PROTOCOL_CONNECTOR
        OPEN c_protocol_connector(i_id_protocol);
        LOOP
            FETCH c_protocol_connector BULK COLLECT
                INTO ibt_protocol_connector_aux LIMIT g_bulk_fetch_rows;
        
            EXIT WHEN c_protocol_connector%NOTFOUND;
        END LOOP;
    
        CLOSE c_protocol_connector;
    
        g_error := 'DELETE OLD PROTOCOL RELATION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_relation
         WHERE id_protocol = i_id_protocol;
    
        g_error := 'DELETE OLD PROTOCOL ELEMENT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_element
         WHERE id_protocol = i_id_protocol;
    
        g_error := 'DELETE OLD PROTOCOL CONNECTOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_connector
         WHERE id_protocol_connector IN (SELECT column_value
                                           FROM TABLE(ibt_protocol_connector_aux));
    
        g_error := 'SETUP NEW ELEMENTS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_element.count != 0)
        THEN
        
            FOR i IN i_element.first .. i_element.last
            LOOP
            
                IF (i_element(i) IS NOT NULL)
                THEN
                    ibt_protocol_element(i).id_protocol_element := get_id_protocol_element_seq;
                    ibt_protocol_element(i).id_protocol := i_id_protocol;
                    ibt_protocol_element(i).id_element := get_id_element_seq;
                    ibt_protocol_element(i).desc_element := i_element(i) (2);
                    ibt_protocol_element(i).element_type := i_element(i) (3);
                    ibt_protocol_element(i).x_coordinate := i_element(i) (4);
                    ibt_protocol_element(i).y_coordinate := i_element(i) (5);
                    ibt_protocol_element(i).flg_available := g_available;
                
                    -- Relation ids
                    ibt_record_relation(i_element(i)(1)).id_app := i_element(i) (1);
                    ibt_record_relation(i_element(i)(1)).id_db := ibt_protocol_element(i).id_protocol_element;
                
                    IF (i_element(i) (3) = g_element_task)
                    THEN
                    
                        IF (i_element_detail.count != 0)
                        THEN
                        
                            FOR j IN i_element_detail.first .. i_element_detail.last
                            LOOP
                                IF (i_element_detail(j) (1) = i_element(i) (1))
                                THEN
                                    l_counter_task := ibt_protocol_task.count + 1;
                                
                                    ibt_protocol_task(l_counter_task).id_protocol_task := get_id_protocol_task_seq;
                                    ibt_protocol_task(l_counter_task).id_group_task := ibt_protocol_element(i).id_element;
                                    ibt_protocol_task(l_counter_task).desc_protocol_task := i_element(i) (2);
                                    ibt_protocol_task(l_counter_task).id_task_link := i_element_detail(j) (2);
                                    ibt_protocol_task(l_counter_task).task_type := i_element_detail(j) (3);
                                    ibt_protocol_task(l_counter_task).task_notes := i_element_detail(j) (4);
                                    ibt_protocol_task(l_counter_task).id_task_attach := i_element_detail(j) (5);
                                    ibt_protocol_task(l_counter_task).task_codification := i_element_detail(j) (6);
                                    -- Inicialização de output com IDs de tarefas
                                    o_id_prot_task.extend;
                                    o_id_prot_task(l_counter_task) := ibt_protocol_task(l_counter_task).id_protocol_task;
                                END IF;
                            
                            END LOOP;
                        END IF;
                    
                    ELSIF (i_element(i) (3) = g_element_question)
                    THEN
                        l_counter := ibt_protocol_question.count + 1;
                        ibt_protocol_question(l_counter).id_protocol_question := ibt_protocol_element(i).id_element;
                        ibt_protocol_question(l_counter).desc_protocol_question := i_element(i) (2);
                    
                    ELSIF (i_element(i) (3) = g_element_warning OR i_element(i)
                           (3) = g_element_instruction OR i_element(i) (3) = g_element_header)
                    THEN
                        l_counter := ibt_protocol_text.count + 1;
                        ibt_protocol_text(l_counter).id_protocol_text := ibt_protocol_element(i).id_element;
                        ibt_protocol_text(l_counter).desc_protocol_text := i_element(i) (2);
                        ibt_protocol_text(l_counter).protocol_text_type := i_element(i) (3);
                    
                        IF (i_element(i) (3) = g_element_header)
                        THEN
                            UPDATE protocol
                               SET protocol_desc = i_element(i) (2)
                             WHERE id_protocol = i_id_protocol;
                        END IF;
                    ELSIF (i_element(i) (3) = g_element_protocol)
                    THEN
                        IF i_element_detail.count != 0
                        THEN
                            FOR j IN i_element_detail.first .. i_element_detail.last
                            LOOP
                                IF (i_element_detail(j) (1) = i_element(i) (1))
                                THEN
                                    l_counter := ibt_protocol_protocol.count + 1;
                                    ibt_protocol_protocol(l_counter).id_protocol_protocol := ibt_protocol_element(i).id_element;
                                    ibt_protocol_protocol(l_counter).desc_protocol_protocol := i_element(i) (2);
                                    ibt_protocol_protocol(l_counter).id_nested_protocol := i_element_detail(j) (2);
                                
                                    -- each element only has a detail
                                    EXIT;
                                END IF;
                            END LOOP;
                        END IF;
                    END IF;
                END IF;
            
            END LOOP;
        
            g_error := 'INSERT NEW ELEMENTS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            BEGIN
                FORALL i IN ibt_protocol_element.first .. ibt_protocol_element.last SAVE EXCEPTIONS
                    INSERT INTO protocol_element
                    VALUES ibt_protocol_element
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            g_error := 'INSERT NEW TASK';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            BEGIN
                FORALL i IN ibt_protocol_task.first .. ibt_protocol_task.last SAVE EXCEPTIONS
                    INSERT INTO protocol_task
                    VALUES ibt_protocol_task
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            g_error := 'INSERT NEW QUESTION';
            pk_alertlog.log_debug(g_error, g_package_name);
            BEGIN
                FORALL i IN ibt_protocol_question.first .. ibt_protocol_question.last SAVE EXCEPTIONS
                    INSERT INTO protocol_question
                    VALUES ibt_protocol_question
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            g_error := 'INSERT NEW TEXT';
            pk_alertlog.log_debug(g_error, g_package_name);
            BEGIN
                FORALL i IN ibt_protocol_text.first .. ibt_protocol_text.last SAVE EXCEPTIONS
                    INSERT INTO protocol_text
                    VALUES ibt_protocol_text
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            g_error := 'INSERT NEW NESTED PROTOCOL';
            pk_alertlog.log_debug(g_error, g_package_name);
            BEGIN
                FORALL i IN ibt_protocol_protocol.first .. ibt_protocol_protocol.last SAVE EXCEPTIONS
                    INSERT INTO protocol_protocol
                    VALUES ibt_protocol_protocol
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
        END IF;
    
        IF (i_element_relation.count != 0)
        THEN
        
            FOR i IN i_element_relation.first .. i_element_relation.last
            LOOP
            
                IF (i_element_relation(i) IS NOT NULL)
                THEN
                    -- Create relation
                    ibt_protocol_relation(i).id_protocol_relation := get_protocol_relation_seq;
                    ibt_protocol_relation(i).id_protocol := i_id_protocol;
                    g_error := 'testing';
                    ibt_protocol_relation(i).id_protocol_element_parent := ibt_record_relation(i_element_relation(i)(1)).id_db;
                    g_error := 'testing2';
                    ibt_protocol_relation(i).id_protocol_connector := get_protocol_connector_seq;
                    g_error := 'testing3';
                    ibt_protocol_relation(i).id_protocol_element := ibt_record_relation(i_element_relation(i)(2)).id_db;
                    ibt_protocol_relation(i).desc_relation := i_element_relation(i) (3);
                    ibt_protocol_relation(i).flg_available := g_available;
                
                    -- Create connector
                    ibt_protocol_connector(i).id_protocol_connector := ibt_protocol_relation(i).id_protocol_connector;
                    ibt_protocol_connector(i).desc_protocol_connector := i_element_relation(i) (3);
                    ibt_protocol_connector(i).flg_desc_protocol_connector := i_element_relation(i) (4);
                    ibt_protocol_connector(i).flg_available := g_available;
                
                END IF;
            
            END LOOP;
        
            g_error := 'INSERT NEW CONNECTORS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            BEGIN
                FORALL i IN ibt_protocol_connector.first .. ibt_protocol_connector.last SAVE EXCEPTIONS
                    INSERT INTO protocol_connector
                    VALUES ibt_protocol_connector
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        
            g_error := 'INSERT NEW RELATIONS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            BEGIN
                FORALL i IN ibt_protocol_relation.first .. ibt_protocol_relation.last SAVE EXCEPTIONS
                    INSERT INTO protocol_relation
                    VALUES ibt_protocol_relation
                        (i);
            
            EXCEPTION
                WHEN dml_errors THEN
                
                    -- FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
                    -- LOOP
                    --     dbms_output.put_line(SQL%BULK_EXCEPTIONS(j)
                    --                        .ERROR_INDEX || ', ' || SQLERRM(-sql%BULK_EXCEPTIONS(j).ERROR_CODE));
                    --
                    --END LOOP;               
                
                    RAISE dml_errors;
            END;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || '/ DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_structure;

    /**
    *  Get protocol structure
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
        
    * @param      O_PROTOCOL_ELEMENTS           Cursor for protocol elements
    * @param      O_PROTOCOL_DETAILS            Cursor for protocol elements details as tasks
    * @param      O_PROTOCOL_RELATION          Cursor for protocol relations    
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_structure
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN protocol.id_protocol%TYPE,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROTOCOL TASK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_elements FOR
            SELECT DISTINCT element_title, id_protocol_element, desc_element, element_type, x_coordinate, y_coordinate
              FROM (SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_text.desc_protocol_text AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate
                      FROM protocol_element prot_elem, protocol_text prot_text
                     WHERE prot_elem.id_element = prot_text.id_protocol_text
                       AND prot_elem.element_type IN (g_element_warning, g_element_instruction, g_element_header)
                       AND prot_elem.element_type = prot_text.protocol_text_type
                       AND prot_elem.id_protocol = i_id_protocol
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_elem.desc_element AS desc_element,
                           element_type,
                           x_coordinate,
                           y_coordinate
                      FROM protocol_element prot_elem
                      LEFT OUTER JOIN protocol_task prot_task
                        ON prot_elem.id_element = prot_task.id_group_task
                     WHERE prot_elem.element_type IN (g_element_task)
                       AND prot_elem.id_protocol = i_id_protocol
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_quest.desc_protocol_question AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate
                      FROM protocol_element prot_elem, protocol_question prot_quest
                     WHERE prot_elem.id_element = prot_quest.id_protocol_question
                       AND prot_elem.element_type IN (g_element_question)
                       AND prot_elem.id_protocol = i_id_protocol
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_elem.desc_element AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate
                      FROM protocol_element prot_elem
                      LEFT OUTER JOIN protocol_protocol prot_prot
                        ON prot_elem.id_element = prot_prot.id_protocol_protocol
                     WHERE prot_elem.element_type IN (g_element_protocol)
                       AND prot_elem.id_protocol = i_id_protocol)
             ORDER BY id_protocol_element;
    
        OPEN o_protocol_relations FOR
            SELECT prot_rel.id_protocol_element_parent,
                   prot_rel.id_protocol_element,
                   prot_rel.desc_relation,
                   prot_conn.desc_protocol_connector,
                   prot_conn.flg_desc_protocol_connector,
                   pk_sysdomain.get_domain(g_domain_prot_connector, prot_conn.flg_desc_protocol_connector, i_lang) AS desc_connector,
                   -- Faz-se get img para obter a cor, foi a unica forma encontrada de fazer isto.
                   pk_sysdomain.get_img(i_lang, g_domain_prot_connector, prot_conn.flg_desc_protocol_connector) AS color
              FROM protocol_relation prot_rel, protocol_connector prot_conn
             WHERE prot_rel.id_protocol_connector = prot_conn.id_protocol_connector
               AND prot_rel.id_protocol = i_id_protocol;
    
        OPEN o_protocol_element_details FOR
            SELECT prot_elem.id_protocol_element AS id_protocol_element,
                   prot_task.id_protocol_task AS id_element,
                   prot_task.id_task_link AS id_link,
                   prot_task.task_type AS TYPE,
                   pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_task.task_type, 0) AS desc_type,
                   prot_task.task_notes AS notes,
                   prot_task.task_codification AS codification,
                   decode(prot_task.task_type,
                          g_task_patient_education,
                          CASE prot_task.id_task_link
                              WHEN '-1' THEN
                               prot_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.id_task_link)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification) ||
                          decode(prot_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach),
                                      ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach) || ')',
                                      NULL)),
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification)) AS elem_desc,
                   prot_task.id_task_attach AS id_elem_attach
              FROM protocol_task prot_task, protocol_element prot_elem
             WHERE prot_task.id_group_task = prot_elem.id_element
               AND prot_elem.element_type = g_element_task
               AND prot_elem.id_protocol = i_id_protocol
            UNION ALL
            SELECT prot_elem.id_protocol_element AS id_protocol_element,
                   prot_prot.id_protocol_protocol AS id_element,
                   to_char(prot_prot.id_nested_protocol) AS id_link,
                   NULL AS TYPE,
                   NULL AS desc_type,
                   NULL AS notes,
                   NULL AS codification,
                   prot.protocol_desc AS elem_desc,
                   NULL AS id_elem_attach
              FROM protocol_protocol prot_prot, protocol_element prot_elem, protocol prot
             WHERE prot_prot.id_protocol_protocol = prot_elem.id_element
               AND prot_elem.element_type = g_element_protocol
               AND prot_elem.id_protocol = i_id_protocol
               AND prot_prot.id_nested_protocol = prot.id_protocol
               AND prot.flg_status = g_protocol_finished;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_STRUCTURE',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_elements);
            pk_types.open_my_cursor(o_protocol_relations);
            pk_types.open_my_cursor(o_protocol_element_details);
            RETURN FALSE;
    END get_protocol_structure;

    /**
    *  Get protocol structure
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS        Protocol ID
    * @param      i_id_episode                 ID of the current episode
    * @param      dt_server                    Date of server        
    * @param      O_PROTOCOL_ELEMENTS          Cursor for protocol elements
    * @param      O_PROTOCOL_DETAILS           Cursor for protocol elements details as tasks
    * @param      O_PROTOCOL_RELATION          Cursor for protocol relations    
    * @param      o_flg_read_only              flag with read only indication
    * @param      O_ERROR                      error
    *
    * @value      o_flg_read_only              {*} 'Y' read-only mode is on
    *                                          {*} 'N' read-only mode is off
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/08
    */
    FUNCTION get_protocol_structure_app
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process      IN protocol_process.id_protocol_process%TYPE,
        i_id_episode               IN episode.id_episode%TYPE,
        dt_server                  OUT VARCHAR2,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_flg_read_only            OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient protocol_process.id_patient%TYPE;
    BEGIN
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT id_patient
          INTO l_id_patient
          FROM protocol_process
         WHERE id_protocol_process = i_id_protocol_process;
    
        g_error := 'GET PROTOCOL TASK';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_elements FOR
            SELECT DISTINCT element_title,
                            id_protocol_element,
                            desc_element,
                            element_type,
                            x_coordinate,
                            y_coordinate,
                            flg_status,
                            flg_active
              FROM (SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_text.desc_protocol_text AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate,
                           decode(prot_proc_elem.flg_status,
                                  g_flag_active_cancelled,
                                  g_flag_active_cancelled,
                                  g_flag_active_exec) flg_status,
                           prot_proc_elem.flg_active
                      FROM protocol_element prot_elem, protocol_text prot_text, protocol_process_element prot_proc_elem
                     WHERE prot_elem.id_element = prot_text.id_protocol_text
                       AND prot_elem.element_type IN (g_element_warning, g_element_instruction, g_element_header)
                       AND prot_elem.element_type = prot_text.protocol_text_type
                       AND prot_proc_elem.id_protocol_process = i_id_protocol_process
                       AND prot_proc_elem.id_protocol_element = prot_elem.id_protocol_element
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_elem.desc_element AS desc_element,
                           prot_elem.element_type,
                           x_coordinate,
                           y_coordinate,
                           decode(prot_proc_elem.flg_status,
                                  g_flag_active_cancelled,
                                  g_flag_active_cancelled,
                                  g_flag_active_exec) flg_status,
                           prot_proc_elem.flg_active
                      FROM protocol_element prot_elem
                      LEFT OUTER JOIN protocol_task prot_task
                        ON prot_elem.id_element = prot_task.id_group_task, protocol_process_element prot_proc_elem
                     WHERE prot_elem.element_type IN (g_element_task)
                       AND prot_proc_elem.id_protocol_process = i_id_protocol_process
                       AND prot_proc_elem.id_protocol_element = prot_elem.id_protocol_element
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_quest.desc_protocol_question AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate,
                           decode(prot_proc_elem.flg_status,
                                  g_flag_active_cancelled,
                                  g_flag_active_cancelled,
                                  g_flag_active_exec) flg_status,
                           prot_proc_elem.flg_active
                      FROM protocol_element         prot_elem,
                           protocol_question        prot_quest,
                           protocol_process_element prot_proc_elem
                     WHERE prot_elem.id_element = prot_quest.id_protocol_question
                       AND prot_elem.element_type IN (g_element_question)
                       AND prot_proc_elem.id_protocol_process = i_id_protocol_process
                       AND prot_proc_elem.id_protocol_element = prot_elem.id_protocol_element
                    UNION ALL
                    SELECT pk_sysdomain.get_domain(g_domain_prot_elem, prot_elem.element_type, i_lang) AS element_title,
                           prot_elem.id_protocol_element,
                           prot_elem.desc_element AS desc_element,
                           prot_elem.element_type,
                           prot_elem.x_coordinate,
                           prot_elem.y_coordinate,
                           decode(prot_proc_elem.flg_status,
                                  g_flag_active_cancelled,
                                  g_flag_active_cancelled,
                                  g_flag_active_exec) flg_status,
                           prot_proc_elem.flg_active
                      FROM protocol_element prot_elem
                      LEFT OUTER JOIN protocol_protocol prot_prot
                        ON prot_elem.id_element = prot_prot.id_protocol_protocol, protocol_process_element
                     prot_proc_elem
                     WHERE prot_elem.element_type IN (g_element_protocol)
                       AND prot_proc_elem.id_protocol_process = i_id_protocol_process
                       AND prot_proc_elem.id_protocol_element = prot_elem.id_protocol_element);
    
        OPEN o_protocol_relations FOR
            SELECT DISTINCT prot_rel.id_protocol_element_parent,
                            prot_rel.id_protocol_element,
                            prot_rel.desc_relation,
                            prot_conn.desc_protocol_connector,
                            prot_conn.flg_desc_protocol_connector,
                            pk_sysdomain.get_domain(g_domain_prot_connector,
                                                    prot_conn.flg_desc_protocol_connector,
                                                    i_lang) AS desc_connector,
                            -- Faz-se get img para obter a cor, foi a unica forma encontrada de fazer isto.
                            pk_sysdomain.get_img(i_lang, g_domain_prot_connector, prot_conn.flg_desc_protocol_connector) AS color,
                            pk_sysdomain.get_rank(i_lang,
                                                  g_domain_prot_connector,
                                                  prot_conn.flg_desc_protocol_connector) AS rank
              FROM protocol_relation prot_rel, protocol_connector prot_conn, protocol_process_element prot_proc_elem
             WHERE prot_rel.id_protocol_connector = prot_conn.id_protocol_connector
               AND prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND (prot_rel.id_protocol_element_parent = prot_proc_elem.id_protocol_element OR
                   prot_rel.id_protocol_element = prot_proc_elem.id_protocol_element);
    
        OPEN o_protocol_element_details FOR
            SELECT prot_proc_elem.id_protocol_element,
                   prot_proc_elem.id_protocol_process_elem,
                   prot_task.id_task_link AS id_link,
                   prot_task.task_type AS TYPE,
                   pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_task.task_type, 0) AS desc_type,
                   prot_task.task_notes AS notes,
                   prot_task.task_codification AS codification,
                   decode(prot_task.task_type,
                          g_task_patient_education,
                          CASE prot_task.id_task_link
                              WHEN '-1' THEN
                               prot_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.id_task_link)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification) ||
                          decode(prot_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach),
                                      ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach) || ')',
                                      NULL)),
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification)) AS elem_desc,
                   prot_proc_elem.id_request,
                   pk_date_utils.date_send_tsz(i_lang, prot_proc_elem.dt_request, i_prof) AS dt_request,
                   prot_proc_elem.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, prot_proc_elem.dt_status, i_prof) AS dt_status,
                   
                   '0' || '|' || pk_date_utils.date_send_tsz(i_lang,
                                                             decode(flg_status,
                                                                    g_process_scheduled,
                                                                    (SELECT dvalue
                                                                       FROM protocol_process_task_det prot_proc_task_det
                                                                      WHERE prot_proc_task_det.id_protocol_process_elem =
                                                                            prot_proc_elem.id_protocol_process_elem
                                                                        AND prot_proc_task_det.flg_detail_type =
                                                                            g_proc_task_det_next_rec),
                                                                    g_process_running,
                                                                    dt_request,
                                                                    dt_status),
                                                             i_prof) --'xxxxxxxxxxxxxx'
                   || '|' || decode(flg_status,
                                    g_process_running,
                                    decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                                           g_scheduled,
                                           g_text,
                                           g_date),
                                    g_process_scheduled,
                                    g_text_icon,
                                    g_process_finished,
                                    g_text_icon,
                                    g_icon) || '|' ||
                   decode(pk_sysdomain.get_img(i_lang, g_domain_flg_protocol_elem, flg_status),
                          g_alert_icon,
                          decode(flg_status, g_process_scheduled, g_green_color, g_red_color),
                          g_waiting_icon,
                          g_red_color,
                          decode(flg_status,
                                 g_process_running,
                                 decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                                        g_scheduled,
                                        g_green_color,
                                        NULL),
                                 NULL)) || '|' ||
                   decode(flg_status,
                          g_process_running,
                          decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                                 g_scheduled,
                                 pk_message.get_message(i_lang, g_message_scheduled),
                                 NULL),
                          pk_sysdomain.get_img(i_lang, g_domain_flg_protocol_elem, flg_status)) || '|' ||
                   decode(flg_status,
                          g_process_scheduled,
                          pk_date_utils.get_elapsed_tsz_years(i_lang,
                                                              (SELECT dvalue
                                                                 FROM protocol_process_task_det prot_proc_task_det
                                                                WHERE prot_proc_task_det.id_protocol_process_elem =
                                                                      prot_proc_elem.id_protocol_process_elem
                                                                  AND prot_proc_task_det.flg_detail_type =
                                                                      g_proc_task_det_next_rec)),
                          pk_date_utils.dt_chr_year_short_tsz(i_lang,
                                                              decode(flg_status, g_process_running, dt_request, dt_status),
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
                                         AND etg.id_exam = safe_to_number(prot_task.id_task_link)))
                             AND get_task_avail(i_lang,
                                                i_prof,
                                                task_type,
                                                prot_task.id_task_link,
                                                prot_task.id_task_attach,
                                                i_id_episode) = g_available THEN
                         g_available
                    -- if the task is not executed yet, check task permissions and availability
                        WHEN task_type != g_task_img
                             AND flg_status IN (g_process_pending, g_process_recommended, g_process_suspended)
                             AND check_task_permissions(i_lang, i_prof, task_type) = g_available
                             AND get_task_avail(i_lang,
                                                i_prof,
                                                task_type,
                                                prot_task.id_task_link,
                                                prot_task.id_task_attach,
                                                i_id_episode) = g_available THEN
                        
                         g_available
                    -- if the task is ongoing, check just check task availability
                        WHEN task_type != g_task_img
                             AND flg_status NOT IN (g_process_pending, g_process_recommended)
                             AND check_task_permissions(i_lang, i_prof, task_type) = g_available THEN
                         g_available
                        ELSE
                         g_not_available
                    END) AS flg_avail
              FROM protocol_task prot_task, protocol_process_element prot_proc_elem
             WHERE prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
               AND prot_proc_elem.element_type = g_element_task
               AND prot_proc_elem.id_protocol_process = i_id_protocol_process
            UNION ALL
            SELECT prot_proc_elem.id_protocol_element,
                   prot_proc_elem.id_protocol_process_elem,
                   to_char(prot_proc_elem.id_protocol_process_link) AS id_link,
                   NULL AS TYPE,
                   NULL AS desc_type,
                   NULL AS notes,
                   NULL AS codification,
                   prot.protocol_desc AS elem_desc,
                   prot_proc_elem.id_request,
                   pk_date_utils.date_send_tsz(i_lang, prot_proc_elem.dt_request, i_prof) AS dt_request,
                   prot_proc_elem.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, prot_proc_elem.dt_status, i_prof) AS dt_status,
                   
                   '0' || '|' || pk_date_utils.date_send_tsz(i_lang, prot_proc_elem.dt_status, i_prof) --'xxxxxxxxxxxxxx'
                   || '|' || decode(prot_proc_elem.flg_status, g_process_finished, g_text_icon, g_icon) || '|' ||
                   decode(pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, prot_proc_elem.flg_status),
                          g_alert_icon,
                          decode(prot_proc_elem.flg_status, g_process_scheduled, g_green_color, g_red_color),
                          g_waiting_icon,
                          g_red_color,
                          NULL) || '|' ||
                   pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, prot_proc_elem.flg_status) || '|' ||
                   pk_date_utils.dt_chr_year_short_tsz(i_lang, prot_proc_elem.dt_status, i_prof) AS status,
                   
                   g_available flg_soft_avail
              FROM protocol_protocol        prot_prot,
                   protocol_element         prot_elem,
                   protocol_process_element prot_proc_elem,
                   protocol                 prot
             WHERE prot_elem.id_protocol_element = prot_proc_elem.id_protocol_element
               AND prot_elem.id_element = prot_prot.id_protocol_protocol
               AND prot_proc_elem.element_type = g_element_protocol
               AND prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND prot_prot.id_nested_protocol = prot.id_protocol
               AND prot_proc_elem.id_protocol_process_link IS NOT NULL;
    
        -- return server time as close as possible to the end of function 
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        -- check "read-only" mode for this professional
        o_flg_read_only := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_intern_name => pk_access.g_view_only_profile);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_STRUCTURE_APP',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_elements);
            pk_types.open_my_cursor(o_protocol_relations);
            pk_types.open_my_cursor(o_protocol_element_details);
            RETURN FALSE;
    END get_protocol_structure_app;

    /**
    *  Set protocol context
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    
    
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
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION set_protocol_context
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_protocol               IN protocol.id_protocol%TYPE,
        i_context_desc              IN protocol.context_desc%TYPE,
        i_context_title             IN protocol.context_title%TYPE,
        i_context_ebm               IN protocol.id_ebm%TYPE,
        i_context_adaptation        IN protocol.context_adaptation%TYPE,
        i_context_type_media        IN protocol.context_type_media%TYPE,
        i_context_editor            IN protocol.context_editor%TYPE,
        i_context_edition_site      IN protocol.context_edition_site%TYPE,
        i_context_edition           IN protocol.context_edition%TYPE,
        i_dt_context_edition        IN protocol.dt_context_edition%TYPE,
        i_context_access            IN protocol.context_access%TYPE,
        i_id_context_language       IN protocol.id_context_language%TYPE,
        i_context_subtitle          IN protocol.context_subtitle%TYPE,
        i_id_context_assoc_language IN protocol.id_context_associated_language%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE PROTOCOL CONTEXT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Update protocol context
        UPDATE protocol
           SET context_desc                   = i_context_desc,
               context_title                  = i_context_title,
               id_ebm                         = i_context_ebm,
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
         WHERE id_protocol = i_id_protocol
           AND flg_status = g_protocol_temp;
    
        g_error := 'SETUP NEW PROTOCOL CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CONTEXT',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_context;

    /**
    *  Get protocol context
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_CONTEXT          Cursor for protocol context
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_context
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        o_protocol_context OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROTOCOL CONTEXT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_context FOR
            SELECT prot.context_desc,
                   prot.context_title,
                   prot.id_ebm,
                   pk_translation.get_translation(i_lang, prot_ebm.code_ebm) AS desc_ebm,
                   prot.context_adaptation,
                   prot.context_type_media,
                   pk_sysdomain.get_domain(g_domain_type_media, prot.context_type_media, i_lang) AS type_media_desc,
                   get_context_author_str(i_lang, i_prof, prot.id_protocol, g_separator2) AS author_desc,
                   prot.context_editor,
                   prot.context_edition_site,
                   prot.context_edition,
                   pk_date_utils.date_send(i_lang, prot.dt_context_edition, i_prof) AS dt_context_edition,
                   prot.context_access,
                   prot.id_context_language,
                   pk_sysdomain.get_domain(g_domain_language, prot.id_context_language, i_lang) AS orig_desc,
                   prot.flg_context_image,
                   get_image_str(i_lang, i_prof, prot.id_protocol, g_separator) AS desc_image,
                   prot.context_subtitle,
                   prot.id_context_associated_language,
                   pk_sysdomain.get_domain(g_domain_language, prot.id_context_associated_language, i_lang) AS assoc_desc
              FROM protocol prot, LANGUAGE lan1, LANGUAGE lan2, ebm prot_ebm
             WHERE prot.id_protocol = i_id_protocol
               AND prot.id_context_language = lan1.id_language(+)
               AND prot.id_context_associated_language = lan2.id_language(+)
               AND prot.id_ebm = prot_ebm.id_ebm(+);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CONTEXT',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_context);
            RETURN FALSE;
    END get_protocol_context;

    /**
    *  Set protocol context authors
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_CONTEXT_AUTHOR_LAST_NAME   Context author last name
    * @param      I_CONTEXT_AUTHOR_FIRST_NAME  Context author first name
    * @param      I_CONTEXT_AUTHOR_TITLE       Context author title
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION set_protocol_context_author
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_protocol               IN protocol.id_protocol%TYPE,
        i_context_author_last_name  IN table_varchar,
        i_context_author_first_name IN table_varchar,
        i_context_author_title      IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_protocol_context_author IS TABLE OF protocol_context_author%ROWTYPE INDEX BY BINARY_INTEGER;
    
        ibt_protocol_context_author t_protocol_context_author;
        count_author                PLS_INTEGER;
    BEGIN
        ---------------
        g_error := 'SET AUTHOR';
        pk_alertlog.log_debug(g_error, g_package_name);
        count_author := i_context_author_first_name.count;
    
        -- Delete old criterias
        g_error := 'DELETE OLD AUTHORS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        DELETE FROM protocol_context_author
         WHERE id_protocol = i_id_protocol;
    
        g_error := 'SETUP NEW AUTHORS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (count_author != 0)
        THEN
        
            FOR i IN i_context_author_first_name.first .. i_context_author_first_name.last
            LOOP
                ibt_protocol_context_author(i).id_protocol_context_author := get_protocol_ctx_author_seq;
                ibt_protocol_context_author(i).id_protocol := i_id_protocol;
                ibt_protocol_context_author(i).first_name := i_context_author_first_name(i);
                ibt_protocol_context_author(i).last_name := i_context_author_last_name(i);
                ibt_protocol_context_author(i).title := i_context_author_title(i);
            
            END LOOP;
        
            g_error := 'INSERT NEW PROTOCOL CONTEXT AUTHOR';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            BEGIN
                FORALL i IN ibt_protocol_context_author.first .. ibt_protocol_context_author.last SAVE EXCEPTIONS
                    INSERT INTO protocol_context_author
                    VALUES ibt_protocol_context_author
                        (i);
            EXCEPTION
                WHEN dml_errors THEN
                    RAISE dml_errors;
            END;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CONTEXT_AUTHOR',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CONTEXT_AUTHOR',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_context_author;

    /**
    *  Get protocol context authors
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      O_PROTOCOL_CONTEXT_AUTHOR          Cursor for protocol context
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_context_author
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_protocol             IN protocol.id_protocol%TYPE,
        o_protocol_context_author OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET PROTOCOL CONTEXT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_context_author FOR
            SELECT first_name, last_name, title
              FROM protocol_context_author prot_ctx_auth
             WHERE prot_ctx_auth.id_protocol = i_id_protocol;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_CONTEXT_AUTHOR',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_context_author);
            RETURN FALSE;
    END get_protocol_context_author;

    /**
    *  Sets a protocol as definitive
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               ID of protocol to set as final
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_prev_protocol protocol.id_protocol%TYPE;
    
        CURSOR c_prot_depends(in_id_nested_protocol protocol_protocol.id_nested_protocol%TYPE) IS
            SELECT prot_elem.id_protocol AS id_protocol_depend
              FROM protocol_protocol prot_prot, protocol_element prot_elem, protocol prot
             WHERE prot.flg_status = g_protocol_finished
               AND prot_elem.id_protocol = prot.id_protocol
               AND prot_elem.element_type = g_element_protocol
               AND prot_elem.id_element = prot_prot.id_protocol_protocol
               AND prot_prot.id_nested_protocol = in_id_nested_protocol;
    
        l_new_protocol_dependency_id protocol.id_protocol%TYPE;
    
        error_update_dependent_prots EXCEPTION;
    BEGIN
        g_error := 'UPDATE PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- set protocol finished
        UPDATE protocol
           SET flg_status = g_protocol_finished
         WHERE id_protocol = i_id_protocol
           AND flg_status = g_protocol_temp
        RETURNING id_protocol_previous_version INTO l_id_prev_protocol;
    
        -- update protocols that have this protocol nested
        FOR rec IN c_prot_depends(l_id_prev_protocol)
        LOOP
            -- edit dependent protocol
            IF (NOT create_protocol(i_lang,
                                    i_prof,
                                    rec.id_protocol_depend,
                                    g_not_duplicate_protocol,
                                    l_new_protocol_dependency_id,
                                    
                                    o_error))
            THEN
                RAISE error_update_dependent_prots;
            END IF;
        
            -- update nested protocol ID
            UPDATE protocol_protocol
               SET id_nested_protocol = i_id_protocol
             WHERE id_protocol_protocol IN (SELECT id_protocol_protocol
                                              FROM protocol_element prot_elem, protocol_protocol prot_prot
                                             WHERE id_protocol = l_new_protocol_dependency_id
                                               AND element_type = g_element_protocol
                                               AND prot_elem.id_element = prot_prot.id_protocol_protocol
                                               AND id_nested_protocol = l_id_prev_protocol);
        
            -- set modifications
            IF (NOT set_protocol(i_lang, i_prof, l_new_protocol_dependency_id, o_error))
            THEN
                RAISE error_update_dependent_prots;
            END IF;
        END LOOP;
    
        -- update protocol ID on protocol_frequent table
        UPDATE protocol_frequent
           SET id_protocol = i_id_protocol
         WHERE id_protocol = l_id_prev_protocol;
    
        -- update status of previous protocol
        UPDATE protocol
           SET flg_status     = g_protocol_deprecated, --g_protocol_deleted
               id_prof_cancel = i_prof.id,
               dt_cancel      = current_timestamp
         WHERE id_protocol = l_id_prev_protocol
           AND flg_status = g_protocol_finished;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        -- Error on update dependent protocols
        WHEN error_update_dependent_prots THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' | COULD NOT UPDATE DEPENDENT PROTOCOLS',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
            -- Error on process creation    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol;

    /** 
    *  Check if it is possible to cancel a protocol process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS        Protocol process ID
    *
    * @return     VARCHAR2:                    'Y': protocol can be canceled, 'N' protocol cannot be canceled
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_cancel_protocol_proc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_val_count PLS_INTEGER;
    
    BEGIN
    
        g_error := 'CHECK CANCEL PROTOCOL PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- verify if this protocol has tasks that cannot be canceled by this user
        SELECT COUNT(1)
          INTO l_ret_val_count
          FROM protocol_process_element ppe, protocol_task pt
         WHERE ppe.id_protocol_process = i_id_protocol_process
           AND ppe.flg_status NOT IN (g_process_pending, g_process_recommended)
           AND ppe.element_type = g_element_task
           AND ppe.id_protocol_task = pt.id_protocol_task
           AND (check_task_permissions(i_lang, i_prof, pt.task_type) = g_not_available OR
               check_task_type_soft_inst(i_lang, i_prof, pt.task_type) = g_not_available);
    
        -- check result
        IF (l_ret_val_count = 0)
        THEN
            RETURN g_available;
        END IF;
    
        RETURN g_not_available;
    
    END check_cancel_protocol_proc;

    /**
    *  Cancel protocol / mark as deleted
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL      ID of protocol.
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_protocol(in_id_protocol NUMBER) IS
            SELECT id_protocol, flg_status
              FROM protocol
             WHERE id_protocol = in_id_protocol;
    
        l_protocol c_protocol%ROWTYPE;
        error_undefined_status EXCEPTION;
    BEGIN
        g_error := 'FETCH PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
        -- Checks if protocol is temp or definitive.
        OPEN c_protocol(i_id_protocol);
    
        FETCH c_protocol
            INTO l_protocol;
    
        CLOSE c_protocol;
    
        g_error := 'VERIFY STATE OF PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (l_protocol.flg_status = g_protocol_temp)
        THEN
        
            g_error := 'DELETE ADVANCED INPUT CRITERIAS DATA';
            pk_alertlog.log_debug(g_error, 'PK_PROTOCOL');
        
            DELETE FROM protocol_adv_input_value
             WHERE flg_type = g_adv_input_type_criterias
               AND id_adv_input_link IN (SELECT a.id_protocol_criteria_link
                                           FROM protocol_criteria_link a, protocol_criteria b
                                          WHERE b.id_protocol = i_id_protocol
                                            AND a.id_protocol_criteria = b.id_protocol_criteria);
        
            g_error := 'DELETE CRITERIA LINK';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_criteria_link
             WHERE id_protocol_criteria_link IN
                   (SELECT a.id_protocol_criteria_link
                      FROM protocol_criteria_link a, protocol_criteria b
                     WHERE b.id_protocol = i_id_protocol
                       AND a.id_protocol_criteria = b.id_protocol_criteria);
        
            g_error := 'DELETE CRITERIA';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_criteria
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE ADVANCED INPUT TASKS DATA';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_adv_input_value
             WHERE flg_type = g_adv_input_type_tasks
               AND id_adv_input_link IN (SELECT id_protocol_task
                                           FROM protocol_task prot_task, protocol_element prot_elem
                                          WHERE prot_task.id_protocol_task = prot_elem.id_element
                                            AND prot_elem.element_type = g_element_task
                                            AND prot_elem.id_protocol = i_id_protocol);
        
            g_error := 'DELETE TASK';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_task
             WHERE id_group_task IN (SELECT id_group_task
                                       FROM protocol_task prot_task, protocol_element prot_elem
                                      WHERE prot_task.id_group_task = prot_elem.id_element
                                        AND prot_elem.element_type = g_element_task
                                        AND prot_elem.id_protocol = i_id_protocol);
        
            g_error := 'DELETE QUESTION';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_question
             WHERE id_protocol_question IN (SELECT id_protocol_question
                                              FROM protocol_question prot_quest, protocol_element prot_elem
                                             WHERE prot_quest.id_protocol_question = prot_elem.id_element
                                               AND prot_elem.element_type = g_element_question
                                               AND prot_elem.id_protocol = i_id_protocol);
        
            g_error := 'DELETE TEXT';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_text
             WHERE id_protocol_text IN
                   (SELECT id_protocol_text
                      FROM protocol_text prot_text, protocol_element prot_elem
                     WHERE prot_text.id_protocol_text = prot_elem.id_element
                       AND prot_elem.element_type IN (g_element_warning, g_element_instruction, g_element_header)
                       AND prot_elem.id_protocol = i_id_protocol);
        
            g_error := 'DELETE NESTED PROTOCOL';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_protocol
             WHERE id_protocol_protocol IN (SELECT id_protocol_protocol
                                              FROM protocol_protocol prot_prot, protocol_element prot_elem
                                             WHERE prot_prot.id_protocol_protocol = prot_elem.id_element
                                               AND prot_elem.element_type = g_element_protocol
                                               AND prot_elem.id_protocol = i_id_protocol);
        
            g_error := 'DELETE RELATION';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_relation
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE CONNECTOR';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_connector
             WHERE id_protocol_connector IN (SELECT id_protocol_connector
                                               FROM protocol_relation
                                              WHERE id_protocol = i_id_protocol);
        
            g_error := 'DELETE ELEMENT';
            pk_alertlog.log_debug(g_error, g_package_name);
            DELETE FROM protocol_element
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE LINK';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_link
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE CONTEXT IMAGE';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_context_image
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE CONTEXT AUTHOR';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol_context_author
             WHERE id_protocol = i_id_protocol;
        
            g_error := 'DELETE TEMP PROTOCOL';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            DELETE FROM protocol
             WHERE id_protocol = i_id_protocol
               AND flg_status = g_protocol_temp;
        
        ELSIF (l_protocol.flg_status = g_protocol_finished)
        THEN
            g_error := 'DELETE CLOSED PROTOCOL';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            UPDATE protocol
               SET flg_status = g_protocol_deleted, id_prof_cancel = i_prof.id, dt_cancel = current_timestamp
             WHERE id_protocol = i_id_protocol
               AND flg_status = g_protocol_finished;
        ELSE
            RAISE error_undefined_status;
            -- error message will have to be added here
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined_status THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state for FLG_STATUS',
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_protocol;

    /** 
    *  Get protocol task types to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_TASKS     List of tasks to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/29
    */
    FUNCTION get_protocol_task_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_tasks OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET PROTOCOL ITEMS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_tasks FOR
            SELECT DISTINCT prot_item.item AS data,
                            pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_item.item, 0) AS label
              FROM (SELECT item,
                           first_value(prot_item.flg_available) over(PARTITION BY prot_item.item ORDER BY prot_item.id_market DESC, prot_item.id_institution DESC, prot_item.id_software DESC, prot_item.flg_available) AS flg_avail
                      FROM protocol_item_soft_inst prot_item
                     WHERE prot_item.id_institution IN (g_all_institution, i_prof.institution)
                       AND prot_item.id_software IN (g_all_software, i_prof.software)
                       AND prot_item.id_market IN (g_all_markets, l_market)
                       AND prot_item.flg_item_type = g_protocol_item_tasks) prot_item
             WHERE flg_avail = g_available
                  -- verify if professional category has permissions to add this type of task
               AND check_task_permissions(i_lang, i_prof, prot_item.item) = g_available
             ORDER BY label;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TASK_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_tasks);
            RETURN FALSE;
    END get_protocol_task_type_list;

    /**
    *  Get multichoice for protocol types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_TYPE              Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_type FOR
            SELECT id_protocol_type,
                   rank,
                   desc_protocol_type,
                   decode(id_protocol_type,
                          -1,
                          decode(COUNT(1) over(ORDER BY rank RANGE BETWEEN unbounded preceding AND unbounded following) -
                                 SUM(decode(flg_select, g_selected, 1, 0))
                                 over(ORDER BY decode(flg_select, g_selected, 1, 0) RANGE BETWEEN unbounded
                                      preceding AND unbounded following),
                                 1,
                                 g_selected,
                                 flg_select),
                          flg_select) AS flg_select
              FROM (SELECT prot_typ.id_protocol_type,
                           2 rank,
                           pk_translation.get_translation(i_lang, prot_typ.code_protocol_type) desc_protocol_type,
                           decode(b.id_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM protocol_type prot_typ,
                           (SELECT id_link
                              FROM protocol_link prot_lnk_typ, protocol prot
                             WHERE prot.id_protocol(+) = i_id_protocol
                               AND prot_lnk_typ.id_protocol = prot.id_protocol
                               AND prot_lnk_typ.link_type(+) = g_protocol_link_type) b
                     WHERE prot_typ.flg_available = g_available
                       AND prot_typ.id_protocol_type = b.id_link(+)
                    UNION ALL
                    SELECT -1 id_protocol_type,
                           1 rank,
                           pk_message.get_message(i_lang, g_all) desc_protocol_type,
                           g_not_selected flg_select
                      FROM dual)
             ORDER BY rank, desc_protocol_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_type);
            RETURN FALSE;
    END get_protocol_type_list;

    /**
    *  Get multichoice for environment
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_ENVIRONMENT       Cursor with all environment availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_environment_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_protocol          IN protocol.id_protocol%TYPE,
        o_protocol_environment OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_environment FOR
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
                                    decode(prot_lnk.id_protocol_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM dept               d,
                           department         dep,
                           dep_clin_serv      dcs,
                           prof_dep_clin_serv pdcs,
                           software_dept      sd,
                           protocol_link      prot_lnk
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
                       AND prot_lnk.id_link(+) = d.id_dept
                       AND prot_lnk.id_protocol(+) = i_id_protocol
                       AND prot_lnk.link_type(+) = g_protocol_link_envi
                    UNION ALL
                    SELECT -1 id_dept, 1 rank, pk_message.get_message(i_lang, g_all) desc_dep, g_not_selected flg_select
                      FROM dual)
             ORDER BY rank, desc_dep;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_ENVIRONMENT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_environment);
            RETURN FALSE;
    END get_protocol_environment_list;
    /**
    *  Get multichoice for specialty
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_SPECIALTY         Cursor with all specialty available
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION get_protocol_specialty_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol        IN protocol.id_protocol%TYPE,
        o_protocol_specialty OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_specialty FOR
        
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
                                   decode(prot_lnk.id_protocol_link, NULL, g_not_selected, g_selected) AS flg_select
                              FROM speciality d, protocol_link prot_lnk
                             WHERE d.flg_available = g_available
                               AND prot_lnk.id_link(+) = d.id_speciality
                               AND prot_lnk.id_protocol(+) = i_id_protocol
                               AND prot_lnk.link_type(+) = g_protocol_link_spec
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
                                            decode(prot_lnk.id_protocol_link, NULL, g_not_selected, g_selected) AS flg_select
                              FROM dep_clin_serv    dcs,
                                   department       dep,
                                   dept,
                                   clinical_service cs,
                                   software_dept    soft_dep,
                                   protocol_link    prot_lnk
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
                               AND prot_lnk.id_link(+) = cs.id_clinical_service
                               AND prot_lnk.id_protocol(+) = i_id_protocol
                               AND prot_lnk.link_type(+) = g_protocol_link_spec
                               AND i_prof.software IN
                                   (pk_alert_constant.g_soft_primary_care, pk_alert_constant.g_soft_home_care)
                             ORDER BY desc_speciality)
                    UNION ALL
                    SELECT -1 id_speciality,
                           1 rank,
                           pk_message.get_message(i_lang, g_all) desc_speciality,
                           'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_speciality;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_SPECIALTY_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_specialty);
            RETURN FALSE;
    END get_protocol_specialty_list;
    /**
    *  Get multichoice for professional
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_PROFESSIONAL      Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_professional FOR
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
                           decode(prot_lnk.id_protocol_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM category d, protocol_link prot_lnk
                     WHERE d.flg_available = g_available
                       AND d.flg_prof = g_available
                       AND d.flg_clinical = g_available
                       AND d.flg_type IN (pk_alert_constant.g_cat_type_doc,
                                          pk_alert_constant.g_cat_type_nurse,
                                          pk_alert_constant.g_cat_type_nutritionist)
                       AND prot_lnk.id_link(+) = d.id_category
                       AND prot_lnk.id_protocol(+) = i_id_protocol
                       AND prot_lnk.link_type(+) = g_protocol_link_prof
                    UNION ALL
                    SELECT -1 id_category, 1 rank, pk_message.get_message(i_lang, g_all) desc_category, 'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_category;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_professional);
            RETURN FALSE;
    END get_protocol_prof_list;
    /** 
    *  Get multichoice for professionals that will be able to edit protocols
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol
    * @param      O_PROTOCOL_PROFESSIONAL     Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_protocol_edit_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_professional FOR
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
                           decode(prot_lnk.id_protocol_link, NULL, g_not_selected, g_selected) AS flg_select
                      FROM category d, protocol_link prot_lnk
                     WHERE d.flg_available = g_available
                       AND d.flg_prof = g_available
                       AND d.flg_clinical = g_available
                       AND d.flg_type IN (pk_alert_constant.g_cat_type_doc,
                                          pk_alert_constant.g_cat_type_nurse,
                                          pk_alert_constant.g_cat_type_nutritionist)
                       AND prot_lnk.id_link(+) = d.id_category
                       AND prot_lnk.id_protocol(+) = i_id_protocol
                       AND prot_lnk.link_type(+) = g_protocol_link_edit_prof
                    UNION ALL
                    SELECT -1 id_category, 1 rank, pk_message.get_message(i_lang, g_all) desc_category, 'N' flg_select
                      FROM dual)
             ORDER BY rank, desc_category;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_EDIT_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_professional);
            RETURN FALSE;
    END get_protocol_edit_prof_list;

    /** 
    *  Get multichoice for types of protocol recommendation
    *
    * @param      I_LANG                  Prefered language ID for this professional
    * @param      I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_REC_MODE     Cursor with types of recommendation
    * @param      O_ERROR                 Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_protocol_type_rec_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_protocol_type_rec OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_type_rec FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_flg_type_rec
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_available
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TYPE_REC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_type_rec);
            RETURN FALSE;
    END get_protocol_type_rec_list;
    /**
    *  Get multichoice for EBM
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               ID of protocol.
    * @param      O_PROTOCOL_EBM              Cursor with all EBM values availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_ebm_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_protocol_ebm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_ebm FOR
            SELECT prot_ebm.id_ebm,
                   2 rank,
                   pk_translation.get_translation(i_lang, prot_ebm.code_ebm) desc_ebm,
                   decode(prot.id_ebm, NULL, g_not_selected, g_selected) AS flg_select
              FROM protocol prot, ebm prot_ebm
             WHERE prot.id_protocol(+) = i_id_protocol
               AND prot.id_ebm(+) = prot_ebm.id_ebm
             ORDER BY rank, desc_ebm;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_EBM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_ebm);
            RETURN FALSE;
    END get_protocol_ebm_list;

    /**
    *  Get multichoice for Gender
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_CRITERIA_TYPE              Criteria Type : I- Incusion E - Exclusion
    * @param      O_PROTOCOL_GENDER           Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_gender_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_criteria_type   IN protocol_criteria.criteria_type%TYPE,
        o_protocol_gender OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_gender FOR
            SELECT val, desc_val
              FROM (SELECT val, desc_val, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_gender
                       AND domain_owner = pk_sysdomain.k_default_schema
                    UNION ALL
                    SELECT NULL, desc_val, -1 AS rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_inc_gen
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_criteria_type = g_criteria_type_inc
                    UNION ALL
                    SELECT NULL, desc_val, -1 AS rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND code_domain = g_domain_exc_gen
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND i_criteria_type = g_criteria_type_exc)
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GENDER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_gender);
            RETURN FALSE;
    END get_gender_list;

    /**
    *  Get multichoice for type of media
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_TM               Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_type_media_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_protocol_tm OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_tm FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_domain_type_media
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_available
             ORDER BY desc_val, rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TYPE_MEDIA_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_tm);
            RETURN FALSE;
    END get_type_media_list;

    /**
    *  Get multichoice for protocol edit options
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_OPTIONS                    Cursor with all options
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_edit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN O_OPTIONS FOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_options FOR
            SELECT g_edit_protocol_option data, pk_message.get_message(i_lang, g_message_edit_protocol) label
              FROM dual
            UNION ALL
            SELECT g_duplicate_protocol_option data, pk_message.get_message(i_lang, g_message_duplicate_protocol) label
              FROM dual
            UNION ALL
            SELECT g_create_protocol_option data, pk_message.get_message(i_lang, g_message_create_protocol) label
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_EDIT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_options);
            RETURN FALSE;
    END get_protocol_edit_list;

    /**
    *  Get multichoice for languages
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_LANGUAGES                  Cursor with all languages
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
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
    
        g_error := 'OPEN O_LANGUAGES FOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_languages FOR
            SELECT to_number(val) data,
                   desc_val label,
                   decode(val, l_default_language, 'Y', 'N') flg_select,
                   9 order_field
              FROM sys_domain s
             WHERE s.code_domain = g_domain_language
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.flg_available = g_available
               AND s.id_language = i_lang
             ORDER BY label, rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LANGUAGE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_languages);
            RETURN FALSE;
    END get_language_list;

    /**
    *  Get title list for professionals
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      O_TITLE                      Title cursor
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
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
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_TITLE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_title);
            RETURN FALSE;
    END get_prof_title_list;

    /** 
    *  Get frequency list for protocol tasks
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_FREQ     Frequencies cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_protocol_task_freq_list
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
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND flg_available = g_available
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_TASK_FREQ_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_freq);
            RETURN FALSE;
    END get_protocol_task_freq_list;

    /** 
    *  Get status list for allergy criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
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
              FROM (SELECT val AS data, desc_val AS label, rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_allergy_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                       AND val NOT IN (pk_problems.g_pat_probl_cancel) -- CANCELADO NÃO DEVEM APARECER
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data,
                           pk_message.get_message(i_lang, g_message_any) AS label,
                           -1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALLERGY_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_allergy_status_list;

    /** 
    *  Get reactions list for allergy criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_REACTS   Reactions cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
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
              FROM (SELECT val AS data, desc_val AS label, rank
                      FROM sys_domain
                     WHERE id_language = i_lang
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND flg_available = g_available
                       AND code_domain = g_domain_allergy_type
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data,
                           pk_message.get_message(i_lang, g_message_any) AS label,
                           -1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALLERGY_REACT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_reacts);
            RETURN FALSE;
    END get_allergy_react_list;

    /** 
    *  Get status list for diagnose criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
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
              FROM (SELECT val AS data, desc_val AS label, rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                       AND val NOT IN (g_pat_probl_not_capable, pk_problems.g_pat_probl_cancel) -- INCAPACITANTE E CANCELADO NÃO DEVEM APARECER
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data,
                           pk_message.get_message(i_lang, g_message_any) AS label,
                           -1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIAGNOSE_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_diagnose_status_list;

    /** 
    *  Get natures list for diagnose criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_NATURES  Natures cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
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
              FROM (SELECT val AS data, desc_val AS label, rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_diagnosis_nature
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND flg_available = g_available
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data,
                           pk_message.get_message(i_lang, g_message_any) AS label,
                           -1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIAGNOSE_NATURE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_natures);
            RETURN FALSE;
    END get_diagnose_nature_list;

    /** 
    *  Get status list for nurse diagnosis criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
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
              FROM (SELECT val AS data, desc_val AS label, rank
                      FROM sys_domain
                     WHERE code_domain = g_domain_nurse_diag_status
                       AND domain_owner = pk_sysdomain.k_default_schema
                       AND id_language = i_lang
                       AND val IN (g_nurse_active, g_nurse_solved) -- DEVEM APARECER APENAS OS ESTADOS ACTIVO e RESOLVIDO
                       AND flg_available = g_available
                    UNION ALL
                    SELECT to_char(g_detail_any) AS data,
                           pk_message.get_message(i_lang, g_message_any) AS label,
                           -1 rank
                      FROM dual)
             ORDER BY rank, label;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NURSE_DIAG_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_nurse_diag_status_list;

    /** 
    *  Get connector options
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/16
    */
    FUNCTION get_connector_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_status FOR
            SELECT val, desc_val AS label, img_name AS color, rank
              FROM sys_domain
             WHERE code_domain = g_domain_prot_connector
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND flg_available = g_available
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONNECTOR_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_connector_list;

    /**
    *  Checks difference between number of allergies and criteria allergy choosen
    *
    * @param      i_prof                      professional structure id
    * @param      i_id_protocol               protocol id
    * @param      i_id_allergy                allergy id
    * @param      i_market                    allergies default market    
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_allergies
    (
        i_prof        profissional,
        i_id_protocol protocol.id_protocol%TYPE,
        i_id_allergy  allergy.id_allergy%TYPE,
        i_market      PLS_INTEGER
    ) RETURN NUMBER IS
        l_count_ale  NUMBER;
        l_count_crit NUMBER;
        l_result     NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(prot_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_ale, l_count_crit
          FROM allergy ale
          JOIN allergy_inst_soft_market aism
            ON ale.id_allergy = aism.id_allergy
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                      WHERE prot.id_protocol = i_id_protocol
                        AND prot_crit.id_protocol = prot.id_protocol
                        AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                        AND prot_crit_lnk.id_link_other_criteria_type = g_protocol_allergies) prot_ids
            ON ale.id_allergy = safe_to_number(prot_ids.id_link_other_criteria)
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
    *  Checks difference between number of diagnoses and criteria diagnoses choosen
    *
    * @param      I_ID_PROTOCOL  Protocol ID
    * @param      I_FLG_TYPE     Diagnoses type
    *
    * @return     NUMBER
    * @author     TS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_count_diagnoses
    (
        i_id_protocol protocol.id_protocol%TYPE,
        i_diags_type  diagnosis.flg_type%TYPE
    ) RETURN NUMBER IS
        l_count_diags NUMBER;
        l_count_crit  NUMBER;
        l_result      NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(prot_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_diags, l_count_crit
          FROM (SELECT DISTINCT dc.id_diagnosis
                  FROM diagnosis_content dc
                 WHERE dc.flg_select = g_diag_select
                   AND dc.flg_type = i_diags_type) diags
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                      WHERE prot.id_protocol = i_id_protocol
                        AND prot_crit.id_protocol = prot.id_protocol
                        AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                        AND prot_crit_lnk.id_link_other_criteria_type = g_protocol_allergies) prot_ids
            ON diags.id_diagnosis = safe_to_number(prot_ids.id_link_other_criteria);
    
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
    *  Checks difference between number of nurse diagnosis and criteria nurse diagnosis choosen
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_ID_NURSE_DIAG              Nurse diagnosis ID
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_nurse_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   protocol.id_protocol%TYPE,
        i_id_nurse_diag NUMBER
    ) RETURN NUMBER IS
        l_count_nurse NUMBER;
        l_count_crit  NUMBER;
        l_result      NUMBER;
    BEGIN
    
        IF (i_id_nurse_diag < 0)
        THEN
            SELECT COUNT(1), SUM(decode(prot_ids.id_link_other_criteria, NULL, 0, 1))
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
                           FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                          WHERE prot.id_protocol = i_id_protocol
                            AND prot_crit.id_protocol = prot.id_protocol
                            AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                            AND prot_crit_lnk.id_link_other_criteria_type = g_protocol_diagnosis_nurse) prot_ids
                ON diag_specific.val = safe_to_number(prot_ids.id_link_other_criteria);
        
        ELSE
        
            SELECT COUNT(1), SUM(decode(prot_ids.id_link_other_criteria, NULL, 0, 1))
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
                           FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                          WHERE prot.id_protocol = i_id_protocol
                            AND prot_crit.id_protocol = prot.id_protocol
                            AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                            AND prot_crit_lnk.id_link_other_criteria_type = g_protocol_diagnosis_nurse) prot_ids
                ON diag_specific.val = safe_to_number(prot_ids.id_link_other_criteria);
        
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
    *  Checks difference between number of analysis and criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_ID_SAMPLE_TYPE             Sample type ID
    * @param      I_ID_EXAM_CAT                Exam category
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_analysis_sample
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    protocol.id_protocol%TYPE,
        i_id_sample_type sample_type.id_sample_type%TYPE,
        i_id_exam_cat    exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER IS
        l_count_sample NUMBER;
        l_count_crit   NUMBER;
        l_result       NUMBER;
    BEGIN
    
        SELECT COUNT(1), SUM(decode(prot_ids.id_link_other_criteria, NULL, 0, 1))
          INTO l_count_sample, l_count_crit
          FROM (SELECT a.id_analysis AS val
                  FROM analysis_instit_soft ana_inst_soft, analysis a, sample_type st, exam_cat ec
                 WHERE st.id_sample_type = nvl(i_id_sample_type, st.id_sample_type)
                   AND a.id_sample_type = st.id_sample_type
                   AND a.flg_available = g_analysis_available
                   AND ec.id_exam_cat = nvl(i_id_exam_cat, ec.id_exam_cat)
                   AND ec.id_exam_cat = ana_inst_soft.id_exam_cat
                   AND ana_inst_soft.id_analysis = a.id_analysis
                   AND ana_inst_soft.id_institution = i_prof.institution
                   AND ana_inst_soft.id_software = i_prof.software) analysis
          LEFT JOIN (SELECT id_link_other_criteria
                       FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                      WHERE prot.id_protocol = i_id_protocol
                        AND prot_crit.id_protocol = prot.id_protocol
                        AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                        AND prot_crit_lnk.id_link_other_criteria_type = g_protocol_analysis) prot_ids
            ON analysis.val = safe_to_number(prot_ids.id_link_other_criteria);
    
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
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_CRITERIA_TYPE              Criteria type - 'I'nclusion / 'E'xclusion
    * @param      I_PROTOCOL_CRITERIA_SEARCH   Criteria search topics
    * @param      I_VALUE_SEARCH               Values to search
    * @param      o_flg_show                   shows warning message: Y - yes, N - No
    * @param      o_msg                        message text
    * @param      o_msg_title                  message title
    * @param      o_button                     buttons to show: N-No, R-Read, C-Confirmed
    * @param      O_CRITERIA_SEARCH            Cursor with all elements of specific criteria
    * @param      O_ERROR                      error
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/08/09
    */
    FUNCTION get_criteria_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN NUMBER,
        i_criteria_type            IN VARCHAR2, -- Inclusion / exclusion
        i_protocol_criteria_search IN table_varchar,
        i_value_search             IN table_varchar,
        o_flg_show                 OUT VARCHAR2,
        o_msg                      OUT VARCHAR2,
        o_msg_title                OUT VARCHAR2,
        o_button                   OUT VARCHAR2,
        o_criteria_search          OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit                  sys_config.value%TYPE;
        l_diag_rowids            table_varchar;
        l_diag_selected_rowids   table_varchar := table_varchar();
        l_last_level             PLS_INTEGER;
        l_value_search           VARCHAR2(50);
        l_protocol_criteria_type NUMBER;
    
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
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_limit    := pk_sysconfig.get_config(g_config_max_diag_rownum, i_prof);
        o_flg_show := pk_alert_constant.g_no;
    
        -- get number of levels
        l_last_level := i_protocol_criteria_search.count;
    
        -- get protocol criteria type
        l_protocol_criteria_type := i_protocol_criteria_search(1);
    
        -- get last value search
        l_value_search := i_value_search(l_last_level);
    
        -- diagnoses
        IF (l_protocol_criteria_type = g_protocol_diagnosis)
        THEN
        
            IF (l_last_level = 1)
            THEN
                -- Type of diagnoses
                OPEN o_criteria_search FOR
                    SELECT /*+opt_estimate(table,t,scale_rows=1))*/
                     t.desc_terminology desc_val,
                     t.flg_terminology val,
                     l_protocol_criteria_type AS val_type,
                     get_count_diagnoses(i_id_protocol, t.flg_terminology) AS flg_select_stat,
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
                                 WHERE d.flg_type = i_protocol_criteria_search(2)
                                   AND rownum > 0) diag
                         WHERE nvl(diag.id_diagnosis_parent, -99) =
                               nvl(decode(l_last_level, 2, NULL, i_protocol_criteria_search(l_last_level)), -99)) diags
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
                                     WHERE d.flg_type = i_protocol_criteria_search(2)
                                       AND rownum > 0) diag
                              JOIN (SELECT prot_crit_lnk.id_link_other_criteria, prot_crit.criteria_type
                                     FROM protocol               prot,
                                          protocol_criteria      prot_crit,
                                          protocol_criteria_link prot_crit_lnk
                                    WHERE prot.id_protocol = i_id_protocol
                                      AND prot_crit.id_protocol = prot.id_protocol
                                      AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                      AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
                                ON diag.id_diagnosis = safe_to_number(crosslink.id_link_other_criteria)
                             WHERE nvl(diag.id_diagnosis_parent, -99) =
                                   nvl(decode(l_last_level, 2, NULL, i_protocol_criteria_search(l_last_level)), -99))
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
                                     l_protocol_criteria_type AS val_type,
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
                                              FROM (SELECT DISTINCT d.id_diagnosis rowid_d,
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
        
        ELSIF (l_protocol_criteria_type = g_protocol_allergies)
        THEN
            IF (l_last_level = 1)
            THEN
                l_market         := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
                l_default_market := pk_allergy.get_default_allergy_market(l_market);
            
                OPEN o_criteria_search FOR
                    SELECT pk_translation.get_translation(i_lang, ale.code_allergy) AS desc_val,
                           ale.id_allergy AS val,
                           get_count_allergies(i_prof, i_id_protocol, ale.id_allergy, l_default_market) AS flg_select_stat,
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
                                                               i_allergy_parent => i_protocol_criteria_search(l_last_level - 1),
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
                           l_protocol_criteria_type AS val_type,
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
                      LEFT JOIN (SELECT prot_crit_lnk.id_link_other_criteria,
                                        prot_crit_lnk.id_link_other_criteria_type,
                                        prot_crit.criteria_type
                                   FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                                  WHERE prot.id_protocol = i_id_protocol
                                    AND prot_crit.id_protocol = prot.id_protocol
                                    AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                    AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
                        ON ale.id_allergy = safe_to_number(crosslink.id_link_other_criteria)
                    ----------------------------------------------------------------------
                     WHERE ((translate(upper(core_allergy.vc_1), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                     ORDER BY desc_val;
            END IF;
        
        ELSIF (l_protocol_criteria_type = g_protocol_analysis)
        THEN
            IF (l_last_level = 1)
            THEN
                OPEN o_criteria_search FOR
                    SELECT pk_translation.get_translation(i_lang, st.code_sample_type) desc_val,
                           st.id_sample_type val,
                           get_count_analysis_sample(i_lang, i_prof, i_id_protocol, st.id_sample_type, NULL) AS flg_select_stat,
                           g_not_available AS flg_select
                      FROM sample_type st
                     WHERE st.flg_available = g_samp_type_avail
                       AND EXISTS
                     (SELECT 1
                              FROM analysis_sample_type ast, analysis_instit_soft ais
                             WHERE ast.id_sample_type = st.id_sample_type
                               AND ast.flg_available = g_analysis_available
                               AND ast.id_analysis = ais.id_analysis
                               AND ast.id_sample_type = ais.id_sample_type
                               AND ais.flg_type = 'P'
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.flg_available = g_analysis_available
                               AND EXISTS (SELECT 1
                                      FROM analysis_param ap
                                     WHERE ap.id_analysis = ast.id_analysis
                                       AND ap.id_sample_type = ast.id_sample_type
                                       AND ap.flg_available = g_analysis_available
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
                                                              i_id_protocol,
                                                              i_protocol_criteria_search(l_last_level),
                                                              ec.id_exam_cat) AS flg_select_stat,
                                    g_not_available AS flg_select
                      FROM exam_cat ec
                     WHERE ec.flg_available = g_analysis_available
                       AND EXISTS (SELECT 1
                              FROM analysis_instit_soft ais, analysis_sample_type ast
                             WHERE ais.id_exam_cat = ec.id_exam_cat
                               AND ais.flg_type = 'P'
                               AND ais.flg_available = g_analysis_available
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.id_analysis = ast.id_analysis
                               AND ais.id_sample_type = ast.id_sample_type
                               AND ast.flg_available = g_analysis_available
                               AND ast.id_sample_type = i_protocol_criteria_search(l_last_level));
            ELSIF (l_last_level = 3)
            THEN
                OPEN o_criteria_search FOR
                    SELECT a.desc_val,
                           a.val,
                           decode(crosslink.id_link_other_criteria,
                                  NULL,
                                  g_criteria_clear,
                                  decode(crosslink.criteria_type,
                                         i_criteria_type,
                                         g_criteria_already_set,
                                         g_criteria_already_crossset)) AS flg_select_stat,
                           g_available AS flg_select
                      FROM (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                             i_prof,
                                                                             pk_lab_tests_constant.g_analysis_alias,
                                                                             'ANALYSIS.CODE_ANALYSIS.' || ast.id_analysis,
                                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                             ast.id_sample_type,
                                                                             NULL) AS desc_val,
                                   ast.id_analysis AS val
                              FROM analysis_sample_type ast, analysis_instit_soft ais
                             WHERE ast.id_sample_type = i_protocol_criteria_search(l_last_level - 1)
                               AND ast.flg_available = g_analysis_available
                               AND ais.id_analysis = ast.id_analysis
                               AND ais.id_sample_type = ast.id_sample_type
                               AND ais.id_exam_cat = i_protocol_criteria_search(l_last_level)
                               AND ais.flg_type = 'P'
                               AND ais.id_institution = i_prof.institution
                               AND ais.id_software = i_prof.software
                               AND ais.flg_available = g_analysis_available) a
                      LEFT JOIN (SELECT prot_crit_lnk.id_link_other_criteria,
                                        prot_crit_lnk.id_link_other_criteria_type,
                                        prot_crit.criteria_type
                                   FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                                  WHERE prot.id_protocol = i_id_protocol
                                    AND prot_crit.id_protocol = prot.id_protocol
                                    AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                    AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
                        ON a.val = safe_to_number(crosslink.id_link_other_criteria)
                    ---------------------------------------------------------------------------------------
                     WHERE ((translate(upper(a.desc_val), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' ||
                           translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           l_value_search IS NOT NULL) OR l_value_search IS NULL)
                    ---------------------------------------------------------------------------------------
                     ORDER BY desc_val;
            END IF;
        
            ----------------------------------------------------------------------
        
        ELSIF (l_protocol_criteria_type = g_protocol_exams OR l_protocol_criteria_type = g_protocol_other_exams)
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
                  FROM (SELECT DISTINCT pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam) desc_val,
                                        e.id_exam AS val,
                                        'E' AS val_type,
                                        0 AS rank --ed.rank AS rank
                          FROM exam_dep_clin_serv ed1, exam e, exam_cat ec
                         WHERE e.flg_available = g_exam_available
                              ---------------------------------
                           AND ((e.flg_type = g_exam_type_img AND l_protocol_criteria_type = g_protocol_exams) --se 'Imagem'
                               OR (e.flg_type != g_exam_type_img AND l_protocol_criteria_type = g_protocol_other_exams)) --se 'Outros exames'
                              ---------------------------------
                              --AND ed.id_software = i_prof.software
                           AND ec.id_exam_cat = e.id_exam_cat
                           AND ed1.id_exam = e.id_exam
                           AND ed1.flg_type = g_exam_can_req
                              --AND ed1.id_software = i_prof.software
                           AND ed1.id_institution = i_prof.institution
                        UNION
                        SELECT pk_translation.get_translation(i_lang, eg.code_exam_group) AS desc_val,
                               eg.id_exam_group AS val,
                               'G' AS val_type,
                               eg.rank AS rank
                          FROM exam_group eg, exam_egp exmg, exam e, exam_cat ec --, EXAM_ROOM ER, ROOM R, DEPARTMENT DEP
                         WHERE exmg.id_exam_group = eg.id_exam_group
                           AND e.id_exam = exmg.id_exam
                           AND e.flg_available = g_exam_available
                              ---------------------------------
                           AND ((e.flg_type = g_exam_type_img AND l_protocol_criteria_type = g_protocol_exams) --se 'Imagem'
                               OR (e.flg_type != g_exam_type_img AND l_protocol_criteria_type = g_protocol_other_exams)) --se 'Outros exames'
                              ---------------------------------
                           AND ec.id_exam_cat = e.id_exam_cat) exams
                  LEFT JOIN (SELECT prot_crit_lnk.id_link_other_criteria,
                                    prot_crit_lnk.id_link_other_criteria_type,
                                    prot_crit.criteria_type
                               FROM protocol prot, protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
                              WHERE prot.id_protocol = i_id_protocol
                                AND prot_crit.id_protocol = prot.id_protocol
                                AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
                    ON exams.val = safe_to_number(crosslink.id_link_other_criteria)
                 WHERE exams.desc_val IS NOT NULL
                   AND ((translate(upper(exams.desc_val), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                       '%' ||
                       translate(upper(l_value_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                       l_value_search IS NOT NULL) OR l_value_search IS NULL)
                 ORDER BY rank, desc_val;
        
        ELSIF (l_protocol_criteria_type = g_protocol_diagnosis_nurse)
        THEN
        
            IF (l_last_level = 1)
            THEN
                OPEN o_criteria_search FOR
                    SELECT desc_val,
                           val,
                           get_count_nurse_diag(i_lang, i_prof, i_id_protocol, val) AS flg_select_stat,
                           g_not_available AS flg_select
                      FROM (SELECT desc_clinical_service AS desc_val, id_clinical_service AS val, rank
                              FROM (SELECT DISTINCT dcs.id_clinical_service id_clinical_service,
                                                    pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                                                    0 rank --i.RANK
                                      FROM icnp_compo_dcs   icd,
                                           dep_clin_serv    dcs,
                                           department       d,
                                           software_dept    sd,
                                           clinical_service cs
                                     WHERE dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                                       AND d.id_department = dcs.id_department
                                       AND sd.id_dept = d.id_dept
                                       AND sd.id_software = i_prof.software
                                       AND cs.id_clinical_service = dcs.id_clinical_service
                                       AND dcs.id_department IN
                                           (SELECT d.id_department
                                              FROM department d
                                             WHERE d.id_institution = i_prof.institution)
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
            
                IF (i_protocol_criteria_search(l_last_level) < 0)
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
                                          FROM dep_clin_serv dcs, department d, dept dp, software_dept sd
                                         WHERE d.id_department = dcs.id_department
                                           AND d.id_institution = i_prof.institution
                                           AND dp.id_dept = d.id_dept
                                           AND sd.id_dept = dp.id_dept
                                           AND sd.id_software = i_prof.software)) diag_specific
                          LEFT JOIN (SELECT prot_crit_lnk.id_link_other_criteria,
                                            prot_crit_lnk.id_link_other_criteria_type,
                                            prot_crit.criteria_type
                                       FROM protocol               prot,
                                            protocol_criteria      prot_crit,
                                            protocol_criteria_link prot_crit_lnk
                                      WHERE prot.id_protocol = i_id_protocol
                                        AND prot_crit.id_protocol = prot.id_protocol
                                        AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                        AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
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
                                       department       d,
                                       software_dept    sd
                                 WHERE icd.id_composition = ic.id_composition
                                   AND ic.flg_type = g_composition_diag_type
                                   AND dcs.id_dep_clin_serv = icd.id_dep_clin_serv
                                   AND dcs.id_clinical_service = i_protocol_criteria_search(l_last_level)
                                   AND d.id_department = dcs.id_department
                                   AND d.id_institution = i_prof.institution
                                   AND sd.id_dept = d.id_dept
                                   AND sd.id_software = i_prof.software
                                   AND ic.flg_available = g_available) diag_specific
                          LEFT JOIN (SELECT prot_crit_lnk.id_link_other_criteria,
                                            prot_crit_lnk.id_link_other_criteria_type,
                                            prot_crit.criteria_type
                                       FROM protocol               prot,
                                            protocol_criteria      prot_crit,
                                            protocol_criteria_link prot_crit_lnk
                                      WHERE prot.id_protocol = i_id_protocol
                                        AND prot_crit.id_protocol = prot.id_protocol
                                        AND prot_crit_lnk.id_protocol_criteria = prot_crit.id_protocol_criteria
                                        AND prot_crit_lnk.id_link_other_criteria_type = l_protocol_criteria_type) crosslink
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
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CRITERIA_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_criteria_search);
            RETURN FALSE;
    END get_criteria_search;

    /**
    *  Get criteria types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                  protocol ID
    * @param      O_CRITERIA_TYPE              cursor with all criteria types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_criteria_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_criteria_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
        g_error := 'GET CURSOR CRITERIA TYPE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_criteria_type FOR
            SELECT prot_crit_typ.id_protocol_criteria_type,
                   pk_translation.get_translation(i_lang, prot_crit_typ.code_protocol_criteria_type) desc_protocol_criteria_type,
                   decode(b.counter_link, NULL, 0, 0, 0, g_criteria_group_some) AS flg_select
              FROM protocol_criteria_type prot_crit_typ,
                   (SELECT prot_crit_link.id_link_other_criteria_type AS id_link_other_criteria_type,
                           COUNT(1) AS counter_link
                      FROM protocol_criteria prot_crit, protocol_criteria_link prot_crit_link
                     WHERE prot_crit.id_protocol = i_id_protocol
                       AND prot_crit_link.id_protocol_criteria = prot_crit.id_protocol_criteria
                     GROUP BY prot_crit_link.id_link_other_criteria_type) b,
                   (SELECT DISTINCT item
                      FROM (SELECT item,
                                   first_value(pisi.flg_available) over(PARTITION BY pisi.item ORDER BY pisi.id_market DESC, pisi.id_institution DESC, pisi.id_software DESC, pisi.flg_available) AS flg_avail
                              FROM protocol_item_soft_inst pisi
                             WHERE pisi.id_institution IN (g_all_institution, i_prof.institution)
                               AND pisi.id_software IN (g_all_software, i_prof.software)
                               AND pisi.id_market IN (g_all_markets, l_market)
                               AND pisi.flg_item_type = g_protocol_item_criteria)
                     WHERE flg_avail = g_available) prot_item
             WHERE prot_crit_typ.flg_available = g_available
               AND prot_crit_typ.id_protocol_criteria_type = b.id_link_other_criteria_type(+)
               AND prot_item.item = prot_crit_typ.id_protocol_criteria_type
             ORDER BY desc_protocol_criteria_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CRITERIA_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_criteria_type);
            RETURN FALSE;
    END get_criteria_type;

    /** 
    *  Obtain all pathologies by search code
    *
    * @param      I_LANG                     Prefered languagie ID for this professional
    * @param      I_PROF                     object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL              Protocol ID
    * @param      I_VALUE_CODE               Value with code to search for
    * @param      O_PATHOLOGY_BY_SEARCH      cursor with all pathologies
    * @param      O_ERROR                    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_pathology_by_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
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
    
    BEGIN
        g_error := 'GET CURSOR PATHOLOGIES BY SEARCH CODE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
    
        -- delete any records present in tbl_temp and fill with diagnosis cursor
        DELETE FROM tbl_temp;
        FETCH c_diags BULK COLLECT
            INTO l_diag_desc, l_id_diagnosis, l_code_icd, l_rank, l_flg_select, l_flg_other, l_id_alert_diagnosis;
        CLOSE c_diags;
    
        -- create temporary table with diags info
        insert_tbl_temp(i_num_1 => l_id_diagnosis, i_vc_1 => l_diag_desc, i_vc_2 => l_flg_select);
    
        OPEN o_pathology_by_code FOR
            SELECT diags.vc_1 AS desc_diagnosis,
                   diags.num_1 AS id_diagnosis,
                   decode(prot_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM protocol_link xp
                                WHERE xp.link_type = g_protocol_link_pathol
                                  AND xp.id_protocol = i_id_protocol) prot_lnk
                ON diags.num_1 = prot_lnk.id_link
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATHOLOGY_BY_CODE',
                                              o_error);
            pk_types.open_my_cursor(o_pathology_by_code);
            RETURN FALSE;
    END get_pathology_by_code;

    /** 
    *  Obtain all pathologies by search
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_SEARCH        cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_pathology_by_search
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
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
        l_overlimit                    BOOLEAN;
    BEGIN
    
        g_error := 'GET CURSOR PATHOLOGIES BY SEARCH';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
            FETCH c_diags BULK COLLECT
                INTO l_coll_desc_diagnosis,
                     l_coll_id_diagnosis,
                     l_coll_code_icd,
                     l_coll_rank,
                     l_coll_avail_for_select,
                     l_coll_flg_other,
                     l_coll_id_alert_diagnosis,
                     l_coll_flg_diag_type;
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
            CLOSE c_diags;
        
            -- create temporary table with diags info
            insert_tbl_temp(i_num_1 => l_coll_id_diagnosis,
                            i_vc_1  => l_coll_desc_diagnosis,
                            i_vc_2  => l_coll_avail_for_select);
        
        END IF;
    
        OPEN o_pathology_by_search FOR
            SELECT diags.vc_1 AS desc_diagnosis,
                   diags.num_1 AS id_diagnosis,
                   decode(prot_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM protocol_link xp
                                WHERE xp.link_type = g_protocol_link_pathol
                                  AND xp.id_protocol = i_id_protocol) prot_lnk
                ON diags.num_1 = prot_lnk.id_link
             ORDER BY desc_diagnosis;
    
        IF l_overlimit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PATHOLOGY_BY_SEARCH', o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATHOLOGY_BY_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_pathology_by_search);
            RETURN FALSE;
    END get_pathology_by_search;

    /** 
    *  Obtain all pathologies by group
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_ID_PARENT                  Parent ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_GROUP         cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_pathology_by_group
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol        IN protocol.id_protocol%TYPE,
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
    
    BEGIN
    
        g_error := 'GET CURSOR PATHOLOGIES BY GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
        FETCH c_diags BULK COLLECT
            INTO l_id_diagnosis, l_id_alert_diagnosis, l_diag_desc, l_id_diagnosis_parent, l_flg_select;
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
                   decode(prot_lnk.id_link, NULL, g_inactive, g_active) AS flg_select_stat,
                   diags.num_2 AS id_diagnosis_parent,
                   diags.vc_2 AS flg_select
              FROM tbl_temp diags
              LEFT OUTER JOIN (SELECT id_link
                                 FROM protocol_link xp
                                WHERE xp.link_type = g_protocol_link_pathol
                                  AND xp.id_protocol = i_id_protocol) prot_lnk
                ON diags.num_1 = prot_lnk.id_link
             ORDER BY desc_diagnosis;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATHOLOGY_BY_GROUP',
                                              o_error);
            pk_types.open_my_cursor(o_pathology_by_group);
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPINION_SPEC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_spec);
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPINION_PROF_SPEC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END get_opinion_prof_spec_list;

    /**
    *  Clean temp protocol
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL      ID of protocol.
    * @param      I_DATE_OFFSET       Date with offset in days
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION clean_protocol_temp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_date_offset IN protocol.dt_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_protocol IS
            SELECT id_protocol, flg_status
              FROM protocol
             WHERE ((id_protocol = i_id_protocol AND i_id_protocol IS NOT NULL) OR i_id_protocol IS NULL)
               AND flg_status = g_protocol_temp
               AND dt_protocol < i_date_offset;
    
    BEGIN
        g_error := 'FETCH PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Checks if protocol is temp or definitive.
        FOR rec_protocol IN c_protocol
        LOOP
            IF (NOT cancel_protocol(i_lang, i_prof, i_id_protocol, o_error))
            THEN
                RETURN FALSE;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CLEAN_PROTOCOL_TEMP',
                                                     o_error);
    END clean_protocol_temp;

    /**
    *  Cancel a task request
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_element_type               Task Type
    * @param      i_id_episode                 episode id
    * @param      i_id_cancel_reason           cancel reason that justifies the task cancel
    * @param      i_cancel_notes               cancel notes (free text) that justifies the task cancel      
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_task_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN protocol_task.task_type%TYPE,
        i_id_request       IN protocol_process_element.id_request%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancel_result BOOLEAN;
    
        l_prof_cat category.flg_type%TYPE;
        l_patient  episode.id_patient%TYPE;
    
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
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT cat.flg_type
          INTO l_prof_cat
          FROM prof_cat pc, category cat
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = cat.id_category;
    
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'CANCEL TASK REQUEST';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_REQUEST                 Request ID of the task
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_task_request_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN protocol_task.task_type%TYPE,
        i_id_request IN protocol_process_element.id_request%TYPE
    ) RETURN VARCHAR2 IS
        l_task_req_stat VARCHAR2(1 CHAR);
        o_error         t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET TASK REQUEST SCHEDULE STATUS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
        
            WHEN g_task_analysis THEN
                -- analysis
            
                g_error := 'GET SCHEDULE ANALYSIS REQUEST';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                SELECT decode(ana_req.flg_time, pk_alert_constant.g_flg_time_e, g_not_scheduled, g_scheduled)
                  INTO l_task_req_stat
                  FROM analysis_req_det ana_req_det, analysis_req ana_req
                 WHERE ana_req_det.id_analysis_req_det = i_id_request
                   AND ana_req_det.id_analysis_req = ana_req.id_analysis_req;
            
            WHEN g_task_appoint THEN
                -- Consultas
            
                g_error := 'GET SCHEDULE APPOINTMENT REQUEST';
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
            
                g_error := 'GET SCHEDULE OTHER EXAMS REQUEST';
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
                SELECT decode(pea.flg_time,
                              pk_alert_constant.g_flg_time_e,
                              g_not_scheduled,
                              pk_alert_constant.g_flg_time_b,
                              g_not_scheduled,
                              g_scheduled)
                  INTO l_task_req_stat
                  FROM procedures_ea pea -- interv_presc_det, interv_prescription interv_presc
                 WHERE pea.id_interv_presc_det = i_id_request;
                --                   AND interv_presc_det.id_interv_prescription = interv_presc.id_interv_prescription;
        
            ELSE
                l_task_req_stat := NULL;
        END CASE;
    
        RETURN l_task_req_stat;
    END get_task_request_schedule;

    /**
    *  Get status of a task request
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_REQUEST                 Request ID
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/14
    */
    FUNCTION get_task_request_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN protocol_task.task_type%TYPE,
        i_id_request IN protocol_process_element.id_request%TYPE
    ) RETURN protocol_process_element.flg_status%TYPE IS
        l_task_req_stat protocol_process_element.flg_status%TYPE;
        o_error         t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET TASK REQUEST STATUS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        CASE i_task_type
            WHEN g_task_analysis THEN
                -- analysis
            
                g_error := 'GET STATUS ANALYSIS REQUEST';
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
                SELECT decode(flg_status,
                              pk_patient_education_api_db.g_nurse_tea_req_pend,
                              g_process_running,
                              pk_patient_education_api_db.g_nurse_tea_req_act,
                              g_process_running,
                              pk_patient_education_api_db.g_nurse_tea_req_canc,
                              g_process_closed,
                              g_process_finished)
                  INTO l_task_req_stat
                  FROM nurse_tea_req ntr
                 WHERE ntr.id_nurse_tea_req = i_id_request;
            
            WHEN g_task_img THEN
                -- Imagem
            
                g_error := 'GET STATUS IMAGE EXAM REQUEST';
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
                SELECT decode(flg_status,
                              pk_procedures_constant.g_interv_finished,
                              g_process_finished,
                              pk_procedures_constant.g_interv_interrupted,
                              g_process_finished,
                              pk_procedures_constant.g_interv_cancel,
                              g_process_closed,
                              g_process_running)
                  INTO l_task_req_stat
                  FROM interv_presc_det
                 WHERE id_interv_presc_det = i_id_request;
            ELSE
                l_task_req_stat := NULL;
        END CASE;
    
        RETURN l_task_req_stat;
    
    END get_task_request_status;

    /**
    *  Update protocol process tasks status
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS      ID of protocol process
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_prot_proc_task_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_proc_tasks_running IS
            SELECT prot_proc_elem.id_protocol_process_elem,
                   prot_proc_elem.id_request,
                   prot_proc_elem.dt_request,
                   prot_proc_elem.flg_status,
                   prot_proc_elem.flg_active,
                   prot_task.task_type
              FROM protocol_process_element prot_proc_elem, protocol_task prot_task
             WHERE prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
               AND prot_proc_elem.flg_status = g_process_running
                  -- nested protocol tasks are processed in a different way
               AND prot_proc_elem.element_type != g_element_protocol;
    
        CURSOR c_proc_tasks_scheduled IS
            SELECT prot_proc_elem.id_protocol_process_elem,
                   prot_proc_elem.id_request,
                   prot_proc_elem.dt_request,
                   prot_proc_elem.flg_status,
                   prot_proc_elem.flg_active
              FROM protocol_process_element prot_proc_elem
             WHERE prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND prot_proc_elem.flg_status = g_process_scheduled
               AND prot_proc_elem.element_type = g_element_task
                  -- nested protocol tasks are processed in a different way
               AND prot_proc_elem.element_type != g_element_protocol;
    
        CURSOR c_proc_nested_prot_tasks IS
            SELECT prot_proc_elem.id_protocol_process_elem, prot_proc_elem.id_protocol_process_link
              FROM protocol_process_element prot_proc_elem
             WHERE prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND prot_proc_elem.element_type = g_element_protocol
               AND prot_proc_elem.id_protocol_process_link IS NOT NULL;
    
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_request_status protocol_process_element.flg_status%TYPE;
        l_next_rec       protocol_process_task_det.dvalue%TYPE;
    
        e_update_nested_protocols EXCEPTION;
    
    BEGIN
        g_error := 'UPDATE STATE OF NESTED PROTOCOL PROCESS TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_proc_nested_prot_tasks
        LOOP
        
            -- update status of all tasks of the nested protocol
            IF NOT update_prot_proc_task_status(i_lang, i_prof, rec.id_protocol_process_link, o_error)
            THEN
                RAISE e_update_nested_protocols;
            END IF;
        
            -- update nested protocol status
            IF NOT update_prot_proc_status(i_lang, i_prof, rec.id_protocol_process_link, o_error)
            THEN
                RAISE e_update_nested_protocols;
            END IF;
        
            -- update status of the task associated to the nested protocol
            UPDATE protocol_process_element ppe
               SET ppe.flg_status =
                   (SELECT pp.flg_status
                      FROM protocol_process pp
                     WHERE pp.id_protocol_process = rec.id_protocol_process_link)
             WHERE ppe.id_protocol_process_elem = rec.id_protocol_process_elem;
        
        END LOOP;
    
        g_error := 'UPDATE STATE OF PROTOCOL PROCESS TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_proc_tasks_scheduled
        LOOP
            -- get next recommendation date
            SELECT dvalue
              INTO l_next_rec
              FROM protocol_process_task_det
             WHERE flg_detail_type = g_proc_task_det_next_rec
               AND id_protocol_process_elem = rec.id_protocol_process_elem;
        
            IF instr(pk_alert_constant.g_date_greater || pk_alert_constant.g_date_equal,
                     pk_date_utils.compare_dates_tsz(i_prof, l_sysdate, l_next_rec)) > 0
            THEN
                -- recommnend task again
                -- update state
                UPDATE protocol_process_element
                   SET flg_status       = g_process_recommended,
                       dt_status        = l_sysdate,
                       id_professional  = i_prof.id,
                       id_cancel_reason = NULL,
                       cancel_notes     = NULL
                 WHERE id_protocol_process_elem = rec.id_protocol_process_elem;
            END IF;
        END LOOP;
    
        g_error := 'UPDATE STATE OF RUNNING PROTOCOL PROCESS TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_proc_tasks_running
        LOOP
        
            l_request_status := get_task_request_status(i_lang, i_prof, rec.task_type, rec.id_request);
        
            IF (l_request_status IS NOT NULL AND l_request_status != g_process_running)
            THEN
            
                -- reset task frequency
                IF l_request_status = g_process_finished
                THEN
                
                    g_error := 'RESET TASK FREQUENCY';
                    pk_alertlog.log_debug(g_error, g_package_name);
                
                    IF (reset_task_frequency(i_lang, i_prof, rec.id_protocol_process_elem))
                    THEN
                        l_request_status := g_process_scheduled;
                    END IF;
                END IF;
            
                -- update state
                UPDATE protocol_process_element
                   SET flg_status       = l_request_status,
                       dt_status        = l_sysdate,
                       id_professional  = i_prof.id,
                       id_cancel_reason = NULL,
                       cancel_notes     = NULL
                 WHERE id_protocol_process_elem = rec.id_protocol_process_elem;
            
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Error while update nested protocol tasks
        WHEN e_update_nested_protocols THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     NULL,
                                                     g_error || ' / ERROR WHILE UPDATE NESTED PROTOCOL TASKS',
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPDATE_PROT_PROC_TASK_STATUS',
                                                     o_error);
            -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPDATE_PROT_PROC_TASK_STATUS',
                                                     o_error);
    END update_prot_proc_task_status;

    /**
    *  Update protocol process status
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_prot_proc_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_proc_status                protocol_process.flg_status%TYPE;
        l_dt_status_protocol_process TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'UPDATE STATE OF PROTOCOL PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- calculate the new state of protocol process
        BEGIN
            SELECT flg_status
              INTO l_proc_status
              FROM (SELECT decode(prot_proc_tsk.flg_status,
                                  g_process_canceled,
                                  g_process_running,
                                  g_process_closed,
                                  g_process_running,
                                  prot_proc_tsk.flg_status) AS flg_status
                      FROM protocol_process_element prot_proc_tsk
                     WHERE prot_proc_tsk.id_protocol_process = i_id_protocol_process
                     ORDER BY decode(prot_proc_tsk.flg_status,
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
                RETURN TRUE;
        END;
    
        -- verify if the protocolos has at least a leaf elements with a finished state
        -- otherwise the protocol has to be in the running state
        IF l_proc_status = g_process_finished
        THEN
        
            SELECT decode(COUNT(1), 0, g_process_running, g_process_finished)
              INTO l_proc_status
              FROM protocol_process_element prot_proc_tsk
             WHERE prot_proc_tsk.id_protocol_process = i_id_protocol_process
               AND prot_proc_tsk.flg_status = g_process_finished
               AND NOT EXISTS (SELECT 1
                      FROM protocol_relation pr
                     WHERE pr.flg_available = g_available
                       AND pr.id_protocol_element_parent = prot_proc_tsk.id_protocol_element);
        END IF;
    
        -- calculate dt_status of protocol_process
        SELECT MAX(dt_status)
          INTO l_dt_status_protocol_process
          FROM protocol_process_element
         WHERE id_protocol_process = i_id_protocol_process;
    
        -- update state of protocol process
        UPDATE protocol_process
           SET flg_status = decode(l_proc_status, g_process_closed, g_process_canceled, l_proc_status),
               dt_status  = l_dt_status_protocol_process
         WHERE id_protocol_process = i_id_protocol_process
           AND flg_status != g_process_canceled;
    
        RETURN TRUE;
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPDATE_PROT_PROC_STATUS',
                                                     o_error);
    END update_prot_proc_status;

    /**
    *  Update all protocol processes status (including tasks)
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                Patient ID
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_all_prot_proc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN protocol_process.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_procs IS
            SELECT id_protocol_process
              FROM protocol_process gp
             WHERE gp.id_patient = nvl(i_id_patient, gp.id_patient)
               AND gp.flg_status != g_process_canceled;
    
        b_result BOOLEAN;
        error_undefined EXCEPTION;
    BEGIN
        g_error := 'UPDATE STATE OF PROTOCOL PROCESSES AND ASSOCIATED TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_procs
        LOOP
        
            b_result := update_prot_proc_task_status(i_lang, i_prof, rec.id_protocol_process, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            b_result := update_prot_proc_status(i_lang, i_prof, rec.id_protocol_process, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on update of the protocol status or protocol tasks status
        WHEN error_undefined THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     NULL,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPDATE_ALL_PROT_PROC_STATUS',
                                                     o_error);
            -- Other errors not included in the previous exception type            
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPDATE_ALL_PROT_PROC_STATUS',
                                                     o_error);
    END update_all_prot_proc_status;

    /**
    *  Get recommended protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_VALUE                      String to search for
    * @param      DT_SERVER                    Current server time
    * @param      O_PROTOCOL_RECOMMENDED       protocol recomended for specific user
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_recommended_protocol
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN protocol_process.id_patient%TYPE,
        i_value                IN VARCHAR2,
        dt_server              OUT VARCHAR2,
        o_protocol_recommended OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        b_result BOOLEAN;
        error_undefined EXCEPTION;
    BEGIN
    
        IF (i_value IS NULL)
        THEN
        
            -- update of protocol processes and associated tasks
            b_result := update_all_prot_proc_status(i_lang, i_prof, i_id_patient, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            COMMIT;
        
            -- verify if any protocol should be automatically recommended to the patient
            b_result := run_batch(i_lang, i_prof, i_id_patient, NULL, NULL, o_error);
        
            IF (NOT b_result)
            THEN
                RAISE error_undefined;
            END IF;
        
            COMMIT;
        
        END IF;
    
        g_error := 'GET RECOMMENDED PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_recommended FOR
            SELECT *
              FROM (SELECT g.id_protocol,
                           gp.id_protocol_process,
                           gp.flg_status,
                           pk_date_utils.date_send_tsz(i_lang, gp.dt_status, i_prof) AS dt_status,
                           pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol, gp.flg_status) rank,
                           get_link_id_str(i_lang, i_prof, g.id_protocol, g_protocol_link_pathol, g_separator) AS desc_pathology,
                           g.protocol_desc AS protocol_title,
                           get_link_id_str(i_lang, i_prof, g.id_protocol, g_protocol_link_type, g_separator) type_desc,
                           pk_translation.get_translation(i_lang, ebm.code_ebm) AS desc_ebm,
                           
                           '0' || '|' || pk_date_utils.date_send_tsz(i_lang, dt_status, i_prof) --'xxxxxxxxxxxxxx'
                           || '|' || decode(gp.flg_status, g_process_finished, g_text_icon, g_icon) || '|' ||
                           decode(pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, gp.flg_status),
                                  g_alert_icon,
                                  decode(gp.flg_status, g_process_scheduled, g_green_color, g_red_color),
                                  g_waiting_icon,
                                  g_red_color,
                                  NULL) || '|' || pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, gp.flg_status) || '|' ||
                           pk_date_utils.dt_chr_year_short_tsz(i_lang, dt_status, i_prof) AS status,
                           --
                           pk_sysdomain.get_domain(g_domain_flg_protocol, gp.flg_status, i_lang) AS desc_status,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         gp.id_professional,
                                                         pb.dt_protocol_batch,
                                                         gp.id_episode) AS request_author_desc,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                              pb.dt_protocol_batch,
                                                              i_prof.institution,
                                                              i_prof.software) request_date_desc,
                           pb.dt_protocol_batch dt_request,
                           decode(pb.batch_type, g_batch_1p_1g, g_no, g_yes) AS flg_auto_recommendation,
                           check_cancel_protocol_proc(i_lang, i_prof, gp.id_protocol_process) AS flg_cancel
                      FROM protocol g, protocol_batch pb, protocol_process gp, ebm ebm
                     WHERE g.id_protocol = gp.id_protocol
                       AND gp.id_patient = i_id_patient
                       AND gp.flg_nested_protocol = g_not_nested_protocol
                       AND pb.id_protocol_batch = gp.id_protocol_batch
                       AND g.id_ebm = ebm.id_ebm(+)
                    -- search for value
                    )
             WHERE ((translate(upper(protocol_title), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value IS NOT NULL) OR i_value IS NULL)
             ORDER BY decode(flg_status,
                             g_process_suspended,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol, g_process_canceled),
                             g_process_canceled,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol, g_process_canceled),
                             rank) ASC,
                      dt_status DESC;
    
        COMMIT;
    
        -- return server time as close as possible to the end of function 
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECOMMENDED_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_protocol_recommended);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECOMMENDED_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_protocol_recommended);
            RETURN FALSE;
    END get_recommended_protocol;

    /**
    *  Change state of recomended protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel     
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_rec_protocol_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_action           IN action.id_action%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        i_transaction_id      IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_status IS
            SELECT prot_proc.flg_status, act.from_state, act.to_state
              FROM protocol_process prot_proc, action act
             WHERE prot_proc.id_protocol_process = i_id_protocol_process
               AND act.id_action = decode(i_id_action, g_state_cancel_operation, act.id_action, i_id_action)
               AND act.to_state = decode(i_id_action, g_state_cancel_operation, g_cancel_protocol, act.to_state)
               AND act.from_state = prot_proc.flg_status
               AND act.subject = g_protocol;
    
        CURSOR c_elem_status(i_status VARCHAR2) IS
            SELECT prot_proc_elem.id_protocol_process_elem,
                   prot_proc_elem.id_protocol_element,
                   prot_proc_elem.element_type,
                   prot_proc_elem.id_request,
                   prot_proc_elem.dt_request,
                   prot_proc_elem.flg_active,
                   act.from_state,
                   act.to_state,
                   prot_task.task_type
              FROM protocol_process_element prot_proc_elem
              LEFT OUTER JOIN protocol_task prot_task
                ON prot_proc_elem.id_protocol_task = prot_task.id_protocol_task, action act
             WHERE prot_proc_elem.id_protocol_process = i_id_protocol_process
               AND ((i_status != g_cancel_protocol AND act.to_state = i_status) OR
                   (i_status = g_cancel_protocol AND act.to_state IN (g_cancel_task, g_close_task)))
               AND prot_proc_elem.flg_status = act.from_state
               AND act.subject = g_task;
    
        l_rec c_status%ROWTYPE;
        error_undefined EXCEPTION;
        l_sysdate TIMESTAMP WITH TIME ZONE := current_timestamp;
        b_result  BOOLEAN;
    
        --Scheduler 3.0 variable 
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'GET ACTION STATES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_status;
    
        FETCH c_status
            INTO l_rec;
    
        IF c_status%NOTFOUND
        THEN
            CLOSE c_status;
            RAISE error_undefined;
        END IF;
    
        CLOSE c_status;
    
        g_error := 'CHANGE STATE OF PROTOCOL_PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        UPDATE protocol_process
           SET flg_status       = l_rec.to_state,
               dt_status        = current_timestamp,
               cancel_notes     = decode(i_id_action, g_state_cancel_operation, i_cancel_notes),
               id_prof_cancel   = decode(i_id_action, g_state_cancel_operation, i_prof.id),
               id_cancel_reason = decode(i_id_action, g_state_cancel_operation, i_id_cancel_reason)
         WHERE id_protocol_process = i_id_protocol_process;
    
        g_error := 'CHANGE STATE OF PROTOCOL_PROCESS_ELEMENTS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec_elem IN c_elem_status(l_rec.to_state)
        LOOP
        
            IF (rec_elem.element_type = g_element_task AND rec_elem.from_state = g_process_running)
            THEN
                -- cancel task request
                b_result := cancel_task_request(i_lang,
                                                i_prof,
                                                rec_elem.task_type,
                                                rec_elem.id_request,
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
        
            UPDATE protocol_process_element
               SET flg_status       = rec_elem.to_state,
                   dt_status        = l_sysdate,
                   id_professional  = i_prof.id,
                   id_cancel_reason = i_id_cancel_reason,
                   cancel_notes     = i_cancel_notes
             WHERE id_protocol_process_elem = rec_elem.id_protocol_process_elem;
        
        END LOOP;
    
        COMMIT;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on cancel protocol task
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REC_PROTOCOL_STATUS',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
        
            RETURN FALSE;
            -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REC_PROTOCOL_STATUS',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END set_rec_protocol_status;

    /** Wrapper for FLASH. DO NOT USE OTHERWISE. */
    FUNCTION set_rec_protocol_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_action           IN action.id_action%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN
    
     IS
    
    BEGIN
    
        RETURN set_rec_protocol_status(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_protocol_process => i_id_protocol_process,
                                       i_id_action           => i_id_action,
                                       i_id_episode          => i_id_episode,
                                       i_id_cancel_reason    => i_id_cancel_reason,
                                       i_cancel_notes        => i_cancel_notes,
                                       i_transaction_id      => NULL,
                                       o_error               => o_error);
    
    END set_rec_protocol_status;

    /**
    *  cancel recomended protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel       
    * @param      I_ID_ACTION                 Action to execute
    
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_rec_protocol
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        i_transaction_id      IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        error_undefined EXCEPTION;
        b_result BOOLEAN;
    
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'CANCEL REC PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        b_result := set_rec_protocol_status(i_lang,
                                            i_prof,
                                            i_id_protocol_process,
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
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Error changing state to cancelled',
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REC_PROTOCOL',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REC_PROTOCOL',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_rec_protocol;

    /** Flash Wrapper. DO NOT USE OTHERWISE */
    FUNCTION cancel_rec_protocol
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN cancel_rec_protocol(i_lang                => i_lang,
                                   i_prof                => i_prof,
                                   i_id_protocol_process => i_id_protocol_process,
                                   i_id_episode          => i_id_episode,
                                   i_id_cancel_reason    => i_id_cancel_reason,
                                   i_cancel_notes        => i_cancel_notes,
                                   i_transaction_id      => NULL,
                                   o_error               => o_error);
    
    END cancel_rec_protocol;

    /********************************************************************************************
    * get all frequent protocols
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT           Patient ID
    * @param      I_ID_EPISODE           Episode ID
    * @param      i_flg_filter                protocols filter   
    * @param      I_VALUE                Value to search for
    * @param      o_protocol_frequent         protocols cursor
    * @param      O_ERROR                error
    *
    * @value      i_flg_filter                {*} 'C' filtered by chief complaint
    *                                         {*} 'S' filtered by i_prof specialty 
    *                                         {*} 'F' all frequent protocols
    * 
    * @return     boolean                     true or false on success or error
    *
    * @author     Tiago Silva
    * @since      13-Jul-2007
    ********************************************************************************************/
    FUNCTION get_protocol_frequent
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN protocol_process.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_filter        IN VARCHAR2,
        i_value             IN VARCHAR2,
        o_protocol_frequent OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_gender   patient.gender%TYPE;
        l_institutions table_number;
        l_id_complaint table_number;
        l_exception EXCEPTION;
        l_filter VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'GET PATIENT GENDER';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT gender
          INTO l_pat_gender
          FROM patient
         WHERE id_patient = i_id_patient;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET CHIEF COMPLAINT FOR EPISODE';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_filter := i_flg_filter; -- staring mode for l_filter condition
        IF i_flg_filter = g_prot_filter_chief_compl
        THEN
            IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_id_episode,
                                                       o_id_complaint => l_id_complaint,
                                                       o_error        => o_error)
            THEN
                RAISE l_exception;
            END IF;
            -- if no complaint was associated with the patient, then show all frequent protocols
            IF l_id_complaint IS NULL
            THEN
                l_filter := g_prot_filter_frequent;
            END IF;
        END IF;
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_frequent FOR
            SELECT id_protocol,
                   protocol_title,
                   rank,
                   check_history_protocol(id_protocol, i_id_patient) AS flg_already_recommended
              FROM (SELECT DISTINCT (prot.id_protocol),
                                    prot.protocol_desc AS protocol_title,
                                    nvl((SELECT pf.rank
                                          FROM protocol_frequent pf
                                         WHERE pf.id_institution = i_prof.institution
                                           AND pf.id_software IN (g_all_software, i_prof.software)
                                           AND pf.id_protocol = prot.id_protocol),
                                        -1) AS rank
                      FROM protocol          prot,
                           protocol_link     prot_lnk,
                           protocol_link     prot_lnk2,
                           protocol_criteria prot_crit_exc,
                           protocol_criteria prot_crit_inc
                     WHERE prot.flg_status = g_protocol_finished
                       AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                                    column_value
                                                     FROM TABLE(l_institutions) inst)
                       AND ( -- protocols edited by the professional
                            EXISTS (SELECT 1
                                      FROM protocol edit_prot
                                     WHERE edit_prot.id_professional = i_prof.id
                                       AND rownum = 1
                                     START WITH edit_prot.id_protocol = prot.id_protocol
                                    CONNECT BY PRIOR edit_prot.id_protocol = edit_prot.id_protocol_previous_version) OR
                           -- protocols as most frequent
                            EXISTS (SELECT 1
                                      FROM protocol_frequent pft
                                     WHERE pft.id_institution = i_prof.institution
                                       AND pft.id_software IN (g_all_software, i_prof.software)
                                       AND pft.id_protocol = prot.id_protocol))
                          -- professional category
                       AND prot_lnk.id_protocol = prot.id_protocol
                       AND prot_lnk.link_type = g_protocol_link_prof
                       AND prot_lnk.id_link = (SELECT pc.id_category
                                                 FROM prof_cat pc
                                                WHERE pc.id_professional = i_prof.id
                                                  AND pc.id_institution = i_prof.institution)
                          -- specialty or chief complaint
                       AND prot_lnk2.id_protocol = prot.id_protocol
                       AND prot_lnk2.link_type IN (g_protocol_link_spec, g_protocol_link_chief_compl)
                       AND ((prot_lnk2.id_link IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                    *
                                                     FROM TABLE(l_id_complaint) t) AND
                           l_filter = g_protocol_link_chief_compl) OR
                           (prot_lnk2.id_link = decode(i_prof.software,
                                                        pk_alert_constant.g_soft_primary_care,
                                                        (SELECT e.id_cs_requested
                                                           FROM episode e
                                                          WHERE e.id_episode = i_id_episode),
                                                        (SELECT id_speciality
                                                           FROM professional
                                                          WHERE id_professional = i_prof.id)) AND
                           l_filter = g_protocol_link_spec) OR
                           (prot_lnk2.id_link = prot_lnk2.id_link AND
                           l_filter NOT IN (g_protocol_link_spec, g_protocol_link_chief_compl)))
                          -- department/environment
                       AND i_prof.software IN (SELECT sd.id_software
                                                 FROM software_dept sd, protocol_link prot_lnk3
                                                WHERE prot_lnk3.id_protocol = prot.id_protocol
                                                  AND prot_lnk3.link_type = g_protocol_link_envi
                                                  AND prot_lnk3.id_link = sd.id_dept)
                          -- search for value
                       AND ((translate(upper(prot.protocol_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                           '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                           i_value IS NOT NULL) OR i_value IS NULL)
                          -- check patient gender
                       AND prot_crit_inc.id_protocol = prot.id_protocol
                       AND prot_crit_inc.criteria_type = g_criteria_type_inc
                       AND nvl(prot_crit_inc.gender, l_pat_gender) = l_pat_gender
                       AND prot_crit_exc.id_protocol = prot.id_protocol
                       AND prot_crit_exc.criteria_type = g_criteria_type_exc
                       AND ((l_pat_gender != prot_crit_exc.gender AND prot_crit_exc.gender IS NOT NULL) OR
                           prot_crit_exc.gender IS NULL))
             ORDER BY rank, upper(protocol_title);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REC_PROTOCOL',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_frequent);
            RETURN FALSE;
    END get_protocol_frequent;

    /**
    *  Verify if a protocol task is available for the software, institution and professional
    *
    * @param      I_LANG             Prefered language ID for this professional
    * @param      I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE        Type of the task
    * @param      I_ID_TASK          Task ID
    * @param      I_ID_TASK_ATTACH   Auxiliary ID associated to the task   
    * @param      i_id_episode       ID of the current episode 
    *
    * @return     VARCHAR2 (Y - available / N - not available)
    * @author     TS
    * @version    0.2
    * @since      2007/09/27
    */
    FUNCTION get_task_avail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_type      IN protocol_task.task_type%TYPE,
        i_id_task        IN protocol_task.id_task_link%TYPE,
        i_id_task_attach IN protocol_task.id_task_attach%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
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
    
        l_req    pk_types.cursor_type;
        l_create VARCHAR2(1 CHAR);
    
        l_ret BOOLEAN;
        l_cat category.flg_type%TYPE;
    
        l_market market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
    BEGIN
    
        g_error := 'VERIFY IF TASK IS AVAILABLE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- verify if the task type is available for this software and institution
        IF (check_task_type_soft_inst(i_lang, i_prof, i_task_type) = g_not_available)
        THEN
            RETURN g_not_available;
        END IF;
    
        -- ALERT-18697
        -- check if task is available for execution if patient is inactive, or active but in scheduling or in an EHR event
        g_error := 'CALL CHECK_AREA_CREATE_PERMISSION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
    
        -- if is an appointment (follow-up or specialty)
        IF (i_task_type = g_task_appoint)
        THEN
            -- validate if professional can request appointments
            l_ret := pk_consult_req.get_subs_req_amb(i_lang     => i_lang,
                                                     i_epis     => i_id_episode,
                                                     i_prof     => i_prof,
                                                     i_flg_type => CASE
                                                                       WHEN i_id_task = '-1' THEN
                                                                        g_cons_followup
                                                                       ELSE
                                                                        g_cons_spec
                                                                   END,
                                                     o_req      => l_req,
                                                     o_create   => l_create,
                                                     o_error    => l_error);
        
            l_cat := pk_prof_utils.get_category(i_lang, i_prof);
        
            IF l_create = g_no
               OR (i_task_type = g_task_appoint AND i_id_task != '-1' AND l_cat = pk_alert_constant.g_cat_type_nurse) -- ALERT-693: do not allow specialty appointments for nurses
            THEN
                RETURN g_not_available;
            END IF;
        
            -- if is an appointment, but not the follow-up one (i.e. specialty appointment)
            -- proceed to the specialty appointments filter
            IF (i_task_type = g_task_appoint AND i_id_task != '-1')
            THEN
                -- filter to enable/disable specialty appointments, even if follow-up appointments are enabled
                SELECT COUNT(1)
                  INTO l_count_results
                  FROM (SELECT item,
                               first_value(pisi.flg_available) over(PARTITION BY pisi.item, pisi.flg_item_type ORDER BY pisi.id_market DESC, pisi.id_institution DESC, pisi.id_software DESC, pisi.flg_available) AS flg_avail
                          FROM protocol_item_soft_inst pisi
                         WHERE pisi.id_institution IN (g_all_institution, i_prof.institution)
                           AND pisi.id_software IN (g_all_software, i_prof.software)
                           AND pisi.id_market IN (g_all_markets, l_market)
                           AND flg_item_type = g_protocol_item_tasks
                           AND item IN (g_task_appoint, g_task_specialty_appointment))
                 WHERE (item = g_task_specialty_appointment AND flg_avail = g_not_available)
                    OR (item = g_task_appoint AND flg_avail = g_not_available);
            
                -- check result
                IF (l_count_results != 0)
                THEN
                    RETURN g_not_available;
                END IF;
            END IF;
        END IF;
    
        -- check result
        IF l_available = g_no
        THEN
            RETURN g_not_available;
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
    *  Get protocol tasks recommended
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PROTOCOL_PROCESS        ID of protocol process
    * @param      i_id_episode                 ID of the current episode
    * @param      DT_SERVER                    Current server time
    * @param      O_PROTOCOL_RECOMMENDED       protocol recomended for specific user
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_recommended_tasks
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN table_number,
        i_id_episode          IN episode.id_episode%TYPE,
        dt_server             OUT VARCHAR2,
        o_task_recommended    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient protocol_process.id_patient%TYPE;
    BEGIN
        g_error := 'GET PATIENT ID';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT id_patient
          INTO l_id_patient
          FROM protocol_process
         WHERE id_protocol_process = i_id_protocol_process(1);
    
        g_error := 'GET RECOMMENDED PROTOCOL TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_task_recommended FOR
            SELECT /*+opt_estimate(table prot_proc_list rows=1)*/
             id_protocol_process,
             id_protocol_process_elem,
             task_type,
             decode(prot_task.task_type,
                    g_task_patient_education,
                    CASE prot_task.id_task_link
                        WHEN '-1' THEN
                         prot_task.task_notes
                        ELSE
                         pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang, i_prof, prot_task.id_task_link)
                    END,
                    g_task_spec,
                    get_task_id_desc(i_lang,
                                     i_prof,
                                     prot_task.id_task_link,
                                     prot_task.task_type,
                                     prot_task.task_codification) ||
                    decode(id_task_attach,
                           '-1', -- physician = <any>
                           '',
                           nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach),
                                ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach) || ')',
                                NULL)),
                    get_task_id_desc(i_lang,
                                     i_prof,
                                     prot_task.id_task_link,
                                     prot_task.task_type,
                                     prot_task.task_codification)) || ' - ' ||
             pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, task_type, 0) AS str_desc, -- TODO: to be discontinued
             
             flg_status AS flg_status,
             pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol_elem, flg_status) rank,
             
             '0' || '|' ||
             pk_date_utils.date_send_tsz(i_lang,
                                         decode(flg_status,
                                                g_process_scheduled,
                                                (SELECT dvalue
                                                   FROM protocol_process_task_det prot_proc_task_det
                                                  WHERE prot_proc_task_det.id_protocol_process_elem =
                                                        prot_proc_tsk.id_protocol_process_elem
                                                    AND prot_proc_task_det.flg_detail_type = g_proc_task_det_next_rec),
                                                g_process_running,
                                                dt_request,
                                                dt_status),
                                         i_prof) --'xxxxxxxxxxxxxx'
             || '|' ||
             decode(flg_status,
                    g_process_running,
                    decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request), g_scheduled, g_text, g_date),
                    g_process_scheduled,
                    g_text_icon,
                    g_process_finished,
                    g_text_icon,
                    g_icon) || '|' ||
             decode(pk_sysdomain.get_img(i_lang, g_domain_flg_protocol_elem, flg_status),
                    g_alert_icon,
                    decode(flg_status, g_process_scheduled, g_green_color, g_red_color),
                    g_waiting_icon,
                    g_red_color,
                    decode(flg_status,
                           g_process_running,
                           decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                                  g_scheduled,
                                  g_green_color,
                                  NULL),
                           NULL)) || '|' ||
             decode(flg_status,
                    g_process_running,
                    decode(get_task_request_schedule(i_lang, i_prof, task_type, id_request),
                           g_scheduled,
                           pk_message.get_message(i_lang, g_message_scheduled),
                           NULL),
                    pk_sysdomain.get_img(i_lang, g_domain_flg_protocol_elem, flg_status)) || '|' ||
             decode(flg_status,
                    g_process_scheduled,
                    pk_date_utils.get_elapsed_tsz_years(i_lang,
                                                        (SELECT dvalue
                                                           FROM protocol_process_task_det prot_proc_task_det
                                                          WHERE prot_proc_task_det.id_protocol_process_elem =
                                                                prot_proc_tsk.id_protocol_process_elem
                                                            AND prot_proc_task_det.flg_detail_type =
                                                                g_proc_task_det_next_rec)),
                    pk_date_utils.dt_chr_year_short_tsz(i_lang,
                                                        decode(flg_status, g_process_running, dt_request, dt_status),
                                                        i_prof)) AS status,
             flg_active,
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
                                   AND etg.id_exam = safe_to_number(prot_task.id_task_link)))
                       AND get_task_avail(i_lang,
                                          i_prof,
                                          task_type,
                                          prot_task.id_task_link,
                                          prot_task.id_task_attach,
                                          i_id_episode) = g_available THEN
                   g_available
              -- if the task is not executed yet, check task permissions and availability
                  WHEN task_type != g_task_img
                       AND flg_status IN (g_process_pending, g_process_recommended, g_process_suspended)
                       AND check_task_permissions(i_lang, i_prof, task_type) = g_available
                       AND get_task_avail(i_lang,
                                          i_prof,
                                          task_type,
                                          prot_task.id_task_link,
                                          prot_task.id_task_attach,
                                          i_id_episode) = g_available THEN
                  
                   g_available
              -- if the task is ongoing, check just check task availability
                  WHEN task_type != g_task_img
                       AND flg_status NOT IN (g_process_pending, g_process_recommended)
                       AND check_task_permissions(i_lang, i_prof, task_type) = g_available THEN
                   g_available
                  ELSE
                   g_not_available
              END) AS flg_avail,
             pk_sysdomain.get_domain(g_domain_task_type, task_type, i_lang) AS task_type_desc,
             decode(prot_task.task_type,
                    g_task_patient_education,
                    CASE prot_task.id_task_link
                        WHEN '-1' THEN
                         prot_task.task_notes
                        ELSE
                         pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang, i_prof, prot_task.id_task_link)
                    END,
                    g_task_spec,
                    get_task_id_desc(i_lang,
                                     i_prof,
                                     prot_task.id_task_link,
                                     prot_task.task_type,
                                     prot_task.task_codification) ||
                    decode(id_task_attach,
                           '-1', -- physician = <any>
                           '',
                           nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach),
                                ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, id_task_attach) || ')',
                                NULL)),
                    get_task_id_desc(i_lang,
                                     i_prof,
                                     prot_task.id_task_link,
                                     prot_task.task_type,
                                     prot_task.task_codification)) AS task_desc
              FROM protocol_process_element prot_proc_tsk,
                   protocol_task prot_task,
                   TABLE(i_id_protocol_process) prot_proc_list
             WHERE prot_proc_tsk.id_protocol_process = prot_proc_list.column_value
               AND prot_proc_tsk.element_type = g_element_task
               AND prot_task.id_protocol_task = prot_proc_tsk.id_protocol_task
             ORDER BY decode(flg_status,
                             g_process_suspended,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol_elem, g_process_canceled),
                             g_process_closed,
                             pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol_elem, g_process_canceled),
                             rank) ASC,
                      decode(flg_status, g_process_running, dt_request, NULL) ASC,
                      decode(flg_status, g_process_pending, str_desc, g_process_recommended, str_desc, NULL) ASC,
                      decode(flg_status,
                             g_process_finished,
                             dt_status,
                             g_process_suspended,
                             dt_status,
                             g_process_canceled,
                             dt_status,
                             g_process_closed,
                             dt_status,
                             NULL) DESC;
    
        -- return server time as close as possible to the end of function 
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECOMMENDED_TASKS',
                                              o_error);
            pk_types.open_my_cursor(o_task_recommended);
            RETURN FALSE;
    END get_recommended_tasks;

    /**
    *  Get protocol tasks recommended details
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_id_protocol_process_elem   ID da tarefa
    * @param      I_ID_EPISODE                 Episode ID         
    * @param      O_TASK_REC_DETAIL            Detail information for specific task
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_rec_task_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_task_type                IN protocol_task.task_type%TYPE,
        i_id_protocol_process_elem IN table_number,
        i_id_episode               IN episode.id_episode%TYPE,
        o_task_rec_detail          OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET RECOMMENDED PROTOCOL TASK DETAIL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_task_type = g_task_analysis)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value AS id_protocol_process_elem,
                 anl.id_analysis,
                 pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', anl.code_analysis, NULL) AS analysis_desc,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active,
                 nvl(ais.flg_harvest, g_yes) flg_col_inst,
                 prot_task.task_codification AS id_codification
                  FROM analysis_instit_soft ais,
                       analysis anl,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE anl.id_analysis = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value
                   AND ais.id_institution = i_prof.institution
                   AND ais.id_software = i_prof.software
                   AND ais.id_analysis = anl.id_analysis
                   AND ais.flg_available = g_available
                   AND ais.flg_type IN (pk_alert_constant.g_analysis_request, pk_alert_constant.g_analysis_exec);
        
        ELSIF (i_task_type = g_task_appoint)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 decode(prot_task.id_task_link, '-1', -1, appoint.id_dep_clin_serv) AS id_dep_clin_serv,
                 decode(prot_task.id_task_link,
                        '-1',
                        pk_message.get_message(i_lang, i_prof, g_message_foll_up_appoint),
                        pk_translation.get_translation(i_lang, appoint.code_clinical_service)) AS desc_appoint,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active
                  FROM (SELECT dcs.id_dep_clin_serv, cs.id_clinical_service, cs.code_clinical_service
                          FROM dep_clin_serv dcs, clinical_service cs
                         WHERE cs.id_clinical_service = dcs.id_clinical_service) appoint,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE appoint.id_dep_clin_serv(+) = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value;
        
        ELSIF (i_task_type = g_task_patient_education)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value AS id_protocol_process_elem,
                 nts.id_nurse_tea_subject AS id_subject,
                 pk_translation.get_translation(i_lang, nts.code_nurse_tea_subject) AS desc_subject,
                 ntt.id_nurse_tea_topic AS id_topic,
                 pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic) AS title_topic,
                 pk_translation.get_translation(i_lang, ntt.code_topic_description) AS desc_topic,
                 prot_task.task_notes AS notes,
                 prot_proc_elem.flg_active
                  FROM TABLE(i_id_protocol_process_elem) gpt
                 INNER JOIN protocol_process_element prot_proc_elem
                    ON prot_proc_elem.id_protocol_process_elem = gpt.column_value
                 INNER JOIN protocol_task prot_task
                    ON prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                 INNER JOIN nurse_tea_topic ntt
                    ON ntt.id_nurse_tea_topic = safe_to_number(prot_task.id_task_link)
                 INNER JOIN nurse_tea_subject nts
                    ON ntt.id_nurse_tea_subject = nts.id_nurse_tea_subject;
        
        ELSIF (i_task_type = g_task_img)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 ex.id_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam) AS desc_image_exams,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active,
                 decode(type_exam.id_exam, NULL, g_not_available, g_available) flg_preg_ultrasound,
                 prot_task.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'E', ex.id_exam) flg_laterality_mcdt
                  FROM exam ex,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt,
                       (SELECT etg.id_exam
                          FROM exam_type_group etg, exam_type et
                         WHERE etg.id_software IN (i_prof.software, g_all_software)
                           AND etg.id_institution IN (i_prof.institution, g_all_institution)
                           AND et.flg_type = g_exam_pregnant_ultrasound
                           AND et.id_exam_type = etg.id_exam_type) type_exam
                 WHERE ex.id_exam = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value
                   AND ex.flg_type = g_exam_only_img
                   AND type_exam.id_exam(+) = ex.id_exam;
        
        ELSIF (i_task_type = g_task_vacc)
        THEN
            pk_types.open_my_cursor(o_task_rec_detail);
        ELSIF (i_task_type = g_task_enfint)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 enfint.id_composition,
                 pk_translation.get_translation(i_lang, enfint.code_icnp_composition) AS desc_enfint,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active
                  FROM icnp_composition enfint,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE enfint.id_composition = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value;
        
        ELSIF (i_task_type = g_task_otherexam)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 id_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, ex.code_exam) AS desc_other_exams,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active,
                 prot_task.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'E', ex.id_exam) flg_laterality_mcdt
                  FROM exam ex,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE ex.id_exam = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value
                   AND ex.flg_type != g_exam_only_img;
        
        ELSIF (i_task_type = g_task_spec)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 id_speciality,
                 pk_translation.get_translation(i_lang, spec.code_speciality) AS desc_specialty,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active,
                 prot_task.id_task_attach
                  FROM speciality spec,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE spec.id_speciality = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value;
        
        ELSIF (i_task_type = g_task_rast)
        THEN
            pk_types.open_my_cursor(o_task_rec_detail);
        
        ELSIF (i_task_type = g_task_proc)
        THEN
            OPEN o_task_rec_detail FOR
                SELECT /*+opt_estimate(table gpt rows=1)*/
                 gpt.column_value id_protocol_process_elem,
                 id_intervention AS id_procedure,
                 pk_procedures_api_db.get_alias_translation(i_lang, i_prof, interv.code_intervention, NULL) AS desc_procedure,
                 prot_task.task_notes,
                 prot_proc_elem.flg_active,
                 prot_task.task_codification AS id_codification,
                 pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'I', id_intervention) flg_laterality_mcdt
                  FROM intervention interv,
                       protocol_process_element prot_proc_elem,
                       protocol_task prot_task,
                       TABLE(i_id_protocol_process_elem) gpt
                 WHERE interv.id_intervention = safe_to_number(prot_task.id_task_link)
                   AND prot_task.id_protocol_task = prot_proc_elem.id_protocol_task
                   AND prot_proc_elem.id_protocol_process_elem = gpt.column_value;
        ELSE
            pk_types.open_my_cursor(o_task_rec_detail);
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
                                              'GET_REC_TASK_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_task_rec_detail);
            RETURN FALSE;
    END get_rec_task_detail;

    /**
    *  Calculates the next recommendation date for a protocol task
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS_ELEM  Protocol process ID
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/09/27
    */
    FUNCTION reset_task_frequency
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN protocol_process_element.id_protocol_process_elem%TYPE
    ) RETURN BOOLEAN IS
        l_freq_detail protocol_process_task_det.vvalue%TYPE;
        l_sysdate     TIMESTAMP WITH TIME ZONE := current_timestamp;
    BEGIN
    
        g_error := 'GET TASK FREQUENCY';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- get task frequency
        SELECT vvalue
          INTO l_freq_detail
          FROM protocol_process_task_det
         WHERE id_protocol_process_elem = i_id_protocol_process_elem
           AND flg_detail_type = g_proc_task_det_freq;
    
        g_error := 'UPDATE REC TASK DATE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- update recommendation date
        UPDATE protocol_process_task_det
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
           AND id_protocol_process_elem = i_id_protocol_process_elem;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'TASK WITHOUT FREQUENCY';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            RETURN FALSE;
    END reset_task_frequency;

    /**
    *  Change state of recomended tasks for a protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_id_protocol_process_elem  Protocol process ID
    * @param      I_ID_ACTION                 Action ID
    * @param      I_ID_REQUEST                Request ID
    * @param      I_DT_REQUEST                Date of request
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel         
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION set_rec_task_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN table_number,
        i_id_action                IN table_number,
        i_id_request               IN table_number,
        i_dt_request               IN VARCHAR2,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes             IN VARCHAR2,
        i_transaction_id           IN VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_status
        (
            c_id_protocol_process_elem protocol_process_element.id_protocol_process_elem%TYPE,
            c_id_action                action.id_action%TYPE
        ) IS
            SELECT prot_proc_tsk.id_protocol_process_elem,
                   prot_proc_tsk.id_protocol_process,
                   prot_proc_tsk.flg_status,
                   prot_proc_tsk.id_request,
                   prot_proc_tsk.dt_request,
                   prot_proc_tsk.flg_active,
                   prot_proc_tsk.element_type,
                   prot_tsk.task_type,
                   act.from_state,
                   act.to_state
              FROM protocol_process_element prot_proc_tsk, action act, protocol_task prot_tsk
             WHERE prot_proc_tsk.id_protocol_process_elem = c_id_protocol_process_elem
               AND act.id_action = decode(c_id_action, g_state_cancel_operation, act.id_action, c_id_action)
               AND (c_id_action != g_state_cancel_operation OR
                   (c_id_action = g_state_cancel_operation AND act.to_state IN (g_cancel_task, g_close_task)))
               AND act.from_state = prot_proc_tsk.flg_status
               AND act.subject = g_task
               AND prot_proc_tsk.id_protocol_task = prot_tsk.id_protocol_task;
    
        l_rec            c_status%ROWTYPE;
        l_sysdate        TIMESTAMP WITH TIME ZONE := current_timestamp;
        b_result         BOOLEAN;
        l_request_status protocol_process_element.flg_status%TYPE;
        error_undefined   EXCEPTION;
        error_id_req_null EXCEPTION;
    
        -- Scheduler 3.0
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        IF i_id_protocol_process_elem.count != 0
        THEN
            FOR i IN i_id_protocol_process_elem.first .. i_id_protocol_process_elem.last
            LOOP
                g_error := 'GET ACTION STATES';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                OPEN c_status(i_id_protocol_process_elem(i), i_id_action(i));
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
                    pk_alertlog.log_debug(g_error, g_package_name);
                
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
            
                l_request_status := NULL;
            
                -- reset task frequency
                IF l_rec.to_state = g_process_finished
                THEN
                
                    g_error := 'RESET TASK FREQUENCY';
                    pk_alertlog.log_debug(g_error, g_package_name);
                
                    IF (reset_task_frequency(i_lang, i_prof, l_rec.id_protocol_process_elem))
                    THEN
                        l_request_status := g_process_scheduled;
                    END IF;
                
                END IF;
            
                g_error := 'VERIFY IF REQUEST ID SHOULD BE NULL';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                IF (l_rec.to_state = g_process_running AND i_id_request(i) IS NULL)
                THEN
                    RAISE error_id_req_null;
                END IF;
            
                g_error := 'CHANGE STATE OF PROTOCOL_PROCESS TASK';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                UPDATE protocol_process_element
                   SET flg_status       = nvl(l_request_status, l_rec.to_state),
                       dt_status        = l_sysdate,
                       id_request       = i_id_request(i),
                       dt_request       = nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_request, NULL),
                                              l_sysdate),
                       id_professional  = i_prof.id,
                       id_cancel_reason = i_id_cancel_reason,
                       cancel_notes     = i_cancel_notes
                 WHERE id_protocol_process_elem = l_rec.id_protocol_process_elem;
            
                g_error := 'UPDATE PROTOCOL_PROCESS TASK STATE';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                b_result := update_prot_proc_task_status(i_lang, i_prof, l_rec.id_protocol_process, o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            
            END LOOP;
        END IF;
    
        COMMIT;
    
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- Error request ID is NULL
        WHEN error_id_req_null THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / REQUEST ID CANNOT BE NULL',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
            -- Error on protocol process status update
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
            -- Other errors not included in the previous exception type           
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REC_TASK_STATUS',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_rec_task_status;

    /* Wrapper for flash invocation . DO NOT USE OTHERWISE !! */
    FUNCTION set_rec_task_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN table_number,
        i_id_action                IN table_number,
        i_id_request               IN table_number,
        i_dt_request               IN VARCHAR2,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes             IN VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN set_rec_task_status(i_lang                     => i_lang,
                                   i_prof                     => i_prof,
                                   i_id_protocol_process_elem => i_id_protocol_process_elem,
                                   i_id_action                => i_id_action,
                                   i_id_request               => i_id_request,
                                   i_dt_request               => i_dt_request,
                                   i_id_episode               => i_id_episode,
                                   i_id_cancel_reason         => i_id_cancel_reason,
                                   i_cancel_notes             => i_cancel_notes,
                                   i_transaction_id           => NULL,
                                   o_error                    => o_error);
    
    END set_rec_task_status;

    /**
    *  Cancel recomended task for a protocol
    *
    * @param      I_LANG                 Preferred language ID
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS  ID of the protocol process
    * @param      I_ID_PROTOCOL_ELEMENT  ID of the protocol element
    * @param      i_id_episode           episode id
    * @param      i_id_cancel_reason     cancel reason that justifies the task cancel
    * @param      i_cancel_notes         cancel notes (free text) that justifies the task cancel            
    
    * @param      O_ERROR                Error message
    *
    * @return     Boolean
    * @author     TS
    * @version    1.0
    * @since      2009/03/06
    */
    FUNCTION cancel_rec_task
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element IN protocol_process_element.id_protocol_element%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        error_undefined EXCEPTION;
        b_result BOOLEAN;
    
        CURSOR c_prot_proc_elem
        (
            c_id_protocol_process protocol_process_element.id_protocol_process%TYPE,
            c_id_protocol_element protocol_process_element.id_protocol_element%TYPE
        ) IS
            SELECT prot_proc_tsk.id_protocol_process_elem, g_state_cancel_operation AS id_action, NULL AS id_request
              FROM protocol_process_element prot_proc_tsk
             WHERE prot_proc_tsk.id_protocol_process = c_id_protocol_process
               AND prot_proc_tsk.id_protocol_element = c_id_protocol_element
               AND prot_proc_tsk.flg_status = g_process_running;
    
        ibt_prot_proc_elem_ids table_number;
        ibt_id_action          table_number;
        ibt_id_request         table_number;
    
        --Scheduler 3.0 Variables
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'OPEN CURSOR WITH PROTOCOL PROCESS ELEMENT IDS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN c_prot_proc_elem(i_id_protocol_process, i_id_protocol_element);
        FETCH c_prot_proc_elem BULK COLLECT
            INTO ibt_prot_proc_elem_ids, ibt_id_action, ibt_id_request;
        CLOSE c_prot_proc_elem;
    
        g_error := 'GET ACTION STATES';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        b_result := set_rec_task_status(i_lang,
                                        i_prof,
                                        ibt_prot_proc_elem_ids,
                                        ibt_id_action,
                                        ibt_id_request,
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
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Error changing state to cancelled',
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REC_TASK',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_REC_TASK',
                                              o_error);
        
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_rec_task;

    /**
    *  Get context info regarding a protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_protocol               protocol ID
    * @param      O_protocol_HELP                       Cursor with all help information / context
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_help
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_help OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_help FOR
            SELECT prot.id_protocol,
                   prot.protocol_desc,
                   get_link_id_str(i_lang, i_prof, i_id_protocol, g_protocol_link_pathol, g_separator) AS desc_path,
                   prot.context_desc,
                   prot.context_title,
                   prot.context_adaptation,
                   prot.context_type_media,
                   get_context_author_str(i_lang, i_prof, i_id_protocol, g_separator2) AS context_author,
                   prot.context_editor,
                   prot.context_edition_site,
                   prot.context_edition,
                   prot.context_access,
                   prot.id_context_language,
                   prot.id_context_associated_language
              FROM protocol prot
             WHERE prot.id_protocol = i_id_protocol;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_HELP',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_help);
            RETURN FALSE;
    END get_protocol_help;
    /**
    *  Get history details for  a protocol task
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       Process ID
    * @param      O_PROTOCOL_DETAIL           Cursor with all help information / context
    * @param      O_PROTOCOL_PROC_INFO        Cursor with protocol process information
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */

    FUNCTION get_protocol_detail_hst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_protocol_detail     OUT pk_types.cursor_type,
        o_protocol_proc_info  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET PROTOCOL PROCCESS CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_proc_info FOR
            SELECT id_protocol,
                   flg_status,
                   protocol_desc,
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
              FROM (SELECT prot.id_protocol id_protocol,
                           prot_proc.flg_status flg_status,
                           prot.protocol_desc protocol_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_pathol, g_separator2) pathology_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_type, g_separator) type_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_envi, g_separator) environment_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_spec, g_separator) speciality_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_prof, g_separator) professional_desc,
                           get_link_id_str(i_lang, i_prof, prot.id_protocol, g_protocol_link_chief_compl, g_separator) AS chief_complaint_desc,
                           prot.flg_type_recommendation AS flg_type_rec,
                           pk_sysdomain.get_domain(g_domain_flg_type_rec, prot.flg_type_recommendation, i_lang) AS desc_recommendation,
                           pk_sysdomain.get_domain(g_domain_flg_protocol, prot_proc.flg_status, i_lang) AS status_desc,
                           decode(prot_proc.flg_status,
                                  g_process_canceled,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, prot_proc.id_prof_cancel),
                                  NULL) AS prof_cancel,
                           decode(prot_proc.flg_status,
                                  g_process_canceled,
                                  pk_prof_utils.get_prof_speciality(i_lang,
                                                                    profissional(prot_proc.id_prof_cancel,
                                                                                 i_prof.institution,
                                                                                 i_prof.software)),
                                  NULL) cancel_prof_spec,
                           prot_proc.cancel_notes,
                           decode(prot_proc.flg_status,
                                  g_process_canceled,
                                  pk_date_utils.date_send_tsz(i_lang, prot_proc.dt_status, i_prof)) AS cancel_date,
                           nvl2(id_cancel_reason,
                                pk_translation.get_translation(i_lang,
                                                               'CANCEL_REASON.CODE_CANCEL_REASON.' || id_cancel_reason),
                                NULL) AS cancel_reason
                      FROM protocol prot, protocol_process prot_proc
                     WHERE prot.id_protocol = prot_proc.id_protocol
                       AND prot_proc.id_protocol_process = i_id_protocol_process);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_detail FOR
            SELECT prot_proc_task.id_protocol_process_elem,
                   prot_proc_task.element_type,
                   prot_proc_task.id_protocol_element,
                   prot_task.task_type,
                   prot_task.id_task_link,
                   prot_task.task_codification,
                   pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_task.task_type, 0) AS task_type_desc,
                   decode(prot_task.task_type,
                          g_task_patient_education,
                          CASE prot_task.id_task_link
                              WHEN '-1' THEN
                               prot_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.id_task_link)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification) ||
                          decode(prot_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach),
                                      ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach) || ')',
                                      NULL)),
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification)) AS task_desc,
                   decode(prot_task.task_type,
                          g_task_patient_education,
                          CASE prot_task.id_task_link
                              WHEN '-1' THEN
                               prot_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       prot_task.id_task_link)
                          END,
                          g_task_spec,
                          get_task_id_desc(i_lang,
                                           i_prof,
                                           prot_task.id_task_link,
                                           prot_task.task_type,
                                           prot_task.task_codification) ||
                          decode(prot_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach),
                                      ' (' || pk_prof_utils.get_name_signature(i_lang, i_prof, prot_task.id_task_attach) || ')',
                                      NULL))) || ' - ' ||
                   pk_sysdomain.get_domain(i_lang, i_prof, g_domain_task_type, prot_task.task_type, 0) AS task_id_desc,
                   prot_proc_task_hst.flg_status_new,
                   pk_sysdomain.get_domain(g_domain_flg_protocol_elem, prot_proc_task_hst.flg_status_new, i_lang) AS flg_status_new_desc,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      prot_proc_task_hst.dt_status_change,
                                                      i_prof.institution,
                                                      i_prof.software) AS dt_status_change,
                   prot_proc_task_hst.id_professional,
                   prof.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) AS name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) AS nick_name,
                   prot_proc_task_hst.lag_flg_status_new,
                   nvl2(prot_proc_task_hst.id_cancel_reason,
                        pk_translation.get_translation(i_lang,
                                                       'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                       prot_proc_task_hst.id_cancel_reason),
                        NULL) AS cancel_reason,
                   prot_proc_task_hst.cancel_notes
              FROM (SELECT ppeh.id_protocol_process_elem,
                           ppeh.id_professional,
                           ppeh.flg_status_new,
                           ppeh.dt_status_change,
                           ppeh.id_cancel_reason,
                           ppeh.cancel_notes,
                           -- get previous row to filter status to avoid duplicated lines
                           lag(ppeh.flg_status_new, 1) over(PARTITION BY ppeh.id_protocol_process_elem ORDER BY ppeh.dt_status_change) AS lag_flg_status_new
                      FROM protocol_process_element_hist ppeh
                      JOIN protocol_process_element
                        ON protocol_process_element.id_protocol_process_elem = ppeh.id_protocol_process_elem
                     WHERE protocol_process_element.id_protocol_process = i_id_protocol_process) prot_proc_task_hst,
                   protocol_process_element prot_proc_task,
                   protocol_task prot_task,
                   protocol_process prot_proc,
                   professional prof
             WHERE prot_proc_task_hst.id_protocol_process_elem = prot_proc_task.id_protocol_process_elem
               AND prot_proc_task.element_type = g_element_task
               AND prot_proc.id_protocol_process = prot_proc_task.id_protocol_process
               AND prot_proc.id_protocol_process = i_id_protocol_process
               AND prof.id_professional = prot_proc_task_hst.id_professional
               AND prot_task.id_protocol_task = prot_proc_task.id_protocol_task
               AND nvl(prot_proc_task_hst.lag_flg_status_new, -1) != prot_proc_task_hst.flg_status_new
               AND nvl(prot_proc_task.flg_status, -1) NOT IN (g_process_pending, g_process_recommended)
             ORDER BY prot_task.task_type, prot_task.id_task_link, prot_proc_task_hst.dt_status_change;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_DETAIL_HST',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_detail);
            RETURN FALSE;
    END get_protocol_detail_hst;

    /**
    *  Call run_batch function. To be called by a job.
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    *
    * @author     SB
    * @version    0.1
    * @since      2007/08/13
    */
    PROCEDURE run_batch_job
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        RESULT BOOLEAN;
    
        l_error t_error_out;
    BEGIN
    
        pk_alertlog.log_info('Protocols run_batch job START', g_package_name);
    
        -- Call run_batch function
        RESULT := run_batch(i_lang        => i_lang,
                            i_prof        => i_prof,
                            i_id_patient  => NULL,
                            i_batch_desc  => NULL,
                            i_id_protocol => NULL,
                            o_error       => l_error);
    
        IF (NOT RESULT)
        THEN
            ROLLBACK;
            pk_alertlog.log_error('Protocols run_batch job ERROR: ' || l_error.err_desc, g_package_name);
        ELSE
            COMMIT;
            pk_alertlog.log_info('Protocols run_batch job FINISHED OK.', g_package_name);
        END IF;
    END;

    /** 
    *  Check if a protocol can be recommended to a patient according its history
    *
    * @param      i_id_protocol   Protocol ID
    * @param      i_id_patient    Patient ID        
    *
    * @author     TS
    * @version    0.1
    * @since      2007/09/27
    */
    FUNCTION check_history_protocol
    (
        i_id_protocol protocol.id_protocol%TYPE,
        i_id_patient  protocol_process.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        RESULT VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'CHECK PROTOCOL HISTORY';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT decode(COUNT(1), 0, g_not_available, g_available)
          INTO RESULT
          FROM (
               -- the protocol should not be recommended again if it or
               -- any of its previous versions are currently active to the patient
                (SELECT id_protocol
                   FROM protocol prot
                  START WITH prot.id_protocol = i_id_protocol
                 CONNECT BY prot.id_protocol = PRIOR prot.id_protocol_previous_version
                 
                 INTERSECT
                 
                 SELECT prot_proc.id_protocol AS id_protocol
                   FROM protocol_process prot_proc
                  WHERE prot_proc.id_patient = i_id_patient
                    AND prot_proc.flg_status IN (g_process_running, g_process_pending, g_process_recommended))
               
                UNION ALL
               
               -- the protocol should not be recommended again unless it has been edited
                (SELECT prot_proc.id_protocol AS id_protocol
                   FROM protocol_process prot_proc
                  WHERE prot_proc.id_patient = i_id_patient
                    AND prot_proc.id_protocol = i_id_protocol
                    AND prot_proc.flg_status NOT IN (g_process_running, g_process_pending, g_process_recommended)));
    
        RETURN RESULT;
    END check_history_protocol;

    /**
    *  Pick up patients for specific protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply protocol to
    * @param      I_BATCH_DESC                 Batch Description
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION run_batch
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_batch_desc  IN protocol_batch.batch_desc%TYPE,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institutions table_number;
    
        -----------------------------------------------------------------------------
        -- Cursor with info regarding protocol
        -----------------------------------------------------------------------------
        CURSOR c_protocol IS
            SELECT prot.id_protocol,
                   ----------- inclusion
                   prot_crit_inc.gender               AS inc_gender,
                   prot_crit_inc.min_age              AS inc_min_age,
                   prot_crit_inc.max_age              AS inc_max_age,
                   prot_crit_inc.min_weight           AS inc_min_weight,
                   prot_crit_inc.max_weight           AS inc_max_weight,
                   prot_crit_inc.min_height           AS inc_min_height,
                   prot_crit_inc.max_height           AS inc_max_height,
                   prot_crit_inc.imc_min              AS inc_min_imc,
                   prot_crit_inc.imc_max              AS inc_max_imc,
                   prot_crit_inc.min_blood_pressure_s AS inc_min_blood_pressure_s,
                   prot_crit_inc.max_blood_pressure_s AS inc_max_blood_pressure_s,
                   prot_crit_inc.min_blood_pressure_d AS inc_min_blood_pressure_d,
                   prot_crit_inc.max_blood_pressure_d AS inc_max_blood_pressure_d,
                   ----------- exclusion
                   prot_crit_exc.gender               AS exc_gender,
                   prot_crit_exc.min_age              AS exc_min_age,
                   prot_crit_exc.max_age              AS exc_max_age,
                   prot_crit_exc.min_weight           AS exc_min_weight,
                   prot_crit_exc.max_weight           AS exc_max_weight,
                   prot_crit_exc.min_height           AS exc_min_height,
                   prot_crit_exc.max_height           AS exc_max_height,
                   prot_crit_exc.imc_min              AS exc_min_imc,
                   prot_crit_exc.imc_max              AS exc_max_imc,
                   prot_crit_exc.min_blood_pressure_s AS exc_min_blood_pressure_s,
                   prot_crit_exc.max_blood_pressure_s AS exc_max_blood_pressure_s,
                   prot_crit_exc.min_blood_pressure_d AS exc_min_blood_pressure_d,
                   prot_crit_exc.max_blood_pressure_d AS exc_max_blood_pressure_d
              FROM protocol prot, protocol_criteria prot_crit_inc, protocol_criteria prot_crit_exc
             WHERE prot.id_protocol = prot_crit_inc.id_protocol
               AND prot_crit_inc.criteria_type = g_criteria_type_inc
               AND prot.id_protocol = prot_crit_exc.id_protocol
               AND prot_crit_exc.criteria_type = g_criteria_type_exc
                  -- State of protocol
               AND prot.flg_status = g_protocol_finished
                  -- i_prof
               AND prot.id_institution IN (SELECT /*+opt_estimate(table inst rows=1)*/
                                            column_value
                                             FROM TABLE(l_institutions) inst)
               AND prot.flg_type_recommendation != g_type_rec_manual
                  --AND prot.id_software = i_prof.software
                  -- Criteria
               AND prot.id_protocol = nvl(i_id_protocol, prot.id_protocol)
                  -- Verify if this protocol can be recommnended in this software
               AND (nvl(i_prof.software, g_all_software) = g_all_software OR
                   i_prof.software IN (SELECT id_software
                                          FROM software_dept sd, protocol_link prot_lnk
                                         WHERE prot_lnk.id_protocol = prot.id_protocol
                                           AND prot_lnk.link_type = g_protocol_link_envi
                                           AND prot_lnk.id_link = sd.id_dept));
    
        -----------------------------------------------------------------------------
        -- Cursor with Patient info
        -----------------------------------------------------------------------------
        CURSOR c_patient_criteria(
                                  ----------- inclusion
                                  c_inc_gender               protocol_criteria.gender%TYPE,
                                  c_inc_min_age              protocol_criteria.min_age%TYPE,
                                  c_inc_max_age              protocol_criteria.max_age%TYPE,
                                  c_inc_min_weight           protocol_criteria.min_weight%TYPE,
                                  c_inc_max_weight           protocol_criteria.max_weight%TYPE,
                                  c_inc_min_height           protocol_criteria.min_height%TYPE,
                                  c_inc_max_height           protocol_criteria.max_height%TYPE,
                                  c_inc_min_imc              protocol_criteria.imc_min%TYPE,
                                  c_inc_max_imc              protocol_criteria.imc_max%TYPE,
                                  c_inc_min_blood_pressure_s protocol_criteria.min_blood_pressure_s%TYPE,
                                  c_inc_max_blood_pressure_s protocol_criteria.max_blood_pressure_s%TYPE,
                                  c_inc_min_blood_pressure_d protocol_criteria.min_blood_pressure_d%TYPE,
                                  c_inc_max_blood_pressure_d protocol_criteria.max_blood_pressure_d%TYPE,
                                  ----------- exclusion
                                  c_exc_gender               protocol_criteria.gender%TYPE,
                                  c_exc_min_age              protocol_criteria.min_age%TYPE,
                                  c_exc_max_age              protocol_criteria.max_age%TYPE,
                                  c_exc_min_weight           protocol_criteria.min_weight%TYPE,
                                  c_exc_max_weight           protocol_criteria.max_weight%TYPE,
                                  c_exc_min_height           protocol_criteria.min_height%TYPE,
                                  c_exc_max_height           protocol_criteria.max_height%TYPE,
                                  c_exc_min_imc              protocol_criteria.imc_min%TYPE,
                                  c_exc_max_imc              protocol_criteria.imc_max%TYPE,
                                  c_exc_min_blood_pressure_s protocol_criteria.min_blood_pressure_s%TYPE,
                                  c_exc_max_blood_pressure_s protocol_criteria.max_blood_pressure_s%TYPE,
                                  c_exc_min_blood_pressure_d protocol_criteria.min_blood_pressure_d%TYPE,
                                  c_exc_max_blood_pressure_d protocol_criteria.max_blood_pressure_d%TYPE,
                                  ----------- ID of protocol associated to the criterias
                                  c_id_protocol protocol.id_protocol%TYPE) IS
            SELECT id_patient, name, gender, desc_age, imc, weight, height
              FROM ((SELECT c.id_patient,
                            c.name,
                            c.gender,
                            c.dt_birth,
                            nvl(trunc(months_between(SYSDATE, c.dt_birth) / 12), c.age) AS desc_age,
                            pk_protocol.get_imc(xb.id_unit_measure, xb.value, xa.id_unit_measure, xa.value) AS imc,
                            xa.id_unit_measure,
                            decode(xa.id_unit_measure,
                                   g_imc_weight_default_um,
                                   xa.value,
                                   pk_unit_measure.get_unit_mea_conversion(xa.value,
                                                                           xa.id_unit_measure,
                                                                           g_imc_weight_default_um)) AS weight,
                            xb.id_unit_measure,
                            decode(xb.id_unit_measure,
                                   g_imc_height_default_um,
                                   xb.value,
                                   pk_unit_measure.get_unit_mea_conversion(xb.value,
                                                                           xb.id_unit_measure,
                                                                           g_imc_height_default_um)) AS height,
                            xc.id_unit_measure,
                            decode(xc.id_unit_measure,
                                   g_blood_pressure_default_um,
                                   xc.value,
                                   pk_unit_measure.get_unit_mea_conversion(xc.value,
                                                                           xc.id_unit_measure,
                                                                           g_blood_pressure_default_um)) AS blood_pressure_s,
                            xd.id_unit_measure,
                            decode(xd.id_unit_measure,
                                   g_blood_pressure_default_um,
                                   xd.value,
                                   pk_unit_measure.get_unit_mea_conversion(xd.value,
                                                                           xd.id_unit_measure,
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
                              WHERE t.rn = 1) xa,
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
                              WHERE t.rn = 1) xb,
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
                              WHERE t.rn = 1) xc,
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
                              WHERE t.rn = 1) xd
                      WHERE c.id_patient = xa.id_patient(+)
                        AND c.id_patient = xb.id_patient(+)
                        AND c.id_patient = xc.id_patient(+)
                        AND c.id_patient = xd.id_patient(+)
                        AND c.dt_deceased IS NULL
                     --AND c.flg_status = g_patient_active
                     
                     ))
            ----------------------------------------------------------------
             WHERE
            -- check if the protocol can be recommended to the patient
             check_history_protocol(c_id_protocol, id_patient) = g_not_available
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
    
        l_applicable          PLS_INTEGER := 0;
        l_id_protocol_batch   protocol_batch.id_protocol_batch%TYPE;
        l_id_protocol_process protocol_process.id_protocol_process%TYPE;
        l_counter             PLS_INTEGER := 0;
        error_create_process   EXCEPTION;
        error_update_processes EXCEPTION;
        b_result BOOLEAN;
    BEGIN
    
        g_error := 'UPDATE STATE OF PROTOCOL PROCESSES AND ASSOCIATED TASKS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        b_result := update_all_prot_proc_status(i_lang, i_prof, i_id_patient, o_error);
    
        IF (NOT b_result)
        THEN
            RAISE error_update_processes;
        END IF;
    
        COMMIT;
    
        g_error := 'RUN BATCH';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Create Batch
        INSERT INTO protocol_batch
            (id_protocol_batch, batch_desc, batch_type, dt_protocol_batch)
        VALUES
            (seq_protocol_batch.nextval,
             i_batch_desc,
             decode(i_id_patient,
                    NULL,
                    decode(i_id_protocol, NULL, g_batch_all, g_batch_ap_1g),
                    decode(i_id_protocol, NULL, g_batch_1p_ag, g_batch_1p_1g)),
             --        l_type,
             current_timestamp)
        RETURNING id_protocol_batch INTO l_id_protocol_batch;
    
        g_error := 'GET ALL INSTITUTIONS FROM THE SAME GROUP';
        pk_alertlog.log_debug(g_error, g_package_name);
        l_institutions := pk_list.tf_get_all_inst_group(i_prof.institution, pk_search.g_inst_grp_flg_rel_adt);
    
        g_error := 'GET PROTOCOL TO LOOK FOR';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- Get protocol for this Institution / Software
        FOR rec_prot IN c_protocol
        LOOP
        
            g_error := 'SEARCH PATIENTS FOR THIS PROTOCOL';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            -- Loop through patients
            FOR rec_pat IN c_patient_criteria(rec_prot.inc_gender,
                                              rec_prot.inc_min_age,
                                              rec_prot.inc_max_age,
                                              rec_prot.inc_min_weight,
                                              rec_prot.inc_max_weight,
                                              rec_prot.inc_min_height,
                                              rec_prot.inc_max_height,
                                              rec_prot.inc_min_imc,
                                              rec_prot.inc_max_imc,
                                              rec_prot.inc_min_blood_pressure_s,
                                              rec_prot.inc_max_blood_pressure_s,
                                              rec_prot.inc_min_blood_pressure_d,
                                              rec_prot.inc_max_blood_pressure_d,
                                              rec_prot.exc_gender,
                                              rec_prot.exc_min_age,
                                              rec_prot.exc_max_age,
                                              rec_prot.exc_min_weight,
                                              rec_prot.exc_max_weight,
                                              rec_prot.exc_min_height,
                                              rec_prot.exc_max_height,
                                              rec_prot.exc_min_imc,
                                              rec_prot.exc_max_imc,
                                              rec_prot.exc_min_blood_pressure_s,
                                              rec_prot.exc_max_blood_pressure_s,
                                              rec_prot.exc_min_blood_pressure_d,
                                              rec_prot.exc_max_blood_pressure_d,
                                              rec_prot.id_protocol)
            LOOP
                -- reset history of the previous criteria check
                l_applicable := 0;
            
                -- Check other criterias
                g_error := 'Check Other Criterias';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                g_error := 'Check Analysis';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check analysis
                SELECT COUNT(1)
                  INTO l_counter
                  FROM (
                       -- Inclusion
                        (SELECT to_number(inc.link_other_crit)
                           FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                          WHERE inc.link_other_crit_typ = g_protocol_analysis
                         MINUS
                         SELECT id_analysis AS id_link
                           FROM analysis_result
                          WHERE id_patient = rec_pat.id_patient) UNION ALL
                       -- Exclusion
                        (SELECT to_number(exc.link_other_crit)
                           FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc
                          WHERE exc.link_other_crit_typ = g_protocol_analysis
                         INTERSECT
                         SELECT id_analysis AS id_link
                           FROM analysis_result
                          WHERE id_patient = rec_pat.id_patient));
            
                l_applicable := l_applicable + nvl(l_counter, 0);
            
                g_error := 'Check Allergies';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check allergies
                IF (l_applicable = 0)
                THEN
                    -- Inclusion                     
                    SELECT abs(COUNT(id_allergy) - COUNT(link_other_crit)) + COUNT(flg_status) + COUNT(flg_type) AS counter
                      INTO l_counter
                      FROM (SELECT pat_all.id_allergy,
                                   inc.link_other_crit,
                                   -- check flg_status detail
                                   decode((SELECT vvalue
                                            FROM protocol_adv_input_value
                                           WHERE flg_type = g_adv_input_type_criterias
                                             AND id_adv_input_link = inc.id_protocol_criteria_link
                                             AND id_advanced_input_field = g_allergy_status_field
                                             AND vvalue != to_char(g_detail_any)),
                                          NULL,
                                          NULL,
                                          pat_all.flg_status,
                                          NULL,
                                          1) AS flg_status,
                                   -- ckeck flg_type detail
                                   decode((SELECT vvalue
                                            FROM protocol_adv_input_value
                                           WHERE flg_type = g_adv_input_type_criterias
                                             AND id_adv_input_link = inc.id_protocol_criteria_link
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
                                   TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_protocol_allergies
                               AND pat_all.id_allergy(+) = inc.link_other_crit);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    -- Exclusion
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc, pat_allergy
                     WHERE exc.link_other_crit_typ = g_protocol_allergies
                       AND id_patient = rec_prot.id_protocol
                       AND flg_status IN (g_allergy_active, g_allergy_passive)
                       AND pat_allergy.id_allergy = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(pat_allergy.flg_status, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM protocol_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_protocol_criteria_link
                                      AND id_advanced_input_field = g_allergy_status_field
                                      AND vvalue != to_char(g_detail_any)),
                                   pat_allergy.flg_status),
                               -1)
                          -- check flg_type detail
                       AND nvl(pat_allergy.flg_type, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM protocol_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_protocol_criteria_link
                                      AND id_advanced_input_field = g_allergy_react_field
                                      AND vvalue != to_char(g_detail_any)),
                                   pat_allergy.flg_type),
                               -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                g_error := 'Check Diagnosis';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check diagnosis
                IF (l_applicable = 0)
                THEN
                    -- Inclusion                     
                    SELECT abs(COUNT(id_link) - COUNT(link_other_crit)) + COUNT(flg_status) + COUNT(flg_nature) AS counter
                      INTO l_counter
                      FROM (SELECT prb.id_link,
                                   inc.link_other_crit,
                                   -- check flg_status detail
                                   decode((SELECT vvalue
                                            FROM protocol_adv_input_value
                                           WHERE flg_type = g_adv_input_type_criterias
                                             AND id_adv_input_link = inc.id_protocol_criteria_link
                                             AND id_advanced_input_field = g_diagnosis_status_field
                                             AND vvalue != to_char(g_detail_any)),
                                          NULL,
                                          NULL,
                                          prb.flg_status,
                                          NULL,
                                          1) AS flg_status,
                                   -- ckeck flg_type detail
                                   decode((SELECT vvalue
                                            FROM protocol_adv_input_value
                                           WHERE flg_type = g_adv_input_type_criterias
                                             AND id_adv_input_link = inc.id_protocol_criteria_link
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
                                   TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_protocol_diagnosis
                               AND prb.id_link(+) = inc.link_other_crit);
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    -- Exclusion
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc,
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
                     WHERE exc.link_other_crit_typ = g_protocol_diagnosis
                       AND prb.id_link = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(prb.flg_status, -1) = nvl(nvl((SELECT vvalue
                                                               FROM protocol_adv_input_value
                                                              WHERE flg_type = g_adv_input_type_criterias
                                                                AND id_adv_input_link = exc.id_protocol_criteria_link
                                                                AND id_advanced_input_field = g_diagnosis_status_field
                                                                AND vvalue != to_char(g_detail_any)),
                                                             prb.flg_status),
                                                         -1)
                          -- check flg_nature detail
                       AND nvl(prb.flg_nature, -1) = nvl(nvl((SELECT vvalue
                                                               FROM protocol_adv_input_value
                                                              WHERE flg_type = g_adv_input_type_criterias
                                                                AND id_adv_input_link = exc.id_protocol_criteria_link
                                                                AND id_advanced_input_field = g_diagnosis_nature_field
                                                                AND vvalue != to_char(g_detail_any)),
                                                             prb.flg_nature),
                                                         -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                g_error := 'Check Exams';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check exams
                IF (l_applicable = 0)
                THEN
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM (
                           -- Inclusion
                            (SELECT to_number(inc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                              WHERE inc.link_other_crit_typ = g_protocol_exams
                             MINUS
                             
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type = g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel) UNION ALL
                           -- Exclusion
                            (SELECT to_number(exc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc
                              WHERE exc.link_other_crit_typ = g_protocol_exams
                             INTERSECT
                             
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type = g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel));
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                g_error := 'Check Other Exams';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check other exams
                IF (l_applicable = 0)
                THEN
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM (
                           -- Inclusion
                            (SELECT to_number(inc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                              WHERE inc.link_other_crit_typ = g_protocol_other_exams
                             MINUS
                             SELECT res.id_exam AS id_link
                               FROM exam_result res, exam ex
                              WHERE res.id_exam = ex.id_exam
                                AND ex.flg_type != g_exam_only_img
                                AND res.id_patient = rec_pat.id_patient
                                AND res.flg_status != pk_exam_constant.g_exam_result_cancel) UNION ALL
                           -- Exclusion
                            (SELECT to_number(exc.link_other_crit)
                               FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc
                              WHERE exc.link_other_crit_typ = g_protocol_other_exams
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
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- check diagnosis nurse
                IF (l_applicable = 0)
                THEN
                
                    -- Inclusion                     
                    SELECT abs(COUNT(id_composition) - COUNT(link_other_crit)) + COUNT(flg_status) AS counter
                      INTO l_counter
                      FROM (SELECT nurse_diag.id_composition,
                                   inc.link_other_crit,
                                   -- check flg_status detail
                                   decode((SELECT vvalue
                                            FROM protocol_adv_input_value
                                           WHERE flg_type = g_adv_input_type_criterias
                                             AND id_adv_input_link = inc.id_protocol_criteria_link
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
                                   TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_inc)) inc
                             WHERE inc.link_other_crit_typ = g_protocol_diagnosis_nurse
                               AND nurse_diag.id_composition(+) = inc.link_other_crit);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                IF (l_applicable = 0)
                THEN
                    -- Exclusion
                    SELECT COUNT(1)
                      INTO l_counter
                      FROM TABLE(get_other_criteria(rec_prot.id_protocol, g_criteria_type_exc)) exc,
                           icnp_epis_diagnosis nurse_diag
                     WHERE exc.link_other_crit_typ = g_protocol_diagnosis_nurse
                       AND nurse_diag.flg_status IN (g_nurse_active, g_nurse_solved)
                       AND nurse_diag.id_patient = rec_pat.id_patient
                       AND nurse_diag.id_composition = exc.link_other_crit
                          -- check flg_status detail
                       AND nvl(nurse_diag.flg_status, -1) =
                           nvl(nvl((SELECT vvalue
                                     FROM protocol_adv_input_value
                                    WHERE flg_type = g_adv_input_type_criterias
                                      AND id_adv_input_link = exc.id_protocol_criteria_link
                                      AND id_advanced_input_field = g_nurse_diagnosis_status_field
                                      AND vvalue != to_char(g_detail_any)),
                                   nurse_diag.flg_status),
                               -1);
                
                    l_applicable := l_applicable + nvl(l_counter, 0);
                END IF;
            
                -- if protocol match with patient profile, then create a protocol process
                IF (l_applicable = 0)
                THEN
                    IF (NOT create_protocol_process(i_lang,
                                                    i_prof,
                                                    rec_prot.id_protocol,
                                                    l_id_protocol_batch,
                                                    NULL,
                                                    rec_pat.id_patient,
                                                    g_process_recommended,
                                                    g_not_nested_protocol,
                                                    l_id_protocol_process,
                                                    o_error))
                    THEN
                        RAISE error_create_process;
                    END IF;
                END IF;
            
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        -- Error on protocol processes status update and its tasks
        WHEN error_update_processes THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     NULL,
                                                     g_error || ' / COULD NOT UPDATE PROCESSES',
                                                     g_package_owner,
                                                     g_package_name,
                                                     'RUN_BATCH',
                                                     o_error);
            -- Error on process creation
        WHEN error_create_process THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     NULL,
                                                     g_error || ' / COULD NOT CREATE PROCESS',
                                                     g_package_owner,
                                                     g_package_name,
                                                     'RUN_BATCH',
                                                     o_error);
            -- Other errors not included in the previous exception type
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'RUN_BATCH',
                                                     o_error);
    END run_batch;

    /**
    *  Create manual protocol processes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION create_protocol_proc_manual
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN table_number,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_protocol_batch   protocol_batch.id_protocol_batch%TYPE;
        l_id_protocol_process protocol_process.id_protocol_process%TYPE;
    
        e_create_process_error EXCEPTION;
    BEGIN
        -- create all protocol processes
        IF i_id_protocol.count != 0
        THEN
            FOR i IN i_id_protocol.first .. i_id_protocol.last
            LOOP
            
                g_error := 'INSERT PROTOCOL BATCH';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                -- create batch
                INSERT INTO protocol_batch
                    (id_protocol_batch, batch_type, dt_protocol_batch)
                VALUES
                    (seq_protocol_batch.nextval, g_batch_1p_1g, current_timestamp)
                RETURNING id_protocol_batch INTO l_id_protocol_batch;
            
                g_error := 'CREATE PROTOCOL PROCESSES';
                pk_alertlog.log_debug(g_error, g_package_name);
            
                IF (NOT create_protocol_process(i_lang,
                                                i_prof,
                                                i_id_protocol(i),
                                                l_id_protocol_batch,
                                                i_id_episode,
                                                i_id_patient,
                                                g_process_pending,
                                                g_not_nested_protocol,
                                                l_id_protocol_process,
                                                o_error))
                THEN
                    RAISE e_create_process_error;
                END IF;
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN e_create_process_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / COULD NOT CREATE PROCESS',
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROTOCOL_PROC_MANUAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROTOCOL_PROC_MANUAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_protocol_proc_manual;

    /**
    *  Create protocol process
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      I_ID_BATCH                   Batch ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_FLG_INIT_STATUS            Protocol process initial status
    * @param      I_FLG_NESTED_PROTOCOL        Nested protocol (Y/N)
    * @param      O_ID_PROTOCOL_PROCESS        Protocol process ID
    * @param      O_ERROR                      Error message
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION create_protocol_process
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
        i_id_protocol_batch   IN protocol_batch.id_protocol_batch%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_flg_init_status     IN protocol_process.flg_status%TYPE,
        i_flg_nested_protocol IN protocol_process.flg_nested_protocol%TYPE,
        o_id_protocol_process OUT protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_tasks IS
            SELECT prot_elem.id_protocol_element,
                   prot_elem.id_protocol,
                   prot_elem.id_element,
                   prot_elem.element_type,
                   prot_elem.x_coordinate,
                   prot_elem.y_coordinate,
                   prot_elem.flg_available,
                   prot_tsk.id_protocol_task,
                   prot_tsk.id_group_task,
                   prot_tsk.desc_protocol_task,
                   prot_tsk.id_task_link,
                   prot_tsk.task_type,
                   prot_tsk.task_notes,
                   prot_tsk.id_task_attach,
                   prot_tsk.task_codification,
                   value_type,
                   nvalue,
                   dvalue,
                   vvalue,
                   nvl2(prot_adv.id_adv_input_link, g_available, g_not_available) AS flg_details
              FROM (protocol_element prot_elem LEFT OUTER JOIN protocol_task prot_tsk ON
                    prot_elem.id_element = prot_tsk.id_group_task)
              LEFT OUTER JOIN protocol_adv_input_value prot_adv
                ON prot_adv.id_adv_input_link = prot_tsk.id_protocol_task
               AND prot_adv.flg_type = g_adv_input_type_tasks
               AND prot_adv.id_advanced_input_field = g_frequency_field
             WHERE prot_elem.id_protocol = i_id_protocol
               AND prot_elem.element_type = g_element_task;
    
        CURSOR c_nested_prots IS
            SELECT prot_elem.id_protocol_element, prot_prot.desc_protocol_protocol, prot_prot.id_nested_protocol
              FROM protocol_element prot_elem
              LEFT OUTER JOIN(protocol_protocol prot_prot
             INNER JOIN protocol prot
                ON prot_prot.id_nested_protocol = prot.id_protocol
               AND prot.flg_status = g_protocol_finished) ON prot_elem.id_element = prot_prot.id_protocol_protocol
             WHERE prot_elem.id_protocol = i_id_protocol
               AND prot_elem.element_type = g_element_protocol;
    
        l_id_protocol_process      protocol_process.id_protocol_process%TYPE;
        l_id_protocol_process_link protocol_process.id_protocol_process%TYPE;
        l_id_protocol_process_elem protocol_process_element.id_protocol_process_elem%TYPE;
    
        error_create_nested_process EXCEPTION;
    BEGIN
    
        g_error := 'INSERT PROCESS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- inserts process
        INSERT INTO protocol_process
            (id_protocol_process,
             id_protocol_batch,
             id_episode,
             id_patient,
             id_protocol,
             flg_status,
             dt_status,
             id_professional,
             flg_nested_protocol)
        VALUES
            (seq_protocol_process.nextval,
             i_id_protocol_batch,
             i_id_episode,
             i_id_patient,
             i_id_protocol,
             i_flg_init_status,
             current_timestamp,
             i_prof.id,
             i_flg_nested_protocol)
        RETURNING id_protocol_process INTO l_id_protocol_process;
    
        -- return protocol process ID
        o_id_protocol_process := l_id_protocol_process;
    
        g_error := 'INSERT PROCESS TASKS AND RELATED DETAILS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- inserts process task and related details
        FOR rec IN c_tasks
        LOOP
            INSERT INTO protocol_process_element
                (id_protocol_process_elem,
                 id_protocol_process,
                 element_type,
                 id_protocol_element,
                 id_protocol_task,
                 element_notes,
                 id_request,
                 dt_request,
                 flg_status,
                 flg_active,
                 dt_status,
                 id_professional)
            VALUES
                (seq_protocol_process_element.nextval,
                 l_id_protocol_process,
                 g_element_task,
                 rec.id_protocol_element,
                 rec.id_protocol_task,
                 rec.task_notes,
                 NULL,
                 NULL,
                 i_flg_init_status,
                 g_flag_active_initial,
                 current_timestamp,
                 i_prof.id)
            RETURNING id_protocol_process_elem INTO l_id_protocol_process_elem;
        
            -- insert frequency detail 
            IF (rec.flg_details = g_available AND rec.vvalue != g_task_unique_freq)
            THEN
                INSERT INTO protocol_process_task_det
                    (id_protocol_process_task_det,
                     id_protocol_process_elem,
                     flg_detail_type,
                     value_type,
                     nvalue,
                     dvalue,
                     vvalue)
                VALUES
                    (seq_protocol_process_task_det.nextval,
                     l_id_protocol_process_elem,
                     g_proc_task_det_freq,
                     rec.value_type,
                     rec.nvalue,
                     rec.dvalue,
                     rec.vvalue);
            
                -- insert next recomendation detail
                INSERT INTO protocol_process_task_det
                    (id_protocol_process_task_det, id_protocol_process_elem, flg_detail_type, value_type, dvalue)
                VALUES
                    (seq_protocol_process_task_det.nextval,
                     l_id_protocol_process_elem,
                     g_proc_task_det_next_rec,
                     g_protocol_d_type,
                     current_timestamp);
            END IF;
        END LOOP;
    
        g_error := 'INSERT PROCESS TEXT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- inserts process text
        INSERT INTO protocol_process_element
            (id_protocol_process_elem,
             id_protocol_process,
             element_type,
             id_protocol_element,
             id_protocol_task,
             element_notes,
             id_request,
             dt_request,
             flg_status,
             flg_active,
             dt_status,
             id_professional)
            (SELECT seq_protocol_process_element.nextval,
                    l_id_protocol_process,
                    prot_elem.element_type,
                    prot_elem.id_protocol_element,
                    NULL,
                    prot_text.desc_protocol_text,
                    NULL,
                    NULL,
                    i_flg_init_status,
                    g_flag_active_initial,
                    current_timestamp,
                    i_prof.id
               FROM protocol_text prot_text, protocol_element prot_elem
              WHERE prot_elem.id_protocol = i_id_protocol
                AND prot_elem.element_type IN (g_element_warning, g_element_header, g_element_instruction)
                AND prot_elem.id_element = prot_text.id_protocol_text);
    
        g_error := 'INSERT PROCESS QUESTION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- inserts process question
        INSERT INTO protocol_process_element
            (id_protocol_process_elem,
             id_protocol_process,
             element_type,
             id_protocol_element,
             id_protocol_task,
             element_notes,
             id_request,
             dt_request,
             flg_status,
             flg_active,
             dt_status,
             id_professional)
            (SELECT seq_protocol_process_element.nextval,
                    l_id_protocol_process,
                    g_element_question,
                    prot_elem.id_protocol_element,
                    NULL,
                    prot_quest.desc_protocol_question,
                    NULL,
                    NULL,
                    i_flg_init_status,
                    g_flag_active_initial,
                    current_timestamp,
                    i_prof.id
               FROM protocol_question prot_quest, protocol_element prot_elem
              WHERE prot_elem.id_protocol = i_id_protocol
                AND prot_elem.element_type = g_element_question
                AND prot_elem.id_element = prot_quest.id_protocol_question);
    
        g_error := 'INSERT PROCESS NESTED PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- inserts process nested protocol
        FOR rec IN c_nested_prots
        LOOP
            IF rec.id_nested_protocol IS NOT NULL
            THEN
                IF (NOT create_protocol_process(i_lang,
                                                i_prof,
                                                rec.id_nested_protocol,
                                                i_id_protocol_batch,
                                                i_id_episode,
                                                i_id_patient,
                                                i_flg_init_status,
                                                g_nested_protocol,
                                                l_id_protocol_process_link,
                                                o_error))
                THEN
                    RAISE error_create_nested_process;
                
                END IF;
            ELSE
                l_id_protocol_process_link := NULL;
            END IF;
        
            INSERT INTO protocol_process_element
                (id_protocol_process_elem,
                 id_protocol_process,
                 element_type,
                 id_protocol_element,
                 id_protocol_task,
                 id_protocol_process_link,
                 element_notes,
                 id_request,
                 dt_request,
                 flg_status,
                 flg_active,
                 dt_status,
                 id_professional)
            VALUES
                (seq_protocol_process_element.nextval,
                 l_id_protocol_process,
                 g_element_protocol,
                 rec.id_protocol_element,
                 NULL,
                 l_id_protocol_process_link,
                 rec.desc_protocol_protocol,
                 NULL,
                 NULL,
                 i_flg_init_status,
                 g_flag_active_initial,
                 current_timestamp,
                 i_prof.id);
        
        END LOOP;
    
        g_error := 'INSERT PROCESS ELEMENTS HISTORY';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- insert process elements history
        INSERT INTO protocol_process_element_hist
            (id_protocol_process_elem_hist,
             id_protocol_process_elem,
             flg_status_old,
             flg_status_new,
             id_request_old,
             id_request_new,
             dt_request_old,
             dt_request_new,
             flg_active_old,
             flg_active_new,
             dt_status_change,
             id_professional)
            (SELECT seq_protocol_process_elem_hist.nextval,
                    id_protocol_process_elem,
                    NULL,
                    i_flg_init_status,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    g_flag_active_initial,
                    current_timestamp,
                    i_prof.id
               FROM protocol_process_element
              WHERE id_protocol_process = l_id_protocol_process);
    
        -- No commit as this should be done by the calling function
        RETURN TRUE;
    EXCEPTION
        -- Error on nested protocol process creation
        WHEN error_create_nested_process THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     NULL,
                                                     NULL,
                                                     g_error || ' / COULD NOT CREATE NESTED PROTOCOL PROCESS',
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CREATE_PROTOCOL_PROCESS',
                                                     o_error);
            -- On any error
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'CREATE_PROTOCOL_PROCESS',
                                                     o_error);
    END create_protocol_process;
    /**
    * Function. returns IMC for specific height and weight
    * @param      I_ID_UNIT_MEASURE_HEIGHT          Unit of measure of height
    * @param      I_HEIGHT                          Height
    * @param      I_ID_UNIT_MEASURE_WEIGHT          Unit of measure of weight
    * @param      I_WEIGHT                          Weight
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_imc
    (
        i_id_unit_measure_height IN protocol_criteria.id_height_unit_measure%TYPE,
        i_height                 IN protocol_criteria.min_height%TYPE,
        i_id_unit_measure_weight IN protocol_criteria.id_weight_unit_measure%TYPE,
        i_weight                 IN protocol_criteria.min_weight%TYPE
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
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_SUBJECT                    Subject of action
    * @param      I_ID_STATE                   Original state from which we want an action
    * @param      O_ACTION                     Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
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
            pk_alertlog.log_debug(g_error, g_package_name);
        
            SELECT pc.id_category
              INTO l_prof_cat
              FROM prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            g_error := 'GET CURSOR';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            OPEN o_action FOR
                SELECT DISTINCT subject,
                                act.id_action,
                                pk_message.get_message(i_lang, i_prof, code_action) AS action_desc,
                                icon,
                                from_state,
                                to_state,
                                flg_default,
                                decode(act.subject, g_protocol, NULL, prot_act_cat.task_type) AS task_type,
                                act.rank
                  FROM action act,
                       TABLE(i_subject) t_subject,
                       (SELECT DISTINCT id_action, task_type
                          FROM (SELECT id_action,
                                       task_type,
                                       first_value(flg_available) over(PARTITION BY id_action, task_type ORDER BY id_profile_template DESC, flg_available) AS flg_avail
                                  FROM (SELECT pac.id_action, pac.task_type, pac.flg_available, pac.id_profile_template
                                          FROM protocol_action_category pac
                                         WHERE pac.id_category = l_prof_cat
                                           AND pac.task_type != 0
                                           AND pac.id_profile_template IN (SELECT ppt.id_profile_template
                                                                             FROM prof_profile_template ppt
                                                                            WHERE ppt.id_professional = i_prof.id
                                                                              AND ppt.id_institution = i_prof.institution
                                                                              AND ppt.id_software = i_prof.software
                                                                           UNION ALL
                                                                           SELECT g_all_profile_template AS id_profile_template
                                                                             FROM dual)
                                        UNION ALL
                                        SELECT prot_ac.id_action,
                                               items.item AS task_type,
                                               prot_ac.flg_available,
                                               prot_ac.id_profile_template
                                          FROM protocol_action_category prot_ac,
                                               (SELECT DISTINCT item
                                                  FROM protocol_item_soft_inst pisi
                                                 WHERE pisi.id_institution IN (g_all_institution, i_prof.institution)
                                                   AND pisi.id_software IN (g_all_software, i_prof.software)
                                                   AND pisi.id_market IN (g_all_markets, l_market)
                                                   AND pisi.flg_item_type = g_protocol_item_tasks) items
                                         WHERE prot_ac.id_category = l_prof_cat
                                           AND prot_ac.id_profile_template IN
                                               (SELECT ppt.id_profile_template
                                                  FROM prof_profile_template ppt
                                                 WHERE ppt.id_professional = i_prof.id
                                                   AND ppt.id_institution = i_prof.institution
                                                   AND ppt.id_software = i_prof.software
                                                UNION ALL
                                                SELECT g_all_profile_template AS id_profile_template
                                                  FROM dual)
                                           AND prot_ac.task_type = 0))
                         WHERE flg_avail = g_available) prot_act_cat
                 WHERE t_subject.column_value = act.subject
                   AND act.flg_status = g_active
                   AND act.from_state = nvl(i_id_state, act.from_state)
                   AND prot_act_cat.id_action = act.id_action
                   AND (prot_act_cat.task_type IN
                       (SELECT DISTINCT item
                           FROM (SELECT item,
                                        first_value(prot_item.flg_available) over(PARTITION BY prot_item.item ORDER BY prot_item.id_market DESC, prot_item.id_institution DESC, prot_item.id_software DESC, prot_item.flg_available) AS flg_avail
                                   FROM protocol_item_soft_inst prot_item
                                  WHERE prot_item.id_institution IN (g_all_institution, i_prof.institution)
                                    AND prot_item.id_software IN (g_all_software, i_prof.software)
                                    AND prot_item.id_market IN (g_all_markets, l_market)
                                    AND prot_item.flg_item_type = g_protocol_item_tasks)
                          WHERE flg_avail = g_available) OR
                       (act.from_state != g_process_running AND act.to_state != g_process_running))
                 ORDER BY rank;
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
                                              'GET_ACTION',
                                              o_error);
            pk_types.open_my_cursor(o_action);
            RETURN FALSE;
    END get_action;

    /**
    *  Get all recommended protocol
    *
    * @param      I_LANG                           Prefered languagie ID for this professional
    * @param      I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                     Episode ID
    * @param      I_VALUE_PAT_NAME_SEARCH          String to search for patient name
    * @param      I_VALUE_RECOM_protocol_SEARCH  String to search for recommended protocol
    * @param      I_VALUE_PROTOCOL_TYPE_SEARCH   Sring to search for protocol type
    * @param      DT_SERVER                        Current server time
    * @param      O_PROTOCOL_RECOMMENDED          Recommended protocol of all users
    * @param      O_ERROR                          error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_all_recommended_protocol
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_value_pat_name_search       IN VARCHAR2,
        i_value_recom_protocol_search IN VARCHAR2,
        i_value_protocol_type_search  IN VARCHAR2,
        dt_server                     OUT VARCHAR2,
        o_protocol_recommended        OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_procs IS
            SELECT id_protocol_process
              FROM protocol_process gp;
    
        b_result BOOLEAN;
        error_undefined EXCEPTION;
    BEGIN
    
        IF (i_value_pat_name_search IS NULL AND i_value_recom_protocol_search IS NULL AND
           i_value_protocol_type_search IS NULL)
        THEN
            g_error := 'UPDATE STATE OF ALL PROTOCOL PROCESSES AND ASSOCIATED TASKS';
            pk_alertlog.log_debug(g_error, g_package_name);
        
            FOR rec IN c_procs
            LOOP
            
                b_result := update_prot_proc_task_status(i_lang, i_prof, rec.id_protocol_process, o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            
                b_result := update_prot_proc_status(i_lang, i_prof, rec.id_protocol_process, o_error);
            
                IF (NOT b_result)
                THEN
                    RAISE error_undefined;
                END IF;
            END LOOP;
        
            COMMIT;
        END IF;
    
        g_error := 'GET ALL RECOMMENDED PROTOCOL';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_protocol_recommended FOR
            SELECT *
              FROM (SELECT g.id_protocol,
                           gp.id_protocol_process,
                           gp.id_patient,
                           gp.flg_status,
                           pk_sysdomain.get_rank(i_lang, g_domain_flg_protocol, gp.flg_status) AS rank,
                           pat.name AS pat_name,
                           -- To get the patient name the following function must be used. 
                           -- Currently this function is not being used because it is waiting for episode ID as input parameter
                           -- pk_patient.get_pat_name(i_lang, i_prof, gp.id_patient, gea.id_episode, NULL) AS pat_name,
                           pat.gender AS pat_gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) AS pat_age,
                           decode(pk_patphoto.check_blob(pat.id_patient),
                                  'N',
                                  '',
                                  pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) AS pat_photo,
                           get_link_id_str(i_lang, i_prof, g.id_protocol, g_protocol_link_pathol, g_separator) AS protocol_desc,
                           
                           get_link_id_str(i_lang, i_prof, g.id_protocol, g_protocol_link_type, g_separator) AS protocol_typ,
                           
                           '0' || '|' || 'xxxxxxxxxxxxxx' || '|' || 'I' --decode(gp.flg_status, g_process_running, 'D', 'I')
                           || '|' || decode(pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, gp.flg_status),
                                            g_alert_icon,
                                            'R',
                                            g_waiting_icon,
                                            'R',
                                            NULL) || '|' ||
                           pk_sysdomain.get_img(i_lang, g_domain_flg_protocol, gp.flg_status) || '|' || NULL AS status
                      FROM protocol g, protocol_process gp, patient pat
                     WHERE g.id_protocol = gp.id_protocol
                       AND pat.id_patient = gp.id_patient
                       AND gp.flg_nested_protocol = g_not_nested_protocol
                    -- search for values
                    )
             WHERE ((translate(upper(pat_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' ||
                   translate(upper(i_value_pat_name_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value_pat_name_search IS NOT NULL) OR i_value_pat_name_search IS NULL)
               AND ((translate(upper(protocol_desc), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value_recom_protocol_search),
                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value_recom_protocol_search IS NOT NULL) OR i_value_recom_protocol_search IS NULL)
                  
               AND ((translate(upper(protocol_typ), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value_protocol_type_search),
                                      'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ',
                                      'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_value_protocol_type_search IS NOT NULL) OR i_value_protocol_type_search IS NULL)
             ORDER BY pat_name, rank, protocol_desc, protocol_typ;
    
        -- return server time as close as possible to the end of function 
        dt_server := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN error_undefined THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / Undefined state',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_RECOMMENDED_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_protocol_recommended);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_RECOMMENDED_PROTOCOL',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_protocol_recommended);
            RETURN FALSE;
    END get_all_recommended_protocol;
    /********************************************************************************************
     * Get Advanced Input for protocol.
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
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/07
    **********************************************************************************************/
    FUNCTION get_protocol_advanced_input
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN protocol_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number,
        o_fields            OUT pk_types.cursor_type,
        o_fields_det        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET ADVANCED INPUT STRUCTURE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
            ---------------------------------------------------------------------
             ORDER BY adv_input.id_advanced_input,
                      adv_input.id_advanced_input_field,
                      adv_input.id_advanced_input_field_det;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_ADVANCED_INPUT',
                                              o_error);
            pk_types.open_my_cursor(o_fields);
            pk_types.open_my_cursor(o_fields_det);
            RETURN FALSE;
    END get_protocol_advanced_input;

    /********************************************************************************************
     * Get field's value for the Advanced Input of protocols
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced Input ID
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADV_INPUT_LINK      Tasks or Criterias links to get advanced input data
     *
     * @return                         PIPELINED type t_coll_protocol_adv_input
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    **********************************************************************************************/

    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN protocol_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number
    ) RETURN t_coll_protocol_adv_input
        PIPELINED IS
    
        rec_out t_rec_protocol_adv_input := t_rec_protocol_adv_input(NULL, NULL, NULL, NULL, NULL, NULL);
    
        CURSOR c_fields IS
            SELECT ai.id_advanced_input,
                   aif.id_advanced_input_field,
                   aidet.id_advanced_input_field_det,
                   --
                   prot_advinput_val.id_adv_input_link,
                   prot_advinput_val.flg_type,
                   prot_advinput_val.value_type,
                   prot_advinput_val.dvalue,
                   prot_advinput_val.nvalue,
                   prot_advinput_val.vvalue,
                   prot_advinput_val.value_desc,
                   prot_advinput_val.criteria_value_type
              FROM advanced_input_soft_inst ai,
                   protocol_adv_input_value prot_advinput_val,
                   TABLE(i_id_adv_input_link) advinput_link,
                   -------------------------------------------------------------------------
                   (advanced_input_field aif LEFT OUTER JOIN advanced_input_field_det aidet ON
                    aidet.id_advanced_input_field = aif.id_advanced_input_field)
             WHERE ai.id_advanced_input = i_id_advanced_input
               AND ai.id_institution IN (i_prof.institution, g_all_institution)
               AND ai.id_software IN (i_prof.software, g_all_software)
               AND aif.id_advanced_input_field = ai.id_advanced_input_field
                  --
               AND prot_advinput_val.id_adv_input_link = advinput_link.column_value
               AND prot_advinput_val.id_advanced_input = ai.id_advanced_input
               AND prot_advinput_val.id_advanced_input_field = ai.id_advanced_input_field
               AND prot_advinput_val.flg_type = i_flg_type;
    
    BEGIN
    
        g_error := 'GET VALUES FOR ADVANCED INPUT FIELDS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        FOR rec IN c_fields
        LOOP
        
            rec_out.id_advanced_input           := rec.id_advanced_input;
            rec_out.id_advanced_input_field     := rec.id_advanced_input_field;
            rec_out.id_advanced_input_field_det := rec.id_advanced_input_field_det;
            rec_out.id_adv_input_link           := rec.id_adv_input_link;
        
            IF (rec.value_type = g_protocol_d_type)
            THEN
                rec_out.value_date := rec.dvalue;
            ELSIF (rec.value_type = g_protocol_n_type)
            THEN
                rec_out.value := rec.nvalue;
            ELSIF (rec.value_type = g_protocol_v_type)
            THEN
                rec_out.value := rec.vvalue;
            END IF;
        
            PIPE ROW(rec_out);
        END LOOP;
        RETURN;
    
    END get_adv_input_field_value;

    /********************************************************************************************
     * Set Advanced Input field value for protocol.
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_ID_PROTOCOL                         Protocol ID
     * @param I_FLG_TYPE                            Advanced for (C)riterias or (T)asks
     * @param I_VALUE_TYPE                          Value type : D-Date, V-Varchar N-Number
     * @param I_DVALUE                              Date value
     * @param I_NVALUE                              Number value
     * @param I_VVALUE                              Varchar value
     * @param I_VALUE_DESC                          Value description
     * @param I_CRITERIA_VALUE_TYPE                 Criteria Value Type
     * @param I_ID_ADVANCED_INPUT                   Advanced Input ID
     * @param I_ID_ADVANCED_INPUT_FIELD             Advanced Input Field ID        
     * @param I_ID_ADVANCED_INPUT_FIELD_DET         Advanced Input Field ID Det    
     
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/07
    **********************************************************************************************/
    FUNCTION set_protocol_adv_input_value
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_adv_input_link           IN protocol_adv_input_value.id_adv_input_link%TYPE,
        i_flg_type                    IN protocol_adv_input_value.flg_type%TYPE,
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
        pk_alertlog.log_debug(g_error, g_package_name);
    
        BEGIN
            FORALL i IN i_value_type.first .. i_value_type.last SAVE EXCEPTIONS
                INSERT INTO protocol_adv_input_value
                    (id_protocol_adv_input_value,
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
                    (seq_protocol_adv_input_value.nextval,
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
        WHEN dml_errors THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / DML ERROR WHILE INSERTING',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_ADV_INPUT_VALUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_ADV_INPUT_VALUE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_adv_input_value;

    /*
     * Set active state for a specific protocol process element
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_ID_PROTOCOL_PROCESS                 Protocol Process ID
     * @param I_ID_PROTOCOL_PROCESS_OLD             OLD element 
     * @param I_ID_PROTOCOL_PROCESS_NEW             New active element
     * @param I_FLG_ACTIVE_OLD                      Flag active for old element
     * @param I_FLG_ACTIVE_NEW                      Flag active for new element
     
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/24
    */
    FUNCTION set_protocol_active_element
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_protocol_process     IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element_old IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element_new IN protocol_process_element.id_protocol_process%TYPE,
        i_flg_active_old          IN protocol_process_element.flg_active%TYPE,
        i_flg_active_new          IN protocol_process_element.flg_active%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'SET PROTOCOL ACTIVE ELEMENT';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        -- pk_sysdomain.get_domain(g_domain_flg_type_rec, prot.flg_type_recommendation, i_lang)    
    
        UPDATE protocol_process_element
           SET flg_active = i_flg_active_old, id_professional = i_prof.id
         WHERE id_protocol_process = i_id_protocol_process
           AND id_protocol_element = i_id_protocol_element_old;
    
        UPDATE protocol_process_element
           SET flg_active = i_flg_active_new, id_professional = i_prof.id
         WHERE id_protocol_process = i_id_protocol_process
           AND id_protocol_element = i_id_protocol_element_new;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_ACTIVE_ELEMENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_active_element;

    /********************************************************************************************
    * get all complaints that can be associated to the protocol
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      i_value                      search string 
    * @param      o_complaints                 cursor with all complaints that can be associated to the protocols
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_value       IN VARCHAR2,
        o_complaints  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_id_complaints   table_number;
        l_desc_complaints table_varchar;
        l_tbl             t_tbl_protocol_complaints := t_tbl_protocol_complaints();
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
    
        -- loop for all complaints to build t_tbl_protocol_complaints array
        FOR i IN 1 .. l_id_complaints.count
        LOOP
            l_tbl.extend;
            l_tbl(l_tbl.count) := t_rec_protocol_complaints(l_id_complaints(i), l_desc_complaints(i));
        END LOOP;
    
        -- open cursor o_complaints
        OPEN o_complaints FOR
            SELECT /*+opt_estimate(table c rows=1)*/
             c.id_complaint, c.desc_complaint, nvl2(pl.id_protocol_link, g_active, g_inactive) AS flg_select
              FROM TABLE(CAST(l_tbl AS t_tbl_protocol_complaints)) c
              LEFT JOIN protocol_link pl
                ON c.id_complaint = pl.id_link
               AND pl.link_type = g_protocol_link_chief_compl
               AND pl.id_protocol = i_id_protocol
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_COMPLAINT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_complaints);
            RETURN FALSE;
        
    END get_complaint_list;

    /********************************************************************************************
    * set protocol complaints
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      i_link_complaint             array with complaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION set_protocol_chief_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_link_complaint IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'delete existing protocol chief complaint links';
        pk_alertlog.log_debug(g_error, g_package_name);
        DELETE FROM protocol_link
         WHERE id_protocol = i_id_protocol
           AND link_type = g_protocol_link_chief_compl;
    
        g_error := 'insert new protocol chief complaint links';
        pk_alertlog.log_debug(g_error, g_package_name);
        INSERT INTO protocol_link
            (id_protocol_link, id_protocol, id_link, link_type)
            SELECT seq_protocol_link.nextval, i_id_protocol, column_value, g_protocol_link_chief_compl
              FROM TABLE(i_link_complaint);
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROTOCOL_CHIEF_COMPLAINT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_protocol_chief_complaint;

    /********************************************************************************************
    * get all filters for frequent protocols screen
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      i_episode                    episode id    
    * @param      o_filters                    cursor with all filters for frequent protocols screen
    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION get_protocol_filters
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
    
        l_protocol_id         protocol.id_protocol%TYPE;
        l_protocol_title      protocol.protocol_desc%TYPE;
        l_protocol_rank       protocol_frequent.rank%TYPE;
        l_protocol_duplicated VARCHAR2(1 CHAR);
    
        l_most_freq_protocols pk_types.cursor_type;
    BEGIN
        -- chief complaints filter is only active if patient has an associated active chief complaint
        g_error := 'GET CHIEF COMPLAINT FOR EPISODE';
        pk_alertlog.log_debug(g_error, g_package_name);
    
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
        
            IF NOT get_protocol_frequent(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_patient        => i_patient,
                                         i_id_episode        => i_episode,
                                         i_flg_filter        => g_prot_filter_chief_compl,
                                         i_value             => NULL,
                                         o_protocol_frequent => l_most_freq_protocols,
                                         o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_protocols
                INTO l_protocol_id, l_protocol_title, l_protocol_rank, l_protocol_duplicated;
        
            IF l_most_freq_protocols%NOTFOUND
            THEN
                l_has_complaint_results := pk_alert_constant.g_no;
            ELSE
                l_has_complaint_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_protocols;
        ELSE
            l_has_complaint_results := pk_alert_constant.g_no;
        END IF;
    
        -- check if there are order sets for professional specialty
        -- (this ony need to be done if there are no results for chief complaint)
        IF l_has_complaint_results = pk_alert_constant.g_no
        THEN
        
            IF NOT get_protocol_frequent(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_patient        => i_patient,
                                         i_id_episode        => i_episode,
                                         i_flg_filter        => g_prot_filter_specialty,
                                         i_value             => NULL,
                                         o_protocol_frequent => l_most_freq_protocols,
                                         o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_protocols
                INTO l_protocol_id, l_protocol_title, l_protocol_rank, l_protocol_duplicated;
        
            IF l_most_freq_protocols%NOTFOUND
            THEN
                l_has_specialty_results := pk_alert_constant.g_no;
            ELSE
                l_has_specialty_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_protocols;
        ELSE
            l_has_specialty_results := pk_alert_constant.g_yes;
        END IF;
    
        -- if there are no results for this chief complaint and professional specialty,
        -- check if there are protocols for this software and institution
        IF l_has_complaint_results = pk_alert_constant.g_no
           AND l_has_specialty_results = pk_alert_constant.g_no
        THEN
        
            IF NOT get_protocol_frequent(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_id_patient        => i_patient,
                                         i_id_episode        => i_episode,
                                         i_flg_filter        => g_prot_filter_frequent,
                                         i_value             => NULL,
                                         o_protocol_frequent => l_most_freq_protocols,
                                         o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            FETCH l_most_freq_protocols
                INTO l_protocol_id, l_protocol_title, l_protocol_rank, l_protocol_duplicated;
        
            IF l_most_freq_protocols%NOTFOUND
            THEN
                l_has_results := pk_alert_constant.g_no;
            ELSE
                l_has_results := pk_alert_constant.g_yes;
            END IF;
        
            CLOSE l_most_freq_protocols;
        
        ELSE
            l_has_results := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'get o_filters cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        OPEN o_filters FOR
            SELECT sd.val AS id_action,
                   NULL   AS id_parent,
                   1      AS "LEVEL",
                   NULL   AS to_state,
                   -- name for specialty filter may differ from one to other environments
                   decode(sd.val,
                          g_prot_filter_specialty,
                          pk_message.get_message(i_lang, i_prof, 'PROTOCOL_M309'),
                          sd.desc_val) AS desc_action,
                   sd.img_name AS icon,
                   decode(sd.val,
                           g_prot_filter_chief_compl,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END),
                           g_prot_filter_specialty,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_no
                                    AND l_has_specialty_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END),
                           g_prot_filter_frequent,
                           (CASE
                               WHEN l_has_complaint_results = pk_alert_constant.g_no
                                    AND l_has_specialty_results = pk_alert_constant.g_no
                                    AND l_has_results = pk_alert_constant.g_yes THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END)) AS flg_default,
                   decode(sd.val,
                          g_prot_filter_chief_compl,
                          decode(l_has_complaint_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          g_prot_filter_specialty,
                          decode(l_has_specialty_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          g_prot_filter_frequent,
                          decode(l_has_results,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive)) AS flg_active
              FROM sys_domain sd
             WHERE sd.code_domain = 'PROTOCOL_FREQUENT_FILTER'
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
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROTOCOL_FILTERS',
                                              o_error);
            pk_types.open_my_cursor(o_filters);
            RETURN FALSE;
    END get_protocol_filters;

BEGIN
    --------------------------------------------------
    -- Bulk fetch limit
    g_bulk_fetch_rows := 100;

    -- Protocol type
    g_protocol_type_any := -1;
    -- Pathology type
    g_protocol_pathol_any := -1;
    -- Truncate string
    g_trunc_str := '...';

    -- Flg active types
    g_flag_active_initial   := 'V';
    g_flag_active_active    := 'A';
    g_flag_active_read      := 'L';
    g_flag_active_exec      := 'E';
    g_flag_active_ignored   := 'I';
    g_flag_active_cancelled := 'C';

    -- Link types   
    g_protocol_link_pathol      := 'H';
    g_protocol_link_envi        := 'E';
    g_protocol_link_prof        := 'P';
    g_protocol_link_spec        := 'S';
    g_protocol_link_type        := 'T';
    g_protocol_link_edit_prof   := 'D';
    g_protocol_link_chief_compl := 'C';

    -- frequent protocol filter types
    g_prot_filter_chief_compl := 'C';
    g_prot_filter_specialty   := 'S';
    g_prot_filter_frequent    := 'F';

    -- Diagnosis
    g_diag_available  := 'Y';
    g_diag_select     := 'Y';
    g_diag_not_select := 'N';
    g_diag_freq       := 'M';
    g_diag_req        := 'P';
    g_diag_type_icpc2 := 'P';
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
    g_available      := 'Y';
    g_not_available  := 'N';
    g_active         := 'A';
    g_inactive       := 'I';
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

    -- Cancel flag
    g_cancelled     := 'Y';
    g_not_cancelled := 'N';
    -- Criteria flag
    g_criteria_already_set      := 1;
    g_criteria_clear            := 0;
    g_criteria_already_crossset := 2;
    g_criteria_group_some       := 3;
    g_criteria_group_all        := 4;
    -- Link States
    g_link_state_new  := 0;
    g_link_state_del  := 1;
    g_link_state_keep := 2;
    -- Protocol states
    g_protocol_temp       := 'T';
    g_protocol_finished   := 'F';
    g_protocol_deleted    := 'C'; -- cancelled
    g_protocol_deprecated := 'D';
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
    g_process_scheduled_weight   := 6;
    g_process_finished_weight    := 5;
    g_process_suspended_weight   := 4;
    g_process_canceled_weight    := 3;
    g_process_closed_weight      := 3;
    g_process_recommended_weight := 2;
    g_process_pending_weight     := 1;

    -- Process task details type
    g_proc_task_det_freq     := 'F';
    g_proc_task_det_next_rec := 'R';

    -- Other criteria types
    g_protocol_allergies       := 1;
    g_protocol_analysis        := 2;
    g_protocol_diagnosis       := 3;
    g_protocol_exams           := 4;
    g_protocol_drug            := 5;
    g_protocol_other_exams     := 6;
    g_protocol_diagnosis_nurse := 7;
    -- Task type
    g_all_tasks                  := 0; -- all tasks
    g_task_analysis              := 1; -- analysis
    g_task_appoint               := 2; -- Consultas
    g_task_patient_education     := 3; -- Patient education
    g_task_img                   := 4; -- Imagem
    g_task_vacc                  := 5; -- imunizações
    g_task_enfint                := 6; --Intervenções de enfermagem
    g_task_drug                  := 7; -- medicação : Local
    g_task_otherexam             := 8; -- outros exames
    g_task_spec                  := 9; -- pareceres
    g_task_rast                  := 10; -- rastreios
    g_task_drug_ext              := 11; -- medicação : exterior
    g_task_proc                  := 12; -- procedimentos
    g_task_fluid                 := 13; -- soros
    g_task_monitorization        := 14; -- monitorizacoes
    g_task_specialty_appointment := 15; -- consultas de especialidade

    -- Criteria
    g_crit_age                   := -1; -- idade
    g_crit_weight                := -2; -- peso
    g_crit_height                := -3; -- altura
    g_crit_imc                   := -4; -- IMC (índice de massa corporal)
    g_crit_sistolic_blood_press  := -5; -- Pressão arterial sistólica
    g_crit_diastolic_blood_press := -6; -- Pressão arterial diastólica
    -- Gender
    g_gender_male   := 'M';
    g_gender_female := 'F';
    -- Unit of measure
    g_um_weight := 2;
    g_um_height := 3;
    -- IMC values
    g_imc_weight_default_um := 10;
    g_imc_height_default_um := 12;
    -- Blood pressure unit of measure
    g_blood_pressure_default_um := 6;
    -- Vital sign criterias
    g_weight_measure           := 29;
    g_height_measure           := 30;
    g_blood_pressure_s_measure := 6;
    g_blood_pressure_d_measure := 7;
    g_blood_pressure_measure   := 28;

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
    g_batch_all   := 'A'; -- all protocol / all patients
    g_batch_1p_ag := 'P'; -- one user /all protocol
    g_batch_1p_1g := 'O'; -- one user /one protocol
    g_batch_ap_1g := 'G'; -- all users /one protocol
    -- Process status
    g_process_active   := 'A';
    g_process_inactive := 'I';
    -- Generic variables for actions
    g_protocol := 'PROTOCOL';
    g_task     := 'PROTOCOL_TASKS';
    -- Domains
    g_domain_gender             := 'PATIENT.GENDER';
    g_domain_type_media         := 'PROTOCOL.CONTEXT_TYPE_MEDIA';
    g_domain_inc_gen            := 'PROTOCOL_CRITERIA.INCLUSION';
    g_domain_exc_gen            := 'PROTOCOL_CRITERIA.EXCLUSION';
    g_domain_flg_protocol       := 'PROTOCOL_PROCESS.FLG_STATUS';
    g_domain_flg_protocol_elem  := 'PROTOCOL_PROCESS_ELEMENT.FLG_STATUS';
    g_domain_task_type          := 'PROTOCOL_TASK.TASK_TYPE';
    g_domain_flg_type_rec       := 'PROTOCOL.FLG_TYPE_RECOMMENDATION';
    g_domain_language           := 'LANGUAGE';
    g_domain_professional_title := 'PROFESSIONAL.TITLE';
    g_domain_allergy_type       := 'PAT_ALLERGY.FLG_TYPE';
    g_domain_allergy_status     := 'PAT_ALLERGY.FLG_STATUS';
    g_domain_diagnosis_status   := 'PAT_PROBLEM.FLG_STATUS';
    g_domain_diagnosis_nature   := 'PAT_PROBLEM.FLG_NATURE';
    g_domain_nurse_diag_status  := 'ICNP_EPIS_DIAGNOSIS.FLG_STATUS';
    g_domain_adv_input_freq     := 'PROTOCOL_ADV_INPUT_VALUE.FREQUENCY';
    g_domain_prot_elem          := 'PROTOCOL_ELEMENT.ELEMENT_TYPE';
    g_domain_prot_connector     := 'PROTOCOL_CONNECTOR.FLG_DESC_PROTOCOL_CONNECTOR';
    g_domain_prot_proc_active   := 'PROTOCOL_PROCESS_ELEMENT.FLG_ACTIVE';
    g_domain_adv_input_flg_type := 'PROTOCOL_ADV_INPUT_VALUE.FLG_TYPE';
    g_domain_protocol_item_type := 'PROTOCOL_ITEM_SOFT_INST.FLG_ITEM_TYPE';

    -- Icons
    g_alert_icon   := 'AlertIcon';
    g_waiting_icon := 'WaitingIcon';
    -- Generic protocol

    g_unknown_link_type   := 'Unknown Link Type';
    g_unknown_detail_type := 'Unknown Detail Type';

    g_close_task             := 'O';
    g_cancel_task            := 'C';
    g_cancel_protocol        := 'C';
    g_state_cancel_operation := -1978;

    -- Advanced Input configurations
    g_advanced_input_drug := 2;

    -- Criteria Value
    g_protocol_d_type := 'D';
    g_protocol_n_type := 'N';
    g_protocol_v_type := 'V';
    -- Keypad Date
    g_date_keypad := 'DT';
    -- Boolean values
    g_true  := 'T';
    g_false := 'F';

    -- Edit Protocol options
    g_message_edit_protocol      := 'PROTOCOL_M066';
    g_message_create_protocol    := 'PROTOCOL_M065';
    g_message_duplicate_protocol := 'PROTOCOL_M068';
    g_edit_protocol_option       := 'E';
    g_create_protocol_option     := 'C';
    g_duplicate_protocol_option  := 'D';

    -- Protocol edit options
    g_protocol_editable   := 'E';
    g_protocol_duplicable := 'D';
    g_protocol_viewable   := 'V';

    g_message_any       := 'PROTOCOL_M062';
    g_message_scheduled := 'ICON_T056';

    -- Exam Types
    g_exam_only_img := 'I';
    -- Image status
    g_img_inactive := 'I';
    g_img_active   := 'A';
    -- Active states for measures
    g_patient_active := 'A';
    g_measure_active := 'A';
    -- Pat Allergy flg_status
    g_allergy_active  := 'A';
    g_allergy_passive := 'P';
    -- Nurse diagnosis flg_status
    g_nurse_active   := 'A';
    g_nurse_finished := 'F';
    g_nurse_solved   := 'S';

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

    -- Drug external
    g_yes := 'Y';
    g_no  := 'N';

    g_sch  := 'SCH_Todos';
    g_cipe := 'TodasEspecialidadesCIPE';

    -- Type of elements
    g_element_task        := 'T';
    g_element_question    := 'Q';
    g_element_warning     := 'W';
    g_element_instruction := 'I';
    g_element_header      := 'H';
    g_element_protocol    := 'P';
    -- Advanced Input type
    g_adv_input_type_tasks     := 'T';
    g_adv_input_type_criterias := 'C';

    -- Protocol type recommendation
    g_default_type_rec   := 'M';
    g_type_rec_manual    := 'M';
    g_type_rec_automatic := 'A';

    -- Advanced input field ID
    g_frequency_field              := 36;
    g_allergy_status_field         := 37;
    g_allergy_react_field          := 38;
    g_diagnosis_status_field       := 39;
    g_diagnosis_nature_field       := 40;
    g_nurse_diagnosis_status_field := 41;

    -- Type of patient problems
    g_pat_probl_not_capable := 'I';

    g_error_message := 'COMMON_M001';
    g_all           := 'COMMON_M014';

    -- NA message
    g_message_na := 'COMMON_M036';

    -- Opinion message
    g_message_opinion_any_prof := 'OPINION_M001';

    -- Appointments specialties
    g_prof_active             := 'A';
    g_external_appoint        := 'C';
    g_message_spec_appoint    := 'PROTOCOL_M069';
    g_message_foll_up_appoint := 'PROTOCOL_M067';

    -- CONFIGS in SYS_CONFIG
    g_config_func_consult_req := 'FUNCTIONALITY_CONSULT_REQ';
    g_config_func_opinion     := 'FUNCTIONALITY_OPINION';
    g_config_max_diag_rownum  := 'NUM_RECORD_SEARCH';

    -- Action subjects
    g_action_protocol_tasks := 'PROTOCOL_TASKS';

    -- Icon colors
    g_green_color := 'G';
    g_red_color   := 'R';

    -- State symbols
    g_icon      := 'I';
    g_text_icon := 'TI';
    g_text      := 'T';
    g_date      := 'D';

    -- Type protocol items
    g_protocol_item_tasks    := 'T';
    g_protocol_item_criteria := 'C';

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

    -- Nested protocol
    g_nested_protocol     := 'Y';
    g_not_nested_protocol := 'N';

    -- Protocol duplication
    g_duplicate_protocol     := 'Y';
    g_not_duplicate_protocol := 'N';

    -- Any criteria detail value
    g_detail_any := -1;

    -- Predefined protocol authors
    g_message_protocol_authors := 'PROTOCOL_M075';

    -- Pregnancy process
    g_pregnancy_process_active := 'A';

    --------------------------------------------------

    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_protocol;
/
