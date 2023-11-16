/*-- Last Change Revision: $Rev: 2027642 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_risk_factor IS

    FUNCTION get_risk_factor_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Returns the sections within a summary page
        *
        * @param i_lang                   The language ID
        * @param i_prof                   Object (professional ID, institution ID, software ID)
        * @param i_id_summary_page        Summary page ID
        * @param i_patient                Patient ID
        * @param o_sections               Cursor containing the sections info
                                              
        * @param o_error                  Error message
                            
        * @return                         true or false on success or error
        * 
        * @author                         Ana Matos
        * @since                          2007/09/05
        */
    
        l_flg_access summary_page.flg_access%TYPE;
        l_age        patient.age%TYPE;
        l_gender     patient.gender%TYPE;
    
    BEGIN
        SELECT p.gender, tab_age.age
          INTO l_gender, l_age
          FROM patient p,
               (SELECT nvl(pat1.age, trunc(months_between(SYSDATE, pat1.dt_birth) / 12, 0)) age,
                       months_between(SYSDATE, pat1.dt_birth) months,
                       (SYSDATE - pat1.dt_birth) days,
                       pat1.id_patient
                  FROM patient pat1
                 WHERE pat1.id_patient = i_patient) tab_age
         WHERE p.id_patient = i_patient;
    
        g_error := 'NEEDS ACCESS CHECK';
        SELECT sp.flg_access
          INTO l_flg_access
          FROM summary_page sp
         WHERE sp.id_summary_page = i_id_summary_page;
    
        IF l_flg_access = g_yes
        THEN
            g_error := 'OPEN O_SECTIONS WITH ACCESS CHECK';
            OPEN o_sections FOR
                SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                       sps.id_doc_area doc_area,
                       sps.screen_name,
                       sps.id_sys_shortcut,
                       spa.flg_write,
                       spa.flg_search,
                       decode(sps.id_doc_area, NULL, g_no, g_yes) flg_template,
                       nvl(spa.height, sps.height) height,
                       dais.flg_type,
                       sps.screen_name_after_save,
                       pk_translation.get_translation(i_lang, sps.code_page_section_subtitle) subtitle,
                       da.intern_name_sample_text_type,
                       da.flg_score,
                       sps.screen_name_free_text
                  FROM summary_page          sp,
                       summary_page_access   spa,
                       summary_page_section  sps,
                       prof_profile_template ppt,
                       doc_area              da,
                       doc_area_inst_soft    dais
                 WHERE spa.id_summary_page_section = sps.id_summary_page_section
                   AND sps.id_summary_page = sp.id_summary_page
                   AND sp.id_summary_page = i_id_summary_page
                   AND ppt.id_profile_template = spa.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_software IN (i_prof.software, 0)
                   AND ppt.id_institution IN (i_prof.institution, 0)
                   AND da.id_doc_area(+) = sps.id_doc_area
                   AND dais.id_doc_area(+) = da.id_doc_area
                   AND (dais.id_institution = decode((SELECT COUNT(0)
                                                       FROM doc_area_inst_soft dais2
                                                      WHERE dais2.id_doc_area = dais.id_doc_area
                                                        AND dais2.id_institution = i_prof.institution
                                                        AND dais2.id_software = i_prof.software),
                                                     0,
                                                     0,
                                                     i_prof.institution) OR dais.id_institution IS NULL)
                   AND (dais.id_software IN (i_prof.software, 0) OR dais.id_software IS NULL)
                   AND (da.gender IS NULL OR da.gender = l_gender OR l_gender = 'I')
                   AND (da.age_min IS NULL OR da.age_min < l_age OR l_age IS NULL)
                   AND (da.age_max IS NULL OR da.age_max > l_age OR l_age IS NULL)
                 ORDER BY sps.rank, 1;
        ELSE
            g_error := 'OPEN O_SECTIONS WITH NO ACCESS CHECK';
            OPEN o_sections FOR
                SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                       sps.id_doc_area doc_area,
                       sps.screen_name,
                       sps.id_sys_shortcut,
                       g_yes flg_write, -- no access check -> write access
                       g_no flg_search, -- no access check -> no search access
                       decode(sps.id_doc_area, NULL, g_no, g_yes) flg_template,
                       sps.height,
                       dais.flg_type,
                       sps.screen_name_after_save,
                       pk_translation.get_translation(i_lang, sps.code_page_section_subtitle) subtitle,
                       da.intern_name_sample_text_type,
                       da.flg_score,
                       sps.screen_name_free_text
                  FROM summary_page sp, summary_page_section sps, doc_area da, doc_area_inst_soft dais
                 WHERE sps.id_summary_page = sp.id_summary_page
                   AND sp.id_summary_page = i_id_summary_page
                   AND da.id_doc_area(+) = sps.id_doc_area
                   AND dais.id_doc_area(+) = da.id_doc_area
                   AND (dais.id_institution = decode((SELECT COUNT(0)
                                                       FROM doc_area_inst_soft dais2
                                                      WHERE dais2.id_doc_area = dais.id_doc_area
                                                        AND dais2.id_institution = i_prof.institution
                                                        AND dais2.id_software = i_prof.software),
                                                     0,
                                                     0,
                                                     i_prof.institution) OR dais.id_institution IS NULL)
                   AND (dais.id_software IN (0, i_prof.software) OR dais.id_software IS NULL)
                   AND (da.gender IS NULL OR da.gender = l_gender OR l_gender = 'I')
                   AND (da.age_min IS NULL OR da.age_min < l_age OR l_age IS NULL)
                   AND (da.age_max IS NULL OR da.age_max > l_age OR l_age IS NULL)
                 ORDER BY sps.rank, 1;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_RISK_FACTOR_SECTIONS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_sections);
                RETURN FALSE;
            
            END;
    END;

    /*
    * Returns documentation data for a given patient 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    *                                     
    * @param o_error                  Error message
    *                   
    * @return                         true or false on success or error
    * 
    * @author                         Ana Matos
    * @since                          2007/09/04
    */

    /********************************************************************************************
    * Returns documentation data for a given patient used by reports
    *
    * @param i_lang                   Language ID
    * @param i_prof_id                Professional ID
    * @param i_prof_inst              Institution ID
    * @param i_prof_sw                Software ID
    * @param i_prof                   Object ()
    * @param i_episode                Episode ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    *                                     
    * @param o_error                  Error message
    *                   
    * @return                         true or false on success or error
    *
    * @author                    Ariel Machado (based on get_risk_factor_summary_page)
    * @version                   1.0  (2.4.3)   
    * @since                     2008/08/27
    *
    ********************************************************************************************/
    FUNCTION get_risk_factor_summ_page_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_filter_days       IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
        RETURN get_risk_factor_summary_page(i_lang,
                                            i_prof,
                                            i_episode,
                                            i_doc_area,
                                            i_filter_days,
                                            o_doc_area_register,
                                            o_doc_area_val,
                                            o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_RISK_FACTOR_SUMM_PAGE_REP');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc_area_register);
                pk_types.open_my_cursor(o_doc_area_val);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_risk_factor_summary_page
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_filter_days       IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Returns documentation data for a given patient 
        *
        * @param i_lang                   Language ID
        * @param i_prof                   Object (professional ID, institution ID, software ID)
        * @param i_episode                Episode ID
        * @param i_doc_area               Doc area ID
        * @param o_doc_area_register      Doc area data
        * @param o_doc_area_val           Documentation data for the patient's episodes
        *                                     
        * @param o_error                  Error message
        *                   
        * @return                         true or false on success or error
        * 
        * @author                         Ana Matos
        * @since                          2007/09/04
        */
    
        l_sql     VARCHAR2(4000);
        l_patient patient.id_patient%TYPE;
    
    BEGIN
    
        g_error   := 'GET PATIENT ID';
        l_patient := pk_episode.get_id_patient(i_episode);
    
        g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT id_epis_documentation,
                   PARENT,
                   id_doc_template,
                   template_desc,
                   dt_creation,
                   dt_register,
                   id_professional,
                   nick_name,
                   desc_speciality,
                   id_doc_area,
                   flg_status,
                   desc_status,
                   notes,
                   dt_last_update,
                   flg_type_register,
                   flg_table_origin,
                   nick_name || ' (' || desc_speciality || '); ' || dt_register signature
              FROM (SELECT ed.id_epis_documentation,
                   ed.id_epis_documentation_parent PARENT,
                   ed.id_doc_template,
                   pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       ed.dt_last_update_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality,
                   ed.id_doc_area,
                   ed.flg_status,
                   decode(ed.flg_status,
                          g_active,
                          NULL,
                          pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS', ed.flg_status, i_lang)) desc_status,
                   ed.notes,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   decode(ed.id_doc_template, NULL, pk_summary_page.g_free_text, pk_summary_page.g_touch_option) flg_type_register,
                   pk_summary_page.g_flg_tab_origin_epis_doc flg_table_origin -- Record has its origin in the epis_documentation table
              FROM epis_documentation ed
              JOIN episode e
                ON e.id_episode = ed.id_episode
              LEFT JOIN doc_template dt
                ON ed.id_doc_template = dt.id_doc_template
             WHERE ed.id_doc_area = i_doc_area
               AND e.id_patient = l_patient
                     ORDER BY dt_last_update DESC)
             WHERE ((i_filter_days IS NOT NULL AND rownum <= i_filter_days) OR (i_filter_days IS NULL));
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT *
              FROM (SELECT id_epis_documentation,
                           PARENT,
                           id_documentation,
                           id_doc_component,
                           id_doc_element_crit,
                           dt_reg,
                           desc_doc_component,
                           flg_type,
                           desc_element,
                           desc_element_view,
                           VALUE,
                           flg_type_element,
                           id_doc_area,
                           rank_component,
                           rank_element,
                           desc_quantifier,
                           desc_quantification,
                           desc_qualification,
                           display_format,
                           separator,
                           row_number() over(PARTITION BY id_epis_documentation ORDER BY dt_last_update_tstz DESC) rn
                      FROM (SELECT ed.id_epis_documentation,
                   ed.id_epis_documentation_parent PARENT,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   TRIM(pk_translation.get_translation(i_lang, decr.code_element_close)) desc_element,
                   TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
                   pk_touch_option.get_formatted_value(i_lang,
                                                       i_prof,
                                                       de.flg_type,
                                                       edd.value,
                                                       edd.value_properties,
                                                       de.input_mask,
                                                       de.flg_optional_value,
                                                       de.flg_element_domain_type,
                                                       de.code_element_domain) VALUE,
                   de.flg_type flg_type_element,
                   ed.id_doc_area,
                   dtad.rank rank_component,
                   de.rank rank_element,
                   pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                   pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                   pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                   de.display_format,
                                   de.separator,
                                   ed.dt_last_update_tstz
              FROM episode e
             INNER JOIN epis_documentation ed
                ON e.id_episode = ed.id_episode
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE ed.id_doc_area = i_doc_area
               AND e.id_patient = l_patient
            
            UNION ALL
            SELECT ed.id_epis_documentation,
                   NULL PARENT,
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                                   decode(erf.desc_result,
                                          NULL,
                                          NULL,
                                          pk_message.get_message(i_lang, 'RISK_FACTORS_T011')) desc_doc_component,
                   NULL flg_type,
                   decode(erf.desc_result,
                          NULL,
                          NULL,
                          nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_element,
                   NULL desc_element_view,
                   NULL VALUE,
                   NULL flg_type_element,
                   ed.id_doc_area,
                   NULL rank_component,
                   NULL rank_element,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                                   NULL separator,
                                   ed.dt_last_update_tstz
              FROM episode e
             INNER JOIN epis_documentation ed
                ON e.id_episode = ed.id_episode
             INNER JOIN epis_risk_factor erf
                ON e.id_episode = erf.id_episode
               AND erf.id_epis_documentation = ed.id_epis_documentation
             INNER JOIN doc_area da
                ON ed.id_doc_area = da.id_doc_area
             WHERE e.id_patient = l_patient
               AND ed.id_doc_area = i_doc_area
                               AND da.flg_score = g_yes) t
                     ORDER BY rank_component, rank_element) tt
             WHERE ((i_filter_days IS NOT NULL AND rn < = i_filter_days) OR (i_filter_days IS NULL));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_RISK_FACTOR_SUMMARY_PAGE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc_area_register);
                pk_types.open_my_cursor(o_doc_area_val);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_elements_score
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        o_score        OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Sets a record of a risk factor
        *
        * @param i_lang      Language identifier
        * @param i_prof      Professional
        * @param i_doc_area  Documentation element IDs
        * @param o_score     Score for a given element
        * @param o_error     Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/28
        */
    
    BEGIN
    
        g_error := 'OPEN O_SCORE';
        OPEN o_score FOR
            SELECT rf.id_doc_element, rf.score score, rf.flg_show_element_score
              FROM risk_factor rf
             WHERE rf.id_doc_element IN
                   (SELECT de.id_doc_element
                      FROM doc_element de
                     WHERE de.id_documentation IN (SELECT d.id_documentation
                                                     FROM documentation d
                                                    WHERE d.id_doc_area = i_doc_area
                                                      AND d.id_doc_template = i_doc_template));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_RISK_FACTOR', 'GET_ELEMENTS_SCORE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_score);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_risk_factor_score
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_doc_element IN table_number,
        o_total_score OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Sets a record of a risk factor
        *
        * @param i_lang             Language identifier
        * @param i_prof             Professional
        * @param i_doc_area         Documentation area ID
        * @param i_doc_element      Documentation element IDs
        * @param o_total_score      Total score
        * @param o_error            Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/28
        */
    
        l_total_score NUMBER(6);
    
    BEGIN
    
        SELECT SUM(rf.score)
          INTO l_total_score
          FROM risk_factor rf
         WHERE rf.id_doc_element IN (SELECT *
                                       FROM TABLE(i_doc_element));
    
        IF i_doc_area = 1089
        THEN
            IF (l_total_score >= 0 AND l_total_score <= 6)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M004') desc_result
                      FROM dual;
            ELSIF (l_total_score >= 7 AND l_total_score <= 11)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M005') desc_result
                      FROM dual;
            ELSIF (l_total_score >= 12 AND l_total_score <= 14)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M006') desc_result
                      FROM dual;
            ELSIF (l_total_score >= 15 AND l_total_score <= 20)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M003') desc_result
                      FROM dual;
            ELSE
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M007') desc_result
                      FROM dual;
            END IF;
        ELSIF i_doc_area = 2092
        THEN
            IF (l_total_score >= 0 AND l_total_score <= 22)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M008') desc_result
                      FROM dual;
            ELSE
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M009') desc_result
                      FROM dual;
            END IF;
        ELSIF i_doc_area = 6773
        THEN
            IF (l_total_score >= 0 AND l_total_score <= 2)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M012') desc_result
                      FROM dual;
            ELSE
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M013') desc_result
                      FROM dual;
            END IF;
        ELSIF i_doc_area = 8864
        THEN
        
            OPEN o_total_score FOR
                SELECT l_total_score total_score, NULL desc_result
                  FROM dual;
        ELSIF i_doc_area = 1056
        THEN
            IF (l_total_score >= 0 AND l_total_score <= 1)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M004') desc_result
                      FROM dual;
            ELSIF l_total_score = 2
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M006') desc_result
                      FROM dual;
            ELSIF (l_total_score >= 3 AND l_total_score <= 4)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M003') desc_result
                      FROM dual;
            ELSE
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M014') desc_result
                      FROM dual;
            END IF;
        ELSE
            IF (l_total_score >= 0 AND l_total_score <= 2)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M001') desc_result
                      FROM dual;
            ELSIF (l_total_score >= 3 AND l_total_score <= 6)
            THEN
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M002') desc_result
                      FROM dual;
            ELSE
                OPEN o_total_score FOR
                    SELECT l_total_score total_score, pk_message.get_message(i_lang, 'RISK_FACTORS_M003') desc_result
                      FROM dual;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_RISK_FACTOR_SCORE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_total_score);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION set_epis_risk_factor
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_episode               IN epis_risk_factor.id_episode%TYPE,
        i_doc_area              IN summary_page_section.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_total_score           IN epis_risk_factor.total_score%TYPE,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Sets a record of a risk factor
        *
        * @param i_lang                   Language identifier
        * @param i_prof                   Professional
        * @param i_prof_cat_type          Professional category
        * @param i_episode                Episode ID
        * @param i_doc_area               Documentation area ID
        * @param i_doc_template           Documentation template ID
        * @param i_epis_documentation     Documentation episode ID
        * @param i_flg_type               Flag Type
        * @param i_id_documentation       Documentation ID
        * @param i_id_doc_element         Documentation element IDs
        * @param i_id_doc_element_crit    Documentation element criteria IDs
        * @param i_value                  Value
        * @param i_notes                  Notes
        * @param i_id_doc_element_qualif  
        * @param i_total_score            Total score
        * @param o_epis_documentation     Documentation ID
        * @param o_error                  Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/23
        */
    
        l_epis_documentation epis_risk_factor.id_epis_documentation%TYPE;
        l_next               epis_risk_factor.id_epis_risk_factor%TYPE;
        l_code_message       VARCHAR2(200);
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        IF NOT pk_touch_option.set_epis_documentation(i_lang                  => i_lang,
                                                      i_prof                  => i_prof,
                                                      i_prof_cat_type         => i_prof_cat_type,
                                                      i_epis                  => i_episode,
                                                      i_doc_area              => i_doc_area,
                                                      i_doc_template          => i_doc_template,
                                                      i_epis_documentation    => i_epis_documentation,
                                                      i_flg_type              => i_flg_type,
                                                      i_id_documentation      => i_id_documentation,
                                                      i_id_doc_element        => i_id_doc_element,
                                                      i_id_doc_element_crit   => i_id_doc_element_crit,
                                                      i_value                 => i_value,
                                                      i_notes                 => i_notes,
                                                      i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                      i_epis_context          => NULL,
                                                      i_summary_and_notes     => NULL,
                                                      o_epis_documentation    => o_epis_documentation,
                                                      o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_epis_documentation := o_epis_documentation;
    
        g_error := 'SEQ_EPIS_RISK_FACTOR.NEXTVAL';
        SELECT seq_epis_risk_factor.nextval
          INTO l_next
          FROM dual;
    
        IF i_total_score IS NOT NULL
        THEN
            IF i_doc_area = 1089
            THEN
                IF (i_total_score >= 0 AND i_total_score <= 6)
                THEN
                    l_code_message := 'RISK_FACTORS_M004';
                ELSIF (i_total_score >= 7 AND i_total_score <= 11)
                THEN
                    l_code_message := 'RISK_FACTORS_M005';
                ELSIF (i_total_score >= 12 AND i_total_score <= 14)
                THEN
                    l_code_message := 'RISK_FACTORS_M006';
                ELSIF (i_total_score >= 15 AND i_total_score <= 20)
                THEN
                    l_code_message := 'RISK_FACTORS_M003';
                ELSE
                    l_code_message := 'RISK_FACTORS_M007';
                END IF;
            ELSIF i_doc_area = 2092
            THEN
                IF (i_total_score >= 0 AND i_total_score <= 22)
                THEN
                    l_code_message := 'RISK_FACTORS_M010';
                ELSE
                    l_code_message := 'RISK_FACTORS_M011';
                END IF;
            ELSIF i_doc_area = 8864
            THEN
                l_code_message := i_total_score;
            ELSIF i_doc_area = 6773
            THEN
                IF (i_total_score >= 0 AND i_total_score <= 2)
                THEN
                    l_code_message := 'RISK_FACTORS_M012';
                ELSE
                    l_code_message := 'RISK_FACTORS_M013';
                END IF;
            
            ELSIF i_doc_area = 1056
            THEN
                IF (i_total_score >= 0 AND i_total_score <= 1)
                THEN
                    l_code_message := 'RISK_FACTORS_M004';
                ELSIF i_total_score = 2
                THEN
                    l_code_message := 'RISK_FACTORS_M006';
                ELSIF (i_total_score >= 3 AND i_total_score <= 4)
                THEN
                    l_code_message := 'RISK_FACTORS_M003';
                ELSE
                    l_code_message := 'RISK_FACTORS_M014';
                END IF;
            
            ELSE
            
                IF (i_total_score >= 0 AND i_total_score <= 2)
                THEN
                    l_code_message := 'RISK_FACTORS_M001';
                ELSIF (i_total_score >= 3 AND i_total_score <= 6)
                THEN
                    l_code_message := 'RISK_FACTORS_M002';
                ELSE
                    l_code_message := 'RISK_FACTORS_M003';
                END IF;
            END IF;
        
            g_error := 'INSERT INTO EPIS_RISK_FACTOR';
            INSERT INTO epis_risk_factor
                (id_epis_risk_factor,
                 id_episode,
                 id_epis_documentation,
                 flg_status,
                 id_prof_cancel,
                 total_score,
                 desc_result,
                 dt_epis_risk_factor_tstz,
                 dt_cancel_tstz)
            VALUES
                (l_next,
                 i_episode,
                 l_epis_documentation,
                 g_active,
                 NULL,
                 i_total_score,
                 l_code_message,
                 g_sysdate_tstz,
                 NULL);
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'SET_EPIS_RISK_FACTOR');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_prev_risk_factor_score
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_doc_area   IN epis_documentation.id_doc_area%TYPE,
        i_flg_type   IN VARCHAR2,
        o_prev_score OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Gets the previous results for a given patient
        *
        * @param i_lang        Language identifier
        * @param i_prof        Professional
        * @param i_patient     Patient ID
        * @param o_prev_score  Previous results
        * @param o_error       Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/30
        */
    
    BEGIN
    
        IF i_flg_type = g_flg_all_eval
        THEN
            OPEN o_prev_score FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_ord,
                       decode(erf.desc_result,
                              NULL,
                              NULL,
                              nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_result,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                       --                       p.nick_name,
                       --                       '(' || pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) || ')' desc_speciality,
                       '(' ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, ed.dt_creation_tstz, e.id_episode) || ')' desc_speciality,
                       pk_date_utils.date_time_chr_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt
                  FROM episode e, epis_risk_factor erf, epis_documentation ed --, professional p
                 WHERE e.id_patient = i_patient
                   AND e.id_episode = erf.id_episode
                   AND erf.id_epis_documentation = ed.id_epis_documentation
                   AND ed.id_doc_area = i_doc_area
                --                   AND ed.id_professional = p.id_professional
                 ORDER BY 1 DESC;
        ELSIF i_flg_type = g_flg_last_eval
        THEN
            OPEN o_prev_score FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_ord,
                       decode(erf.desc_result,
                              NULL,
                              NULL,
                              nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_result,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                       --                       p.nick_name,
                       --                       '(' || pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) || ')' desc_speciality,
                       '(' ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, ed.dt_creation_tstz, e.id_episode) || ')' desc_speciality,
                       pk_date_utils.date_time_chr_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt
                  FROM episode e, epis_risk_factor erf, epis_documentation ed --, professional p
                 WHERE e.id_patient = i_patient
                   AND e.id_episode = erf.id_episode
                   AND erf.id_epis_documentation = ed.id_epis_documentation
                   AND ed.id_doc_area = i_doc_area
                      --                   AND ed.id_professional = p.id_professional
                   AND ed.dt_creation_tstz = (SELECT MAX(ed1.dt_creation_tstz)
                                                FROM epis_documentation ed1, episode e, epis_risk_factor erf
                                               WHERE e.id_patient = i_patient
                                                 AND e.id_episode = erf.id_episode
                                                 AND erf.id_epis_documentation = ed1.id_epis_documentation
                                                 AND ed1.id_doc_area = i_doc_area)
                 ORDER BY 1 DESC;
        ELSIF i_flg_type = g_flg_my_eval
        THEN
            OPEN o_prev_score FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_ord,
                       decode(erf.desc_result,
                              NULL,
                              NULL,
                              nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_result,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                       --                       p.nick_name,
                       --                       '(' || pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) || ')' desc_speciality,
                       '(' ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, ed.dt_creation_tstz, e.id_episode) || ')' desc_speciality,
                       pk_date_utils.date_time_chr_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt
                  FROM episode e, epis_risk_factor erf, epis_documentation ed --, professional p
                 WHERE e.id_patient = i_patient
                   AND e.id_episode = erf.id_episode
                   AND erf.id_epis_documentation = ed.id_epis_documentation
                   AND ed.id_doc_area = i_doc_area
                --                   AND ed.id_professional = p.id_professional
                --                   AND p.id_professional = i_prof.id
                 ORDER BY 1 DESC;
        ELSE
            OPEN o_prev_score FOR
                SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_ord,
                       decode(erf.desc_result,
                              NULL,
                              NULL,
                              nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_result,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                       --                       p.nick_name,
                       --                       '(' || pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) || ')' desc_speciality,
                       '(' ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, ed.dt_creation_tstz, e.id_episode) || ')' desc_speciality,
                       pk_date_utils.date_time_chr_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt
                  FROM episode e, epis_risk_factor erf, epis_documentation ed --, professional p
                 WHERE e.id_patient = i_patient
                   AND e.id_episode = erf.id_episode
                   AND erf.id_epis_documentation = ed.id_epis_documentation
                   AND ed.id_doc_area = i_doc_area
                      --                   AND ed.id_professional = p.id_professional
                      --                   AND p.id_professional = i_prof.id
                   AND ed.dt_creation_tstz = (SELECT MAX(ed1.dt_creation_tstz)
                                                FROM epis_documentation ed1, episode e, epis_risk_factor erf
                                               WHERE e.id_patient = i_patient
                                                 AND e.id_episode = erf.id_episode
                                                 AND erf.id_epis_documentation = ed1.id_epis_documentation
                                                 AND ed1.id_doc_area = i_doc_area)
                 ORDER BY 1 DESC;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_PREV_RISK_FACTOR_SCORE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_prev_score);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_risk_factor_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Returns the detail for a given register
        *
        * @param i_lang               Language identifier
        * @param i_prof               Professional
        * @param i_epis_document      Documentation ID
        * @param i_epis_doc_register  
        * @param o_epis_document_val    
        * @param o_error              Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/09/26
        */
    
        l_epis_doc table_number;
    
        CURSOR c_epis_doc IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
            CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
             START WITH ed.id_epis_documentation = i_epis_document
            UNION ALL
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation <> i_epis_document
            CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
             START WITH ed.id_epis_documentation = i_epis_document;
    BEGIN
        g_error := 'OPEN C_EPIS_DOC';
        OPEN c_epis_doc;
        FETCH c_epis_doc BULK COLLECT
            INTO l_epis_doc;
        CLOSE c_epis_doc;
    
        g_error := 'GET CURSOR O_EPIS_DOC_REGISTER';
        OPEN o_epis_doc_register FOR
            SELECT /*+ opt_estimate(table t rows=1)*/
             ed.id_epis_documentation,
             ed.id_doc_template,
             pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
             pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
             pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
             ed.id_professional,
             pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, '') desc_speciality,
             ed.id_doc_area,
             ed.flg_status,
             pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS', ed.flg_status, i_lang) desc_status,
             ed.notes
              FROM TABLE(l_epis_doc) t
              JOIN epis_documentation ed
                ON ed.id_epis_documentation = t.column_value
             ORDER BY dt_last_update_tstz DESC;
    
        g_error := 'GET CURSOR O_EPIS_DOCUMENT_VAL';
        OPEN o_epis_document_val FOR
            SELECT dt.*
              FROM (SELECT ed.id_epis_documentation,
                           d.id_documentation,
                           d.id_doc_component,
                           decr.id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                           TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                           pk_touch_option.get_epis_formatted_element(i_lang, i_prof, edd.id_epis_documentation_det) desc_element,
                           NULL VALUE,
                           ed.id_doc_area,
                           dtad.rank rank_component,
                           de.rank rank_element
                      FROM epis_documentation ed
                     INNER JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                     INNER JOIN documentation d
                        ON d.id_documentation = edd.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON dtad.id_doc_template = ed.id_doc_template
                       AND dtad.id_doc_area = ed.id_doc_area
                       AND dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dc
                        ON d.id_doc_component = dc.id_doc_component
                     INNER JOIN doc_element_crit decr
                        ON edd.id_doc_element_crit = decr.id_doc_element_crit
                     INNER JOIN doc_element de
                        ON de.id_documentation = d.id_documentation
                       AND de.id_doc_element = decr.id_doc_element
                    UNION
                    SELECT ed.id_epis_documentation,
                           NULL id_documentation,
                           NULL id_doc_component,
                           NULL id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                           decode(erf.desc_result, NULL, NULL, pk_message.get_message(i_lang, 'RISK_FACTORS_T011')) desc_doc_component,
                           decode(erf.desc_result,
                                  NULL,
                                  NULL,
                                  nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_element,
                           NULL VALUE,
                           ed.id_doc_area,
                           NULL rank_component,
                           NULL rank_element
                      FROM epis_risk_factor erf
                     INNER JOIN epis_documentation ed
                        ON erf.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN doc_area da
                        ON ed.id_doc_area = da.id_doc_area
                     WHERE da.flg_score = g_yes) dt
              JOIN (SELECT /*+ opt_estimate(table t rows=1)*/
                     t.column_value id_epis_documentation
                      FROM TABLE(l_epis_doc) t) t
                ON dt.id_epis_documentation = t.id_epis_documentation
             ORDER BY dt.id_epis_documentation, rank_component, rank_element;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_RISK_FACTOR', 'GET_RISK_FACTOR_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_epis_doc_register);
                pk_types.open_my_cursor(o_epis_document_val);
            
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_total_score(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE) RETURN NUMBER IS
    
        /*
        * Returns the total score
        *
        * @param i_epis_documentation  Documentation ID
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/29
        */
    
        l_total_score NUMBER(6);
    
    BEGIN
    
        g_error := 'GET POINTS';
        SELECT SUM(rf.score)
          INTO l_total_score
          FROM epis_documentation ed, epis_documentation_det dd, doc_element_crit c, doc_element de, risk_factor rf
         WHERE ed.id_epis_documentation = i_epis_documentation
           AND dd.id_epis_documentation = ed.id_epis_documentation
           AND c.id_doc_element_crit = dd.id_doc_element_crit
           AND c.id_doc_criteria = 1
           AND de.id_doc_element = c.id_doc_element
           AND rf.id_doc_element = de.id_doc_element;
    
        RETURN l_total_score;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END;

    /********************************************************************************************
    * Get the risk total score of a specific documentation area 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             patient ID
    * @param   i_doc_area            doc area ID
    *
    * @RETURN  Total score
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   21-11-2011
    **********************************************************************************************/
    FUNCTION get_pat_total_score
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN NUMBER IS
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        CURSOR c_epis_doc IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
              JOIN episode e
                ON e.id_episode = ed.id_episode
             WHERE e.id_patient = i_patient
               AND ed.id_doc_area = i_doc_area
               AND ed.flg_status = pk_alert_constant.g_active
             ORDER BY ed.dt_last_update_tstz DESC;
    
    BEGIN
    
        g_error := 'GET EPISODE DOCUMENTATION ID';
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_epis_documentation;
        CLOSE c_epis_doc;
    
        RETURN get_total_score(l_epis_documentation);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_total_score;

    FUNCTION get_risk_factor_help
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_title    OUT pk_types.cursor_type,
        o_help     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * Returns the help text to show to the usar
        *
        * @param i_lang          Language identifier
        * @param i_prof          Professional
        * @param i_risk_factor   Risk factor ID
        * @param o_title         Title
        * @param o_help          Help text
        * @param o_error         Error
        *
        * @author ASM
        * @version alpha
        * @since 2007/08/30
        */
    
    BEGIN
    
        g_error := 'GET CURSOR O_TITLE';
        OPEN o_title FOR
            SELECT pk_translation.get_translation(i_lang, rfh.code_title_risk_factor_help) title_help
              FROM doc_area da, risk_factor_help rfh
             WHERE da.id_doc_area = i_doc_area
               AND da.id_doc_area = rfh.id_doc_area
               AND rfh.flg_available = g_available;
    
        g_error := 'GET CURSOR O_HELP';
        OPEN o_help FOR
            SELECT pk_translation.get_translation(i_lang, rfh.code_risk_factor_help) desc_help
              FROM doc_area da, risk_factor_help rfh
             WHERE da.id_doc_area = i_doc_area
               AND da.id_doc_area = rfh.id_doc_area
               AND rfh.flg_available = g_available;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_RISK_FACTOR',
                                   'GET_RISK_FACTOR_HELP');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_title);
                pk_types.open_my_cursor(o_help);
            
                RETURN FALSE;
            
            END;
    END;
    /********************************************************************************************
    * return list of scales for a given epis_documentation           
    *                                                                         
    * @param i_lang                   The language ID                         
    * @param i_prof                   Object (professional ID, institution ID,software ID)   
    * @param i_patient                patient ID                         
    * @param i_epis_documentation     array with ID_EPIS_DOCUMENTION                        
    *                                                                         
    * @return                         return list of scales epis_documentation       
    *                                                                         
    * @author                         Elisabete Bugalho                              
    * @version                        2.6.2.1                                     
    * @since                          2012/03/26                              
    **************************************************************************/
    FUNCTION tf_risk_total_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN table_number
    ) RETURN t_coll_doc_risk
        PIPELINED IS
    
        l_coll_risk    t_coll_doc_risk;
        l_message_risk sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'RISK_FACTORS_T011');
        CURSOR c_risk IS
            SELECT ed.id_epis_documentation,
                   erf.id_epis_risk_factor id_score,
                   ed.id_doc_template,
                   decode(erf.desc_result, NULL, NULL, l_message_risk) || ':' ||
                   decode(erf.desc_result,
                          NULL,
                          NULL,
                          nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_element,
                   get_total_score(ed.id_epis_documentation) total,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   ed.dt_last_update_tstz,
                   ed.flg_status
              FROM episode e
             INNER JOIN epis_documentation ed
                ON e.id_episode = ed.id_episode
             INNER JOIN epis_risk_factor erf
                ON e.id_episode = erf.id_episode
               AND erf.id_epis_documentation = ed.id_epis_documentation
             INNER JOIN doc_area da
                ON ed.id_doc_area = da.id_doc_area
             WHERE ed.id_epis_documentation IN (SELECT /*+ dynamic_sampling(t 2) */
                                                 t.column_value
                                                  FROM TABLE(i_epis_documentation) t)
               AND da.flg_score = g_yes
             ORDER BY ed.dt_last_update_tstz DESC;
    
    BEGIN
    
        OPEN c_risk;
        LOOP
            FETCH c_risk BULK COLLECT
                INTO l_coll_risk LIMIT 500;
            FOR i IN 1 .. l_coll_risk.count
            LOOP
                PIPE ROW(l_coll_risk(i));
            END LOOP;
            EXIT WHEN c_risk%NOTFOUND;
        END LOOP;
        CLOSE c_risk;
    
        RETURN;
    
    END tf_risk_total_score;

    /********************************************************************************************
    * Cancel documentation risk_factor episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Jorge Silva
    * @version                        1.0   
    * @since                          2013/04/11
    *  
    **********************************************************************************************/

    FUNCTION cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_notes       IN VARCHAR2,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'cancel_epis_documentation';
    BEGIN
        g_error := 'call pk_touch_option.cancel_epis_documentation';
        IF NOT pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_epis_doc   => i_id_epis_doc,
                                                         i_notes         => i_notes,
                                                         i_test          => i_test,
                                                         i_cancel_reason => NULL,
                                                         o_flg_show      => o_flg_show,
                                                         o_msg_title     => o_msg_title,
                                                         o_msg_text      => o_msg_text,
                                                         o_button        => o_button,
                                                         o_error         => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_RISK_FACTOR', l_func_name);
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                RETURN FALSE;
            END;
    END cancel_epis_documentation;

    FUNCTION get_epis_risk_factors
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_risk_factors OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient         patient.id_patient%TYPE;
        k_id_summary_page summary_page.id_summary_page%TYPE := 5;
        c_chr_separator   VARCHAR2(5) := ': ';
        l_sections        pk_types.cursor_type;
        l_sections_rec    pk_summary_page.t_rec_section;
        l_sections_tab    pk_summary_page.t_coll_section;
        l_doc_scales      pk_scales_core.t_cur_doc_scales;
        l_doc_scales_rec  pk_scales_core.t_rec_doc_scales;
        l_doc_scales_tab  pk_scales_core.t_coll_doc_scales;
        l_epis_doc_ids    table_number;
        l_doc_area_ids    table_number;
        l_record_count    NUMBER;
        l_tp_desc_scales  t_coll_desc_scales := t_coll_desc_scales();
        CURSOR c_risk_factors(i_id_doc_area IN doc_area.id_doc_area%TYPE) IS
            SELECT signature, desc_doc_component, desc_element
              FROM (SELECT ed.dt_last_update_tstz,
                           pk_prof_utils.get_detail_signature(i_lang,
                                                              i_prof,
                                                              NULL,
                                                              ed.dt_last_update_tstz,
                                                              ed.id_professional) signature,
                           decode(erf.desc_result, NULL, NULL, pk_message.get_message(i_lang, 'RISK_FACTORS_T011')) desc_doc_component,
                           decode(erf.desc_result,
                                  NULL,
                                  NULL,
                                  nvl(pk_message.get_message(i_lang, erf.desc_result), erf.desc_result)) desc_element,
                           row_number() over(ORDER BY ed.dt_last_update_tstz) rn
                      FROM epis_documentation ed
                      LEFT JOIN epis_risk_factor erf
                        ON ed.id_epis_documentation = erf.id_epis_documentation
                     WHERE ed.id_episode = i_episode
                       AND id_doc_area = i_id_doc_area
                       AND ed.flg_status = pk_alert_constant.g_active)
             WHERE rn = 1;
        l_rec_risk_factors   c_risk_factors%ROWTYPE;
        l_desc_doc_component VARCHAR2(200 CHAR);
        l_desc_element       VARCHAR2(200 CHAR);
        l_signature          VARCHAR2(200 CHAR);
    BEGIN
        IF i_episode IS NULL
        THEN
            RAISE g_exception;
            RETURN FALSE;
        END IF;
        g_error := 'CALL pk_episode.get_epis_patient: i_id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        -- Get patient from episode
        l_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        g_error   := 'CALL pk_summary_page.get_summary_page_sections: i_id_summary_page: ' || k_id_summary_page ||
                     ', i_pat: ' || l_patient;
        pk_alertlog.log_debug(g_error);
        -- Get summary page sections for the assessment scales summary page, but we only need the doc_area ids and the section title
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => k_id_summary_page,
                                                         i_pat             => l_patient,
                                                         o_sections        => l_sections,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_sections BULK COLLECT
            INTO l_sections_tab;
        FOR i IN 1 .. l_sections_tab.count
        LOOP
            l_sections_rec := l_sections_tab(i);
            g_error        := 'CALL pk_touch_option.get_doc_area_value_ids: epis:' || i_episode || 'doc_area:' ||
                              l_sections_rec.id_doc_area;
            pk_alertlog.log_debug(g_error);
        
            OPEN c_risk_factors(l_sections_rec.id_doc_area);
            FETCH c_risk_factors
                INTO l_signature, l_desc_doc_component, l_desc_element;
            CLOSE c_risk_factors;
            IF l_sections_rec.flg_score = pk_alert_constant.g_yes
            THEN
                IF l_signature IS NOT NULL
                THEN
                    IF l_desc_doc_component IS NOT NULL
                    THEN
                        l_tp_desc_scales.extend;
                        l_tp_desc_scales(l_tp_desc_scales.last()) := t_rec_desc_scales(l_sections_rec.translated_code ||
                                                                                       c_chr_separator ||
                                                                                       l_desc_doc_component ||
                                                                                       c_chr_separator ||
                                                                                       l_desc_element,
                                                                                       l_signature);
                    ELSE
                        l_tp_desc_scales.extend;
                        l_tp_desc_scales(l_tp_desc_scales.last()) := t_rec_desc_scales(l_sections_rec.translated_code,
                                                                                       l_signature);
                    END IF;
                END IF;
                l_signature := NULL;
            END IF;
        END LOOP;
        
        OPEN o_risk_factors FOR
            SELECT desc_class desc_info, signature
              FROM TABLE(l_tp_desc_scales);
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_RISK_FACTOR',
                                              'GET_EPIS_RISK_FACTORS',
                                              o_error);
            RETURN FALSE;
    END get_epis_risk_factors;

END;
/
