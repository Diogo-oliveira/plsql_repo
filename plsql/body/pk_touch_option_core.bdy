/*-- Last Change Revision: $Rev: 1989667 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-05-20 11:06:26 +0100 (qui, 20 mai 2021) $*/
CREATE OR REPLACE PACKAGE BODY pk_touch_option_core IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */

    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /********************************************************************************************
     * Returns the templates for an area
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_professional           Profissional ID
     * @param i_institution            Institution ID
     * @param i_software               Id of the software to get areas
     * @param i_doc_area               Id of the area to get templates
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        2.6.2
     * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION tf_doc_templates
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN table_number DEFAULT NULL
    ) RETURN t_coll_doc_template
        PIPELINED IS
        CURSOR c_doc_area IS
            SELECT dis.flg_type
              FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_institution, i_software)) dis;
    
        l_prof_template     profile_template.id_profile_template%TYPE;
        l_cursor            pk_touch_option_core.t_cur_doc_template;
        l_coll_doc_template pk_touch_option_core.t_coll_doc_template;
        l_doc_area_flg_type doc_area_inst_soft.flg_type%TYPE;
        l_context           doc_template_context.id_context%TYPE := NULL;
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_doc_templates';
        k_bulk_limit    CONSTANT PLS_INTEGER := 100;
        l_prof  profissional;
        l_error t_error_out;
    
    BEGIN
    
        l_prof          := profissional(i_professional, i_institution, i_software);
        l_prof_template := pk_prof_utils.get_prof_profile_template(l_prof);
    
        OPEN c_doc_area;
        FETCH c_doc_area
            INTO l_doc_area_flg_type;
        CLOSE c_doc_area;
    
        CASE
            WHEN l_doc_area_flg_type IN (pk_touch_option.g_flg_type_doc_area,
                                         pk_touch_option.g_flg_type_doc_area_complaint,
                                         pk_touch_option.g_flg_type_doc_area_appointmt,
                                         pk_touch_option.g_flg_type_doc_area_service,
                                         pk_touch_option.g_flg_type_doc_area_complaint,
                                         pk_touch_option.g_flg_type_doc_area_surg_proc) THEN
                l_context := i_doc_area;
            WHEN l_doc_area_flg_type IN (pk_touch_option.g_flg_type_appointment,
                                         pk_touch_option.g_flg_type_nursingedis_service,
                                         pk_touch_option.g_flg_type_clin_serv,
                                         pk_touch_option.g_flg_type_complaint,
                                         pk_touch_option.g_flg_type_sch_dep_clin_serv,
                                         pk_touch_option.g_flg_type_intervention,
                                         pk_touch_option.g_flg_type_exam,
                                         pk_touch_option.g_flg_type_cipe) THEN
                l_context := NULL;
            
        -- Unknown... a new unexpected type?
            ELSE
                l_context := NULL;
                --TODO: l_error := 'UNKNOWN DOC_AREA_SOFT_INST FLG_TYPE: ' || l_doc_area_flg_type;
        --TODO: RAISE g_exception;
        END CASE;
    
        OPEN l_cursor FOR
            SELECT /*+ result_cache */
             x.id_doc_template, x.code_doc_template
              FROM (SELECT DISTINCT dtc.id_doc_template, dt.code_doc_template
                      FROM doc_template dt
                     INNER JOIN doc_template_context dtc
                        ON dt.id_doc_template = dtc.id_doc_template
                     WHERE (dtc.id_context = l_context OR l_context IS NULL)
                       AND (dtc.id_profile_template = l_prof_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
                       AND ((dtc.flg_type = l_doc_area_flg_type AND
                           l_doc_area_flg_type != pk_touch_option.g_flg_type_complaint_sch_evnt) OR
                           (l_doc_area_flg_type = pk_touch_option.g_flg_type_complaint_sch_evnt AND
                           dtc.flg_type IN
                           (pk_touch_option.g_flg_type_complaint_sch_evnt, pk_touch_option.g_flg_type_appointment)))
                       AND dtc.id_software IN (0, i_software)
                       AND dtc.id_institution IN (0, i_institution)
                       AND dt.flg_available = pk_alert_constant.g_yes
                          
                       AND (i_doc_template IS NULL OR
                           dt.id_doc_template IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                    t.column_value
                                                     FROM TABLE(i_doc_template) t))
                       AND rownum > 0) x
            
            -- We ensure that the template has content for the area indicated                                                           
             WHERE EXISTS (SELECT 1
                      FROM doc_template_area dta
                     WHERE dta.id_doc_template = x.id_doc_template
                       AND dta.id_doc_area = i_doc_area
                       AND pk_touch_option_core.get_template_translated(i_lang         => i_lang,
                                                                        i_prof         => l_prof,
                                                                        i_doc_area     => i_doc_area,
                                                                        i_doc_template => x.id_doc_template) =
                           pk_alert_constant.g_yes);
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_coll_doc_template LIMIT k_bulk_limit;
            EXIT WHEN l_coll_doc_template.count = 0;
        
            FOR i IN 1 .. l_coll_doc_template.count
            LOOP
                PIPE ROW(l_coll_doc_template(i));
            END LOOP;
        
        END LOOP;
        CLOSE l_cursor;
    
        RETURN;
    EXCEPTION
        WHEN no_data_needed THEN
            -- when we run a pipelined function without exhausting it we see this exception being rased to clean up (releasing any resources that need be released).
            -- Perform cleanup operations
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            RETURN;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
        
            RAISE;
    END tf_doc_templates;

    /********************************************************************************************
    * Returns the areas for a product
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_professional           Profissional ID
    * @param i_institution            Institution ID
    * @param i_software               Id of the software to get areas
    * @param i_prof_profile_template  Profile ID used by i_professional for the i_software. NULL: the profile will be retrieved according the input parameters.
    * @param i_inst_market            Market ID of i_institution. NULL the market will be retrieved according the input parameter.
    * @param i_check_template_exists  Ensure that the areas have templates. If an area has no templates then is not included in the output.    
    *
    * @return                         true or false on success or error
    *
    * @author                         Daniel Ferreira
    * @version                        2.6.2
    * @since                          2012/01/19
    **********************************************************************************************/
    FUNCTION tf_doc_areas
    (
        i_lang                  IN language.id_language%TYPE,
        i_professional          IN professional.id_professional%TYPE,
        i_institution           IN institution.id_institution%TYPE,
        i_software              IN software.id_software%TYPE,
        i_prof_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_inst_market           IN market.id_market%TYPE DEFAULT NULL,
        i_check_template_exists IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN t_coll_doc_area
        PIPELINED IS
    
        l_cursor                pk_touch_option_core.t_cur_doc_area;
        l_coll_doc_area         pk_touch_option_core.t_coll_doc_area;
        l_prof_profile_template profile_template.id_profile_template%TYPE;
        l_inst_market           market.id_market%TYPE;
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_doc_areas';
        k_bulk_limit    CONSTANT PLS_INTEGER := 100;
        l_error t_error_out;
    BEGIN
        IF i_prof_profile_template IS NULL
        THEN
            l_prof_profile_template := pk_prof_utils.get_prof_profile_template(profissional(i_professional,
                                                                                            i_institution,
                                                                                            i_software));
        ELSE
            l_prof_profile_template := i_prof_profile_template;
        END IF;
    
        IF i_inst_market IS NULL
        THEN
            l_inst_market := pk_core.get_inst_mkt(i_institution);
        ELSE
            l_inst_market := i_inst_market;
        END IF;
    
        OPEN l_cursor FOR
        -- Areas with profile access check (summary_page.flg_access = Y)
            SELECT /*+ result_cache */
             t.id_doc_area
              FROM (SELECT DISTINCT da.id_doc_area id_doc_area
                      FROM summary_page sp
                     INNER JOIN summary_page_section sps
                        ON sp.id_summary_page = sps.id_summary_page
                     INNER JOIN summary_page_access spa
                        ON spa.id_summary_page_section = sps.id_summary_page_section
                     INNER JOIN profile_template pt
                        ON pt.id_profile_template = spa.id_profile_template
                     INNER JOIN doc_area da
                        ON sps.id_doc_area = da.id_doc_area
                     INNER JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_institution, l_inst_market, i_software)) dais
                        ON da.id_doc_area = dais.id_doc_area
                     WHERE sp.flg_access = pk_alert_constant.g_yes
                       AND pt.id_profile_template = l_prof_profile_template
                       AND spa.flg_write = pk_alert_constant.g_yes
                       AND (dais.flg_mode = 'D' OR
                           (dais.flg_mode = 'N' AND dais.flg_switch_mode = pk_alert_constant.g_yes))) t
             WHERE (i_check_template_exists = pk_alert_constant.g_no)
                OR EXISTS
             (SELECT 1
                      FROM TABLE(tf_doc_templates(i_lang, i_professional, i_institution, i_software, t.id_doc_area)))
            
            UNION ALL
            -- Areas with no profile access check (summary_page.flg_access = N)
            SELECT /*+ result_cache */
             t.id_doc_area
              FROM (SELECT DISTINCT da.id_doc_area
                      FROM summary_page sp
                     INNER JOIN summary_page_section sps
                        ON sp.id_summary_page = sps.id_summary_page
                     INNER JOIN doc_area da
                        ON sps.id_doc_area = da.id_doc_area
                     INNER JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_institution, l_inst_market, i_software)) dais
                    
                        ON da.id_doc_area = dais.id_doc_area
                     WHERE sp.flg_access = pk_alert_constant.g_no
                       AND (dais.flg_mode = 'D' OR
                           (dais.flg_mode = 'N' AND dais.flg_switch_mode = pk_alert_constant.g_yes))) t
             WHERE (i_check_template_exists = pk_alert_constant.g_no)
                OR EXISTS
             (SELECT 1
                      FROM TABLE(tf_doc_templates(i_lang, i_professional, i_institution, i_software, t.id_doc_area)))
            
            UNION ALL
            -- "External" areas that aren't Touch-option "pure" documentation but use templates (Procedures, Other Exams, ICNP)
            SELECT /*+ result_cache */
             ext_area.column_value id_doc_area
              FROM TABLE(table_number(pk_procedures_constant.g_doc_area_intervention,
                                      pk_exam_constant.g_doc_area_exam,
                                      pk_icnp_constant.g_doc_area_icnp)) ext_area
             WHERE EXISTS (SELECT 1
                      FROM TABLE(tf_doc_templates(i_lang,
                                                  i_professional,
                                                  i_institution,
                                                  i_software,
                                                  ext_area.column_value)));
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_coll_doc_area LIMIT k_bulk_limit;
            EXIT WHEN l_coll_doc_area.count = 0;
        
            FOR i IN 1 .. l_coll_doc_area.count
            LOOP
                PIPE ROW(l_coll_doc_area(i));
            END LOOP;
        
        END LOOP;
        CLOSE l_cursor;
        RETURN;
    EXCEPTION
        WHEN no_data_needed THEN
            -- when we run a pipelined function without exhausting it we see this exception being rased to clean up (releasing any resources that need be released).
            -- Perform cleanup operations
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            RETURN;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
        
            RAISE;
    END tf_doc_areas;

    /**
    * Check if the template remains available to be used by this professional
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_doc_area       Documentation area ID 
    * @param   i_doc_template   Template ID. If Null this function will returns 'Y'.
    *
    * @return  Flag indicating if template is currently available to be used or not.
    *
    * @value return  {*} 'Y' Template is currently available (or  i_doc_template is null) {*} 'N' The template is not available 
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   31-01-2012
    */
    FUNCTION check_can_use_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2 IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_can_use_template';
        l_can_use VARCHAR2(1 CHAR);
        l_error   t_error_out;
    BEGIN
        l_can_use := pk_alert_constant.g_no;
    
        IF i_doc_template IS NULL
        THEN
            -- The documentation was performed without using a template (documented in free text). Therefore the registration information can be reused.
            l_can_use := pk_alert_constant.g_yes;
        ELSE
            -- Verify if the template used to document this record is currently available to be used by the professional in this environment
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_can_use
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM TABLE(pk_touch_option_core.tf_doc_templates(i_lang         => i_lang,
                                                                           i_professional => i_prof.id,
                                                                           i_institution  => i_prof.institution,
                                                                           i_software     => i_prof.software,
                                                                           i_doc_area     => i_doc_area)) dt
                         WHERE dt.id_doc_template = i_doc_template);
            EXCEPTION
                WHEN no_data_found THEN
                    -- The template used is not available
                    l_can_use := pk_alert_constant.g_no;
            END;
        END IF;
        RETURN l_can_use;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RETURN NULL;
    END check_can_use_template;

    /**
    * Procedure that resolves bind variables required for the filter TOTPreviousRecords
    *
    * @param i_context_ids  Static contexts (i_prof, i_lang, i_episode, i_patient)
    * @param i_context_vals Custom contexts, sent from the user interface
    * @param i_name         Name of the bind variable to get
    * @param  o_vc2         Varchar2 value returned by the procedure
    * @param  o_num         Numeric value returned by the procedure
    * @param  o_id          NUMBER(24) value returned by the procedure
    * @param  o_tstz        Timestamp value returned by the procedure
    *
    * @catches 
    * @throws  e_invalid_parameter      If i_context_vals is not initialized, does not include required values as id_doc_area
    * @throws  e_bind_resolution_error  An unexpected bind name is being used in SQL base filter
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   15-02-2012
    */
    PROCEDURE init_fltr_params_prev_records
    (
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'init_fltr_params_prev_records';
    
        k_lang             CONSTANT NUMBER(24) := 1;
        k_prof_id          CONSTANT NUMBER(24) := 2;
        k_prof_institution CONSTANT NUMBER(24) := 3;
        k_prof_software    CONSTANT NUMBER(24) := 4;
        k_episode          CONSTANT NUMBER(24) := 5;
        k_patient          CONSTANT NUMBER(24) := 6;
    
        -- Custom context vals
        k_doc_area CONSTANT NUMBER(24) := 1;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(k_prof_id),
                                                        i_context_ids(k_prof_institution),
                                                        
                                                        i_context_ids(k_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(k_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(k_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    BEGIN
        -- Explicit initialization to suppress compilation warns like: Parameter 'X' is declared but never used
        o_vc2  := NULL;
        o_num  := NULL;
        o_id   := NULL;
        o_tstz := NULL;
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_visit' THEN
                IF l_episode IS NOT NULL
                THEN
                    o_id := pk_episode.get_id_visit(l_episode);
                END IF;
            
            WHEN 'i_doc_area' THEN
                -- Retrieve id_doc_area value from custom context
                IF i_context_vals IS NOT NULL
                   AND i_context_vals.exists(k_doc_area)
                THEN
                    o_id := to_number(i_context_vals(k_doc_area));
                ELSE
                    -- No context value for id_doc_area
                    RAISE pk_touch_option_core.e_invalid_parameter;
                END IF;
            
            WHEN 'i_last_visit' THEN
                o_id := pk_episode.get_id_visit(l_episode);
                /*
                TODO: owner="ariel.machado" created="01-02-2012"
                text="Replace this code by a method that retrieves the last visit for current episode (last visit != current visit )"
                */
            ELSE
                -- Unexpected bind variable
                RAISE pk_touch_option_core.e_invalid_parameter;
            
        END CASE;
    
        pk_alertlog.log_debug(text            => 'Value of bind variable ' || nvl(i_name, '<null>') || ' : ' ||
                                                 nvl(coalesce(o_vc2, to_char(o_num), to_char(o_id), to_char(o_tstz)),
                                                     '<null>'),
                              object_name     => g_package_name,
                              sub_object_name => k_function_name);
    
    EXCEPTION
        WHEN pk_touch_option_core.e_invalid_parameter THEN
            DECLARE
                l_instance PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_parameter',
                                                   err_instance_id_out => l_instance,
                                                   text_in             => 'No context value for id_doc_area',
                                                   name1_in            => 'PACKAGE',
                                                   value1_in           => g_package_name,
                                                   name2_in            => 'METHOD',
                                                   value2_in           => k_function_name);
                RAISE;
            END;
        
        WHEN pk_touch_option_core.e_bind_resolution_error THEN
            DECLARE
                l_instance PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => 'e_bind_resolution_error',
                                                   err_instance_id_out => l_instance,
                                                   text_in             => 'Unexpected bind variable i_name=' ||
                                                                          nvl(i_name, '<null>'),
                                                   name1_in            => 'PACKAGE',
                                                   value1_in           => g_package_name,
                                                   name2_in            => 'METHOD',
                                                   value2_in           => k_function_name);
                RAISE;
            END;
        
    END init_fltr_params_prev_records;

    /**
    * Retrieves details about a set of previous records done in a touch-option area 
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_patient             Patient ID 
    * @param   i_episode             Episode ID
    * @param   i_doc_area            Documentation area ID        
    * @param   i_epis_doc            Table number with id_epis_documentation        
    * @param   o_doc_area_register   Cursor with the doc area info register        
    * @param   o_doc_area_val        Cursor containing the completed info for episode        
    * @param   o_template_layouts    Cursor containing the layout for each template used        
    * @param   o_doc_area_component  Cursor containing the components for each template used        
    *
    * @catches 
    * @throws  e_function_call_error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   16-02-2012
    */
    PROCEDURE get_prev_record_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_doc           IN table_number,
        o_doc_area_register  OUT NOCOPY pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT NOCOPY pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_prev_records_detail';
        l_error t_error_out;
    BEGIN
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_episode,
                                                           i_id_patient         => i_patient,
                                                           i_doc_area           => i_doc_area,
                                                           i_epis_doc           => i_epis_doc,
                                                           i_epis_anamn         => table_number(),
                                                           i_epis_rev_sys       => table_number(),
                                                           i_epis_obs           => table_number(),
                                                           i_epis_past_fsh      => table_number(),
                                                           i_epis_recomend      => table_number(),
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           i_order              => pk_alert_constant.g_order_descending,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => l_error)
        THEN
            pk_alert_exceptions.add_context(err_instance_id_in => l_error.err_instance_id_out,
                                            name_in            => 'PACKAGE',
                                            value_in           => g_package_name);
            pk_alert_exceptions.add_context(err_instance_id_in => l_error.err_instance_id_out,
                                            name_in            => 'METHOD',
                                            value_in           => k_function_name);
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
    
    END get_prev_record_detail;

    /********************************************************************************************
    * Checks if the elements of a template has translations
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_doc_area               Doc area
    * @param i_doc_template           Template                                                                                       
    *                                                                                                                                         
    * @return                         {*} 'Y'  Has translations {*} 'N' Has no translations                                                        
    *
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/07/25                                                                                               
    ********************************************************************************************/
    FUNCTION get_template_translated
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN VARCHAR2 IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_template_translated';
    
        --Number of elements in the template used as sample to see if they have translations
        k_content_sample_size CONSTANT PLS_INTEGER := 5;
    
        l_is_translated VARCHAR2(1) := pk_alert_constant.g_no;
        l_error         t_error_out;
    
        no_elements_excep EXCEPTION;
    BEGIN
    
        --Check if this template has elements for the doc_area
        SELECT decode(COUNT(0), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_is_translated
          FROM doc_template_area dta
         WHERE dta.id_doc_template = i_doc_template
           AND dta.id_doc_area = i_doc_area
           AND EXISTS (SELECT 1
                  FROM doc_template_area_doc dtad
                 WHERE dtad.id_doc_template = dta.id_doc_template
                   AND dtad.id_doc_area = dta.id_doc_area);
    
        --(ALERT-10431) Only if exist elements for the doc_area then check if has translations
        IF l_is_translated = pk_alert_constant.g_no
        THEN
            RAISE no_elements_excep;
        ELSE
            g_error := 'TRANSLATIONS COUNTING FOR TEMPLATE';
            WITH content_sample AS
             (SELECT /*+ materialize */
               code_element_open
                FROM (SELECT row_number() over(ORDER BY dtad.rank) rn, decr.code_element_open
                        FROM doc_element_crit decr
                       INNER JOIN doc_element de
                          ON decr.id_doc_element = de.id_doc_element
                       INNER JOIN documentation d
                          ON de.id_documentation = d.id_documentation
                       INNER JOIN doc_template_area_doc dtad
                          ON d.id_documentation = dtad.id_documentation
                       WHERE dtad.id_doc_template = i_doc_template
                         AND dtad.id_doc_area = i_doc_area
                         AND de.flg_type != pk_touch_option.g_elem_flg_type_text
                         AND decr.flg_available = pk_alert_constant.g_yes
                         AND d.flg_available = pk_alert_constant.g_yes
                         AND de.flg_available = pk_alert_constant.g_yes)
               WHERE rn <= k_content_sample_size)
            SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
              INTO l_is_translated
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM content_sample x
                     WHERE length(TRIM(pk_translation.get_translation(i_lang, x.code_element_open))) > 0);
        
            -- Does not exist translations, but the template can have been built only with elements that don't use descriptions (texts, numerical elements, etc. ..)
            -- Then it checks that does not exist elements that should have descriptions
            IF (l_is_translated = pk_alert_constant.g_no)
            THEN
                SELECT decode(COUNT(0), 0, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                  INTO l_is_translated
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM doc_element de
                         INNER JOIN documentation d
                            ON de.id_documentation = d.id_documentation
                         INNER JOIN doc_template_area_doc dtad
                            ON d.id_documentation = dtad.id_documentation
                         WHERE dtad.id_doc_template = i_doc_template
                           AND dtad.id_doc_area = i_doc_area
                           AND de.flg_available = pk_alert_constant.g_yes
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND de.flg_type IN (pk_touch_option.g_elem_flg_type_touch,
                                               pk_touch_option.g_elem_flg_type_mchoice_single,
                                               pk_touch_option.g_elem_flg_type_mchoice_multpl,
                                               pk_touch_option.g_elem_flg_type_comp_numeric,
                                               pk_touch_option.g_elem_flg_type_comp_date,
                                               pk_touch_option.g_elem_flg_type_comp_text,
                                               pk_touch_option.g_elem_flg_type_comp_ref_value));
            END IF;
        
        END IF;
        RETURN l_is_translated;
    
    EXCEPTION
        WHEN no_elements_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   'The doc_template = ' || i_doc_template || ' has no elements for the doc_area = ' ||
                                   i_doc_area,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error);
                RETURN l_is_translated; --Treated as no error for user
            END;
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END get_template_translated;

    /**
    * Returns list of editions done in a documentation entry
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_epis_documentation   ID documentation entry 
    *
    * @return  Collection of t_rec_epis_edition_log
    *
    * @catches 
    * @throws  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   09-03-2012
    */
    FUNCTION get_epis_doc_edition_log
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN t_coll_epis_edition_log IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_epis_doc_edition_log';
        l_coll_epis_edition_log t_coll_epis_edition_log;
    BEGIN
        g_error := 'Retrieves edition log for id_epis_documentation: ' || to_char(i_epis_documentation);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        SELECT x.*
          BULK COLLECT
          INTO l_coll_epis_edition_log
          FROM (SELECT ed.id_epis_documentation,
                       ed.id_epis_documentation_parent,
                       ed.flg_status,
                       ed.flg_edition_type,
                       ed.dt_creation_tstz
                  FROM epis_documentation ed
                CONNECT BY PRIOR ed.id_epis_documentation = ed.id_epis_documentation_parent
                 START WITH ed.id_epis_documentation = i_epis_documentation
                UNION ALL
                SELECT ed.id_epis_documentation,
                       ed.id_epis_documentation_parent,
                       ed.flg_status,
                       ed.flg_edition_type,
                       ed.dt_creation_tstz
                  FROM epis_documentation ed
                 WHERE ed.id_epis_documentation <> i_epis_documentation
                CONNECT BY PRIOR ed.id_epis_documentation_parent = ed.id_epis_documentation
                 START WITH ed.id_epis_documentation = i_epis_documentation
                 ORDER BY dt_creation_tstz DESC) x;
        RETURN l_coll_epis_edition_log;
    END get_epis_doc_edition_log;

    /**
    * Returns if an entry can be edited or not
    *
    * @param   i_flg_table_origin         Professional preferred language
    *
    * @value   i_flg_table_origin         {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION {*} 'R' EPIS_RECOMEND {*} 'F' PAT_FAM_SOC_HIST {*} 'G' EPIS_DIAGNOSIS {*} 'U' SR_SURGERY_RECORD
    * 
    * @return  Boolean
    *
    * @author  MIGUEL.LEITE
    * @version V2.6.2.1
    * @since   21-03-2012 14:59:41
    */
    FUNCTION can_edit_entry(i_flg_table_origin IN VARCHAR2) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF (i_flg_table_origin IN (pk_touch_option.g_flg_tab_origin_epis_recomend,
                                   pk_touch_option.g_flg_tab_origin_epis_past_fsh,
                                   pk_touch_option.g_flg_tab_origin_epis_diags,
                                   pk_touch_option.g_flg_tab_origin_surg_record))
        
        THEN
            RETURN pk_alert_constant.g_no;
        
        ELSE
            RETURN pk_alert_constant.g_yes;
        
        END IF;
    
    END can_edit_entry;

    /**
    * Returns the possible actions for a documentation entry in a touch option area
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_documentation    Entry ID
    * @param   i_flg_table_origin      Entry table origin
    * @param   i_flg_write             Write permission
    * @param   i_flg_no_changes        Permission for "No changes" action
    * @param   i_show_disabled_actions Allow invalid actions to be returned, but disabled <FLG_ACTIVE == 'N'>
    * @param   o_actions               Actions information
    *
    * @value   i_flg_table_origin      {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION {*} 'R' EPIS_RECOMEND {*} 'F' PAT_FAM_SOC_HIST {*} 'G' EPIS_DIAGNOSIS {*} 'U' SR_SURGERY_RECORD
    * @value   i_flg_write             {*} 'Y'  YES {*} 'N'  NO
    * @value   i_flg_no_changes        {*} 'Y'  YES {*} 'N'  NO
    * @value   i_show_disabled_actions {*} 'Y'  YES {*} 'N'  NO
    * @param   i_nr_record             Number of allowed record 
    *
    * @author  MIGUEL.LEITE
    * @version V2.6.2.1
    * @since   20-03-2012 14:59:41
    */
    PROCEDURE get_entry_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_table_origin      IN VARCHAR2,
        i_flg_write             IN VARCHAR2,
        i_flg_update            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_no_changes        IN VARCHAR2 DEFAULT 'N',
        i_show_disabled_actions IN VARCHAR2 DEFAULT 'N',
        i_nr_record             IN NUMBER DEFAULT NULL,
        o_actions               OUT pk_types.cursor_type
    ) IS
    
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_entry_actions';
    
        -- GENERAL VARIABLES
        l_prof_entry      professional.id_professional%TYPE;
        l_status_entry    epis_documentation.flg_status%TYPE;
        l_editable_entry  VARCHAR2(1 CHAR);
        l_edit_other_prof sys_config.value%TYPE;
    
        -- SYS_MESSAGE CONSTANTS
        l_msg_edit           CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M021';
        l_msg_update         CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M030';
        l_msg_no_changes     CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M031';
        l_msg_cancel         CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M053';
        l_cfg_edit_ign_owner CONSTANT sys_config.id_sys_config%TYPE := 'TO_ALLOW_EDIT_IGNORING_OWNER';
    
        -- FLG_ACTION CONSTANTS
        l_flg_edit       CONSTANT VARCHAR2(1 CHAR) := 'E';
        l_flg_update     CONSTANT VARCHAR2(1 CHAR) := 'U';
        l_flg_no_changes CONSTANT VARCHAR2(1 CHAR) := 'O';
        l_flg_cancel     CONSTANT VARCHAR2(1 CHAR) := 'C';
    
    BEGIN
        l_edit_other_prof := pk_sysconfig.get_config(i_code_cf   => l_cfg_edit_ign_owner,
                                                     i_prof_inst => i_prof.institution,
                                                     i_prof_soft => i_prof.software);
    
        IF i_epis_documentation IS NULL
           OR i_flg_table_origin IS NULL
        
        THEN
            g_error := 'I_EPIS_DOCUMENTATION (' || nvl(to_char(i_epis_documentation), '<NULL>') ||
                       ') / I_FLG_TABLE_ORIGIN (' || nvl(i_flg_table_origin, '<NULL>') || ') INVALID ARGUMENTS';
            RAISE e_invalid_parameter;
        
        END IF;
    
        l_editable_entry := can_edit_entry(i_flg_table_origin);
    
        DELETE FROM tbl_temp;
    
        -- If entry is not editable, returns an empty result
        IF l_editable_entry = pk_alert_constant.g_yes
           AND i_flg_write = pk_alert_constant.g_yes
           OR i_show_disabled_actions = pk_alert_constant.g_yes
        
        THEN
            g_error := 'Insert in tbl_temp the possible actions for an entry';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        
            -- Insert in tbl_temp the possible actions for an entry
            INSERT ALL INTO tbl_temp
                (vc_1, vc_2, vc_3, num_1)
            VALUES
                (l_flg_edit, l_msg_edit, pk_alert_constant.g_inactive, 10) INTO tbl_temp
                (vc_1, vc_2, vc_3, num_1)
            VALUES
                (l_flg_update, l_msg_update, pk_alert_constant.g_inactive, 20) INTO tbl_temp
                (vc_1, vc_2, vc_3, num_1)
            VALUES
                (l_flg_no_changes, l_msg_no_changes, pk_alert_constant.g_inactive, 30) INTO tbl_temp
                (vc_1, vc_2, vc_3, num_1)
            VALUES
                (l_flg_cancel, l_msg_cancel, pk_alert_constant.g_inactive, 40)
                SELECT *
                  FROM dual;
        
            -- All actions will be enabled only if it has writing permessions
            IF i_flg_write = pk_alert_constant.g_yes
            
            THEN
            
                -- Table source of the record currently in editing
                CASE i_flg_table_origin
                -- Edition of a documentation record that was previously saved in EPIS_DOCUMENTATION        
                    WHEN pk_touch_option.g_flg_tab_origin_epis_doc THEN
                        g_error := 'Get info of entry from EPIS_DOCUMENTATION';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => k_function_name);
                    
                        SELECT ed.id_professional, ed.flg_status
                          INTO l_prof_entry, l_status_entry
                          FROM epis_documentation ed
                         WHERE ed.id_epis_documentation = i_epis_documentation;
                    
                -- Edition of an old HPI record (free-text) that was previously saved in EPIS_ANAMNESIS
                    WHEN pk_touch_option.g_flg_tab_origin_epis_anamn THEN
                        g_error := 'Get info of entry from EPIS_ANAMNESIS';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => k_function_name);
                    
                        SELECT ea.id_professional, ea.flg_status
                          INTO l_prof_entry, l_status_entry
                          FROM epis_anamnesis ea
                         WHERE ea.id_epis_anamnesis = i_epis_documentation;
                    
                -- Edition of an old RoS record (free-text) that was previously saved in EPIS_REVIEW_SYSTEMS        
                    WHEN pk_touch_option.g_flg_tab_origin_epis_rev_sys THEN
                        g_error := 'Get info of entry from EPIS_REVIEW_SYSTEMS';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => k_function_name);
                    
                        SELECT ers.id_professional, ers.flg_status
                          INTO l_prof_entry, l_status_entry
                          FROM epis_review_systems ers
                         WHERE ers.id_epis_review_systems = i_epis_documentation;
                    
                -- Edition of an old Physical Exam/Assessment record (free-text) that was previously saved in EPIS_OBSERVATION
                    WHEN pk_touch_option.g_flg_tab_origin_epis_obs THEN
                        g_error := 'Get info of entry from EPIS_OBSERVATION';
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => k_function_name);
                    
                        SELECT eo.id_professional, eo.flg_status
                          INTO l_prof_entry, l_status_entry
                          FROM epis_observation eo
                         WHERE eo.id_epis_observation = i_epis_documentation;
                    
                    ELSE
                        g_error := 'I_FLG_TABLE_ORIGIN (' || i_flg_table_origin || ') NOT SUPPORTED';
                    
                        RAISE pk_touch_option_core.e_invalid_parameter;
                    
                END CASE;
            
                -- Updates the state of each action according to some conditions
                g_error := 'Updates the state of each action according to some conditions';
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => k_function_name);
            
                UPDATE tbl_temp tt
                   SET tt.vc_3 = pk_alert_constant.g_active
                 WHERE
                -- EDIT
                 (tt.vc_1 = l_flg_edit AND (l_prof_entry = i_prof.id OR l_edit_other_prof = pk_alert_constant.g_yes) AND
                 l_status_entry = pk_alert_constant.g_active AND l_editable_entry = pk_alert_constant.g_yes)
                 OR
                -- UPDATE
                 (tt.vc_1 = l_flg_update AND l_status_entry = pk_alert_constant.g_active AND
                 l_editable_entry = pk_alert_constant.g_yes AND (i_nr_record > 1 OR i_nr_record IS NULL) AND
                 i_flg_update = pk_alert_constant.g_yes)
                 OR
                -- NO_CHANGES
                 (tt.vc_1 = l_flg_no_changes AND l_status_entry = pk_alert_constant.g_active AND
                 l_editable_entry = pk_alert_constant.g_yes AND i_flg_no_changes = pk_alert_constant.g_yes)
                 OR
                -- CANCEL
                 (tt.vc_1 = l_flg_cancel AND l_status_entry = pk_alert_constant.g_active AND l_prof_entry = i_prof.id AND
                 i_flg_table_origin = pk_touch_option.g_flg_tab_origin_epis_doc);
            
            END IF;
        
        END IF;
    
        g_error := 'Open cursor for retrieve actions';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        OPEN o_actions FOR
            SELECT NULL id_action,
                   NULL id_parent,
                   1 "LEVEL",
                   NULL from_state,
                   NULL to_state,
                   pk_message.get_message(i_lang => i_lang, i_code_mess => act.vc_2) desc_action,
                   NULL icon,
                   NULL flg_default,
                   act.vc_3 flg_active,
                   act.vc_1 action
              FROM tbl_temp act
             WHERE act.vc_3 = pk_alert_constant.g_active
                OR i_show_disabled_actions = pk_alert_constant.g_yes
             ORDER BY "LEVEL", act.num_1, desc_action;
    
    EXCEPTION
    
        WHEN e_invalid_parameter THEN
        
            DECLARE
                l_instance_id PLS_INTEGER;
            
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_parameter',
                                                   err_instance_id_out => l_instance_id,
                                                   text_in             => 'ENTRY_ACTIONS',
                                                   name1_in            => 'PACKAGE',
                                                   value1_in           => g_package_name,
                                                   name2_in            => 'METHOD',
                                                   value2_in           => k_function_name,
                                                   name3_in            => 'ERROR',
                                                   value3_in           => g_error);
                RAISE;
            END;
    END get_entry_actions;

    /**
    * Returns the content of a set of Touch-option documentation entries in plain-text format
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation_list   List of id_pis_documentation to retrieve
    * @param   i_use_html_format           Use HTML tags to format output. Default: No
    * @param   o_entries                   Cursor with the content of entries in plain text format
    *
    * @value   i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.3
    * @since   26-06-2012
    */
    PROCEDURE get_plain_text_entries
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_documentation_list IN table_number,
        i_use_html_format         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_entries                 OUT t_cur_plain_text_entry
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_plain_text_entries';
    
        --t_tbl_plain_text_entry
        --g_rec_plain_text_entry
    
        l_entries t_cur_plain_text_entry;
        t_entries t_tbl_plain_text_entry;
    BEGIN
        g_error := 'Input arguments' || chr(10) || 'i_lang: ' || i_lang || ' institution:' || i_prof.institution ||
                   ' software:' || i_prof.software;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        g_error := 'Open cursor o_entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        -- OPEN l_entries FOR
        -- Documentation entries
        WITH ed_entries AS
         (SELECT /*+ materialize */
           ed.id_epis_documentation,
           ed.dt_creation_tstz,
           ed.flg_status,
           ed.id_doc_area,
           ed.id_doc_template,
           regexp_replace(ed.notes, '\s+(' || chr(13) || chr(10) || '|$)', '') notes,
           pk_summary_page.get_doc_area_name(i_lang, i_prof.software, ed.id_doc_area) area_name
            FROM epis_documentation ed
           WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value
                                                FROM TABLE(i_epis_documentation_list) t)),
        
        -- Free-text entries
        ed_free_text AS
         (SELECT /*+ materialize */
           e.id_epis_documentation, e.dt_creation_tstz, e.notes, e.area_name
            FROM ed_entries e
           WHERE e.id_doc_template IS NULL
             AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
        
        -- Additional Notes for template entries
        ed_additional_notes AS
         (SELECT /*+ materialize */
           e.id_epis_documentation, e.notes
            FROM ed_entries e
           WHERE e.id_doc_template IS NOT NULL
             AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
        
        -- Lines of documentation entries (components)
        edd_lines AS
         (SELECT /*+ materialize */
          DISTINCT edd.id_epis_documentation,
                   edd.id_documentation,
                   dtad.rank rank_component,
                   dc.code_doc_component,
                   d.id_documentation_parent,
                   ed.id_doc_template,
                   ed.id_doc_area
            FROM epis_documentation ed
           INNER JOIN epis_documentation_det edd
              ON ed.id_epis_documentation = edd.id_epis_documentation
           INNER JOIN documentation d
              ON d.id_documentation = edd.id_documentation
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_template_area_doc dtad
              ON dtad.id_doc_template = ed.id_doc_template
             AND dtad.id_doc_area = ed.id_doc_area
             AND dtad.id_documentation = edd.id_documentation
           WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                FROM ed_entries t)),
        
        -- Lines of titles (Components of type "Title")
        edd_titles AS
         (SELECT /*+ materialize */
           t.id_epis_documentation, d.id_documentation, dc.code_doc_component, dtad.rank rank_component
            FROM (SELECT DISTINCT l.id_epis_documentation, l.id_documentation_parent, l.id_doc_area, l.id_doc_template
                    FROM edd_lines l
                   WHERE l.id_documentation_parent IS NOT NULL) t
           INNER JOIN documentation d
              ON d.id_documentation = t.id_documentation_parent
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_template_area_doc dtad
              ON dtad.id_doc_template = t.id_doc_template
             AND dtad.id_doc_area = t.id_doc_area
             AND dtad.id_documentation = t.id_documentation_parent
           WHERE dc.flg_type = pk_summary_page.g_doc_title
             AND dc.flg_available = pk_alert_constant.g_available
             AND d.flg_available = pk_alert_constant.g_available),
        
        -- Documented elements
        edd_elements AS
         (SELECT /*+ materialize */
           ed.id_epis_documentation,
           d.id_documentation,
           d.id_documentation_parent,
           dc.id_doc_component,
           dc.code_doc_component,
           de.id_doc_element,
           pk_touch_option.get_epis_formatted_element(i_lang, i_prof, edd.id_epis_documentation_det, i_use_html_format) desc_element,
           de.separator,
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
             AND dtad.id_documentation = edd.id_documentation
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_element_crit decr
              ON decr.id_doc_element_crit = edd.id_doc_element_crit
           INNER JOIN doc_element de
              ON de.id_doc_element = edd.id_doc_element
           WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                FROM ed_entries t)),
        -- Formated Touch-option template entries in plain text (titles + components: elements + additional notes)
        full_entries_as_text AS
         (SELECT x.id_epis_documentation,
                 x.id_documentation,
                 CASE i_use_html_format
                     WHEN pk_alert_constant.g_yes THEN
                      htf.bold(pk_translation.get_translation(i_lang, x.code_doc_component))
                     ELSE
                      pk_translation.get_translation(i_lang, x.code_doc_component)
                 END desc_component,
                 pk_string_utils.concat_element_list_clob(CAST(MULTISET
                                                               (SELECT e.desc_element,
                                                                       CASE
                                                                            WHEN e.separator IS NULL THEN
                                                                             pk_touch_option.g_elem_separator_default
                                                                            WHEN e.separator =
                                                                                 pk_touch_option.g_elem_separator_none THEN
                                                                             NULL
                                                                            ELSE
                                                                             e.separator
                                                                        END delimiter
                                                                  FROM edd_elements e
                                                                 WHERE e.id_epis_documentation = x.id_epis_documentation
                                                                   AND e.id_documentation = x.id_documentation
                                                                 ORDER BY e.rank_element) AS t_coll_text_delimiter_tuple)) desc_element_list,
                 x.rank_component
            FROM edd_lines x
          -- Titles
          UNION ALL
          SELECT t.id_epis_documentation,
                 t.id_documentation,
                 chr(10) || CASE i_use_html_format
                     WHEN pk_alert_constant.g_yes THEN
                      htf.bold(pk_translation.get_translation(i_lang, t.code_doc_component))
                     ELSE
                      pk_translation.get_translation(i_lang, t.code_doc_component)
                 END desc_component,
                 empty_clob() desc_element_list,
                 t.rank_component
            FROM edd_titles t
          
          UNION ALL
          -- Additional Notes
          SELECT an.id_epis_documentation,
                 NULL id_documentation,
                 chr(10) || CASE i_use_html_format
                     WHEN pk_alert_constant.g_yes THEN
                      htf.bold(pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010'))
                     ELSE
                      pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010')
                 END desc_component,
                 CASE i_use_html_format
                     WHEN pk_alert_constant.g_yes THEN
                      pk_string_utils.escape_sc(an.notes)
                     ELSE
                      an.notes
                 END desc_element_list,
                 
                 999999999999 rank_component
            FROM ed_additional_notes an
           ORDER BY id_epis_documentation, rank_component)
        
        -- Main query:
        -- Touch-option entries
        SELECT g_rec_plain_text_entry(z.id_epis_documentation,
                                      z.dt_creation_tstz,
                                      z.template_title,
                                      z.desc_element_list,
                                      z.area_name,
                                      z.desc_component)
          BULK COLLECT
          INTO t_entries
          FROM (SELECT tot.id_epis_documentation,
                       e.dt_creation_tstz,
                       pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || e.id_doc_template) template_title,
                       tot.desc_element_list,
                       e.area_name,
                       tot.desc_component,
                       tot.rank_component
                  FROM full_entries_as_text tot
                 INNER JOIN ed_entries e
                    ON e.id_epis_documentation = tot.id_epis_documentation
                UNION ALL
                -- Free-text entries
                SELECT ft.id_epis_documentation,
                       ft.dt_creation_tstz,
                       NULL template_title,
                       CASE i_use_html_format
                           WHEN pk_alert_constant.g_yes THEN
                            pk_string_utils.escape_sc(ft.notes)
                           ELSE
                            ft.notes
                       END plain_text_entry,
                       ft.area_name,
                       NULL desc_component,
                       NULL rank_component
                  FROM ed_free_text ft
                 ORDER BY dt_creation_tstz DESC, rank_component) z;
    
        OPEN o_entries FOR
            SELECT t.id_epis_documentation,
                   t.dt_creation_tstz,
                   t.template_title,
                   pk_utils.concat_table_clob(i_tab   => (CAST(MULTISET
                                                               (SELECT pk_string_utils.concat_if_exists_clob(f.desc_component,
                                                                                                              CASE
                                                                                                              -- Punctuation character at end of line
                                                                                                                  WHEN dbms_lob.getlength(f.plain_text_entry) = 0 THEN
                                                                                                                   empty_clob()
                                                                                                                  WHEN instr('!,.:;?',
                                                                                                                             substr(f.plain_text_entry, -1)) = 0 THEN
                                                                                                                   f.plain_text_entry || '.'
                                                                                                                  ELSE
                                                                                                                   f.plain_text_entry
                                                                                                              END,
                                                                                                              ': ')
                                                                  FROM TABLE(t_entries) f
                                                                 WHERE f.id_epis_documentation = t.id_epis_documentation
                                                                   AND rownum > 0
                                                                 ORDER BY id_epis_documentation) AS table_clob)),
                                              i_delim => chr(10)) plain_text_entry,
                   t.area_name
              FROM TABLE(t_entries) t
             GROUP BY id_epis_documentation, dt_creation_tstz, template_title, area_name
            
            ;
    
    END get_plain_text_entries;

    /**
    * Returns the content of a set of Touch-option documentation entry in plain-text format
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation        id_pis_documentation to retrieve
    * @param   i_use_html_format           Use HTML tags to format output. Default: No
    *
    * @return  The content of entry in plain text format
    *
    * @value   i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.7
    * @since   02-07-2013
    */
    FUNCTION get_plain_text_entry
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_use_html_format    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_plain_text_entry';
        l_lob                  CLOB;
        l_cur_plain_text_entry t_cur_plain_text_entry;
        l_rec_plain_text_entry t_rec_plain_text_entry;
    BEGIN
    
        get_plain_text_entries(i_lang                    => i_lang,
                               i_prof                    => i_prof,
                               i_epis_documentation_list => table_number(i_epis_documentation),
                               i_use_html_format         => i_use_html_format,
                               o_entries                 => l_cur_plain_text_entry);
    
        LOOP
            FETCH l_cur_plain_text_entry
                INTO l_rec_plain_text_entry;
            EXIT WHEN l_cur_plain_text_entry%NOTFOUND;
        
        END LOOP;
        CLOSE l_cur_plain_text_entry;
    
        RETURN l_rec_plain_text_entry.plain_text_entry;
    END get_plain_text_entry;
    /**
    * Get the ID of last active Touch-option entry documented in an area and scope using a specific template (optional)
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_doc_area           Documentation area ID
    * @param   i_doc_template       Touch-option template ID (Optional) Null = All templates
    * @param   o_last_epis_doc       Last documentation ID 
    * @param   o_last_date_epis_doc  Date of last epis documentation
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @catches 
    * @throws  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.5
    * @since   5/16/2013
    */

    FUNCTION get_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_last_doc_area';
        e_invalid_argument EXCEPTION;
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
        CURSOR c_last_epis_doc IS
            SELECT id_epis_documentation, dt_creation_tstz
              FROM (SELECT ed.id_epis_documentation,
                           ed.dt_creation_tstz,
                           row_number() over(PARTITION BY ed.id_episode ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                     INNER JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_doc_area = i_doc_area
                       AND (e.id_episode = nvl(l_episode, e.id_episode) OR
                           ed.id_episode_context = nvl(l_episode, ed.id_episode_context))
                       AND e.id_visit = nvl(l_visit, e.id_visit)
                       AND e.id_patient = l_patient
                          
                       AND (ed.id_doc_template = i_doc_template OR i_doc_template IS NULL)
                       AND ed.flg_status = pk_touch_option.g_epis_doc_active)
             WHERE rn = 1;
    
    BEGIN
        g_error := 'ANALYSING INPUT ARGUMENTS';
        IF i_doc_area IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'OPEN C_LAST_EPIS_DOC';
        OPEN c_last_epis_doc;
        FETCH c_last_epis_doc
            INTO o_last_epis_doc, o_last_date_epis_doc;
        CLOSE c_last_epis_doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'An input parameter has an unexpected value',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_last_doc_area;

    /**
    * Returns a documented element value in raw format according with the type of element:
    *         Date element: Returns a string that represents the date value at institution timezone
    *         Numeric elements: check if has an unit of measure related and then concatenate value with UOM ID
    *         Numeric elements with reference values: verifies that it has properties, then concatenate them
    *         Vital sign elements:  related id_vital_sign_read(s) saved in value_properties field are returned
    *
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_element_crit       Element criteria ID
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  A string with the element value in raw format 
    *    
    * @author  ARIEL.MACHADO
    * @version 2.6.3.7.2
    * @since   27-08-2013
    */
    FUNCTION get_unformatted_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_element_crit   IN doc_element_crit.id_doc_element_crit%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_unformatted_value';
        l_value VARCHAR2(32767);
        l_error t_error_out;
    BEGIN
    
        SELECT CASE de.flg_type
                   WHEN pk_touch_option.g_elem_flg_type_comp_date THEN
                   --For date elements display at timezone institution
                    pk_touch_option.get_date_value_insttimezone(i_lang, i_prof, edd.value, edd.value_properties)
                   WHEN pk_touch_option.g_elem_flg_type_comp_numeric THEN
                   --For numeric elements check if has an unit of measure related and then concatenate value with UOM ID
                    decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                   WHEN pk_touch_option.g_elem_flg_type_comp_ref_value THEN
                   --For numeric elements with reference values verifies that it has properties, then concatenate them
                    decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                   WHEN pk_touch_option.g_elem_flg_type_vital_sign THEN
                   -- For vital sign elements,  related id_vital_sign_read(s) saved in value_properties field are returned
                    edd.value_properties
                   ELSE
                    edd.value
               END VALUE
          INTO l_value
          FROM epis_documentation_det edd
         INNER JOIN doc_element de
            ON de.id_doc_element = edd.id_doc_element
         WHERE edd.id_epis_documentation = i_epis_documentation
           AND edd.id_doc_element_crit = i_doc_element_crit;
        RETURN l_value;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              l_error);
        
            RETURN NULL;
    END get_unformatted_value;

    /**
    * Returns true if a template is bilateral false otherwise
    *
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  Returns true if a template is bilateral false otherwise
    *    
    * @author  ARIEL.MACHADO
    * @version 2.6.4
    * @since   2014-11-05
    */
    FUNCTION has_layout(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE) RETURN VARCHAR2 IS
        k_function_name pk_types.t_internal_name_byte := 'has_layout';
        l_doc_template  doc_template.id_doc_template%TYPE;
        l_doc_area      doc_area.id_doc_area%TYPE;
        l_has_layout    VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_layout        CLOB;
    BEGIN
    
        BEGIN
            SELECT ed.id_doc_template, ed.id_doc_area
              INTO l_doc_template, l_doc_area
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = i_epis_documentation;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'Invalid i_epis_documentation: ' || to_char(i_epis_documentation);
                
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_argument',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name);
                    l_doc_template := NULL;
                END;
        END;
        IF l_doc_template IS NOT NULL
        THEN
            BEGIN
                SELECT xmlquery('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]' passing dt.template_layout AS "layout", CAST(l_doc_area AS NUMBER) AS "id_doc_area", CAST(l_doc_template AS NUMBER) AS "id_doc_template" RETURNING content).getclobval() layout
                  INTO l_layout
                  FROM doc_template dt
                 WHERE dt.id_doc_template = l_doc_template
                   AND xmlexists('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]'
                                 passing dt.template_layout AS "layout",
                                 CAST(l_doc_area AS NUMBER) AS "id_doc_area",
                                 CAST(l_doc_template AS NUMBER) AS "id_doc_template");
            
                IF dbms_lob.getlength(lob_loc => l_layout) > 0
                THEN
                    l_has_layout := pk_alert_constant.g_yes;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_has_layout := pk_alert_constant.g_no;
            END;
        
        END IF;
    
        RETURN l_has_layout;
    
    END has_layout;
    /**
    * Returns the id of the professional that created the template
    *
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  Returns id_prof
    *    
    * @author  Paulo Teixeira
    * @version 2.6.5
    * @since   2015-07-15
    */
    FUNCTION get_id_prof_create_ed(i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
        RETURN epis_documentation.id_professional%TYPE result_cache IS
    
        l_id_prof_create epis_documentation.id_professional%TYPE;
        l_id_ed_create   epis_documentation.id_epis_documentation%TYPE;
    
    BEGIN
    
        SELECT id_epis_documentation
          INTO l_id_ed_create
          FROM (SELECT ed.id_epis_documentation, id_epis_documentation_parent
                  FROM epis_documentation ed
                CONNECT BY nocycle ed.id_epis_documentation = PRIOR ed.id_epis_documentation_parent
                 START WITH ed.id_epis_documentation = i_id_epis_documentation) a
         WHERE a.id_epis_documentation_parent IS NULL;
    
        BEGIN
            SELECT ed.id_professional
              INTO l_id_prof_create
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = l_id_ed_create;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_prof_create := NULL;
        END;
    
        RETURN l_id_prof_create;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_prof_create_ed;

    FUNCTION get_dt_create_ed(i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
        RETURN epis_documentation.dt_creation_tstz%TYPE result_cache IS
    
        l_dt_create    epis_documentation.dt_creation_tstz%TYPE;
        l_id_ed_create epis_documentation.id_epis_documentation%TYPE;
    
    BEGIN
    
        SELECT id_epis_documentation
          INTO l_id_ed_create
          FROM (SELECT ed.id_epis_documentation, id_epis_documentation_parent
                  FROM epis_documentation ed
                CONNECT BY nocycle ed.id_epis_documentation = PRIOR ed.id_epis_documentation_parent
                 START WITH ed.id_epis_documentation = i_id_epis_documentation) a
         WHERE a.id_epis_documentation_parent IS NULL;
    
        BEGIN
            SELECT ed.dt_creation_tstz
              INTO l_dt_create
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = l_id_ed_create;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_create := NULL;
        END;
    
        RETURN l_dt_create;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_create_ed;
    /**
    * Returns the content of a set of Touch-option documentation entries in new format FOR screens AND reports
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation_list   id_pis_documentation to retrieve
    * @param   i_id_request                id of epis_hhc_request(this value is only for the reports)
    * @param   o_entries                   Cursor with the content of entries 
    *
    *
    * @author  Nuno Coelho
    * @version 2.8.1
    * @since   30-01-2020
    */
    PROCEDURE get_plain_text_entries_type
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_request            IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_flg_report            IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_entries               OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_plain_text_entries_type';
        l_error   t_error_out;
        t_entries t_tbl_plain_text_entry;
    
        l_entries_type t_coll_hhc_req_hist := t_coll_hhc_req_hist();
        l_header       VARCHAR2(400);
        l_flg_status   VARCHAR(1 CHAR);
        l_descr        sys_message.desc_message%TYPE;
    
    BEGIN
        g_error := 'Input arguments' || chr(10) || 'i_lang: ' || i_lang || ' institution:' || i_prof.institution ||
                   ' software:' || i_prof.software;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        g_error := 'Open cursor o_entries';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        -- Documentation entries
        WITH ed_entries AS
         (SELECT /*+ materialize */
           ed.id_epis_documentation,
           ed.dt_creation_tstz,
           ed.flg_status,
           ed.id_doc_area,
           ed.id_doc_template,
           regexp_replace(ed.notes, '\s+(' || chr(13) || chr(10) || '|$)', '') notes,
           pk_summary_page.get_doc_area_name(i_lang, i_prof.software, ed.id_doc_area) area_name
            FROM epis_documentation ed
           WHERE ed.id_epis_documentation = i_id_epis_documentation),
        
        -- Free-text entries
        ed_free_text AS
         (SELECT /*+ materialize */
           e.id_epis_documentation, e.dt_creation_tstz, e.notes, e.area_name
            FROM ed_entries e
           WHERE e.id_doc_template IS NULL
             AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
        
        -- Additional Notes for template entries
        ed_additional_notes AS
         (SELECT /*+ materialize */
           e.id_epis_documentation, e.notes
            FROM ed_entries e
           WHERE e.id_doc_template IS NOT NULL
             AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
        
        -- Lines of documentation entries (components)
        edd_lines AS
         (SELECT /*+ materialize */
          DISTINCT edd.id_epis_documentation,
                   edd.id_documentation,
                   dtad.rank rank_component,
                   dc.code_doc_component,
                   d.id_documentation_parent,
                   ed.id_doc_template,
                   ed.id_doc_area
            FROM epis_documentation ed
           INNER JOIN epis_documentation_det edd
              ON ed.id_epis_documentation = edd.id_epis_documentation
           INNER JOIN documentation d
              ON d.id_documentation = edd.id_documentation
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_template_area_doc dtad
              ON dtad.id_doc_template = ed.id_doc_template
             AND dtad.id_doc_area = ed.id_doc_area
             AND dtad.id_documentation = edd.id_documentation
           WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                FROM ed_entries t)),
        
        -- Lines of titles (Components of type "Title")
        edd_titles AS
         (SELECT /*+ materialize */
           t.id_epis_documentation, d.id_documentation, dc.code_doc_component, dtad.rank rank_component
            FROM (SELECT DISTINCT l.id_epis_documentation, l.id_documentation_parent, l.id_doc_area, l.id_doc_template
                    FROM edd_lines l
                   WHERE l.id_documentation_parent IS NOT NULL) t
           INNER JOIN documentation d
              ON d.id_documentation = t.id_documentation_parent
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_template_area_doc dtad
              ON dtad.id_doc_template = t.id_doc_template
             AND dtad.id_doc_area = t.id_doc_area
             AND dtad.id_documentation = t.id_documentation_parent
           WHERE dc.flg_type = pk_summary_page.g_doc_title
             AND dc.flg_available = pk_alert_constant.g_available
             AND d.flg_available = pk_alert_constant.g_available),
        
        -- Documented elements
        edd_elements AS
         (SELECT /*+ materialize */
           ed.id_epis_documentation,
           d.id_documentation,
           d.id_documentation_parent,
           dc.id_doc_component,
           dc.code_doc_component,
           de.id_doc_element,
           pk_touch_option.get_epis_formatted_element(i_lang,
                                                      i_prof,
                                                      edd.id_epis_documentation_det,
                                                      pk_alert_constant.g_no) desc_element,
           de.separator,
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
             AND dtad.id_documentation = edd.id_documentation
           INNER JOIN doc_component dc
              ON dc.id_doc_component = d.id_doc_component
           INNER JOIN doc_element_crit decr
              ON decr.id_doc_element_crit = edd.id_doc_element_crit
           INNER JOIN doc_element de
              ON de.id_doc_element = edd.id_doc_element
           WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                FROM ed_entries t)),
        -- Formated Touch-option template entries in plain text (titles + components: elements + additional notes)
        full_entries_as_text AS
         (SELECT x.id_epis_documentation,
                 x.id_documentation,
                 pk_translation.get_translation(i_lang, x.code_doc_component) desc_component,
                 pk_string_utils.concat_element_list_clob(CAST(MULTISET
                                                               (SELECT e.desc_element,
                                                                       CASE
                                                                            WHEN e.separator IS NULL THEN
                                                                             pk_touch_option.g_elem_separator_default
                                                                            WHEN e.separator =
                                                                                 pk_touch_option.g_elem_separator_none THEN
                                                                             NULL
                                                                            ELSE
                                                                             e.separator
                                                                        END delimiter
                                                                  FROM edd_elements e
                                                                 WHERE e.id_epis_documentation = x.id_epis_documentation
                                                                   AND e.id_documentation = x.id_documentation
                                                                 ORDER BY e.rank_element) AS t_coll_text_delimiter_tuple)) desc_element_list,
                 x.rank_component
            FROM edd_lines x
          -- Titles
          UNION ALL
          SELECT t.id_epis_documentation,
                 t.id_documentation,
                 pk_translation.get_translation(i_lang, t.code_doc_component) desc_component,
                 empty_clob() desc_element_list,
                 t.rank_component
            FROM edd_titles t
          
          UNION ALL
          -- Additional Notes
          SELECT an.id_epis_documentation,
                 NULL id_documentation,
                 pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010') desc_component,
                 an.notes desc_element_list,
                 999999999999 rank_component
            FROM ed_additional_notes an
           ORDER BY id_epis_documentation, rank_component)
        
        -- Main query:
        -- Touch-option entries
        SELECT g_rec_plain_text_entry(z.id_epis_documentation,
                                      z.dt_creation_tstz,
                                      z.template_title,
                                      z.desc_element_list,
                                      z.area_name,
                                      z.desc_component)
          BULK COLLECT
          INTO t_entries
          FROM (SELECT tot.id_epis_documentation,
                       e.dt_creation_tstz,
                       pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || e.id_doc_template) template_title,
                       tot.desc_element_list,
                       e.area_name,
                       tot.desc_component,
                       tot.rank_component
                  FROM full_entries_as_text tot
                 INNER JOIN ed_entries e
                    ON e.id_epis_documentation = tot.id_epis_documentation
                UNION ALL
                -- Free-text entries
                SELECT ft.id_epis_documentation,
                       ft.dt_creation_tstz,
                       NULL                     template_title,
                       ft.notes                 plain_text_entry,
                       ft.area_name,
                       NULL                     desc_component,
                       NULL                     rank_component
                  FROM ed_free_text ft
                UNION ALL
                SELECT tsl.id_epis_documentation,
                       tsl.dt_last_update_tstz   dt_creation_tstz,
                       NULL                      template_title,
                       NULL                      plain_text_entry,
                       NULL                      area_name,
                       tsl.doc_desc_class        desc_component,
                       100                       rank_component
                  FROM TABLE(pk_scales_core.tf_scales_list(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => i_id_patient,
                                                           i_epis_documentation => table_number(i_id_epis_documentation))) tsl
                 ORDER BY dt_creation_tstz DESC, rank_component) z;
    
        SELECT CASE ed.flg_status
                   WHEN pk_alert_constant.g_active THEN
                    pk_alert_constant.g_flg_status_report_a
                   ELSE
                    pk_alert_constant.g_flg_status_report_h
               END flg_status
          INTO l_flg_status
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = i_id_epis_documentation;
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
            l_descr := pk_message.get_message(i_lang, 'SOCIAL_T124');
            l_entries_type.extend;
            l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist(l_descr,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l0,
                                                                        pk_alert_constant.g_flg_status_report_h,
                                                                        i_id_request);
        
            l_descr := pk_message.get_message(i_lang, 'PROF_TEAMS_M007');
            l_entries_type.extend;
            l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist(l_descr,
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_l0,
                                                                        pk_alert_constant.g_flg_status_report_h,
                                                                        i_id_request);
        END IF;
    
        FOR r IN t_entries.first() .. t_entries.last()
        LOOP
            IF l_header IS NULL
            THEN
                l_header := t_entries(r).template_title;
                l_entries_type.extend;
                l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist(l_header,
                                                                            '',
                                                                            pk_alert_constant.g_flg_screen_l1,
                                                                            l_flg_status,
                                                                            i_id_request);
                --scores                                                            
                /*               l_entries_type.extend;
                l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist(NULL,
                                                                            t_entries(r).desc_component,
                                                                            pk_alert_constant.g_flg_screen_l1,
                                                                            l_flg_status,
                                                                            i_id_request);*/
            
            END IF;
            /* l_entries_type.extend;
            l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist('',
                                                                        '',
                                                                        pk_alert_constant.g_flg_screen_wl,
                                                                        l_flg_status,
                                                                        i_id_request);*/
            l_entries_type.extend;
            l_entries_type(l_entries_type.last()) := t_rec_hhc_req_hist(t_entries(r).desc_component,
                                                                        nvl(t_entries(r).plain_text_entry, ' '),
                                                                        pk_alert_constant.g_flg_screen_l2,
                                                                        l_flg_status,
                                                                        i_id_request);
        
        END LOOP;
		
        OPEN o_entries FOR
            SELECT t.descr, t.val, t.tipo AS flg_type, l_flg_status AS flg_status, id_request, pk_alert_constant.g_no flg_html, null val_clob, pk_alert_constant.g_no flg_clob
              FROM TABLE(l_entries_type) t;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => l_error);
            pk_types.open_my_cursor(o_entries);
    END get_plain_text_entries_type;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
END pk_touch_option_core;
/
