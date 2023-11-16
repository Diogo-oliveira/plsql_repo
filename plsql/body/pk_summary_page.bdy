/*-- Last Change Revision: $Rev: 2010617 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-03-09 11:35:03 +0000 (qua, 09 mar 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_summary_page IS

    PROCEDURE open_my_cursor(i_cursor IN OUT t_cur_section) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL translated_code,
                   NULL id_doc_area,
                   NULL screen_name,
                   NULL id_sys_shortcut,
                   NULL flg_write,
                   NULL flg_search,
                   NULL flg_no_changes,
                   NULL flg_template,
                   NULL height,
                   NULL flg_type,
                   NULL screen_name_after_save,
                   NULL subtitle,
                   NULL intern_name_sample_text_type,
                   NULL flg_score,
                   NULL screen_name_free_text,
                   NULL flg_scope_type,
                   NULL flg_data_paging_enabled,
                   NULL page_size,
                   NULL rank,
                   NULL flg_create
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /********************************************************************************************
    * Returns the sections within a summary page to be presented in reports
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param o_sections               Cursor containing the sections info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Tiago LourenÁo
    * @version                        v2.5.1.6
    * @since                          08-Jun-2011
    **********************************************************************************************/
    FUNCTION get_summary_page_sections_rep
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE;
    BEGIN
    
        ---- MARKET
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        ---- QUERY
        OPEN o_sections FOR
            SELECT DISTINCT sps.id_doc_area doc_area,
                            pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                            sps.rank
              FROM summary_page sp
             INNER JOIN summary_page_section sps
                ON sp.id_summary_page = sps.id_summary_page
             INNER JOIN doc_area da
                ON sps.id_doc_area = da.id_doc_area
             INNER JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, l_market, i_prof.software)) dais
                ON da.id_doc_area = dais.id_doc_area
             WHERE sp.id_summary_page = i_id_summary_page
             ORDER BY sps.rank, translated_code;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_PAGE_SECTIONS_REP',
                                              o_error);
            pk_types.open_my_cursor(o_sections);
            RETURN FALSE;
    END get_summary_page_sections_rep;
    /********************************************************************************************
    * RETURN the doc area BY category AND professional
    ********************************************************************************************/
    FUNCTION get_doc_area_by_cat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_category IN doc_category.id_doc_category%TYPE
    ) RETURN table_number IS
        l_id_doc_area table_number;
    BEGIN
        SELECT id_doc_area
          BULK COLLECT
          INTO l_id_doc_area
          FROM doc_category_area_inst_soft dcais
          JOIN doc_category_inst_soft dcis
            ON dcais.id_doc_category = dcis.id_doc_category
          JOIN doc_category dc
            ON dc.id_doc_category = dcis.id_doc_category
         WHERE dc.id_doc_category = i_id_doc_category
           AND dc.flg_available = pk_alert_constant.g_yes
           AND dcais.id_software = dcis.id_software
           AND dcis.id_institution = i_prof.institution
           AND dcis.id_software = i_prof.software;
        RETURN l_id_doc_area;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_doc_area_by_cat;
    --
    /********************************************************************************************
    * Returns the sections within a summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_pat                    Patient ID
    * @param i_doc_areas_ex           doc_areas to exclude
    * @param i_doc_areas_in           doc_areas to include
    * @param o_sections               Cursor containing the sections info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu, LuÌs Gaspar
    * @version                        1.0
    * @since                          2007/05/24
    **********************************************************************************************/
    FUNCTION get_summary_page_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_pat              IN patient.id_patient%TYPE,
        i_complete_epi_rep IN BOOLEAN,
        i_doc_areas_ex     IN table_number,
        i_doc_areas_in     IN table_number,
        o_sections         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_access       summary_page.flg_access%TYPE;
        l_age              patient.age%TYPE;
        l_gender           patient.gender%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_market           market.id_market%TYPE;
    
        l_sections t_coll_sections;
    BEGIN
    
        g_error := 'AGE AND GENDER CHECK'; -- RdSN
        SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age_in_years
          INTO l_gender, l_age
          FROM patient p
         WHERE p.id_patient = i_pat;
    
        IF i_complete_epi_rep
        THEN
            l_flg_access       := g_yes;
            l_profile_template := pk_sysconfig.get_config(i_code_cf   => 'COMPLETE_EPISODE_REPORT_PROFILE',
                                                          i_prof_inst => i_prof.institution,
                                                          i_prof_soft => i_prof.software);
        ELSE
            g_error := 'NEEDS ACCESS CHECK';
            SELECT sp.flg_access
              INTO l_flg_access
              FROM summary_page sp
             WHERE sp.id_summary_page = i_id_summary_page;
        
            g_error            := 'GET ID_PROFILE_TEMPLATE';
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        END IF;
    
        g_error  := 'GET MARKET';
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        --    if i_doc_areas is not  or i_doc_areas.exists() 
        IF l_flg_access = g_yes
        THEN
        
            g_error := 'OPEN O_SECTIONS WITH ACCESS CHECK';
        
            l_sections := tf_sections(i_lang             => i_lang,
                                      i_prof             => i_prof,
                                      i_market           => l_market,
                                      i_gender           => l_gender,
                                      i_age              => l_age,
                                      i_profile_template => l_profile_template,
                                      i_id_summary_page  => i_id_summary_page,
                                      i_doc_areas_ex     => i_doc_areas_ex,
                                      i_doc_areas_in     => i_doc_areas_in);
        
            OPEN o_sections FOR
                SELECT t.translated_code,
                       t.doc_area,
                       t.screen_name,
                       t.id_sys_shortcut,
                       t.flg_write,
                       t.flg_search,
                       t.flg_no_changes,
                       t.flg_template,
                       t.height,
                       t.flg_type,
                       t.screen_name_after_save,
                       t.subtitle,
                       t.intern_name_sample_text_type,
                       t.flg_score,
                       t.screen_name_free_text,
                       t.flg_scope_type,
                       t.flg_data_paging_enabled,
                       t.page_size,
                       t.rank,
                       t.flg_create
                  FROM TABLE(l_sections) t;
        
        ELSE
            g_error := 'OPEN O_SECTIONS WITH NO ACCESS CHECK';
            OPEN o_sections FOR
                SELECT translated_code,
                       doc_area,
                       screen_name,
                       id_sys_shortcut,
                       flg_write,
                       flg_search,
                       flg_no_changes,
                       flg_template,
                       height,
                       flg_type,
                       screen_name_after_save,
                       subtitle,
                       intern_name_sample_text_type,
                       flg_score,
                       screen_name_free_text,
                       flg_scope_type,
                       flg_data_paging_enabled,
                       page_size,
                       rank,
                       NULL flg_create
                  FROM (SELECT t.*,
                               translate(upper(t.translated_code),
                                         '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ',
                                         'AEIOUAEIOUAEIOUAOCAEIOUN%') AS sort_description
                          FROM (SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                                       sps.id_doc_area doc_area,
                                       sps.screen_name,
                                       sps.id_sys_shortcut,
                                       g_yes flg_write, -- no access check -> write access
                                       g_no flg_search, -- no access check -> no search access
                                       g_yes flg_no_changes, -- no access check -> no_changes access
                                       decode(sps.id_doc_area, NULL, g_no, g_yes) flg_template,
                                       sps.height,
                                       dais.flg_type,
                                       sps.screen_name_after_save,
                                       pk_translation.get_translation(i_lang, sps.code_page_section_subtitle) subtitle,
                                       da.intern_name_sample_text_type,
                                       da.flg_score,
                                       sps.screen_name_free_text,
                                       dais.flg_scope_type,
                                       dais.flg_data_paging_enabled,
                                       dais.page_size,
                                       sps.rank
                                  FROM summary_page sp
                                 INNER JOIN summary_page_section sps
                                    ON sp.id_summary_page = sps.id_summary_page
                                 INNER JOIN doc_area da
                                    ON sps.id_doc_area = da.id_doc_area
                                 INNER JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, l_market, i_prof.software)) dais
                                    ON da.id_doc_area = dais.id_doc_area
                                 WHERE sp.id_summary_page = i_id_summary_page
                                   AND (da.gender IS NULL OR da.gender = l_gender OR l_gender = 'I')
                                   AND (da.age_min IS NULL OR da.age_min <= l_age OR l_age IS NULL)
                                   AND (da.age_max IS NULL OR da.age_max >= l_age OR l_age IS NULL)) t)
                 ORDER BY rank, sort_description;
        
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
                                              'GET_SUMMARY_PAGE_SECTIONS',
                                              o_error);
            open_my_cursor(o_sections);
            RETURN FALSE;
    END get_summary_page_sections;
    --
    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_summary_page_sections(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_summary_page  => i_id_summary_page,
                                         i_pat              => i_pat,
                                         i_complete_epi_rep => FALSE,
                                         i_id_doc_category  => NULL,
                                         o_sections         => o_sections,
                                         o_error            => o_error);
    END get_summary_page_sections;

    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        i_id_doc_category IN doc_category.id_doc_category%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_summary_page_sections(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_summary_page  => i_id_summary_page,
                                         i_pat              => i_pat,
                                         i_complete_epi_rep => FALSE,
                                         i_id_doc_category  => i_id_doc_category,
                                         o_sections         => o_sections,
                                         o_error            => o_error);
    END get_summary_page_sections;

    /********************************************************************************************
    * Returns the sections within a summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_pat                    Patient ID
    * @param o_sections               Cursor containing the sections info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Abreu, LuÌs Gaspar
    * @version                        1.0
    * @since                          2007/05/24
    **********************************************************************************************/
    FUNCTION get_summary_page_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_summary_page  IN summary_page.id_summary_page%TYPE,
        i_pat              IN patient.id_patient%TYPE,
        i_complete_epi_rep IN BOOLEAN,
        i_id_doc_category  IN doc_category.id_doc_category%TYPE DEFAULT NULL,
        o_sections         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_doc_area table_number;
    BEGIN
        IF i_id_doc_category IS NOT NULL
        THEN
            l_id_doc_area := get_doc_area_by_cat(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_doc_category => i_id_doc_category);
        END IF;
    
        RETURN get_summary_page_sections(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_summary_page  => i_id_summary_page,
                                         i_pat              => i_pat,
                                         i_complete_epi_rep => FALSE,
                                         i_doc_areas_ex     => NULL,
                                         i_doc_areas_in     => l_id_doc_area,
                                         o_sections         => o_sections,
                                         o_error            => o_error);
    END get_summary_page_sections;

    --
    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    * Similar to PK_SUMMARY_PAGE.GET_SUMM_PAGE_DOC_AREA_VALUE, but for all patient episodes
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/02
    *
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/

    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL get_past_hist_relev_notes_int';
        IF NOT get_summ_page_doc_area_pat_int(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_episode            => i_episode,
                                              i_pat                => i_pat,
                                              i_doc_area           => i_doc_area,
                                              o_doc_area_register  => o_doc_area_register,
                                              o_doc_area_val       => o_doc_area_val,
                                              o_template_layouts   => o_template_layouts,
                                              o_doc_area_component => o_doc_area_component,
                                              o_error              => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        pk_types.open_cursor_if_closed(o_template_layouts);
        pk_types.open_cursor_if_closed(o_doc_area_component);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_page_doc_area_pat',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            RETURN FALSE;
        
    END get_summ_page_doc_area_pat;

    /********************************************************************************************
    * Returns documentation data for a given patient (the one referenced on the current episode)
    * Similar to PK_SUMMARY_PAGE.GET_SUMM_PAGE_DOC_AREA_VALUE, but for all patient episodes
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/02
    *
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat_int
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_pat                IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_summ_page_doc_area_pat_int';
        l_order_by     sys_config.value%TYPE;
        l_record_count NUMBER;
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => l_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'CALL pk_touch_option.get_doc_area_value';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_episode,
                                                  i_scope              => i_pat,
                                                  i_scope_type         => pk_alert_constant.g_scope_type_patient,
                                                  i_order              => l_order_by,
                                                  i_paging             => pk_alert_constant.g_no,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => l_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              l_function_name,
                                              o_error);
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            RETURN FALSE;
    END get_summ_page_doc_area_pat_int;
    --
    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para um episÛdio
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/05/30
    *
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_visit              IN visit.id_visit%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_summ_page_doc_area';
        l_order_by     sys_config.value%TYPE;
        l_scope_type   doc_area_inst_soft.flg_scope_type%TYPE;
        l_scope        NUMBER(24);
        l_record_count NUMBER;
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => l_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        IF i_visit IS NOT NULL
        THEN
            l_scope      := i_visit;
            l_scope_type := pk_alert_constant.g_scope_type_visit;
        ELSE
            l_scope      := i_episode;
            l_scope_type := pk_alert_constant.g_scope_type_episode;
        END IF;
    
        g_error := 'CALL pk_touch_option.get_doc_area_value';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_episode,
                                                  i_scope              => l_scope,
                                                  i_scope_type         => l_scope_type,
                                                  i_order              => l_order_by,
                                                  i_paging             => pk_alert_constant.g_no,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => l_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              'get_summ_page_doc_area',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_summ_page_doc_area;

    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para um episÛdio
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/05/30
    *
    * Changes:
    *                             Ariel Machado
    *                             version 2.4.4   
    *                             2009/03/20
    *                             Returns layout for each template used
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN get_summ_page_doc_area(i_lang,
                                      i_prof,
                                      i_episode,
                                      NULL,
                                      i_doc_area,
                                      o_doc_area_register,
                                      o_doc_area_val,
                                      o_template_layouts,
                                      o_doc_area_component,
                                      o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_page_doc_area_value',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_summ_page_doc_area_value;

    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para uma visita
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         JosÈ Silva
    * @version                        2.5
    * @since                          2010/03/18
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_visit
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit visit.id_visit%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_VISIT';
        SELECT id_visit
          INTO l_visit
          FROM episode
         WHERE id_episode = i_episode;
    
        RETURN get_summ_page_doc_area(i_lang,
                                      i_prof,
                                      NULL,
                                      l_visit,
                                      i_doc_area,
                                      o_doc_area_register,
                                      o_doc_area_val,
                                      o_template_layouts,
                                      o_doc_area_component,
                                      o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_page_doc_area_visit',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_summ_page_doc_area_visit;

    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para um paciente - Para uso nos reports
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID
    * @param i_prof_sw                software ID
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @version                        2.4.3
    * @since                          2008/08/11
    *                                 Retrieves data from multichoice elements
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_pg_doc_ar_val_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
    
        RETURN get_summ_page_doc_area_value(i_lang,
                                            i_prof,
                                            i_episode,
                                            i_doc_area,
                                            o_doc_area_register,
                                            o_doc_area_val,
                                            o_template_layouts,
                                            o_doc_area_component,
                                            o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_pg_doc_ar_val_reports',
                                              o_error);
        
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_summ_pg_doc_ar_val_reports;
    --

    /********************************************************************************************
    * Devolver o profissional que efectou a ˙ltima alteraÁ„o e respectiva data. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_last_update            Cursor containing the last update register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/05/30
    *
    * Changes:
    *                             Ariel Machado
    *                             version 1.1   
    *                             2008/04/15
    *                             Check doc_area collection if it's necessary to obtain last updates 
    *                             of records that are not in the documentation format.
    **********************************************************************************************/
    FUNCTION get_summ_hist_ill_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date_doc         VARCHAR2(200 CHAR);
        l_nick_name        professional.nick_name%TYPE;
        l_desc_speciality  pk_translation.t_desc_translation;
        l_date_target      VARCHAR2(200 CHAR);
        l_hour_target      VARCHAR2(200 CHAR);
        l_title            VARCHAR2(200 CHAR);
        l_date_hour_target VARCHAR2(200 CHAR);
        --
        l_compl_date             VARCHAR2(200 CHAR);
        l_compl_nick_name        professional.nick_name%TYPE;
        l_compl_desc_speciality  pk_translation.t_desc_translation;
        l_compl_date_target      VARCHAR2(200 CHAR);
        l_compl_hour_target      VARCHAR2(200 CHAR);
        l_compl_date_hour_target VARCHAR2(200 CHAR);
        --
        l_anam_compl_date            VARCHAR2(200 CHAR);
        l_anam_compl_nick_name       professional.nick_name%TYPE;
        l_anam_compl_desc_speciality pk_translation.t_desc_translation;
        l_anam_compl_date_target     VARCHAR2(200 CHAR);
        l_anam_compl_hour_target     VARCHAR2(200 CHAR);
        --l_anam_compl_date_hour_target VARCHAR2(200 CHAR);
        --
        l_anam_date             VARCHAR2(200 CHAR);
        l_anam_nick_name        professional.nick_name%TYPE;
        l_anam_desc_speciality  pk_translation.t_desc_translation;
        l_anam_date_target      VARCHAR2(200 CHAR);
        l_anam_hour_target      VARCHAR2(200 CHAR);
        l_anam_date_hour_target VARCHAR2(200 CHAR);
        --
        l_rvs_date             VARCHAR2(200 CHAR);
        l_rvs_nick_name        professional.nick_name%TYPE;
        l_rvs_desc_speciality  pk_translation.t_desc_translation;
        l_rvs_date_target      VARCHAR2(200 CHAR);
        l_rvs_hour_target      VARCHAR2(200 CHAR);
        l_rvs_date_hour_target VARCHAR2(200 CHAR);
        --
        l_exm_date             VARCHAR2(200 CHAR);
        l_exm_nick_name        professional.nick_name%TYPE;
        l_exm_desc_speciality  pk_translation.t_desc_translation;
        l_exm_date_target      VARCHAR2(200 CHAR);
        l_exm_hour_target      VARCHAR2(200 CHAR);
        l_exm_date_hour_target VARCHAR2(200 CHAR);
        --
        l_asm_date             VARCHAR2(200 CHAR);
        l_asm_nick_name        professional.nick_name%TYPE;
        l_asm_desc_speciality  pk_translation.t_desc_translation;
        l_asm_date_target      VARCHAR2(200 CHAR);
        l_asm_hour_target      VARCHAR2(200 CHAR);
        l_asm_date_hour_target VARCHAR2(200 CHAR);
    
        l_doc_last_update        pk_types.cursor_type;
        l_compl_last_update      pk_types.cursor_type;
        l_anam_last_update       pk_types.cursor_type;
        l_anam_compl_last_update pk_types.cursor_type;
        l_rvs_last_update        pk_types.cursor_type;
        l_exm_last_update        pk_types.cursor_type;
        l_asm_last_update        pk_types.cursor_type;
    
        --
        l_doc_last_found   VARCHAR2(5 CHAR);
        l_compl_found      VARCHAR2(5 CHAR);
        l_anam_found       VARCHAR2(5 CHAR);
        l_anam_compl_found VARCHAR2(5 CHAR);
        l_rvs_found        VARCHAR2(5 CHAR);
        l_exm_found        VARCHAR2(5 CHAR);
        l_asm_found        VARCHAR2(5 CHAR);
    
        --   
        l_doc_area_idx NUMBER;
    BEGIN
    
        --Documentation last update
        g_error := 'CALL PK_TOUCH_OPTION.GET_EPIS_DOCUMENT_LAST_UPDATE';
        IF NOT pk_touch_option.get_epis_document_last_update(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_episode     => i_episode,
                                                             i_doc_area    => i_doc_area,
                                                             o_last_update => l_doc_last_update,
                                                             o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH L_DOC_LAST_UPDATE';
        FETCH l_doc_last_update
            INTO l_title, l_date_doc, l_nick_name, l_desc_speciality, l_date_target, l_hour_target, l_date_hour_target;
        l_doc_last_found := pk_utils.to_str(l_doc_last_update%FOUND);
        CLOSE l_doc_last_update;
    
        l_compl_found      := 'FALSE';
        l_anam_found       := 'FALSE';
        l_anam_compl_found := 'FALSE';
        l_rvs_found        := 'FALSE';
        l_exm_found        := 'FALSE';
        l_asm_found        := 'FALSE';
    
        -- AM, version 1.1
        --Traverse doc_area collection to check if it's necessary to obtain last updates of records that are not in the documentation format 
        l_doc_area_idx := i_doc_area.first;
        <<doc_area_loop>>
        WHILE l_doc_area_idx IS NOT NULL
        LOOP
        
            CASE i_doc_area(l_doc_area_idx)
            
                WHEN g_doc_area_complaint THEN
                    --Complaint last update (touch mode)
                
                    g_error := 'CALL PK_COMPLAINT.GET_EPIS_COMPLAINT_LAST_UPDATE';
                    IF NOT pk_complaint.get_epis_complaint_last_update(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_episode     => i_episode,
                                                                       i_doc_area    => i_doc_area,
                                                                       o_last_update => l_compl_last_update,
                                                                       o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'FETCH L_COMPL_LAST_UPDATE';
                    FETCH l_compl_last_update
                        INTO l_compl_date,
                             l_compl_nick_name,
                             l_compl_desc_speciality,
                             l_compl_date_target,
                             l_compl_hour_target,
                             l_compl_date_hour_target;
                    l_compl_found := pk_utils.to_str(l_compl_last_update%FOUND);
                    CLOSE l_compl_last_update;
                
                    --Complaint last update (free text mode)
                    g_error := 'CALL pk_clinical_info.get_epis_anamnesis_last_update (complaint)';
                    IF NOT pk_clinical_info.get_epis_anamnesis_last_update(i_lang        => i_lang,
                                                                           i_prof        => i_prof,
                                                                           i_episode     => i_episode,
                                                                           i_flg_type    => g_epis_anam_flg_type_c,
                                                                           o_last_update => l_anam_compl_last_update,
                                                                           o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --
                    g_error := 'FETCH L_ANAM_COMPL_LAST_UPDATE';
                    FETCH l_anam_compl_last_update
                        INTO l_anam_compl_date,
                             l_anam_compl_nick_name,
                             l_anam_compl_desc_speciality,
                             l_anam_compl_date_target,
                             l_anam_compl_hour_target,
                             l_anam_date_hour_target;
                    l_anam_compl_found := pk_utils.to_str(l_anam_compl_last_update%FOUND);
                    CLOSE l_anam_compl_last_update;
                
                WHEN g_doc_area_hist_ill THEN
                    --Anamnesis last update 
                
                    g_error := 'CALL pk_clinical_info.get_epis_anamnesis_last_update (anamnesis)';
                    IF NOT pk_clinical_info.get_epis_anamnesis_last_update(i_lang        => i_lang,
                                                                           i_prof        => i_prof,
                                                                           i_episode     => i_episode,
                                                                           i_flg_type    => g_epis_anam_flg_type_a,
                                                                           o_last_update => l_anam_last_update,
                                                                           o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --
                    g_error := 'FETCH L_ANAM_LAST_UPDATE';
                    FETCH l_anam_last_update
                        INTO l_anam_date,
                             l_anam_nick_name,
                             l_anam_desc_speciality,
                             l_anam_date_target,
                             l_anam_hour_target,
                             l_anam_date_hour_target;
                    l_anam_found := pk_utils.to_str(l_anam_last_update%FOUND);
                    CLOSE l_anam_last_update;
                
                WHEN g_doc_area_rev_sys THEN
                    --Review of system last update
                
                    g_error := 'CALL pk_clinical_info.get_epis_anamnesis_last_update';
                    IF NOT pk_clinical_info.get_epis_rvsystems_last_update(i_lang        => i_lang,
                                                                           i_prof        => i_prof,
                                                                           i_episode     => i_episode,
                                                                           o_last_update => l_rvs_last_update,
                                                                           o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                    --
                    g_error := 'FETCH L_rvs_LAST_UPDATE';
                    FETCH l_rvs_last_update
                        INTO l_rvs_date,
                             l_rvs_nick_name,
                             l_rvs_desc_speciality,
                             l_rvs_date_target,
                             l_rvs_hour_target,
                             l_rvs_date_hour_target;
                    l_rvs_found := pk_utils.to_str(l_rvs_last_update%FOUND);
                    CLOSE l_rvs_last_update;
                
                WHEN g_doc_area_phy_exam THEN
                    --Physical exam last update
                
                    g_error := 'CALL pk_clinical_info.get_epis_obs_last_update (exam)';
                    IF NOT pk_clinical_info.get_epis_obs_last_update(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_episode     => i_episode,
                                                                     i_flg_type    => g_epis_obs_flg_type_e,
                                                                     o_last_update => l_exm_last_update,
                                                                     o_error       => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    g_error := 'FETCH l_exm_last_update';
                    FETCH l_exm_last_update
                        INTO l_exm_date,
                             l_exm_nick_name,
                             l_exm_desc_speciality,
                             l_exm_date_target,
                             l_exm_hour_target,
                             l_exm_date_hour_target;
                    l_exm_found := pk_utils.to_str(l_exm_last_update%FOUND);
                    CLOSE l_exm_last_update;
                
                ELSE
                    NULL;
            END CASE;
            l_doc_area_idx := i_doc_area.next(l_doc_area_idx);
        END LOOP doc_area_loop;
        --
        g_error := 'OPEN O_LAST_UPDATE';
        OPEN o_last_update FOR
            SELECT nvl(title, pk_message.get_message(i_lang, 'DOCUMENTATION_T001')) title,
                   last_date,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   date_hour_target
              FROM (SELECT l_title            title,
                           l_date_doc         last_date,
                           l_nick_name        nick_name,
                           l_desc_speciality  desc_speciality,
                           l_date_target      date_target,
                           l_hour_target      hour_target,
                           l_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_doc_last_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                     title,
                           l_compl_date             last_date,
                           l_compl_nick_name        nick_name,
                           l_compl_desc_speciality  desc_speciality,
                           l_compl_date_target      date_target,
                           l_compl_hour_target      hour_target,
                           l_compl_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_compl_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                         title,
                           l_anam_compl_date            last_date,
                           l_anam_compl_nick_name       nick_name,
                           l_anam_compl_desc_speciality desc_speciality,
                           l_anam_compl_date_target     date_target,
                           l_anam_compl_hour_target     hour_target,
                           l_anam_date_hour_target      date_hour_target
                      FROM dual
                     WHERE l_anam_compl_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                    title,
                           l_anam_date             last_date,
                           l_anam_nick_name        nick_name,
                           l_anam_desc_speciality  desc_speciality,
                           l_anam_date_target      date_target,
                           l_anam_hour_target      hour_target,
                           l_anam_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_anam_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                   title,
                           l_rvs_date             last_date,
                           l_rvs_nick_name        nick_name,
                           l_rvs_desc_speciality  desc_speciality,
                           l_rvs_date_target      date_target,
                           l_rvs_hour_target      hour_target,
                           l_rvs_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_rvs_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                   title,
                           l_exm_date             last_date,
                           l_exm_nick_name        nick_name,
                           l_exm_desc_speciality  desc_speciality,
                           l_exm_date_target      date_target,
                           l_exm_hour_target      hour_target,
                           l_exm_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_exm_found = 'TRUE'
                    UNION ALL
                    SELECT NULL                   title,
                           l_asm_date             last_date,
                           l_asm_nick_name        nick_name,
                           l_asm_desc_speciality  desc_speciality,
                           l_asm_date_target      date_target,
                           l_asm_hour_target      hour_target,
                           l_asm_date_hour_target date_hour_target
                      FROM dual
                     WHERE l_asm_found = 'TRUE'
                     ORDER BY last_date DESC)
             WHERE rownum < 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_hist_ill_last_update',
                                              o_error);
        
            pk_types.open_my_cursor(o_last_update);
            RETURN FALSE;
    END get_summ_hist_ill_last_update;
    --
    /********************************************************************************************
    * Devolver para um episÛdio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2006/10/17
    * @alter                          2007/06/20
    **********************************************************************************************/
    FUNCTION get_summ_last_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_documentation';
        OPEN o_documentation FOR
            WITH ed_last_entries AS
             (SELECT /*+ materialize */
               t_ed.id_epis_documentation
                FROM (SELECT ed.id_epis_documentation,
                             row_number() over(PARTITION BY ed.id_episode ORDER BY ed.dt_creation_tstz DESC NULLS LAST) rn
                        FROM epis_documentation ed
                       WHERE ed.id_episode IN (SELECT /*+opt_estimate(table e rows=1)*/
                                                e.column_value
                                                 FROM TABLE(i_episode) e)
                         AND ed.id_doc_area = i_doc_area
                         AND ed.flg_status = pk_alert_constant.g_active) t_ed
               WHERE t_ed.rn = 1)
            -- outer select is done because outp summary page expects a desc_info field
            SELECT t.id_doc_component,
                   t.id_episode,
                   t.desc_component,
                   t.desc_element,
                   pk_string_utils.concat_if_exists(TRIM(t.desc_component),
                                                     CASE
                                                     -- Punctuation character at end of line
                                                         WHEN t.desc_element IS NULL THEN
                                                          NULL
                                                         WHEN instr('!,.:;?', substr(t.desc_element, -1)) = 0 THEN
                                                          t.desc_element || '.'
                                                         ELSE
                                                          t.desc_element
                                                     END,
                                                     ' ') desc_info,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      t.id_episode,
                                                      t.dt_last_update_tstz,
                                                      t.id_prof_last_update) signature
              FROM (SELECT dc.id_doc_component,
                           ed.id_episode,
                           pk_translation.get_translation(i_lang, dc.code_doc_component) || ': ' desc_component,
                           pk_string_utils.concat_element_list(CAST(MULTISET
                                                                    (SELECT pk_touch_option.get_epis_formatted_element(i_lang,
                                                                                                                       i_prof,
                                                                                                                       edd.id_epis_documentation_det) desc_element,
                                                                            CASE
                                                                                 WHEN de.separator IS NULL THEN
                                                                                  pk_touch_option.g_elem_separator_default
                                                                                 WHEN de.separator =
                                                                                      pk_touch_option.g_elem_separator_none THEN
                                                                                  NULL
                                                                                 ELSE
                                                                                  de.separator
                                                                             END delimiter
                                                                       FROM epis_documentation_det edd
                                                                      INNER JOIN doc_element de
                                                                         ON de.id_doc_element = edd.id_doc_element
                                                                      WHERE edd.id_epis_documentation =
                                                                            t_d.id_epis_documentation
                                                                        AND edd.id_documentation = d.id_documentation
                                                                      ORDER BY de.rank) AS t_coll_text_delimiter_tuple)) desc_element,
                           ed.id_prof_last_update,
                           ed.dt_last_update_tstz,
                           dtad.rank
                      FROM epis_documentation ed
                     INNER JOIN (SELECT DISTINCT edd.id_documentation, edd.id_epis_documentation
                                  FROM epis_documentation_det edd
                                 WHERE edd.id_epis_documentation IN
                                       (SELECT t.id_epis_documentation
                                          FROM ed_last_entries t)) t_d
                        ON t_d.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN documentation d
                        ON d.id_documentation = t_d.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON dtad.id_doc_template = ed.id_doc_template
                       AND dtad.id_doc_area = ed.id_doc_area
                       AND dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                     WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                          FROM ed_last_entries t)
                    
                    -- Additional notes / Free text entry
                    UNION ALL
                    SELECT NULL id_doc_component,
                           ed.id_episode,
                           CASE
                               WHEN ed.id_doc_template IS NULL THEN
                                NULL
                               ELSE
                                pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010') || ': '
                           END desc_component,
                           pk_string_utils.clob_to_sqlvarchar2(ed.notes) desc_element,
                           ed.id_prof_last_update,
                           ed.dt_last_update_tstz,
                           999 rank
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                          FROM ed_last_entries t)
                       AND coalesce(dbms_lob.getlength(ed.notes), 0) > 0
                     ORDER BY id_episode, rank) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_last_documentation',
                                              o_error);
            pk_types.open_my_cursor(o_documentation);
            RETURN FALSE;
    END get_summ_last_documentation;
    --
    /********************************************************************************************
    * Gets doc_template from a given value (clinical service, doc_area, etc). 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           episode id
    * @param i_patient           patient id
    * @param i_value             context id
    * @param i_flg_type          C - Complaint; I - Intervention; A - Appointment type; D - Doc area
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *    
    * @author                    Ana Matos
    * @version                   1.0
    * @since                     28-08-2007
    **********************************************************************************************/
    FUNCTION get_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_value        IN doc_template_context.id_context%TYPE,
        i_flg_type     IN doc_template_context.flg_type%TYPE,
        o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_clin_serv IS
            SELECT e.id_clinical_service
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        CURSOR c_patient_info IS
            SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age
              FROM patient p
             WHERE p.id_patient = i_patient;
        --
        l_id_clin_serv clinical_service.id_clinical_service%TYPE;
        l_gender       patient.gender%TYPE;
        l_age          patient.age%TYPE;
        o_cursor       pk_types.cursor_type;
    BEGIN
        g_error := 'GET CURSOR C_PATIENT_INFO';
        OPEN c_patient_info;
        FETCH c_patient_info
            INTO l_gender, l_age;
        CLOSE c_patient_info;
        --
        g_error := 'GET CLIN_SERV';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv;
        CLOSE c_clin_serv;
        --
        IF i_flg_type = g_flg_type_a
        THEN
            IF (l_id_clin_serv IS NOT NULL)
            THEN
                g_error := 'OPEN O_CURSOR PRF';
                OPEN o_cursor FOR
                    SELECT dtc.id_doc_template
                      FROM clinical_service cs, doc_template dt, doc_template_context dtc, prof_profile_template ppt
                     WHERE cs.id_clinical_service = l_id_clin_serv
                       AND cs.flg_available = pk_alert_constant.g_available
                       AND cs.id_clinical_service = dtc.id_context
                       AND dtc.flg_type = g_flg_type_a
                       AND dtc.id_software = i_prof.software
                       AND dtc.id_institution IN (0, i_prof.institution)
                          --filtar templates adequados ao paciente
                       AND dt.id_doc_template = dtc.id_doc_template
                       AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                       AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                       AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                       AND dt.flg_available = pk_alert_constant.g_available
                          --ler prefs gerais
                       AND ppt.id_profile_template = dtc.id_profile_template
                          --ler prefs pessoais
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                     ORDER BY dtc.id_institution DESC;
            ELSE
                g_error := 'NO ACTIVE CLIN_SERV IN EPISODE';
                RAISE g_exception;
            END IF;
        
        ELSIF i_flg_type = g_flg_type_d
        THEN
            g_error := 'OPEN O_CURSOR PRF';
            OPEN o_cursor FOR
                SELECT dtc.id_doc_template
                  FROM doc_area da, doc_template_context dtc, doc_template dt, prof_profile_template ppt
                 WHERE da.id_doc_area = i_value
                   AND da.id_doc_area = dtc.id_context
                   AND dtc.flg_type = g_flg_type_d
                   AND dtc.id_software = i_prof.software
                   AND dtc.id_institution IN (0, i_prof.institution)
                   AND dt.id_doc_template = dtc.id_doc_template
                   AND pk_patient.validate_pat_gender('F', dt.flg_gender) = 1
                   AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                   AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                   AND dt.flg_available = 'Y'
                   AND ppt.id_profile_template = dtc.id_profile_template
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                 ORDER BY dtc.id_institution DESC;
        END IF;
        --
        FETCH o_cursor
            INTO o_doc_template;
        CLOSE o_cursor;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_template',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_template;
    --
    /********************************************************************************************
    * Retorna TRUE se o clinical service È o default de obstetricia
    *
    * @param i_lang              language id
    * @param i_episode           episode id
    * @param o_flg_status        Y se È true, N se n„o
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rita Lopes
    * @version                   1.0
    * @since                     05-09-2007
    **********************************************************************************************/
    FUNCTION get_clin_service_status
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_clin_serv IS
            SELECT e.id_clinical_service
              FROM episode e, sys_config s
             WHERE e.id_episode = i_episode
               AND e.flg_status = g_active
               AND e.id_clinical_service = s.value
               AND s.id_sys_config = 'OBSTETRIC_HISTORY_DEFAULT';
        --    
        l_id_clin_serv clinical_service.id_clinical_service%TYPE;
    BEGIN
        g_error := 'OPEN C_CLIN_SERV';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv;
        g_found := c_clin_serv%NOTFOUND;
        CLOSE c_clin_serv;
        --
        IF g_found
        THEN
            o_flg_status := 'N';
        ELSE
            o_flg_status := 'Y';
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
                                              'get_clin_service_status',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_clin_service_status;
    --
    /********************************************************************************************
    * Devolver para um episÛdio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_past_hist_med          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/09/07
    **********************************************************************************************/
    FUNCTION get_summ_last_past_hist_med
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_pat           IN patient.id_patient%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_past_hist_med OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message_unknown sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T021');
    BEGIN
        g_error := 'OPEN o_past_hist_med';
        OPEN o_past_hist_med FOR
            SELECT e.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis) ||
                   -- ALERT-736 synonyms diagnosis
                    pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                               i_code               => d.code_icd,
                                               i_flg_other          => d.flg_other,
                                               i_flg_std_diag       => ad.flg_icd9) desc_past_hist,
                   -- desc
                   -- checks if diagnosis is null. if it is, it means it is an unclassified diagnosis (None or Unknown)
                   decode(phd.id_alert_diagnosis,
                          g_diag_none,
                          pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG', g_pat_hist_diag_none, i_lang),
                          decode(phd.id_alert_diagnosis,
                                 g_diag_unknown,
                                 pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                         g_pat_hist_diag_unknown,
                                                         i_lang),
                                 decode(phd.id_alert_diagnosis,
                                        pk_past_history.g_diag_non_remark,
                                        pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS_NO_DIAG',
                                                                pk_past_history.g_pat_hist_diag_non_remark,
                                                                i_lang),
                                        -- ALERT-736 synonyms diagnosis
                                        pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                    i_code               => d.code_icd,
                                                                    i_flg_other          => d.flg_other,
                                                                    i_flg_std_diag       => ad.flg_icd9) ||
                                         decode(phd.desc_pat_history_diagnosis,
                                                NULL,
                                                '',
                                                ' - ' || phd.desc_pat_history_diagnosis) || ' (' ||
                                        -- status
                                         pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) ||
                                        -- nature
                                         decode(pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE',
                                                                        decode(g_doc_area_past_surg,
                                                                               i_doc_area,
                                                                               phd.flg_compl,
                                                                               phd.flg_nature),
                                                                        i_lang),
                                                NULL,
                                                NULL,
                                                ', ') || pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE',
                                                                                 decode(g_doc_area_past_surg,
                                                                                        i_doc_area,
                                                                                        phd.flg_compl,
                                                                                        phd.flg_nature),
                                                                                 i_lang) ||
                                         pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                                                 i_prof      => i_prof,
                                                                                 i_date      => phd.dt_diagnosed,
                                                                                 i_precision => phd.dt_diagnosed_precision) || ')'))) desc_past_hist_all,
                   phd.flg_status,
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_STATUS', phd.flg_status, i_lang) desc_status,
                   decode(g_doc_area_past_surg, i_doc_area, phd.flg_compl, phd.flg_nature),
                   pk_sysdomain.get_domain('PAT_PROBLEM.FLG_NATURE',
                                           decode(g_doc_area_past_surg, i_doc_area, phd.flg_compl, phd.flg_nature),
                                           i_lang) desc_nature,
                   -- check if it is the current episode
                   decode(e.id_episode, i_episode, g_current_episode_yes, g_current_episode_no) flg_current_episode,
                   -- check if the diagnosis was registered by the current professional
                   decode(p.id_professional, i_prof.id, g_current_professional_yes, g_current_professional_no) flg_current_professional,
                   -- check if it is the last record
                   decode(phd_max.max_dt_pat_history_diagnosis,
                          phd.dt_pat_history_diagnosis_tstz,
                          g_last_record_yes,
                          g_last_record_no) flg_last_record,
                   -- check if it is the last record by that professional
                   decode(phd_max_prof.max_dt_pat_history_diagnosis,
                          phd.dt_pat_history_diagnosis_tstz,
                          g_last_record_yes,
                          g_last_record_no) flg_last_record_prof,
                   phd.id_alert_diagnosis id_diagnosis,
                   decode(phd.id_pat_history_diagnosis_new, NULL, g_outdated_no, g_outdated_yes) flg_outdated,
                   decode(phd.flg_status, g_pat_hist_diag_canceled, g_canceled_yes, g_canceled_no) flg_canceled,
                   NULL day_begin,
                   NULL month_begin,
                   NULL year_begin,
                   pk_past_history.get_partial_date_format(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_date      => phd.dt_diagnosed,
                                                           i_precision => phd.dt_diagnosed_precision) onset,
                   pk_date_utils.date_char_tsz(i_lang,
                                               phd.dt_pat_history_diagnosis_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_register_chr,
                   decode(phd.flg_status,
                          g_pat_hist_diag_canceled,
                          pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_pat_hist_diag_canceled, i_lang),
                          decode(phd.id_pat_history_diagnosis_new,
                                 NULL,
                                 NULL,
                                 pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', g_outdated, i_lang))) desc_flg_status,
                   pk_date_utils.to_char_insttimezone(i_prof, phd.dt_pat_history_diagnosis_tstz, 'YYYYMMDDHH24MISS') dt_register_order
              FROM pat_history_diagnosis phd,
                   professional          p,
                   diagnosis             d,
                   episode               e,
                   --visit v,
                   --visit vis,
                   episode epis,
                   alert_diagnosis ad,
                   (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, /*visit v, visit vis,*/ episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND e.id_visit = v.id_visit
                          --AND vis.id_visit = epis.id_visit
                          --AND v.id_patient = vis.id_patient) phd_max,
                       AND epis.id_patient = e.id_patient) phd_max,
                   (SELECT MAX(dt_pat_history_diagnosis_tstz) max_dt_pat_history_diagnosis
                      FROM pat_history_diagnosis phd, episode e, /*visit v, visit vis,*/ episode epis
                     WHERE phd.id_episode = e.id_episode
                       AND epis.id_episode = i_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND e.id_visit = v.id_visit
                          --AND vis.id_visit = epis.id_visit
                          --AND v.id_patient = vis.id_patient
                       AND epis.id_patient = e.id_patient
                       AND phd.id_professional = i_prof.id) phd_max_prof
             WHERE phd.id_professional = p.id_professional
               AND phd.id_episode = e.id_episode
               AND epis.id_episode = i_episode
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --AND e.id_visit = v.id_visit
                  --AND vis.id_visit = epis.id_visit
                  --AND v.id_patient = vis.id_patient
               AND e.id_patient = epis.id_patient
                  --
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND ad.id_diagnosis = d.id_diagnosis(+)
               AND (ad.flg_type = g_alert_diag_type_med OR
                   phd.id_alert_diagnosis IN (g_diag_unknown, g_diag_none, pk_past_history.g_diag_non_remark))
               AND phd.flg_type NOT IN (g_alert_diag_type_surg, g_alert_diag_type_cong_anom)
             ORDER BY decode(e.id_episode, i_episode, g_current_episode_yes, g_current_episode_no) DESC,
                      phd.dt_pat_history_diagnosis_tstz DESC,
                      desc_past_hist ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_last_past_hist_med',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_summ_last_past_hist_med;

    /********************************************************************************************
    * Concatenar as qualificaÁıes / quantificaÁıes associadas a um elemento
    *
    * @param i_lang                   The language ID
    * @param i_epis_document_det      the episode documentation detail
    *                        
    * @return                         description
    * 
    * @author                         EmÌlia Taborda e Jo„o Eiras
    * @version                        1.0
    * @since                          2007/09/14
    *
    * This function will be deprecated and should use pk_touch_option functions:
    * - get_epis_doc_quantification()
    * - get_epis_doc_qualification()
    * - get_epis_doc_quantifier()
    *
    * Referenced by: pk_ehr_common;pk_progress_notes;pk_summary_page;pk_touch_option;pk_wtl_pbl_core
    **********************************************************************************************/
    FUNCTION get_epis_doc_qualif
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
    BEGIN
        SELECT decode(qnt.desc_quantif || qll.desc_qualif,
                      NULL,
                      NULL,
                      ' (' ||
                      nvl2(qnt.desc_quantif,
                           decode(qll.desc_qualif, NULL, qnt.desc_quantif, qnt.desc_quantif || ': ' || qll.desc_qualif),
                           qll.desc_qualif) || ')')
          INTO l_result
          FROM (SELECT (SELECT pk_translation.get_translation(i_lang,
                                                              'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_CLOSE.' ||
                                                              edq.id_doc_element_qualif)
                          FROM epis_documentation_qualif edq, doc_element_qualif deq
                         WHERE edq.id_epis_documentation_det = i_epis_document_det
                           AND deq.id_doc_element_qualif = edq.id_doc_element_qualif
                           AND deq.id_doc_quantification IS NOT NULL
                           AND deq.id_doc_qualification IS NULL) desc_quantif
                  FROM dual) qnt,
               (SELECT pk_utils.concatenate_list(CURSOR (SELECT pk_translation.get_translation(i_lang,
                                                                                        'DOC_ELEMENT_QUALIF.CODE_DOC_ELEM_QUALIF_CLOSE.' ||
                                                                                        edq.id_doc_element_qualif)
                                                    FROM epis_documentation_qualif edq, doc_element_qualif deq
                                                   WHERE edq.id_epis_documentation_det = i_epis_document_det
                                                     AND deq.id_doc_element_qualif = edq.id_doc_element_qualif
                                                     AND deq.id_doc_qualification IS NOT NULL),
                                                 ', ') desc_qualif
                  FROM dual) qll;
        RETURN l_result;
    END;
    --
    /********************************************************************************************
    * Depending on the context defined on the doc_area_inst_soft, returns if the obstetric history
    * should do a shortcut for the woman health deepnav. If the context corresponds to the clinical service,
    * it returns 'Y' if there is a parameterization on the sys_config. Else, it returns if it is in the 
    * context of an episode.
    *
    * @param i_lang              language id
    * @param i_episode           episode id
    * @param i_doc_area          doc area id
    * @param o_flg_status        if it should call the shortcut for the obs history (Y/N)
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rui de Sousa Neves
    * @version                   1.0
    * @since                     28-09-2007
    **********************************************************************************************/
    FUNCTION get_context_status
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_doc_area   IN doc_area.id_doc_area%TYPE,
        i_prof       IN profissional,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sps_param IS
            SELECT flg_type
              FROM doc_area_inst_soft dais
             WHERE (dais.id_institution = decode((SELECT COUNT(0)
                                                   FROM doc_area_inst_soft dais2
                                                  WHERE dais2.id_doc_area = dais.id_doc_area
                                                    AND dais2.id_institution = i_prof.institution
                                                    AND dais2.id_software = i_prof.software),
                                                 0,
                                                 0,
                                                 i_prof.institution) OR dais.id_institution IS NULL)
               AND (dais.id_software IN (0, i_prof.software) OR dais.id_software IS NULL);
    
        l_sps_param  doc_area_inst_soft.flg_type%TYPE;
        l_flg_status VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'OPEN c_sps_param';
        OPEN c_sps_param;
        FETCH c_sps_param
            INTO l_sps_param;
        g_found := c_sps_param%NOTFOUND;
        CLOSE c_sps_param;
    
        g_error := 'IF TYPE OF APPOINTMENT';
        IF l_sps_param = 'A'
        THEN
        
            g_error := 'CALL PK_SUMMARY_PAGE.GET_CLIN_SERVICE_STATUS';
            IF NOT pk_summary_page.get_clin_service_status(i_lang       => i_lang,
                                                           i_episode    => i_episode,
                                                           o_flg_status => l_flg_status,
                                                           o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSIF i_episode IS NULL
        THEN
            g_error      := 'CHECK IF EPISODE IS NULL';
            l_flg_status := 'N';
        ELSE
            g_error      := 'CHECK IF EPISODE IS NOT NULL';
            l_flg_status := 'Y';
        END IF;
    
        o_flg_status := l_flg_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_context_status',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_context_status;

    /********************************************************************************************
    * Devolver para um episÛdio de documentation os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_epis_documentation     the episode documentation ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode documentation
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/10/01
    **********************************************************************************************/
    FUNCTION get_summ_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_documentation      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_documentation';
        OPEN o_documentation FOR
        -- outer select is done because outp summary page expects a desc_info field
            SELECT t.id_doc_component,
                   t.id_episode,
                   t.desc_component,
                   t.desc_element,
                   to_clob(TRIM(t.desc_component)) || ' ' || to_clob(t.desc_element) || '.' AS desc_info
              FROM (SELECT dc.id_doc_component,
                           ed.id_episode,
                           pk_translation.get_translation(i_lang, dc.code_doc_component) || ': ' desc_component,
                           to_clob(pk_touch_option.concat_element_list(CURSOR
                                                                       (SELECT pk_touch_option.get_epis_formatted_element(i_lang,
                                                                                                                          i_prof,
                                                                                                                          edd.id_epis_documentation_det) desc_element,
                                                                               CASE
                                                                                    WHEN de.separator IS NULL THEN
                                                                                     pk_touch_option.g_elem_separator_default
                                                                                    WHEN de.separator =
                                                                                         pk_touch_option.g_elem_separator_none THEN
                                                                                     NULL
                                                                                    ELSE
                                                                                     de.separator
                                                                                END delimiter
                                                                          FROM epis_documentation_det edd
                                                                         INNER JOIN doc_element de
                                                                            ON de.id_doc_element = edd.id_doc_element
                                                                         WHERE edd.id_epis_documentation =
                                                                               t_d.id_epis_documentation
                                                                           AND edd.id_documentation = d.id_documentation
                                                                         ORDER BY de.rank))) desc_element,
                           dtad.rank
                      FROM epis_documentation ed
                     INNER JOIN (SELECT DISTINCT edd.id_documentation, edd.id_epis_documentation
                                  FROM epis_documentation_det edd) t_d
                        ON t_d.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN documentation d
                        ON d.id_documentation = t_d.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON dtad.id_doc_template = ed.id_doc_template
                       AND dtad.id_doc_area = ed.id_doc_area
                       AND dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                     WHERE ed.id_epis_documentation = i_epis_documentation
                       AND ed.id_doc_area = i_doc_area
                       AND ed.flg_status = pk_alert_constant.g_active
                    -- Additional notes / Free text entry
                    UNION ALL
                    SELECT NULL id_doc_component,
                           ed.id_episode,
                           CASE
                               WHEN ed.id_doc_template IS NULL THEN
                                NULL
                               ELSE
                                pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010') || ': '
                           END desc_component,
                           ed.notes desc_element,
                           999 rank
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation = i_epis_documentation
                       AND ed.id_doc_area = i_doc_area
                       AND ed.flg_status = pk_alert_constant.g_active
                       AND coalesce(dbms_lob.getlength(ed.notes), 0) > 0
                     ORDER BY rank) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_last_doc_area',
                                              o_error);
            pk_types.open_my_cursor(o_documentation);
            RETURN FALSE;
    END get_summ_last_doc_area;
    --
    /********************************************************************************************
    * Devolve os ˙ltimos registos da histÛria familiar, social e cir˙rgica de um paciente 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                the patient ID
    * @param o_last_hist_all          Cursor containing the last information of past history family, social, surgical
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         EmÌlia Taborda
    * @version                        1.0
    * @since                          2007/10/02
    **********************************************************************************************/
    FUNCTION get_summ_last_hist_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        o_last_hist_all OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_documentation';
        OPEN o_last_hist_all FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M021') || ' ' || notes desc_element
              FROM (SELECT pk_string_utils. clob_to_sqlvarchar2(ed.notes) notes, ed.dt_creation_tstz
                      FROM epis_documentation ed, episode epis --, visit v
                     WHERE ed.id_doc_area = g_doc_area_past_fam
                       AND epis.id_episode = ed.id_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND epis.id_visit = v.id_visit
                          --AND v.id_patient = i_patient
                       AND epis.id_patient = i_patient
                          --
                       AND ed.flg_status = g_active
                    UNION ALL
                    SELECT ph.notes, ph.dt_pat_fam_soc_hist_tstz
                      FROM pat_fam_soc_hist ph
                     WHERE ph.flg_type = g_alert_diag_type_fam
                       AND ph.id_institution = i_prof.institution
                       AND ph.id_patient = i_patient
                     ORDER BY 2 DESC)
             WHERE rownum < 2
               AND notes IS NOT NULL
            UNION ALL
            SELECT pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M022') || ' ' || notes desc_element
              FROM (SELECT pk_string_utils.clob_to_sqlvarchar2(ed.notes) notes, ed.dt_creation_tstz
                      FROM epis_documentation ed, episode epis --, visit v
                     WHERE ed.id_doc_area = g_doc_area_past_soc
                       AND epis.id_episode = ed.id_episode
                          -- <DENORM_EPISODE_JOSE_BRITO>
                          --AND epis.id_visit = v.id_visit
                          --AND v.id_patient = i_patient
                       AND epis.id_patient = i_patient
                          --
                       AND ed.flg_status = g_active
                    UNION ALL
                    SELECT ph.notes, ph.dt_pat_fam_soc_hist_tstz
                      FROM pat_fam_soc_hist ph
                     WHERE ph.flg_type = g_alert_diag_type_soc
                       AND ph.id_institution = i_prof.institution
                       AND ph.id_patient = i_patient
                     ORDER BY 2 DESC)
             WHERE rownum < 2
               AND notes IS NOT NULL
            UNION ALL
            SELECT pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M025') || ' ' ||
                   nvl2(desc_past_hist,
                        decode(notes, NULL, desc_past_hist, desc_past_hist || chr(13) || notes),
                        desc_past_hist) desc_element
              FROM (SELECT phd.dt_pat_history_diagnosis_tstz,
                           phd.notes,
                           decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis) ||
                           -- ALERT-736 synonyms diagnosis
                            pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                       i_code               => d.code_icd,
                                                       i_flg_other          => d.flg_other,
                                                       i_flg_std_diag       => ad.flg_icd9) desc_past_hist
                      FROM pat_history_diagnosis phd, diagnosis d, alert_diagnosis ad
                     WHERE phd.id_patient = i_patient
                       AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                       AND ad.id_diagnosis = d.id_diagnosis(+)
                       AND (ad.flg_type = g_alert_diag_type_surg OR
                           phd.id_alert_diagnosis IN (g_diag_unknown, g_diag_none, pk_past_history.g_diag_non_remark))
                       AND phd.flg_type NOT IN (g_alert_diag_type_med, g_alert_diag_type_cong_anom)
                     ORDER BY 2 DESC)
             WHERE rownum < 2;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_last_hist_all',
                                              o_error);
            pk_types.open_my_cursor(o_last_hist_all);
            RETURN FALSE;
    END get_summ_last_hist_all;
    --
    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para um paciente
    *
    * @param i_lang                   Professional preferred language
    * @param i_prof                   Professional identification and its context (institution and software)
    * @param i_episode                Current episode ID
    * @param i_doc_area               Documentation area ID
    * @param o_doc_area_register      Cursor containing information about registers (professional, record date, status, etc.)
    * @param o_doc_area_val           Cursor containing information about data values saved in registers
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2008/05/19
    *
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value';
        l_order_by     sys_config.value%TYPE;
        l_patient      patient.id_patient%TYPE;
        l_record_count NUMBER;
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => l_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'Get patient ID';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => l_function_name);
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        g_error := 'CALL pk_touch_option.get_doc_area_value';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_episode,
                                                  i_scope              => l_patient,
                                                  i_scope_type         => pk_alert_constant.g_scope_type_patient,
                                                  i_order              => l_order_by,
                                                  i_paging             => pk_alert_constant.g_no,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => l_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              l_function_name,
                                              o_error);
            /* Open out cursors */
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_summ_page_doc_area_pat;
    /********************************************************************************************
    * Devolve toda a informaÁ„o registada na Documentation para um paciente - Para uso nos reports
    *
    * @param i_lang                   The language ID
    * @param i_prof_id                professional ID
    * @param i_prof_inst              institution ID
    * @param i_prof_sw                software ID
    * @param i_episode                the episode ID
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Spratley
    * @version                        2.4.3
    * @since                          2008/08/11
    *                                 Retrieves data from multichoice elements
    * @Deprecated : get_doc_area_value should be used instead.
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pat_rep
    (
        i_lang               IN language.id_language%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_prof_inst          IN institution.id_institution%TYPE,
        i_prof_sw            IN software.id_software%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional;
    BEGIN
    
        l_prof := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
        IF NOT get_summ_page_doc_area_pat(i_lang,
                                          l_prof,
                                          i_episode,
                                          i_doc_area,
                                          o_doc_area_register,
                                          o_doc_area_val,
                                          o_template_layouts,
                                          o_doc_area_component,
                                          o_error)
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
                                              'get_summ_page_doc_area_pat_rep',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_summ_page_doc_area_pat_rep;

    /**
    * Returns a set of records done in a touch-option area based on scope criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor containing information about registers (professional, record date, status, etc.)
    * @param   o_doc_area_val       Cursor containing information about data values saved in registers
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   11/16/2010
    */
    FUNCTION get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value';
        l_order_by sys_config.value%TYPE;
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'CALL pk_touch_option.get_doc_area_value';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => i_doc_area,
                                                  i_current_episode    => i_current_episode,
                                                  i_scope              => i_scope,
                                                  i_scope_type         => i_scope_type,
                                                  i_order              => l_order_by,
                                                  i_paging             => i_paging,
                                                  i_start_record       => i_start_record,
                                                  i_num_records        => i_num_records,
                                                  o_doc_area_register  => o_doc_area_register,
                                                  o_doc_area_val       => o_doc_area_val,
                                                  o_template_layouts   => o_template_layouts,
                                                  o_doc_area_component => o_doc_area_component,
                                                  o_record_count       => o_record_count,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              l_function_name,
                                              o_error);
            /* Open out cursors */
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_doc_area_value;

    /**************************************************************************
    * Get doc area name        
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_software               Software ID          
    * @param i_doc_area               Doc area ID
    * @param i_use_abbrev_name        Return the abbreviated name or full name. Default: full name
    *
    * @value i_use_abbrev_name       {*} 'Y'  Yes {*} 'N' No
    * return doc area name         
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                         
    * @since                          2011/02/16                                       
    **************************************************************************/
    FUNCTION get_doc_area_name
    (
        i_lang            IN language.id_language%TYPE,
        i_software        IN software.id_software%TYPE,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_use_abbrev_name IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 result_cache IS
        l_doc_area_name pk_translation.t_desc_translation;
    BEGIN
        SELECT coalesce(pk_translation.get_translation(i_lang, t.code_doc_area_soft),
                        pk_translation.get_translation(i_lang, t.code_doc_area))
          INTO l_doc_area_name
          FROM (SELECT CASE i_use_abbrev_name
                           WHEN pk_alert_constant.g_yes THEN
                            das.code_abbreviation
                           ELSE
                            das.code_doc_area
                       END code_doc_area_soft,
                       CASE i_use_abbrev_name
                           WHEN pk_alert_constant.g_yes THEN
                            da.code_abbreviation
                           ELSE
                            da.code_doc_area
                       END code_doc_area,
                       rank() over(PARTITION BY das.id_doc_area ORDER BY das.id_software DESC) rank_level
                  FROM doc_area da
                  LEFT OUTER JOIN doc_area_software das
                    ON da.id_doc_area = das.id_doc_area
                   AND das.id_software IN (0, i_software)
                 WHERE da.id_doc_area = i_doc_area) t
         WHERE t.rank_level = 1;
        RETURN l_doc_area_name;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_area_name;

    /**************************************************************************
    * Get doc area name        
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Professional identification and its context (institution and software)
    * @param i_doc_area               Doc area ID
    * @param i_use_abbrev_name        Return the abbreviated name or full name. Default: full name
    *
    * @value i_use_abbrev_name       {*} 'Y'  Yes {*} 'N' No
    * return doc area name         
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                         
    * @since                          2011/02/16                                       
    **************************************************************************/
    FUNCTION get_doc_area_name
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_use_abbrev_name IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN get_doc_area_name(i_lang            => i_lang,
                                 i_software        => i_prof.software,
                                 i_doc_area        => i_doc_area,
                                 i_use_abbrev_name => i_use_abbrev_name);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_area_name;

    /********************************************************************************************
    * Gets the flg_no_change according to a doc_area:
    * if does not exists a summary_page_section to the given id_doc_area returns 'Y'
    * if there is some active flg_no_changes in some summary page access of the given doc_area
    * return 'Y'. Otherwise return 'N'
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)    
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1
    * @since                          15-Apr-2011
    **********************************************************************************************/
    FUNCTION get_flg_no_changes_by_doc_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2 IS
        l_profile_template     profile_template.id_profile_template%TYPE;
        l_count_flg_no_changes PLS_INTEGER := 0;
        l_flg_no_changes_list  table_varchar := table_varchar();
        l_flg_no_changes       summary_page_access.flg_no_changes%TYPE := pk_alert_constant.g_yes;
        l_error                t_error_out;
    BEGIN
        g_error := 'GET ID_PROFILE_TEMPLATE';
        pk_alertlog.log_debug(g_error);
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        --if does not exists a summary_page_section to the given id_doc_area
        --return 'Y'         
        BEGIN
            g_error := 'GET SUMMARY PAGE ACCESS FLG_NO_CHANGE. id_doc_area: ' || i_id_doc_area;
            pk_alertlog.log_debug(g_error);
            SELECT spa.flg_no_changes
              BULK COLLECT
              INTO l_flg_no_changes_list
              FROM summary_page_section sps
             INNER JOIN summary_page_access spa
                ON sps.id_summary_page_section = spa.id_summary_page_section
             INNER JOIN doc_area da
                ON sps.id_doc_area = da.id_doc_area
             WHERE spa.id_profile_template = l_profile_template
               AND da.id_doc_area = i_id_doc_area;
        
            IF (l_flg_no_changes_list IS NOT NULL AND l_flg_no_changes_list.exists(1))
            THEN
                g_error := 'COUNT ACTIVE FLG_NO_CHANGE';
                pk_alertlog.log_debug(g_error);
                SELECT COUNT(1)
                  INTO l_count_flg_no_changes
                  FROM TABLE(l_flg_no_changes_list) t
                 WHERE t.column_value = pk_alert_constant.g_yes;
            
                --if there is some active flg_no_changes in some summary page access of the given doc_area
                --return 'Y'. Otherwise return 'N'
                IF (l_count_flg_no_changes > 0)
                THEN
                    l_flg_no_changes := pk_alert_constant.g_yes;
                ELSE
                    l_flg_no_changes := pk_alert_constant.g_no;
                END IF;
            
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_flg_no_changes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_flg_no_changes_by_doc_area',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END get_flg_no_changes_by_doc_area;

    /********************************************************************************************
    * Checks if this professional has a way to register a complaint other than using "History of Present Illness" area
    * If he has other screens to do it the application can automatically enter create mode for "History of Present Illness".
    * If there isn't another area with this screen the application must remain on the summary page and not enter the HPI creation screen by default
    * 
    *
    * @param   i_lang                   The language ID
    * @param   i_prof                   Object (professional ID, institution ID, software ID)    
    *                
    * @param   o_can_create_hpi         Indicates if the professional should enter create mode by default in the HPI area - Values: Y/N
    *
    * @return  True or False on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.6
    * @since                          23-Dez-2011
    **********************************************************************************************/
    FUNCTION get_prof_complaint_screens
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_can_create_hpi OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_profile_template profile_template.id_profile_template%TYPE;
        l_error            t_error_out;
        l_count            NUMBER;
    BEGIN
        g_error := 'GET ID_PROFILE_TEMPLATE';
        pk_alertlog.log_debug(g_error);
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        o_can_create_hpi   := pk_alert_constant.get_yes;
    
        --Check if there are active screens where the user can register a complaint
        BEGIN
            g_error := 'GET PROFILE COMPLAINTS, PROFILE: ' || l_profile_template;
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(1)
              INTO l_count
              FROM profile_templ_access pta
             WHERE (pta.id_profile_template = l_profile_template OR
                   (pta.id_profile_template =
                   (SELECT pt.id_parent
                        FROM profile_template pt
                       WHERE pt.id_profile_template = l_profile_template)))
               AND pta.flg_add_remove = pk_access.g_flg_type_add
               AND pta.id_sys_button_prop IN
                   (SELECT sbp.id_sys_button_prop
                      FROM sys_button_prop sbp
                     WHERE sbp.screen_name IN ('ChiefComplaintSummary.swf', 'ComplaintDoctorSummary.swf')
                       AND sbp.flg_visible = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 0
                              FROM profile_templ_access p
                             WHERE p.id_profile_template = l_profile_template
                               AND p.id_sys_button_prop = sbp.id_sys_button_prop
                               AND p.flg_add_remove = pk_access.g_flg_type_remove));
        
            IF l_count = 0
            THEN
                o_can_create_hpi := pk_alert_constant.get_no;
            ELSE
                o_can_create_hpi := pk_alert_constant.get_yes;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                o_can_create_hpi := pk_alert_constant.get_no;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_complaint_screens',
                                              l_error);
            RETURN FALSE;
    END get_prof_complaint_screens;

    /*
    * Checks if a doc_area belongs to a summary page
    *
    * @param     i_lang                       Language id
    * @param     i_prof                       Professional object identifier
    * @param     i_id_doc_area                Documentation Area identifier
    * @param     i_id_summary_page            Summary Page identifier
    
    * @return                                 'Y' - doc area belongs to summary page, 'N' - otherwise No
    *
    * @author                                 AntÛnio Neto
    * @version                                v2.6.2
    * @since                                  24-Apr-2012
    */
    FUNCTION is_doc_area_in_summary_page
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        i_id_summary_page IN summary_page.id_summary_page%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(1 CHAR);
    BEGIN
    
        g_error := 'CHECK if id_doc_area: ' || i_id_doc_area || ' IN id_summary_page: ' || i_id_summary_page;
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'IS_DOC_AREA_IN_SUMMARY_PAGE');
        BEGIN
            SELECT g_yes
              INTO l_ret
              FROM summary_page_section sps
             WHERE sps.id_doc_area = i_id_doc_area
               AND sps.id_summary_page = i_id_summary_page;
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := g_no;
        END;
    
        RETURN l_ret;
    END is_doc_area_in_summary_page;

    /********************************************************************************************
    * Returns the section within a summary page associated to a doc_area
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_summary_page        Summary page ID
    * @param i_id_doc_area            Doc area ID
    * @param o_section                Cursor containing the section info                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.3.5
    * @since                          29-Mai-2013
    **********************************************************************************************/
    FUNCTION get_summary_page_section
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        o_section         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SECTION. i_id_summary_page: ' || i_id_summary_page || ' i_id_doc_area: ' || i_id_doc_area;
        pk_alertlog.log_debug(g_error);
        OPEN o_section FOR
            SELECT sps.id_doc_area doc_area,
                   sps.screen_name,
                   sps.screen_name_after_save,
                   da.intern_name_sample_text_type,
                   sps.screen_name_free_text,
                   da.flg_score
              FROM summary_page sp
             INNER JOIN summary_page_section sps
                ON sp.id_summary_page = sps.id_summary_page
             INNER JOIN doc_area da
                ON sps.id_doc_area = da.id_doc_area
             WHERE sp.id_summary_page = i_id_summary_page
               AND sps.id_doc_area = i_id_doc_area;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_PAGE_SECTION',
                                              o_error);
            open_my_cursor(o_section);
            RETURN FALSE;
    END get_summary_page_section;

    /********************************************************************************************
    * Devolver para um episÛdio os componentes e seus respectivos elementos. 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                the episode ID
    * @param i_doc_area               Array with the doc area ID
    * @param o_documentation          Cursor containing the components and the elements for the episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexander Camilo
    * @version                        1.0
    * @since                          2018/01/30
    * @alter                          2018/01/30
    **********************************************************************************************/
    FUNCTION get_summ_all_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN o_documentation';
        OPEN o_documentation FOR
            WITH ed_last_entries AS
             (SELECT /*+ materialize */
               t_ed.id_epis_documentation
                FROM (SELECT ed.id_epis_documentation
                        FROM epis_documentation ed
                       WHERE ed.id_episode IN (SELECT /*+opt_estimate(table e rows=1)*/
                                                e.column_value
                                                 FROM TABLE(i_episode) e)
                         AND ed.id_doc_area = i_doc_area
                         AND ed.flg_status = pk_alert_constant.g_active) t_ed)
            -- outer select is done because outp summary page expects a desc_info field
            SELECT pk_string_utils.concat_if_exists(TRIM(t.desc_component),
                                                     CASE
                                                     -- Punctuation character at end of line
                                                         WHEN t.desc_element IS NULL THEN
                                                          NULL
                                                         WHEN instr('!,.:;?', substr(t.desc_element, -1)) = 0 THEN
                                                          t.desc_element || '.'
                                                         ELSE
                                                          t.desc_element
                                                     END,
                                                     ' ') desc_info
            
              FROM (SELECT dc.id_doc_component,
                           ed.id_epis_documentation,
                           ed.id_episode,
                           pk_translation.get_translation(i_lang, dc.code_doc_component) || ': ' desc_component,
                           pk_string_utils.concat_element_list(CAST(MULTISET
                                                                    (SELECT pk_touch_option.get_epis_formatted_element(i_lang,
                                                                                                                       i_prof,
                                                                                                                       edd.id_epis_documentation_det) desc_element,
                                                                            CASE
                                                                                 WHEN de.separator IS NULL THEN
                                                                                  pk_touch_option.g_elem_separator_default
                                                                                 WHEN de.separator =
                                                                                      pk_touch_option.g_elem_separator_none THEN
                                                                                  NULL
                                                                                 ELSE
                                                                                  de.separator
                                                                             END delimiter
                                                                       FROM epis_documentation_det edd
                                                                      INNER JOIN doc_element de
                                                                         ON de.id_doc_element = edd.id_doc_element
                                                                      WHERE edd.id_epis_documentation =
                                                                            t_d.id_epis_documentation
                                                                        AND edd.id_documentation = d.id_documentation
                                                                      ORDER BY de.rank) AS t_coll_text_delimiter_tuple)) desc_element,
                           dtad.rank
                      FROM epis_documentation ed
                     INNER JOIN (SELECT DISTINCT edd.id_documentation, edd.id_epis_documentation
                                  FROM epis_documentation_det edd
                                 WHERE edd.id_epis_documentation IN
                                       (SELECT t.id_epis_documentation
                                          FROM ed_last_entries t)) t_d
                        ON t_d.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN documentation d
                        ON d.id_documentation = t_d.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON dtad.id_doc_template = ed.id_doc_template
                       AND dtad.id_doc_area = ed.id_doc_area
                       AND dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                     WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                          FROM ed_last_entries t)
                    
                    -- Additional notes / Free text entry
                    UNION ALL
                    SELECT NULL id_doc_component,
                           ed.id_epis_documentation,
                           ed.id_episode,
                           CASE
                               WHEN ed.id_doc_template IS NULL THEN
                                NULL
                               ELSE
                                pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010') || ': '
                           END desc_component,
                           pk_string_utils.clob_to_sqlvarchar2(ed.notes) desc_element,
                           999 rank
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                          FROM ed_last_entries t)
                       AND coalesce(dbms_lob.getlength(ed.notes), 0) > 0
                     ORDER BY id_episode, rank) t
             ORDER BY t.id_episode, t.id_epis_documentation, t.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_summ_all_documentation',
                                              o_error);
            pk_types.open_my_cursor(o_documentation);
            RETURN FALSE;
    END get_summ_all_documentation;

    FUNCTION get_flg_write_exception
    (
        i_lang               language.id_language%TYPE,
        i_prof               profissional,
        i_id_page_summary    summary_page_section.id_summary_page_section%TYPE,
        i_flg_write          VARCHAR2,
        i_flg_doc_area_avail VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_prof_sub_category VARCHAR2(1 CHAR) := pk_prof_utils.get_prof_sub_category(i_lang, i_prof);
        l_sys_config        VARCHAR2(1 CHAR) := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                        i_code_cf => 'USE_PROF_SURGICAL_CAT_SUMM_PAGE');
    
        l_section_anesth  table_number := table_number(157, 160, 166, 167, 172, 176);
        l_section_surgeon table_number := table_number(156, 171);
    
        l_ret VARCHAR2(1 CHAR) := i_flg_write;
    BEGIN
        IF i_flg_doc_area_avail = pk_alert_constant.g_no
        THEN
            l_ret := pk_alert_constant.g_no;
        
        ELSE
            IF l_sys_config = pk_alert_constant.g_yes
            THEN
            
                IF pk_utils.search_table_number(i_table => l_section_anesth, i_search => i_id_page_summary) > -1
                THEN
                    IF l_prof_sub_category = pk_alert_constant.g_na
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSIF pk_utils.search_table_number(i_table => l_section_surgeon, i_search => i_id_page_summary) > -1
                THEN
                    IF l_prof_sub_category != pk_alert_constant.g_na
                       OR l_prof_sub_category IS NULL
                    THEN
                        l_ret := pk_alert_constant.g_yes;
                    ELSE
                        l_ret := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_ret := i_flg_write;
                END IF;
            
            END IF;
        END IF;
        RETURN l_ret;
    END get_flg_write_exception;

    FUNCTION get_sections_with_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        o_cursor_cat      OUT pk_types.cursor_type,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_doc_categories   t_coll_categories;
        l_sections         t_coll_sections;
        l_age              patient.age%TYPE;
        l_gender           patient.gender%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_market           market.id_market%TYPE;
    BEGIN
    
        g_error := 'AGE AND GENDER CHECK'; -- RdSN
        SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age_in_years
          INTO l_gender, l_age
          FROM patient p
         WHERE p.id_patient = i_pat;
    
        g_error            := 'GET MARKET';
        l_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        g_error            := 'GET PROFILE_TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_sections := tf_sections(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_market           => l_market,
                                  i_gender           => l_gender,
                                  i_age              => l_age,
                                  i_profile_template => l_profile_template,
                                  i_id_summary_page  => i_id_summary_page,
                                  i_doc_areas_ex     => NULL,
                                  i_doc_areas_in     => NULL);
    
        l_doc_categories := tf_categories(i_lang => i_lang, i_prof => i_prof);
    
        /*OPEN o_cursor_cat FOR
        SELECT *
          FROM doc_category_area_inst_soft dcais
         LEFT JOIN TABLE(l_sections) s
            ON s.doc_area = dcais.id_doc_area
         LEFT JOIN TABLE(l_doc_categories) dc
            ON dc.id_doc_category = dcais.id_doc_category
         WHERE dcais.id_institution IN (i_prof.institution, 0)
           AND dcais.id_software IN (i_prof.software, 0);*/
    
        OPEN o_cursor_cat FOR
            SELECT s.translated_code  desc_area,
                   dc.translated_code desc_category,
                   s.doc_area,
                   dc.id_doc_category,
                   s.rank             rank_areas
              FROM TABLE(l_sections) s
              JOIN doc_category_area_inst_soft dcais
                ON dcais.id_doc_area = s.doc_area
               AND dcais.id_institution = i_prof.institution
               AND dcais.id_software = i_prof.software
              JOIN TABLE(l_doc_categories) dc
                ON dc.id_doc_category = dcais.id_doc_category
             WHERE s.flg_write = pk_alert_constant.g_yes
             ORDER BY dc.rank, desc_category;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_sections_with_category;

    FUNCTION tf_categories
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_coll_categories IS
        l_coll_categories t_coll_categories;
    BEGIN
    
        SELECT t_rec_doc_category(id_doc_category => t.id_doc_category, translated_code => trans, rank => rank)
          BULK COLLECT
          INTO l_coll_categories
          FROM (SELECT dc.id_doc_category id_doc_category,
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => dc.code_doc_category) trans,
                       rank
                  FROM doc_category_inst_soft dcis
                  JOIN doc_category dc
                    ON dc.id_doc_category = dcis.id_doc_category
                 WHERE dcis.id_institution = i_prof.institution
                   AND dcis.id_software = i_prof.software) t
         ORDER BY rank, trans;
    
        RETURN l_coll_categories;
    
    END tf_categories;

    FUNCTION tf_sections
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_market           IN NUMBER,
        i_gender           IN VARCHAR2,
        i_age              IN NUMBER,
        i_profile_template IN NUMBER,
        i_id_summary_page  IN NUMBER,
        i_doc_areas_ex     IN table_number,
        i_doc_areas_in     IN table_number
    ) RETURN t_coll_sections IS
        l_sections t_coll_sections;
    BEGIN
    
        SELECT t_rec_sections(translated_code              => tt.translated_code,
                              doc_area                     => tt.doc_area,
                              screen_name                  => tt.screen_name,
                              id_sys_shortcut              => tt.id_sys_shortcut,
                              flg_write                    => tt.flg_write,
                              flg_search                   => tt.flg_search,
                              flg_no_changes               => tt.flg_no_changes,
                              flg_template                 => tt.flg_template,
                              height                       => tt.height,
                              flg_type                     => tt.flg_type,
                              screen_name_after_save       => tt.screen_name_after_save,
                              subtitle                     => tt.subtitle,
                              intern_name_sample_text_type => tt.intern_name_sample_text_type,
                              flg_score                    => tt.flg_score,
                              screen_name_free_text        => tt.screen_name_free_text,
                              flg_scope_type               => tt.flg_scope_type,
                              flg_data_paging_enabled      => tt.flg_data_paging_enabled,
                              page_size                    => tt.page_size,
                              rank                         => tt.rank,
                              flg_create                   => NULL)
          BULK COLLECT
          INTO l_sections
          FROM (SELECT t.translated_code,
                        t.doc_area,
                        t.screen_name,
                        t.id_sys_shortcut,
                        t.flg_write,
                        t.flg_search,
                        t.flg_no_changes,
                        t.flg_template,
                        t.height,
                        t.flg_type,
                        t.screen_name_after_save,
                        t.subtitle,
                        t.intern_name_sample_text_type,
                        t.flg_score,
                        t.screen_name_free_text,
                        t.flg_scope_type,
                        t.flg_data_paging_enabled,
                        t.page_size,
                        t.rank
                   FROM (SELECT tt.*,
                                 translate(upper(tt.translated_code),
                                           '¡…Õ”⁄¿»Ã“Ÿ¬ Œ‘€√’«ƒÀœ÷‹— ',
                                           'AEIOUAEIOUAEIOUAOCAEIOUN%') AS sort_description
                            FROM (SELECT DISTINCT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                                                   sps.id_doc_area doc_area,
                                                   sps.screen_name,
                                                   sps.id_sys_shortcut,
                                                   get_flg_write_exception(i_lang,
                                                                           i_prof,
                                                                           sps.id_summary_page_section,
                                                                           spa.flg_write,
                                                                           da.flg_available) flg_write,
                                                   -- Disables advanced search button to select templates when the area doesn't use templates per episode
                                                (CASE
                                                     WHEN dais.flg_mode = g_touch_option
                                                          AND nvl(dais.flg_multiple, pk_alert_constant.g_no) =
                                                          pk_alert_constant.g_no
                                                          AND spa.flg_search = pk_alert_constant.g_yes THEN
                                                      pk_alert_constant.g_no
                                                     ELSE
                                                      nvl(spa.flg_search, pk_alert_constant.g_no)
                                                 END) flg_search,
                                                spa.flg_no_changes,
                                                decode(sps.id_doc_area, NULL, g_no, g_yes) flg_template,
                                                --nvl(spa.height, sps.height) height,
                                                sps.height height,
                                                dais.flg_type,
                                                sps.screen_name_after_save,
                                                pk_translation.get_translation(i_lang, sps.code_page_section_subtitle) subtitle,
                                                da.intern_name_sample_text_type,
                                                da.flg_score,
                                                sps.screen_name_free_text,
                                                dais.flg_scope_type,
                                                dais.flg_data_paging_enabled,
                                                dais.page_size,
                                                sps.rank
                                  FROM summary_page sp
                                 INNER JOIN summary_page_section sps
                                    ON sp.id_summary_page = sps.id_summary_page
                                 INNER JOIN summary_page_access spa
                                    ON sps.id_summary_page_section = spa.id_summary_page_section
                                 INNER JOIN doc_area da
                                    ON sps.id_doc_area = da.id_doc_area
                                 INNER JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, i_market, i_prof.software)) dais
                                    ON da.id_doc_area = dais.id_doc_area
                                 WHERE sp.id_summary_page = i_id_summary_page
                                   AND spa.id_profile_template = i_profile_template
                                   AND (da.gender IS NULL OR da.gender = i_gender OR i_gender = 'I')
                                   AND (da.age_min IS NULL OR da.age_min <= i_age OR i_age IS NULL)
                                   AND (da.age_max IS NULL OR da.age_max >= i_age OR i_age IS NULL)
                                   AND (da.id_doc_area MEMBER OF(i_doc_areas_in) OR i_doc_areas_in IS NULL)
                                   AND (da.id_doc_area NOT MEMBER OF(i_doc_areas_ex) OR i_doc_areas_ex IS NULL)) tt) t
                 ORDER BY t.rank, t.sort_description) tt;
    
        RETURN l_sections;
    
    END tf_sections;

    FUNCTION tf_categories_permission
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN t_coll_categories IS
        l_doc_categories   t_coll_categories;
        l_sections         t_coll_sections;
        l_age              patient.age%TYPE;
        l_gender           patient.gender%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_market           market.id_market%TYPE;
        l_coll_categories  t_coll_categories;
    BEGIN
    
        g_error := 'AGE AND GENDER CHECK'; -- RdSN
        SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age_in_years
          INTO l_gender, l_age
          FROM patient p
         WHERE p.id_patient = i_pat;
    
        g_error            := 'GET MARKET';
        l_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        g_error            := 'GET PROFILE_TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_sections := tf_sections(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_market           => l_market,
                                  i_gender           => l_gender,
                                  i_age              => l_age,
                                  i_profile_template => l_profile_template,
                                  i_id_summary_page  => 34,
                                  i_doc_areas_ex     => NULL,
                                  i_doc_areas_in     => NULL);
    
        l_doc_categories := tf_categories(i_lang => i_lang, i_prof => i_prof);
    
        /*  SELECT t_rec_doc_category(id_doc_category => dc.id_doc_category, translated_code => dc.translated_code,rank => dc.rank)
          BULK COLLECT
          INTO l_coll_categories
          FROM TABLE(l_sections) s
          JOIN doc_category_area_inst_soft dcais
            ON dcais.id_doc_area = s.doc_area
           AND dcais.id_institution = i_prof.institution
           AND dcais.id_software = i_prof.software
          JOIN TABLE(l_doc_categories) dc
            ON dc.id_doc_category = dcais.id_doc_category
         WHERE s.flg_write = pk_alert_constant.g_yes
        ORDER BY dc.rank, dc.translated_code;*/
    
        SELECT t_rec_doc_category(id_doc_category => id_doc_category, translated_code => translated_code, rank => rank)
          BULK COLLECT
          INTO l_coll_categories
          FROM (SELECT dc.id_doc_category,
                       dc.translated_code,
                       dc.rank,
                       row_number() over(PARTITION BY dc.id_doc_category ORDER BY dc.rank DESC NULLS LAST) rn
                  FROM TABLE(l_sections) s
                  JOIN doc_category_area_inst_soft dcais
                    ON dcais.id_doc_area = s.doc_area
                   AND dcais.id_institution = i_prof.institution
                   AND dcais.id_software = i_prof.software
                  JOIN TABLE(l_doc_categories) dc
                    ON dc.id_doc_category = dcais.id_doc_category
                 WHERE s.flg_write = pk_alert_constant.g_yes
                 ORDER BY rank, translated_code)
         WHERE rn = 1;
    
        RETURN l_coll_categories;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_coll_categories;
        
    END tf_categories_permission;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_summary_page;
/
