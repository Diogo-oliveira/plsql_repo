/*-- Last Change Revision: $Rev: 2052786 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-12 14:42:47 +0000 (seg, 12 dez 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_touch_option AS
    -- Private type declarations
    TYPE t_rec_value_properties IS RECORD(
        timezone_region      VARCHAR2(64),
        id_unit_measure      unit_measure.id_unit_measure%TYPE,
        flg_ref_op_min       doc_element.flg_ref_op_min%TYPE,
        ref_val_min          doc_element.ref_val_min%TYPE,
        flg_ref_op_max       doc_element.flg_ref_op_max%TYPE,
        ref_val_max          doc_element.ref_val_max%TYPE,
        vital_sign_read_list table_number);

    -- Private constant declarations

    --Format mask used by to_number(). Max representation: NUMBER(24.6)
    k_to_number_mask CONSTANT VARCHAR2(60) := '999999999999999999999999.999999';

    -- Translation prefix code_doc_template in DOC_TEMPLATE    
    k_code_doc_template CONSTANT translation.code_translation%TYPE := 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error         VARCHAR2(32767);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    PROCEDURE open_cur_doc_area_register(i_cursor IN OUT t_cur_doc_area_register) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL order_by_default,
                   NULL order_default,
                   NULL id_epis_documentation,
                   NULL PARENT,
                   NULL id_doc_template,
                   NULL template_desc,
                   NULL dt_creation,
                   NULL dt_creation_tstz,
                   NULL dt_register,
                   NULL id_professional,
                   NULL nick_name,
                   NULL desc_speciality,
                   NULL id_doc_area,
                   NULL flg_status,
                   NULL desc_status,
                   NULL id_episode,
                   NULL flg_current_episode,
                   NULL notes,
                   NULL dt_last_update,
                   NULL dt_last_update_tstz,
                   NULL flg_detail,
                   NULL flg_external,
                   NULL flg_type_register,
                   NULL flg_table_origin,
                   NULL flg_reviewed,
                   NULL id_prof_cancel,
                   NULL dt_cancel_tstz,
                   NULL id_cancel_reason,
                   NULL cancel_reason,
                   NULL cancel_notes,
                   NULL flg_edition_type,
                   NULL nick_name_prof_create,
                   NULL desc_speciality_prof_create,
                   NULL dt_clinical,
                   NULL dt_clinical_chr,
                   NULL signature
              FROM dual
             WHERE 1 = 0;
    END open_cur_doc_area_register;

    PROCEDURE open_cur_doc_area_val(i_cursor IN OUT t_cur_doc_area_val) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_epis_documentation,
                   NULL PARENT,
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   NULL dt_reg,
                   NULL desc_doc_component,
                   NULL flg_type,
                   NULL desc_element,
                   NULL desc_element_view,
                   NULL VALUE,
                   NULL flg_type_element,
                   NULL id_doc_area,
                   NULL rank_component,
                   NULL rank_element,
                   NULL internal_name,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                   NULL separator,
                   NULL flg_table_origin,
                   NULL flg_status,
                   NULL value_id,
                   NULL signature
              FROM dual
             WHERE 1 = 0;
    END open_cur_doc_area_val;

    /******************************************************************************************
    * Retrieves a list of default templates 
    *                                                                                                                                          
    * @param i_lang              Language ID                                                                                              
    * @param i_prof              Professional, software and institution ids
    * @param i_episode           Episode identifier
    * @param o_id_doc_template   Default template identifier
    * @param o_desc_doc_template Default template name
    * @param o_error             Error object
    *                                                                                                                                         
    * @return                    true (sucess), false (error)                                                        
    * 
    * @notes                     (only developed for the 'CT' flg_type)
    *                                                                                                                   
    * @author                    Sérgio Santos                                                                                    
    * @version                   2.5                                                                                                     
    * @since                     2009/06/18                                                                                               
    ********************************************************************************************/
    FUNCTION get_default_template
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_id_doc_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_doc_template OUT pk_translation.t_desc_translation,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_id_sch_event        sch_event.id_sch_event%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_doc_area_flg_type   default_template_cfg.flg_type%TYPE;
        l_id_department       department.id_department%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_pat_age             patient.age%TYPE;
        l_pat_gender          patient.gender%TYPE;
    BEGIN
        -- Get the id_clinical_service and id_sch_event from the episode and schedule
        g_error := 'GET CLINICAL SERVICE AND APPOINTMENT TYPE';
        SELECT e.id_clinical_service, s.id_sch_event, e.id_department, ei.id_dep_clin_serv
          INTO l_id_clinical_service, l_id_sch_event, l_id_department, l_id_dep_clin_serv
          FROM episode e
          JOIN epis_info ei
            ON ei.id_episode = e.id_episode
          LEFT JOIN schedule s
            ON s.id_schedule = ei.id_schedule
         WHERE e.id_episode = i_episode;
    
        -- Get the profissional id_profile_template
        g_error               := 'GET PROF_PROFILE_TEMPLATE';
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        -- Get patient age and gender
        SELECT p.gender, nvl(floor((SYSDATE - dt_birth) / 365), p.age)
          INTO l_pat_gender, l_pat_age
          FROM patient p
          JOIN episode e
            ON e.id_patient = p.id_patient
         WHERE e.id_episode = i_episode;
    
        -- Get the documentation flg_type
        g_error := 'GET DOCUMENTATION FLG_TYPE';
        BEGIN
            SELECT flg_type
              INTO l_doc_area_flg_type
              FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_prof.institution, i_prof.software))
             WHERE rownum <= 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_doc_area_flg_type := NULL;
        END;
    
        -- Get the default template (just one)
        CASE l_doc_area_flg_type
        
        -- Template by Complaint + Scheduled event (Used in Private-Practice by PK_COMPLAINT)
            WHEN g_flg_type_complaint_sch_evnt THEN
                g_error := 'GET DEAULT_TEMPLATE G_FLG_TYPE_COMPLAINT_SCH_EVNT';
                BEGIN
                    -- The template must be in the default template configurarion...
                    SELECT dta.id_doc_template, pk_translation.get_translation(i_lang, dta.code_doc_template)
                      INTO o_id_doc_template, o_desc_doc_template
                      FROM (SELECT dt.id_doc_template, dt.code_doc_template
                              FROM default_template_cfg dtcfg
                              JOIN doc_template dt
                                ON dt.id_doc_template = dtcfg.id_doc_template
                             WHERE dtcfg.id_software IN (0, i_prof.software)
                               AND dtcfg.id_institution IN (0, i_prof.institution)
                               AND dtcfg.id_profile_template IN (0, l_id_profile_template)
                               AND (dtcfg.id_clinical_service = l_id_clinical_service OR
                                   dtcfg.id_clinical_service IS NULL)
                               AND (dtcfg.id_department = l_id_department OR dtcfg.id_department IS NULL)
                               AND (dtcfg.id_sch_event = l_id_sch_event OR dtcfg.id_sch_event IS NULL)
                               AND (dtcfg.id_doc_area = i_doc_area OR dtcfg.id_doc_area IS NULL)
                               AND dtcfg.id_doc_template IN -- ...and must be parametrized in doc_template_context for the given professional
                                   (SELECT dt.id_doc_template
                                      FROM doc_template dt
                                      JOIN doc_template_context dtc
                                        ON dt.id_doc_template = dtc.id_doc_template
                                     WHERE dtc.id_doc_template = dtcfg.id_doc_template
                                       AND dtc.id_profile_template = l_id_profile_template
                                       AND (dtc.id_dep_clin_serv = l_id_dep_clin_serv OR l_id_dep_clin_serv IS NULL)
                                       AND (dtc.id_profile_template IS NULL OR
                                           dtc.id_profile_template = l_id_profile_template)
                                       AND dtc.flg_type = l_doc_area_flg_type
                                       AND dtc.id_software IN (0, i_prof.software)
                                       AND dtc.id_institution IN (0, i_prof.institution)
                                       AND dt.flg_available = g_available
                                       AND pk_patient.validate_pat_gender(l_pat_gender, dt.flg_gender) = 1
                                       AND (dt.age_min <= l_pat_gender OR dt.age_min IS NULL OR l_pat_gender IS NULL)
                                       AND (dt.age_max >= l_pat_age OR dt.age_max IS NULL OR l_pat_age IS NULL))
                             ORDER BY dtcfg.id_software         DESC,
                                      dtcfg.id_institution      DESC,
                                      dtcfg.id_profile_template DESC,
                                      dtcfg.id_clinical_service DESC,
                                      dtcfg.id_sch_event        DESC,
                                      dtcfg.id_department       DESC) dta
                     WHERE rownum <= 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_id_doc_template   := NULL;
                        o_desc_doc_template := NULL;
                END;
            ELSE
                o_id_doc_template   := NULL;
                o_desc_doc_template := NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DEFAULT_TEMPLATE');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_default_template;

    /*************************************************************************
    * Get E/M documentation guideline specified subject.                     *
    *                                                                        *
    * @param i_lang                Preferred language ID for this            *
    *                              professional                              *
    * @param i_prof                Object (professional ID,                  *
    *                              institution ID, software ID)              *
    * @param i_subject             Subject                                   *
    *                                                                        *
    * @return                      Documentation guideline                   *
    *                                                                        *
    * @author                      Gustavo Serrano                           *
    * @version                     2.6.1                                     *
    * @since                       08-Fev-2011                               *
    **************************************************************************/
    FUNCTION get_doc_guideline
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_subject OUT action.subject%TYPE
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_guideline';
        l_error t_error_out;
        co_cfg_em_guideline      CONSTANT sys_config.id_sys_config%TYPE := 'EM_DOC_GUIDELINE';
        co_cfg_em_guideline_none CONSTANT sys_config.value%TYPE := 'NONE';
    
    BEGIN
        g_error   := 'Fetch sys_config config - ' || co_cfg_em_guideline;
        o_subject := pk_sysconfig.get_config(i_code_cf => co_cfg_em_guideline, i_prof => i_prof);
    
        IF (o_subject IS NULL OR o_subject = co_cfg_em_guideline_none)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
        
            RETURN FALSE;
    END get_doc_guideline;

    /********************************************************************************************
    * Retrieves a list of templates satisfying the input criteria. 
    * This function must be the ONLY way to search parameterized templates on DOC_TEMPLATE_CONTEXT table.
    *                                                                                                                                          
    * @param i_lang              Language ID                                                                                              
    * @param i_prof              Professional, software and institution ids
    * @param i_gender            Patient gender
    * @param i_age               Patient age
    * @param i_flg_type          Templates context criterion (by Complaint,by Area, etc.)
    * @param i_context           Context value (Complaint ID, Area ID, etc.)
    * @param i_context_2         Aditional context value used by some context criteria. Default NULL (ignore value)
    * @param i_dep_clin_serv     Dep_clin_service used by some context criteria.  Default NULL (ignore value)
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_templates         Template list (id_doc_template, template_desc) sorted by template_desc
    * @param o_error             Error message
    *                                                                                                                                         
    * @return                    true (sucess), false (error)                                                        
    *                                                                                                                          
    * @author                    Ariel Geraldo Machado                                                                                    
    * @version                   1.0 (2.5)                                                                                                     
    * @since                     2009/04/17                                                                                               
    ********************************************************************************************/
    FUNCTION get_applicable_templates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_gender         IN patient.gender%TYPE,
        i_age            IN patient.age%TYPE,
        i_flg_type       IN doc_template_context.flg_type%TYPE,
        i_context        IN table_number,
        i_context_2      IN table_number DEFAULT NULL,
        i_dep_clin_serv  IN doc_template_context.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count   PLS_INTEGER;
        l_log_msg VARCHAR2(32767);
    
    BEGIN
        l_log_msg := 'Input parameters: ' || chr(10) || 'prof:' || i_prof.id || chr(10) || 'inst:' ||
                     i_prof.institution || chr(10) || 'soft:' || i_prof.software || chr(10) || 'i_gender:' || i_gender ||
                     chr(10) || 'i_age:' || i_age || chr(10) || 'i_flg_type:' || i_flg_type || chr(10) || 'i_context:' ||
                     pk_utils.concat_table(i_tab => i_context, i_delim => ',') || chr(10) || 'i_dep_clin_serv:' ||
                     i_dep_clin_serv;
        pk_alertlog.log_debug(l_log_msg, 'get_applicable_templates');
    
        g_error := 'GET COUNT';
        SELECT COUNT(*)
          INTO l_count
          FROM doc_template dt
         INNER JOIN doc_template_context dtc
            ON dt.id_doc_template = dtc.id_doc_template
          LEFT JOIN prof_profile_template ppt
            ON ppt.id_profile_template = dtc.id_profile_template -- dtc.id_profile_template may be null (= applicable to all profiles)
           AND ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
         WHERE dtc.id_context IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(i_context) t)
           AND (dtc.id_context_2 IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      *
                                       FROM TABLE(i_context_2) t) OR i_context_2 IS NULL)
           AND (dtc.id_context_2 IS NULL OR dtc.id_context_2 != 0) -- excludes a possible default template
           AND (dtc.id_dep_clin_serv IS NULL OR dtc.id_dep_clin_serv = i_dep_clin_serv OR i_dep_clin_serv IS NULL)
           AND (dtc.id_profile_template IS NULL OR dtc.id_profile_template = ppt.id_profile_template OR
               i_ignore_profile = pk_alert_constant.g_yes)
           AND dtc.flg_type = i_flg_type
           AND dtc.id_software IN (0, i_prof.software)
           AND dtc.id_institution IN (0, i_prof.institution)
           AND dt.flg_available = g_available
           AND pk_patient.validate_pat_gender(i_gender, dt.flg_gender) = 1
           AND (dt.age_min <= i_age OR dt.age_min IS NULL OR i_age IS NULL)
           AND (dt.age_max >= i_age OR dt.age_max IS NULL OR i_age IS NULL);
    
        --If no records returns a null cursor (avoids to do a fetch to know if it's empty)
        IF l_count > 0
        THEN
            g_error := 'GET APPLICABLE TEMPLATES';
            OPEN o_templates FOR
                SELECT DISTINCT dtc.id_doc_template,
                                pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc
                  FROM doc_template dt
                 INNER JOIN doc_template_context dtc
                    ON dt.id_doc_template = dtc.id_doc_template
                  LEFT JOIN prof_profile_template ppt
                    ON ppt.id_profile_template = dtc.id_profile_template -- dtc.id_profile_template may be null (= applicable to all profiles)
                   AND ppt.id_professional = i_prof.id
                   AND ppt.id_institution = i_prof.institution
                   AND ppt.id_software = i_prof.software
                 WHERE dtc.id_context IN (SELECT /*+opt_estimate (table t rows=1)*/
                                           *
                                            FROM TABLE(i_context) t)
                   AND (dtc.id_context_2 IN (SELECT /*+opt_estimate (table t rows=1)*/
                                              *
                                               FROM TABLE(i_context_2) t) OR i_context_2 IS NULL)
                   AND (dtc.id_context_2 IS NULL OR dtc.id_context_2 != 0) -- excludes a possible default template
                   AND (dtc.id_dep_clin_serv IS NULL OR dtc.id_dep_clin_serv = i_dep_clin_serv OR
                       i_dep_clin_serv IS NULL)
                   AND (dtc.id_profile_template IS NULL OR dtc.id_profile_template = ppt.id_profile_template OR
                       i_ignore_profile = pk_alert_constant.g_yes)
                   AND dtc.flg_type = i_flg_type
                   AND dtc.id_software IN (0, i_prof.software)
                   AND dtc.id_institution IN (0, i_prof.institution)
                   AND dt.flg_available = g_available
                   AND pk_patient.validate_pat_gender(i_gender, dt.flg_gender) = 1
                   AND (dt.age_min <= i_age OR dt.age_min IS NULL OR i_age IS NULL)
                   AND (dt.age_max >= i_age OR dt.age_max IS NULL OR i_age IS NULL)
                 ORDER BY template_desc;
        ELSE
            -- Does not exist records that satisfy the input criteria
            -- Trying obtain a default template (ID_CONTEXT_2 = 0)
            pk_alertlog.log_info('Does not exist records on DOC_TEMPLATE_CONTEXT table that satisfy the input criteria to choice a template. Trying obtain a default template',
                                 'get_applicable_templates');
        
            g_error := 'GET COUNT';
            SELECT COUNT(*)
              INTO l_count
              FROM doc_template dt
             INNER JOIN doc_template_context dtc
                ON dt.id_doc_template = dtc.id_doc_template
              LEFT JOIN prof_profile_template ppt
                ON ppt.id_profile_template = dtc.id_profile_template -- dtc.id_profile_template may be null (= applicable to all profiles)
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
             WHERE dtc.id_context IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(i_context) t)
               AND dtc.id_context_2 = 0 -- If ID_CONTEXT_2 is null then it's a default template for current criteria
               AND (dtc.id_dep_clin_serv IS NULL OR dtc.id_dep_clin_serv = i_dep_clin_serv OR i_dep_clin_serv IS NULL)
               AND (dtc.id_profile_template IS NULL OR dtc.id_profile_template = ppt.id_profile_template OR
                   i_ignore_profile = pk_alert_constant.g_yes)
               AND dtc.flg_type = i_flg_type
               AND dtc.id_software IN (0, i_prof.software)
               AND dtc.id_institution IN (0, i_prof.institution)
               AND dt.flg_available = g_available
               AND pk_patient.validate_pat_gender(i_gender, dt.flg_gender) = 1
               AND (dt.age_min <= i_age OR dt.age_min IS NULL OR i_age IS NULL)
               AND (dt.age_max >= i_age OR dt.age_max IS NULL OR i_age IS NULL);
        
            --If no records returns a null cursor (avoids to do a fetch to know if it's empty)
            IF l_count > 0
            THEN
                pk_alertlog.log_info('A default template was found for input criteria', 'get_applicable_templates');
                g_error := 'GET APPLICABLE TEMPLATES';
                OPEN o_templates FOR
                    SELECT DISTINCT dtc.id_doc_template,
                                    pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc
                      FROM doc_template dt
                     INNER JOIN doc_template_context dtc
                        ON dt.id_doc_template = dtc.id_doc_template
                      LEFT JOIN prof_profile_template ppt
                        ON ppt.id_profile_template = dtc.id_profile_template -- dtc.id_profile_template may be null (= applicable to all profiles)
                       AND ppt.id_professional = i_prof.id
                       AND ppt.id_institution = i_prof.institution
                       AND ppt.id_software = i_prof.software
                     WHERE dtc.id_context IN (SELECT /*+opt_estimate (table t rows=1)*/
                                               *
                                                FROM TABLE(i_context) t)
                       AND dtc.id_context_2 = 0 -- If ID_CONTEXT_2 is null then it's a default template for current criteria
                       AND (dtc.id_dep_clin_serv IS NULL OR dtc.id_dep_clin_serv = i_dep_clin_serv OR
                           i_dep_clin_serv IS NULL)
                       AND (dtc.id_profile_template IS NULL OR dtc.id_profile_template = ppt.id_profile_template OR
                           i_ignore_profile = pk_alert_constant.g_yes)
                       AND dtc.flg_type = i_flg_type
                       AND dtc.id_software IN (0, i_prof.software)
                       AND dtc.id_institution IN (0, i_prof.institution)
                       AND dt.flg_available = g_available
                       AND pk_patient.validate_pat_gender(i_gender, dt.flg_gender) = 1
                       AND (dt.age_min <= i_age OR dt.age_min IS NULL OR i_age IS NULL)
                       AND (dt.age_max >= i_age OR dt.age_max IS NULL OR i_age IS NULL)
                     ORDER BY template_desc;
            ELSE
                pk_alertlog.log_info('No default template was found for input criteria', 'get_applicable_templates');
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_APPLICABLE_TEMPLATES');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_applicable_templates;

    /********************************************************************************************
    * Returns a list of available doc templates for selection by appointment and doc_area (flg_type = DA)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          doc_area id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template list or null if not exist
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Ariel Machado
    * @version                   1.0   
    * @since                     2008/03/16
    ********************************************************************************************/
    FUNCTION get_doc_template_by_area_appnt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        i_gender         IN VARCHAR2,
        i_age            IN VARCHAR2,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_clin_serv IS
        -- When template by appointment, episode.clinical_service is associated to the appointment
        -- type of episode (Cardiology,etc.)
            SELECT e.id_clinical_service
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_id_clin_serv clinical_service.id_clinical_service%TYPE;
    
    BEGIN
        g_error := 'GET CLIN_SERV BY EPISODE';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv;
        CLOSE c_clin_serv;
    
        g_error := 'GET APPLICABLE_TEMPLATES BY AREA + APPOINTMENT';
        RETURN get_applicable_templates(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_gender         => i_gender,
                                        i_age            => i_age,
                                        i_flg_type       => g_flg_type_doc_area_appointmt,
                                        i_context        => table_number(i_doc_area),
                                        i_context_2      => table_number(l_id_clin_serv),
                                        i_ignore_profile => i_ignore_profile,
                                        o_templates      => o_templates,
                                        o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_AREA_APPNT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_area_appnt;

    /********************************************************************************************
    * Returns a list of available doc templates for selection by service and doc_area (flg_type = SA)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          doc_area id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Pedro Lopes
    * @version                   1.0   
    * @since                     2008/03/16
    ********************************************************************************************/
    FUNCTION get_doc_template_by_area_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        i_gender         IN VARCHAR2,
        i_age            IN VARCHAR2,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --PLLopes ALERT-23709
        --When template by Service, epis_info.id_dep_clin_serv is related to the current clin_service of an episode 
        CURSOR c_clin_serv IS
            SELECT dcs.id_clinical_service, dcs.id_dep_clin_serv
              FROM epis_info epo, dep_clin_serv dcs
             WHERE epo.id_episode = i_episode
               AND dcs.id_dep_clin_serv = epo.id_dep_clin_serv;
    
        l_id_clin_serv     clinical_service.id_clinical_service%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    BEGIN
    
        g_error := 'GET CLIN_SERV BY EPIS_INFO';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv, l_id_dep_clin_serv;
        CLOSE c_clin_serv;
    
        g_error := 'GET APPLICABLE_TEMPLATES BY AREA + CLINICAL SERVICE';
        RETURN get_applicable_templates(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_gender         => i_gender,
                                        i_age            => i_age,
                                        i_flg_type       => g_flg_type_doc_area_service,
                                        i_context        => table_number(i_doc_area),
                                        i_context_2      => table_number(l_id_clin_serv),
                                        i_dep_clin_serv  => l_id_dep_clin_serv,
                                        i_ignore_profile => i_ignore_profile,
                                        o_templates      => o_templates,
                                        o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_AREA_SERV');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_area_serv;

    /********************************************************************************************
    * Returns a list of available doc templates for selection by complaint and doc_area (flg_type = DC)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          doc_area id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template list or null if not exist
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Ariel Machado
    * @version                   1.0   
    * @since                     2008/03/16
    ********************************************************************************************/
    FUNCTION get_doc_template_by_area_cplnt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        i_gender         IN VARCHAR2,
        i_age            IN VARCHAR2,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_template_by_area_cplnt';
        function_call_excep EXCEPTION;
        l_complaint         table_number;
        l_comp_filter       sys_config.value%TYPE;
        l_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin_serv IS
            SELECT ei.id_dcs_requested
              FROM epis_info ei
             INNER JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE e.id_episode = i_episode;
    
    BEGIN
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
        --    
        g_error := 'GET_COMPLAINT';
        IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   o_id_complaint => l_complaint,
                                                   o_error        => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        IF (l_complaint IS NULL)
        THEN
            g_error := 'EPISODE HAS NO ACTIVE COMPLAINT';
            pk_alertlog.log_warn(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        END IF;
    
        IF l_comp_filter = pk_complaint.g_comp_filter_prf
        THEN
            -- Template by Complaint 
            g_error := 'GET APPLICABLE_TEMPLATES BY AREA + COMPLAINT';
            IF NOT get_applicable_templates(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_gender         => i_gender,
                                            i_age            => i_age,
                                            i_flg_type       => g_flg_type_doc_area_complaint,
                                            i_context        => table_number(i_doc_area),
                                            i_context_2      => l_complaint,
                                            i_ignore_profile => i_ignore_profile,
                                            o_templates      => o_templates,
                                            o_error          => o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        
        ELSIF l_comp_filter = pk_complaint.g_comp_filter_dcs
        THEN
            -- Template by Complaint and ID_DEP_CLIN_SERV
            g_error := 'OPEN C_DEP_CLIN_SERV';
            OPEN c_dep_clin_serv;
            FETCH c_dep_clin_serv
                INTO l_dep_clin_serv;
            CLOSE c_dep_clin_serv;
        
            g_error := 'GET APPLICABLE_TEMPLATES BY AREA + COMPLAINT (filtered by ID_DEP_CLIN_SERV)';
            IF NOT get_applicable_templates(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_gender         => i_gender,
                                            i_age            => i_age,
                                            i_flg_type       => g_flg_type_doc_area_complaint,
                                            i_context        => table_number(i_doc_area),
                                            i_context_2      => l_complaint,
                                            i_dep_clin_serv  => l_dep_clin_serv,
                                            i_ignore_profile => i_ignore_profile,
                                            o_templates      => o_templates,
                                            o_error          => o_error)
            
            THEN
                RAISE function_call_excep;
            END IF;
        
        ELSE
            g_error := 'NO SYS_CONFIG: COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software ||
                       ') DEFINED!';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            g_error := 'The call to function ' || g_error || ' returned an error ';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_doc_template_by_area_cplnt;

    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by current clinical service (flg_type = S)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Carlos Ferreira
    * @version                   1.0   
    * @since                     2007/09/20
    *
    * @changes
    * 2009/04/17(Ariel Machado) - Renamed function name to be more expressive
    ********************************************************************************************/
    FUNCTION get_doc_template_by_serv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_gender         IN VARCHAR2,
        i_age            IN VARCHAR2,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_clin_serv IS
            SELECT dcs.id_clinical_service, dcs.id_dep_clin_serv
              FROM epis_info epo, dep_clin_serv dcs
             WHERE epo.id_episode = i_episode
               AND dcs.id_dep_clin_serv = epo.id_dep_clin_serv;
    
        l_id_clin_serv     clinical_service.id_clinical_service%TYPE;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_context_2        table_number;
    BEGIN
        g_error := 'GET CLIN_SERV BY EPIS_INFO';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv, l_id_dep_clin_serv;
        CLOSE c_clin_serv;
    
        g_error     := 'CALL pk_progress_notes_upd.get_soap_note';
        l_context_2 := table_number(pk_progress_notes_upd.get_soap_note);
    
        IF l_context_2(l_context_2.first) IS NULL
        THEN
            l_context_2 := NULL;
        END IF;
    
        g_error := 'GET APPLICABLE_TEMPLATES BY CLINICAL SERVICE';
        RETURN get_applicable_templates(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_gender         => i_gender,
                                        i_age            => i_age,
                                        i_flg_type       => g_flg_type_clin_serv,
                                        i_context        => table_number(l_id_clin_serv),
                                        i_context_2      => l_context_2,
                                        i_dep_clin_serv  => l_id_dep_clin_serv,
                                        i_ignore_profile => i_ignore_profile,
                                        o_templates      => o_templates,
                                        o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_SERV');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_serv;
    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection by area + surgical procedure (flg_type = SP)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          doc_area id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template list or null if not exist
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Ariel Machado
    * @version                   2.5.0.6   
    * @since                     2009/09/01
    ********************************************************************************************/
    FUNCTION get_doc_template_by_area_surg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_surgical_procedures IS
            SELECT sri.id_sr_intervention
              FROM sr_epis_interv sri
             WHERE sri.id_episode_context = i_episode
               AND sri.flg_status != pk_alert_constant.g_interv_status_cancel
               AND sri.flg_code_type = pk_alert_constant.g_interv_code_type_coded;
    
        l_surgical_procedures table_number;
    
    BEGIN
        g_error := 'GET SURGICAL PROCEDURES BY EPISODE';
        OPEN c_surgical_procedures;
        FETCH c_surgical_procedures BULK COLLECT
            INTO l_surgical_procedures;
        CLOSE c_surgical_procedures;
    
        g_error := 'GET APPLICABLE_TEMPLATES BY AREA + SURGICAL PROCEDURE';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_doc_area_surg_proc,
                                        i_context   => table_number(i_doc_area),
                                        i_context_2 => l_surgical_procedures,
                                        o_templates => o_templates,
                                        o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_AREA_APPNT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_area_surg;
    --

    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by cipe.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_context           the context id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Nuno Neves
    * @version                   2.6.0.5  
    * @since                     2011/03/14
    ********************************************************************************************/
    FUNCTION get_doc_template_by_cipe
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET APPLICABLE_TEMPLATES BY CIPE';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_cipe,
                                        i_context   => table_number(i_context),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_CIPE');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_cipe;
    /**
    * Returns ID of last documentation done by a professional for a patient and scope
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           Patient ID          
    * @param i_visit             Visit ID   [Optional]
    * @param i_episode           Episode ID [Optional]
    * @param o_last_doc_det      Last id_epis_documentation_det of component
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   12/17/2010
    */
    FUNCTION get_last_epis_doc_prof
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_visit         IN visit.id_visit%TYPE DEFAULT NULL,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        g_error := 'GET LAST_DOC_DET';
        SELECT id_epis_documentation_det
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT /*+ opt_estimate(table t rows=1) */
                 edd.id_epis_documentation_det, row_number() over(ORDER BY edd.dt_creation_tstz DESC) rn
                  FROM epis_documentation ed
                  JOIN epis_documentation_det edd
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  JOIN TABLE(tf_epis_documentation(i_lang, i_prof, i_patient, i_episode, i_visit)) t
                    ON t.id_episode = ed.id_episode
                 WHERE edd.id_documentation = i_documentation
                   AND edd.id_professional = i_prof.id
                   AND edd.dt_creation_tstz IS NOT NULL
                   AND t.ed_flg_status != g_canceled)
         WHERE rn = 1;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        o_last_doc_det := l_return;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_LAST_EPIS_DOC_PROF');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_last_epis_doc_prof;

    /********************************************************************************************
    * Indica para uma dada doc_area se se usa interacção texto liver, ou documentation
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_id_doc_area          id da doc_area
    * @param o_flg_mode             flag com valores possivel D (documentation) ou N (texto livre)
    * @param o_flg_switch_mode      flag com valores possivel Y (Alternância entre touch option e free text) 
                                                              N (Não há alternância entre touch option e free text)
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    * 
    * @author                       João Eiras
    * @version                      1.0   
    * @since                        23-05-2007
    ********************************************************************************************/
    FUNCTION get_touch_option_mode
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        o_flg_mode        OUT VARCHAR2,
        o_flg_switch_mode OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_mode_prof doc_area_inst_soft.flg_mode%TYPE;
        l_flg_mode_inst doc_area_inst_soft.flg_mode%TYPE;
        --
        CURSOR c_flg_mode_prof IS
            SELECT flg_mode
              FROM doc_area_inst_soft_prof
             WHERE id_doc_area = i_doc_area
               AND id_institution = i_prof.institution
               AND id_software = i_prof.software
               AND id_professional = i_prof.id
             ORDER BY id_institution DESC;
    
        CURSOR c_flg_mode_inst IS
            SELECT flg_mode, flg_switch_mode
              FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_prof.institution, i_prof.software));
    
    BEGIN
        g_error := 'OPEN C_FLG_MODE_PROF';
        OPEN c_flg_mode_prof;
        FETCH c_flg_mode_prof
            INTO l_flg_mode_prof;
        CLOSE c_flg_mode_prof;
        --
        g_error := 'OPEN C_FLG_MODE_INST';
        OPEN c_flg_mode_inst;
        FETCH c_flg_mode_inst
            INTO l_flg_mode_inst, o_flg_switch_mode;
        CLOSE c_flg_mode_inst;
        --
        --1º Flg mode associada ao profissional
        IF o_flg_mode IS NULL
           AND l_flg_mode_prof IS NOT NULL
        THEN
            o_flg_mode := l_flg_mode_prof;
        END IF;
        --  
        --2º Flg mode associada à instituição
        IF o_flg_mode IS NULL
           AND l_flg_mode_inst IS NOT NULL
        THEN
            o_flg_mode := l_flg_mode_inst;
        END IF;
        --
        --3º Flg mode não associada nem à instituição nem ao profissonal
        IF o_flg_mode IS NULL
        THEN
            g_error    := 'GET CONFIG - DOCUMENTATION_TEXT';
            o_flg_mode := pk_sysconfig.get_config('DOCUMENTATION_TEXT', i_prof);
        END IF;
        --
        --4º Switch não está parametrizado, por defeito assume o valor 'N'
        IF o_flg_switch_mode IS NULL
        THEN
            o_flg_switch_mode := g_no;
        END IF;
        --
        --5º Flg mode não está associada        
        IF o_flg_mode IS NULL
        THEN
            g_error := 'GET CONFIG - DOCUMENTATION_TEXT MISSING';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_TOUCH_OPTION_MODE');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END;
    --
    /********************************************************************************************
    * Devolve a lista de doc_area a que este profissional tem acesso, 
      mediante software e instituição, e os respectivos valores das preferencias do
      metodo de input (documentation ou texto livre)
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_institution          id da instituição de onde se le a preferencia
    * @param i_software             id do software onde é apresentada a doc_area
    * @param o_options              cursor com doc_areas e preferencias    
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    *
    * @author                       João Eiras
    * @version                      1.0   
    * @since                        24-05-2007
    ********************************************************************************************/
    FUNCTION get_prof_touch_options_mode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_profile_template profile_template.id_profile_template%TYPE;
        k_summary_page_ph       summary_page.id_summary_page%TYPE := 2;
    
    BEGIN
    
        g_error                 := 'GET PROFILE TEMPLATE';
        l_prof_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'OPEN O_OPTIONS';
        OPEN o_options FOR
            SELECT da.id_doc_area,
                   pk_summary_page.get_doc_area_name(i_lang, i_software, da.id_doc_area) desc_doc_area,
                   
                   pk_summary_page.get_doc_area_name(i_lang, i_software, da.id_doc_area, pk_alert_constant.g_yes) abbr_doc_area,
                   coalesce(daisp.flg_mode, dais.flg_mode, 'P') flg_mode
              FROM doc_area da
              JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_institution, i_software)) dais
                ON da.id_doc_area = dais.id_doc_area
               AND dais.id_institution = i_institution
               AND dais.id_software = i_software
              LEFT JOIN doc_area_inst_soft_prof daisp
                ON daisp.id_doc_area = da.id_doc_area
               AND daisp.id_professional = i_prof.id
               AND daisp.id_institution = i_institution
               AND daisp.id_software = i_software
             WHERE da.flg_available = pk_alert_constant.g_yes
               AND dais.flg_switch_mode = pk_alert_constant.g_yes
               AND EXISTS (SELECT 0
                      FROM summary_page sp
                      JOIN summary_page_section sps
                        ON sp.id_summary_page = sps.id_summary_page
                      JOIN summary_page_access spa
                        ON sps.id_summary_page_section = spa.id_summary_page_section
                     WHERE da.id_doc_area = sps.id_doc_area
                       AND spa.id_profile_template = l_prof_profile_template
                       AND sp.flg_access = pk_alert_constant.g_yes
                       AND spa.flg_write = pk_alert_constant.g_yes
                       AND sp.id_summary_page <> k_summary_page_ph
                    UNION ALL
                    SELECT 0
                      FROM summary_page sp
                      JOIN summary_page_section sps
                        ON sp.id_summary_page = sps.id_summary_page
                     WHERE da.id_doc_area = sps.id_doc_area
                       AND sp.flg_access = pk_alert_constant.g_no)
             ORDER BY desc_doc_area;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                pk_types.open_my_cursor(o_options);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROF_TOUCH_OPTIONS_MODE');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_prof_touch_options_mode;
    --
    /********************************************************************************************
    * Guarda as preferencias do metodo de input preferido do profissional para um conjunto de doc areas, mediante software e instituição.
      Utilizado no backoffice do utilizador
    *
    * @param i_lang           id da lingua
    * @param i_prof           objecto com info do utilizador
    * @param i_institution    id da instituição de onde se le a preferencia
    * @param i_software       id do software onde é apresentada a doc_area
    * @param i_doc_areas      table_number com ids das doc_areas
    * @param i_flg_modes      table_varchar com metodo de input preferido para a respectiva doc_area    
    * @param o_error          Error message
    *                        
    * @return                 true or false on success or error
    *
    * @author                 João Eiras
    * @version                1.0   
    * @since                  24-05-2007
    ********************************************************************************************/
    FUNCTION set_prof_touch_options_mode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institutions IN table_number,
        i_softwares    IN table_number,
        i_doc_areas    IN table_number,
        i_flg_modes    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'MERGE STUFF';
        FORALL idx IN 1 .. i_doc_areas.count
            MERGE INTO doc_area_inst_soft_prof da
            USING (SELECT i_institutions(idx) id_institution,
                          i_softwares(idx) id_software,
                          i_doc_areas(idx) id_doc_area,
                          i_flg_modes(idx) flg_mode,
                          i_prof.id id_professional
                     FROM dual) db
            ON (da.id_doc_area = db.id_doc_area AND da.id_professional = db.id_professional AND da.id_institution = db.id_institution AND da.id_software = db.id_software)
            WHEN MATCHED THEN
                UPDATE
                   SET flg_mode = db.flg_mode
            WHEN NOT MATCHED THEN
                INSERT
                    (id_doc_area_inst_soft_prof, id_doc_area, id_professional, id_institution, id_software, flg_mode)
                VALUES
                    (seq_doc_area_inst_soft_prof.nextval,
                     db.id_doc_area,
                     db.id_professional,
                     db.id_institution,
                     db.id_software,
                     db.flg_mode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_PROF_TOUCH_OPTIONS_MODE');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Rollback changes */
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_prof_touch_options_mode;
    --
    /********************************************************************************************
    * Indica se um profissional fez registos numa dada doc_area num dado episódio no caso afirmativo, 
      devolve a última documentation
    *
    * @param i_lang                id da lingua
    * @param i_prof                utilizador autenticado
    * @param i_episode             id do episódio 
    * @param i_doc_area            id da doc_area da qual se verificam se foram feitos registos
    * @param o_last_prof_epis_doc  Last documentation episode ID to profissional
    * @param o_date_last_epis      Data do último episódio
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @autor
    * @version                     1.0
    * @since
    **********************************************************************************************/
    FUNCTION get_prof_doc_area_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis     OUT epis_documentation.dt_creation_tstz%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit   visit.id_visit%TYPE;
        l_episode episode.id_episode%TYPE;
    
        CURSOR c_last_epis_doc IS
            SELECT id_epis_documentation, dt_creation_tstz
              FROM (SELECT ed.id_epis_documentation,
                           ed.dt_creation_tstz,
                           row_number() over(ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ((l_episode IS NOT NULL AND ed.id_episode = l_episode) OR l_episode IS NULL)
                       AND ((l_visit IS NOT NULL AND e.id_visit = l_visit) OR l_visit IS NULL)
                       AND ed.id_doc_area = i_doc_area
                       AND ed.id_professional = i_prof.id
                       AND ed.flg_status = g_epis_doc_active
                       AND ed.dt_creation_tstz IS NOT NULL
                          -- Do not return reasons for not filling questionaires
                       AND ed.flg_edition_type <> 'X')
             WHERE rn = 1;
    
    BEGIN
    
        l_episode := i_episode;
    
        -- documentation per visit
        IF i_doc_area = g_doc_area_pat_belong
        THEN
            g_error := 'GET ID_VISIT';
            l_visit := pk_episode.get_id_visit(i_episode);
        
            l_episode := NULL;
        END IF;
    
        g_error := 'OPEN C_LAST_EPIS_DOC';
        OPEN c_last_epis_doc;
        FETCH c_last_epis_doc
            INTO o_last_prof_epis_doc, o_date_last_epis;
    
        IF c_last_epis_doc%FOUND
        THEN
            o_flg_data := g_yes;
        ELSE
            o_flg_data := g_no;
        END IF;
        CLOSE c_last_epis_doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_PROF_DOC_AREA_EXISTS');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_prof_doc_area_exists;

    /**
    * Checks if at least one of a set of areas has entries according an input scope.
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_doc_area_list List of documentation area IDs
    * @param   i_scope         Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type    Scope type (by episode; by visit; by patient)
    * @param   o_flg_data      There exists entries (Y/N)
    * @param   o_error         Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    * @value o_flg_data {*} (Y) There are entries {*} (N) There are no entries
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   12/6/2010
    */
    FUNCTION get_doc_area_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area_list IN table_number,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2 DEFAULT 'E',
        o_flg_data      OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_exists';
        l_exists  VARCHAR2(1 CHAR);
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    
    BEGIN
        l_exists := pk_alert_constant.g_no;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT get_scope_vars(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_scope      => i_scope,
                              i_scope_type => i_scope_type,
                              o_patient    => l_patient,
                              o_visit      => l_visit,
                              o_episode    => l_episode,
                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Check entries done in Touch-option model
        BEGIN
            g_error := 'Entries done in EPIS_DOCUMENTATION';
            SELECT pk_alert_constant.g_yes
              INTO l_exists
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=10)*/
                                               t.column_value
                                                FROM TABLE(i_doc_area_list) t)
                       AND e.id_episode = l_episode
                       AND i_scope_type = pk_alert_constant.g_scope_type_episode
                    UNION ALL
                    SELECT 1
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=10)*/
                                               t.column_value
                                                FROM TABLE(i_doc_area_list) t)
                       AND e.id_visit = l_visit
                       AND i_scope_type = pk_alert_constant.g_scope_type_visit
                    UNION ALL
                    SELECT 1
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=10)*/
                                               t.column_value
                                                FROM TABLE(i_doc_area_list) t)
                       AND e.id_patient = l_patient
                       AND i_scope_type = pk_alert_constant.g_scope_type_patient);
        EXCEPTION
            WHEN no_data_found THEN
                l_exists := pk_alert_constant.g_no;
        END;
    
        IF l_exists = pk_alert_constant.g_no
           AND pk_summary_page.g_doc_area_hist_ill MEMBER OF i_doc_area_list
        THEN
            --Check free-text entries in HPI area that were done out of Touch-option model (Old free-text entries) 
            -- + Free text entries for Subjective from Progress Notes(SOAP)
            BEGIN
                g_error := 'HPI entries done in EPIS_ANAMNESIS';
                SELECT pk_alert_constant.g_yes
                  INTO l_exists
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient)
                    OR EXISTS (SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := pk_alert_constant.g_no;
            END;
        END IF;
    
        IF l_exists = pk_alert_constant.g_no
           AND pk_summary_page.g_doc_area_complaint MEMBER OF i_doc_area_list
        THEN
            --Check free-text entries in Complaint area that were done out of Touch-option model (Old free-text entries)
            BEGIN
                g_error := 'Complaint entries done in EPIS_ANAMNESIS';
                SELECT pk_alert_constant.g_yes
                  INTO l_exists
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_anamnesis ea
                          JOIN episode e
                            ON e.id_episode = ea.id_episode
                         WHERE ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := pk_alert_constant.g_no;
            END;
        END IF;
    
        IF l_exists = pk_alert_constant.g_no
           AND pk_summary_page.g_doc_area_rev_sys MEMBER OF i_doc_area_list
        THEN
            --Check free-text entries for Review of System area that were done out of Touch-option model (Old free-text entries)
            BEGIN
                g_error := 'RoS entries done in EPIS_REVIEW_SYSTEMS';
                SELECT pk_alert_constant.g_yes
                  INTO l_exists
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM epis_review_systems ers
                          JOIN episode e
                            ON e.id_episode = ers.id_episode
                         WHERE e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_review_systems ers
                          JOIN episode e
                            ON e.id_episode = ers.id_episode
                         WHERE e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_review_systems ers
                          JOIN episode e
                            ON e.id_episode = ers.id_episode
                         WHERE e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := pk_alert_constant.g_no;
            END;
        END IF;
    
        IF l_exists = pk_alert_constant.g_no
           AND pk_summary_page.g_doc_area_phy_exam MEMBER OF i_doc_area_list
        THEN
            --Check free-text entries for Physical Exam area that were done out of Touch-option model (Old free-text entries)  
            -- + Free text entries for Objective from Progress Notes(SOAP)
            BEGIN
                g_error := 'PE entries done in EPIS_OBSERVATION + Objective(SOAP) entries done in EPIS_RECOMEND';
                SELECT pk_alert_constant.g_yes
                  INTO l_exists
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM epis_observation eo
                          JOIN episode e
                            ON e.id_episode = eo.id_episode
                         WHERE eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_observation eo
                          JOIN episode e
                            ON e.id_episode = eo.id_episode
                         WHERE eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_observation eo
                          JOIN episode e
                            ON e.id_episode = eo.id_episode
                         WHERE eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient)
                    OR EXISTS (SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := pk_alert_constant.g_no;
            END;
        END IF;
    
        IF l_exists = pk_alert_constant.g_no
           AND pk_summary_page.g_doc_area_nursing_notes MEMBER OF i_doc_area_list
        THEN
            --Check free-text entries for Nursing Notes(EDIS/PP/OUTP/CARE/ORIS) that were done out of Touch-option model (Old free-text entries)
            BEGIN
                g_error := 'Nursing Notes done in EPIS_RECOMEND';
                SELECT pk_alert_constant.g_yes
                  INTO l_exists
                  FROM dual
                 WHERE EXISTS (SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = 'N'
                           AND e.id_episode = l_episode
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = 'N'
                           AND e.id_visit = l_visit
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        SELECT 1
                          FROM epis_recomend er
                          JOIN episode e
                            ON e.id_episode = er.id_episode
                         WHERE er.flg_type = 'N'
                           AND e.id_patient = l_patient
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient);
            EXCEPTION
                WHEN no_data_found THEN
                    l_exists := pk_alert_constant.g_no;
            END;
        END IF;
    
        o_flg_data := l_exists;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, l_function_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_area_exists;

    --
    /********************************************************************************************
    * Checks if a doc area has registers by an episode / patient.
    *
    * @param i_lang            language id
    * @param i_prof            professional, software and institution ids
    * @param i_episode         episode id 
    * @param i_doc_area        doc area id 
    * @param i_patient         [Optional] patient id (default NULL)
    * @param i_flg_by          [Optional] check by Episode / Patient
    * @param o_flg_data        Y if there are data, F when no date found
    * @param o_error           Error message
    *
    * @value i_flg_by          {*} 'E' - Check by episode (default) {*} 'P' - Check by patient                        
    *
    * @return                  true or false on success or error
    *
    * @author                  Luís Gaspar 
    * @version                 1.0                    
    * @since                   24-05-2007
    *
    * Changes:
    *
    * @author                  Ariel Machado 
    * @version                 2.4.3                    
    * @since                   15-07-2008
    * reason                   Filter by episode/patient. Added i_patient and i_flg_by 
    * @Deprecated : get_doc_area_exists (with i_scope_type) should be used instead.
    **********************************************************************************************/
    FUNCTION get_doc_area_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_by   IN VARCHAR2 DEFAULT 'E',
        o_flg_data OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_scope      NUMBER;
        l_scope_type VARCHAR2(1 CHAR);
    
    BEGIN
    
        IF i_flg_by = pk_alert_constant.g_scope_type_episode
        THEN
            l_scope      := i_episode;
            l_scope_type := pk_alert_constant.g_scope_type_episode;
        
        ELSIF i_flg_by = pk_alert_constant.g_scope_type_patient
        THEN
            l_scope      := i_patient;
            l_scope_type := pk_alert_constant.g_scope_type_patient;
        ELSE
            g_error := 'INVALID PARAMETER VALUE IN i_flg_by';
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_doc_area_exists (with i_scope)';
        RETURN get_doc_area_exists(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_doc_area_list => table_number(i_doc_area),
                                   i_scope         => l_scope,
                                   i_scope_type    => l_scope_type,
                                   o_flg_data      => o_flg_data,
                                   o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_AREA_EXISTS');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_area_exists;
    --
    /********************************************************************************************
    * Lists doc_components, doc_elements, doc_element_crits, actions ,relations between them
      in order, doc_element_qualif and doc_qualif_rel to build a screen representing part (doc_area) of a template (doc_template).
    *
    * @param i_lang                      language id
    * @param i_prof                      professional, software and institution ids
    * @param i_patient                   the patient id
    * @param i_episode                   the episode id
    * @param i_doc_area                  doc_area id
    * @param i_doc_template              doc_template id
    * @param o_component                 cursor with the components info
    * @param o_element                   cursor with elements info
    * @param o_element_status            cursor with element status info
    * @param o_element_action            cursor with elements status actions (by criteria)
    * @param o_element_exclusive         cursor with elements relations
    * @param o_element_qualif            cursor with elements qualification
    * @param o_element_qualif_exclusive  cursor with elements qualification relations        
    * @param o_element_domain            cursor with elements domain (case flg_element_domain_type is S-sys_domain or T-element_domain)
    * @param o_element_function_param    cursor with elements function params (case flg_element_domain_type is D has have parameters)
    * @param o_element_related_actions   cursor with actions between elements (by elements)
    * @param o_template_layout           cursor with XML layout to be applied
    * @param o_template_actions_menu     cursor with the menu to apply into Action button
    * @param o_vs_info                   cursor with vital sign-related information
    * @param o_element_crit_interval     cursor with value intervals of an element and associated description to be used instead of its description
    * @param o_error                     Error message
    *                        
    * @return                            true or false on success or error
    *
    * @author                            Luís Gaspar e Luís Oliveira, based on pk_documentation.get_component_list
    * @version                           1.0    
    * @since                             26-05-2007
    *
    * @author alter                      Emilia Taborda 
    * @since                             2007/08/29
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/19
    *                             Element domain and function parameters. New fields for component/element fill behavior;
    *
    *                             Ariel Machado
    *                             1.2   
    *                             2009/03/18
    *                             Template layout and actions between elements
    **********************************************************************************************/
    FUNCTION get_component_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_episode                  IN episode.id_episode%TYPE,
        i_doc_area                 IN doc_area.id_doc_area%TYPE,
        i_doc_template             IN doc_template.id_doc_template%TYPE,
        o_component                OUT pk_types.cursor_type,
        o_component_action         OUT pk_types.cursor_type,
        o_element                  OUT pk_types.cursor_type,
        o_element_status           OUT pk_types.cursor_type,
        o_element_action           OUT pk_types.cursor_type,
        o_element_exclusive        OUT pk_types.cursor_type,
        o_element_qualif           OUT pk_types.cursor_type,
        o_element_qualif_exclusive OUT pk_types.cursor_type,
        o_element_domain           OUT pk_types.cursor_type,
        o_element_function_param   OUT pk_types.cursor_type,
        o_element_related_actions  OUT pk_types.cursor_type,
        o_template_layout          OUT pk_types.cursor_type,
        o_template_actions_menu    OUT pk_types.cursor_type,
        o_vs_info                  OUT pk_types.cursor_type,
        o_element_crit_interval    OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_gender      patient.gender%TYPE;
        l_age         patient.age%TYPE;
        l_subject     action.subject%TYPE;
        l_lst_vs      table_number;
        l_lst_aux_vs  table_number;
        l_lst_conf_vs table_number;
        --
        l_flg_show_previous_values doc_template_context.flg_show_previous_values%TYPE;
        l_hash_vital_sign          table_table_varchar;
    BEGIN
        g_error := 'CALLING GET_PAT_INFO_BY_PATIENT';
        IF NOT pk_patient.get_pat_info_by_patient(i_lang, i_patient, l_gender, l_age)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_gender IS NULL
        THEN
            l_gender := pk_touch_option.g_gender_i;
        END IF;
    
        --
        g_error := 'GET CURSOR O_COMPONENT';
        --Notice: Using scalar subqueries in each call of get_translation for performance improvement (SELECT pk.get_translation FROM dual)
        OPEN o_component FOR
            SELECT id_documentation,
                   id_doc_component,
                   desc_doc_component,
                   flg_type,
                   flg_behavior,
                   x_position,
                   height,
                   width,
                   element_external_width,
                   flg_enabled,
                   viewer_screen,
                   leaf_sys_button,
                   id_documentation_parent,
                   rank
              FROM (SELECT d.id_documentation,
                           dcomp.id_doc_component,
                           (SELECT pk_translation.get_translation(i_lang, dcomp.code_doc_component)
                              FROM dual) desc_doc_component,
                           dcomp.flg_type,
                           nvl(dcomp.flg_behavior, pk_alert_constant.g_no) flg_behavior, --Default: 'N'-Normal
                           dd.x_position,
                           dd.height,
                           dd.width,
                           -- external element dimension
                           nvl((SELECT SUM(dd1.width)
                                 FROM doc_element de, doc_dimension dd1
                                WHERE de.id_documentation = d.id_documentation
                                  AND de.position = pk_touch_option.g_position_out
                                  AND de.flg_available = pk_alert_constant.g_available
                                  AND dd1.id_doc_dimension = de.id_doc_dimension),
                               0) element_external_width,
                           d.flg_enabled,
                           d.viewer_screen,
                           d.leaf_sys_button,
                           d.id_documentation_parent,
                           dtad.rank
                      FROM doc_template_area_doc dtad
                     INNER JOIN documentation d
                        ON dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dcomp
                        ON dcomp.id_doc_component = d.id_doc_component
                     INNER JOIN doc_dimension dd
                        ON d.id_doc_dimension = dd.id_doc_dimension
                     WHERE dtad.id_doc_template = i_doc_template
                       AND dtad.id_doc_area = i_doc_area
                          -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
                       AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
                       AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
                       AND d.flg_available = pk_alert_constant.g_available
                       AND dcomp.flg_available = pk_alert_constant.g_available
                       AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR
                           l_gender = pk_touch_option.g_gender_i)
                       AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR
                           l_age IS NULL)
                     ORDER BY dtad.rank)
             ORDER BY rank,
                      regexp_substr(desc_doc_component, '^\D*') NULLS FIRST,
                      to_number(regexp_substr(desc_doc_component, '\d+'));
        -- Get vital sign IDs that are referenced by elements of this template
        g_error := 'CALLING GET_TEMPLATE_VS_LIST';
    
        IF NOT pk_touch_option_ti.get_template_vs_list(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_doc_area        => i_doc_area,
                                                       i_doc_template    => i_doc_template,
                                                       i_pat_gender      => l_gender,
                                                       i_pat_age         => l_age,
                                                       i_flg_view        => NULL,
                                                       o_lst_vs          => l_lst_vs,
                                                       o_lst_aux_vs      => l_lst_aux_vs,
                                                       o_lst_conf_vs     => l_lst_conf_vs,
                                                       o_hash_vital_sign => l_hash_vital_sign,
                                                       o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        g_error := 'GET CURSOR O_ELEMENT';
        OPEN o_element FOR
            SELECT id_documentation,
                   id_doc_component,
                   id_doc_element,
                   id_master_item,
                   position,
                   height,
                   width,
                   flg_type,
                   flg_behavior,
                   flg_optional_value,
                   code_element_domain,
                   flg_element_domain_type,
                   display_format,
                   separator,
                   max_value,
                   min_value,
                   format_num,
                   id_unit_measure_type,
                   id_unit_measure_subtype,
                   id_unit_measure_reference,
                   ref_val_min,
                   ref_val_max,
                   flg_ref_op_min,
                   flg_ref_op_max,
                   id_master_item_aux
              FROM (SELECT d.id_documentation,
                           dcomp.id_doc_component,
                           de.id_doc_element,
                           de.id_master_item,
                           de.id_master_item_aux,
                           de.position,
                           dd.height,
                           dd.width,
                           de.flg_type,
                           nvl(de.flg_behavior, pk_alert_constant.g_no) flg_behavior,
                           nvl(de.flg_optional_value, pk_alert_constant.g_no) flg_optional_value,
                           de.code_element_domain,
                           de.flg_element_domain_type,
                           (SELECT pk_touch_option_ti.get_element_description(i_lang,
                                                                              i_prof,
                                                                              de.flg_type,
                                                                              de.id_master_item,
                                                                              decr.code_element_open)
                              FROM doc_element_crit decr
                             INNER JOIN doc_criteria dcr
                                ON decr.id_doc_criteria = dcr.id_doc_criteria
                             WHERE decr.id_doc_element = de.id_doc_element
                               AND decr.flg_available = pk_alert_constant.g_available
                               AND dcr.flg_available = pk_alert_constant.g_available
                               AND dcr.flg_criteria = pk_alert_constant.g_doccrit_flg_crit_initial) element_open,
                           dtad.rank doc_rank,
                           de.rank doc_element_rank,
                           de.display_format,
                           de.separator,
                           de.max_value,
                           de.min_value,
                           de.input_mask format_num,
                           de.id_unit_measure_type,
                           de.id_unit_measure_subtype,
                           de.id_unit_measure_reference,
                           de.ref_val_min,
                           de.ref_val_max,
                           de.flg_ref_op_min,
                           de.flg_ref_op_max
                      FROM doc_template_area_doc dtad
                     INNER JOIN documentation d
                        ON dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dcomp
                        ON dcomp.id_doc_component = d.id_doc_component
                     INNER JOIN doc_element de
                        ON d.id_documentation = de.id_documentation
                      LEFT JOIN doc_dimension dd
                        ON de.id_doc_dimension = dd.id_doc_dimension
                     WHERE dtad.id_doc_template = i_doc_template
                          -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
                       AND dtad.id_doc_area = i_doc_area
                       AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
                       AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
                       AND d.flg_available = pk_alert_constant.g_available
                       AND dcomp.flg_available = pk_alert_constant.g_available
                       AND de.flg_available = pk_alert_constant.g_available
                       AND (de.flg_type != pk_touch_option.g_elem_flg_type_vital_sign OR
                           (de.flg_type = pk_touch_option.g_elem_flg_type_vital_sign AND
                           de.id_master_item IN (SELECT /*+ opt_estimate(table c rows=1)*/
                                                    c.column_value
                                                     FROM TABLE(l_lst_conf_vs) c)))
                       AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR
                           l_gender = pk_touch_option.g_gender_i)
                       AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR
                           l_age IS NULL)
                       AND (de.flg_gender IS NULL OR de.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
                       AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR l_age IS NULL))
             ORDER BY doc_rank, position DESC, doc_element_rank, element_open;
        --
        g_error := 'GET CURSOR O_ELEMENT_STATUS';
        --Notice: Using scalar subqueries in each call of get_translation for performance improvement (SELECT pk.get_translation FROM dual)
        OPEN o_element_status FOR
            SELECT d.id_documentation,
                   dcomp.id_doc_component,
                   de.id_doc_element,
                   decr.id_doc_element_crit,
                   pk_touch_option_ti.get_element_description(i_lang,
                                                              i_prof,
                                                              de.flg_type,
                                                              de.id_master_item,
                                                              decr.code_element_open) desc_element,
                   decode(dc.flg_criteria,
                          'I',
                          NULL,
                          pk_touch_option_ti.get_element_description(i_lang,
                                                                     i_prof,
                                                                     de.flg_type,
                                                                     de.id_master_item,
                                                                     decr.code_element_close)) desc_element_close,
                   dc.id_doc_criteria,
                   dc.flg_criteria,
                   decr.flg_default,
                   dc.element_color,
                   dc.text_color,
                   decr.flg_confirm
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dcomp
                ON dcomp.id_doc_component = d.id_doc_component
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_element_crit decr
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN doc_criteria dc
                ON decr.id_doc_criteria = dc.id_doc_criteria
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND dcomp.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND decr.flg_available = pk_alert_constant.g_available
               AND (de.flg_type != pk_touch_option.g_elem_flg_type_vital_sign OR
                   (de.flg_type = pk_touch_option.g_elem_flg_type_vital_sign AND
                   de.id_master_item IN (SELECT /*+ opt_estimate(table c rows=1)*/
                                            c.column_value
                                             FROM TABLE(l_lst_conf_vs) c)))
               AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR l_age IS NULL)
               AND (de.flg_gender IS NULL OR de.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR l_age IS NULL)
             ORDER BY dtad.rank, de.rank, dc.rank;
        --
        g_error := 'GET CURSOR O_ELEMNT_ACTION';
        OPEN o_element_action FOR
            SELECT dac.id_doc_action_criteria,
                   dec1.id_doc_element        id_doc_element_crit,
                   dac.id_doc_element_crit    action_element_crit,
                   dac.flg_action,
                   dec2.id_doc_element        id_doc_element_crit_action,
                   dac.id_elem_crit_action    action_elem_crit_action
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dcomp
                ON dcomp.id_doc_component = d.id_doc_component
             INNER JOIN doc_element de1
                ON d.id_documentation = de1.id_documentation
             INNER JOIN doc_element_crit dec1
                ON de1.id_doc_element = dec1.id_doc_element
             INNER JOIN doc_action_criteria dac
                ON dec1.id_doc_element_crit = dac.id_doc_element_crit
             INNER JOIN doc_element_crit dec2
                ON dac.id_elem_crit_action = dec2.id_doc_element_crit
             INNER JOIN doc_element de2
                ON dec2.id_doc_element = de2.id_doc_element
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable         
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND dcomp.flg_available = pk_alert_constant.g_available
               AND de1.flg_available = pk_alert_constant.g_available
               AND dec1.flg_available = pk_alert_constant.g_available
               AND de2.flg_available = pk_alert_constant.g_available
               AND dec2.flg_available = pk_alert_constant.g_available
               AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR l_age IS NULL)
               AND (de1.flg_gender IS NULL OR de1.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(de1.age_min, 0) AND nvl(de1.age_max, nvl(l_age, 0)) OR l_age IS NULL)
               AND dac.flg_available = pk_alert_constant.g_available;
    
        g_error := 'GET CURSOR O_ELEMENT_EXCLUSIVE';
        OPEN o_element_exclusive FOR
            SELECT der.id_doc_element_rel,
                   der.id_group,
                   de.id_doc_element,
                   d.id_documentation,
                   der.flg_type,
                   der.id_doc_element_rel_parent,
                   (SELECT der1.id_doc_element
                      FROM doc_element_rel der1
                     WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_element_rel der
                ON de.id_doc_element = der.id_doc_element
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND der.flg_available = pk_alert_constant.g_available
               AND der.flg_type IN (pk_touch_option.g_der_flg_type_exclusive, pk_touch_option.g_der_flg_type_unique);
        --
        g_error := 'GET CURSOR O_ELEMENT_RELATED_ACTIONS';
        OPEN o_element_related_actions FOR
            SELECT der.id_group, der.id_doc_element, der.id_doc_element_target, der.flg_type, d.id_documentation
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_element_rel der
                ON de.id_doc_element = der.id_doc_element
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND der.flg_type IN (pk_touch_option.g_der_flg_type_copy_action) --For future new actions it's necessary to add the flag action here
               AND der.flg_available = pk_alert_constant.g_available;
    
        g_error := 'GET CURSOR O_ELEMENT_QUALIF';
        --Notice: Using scalar subqueries in each call of get_translation for performance improvement (SELECT pk.get_translation FROM dual)
        OPEN o_element_qualif FOR
            SELECT deq.id_doc_element_qualif,
                   d.id_documentation,
                   de.id_doc_element,
                   deq.id_doc_element_crit,
                   deq.id_doc_qualification,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'DOC_QUALIFICATION.CODE_DOC_QUALIFICATION.' ||
                                                          deq.id_doc_qualification)
                      FROM dual) desc_qualification,
                   deq.id_doc_criteria,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'DOC_CRITERIA.CODE_DOC_CRITERIA.' || deq.id_doc_criteria)
                      FROM dual) desc_criteria,
                   deq.id_doc_criteria_quant,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'DOC_CRITERIA.CODE_DOC_CRITERIA.' || deq.id_doc_criteria_quant)
                      FROM dual) desc_criteria_quant,
                   deq.id_doc_quantification,
                   (SELECT pk_translation.get_translation(i_lang,
                                                          'DOC_QUANTIFICATION.CODE_DOC_QUANTIFICATION.' ||
                                                          deq.id_doc_quantification)
                      FROM dual) desc_quantification,
                   (SELECT dq.level_quant
                      FROM doc_quantification dq
                     WHERE dq.id_doc_quantification = deq.id_doc_quantification) level_quantification,
                   (SELECT pk_translation.get_translation(i_lang, deq.code_doc_elem_qualif_close)
                      FROM dual) desc_doc_elem_qual_close,
                   (SELECT pk_translation.get_translation(i_lang, deq.code_doc_element_quantif_close)
                      FROM dual) desc_element_quantif_close
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_element_crit decr
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN doc_element_qualif deq
                ON decr.id_doc_element_crit = deq.id_doc_element_crit
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND deq.flg_available = pk_alert_constant.g_available
             ORDER BY dtad.rank,
                      de.rank,
                      deq.id_doc_element_crit,
                      deq.rank,
                      desc_qualification,
                      deq.id_doc_criteria,
                      deq.id_doc_quantification ASC;
        --
        g_error := 'GET CURSOR O_ELEMENT_QUALIF_EXCLUSIVE';
        OPEN o_element_qualif_exclusive FOR
            SELECT dqr.id_doc_qualification_rel,
                   dqr.id_group,
                   de.id_doc_element,
                   decr.id_doc_element_crit,
                   d.id_documentation,
                   dqr.flg_type,
                   dqr.id_doc_qualif_rel_parent,
                   (SELECT deq.id_doc_element_qualif
                      FROM doc_qualification_rel dqr1, doc_element_qualif deq
                     WHERE dqr1.id_doc_qualification_rel = dqr.id_doc_qualif_rel_parent
                       AND dqr1.id_doc_element_qualif = deq.id_doc_element_qualif) doc_qualif_parent,
                   deq.id_doc_element_qualif,
                   deq.id_doc_qualification,
                   deq.id_doc_quantification,
                   deq.id_doc_criteria,
                   deq.id_doc_criteria_quant
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_element_crit decr
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN doc_element_qualif deq
                ON decr.id_doc_element_crit = deq.id_doc_element_crit
             INNER JOIN doc_qualification_rel dqr
                ON dqr.id_doc_element_qualif = deq.id_doc_element_qualif
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND dqr.flg_available = pk_alert_constant.g_available
               AND deq.flg_available = pk_alert_constant.g_available;
    
        g_error := 'GET CURSOR O_ELEMENT_DOMAIN';
        OPEN o_element_domain FOR
            SELECT de.id_doc_element, ded.desc_val label, ded.val data, ded.img_name icon, ded.rank
              FROM doc_element_domain ded
             INNER JOIN doc_element de
                ON ded.code_element_domain = de.code_element_domain
             INNER JOIN documentation d
                ON de.id_documentation = d.id_documentation
             INNER JOIN doc_component dcomp
                ON d.id_doc_component = dcomp.id_doc_component
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND de.flg_element_domain_type = pk_touch_option.g_flg_element_domain_template
               AND ded.flg_available = pk_alert_constant.g_available
               AND ded.id_language = i_lang
               AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR l_age IS NULL)
               AND (de.flg_gender IS NULL OR de.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR l_age IS NULL)
             ORDER BY dtad.rank, de.rank, ded.rank, ded.desc_val;
    
        g_error := 'GET CURSOR O_ELEMENT_FUNCTION_PARAMS';
        OPEN o_element_function_param FOR
            SELECT de.id_doc_element,
                   de.code_element_domain id_doc_function,
                   df.out_cursor_name,
                   upper(df.out_cursor_fields) out_cursor_fields,
                   -- function params collection in format: parameterType|valueType|parameterValue[|idDocumentation]   ([]=only when parameterType = Template)
                   CAST(MULTISET (SELECT defp.flg_param_type || '|' || defp.flg_value_type || '|' || defp.param_value ||
                                decode(defp.flg_param_type,
                                       pk_touch_option.g_flg_element_domain_template,
                                       (SELECT '|' || de1.id_documentation
                                          FROM doc_element de1
                                         WHERE de1.id_doc_element = to_number(defp.param_value)),
                                       NULL)
                           FROM doc_element_function_param defp
                          WHERE defp.id_doc_element = de.id_doc_element
                            AND defp.id_doc_function = de.code_element_domain
                          ORDER BY defp.rank) AS table_varchar) function_params
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dcomp
                ON d.id_doc_component = dcomp.id_doc_component
             INNER JOIN doc_element de
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_function df
                ON de.code_element_domain = df.id_doc_function
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND de.flg_element_domain_type = pk_touch_option.g_flg_element_domain_dynamic
               AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR l_age IS NULL)
               AND (de.flg_gender IS NULL OR de.flg_gender = l_gender OR l_gender = pk_touch_option.g_gender_i)
               AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR l_age IS NULL)
             ORDER BY dtad.rank, de.rank;
    
        OPEN o_template_layout FOR
            SELECT xmlquery('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]' passing dt.template_layout AS "layout", CAST(i_doc_area AS NUMBER) AS "id_doc_area", CAST(i_doc_template AS NUMBER) AS "id_doc_template" RETURNING content).getclobval() layout
              FROM doc_template dt
             WHERE dt.id_doc_template = i_doc_template
               AND xmlexists('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]'
                             passing dt.template_layout AS "layout",
                             CAST(i_doc_area AS NUMBER) AS "id_doc_area",
                             CAST(i_doc_template AS NUMBER) AS "id_doc_template");
    
        BEGIN
            SELECT dta.action_subject
              INTO l_subject
              FROM doc_template_area dta
             WHERE dta.id_doc_template = i_doc_template
               AND dta.id_doc_area = i_doc_area;
        
            IF NOT pk_action.get_actions(i_lang, i_prof, l_subject, NULL, o_template_actions_menu, o_error)
            THEN
                g_error := 'Error calling pk_action.get_actions';
                RAISE g_exception;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                /* No action subject for area and template */
                pk_types.open_my_cursor(o_template_actions_menu);
            WHEN OTHERS THEN
                RAISE; /* Re-raise the current exception. */
        END;
    
        g_error := 'GET CURSOR O_COMPONENT_ACTION';
        OPEN o_component_action FOR
            SELECT dr.flg_applicable_criteria,
                   dr.id_documentation,
                   dr.id_documentation_action,
                   dr.flg_action,
                   dr.flg_else_action,
                   dr.tab_id_documentation,
                   dr.flg_doc_op,
                   dr.tab_id_doc_element_crit,
                   dr.flg_elem_crit_op
              FROM doc_template_area_doc dtad
             INNER JOIN documentation d
                ON dtad.id_documentation = d.id_documentation
             INNER JOIN documentation_rel dr
                ON d.id_documentation = dr.id_documentation
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND d.flg_available = pk_alert_constant.g_available
               AND dr.flg_action != pk_touch_option.g_flg_workflow
               AND dr.flg_available = pk_alert_constant.g_available
             ORDER BY dtad.rank;
    
        -- Information relating to vital signs that are referenced by elements of this template
        IF (i_episode IS NOT NULL AND l_lst_vs.count > 0)
        THEN
            BEGIN
                SELECT dtc.flg_show_previous_values
                  INTO l_flg_show_previous_values
                  FROM doc_template_context dtc
                 WHERE dtc.id_institution IN (0, i_prof.institution)
                   AND dtc.id_software = i_prof.software
                   AND dtc.id_context = i_doc_area
                   AND dtc.id_doc_template = i_doc_template;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_show_previous_values := NULL;
            END;
        
            g_error := 'CALLING GET_VS_INFO';
            IF NOT pk_touch_option_ti.get_vs_info(i_lang                     => i_lang,
                                                  i_prof                     => i_prof,
                                                  i_patient                  => i_patient,
                                                  i_episode                  => i_episode,
                                                  i_tbl_vs                   => l_lst_vs,
                                                  i_tbl_aux_vs               => l_lst_aux_vs,
                                                  i_flg_show_previous_values => l_flg_show_previous_values,
                                                  i_hash_vital_sign          => l_hash_vital_sign,
                                                  o_vs_info                  => o_vs_info,
                                                  o_error                    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_vs_info);
        END IF;
    
        g_error := 'GET CURSOR O_ELEMENT_CRIT_INTERVAL';
        --Notice: Using scalar subqueries in each call of get_translation for performance improvement (SELECT pk.get_translation FROM dual)
        OPEN o_element_crit_interval FOR
            SELECT deci.id_doc_element_crit,
                   deci.min_value,
                   deci.max_value,
                   (SELECT pk_translation.get_translation(i_lang, deci.code_element_close)
                      FROM dual) desc_element_close,
                   CASE de.flg_type
                       WHEN pk_touch_option.g_elem_flg_type_comp_ref_value THEN
                        (SELECT pk_translation.get_translation(i_lang, deci.code_ref_val_above)
                           FROM dual)
                       ELSE
                        NULL
                   END desc_ref_val_above,
                   CASE de.flg_type
                       WHEN pk_touch_option.g_elem_flg_type_comp_ref_value THEN
                        (SELECT pk_translation.get_translation(i_lang, deci.code_ref_val_below)
                           FROM dual)
                       ELSE
                        NULL
                   END desc_ref_val_below,
                   CASE de.flg_type
                       WHEN pk_touch_option.g_elem_flg_type_comp_ref_value THEN
                        (SELECT pk_translation.get_translation(i_lang, deci.code_ref_val_normal)
                           FROM dual)
                       ELSE
                        NULL
                   END desc_ref_val_normal
              FROM doc_element_crit_int deci
             INNER JOIN doc_element_crit decr
                ON deci.id_doc_element_crit = decr.id_doc_element_crit
             INNER JOIN doc_element de
                ON decr.id_doc_element = de.id_doc_element
             INNER JOIN documentation d
                ON de.id_documentation = d.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_template = i_doc_template
               AND dtad.id_doc_area = i_doc_area
                  -- validates that documentation component is fully shared, applicable to a specific use within a template/area, or not shareable
               AND (d.id_doc_template = i_doc_template OR d.id_doc_template IS NULL)
               AND (d.id_doc_area = i_doc_area OR d.id_doc_area IS NULL)
               AND d.flg_available = pk_alert_constant.g_yes
               AND de.flg_available = pk_alert_constant.g_yes
               AND decr.flg_available = pk_alert_constant.g_yes
               AND deci.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                pk_types.open_my_cursor(o_component);
                pk_types.open_my_cursor(o_element);
                pk_types.open_my_cursor(o_element_status);
                pk_types.open_my_cursor(o_element_action);
                pk_types.open_my_cursor(o_element_exclusive);
                pk_types.open_my_cursor(o_element_qualif);
                pk_types.open_my_cursor(o_element_qualif_exclusive);
                pk_types.open_my_cursor(o_element_domain);
                pk_types.open_my_cursor(o_element_function_param);
                pk_types.open_my_cursor(o_template_layout);
                pk_types.open_my_cursor(o_template_actions_menu);
                pk_types.open_my_cursor(o_component_action);
                pk_types.open_my_cursor(o_vs_info);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_COMPONENT_LIST');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_component_list;
    /********************************************************************************************
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Allows for new, edit and agree epis documentation.
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new 
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif  
    * @param i_epis_context               context id (Ex: id_interv_presc_det, id_exam...)
    * @param i_summary_and_notes          template summary to be included on clinical notes
    * @param i_episode_context            context episode id  used in preoperative ORIS area by OUTP, INP, EDIS 
    * @param i_flg_table_origin            Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param o_error                       Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Luís Gaspar e Luís Oliveira, based on pk_documentation.set_epis_bartchart
    * @version                            1.0   
    * @since                              26-05-2007
    *
    * @author alter                       Emilia Taborda
    * @since                              2007/08/29
    *
    * @Deprecated : set_epis_documentation (with vital signs support) should be used instead.
    **********************************************************************************************/
    FUNCTION set_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT set_epis_document_internal(i_lang                  => i_lang,
                                          i_prof                  => i_prof,
                                          i_prof_cat_type         => i_prof_cat_type,
                                          i_epis                  => i_epis,
                                          i_doc_area              => i_doc_area,
                                          i_doc_template          => i_doc_template,
                                          i_epis_documentation    => i_epis_documentation,
                                          i_flg_type              => i_flg_type,
                                          i_id_documentation      => i_id_documentation,
                                          i_id_doc_element        => i_id_doc_element,
                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                          i_value                 => i_value,
                                          i_notes                 => i_notes,
                                          i_id_epis_complaint     => NULL,
                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                          i_epis_context          => i_epis_context,
                                          i_episode_context       => i_episode_context,
                                          i_flg_table_origin      => i_flg_table_origin,
                                          i_flg_status            => pk_alert_constant.g_active,
                                          i_dt_creation           => current_timestamp,
                                          o_epis_documentation    => o_epis_documentation,
                                          o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        /*        IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_epis,
                                                             i_id_doc_area => i_doc_area,
                                                             i_desc        => i_summary_and_notes,
                                                             i_id_item     => o_epis_documentation,
                                                             o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;*/
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_EPIS_DOCUMENTATION');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Rollback changes */
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_epis_documentation;

    /**
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
    Includes support for vital signs.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_prof_cat_type              Professional category
    * @param   i_epis                       Episode ID
    * @param   i_doc_area                   Documentation area ID
    * @param   i_doc_template               Touch-option template ID
    * @param   i_epis_documentation         Epis documentation ID
    * @param   i_flg_type                   Operation that was applied to save this entry
    * @param   i_id_documentation           Array with id documentation
    * @param   i_id_doc_element             Array with doc elements
    * @param   i_id_doc_element_crit        Array with doc elements crit
    * @param   i_value                      Array with values
    * @param   i_notes                      Free text documentation / Additional notes
    * @param   i_id_doc_element_qualif      Array with element quantifications/qualifications 
    * @param   i_epis_context               Context ID (Ex: id_interv_presc_det, id_exam...)
    * @param   i_summary_and_notes          Template's summary to be included in clinical notes
    * @param   i_episode_context            Context episode id  used in preoperative ORIS area by OUTP, INP, EDIS
    * @param   i_flg_table_origin           Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
    * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
    * @param   i_vs_value_list              List of vital signs values
    * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
    * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
    * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/29/2011
    */
    FUNCTION set_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_epis_vital_sign_touch';
        e_function_call EXCEPTION;
    BEGIN
        g_error := 'Calling  set_epis_document_internal';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          i_episode_context       => i_episode_context,
                                                          i_flg_table_origin      => i_flg_table_origin,
                                                          i_flg_status            => pk_alert_constant.g_active,
                                                          i_dt_creation           => current_timestamp,
                                                          i_vs_element_list       => i_vs_element_list,
                                                          i_vs_save_mode_list     => i_vs_save_mode_list,
                                                          i_vs_list               => i_vs_list,
                                                          i_vs_value_list         => i_vs_value_list,
                                                          i_vs_uom_list           => i_vs_uom_list,
                                                          i_vs_scales_list        => i_vs_scales_list,
                                                          i_vs_date_list          => i_vs_date_list,
                                                          i_vs_read_list          => i_vs_read_list,
                                                          i_id_edit_reason        => i_id_edit_reason,
                                                          i_notes_edit            => i_notes_edit,
                                                          i_dt_clinical           => i_dt_clinical,
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_error                 => o_error)
        
        THEN
            g_error := 'The function pk_touch_option.set_epis_document_internal returns error';
            RAISE e_function_call;
        END IF;
    
        /*        g_error := 'Calling  set_clinical_notes_doc_area';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_epis,
                                                             i_id_doc_area => i_doc_area,
                                                             i_desc        => pk_string_utils.clob_to_sqlvarchar2(i_summary_and_notes),
                                                             i_id_item     => o_epis_documentation,
                                                             o_error       => o_error)
        THEN
            g_error := 'The function pk_clinical_notes.set_clinical_notes_doc_area returns error';
            RAISE e_function_call;
        END IF;*/
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error calling internal function',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_epis_documentation;
    FUNCTION set_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_epis_vital_sign_touch';
        e_function_call EXCEPTION;
    BEGIN
        g_error := 'Calling  set_epis_document_internal';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          i_episode_context       => i_episode_context,
                                                          i_flg_table_origin      => i_flg_table_origin,
                                                          i_flg_status            => pk_alert_constant.g_active,
                                                          i_dt_creation           => current_timestamp,
                                                          i_vs_element_list       => i_vs_element_list,
                                                          i_vs_save_mode_list     => i_vs_save_mode_list,
                                                          i_vs_list               => i_vs_list,
                                                          i_vs_value_list         => i_vs_value_list,
                                                          i_vs_uom_list           => i_vs_uom_list,
                                                          i_vs_scales_list        => i_vs_scales_list,
                                                          i_vs_date_list          => i_vs_date_list,
                                                          i_vs_read_list          => i_vs_read_list,
                                                          i_id_edit_reason        => table_number(),
                                                          i_notes_edit            => table_clob(),
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_error                 => o_error)
        
        THEN
            g_error := 'The function pk_touch_option.set_epis_document_internal returns error';
            RAISE e_function_call;
        END IF;
    
        /*        g_error := 'Calling  set_clinical_notes_doc_area';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_id_episode  => i_epis,
                                                             i_id_doc_area => i_doc_area,
                                                             i_desc        => pk_string_utils.clob_to_sqlvarchar2(i_summary_and_notes),
                                                             i_id_item     => o_epis_documentation,
                                                             o_error       => o_error)
        THEN
            g_error := 'The function pk_clinical_notes.set_clinical_notes_doc_area returns error';
            RAISE e_function_call;
        END IF;*/
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error calling internal function',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_epis_documentation;
    --
    /**
      Sets documentation values associated with an area (doc_area) of a template (doc_template). 
      Includes support for vital signs.
      Does not perform COMMIT transaction.
      *
      * @param   i_lang                       Professional preferred language
      * @param   i_prof                       Professional identification and its context (institution and software)
      * @param   i_prof_cat_type              Professional category
      * @param   i_epis                       Episode ID
      * @param   i_doc_area                   Documentation area ID
      * @param   i_doc_template               Touch-option template ID
      * @param   i_epis_documentation         Epis documentation ID
      * @param   i_flg_type                   Operation that was applied to save this entry
      * @param   i_id_documentation           Array with id documentation
      * @param   i_id_doc_element             Array with doc elements
      * @param   i_id_doc_element_crit        Array with doc elements crit
      * @param   i_value                      Array with values
      * @param   i_notes                      Free text documentation / Additional notes
      * @param   i_id_doc_element_qualif      Array with element quantifications/qualifications 
      * @param   i_epis_context               Context ID (Ex: id_interv_presc_det, id_exam...)
      * @param   i_summary_and_notes          Template's summary to be included in clinical notes
      * @param   i_episode_context            Context episode id  used in preoperative ORIS area by OUTP, INP, EDIS
      * @param   i_flg_table_origin           Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
      * @param   i_flg_status                 Entry status. Default: (A)ctive
      * @param   i_dt_creation                Creation date. Default: current timestamp
      * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
      * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
      * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
      * @param   i_vs_value_list              List of vital signs values
      * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
      * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
      * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
      * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
      * @param   o_epis_documentation         The epis_documentation ID created
      * @param   o_error                      Error message
      *
      * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
      * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION (default) {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
      * @value i_flg_status                  {*} 'A'  Active (default) {*} 'O' Outdated {*} 'C' Cancelled
      * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
      *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1
    * @since   3/30/2011
    */
    FUNCTION set_epis_document_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_epis_complaint     IN epis_complaint.id_epis_complaint%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_flg_status            IN epis_documentation.flg_status%TYPE DEFAULT pk_alert_constant.g_active,
        i_dt_creation           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_epis_document_internal';
        e_function_call     EXCEPTION;
        function_call_excep EXCEPTION;
    
        FUNCTION inner_set_vs_touch(i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE)
            RETURN pk_touch_option_ti.t_coll_doc_element_vs IS
            l_pat patient.id_patient%TYPE;
            l_ret pk_touch_option_ti.t_coll_doc_element_vs;
        BEGIN
            IF i_vs_element_list IS NOT NULL
               AND i_vs_element_list.count > 0
            THEN
                g_error := 'Calling get_id_patient';
                l_pat   := pk_episode.get_id_patient(i_epis);
            
                g_error := 'Calling set_epis_vital_sign_touch';
                IF NOT pk_touch_option_ti.set_epis_vital_sign_touch(i_lang                   => i_lang,
                                                                    i_prof                   => i_prof,
                                                                    i_episode                => i_epis,
                                                                    i_pat                    => l_pat,
                                                                    i_doc_element_list       => i_vs_element_list,
                                                                    i_save_mode_list         => i_vs_save_mode_list,
                                                                    i_vital_sign_list        => i_vs_list,
                                                                    i_vital_sign_value_list  => i_vs_value_list,
                                                                    i_vital_sign_uom_list    => i_vs_uom_list,
                                                                    i_vital_sign_scales_list => i_vs_scales_list,
                                                                    i_vital_sign_date_list   => i_vs_date_list,
                                                                    i_vital_sign_read_list   => i_vs_read_list,
                                                                    i_dt_creation_tstz       => i_dt_creation,
                                                                    i_id_edit_reason         => i_id_edit_reason,
                                                                    i_notes_edit             => i_notes_edit,
                                                                    i_id_epis_documentation  => i_id_epis_documentation,
                                                                    o_doc_element_vs_list    => l_ret,
                                                                    o_error                  => o_error)
                THEN
                
                    g_error := 'The function pk_touch_option_ti.set_epis_vital_sign_touch returns error';
                    RAISE e_function_call;
                END IF;
            ELSE
                l_ret := pk_touch_option_ti.t_coll_doc_element_vs();
            END IF;
            RETURN l_ret;
        END inner_set_vs_touch;
    
        /********************************************************************************************
        * Editing of HPI records (free-text) that were originally saved in EPIS_ANAMNESIS table.
        *
        * @param i_epis_anamnesis           Original record ID
        *
        * @param o_epis_documentation        New record ID                        
        * @param o_error                     Error message
        * @return                            True or False on success or error
        *
        * @author  ARIEL.MACHADO
        * @version 2.5.0.7.7
        * @since   04-Feb-10
        **********************************************************************************************/
        FUNCTION inner_set_old_free_text_hpi
        (
            i_epis_anamnesis     IN epis_anamnesis.id_epis_anamnesis%TYPE,
            o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
            o_error              OUT t_error_out
        ) RETURN BOOLEAN IS
            l_next_epis_documentation epis_documentation.id_epis_documentation%TYPE;
            l_notes                   epis_documentation.notes%TYPE;
            l_rows_out                table_varchar := table_varchar();
            l_rows_ea_out             table_varchar := table_varchar();
        BEGIN
        
            IF i_flg_type = g_flg_edition_type_nochanges
            THEN
                --No changes edition. Copies the values from previous record and creates a new record using current professional
                SELECT desc_epis_anamnesis
                  INTO l_notes
                  FROM epis_anamnesis ea
                 WHERE ea.id_epis_anamnesis = i_epis_anamnesis;
            ELSE
                -- Edition
                l_notes := i_notes;
            END IF;
        
            --Creates a new record in EPIS_DOCUMENTATION 
            g_error                   := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
            l_next_epis_documentation := ts_epis_documentation.next_key(sequence_in => 'SEQ_EPIS_DOCUMENTATION');
        
            g_error := 'INSERT EPIS_DOCUMENTATION';
            ts_epis_documentation.ins(id_epis_documentation_in       => l_next_epis_documentation,
                                      id_epis_complaint_in           => NULL,
                                      id_episode_in                  => i_epis,
                                      id_professional_in             => i_prof.id,
                                      dt_creation_tstz_in            => i_dt_creation,
                                      id_prof_last_update_in         => i_prof.id,
                                      dt_last_update_tstz_in         => i_dt_creation,
                                      flg_status_in                  => i_flg_status,
                                      id_doc_area_in                 => i_doc_area,
                                      id_doc_template_in             => i_doc_template,
                                      notes_in                       => l_notes,
                                      id_epis_documentation_paren_in => NULL,
                                      id_epis_context_in             => i_epis_context,
                                      id_episode_context_in          => i_episode_context,
                                      flg_edition_type_in            => i_flg_type,
                                      rows_out                       => l_rows_out);
        
            -- If this is an edition then sets previous record as outdated
            IF i_epis_anamnesis IS NOT NULL
               AND i_flg_type = g_flg_edition_type_edit
            THEN
                g_error := 'UPDATING epis_anamnesis';
                ts_epis_anamnesis.upd(flg_status_in        => pk_alert_constant.g_outdated,
                                      id_epis_anamnesis_in => i_epis_anamnesis,
                                      rows_out             => l_rows_ea_out);
            
                g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_ANAMNESIS',
                                              i_rowids       => l_rows_ea_out,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        
            g_error := 'CALL PROCESS_INSERT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DOCUMENTATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            o_epis_documentation := l_next_epis_documentation;
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_SET_OLD_FREE_TEXT_HPI');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_set_old_free_text_hpi;
    
        /********************************************************************************************
        * Editing of Review of System records (free-text) that were originally saved in EPIS_REVIEW_SYSTEMS table.
        *
        * @param i_epis_review_systems       Original record ID
        *
        * @param o_epis_documentation        New record ID                        
        * @param o_error                     Error message
        * @return                            True or False on success or error
        *
        * @author  ARIEL.MACHADO
        * @version 2.5.0.7.7
        * @since   04-Feb-10
        **********************************************************************************************/
        FUNCTION inner_set_old_free_text_ros
        (
            i_epis_review_systems IN epis_review_systems.id_epis_review_systems%TYPE,
            o_epis_documentation  OUT epis_documentation.id_epis_documentation%TYPE,
            o_error               OUT t_error_out
        ) RETURN BOOLEAN IS
            l_next_epis_documentation epis_documentation.id_epis_documentation%TYPE;
            l_notes                   epis_documentation.notes%TYPE;
            l_rows_out                table_varchar := table_varchar();
        BEGIN
        
            IF i_flg_type = g_flg_edition_type_nochanges
            THEN
                --No changes edition. Copies the values from previous record and creates a new record using current professional
                SELECT ros.desc_review_systems
                  INTO l_notes
                  FROM epis_review_systems ros
                 WHERE ros.id_epis_review_systems = i_epis_review_systems;
            ELSE
                -- Edition
                l_notes := i_notes;
            END IF;
        
            --Creates a new record in EPIS_DOCUMENTATION 
            g_error                   := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
            l_next_epis_documentation := ts_epis_documentation.next_key(sequence_in => 'SEQ_EPIS_DOCUMENTATION');
        
            g_error := 'INSERT EPIS_DOCUMENTATION';
            ts_epis_documentation.ins(id_epis_documentation_in       => l_next_epis_documentation,
                                      id_epis_complaint_in           => NULL,
                                      id_episode_in                  => i_epis,
                                      id_professional_in             => i_prof.id,
                                      dt_creation_tstz_in            => i_dt_creation,
                                      id_prof_last_update_in         => i_prof.id,
                                      dt_last_update_tstz_in         => i_dt_creation,
                                      flg_status_in                  => i_flg_status,
                                      id_doc_area_in                 => i_doc_area,
                                      id_doc_template_in             => i_doc_template,
                                      notes_in                       => l_notes,
                                      id_epis_documentation_paren_in => NULL,
                                      id_epis_context_in             => i_epis_context,
                                      id_episode_context_in          => i_episode_context,
                                      flg_edition_type_in            => i_flg_type,
                                      rows_out                       => l_rows_out);
        
            -- If this is an edition then sets previous record as outdated
            IF i_epis_review_systems IS NOT NULL
               AND i_flg_type = g_flg_edition_type_edit
            THEN
                g_error := 'UPDATING epis_anamnesis';
                UPDATE epis_review_systems
                   SET flg_status = pk_alert_constant.g_outdated
                 WHERE id_epis_review_systems = i_epis_review_systems;
            END IF;
        
            g_error := 'CALL PROCESS_INSERT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DOCUMENTATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            o_epis_documentation := l_next_epis_documentation;
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_SET_OLD_FREE_TEXT_ROS');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_set_old_free_text_ros;
    
        /********************************************************************************************
        * Editing of Physical Exam/Physical Assessment records (free-text) that were originally saved in EPIS_OBSERVATION table.
        *
        * @param i_epis_observation          Original record ID
        *
        * @param o_epis_documentation        New record ID                        
        * @param o_error                     Error message
        * @return                            True or False on success or error
        *
        * @author  ARIEL.MACHADO
        * @version 2.5.0.7.7
        * @since   04-Feb-10
        **********************************************************************************************/
        FUNCTION inner_set_old_free_text_obs
        (
            i_epis_observation   IN epis_observation.id_epis_observation%TYPE,
            o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
            o_error              OUT t_error_out
        ) RETURN BOOLEAN IS
            l_next_epis_documentation epis_documentation.id_epis_documentation%TYPE;
            l_notes                   epis_documentation.notes%TYPE;
            l_rows_out                table_varchar := table_varchar();
        BEGIN
        
            IF i_flg_type = g_flg_edition_type_nochanges
            THEN
                --No changes edition. Copies the values from previous record and creates a new record using current professional
                SELECT eo.desc_epis_observation
                  INTO l_notes
                  FROM epis_observation eo
                 WHERE eo.id_epis_observation = i_epis_observation;
            ELSE
                -- Edition
                l_notes := i_notes;
            END IF;
        
            --Creates a new record in EPIS_DOCUMENTATION 
            g_error                   := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
            l_next_epis_documentation := ts_epis_documentation.next_key(sequence_in => 'SEQ_EPIS_DOCUMENTATION');
        
            g_error := 'INSERT EPIS_DOCUMENTATION';
            ts_epis_documentation.ins(id_epis_documentation_in       => l_next_epis_documentation,
                                      id_epis_complaint_in           => NULL,
                                      id_episode_in                  => i_epis,
                                      id_professional_in             => i_prof.id,
                                      dt_creation_tstz_in            => i_dt_creation,
                                      id_prof_last_update_in         => i_prof.id,
                                      dt_last_update_tstz_in         => i_dt_creation,
                                      flg_status_in                  => i_flg_status,
                                      id_doc_area_in                 => i_doc_area,
                                      id_doc_template_in             => i_doc_template,
                                      notes_in                       => l_notes,
                                      id_epis_documentation_paren_in => NULL,
                                      id_epis_context_in             => i_epis_context,
                                      id_episode_context_in          => i_episode_context,
                                      flg_edition_type_in            => i_flg_type,
                                      rows_out                       => l_rows_out);
        
            -- If this is an edition then sets previous record as outdated
            IF i_epis_observation IS NOT NULL
               AND i_flg_type = g_flg_edition_type_edit
            THEN
                g_error := 'UPDATING epis_anamnesis';
                UPDATE epis_observation
                   SET flg_status = pk_alert_constant.g_outdated
                 WHERE id_epis_observation = i_epis_observation;
            
            END IF;
        
            g_error := 'CALL PROCESS_INSERT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DOCUMENTATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            o_epis_documentation := l_next_epis_documentation;
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_SET_OLD_FREE_TEXT_OBS');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_set_old_free_text_obs;
    
        /********************************************************************************************
        * Editing records that were originally saved in EPIS_DOCUMENTATION table.
        *
        * @param i_epis_documentation         Original record ID
        *
        * @param o_epis_documentation        New record ID                        
        * @param o_error                     Error message
        * @return                            True or False on success or error
        *
        * @author  ARIEL.MACHADO
        * @version 2.5.0.7.7
        * @since   04-Feb-10
        **********************************************************************************************/
        FUNCTION inner_set_epis_documentation
        (
            i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
            o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
            o_error              OUT t_error_out
        ) RETURN BOOLEAN IS
            --Documentation from origin
            CURSOR c_prev_epis_documentation IS
                SELECT id_epis_complaint, notes
                  FROM epis_documentation
                 WHERE id_epis_documentation = i_epis_documentation;
            --Documentation details from origin
            CURSOR c_prev_epis_documentation_det IS
                SELECT id_epis_documentation_det,
                       id_documentation,
                       id_doc_element,
                       id_doc_element_crit,
                       VALUE,
                       value_properties
                  FROM epis_documentation_det edd
                 WHERE edd.id_epis_documentation = i_epis_documentation;
            --Documentation qualifications from origin
            CURSOR c_prev_epis_doc_qualif(v_epis_documentation_det epis_documentation_det.id_epis_documentation_det%TYPE) IS
                SELECT id_doc_element_qualif
                  FROM epis_documentation_qualif edq
                 WHERE edq.id_epis_documentation_det = v_epis_documentation_det;
        
            l_notes                   epis_documentation.notes%TYPE;
            l_rows_out                table_varchar := table_varchar();
            l_rows_out_upd            table_varchar := table_varchar();
            l_next_epis_documentation epis_documentation.id_epis_documentation%TYPE;
            l_next_epis_doc_det       epis_documentation_det.id_epis_documentation_det%TYPE;
            r_prev_epis_doc_det       c_prev_epis_documentation_det%ROWTYPE;
            r_prev_epis_doc_qualif    c_prev_epis_doc_qualif%ROWTYPE;
        
            l_epis_documentation  epis_documentation.id_epis_documentation%TYPE;
            l_id_epis_complaint   epis_complaint.id_epis_complaint%TYPE;
            l_doc_element_vs_list pk_touch_option_ti.t_coll_doc_element_vs;
            l_element_type        doc_element.flg_type%TYPE;
            l_value               epis_documentation_det.value%TYPE;
            l_value_properties    epis_documentation_det.value_properties%TYPE;
            l_patient             patient.id_patient%TYPE;
            l_episode             episode.id_episode%TYPE;
            l_dt_clinical         epis_documentation.dt_clinical%TYPE;
        
            l_rowids table_varchar := table_varchar();
        BEGIN
        
            --When is a new record previous record ID is not used
            IF i_flg_type = g_flg_edition_type_new
            THEN
                l_epis_documentation := NULL;
            ELSE
                l_epis_documentation := CASE
                                            WHEN nvl(i_flg_table_origin, g_flg_tab_origin_epis_doc) = g_flg_tab_origin_epis_doc THEN
                                             i_epis_documentation
                                            ELSE
                                             NULL
                                        END;
            END IF;
        
            IF i_flg_type = g_flg_edition_type_nochanges
            THEN
                --No changes edition. Copies the values from previous record and creates a new record using current professional
                g_error := 'GET EPIS_DOCUMENTATION';
                OPEN c_prev_epis_documentation;
                FETCH c_prev_epis_documentation
                    INTO l_id_epis_complaint, l_notes;
                CLOSE c_prev_epis_documentation;
            ELSE
                l_id_epis_complaint := i_id_epis_complaint;
                l_notes             := i_notes;
            END IF;
        
            IF i_dt_clinical IS NULL
            THEN
                l_dt_clinical := NULL;
            ELSE
                l_dt_clinical := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_clinical, NULL);
            END IF;
        
            g_error                   := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
            l_next_epis_documentation := ts_epis_documentation.next_key(sequence_in => 'SEQ_EPIS_DOCUMENTATION');
        
            g_error := 'INSERT EPIS_DOCUMENTATION';
            ts_epis_documentation.ins(id_epis_documentation_in       => l_next_epis_documentation,
                                      id_epis_complaint_in           => l_id_epis_complaint,
                                      id_episode_in                  => i_epis,
                                      id_professional_in             => i_prof.id,
                                      dt_creation_tstz_in            => i_dt_creation,
                                      id_prof_last_update_in         => i_prof.id,
                                      dt_last_update_tstz_in         => i_dt_creation,
                                      flg_status_in                  => i_flg_status,
                                      id_doc_area_in                 => i_doc_area,
                                      id_doc_template_in             => i_doc_template,
                                      notes_in                       => l_notes,
                                      id_epis_documentation_paren_in => l_epis_documentation,
                                      id_epis_context_in             => i_epis_context,
                                      id_episode_context_in          => i_episode_context,
                                      flg_edition_type_in            => i_flg_type,
                                      dt_clinical_in                 => l_dt_clinical,
                                      rows_out                       => l_rows_out);
        
            -- If this is an edition then sets previous record as outdated
            IF (i_epis_documentation IS NOT NULL AND i_flg_type = g_flg_edition_type_edit)
            THEN
                l_rows_out_upd := NULL;
                ts_epis_documentation.upd(id_epis_documentation_in => i_epis_documentation,
                                          flg_status_in            => g_epis_bartchart_out,
                                          rows_out                 => l_rows_out_upd);
                g_error := 'CALL PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_DOCUMENTATION',
                                              i_rowids       => l_rows_out_upd,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            
                g_error := 'Get episode and patient IDs';
                SELECT ed.id_episode, e.id_patient
                  INTO l_episode, l_patient
                  FROM epis_documentation ed
                 INNER JOIN episode e
                    ON e.id_episode = ed.id_episode
                 WHERE ed.id_epis_documentation = i_epis_documentation;
            
                -- Remove an oudated documentation entry from print list (if exists)         
                g_error := 'Call REMOVE_PRINT_LIST_JOBS';
                IF NOT remove_print_list_jobs(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => l_patient,
                                              i_episode            => l_episode,
                                              i_epis_documentation => i_epis_documentation,
                                              o_error              => o_error)
                THEN
                    g_error := 'The function remove_print_list_jobs returns error';
                    RAISE e_function_call;
                END IF;
            
            END IF;
        
            g_error := 'CALL PROCESS_INSERT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DOCUMENTATION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- Create NEW DETAIL LINES for EPIS_DOCUMENTATION     
            IF (i_flg_type = g_flg_edition_type_nochanges)
            THEN
                --No changes edition. 
                --Creates lines of detail coping from previous record but using current professional
                FOR r_prev_epis_doc_det IN c_prev_epis_documentation_det
                LOOP
                    g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                    SELECT seq_epis_documentation_det.nextval
                      INTO l_next_epis_doc_det
                      FROM dual;
                
                    g_error := 'NO CHANGES / INSERT EPIS_DOCUMENTATION_DET';
                    INSERT INTO epis_documentation_det
                        (id_epis_documentation_det,
                         id_epis_documentation,
                         id_documentation,
                         id_doc_element,
                         id_doc_element_crit,
                         id_professional,
                         dt_creation_tstz,
                         VALUE,
                         value_properties)
                    VALUES
                        (l_next_epis_doc_det,
                         l_next_epis_documentation,
                         r_prev_epis_doc_det.id_documentation,
                         r_prev_epis_doc_det.id_doc_element,
                         r_prev_epis_doc_det.id_doc_element_crit,
                         i_prof.id,
                         i_dt_creation,
                         r_prev_epis_doc_det.value,
                         r_prev_epis_doc_det.value_properties);
                
                    FOR r_prev_epis_doc_qualif IN c_prev_epis_doc_qualif(r_prev_epis_doc_det.id_epis_documentation_det)
                    LOOP
                        g_error := 'NO CHANGES / INSERT EPIS_DOCUMENTATION_QUALIF';
                        INSERT INTO epis_documentation_qualif
                            (id_epis_documentation_qualif,
                             id_epis_documentation_det,
                             id_doc_element_qualif,
                             adw_last_update)
                        VALUES
                            (seq_epis_documentation_qualif.nextval,
                             l_next_epis_doc_det,
                             r_prev_epis_doc_qualif.id_doc_element_qualif,
                             g_sysdate);
                    END LOOP;
                END LOOP;
            
            ELSE
                --Editions of type New,Edit,Agree,Update. 
                --Creates lines of detail from arguments passed to function
            
                -- Saves vital signs values
                l_doc_element_vs_list := inner_set_vs_touch(l_next_epis_documentation);
            
                g_error := ' INSERT EPIS_DOCUMENTATION_DET';
                FOR i IN 1 .. i_id_documentation.count
                LOOP
                    g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                    SELECT seq_epis_documentation_det.nextval
                      INTO l_next_epis_doc_det
                      FROM dual;
                
                    SELECT de.flg_type
                      INTO l_element_type
                      FROM doc_element de
                     WHERE de.id_doc_element = i_id_doc_element(i);
                    l_value            := get_value(i_lang, i_prof, l_element_type, i_value(i));
                    l_value_properties := get_value_properties(i_lang,
                                                               i_prof,
                                                               l_element_type,
                                                               i_value(i),
                                                               i_id_doc_element(i),
                                                               l_doc_element_vs_list);
                
                    g_error := 'INSERT EPIS_DOCUMENTATION_DET';
                    INSERT INTO epis_documentation_det
                        (id_epis_documentation_det,
                         id_epis_documentation,
                         id_documentation,
                         id_doc_element,
                         id_doc_element_crit,
                         id_professional,
                         dt_creation_tstz,
                         VALUE,
                         value_properties)
                    VALUES
                        (l_next_epis_doc_det,
                         l_next_epis_documentation,
                         i_id_documentation(i),
                         i_id_doc_element(i),
                         i_id_doc_element_crit(i),
                         i_prof.id,
                         i_dt_creation,
                         l_value,
                         l_value_properties);
                    --
                    --Verifica se o elemento inserido tem qualificação e/ ou quantificador associada (id_doc_element_qualif)
                    IF nvl(i_id_doc_element_qualif(i).count, 0) > 0
                    THEN
                        FOR j IN i_id_doc_element_qualif(i).first .. i_id_doc_element_qualif(i).last
                        LOOP
                            IF i_id_doc_element_qualif(i) (j) IS NOT NULL
                            THEN
                                g_error := 'INSERT EPIS_DOCUMENTATION_QUALIF';
                                --
                                INSERT INTO epis_documentation_qualif
                                    (id_epis_documentation_qualif,
                                     id_epis_documentation_det,
                                     id_doc_element_qualif,
                                     adw_last_update)
                                VALUES
                                    (seq_epis_documentation_qualif.nextval,
                                     l_next_epis_doc_det,
                                     i_id_doc_element_qualif(i) (j),
                                     g_sysdate);
                            END IF;
                        END LOOP;
                    END IF;
                END LOOP;
            END IF;
            o_epis_documentation := l_next_epis_documentation;
        
            --IF DNR => OUTDATE PREVIOUS DNR   
            IF i_doc_area = g_doc_area_dnr
            THEN
                g_error := 'UPDATE EPIS_DOCUMENTATION';
                BEGIN
                    SELECT e.id_patient
                      INTO l_patient
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE ed.id_epis_documentation = o_epis_documentation;
                
                    ts_epis_documentation.upd(flg_status_in => g_epis_bartchart_out,
                                              where_in      => 'id_doc_area = ' || i_doc_area ||
                                                               ' AND id_episode IN ( SELECT id_episode
                                                                            FROM episode
                                                                           WHERE id_patient = ' ||
                                                               l_patient || ')' || ' AND flg_status = ''' ||
                                                               g_epis_bartchart_act || '''' ||
                                                              
                                                               ' AND id_epis_documentation <> ' || o_epis_documentation,
                                              rows_out      => l_rowids);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_patient := NULL;
                END;
            END IF;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_SET_EPIS_DOCUMENTATION');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                END;
        END inner_set_epis_documentation;
    
    BEGIN
        g_sysdate := SYSDATE;
    
        --For edition actions (Edit; No Changes), the table origin and record ID are required
        IF (i_flg_type = g_flg_edition_type_edit OR i_flg_type = g_flg_edition_type_nochanges)
           AND (i_flg_table_origin IS NULL OR i_epis_documentation IS NULL)
        THEN
            g_error := 'RECORD EDITION WITHOUT FLG_TABLE_ORIGIN or ID_EPIS_DOCUMENTATION PARAMETER';
            RAISE g_exception;
        END IF;
    
        -- Operation to perform
        CASE
            WHEN i_flg_type IN (g_flg_edition_type_edit, g_flg_edition_type_nochanges) THEN
            
                -- Table source of the record currently in editing
                CASE i_flg_table_origin
                -- Edition of an old HPI record (free-text) that was previously saved in EPIS_ANAMNESIS
                    WHEN g_flg_tab_origin_epis_anamn THEN
                        g_error := 'inner_set_old_free_text_hpi';
                        IF NOT inner_set_old_free_text_hpi(i_epis_documentation, o_epis_documentation, o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                -- Edition of an old RoS record (free-text) that was previously saved in EPIS_REVIEW_SYSTEMS        
                    WHEN g_flg_tab_origin_epis_rev_sys THEN
                        g_error := 'inner_set_old_free_text_ros';
                        IF NOT inner_set_old_free_text_ros(i_epis_documentation, o_epis_documentation, o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                -- Edition of an old Physical Exam/Assessment record (free-text) that was previously saved in EPIS_OBSERVATION
                    WHEN g_flg_tab_origin_epis_obs THEN
                        g_error := 'inner_set_old_free_text_obs';
                        IF NOT inner_set_old_free_text_obs(i_epis_documentation, o_epis_documentation, o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                -- Edition of a documentation record that was previously saved in EPIS_DOCUMENTATION        
                    WHEN g_flg_tab_origin_epis_doc THEN
                        g_error := 'inner_set_epis_documentation';
                        IF NOT inner_set_epis_documentation(i_epis_documentation, o_epis_documentation, o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                    ELSE
                        g_error := 'I_FLG_TABLE_ORIGIN (' || i_flg_table_origin || ') NOT SUPPORTED';
                        RAISE g_exception;
                    
                END CASE;
            
            WHEN i_flg_type IN (g_flg_edition_type_new, g_flg_edition_type_agree, g_flg_edition_type_update) THEN
                IF NOT inner_set_epis_documentation(i_epis_documentation, o_epis_documentation, o_error)
                THEN
                    RAISE function_call_excep;
                END IF;
            ELSE
                g_error := 'I_FLG_TYPE (' || i_flg_type || ') NOT SUPPORTED';
                RAISE g_exception;
        END CASE;
    
        g_error := 'CALL SET_CODING_ELEMENT_CHART';
        IF NOT pk_medical_decision.set_coding_element_chart(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_epis          => i_epis,
                                                            i_document_area => i_doc_area,
                                                            o_error         => o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
        --
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => i_dt_creation,
                                      i_dt_first_obs        => i_dt_creation,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
        IF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            g_error := 'CHANGE THE STATUS - PK_HHC_CORE.SET_REQ_STATUS_IE';
            --change the status
            IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => i_epis,
                                                 i_id_epis_hhc_req => NULL,
                                                 o_error           => o_error)
            THEN
                pk_utils.undo_changes();
                RETURN FALSE;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Error calling internal function',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_epis_document_internal;

    --
    /********************************************************************************************
    * Devolver os valores registados numa área(doc_area) para um episódio
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_epis_document     the documentation episode id
    * @param o_epis_document     array with values of documentation    
    * @param o_vs_info           cursor with values of vital_sign documentation
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda, based on pk_documentation.get_epis_bartchart
    * @version                   1.0    
    * @since                     2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    *
    *                             Ariel Machado
    *                             1.2 (2.4.3)
    *                             2008/05/30
    *                             Returns dynamics element's domain from functions and sysdomain
    ********************************************************************************************/
    FUNCTION get_epis_documentation
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_document   IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_document   OUT pk_types.cursor_type,
        o_element_domain  OUT pk_types.cursor_type,
        o_vs_info         OUT pk_types.cursor_type,
        o_additional_info OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --elements with dynamic domain (functions)
        CURSOR c_dynamic_functions IS
            SELECT de.id_doc_element,
                   de.code_element_domain id_doc_function,
                   CURSOR (SELECT t_rec_function_param(defp.flg_param_type,
                                                       defp.flg_value_type,
                                                       decode(defp.flg_param_type,
                                                              g_flg_param_type_template_elem,
                                                              decode(defp.flg_value_type,
                                                                     g_flg_value_type_value, --Value
                                                                     (SELECT edd1.value
                                                                        FROM epis_documentation_det edd1
                                                                       WHERE edd1.id_epis_documentation = i_epis_document
                                                                         AND edd1.id_doc_element =
                                                                             to_number(defp.param_value)),
                                                                     g_flg_param_type_criteria, --Criteria
                                                                     (SELECT edd1.id_doc_element_crit
                                                                        FROM epis_documentation_det edd1
                                                                       WHERE edd1.id_epis_documentation = i_epis_document
                                                                         AND edd1.id_doc_element =
                                                                             to_number(defp.param_value)),
                                                                     defp.param_value),
                                                              defp.param_value)) function_params
                             FROM doc_element_function_param defp
                            WHERE de.id_doc_element = defp.id_doc_element
                              AND de.code_element_domain = defp.id_doc_function
                            ORDER BY defp.rank)                 function_params
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
            
             WHERE ed.id_epis_documentation = i_epis_document
               AND de.flg_element_domain_type = g_flg_element_domain_dynamic;
    
        -- local variables
        l_idx                PLS_INTEGER;
        c_function_params    SYS_REFCURSOR;
        l_doc_element        doc_element.id_doc_element%TYPE;
        l_function           doc_element.code_element_domain%TYPE;
        l_id_episode         episode.id_episode%TYPE;
        l_id_patient         patient.id_patient%TYPE;
        l_data               table_varchar2;
        l_label              table_varchar2;
        l_icon               table_varchar2;
        l_tbl_vsr            table_varchar;
        l_tab_dynamic_domain t_table_rec_element_domain;
    
        -- Inner function to retrieves a dynamic domain 
        FUNCTION inner_get_dynamic_domain
        (
            i_doc_function    IN doc_function.id_doc_function%TYPE,
            i_function_params IN SYS_REFCURSOR,
            o_data            OUT table_varchar2,
            o_label           OUT table_varchar2,
            o_icon            OUT table_varchar2,
            o_error           OUT t_error_out
        ) RETURN BOOLEAN IS
        
            TYPE function_params_t IS TABLE OF t_rec_function_param INDEX BY BINARY_INTEGER;
            l_function_params function_params_t;
            c_domain          pk_types.cursor_type;
            l_doc_function    doc_function.id_doc_function%TYPE;
            l_tab_dummy1      table_varchar2;
            l_tab_dummy2      table_varchar2;
            l_tab_dummy3      table_varchar2;
            l_tab_dummy4      table_number;
        
        BEGIN
        
            l_doc_function := upper(i_doc_function);
        
            g_error := 'GET FUNCTION PARAMS';
            FETCH i_function_params BULK COLLECT
                INTO l_function_params;
            CLOSE i_function_params;
        
            CASE l_doc_function
            --Category list
                WHEN 'LIST.GET_CAT_LIST' THEN
                    g_error := 'CALL PK_LIST.GET_CAT_LIST';
                    IF NOT pk_list.get_cat_list(i_lang => i_lang, o_cat => c_domain, o_error => o_error)
                    THEN
                        RETURN FALSE;
                    ELSE
                        FETCH c_domain BULK COLLECT
                            INTO o_data, l_tab_dummy1, o_label, l_tab_dummy2;
                        CLOSE c_domain;
                    
                        --This function doesn't have icons, then fill the field as null
                        o_icon := table_varchar2();
                        o_icon.extend(o_data.count);
                    END IF;
                
            --Professional list
                WHEN 'LIST.GET_PROF_LIST' THEN
                    g_error := 'CALL PK_LIST.GET_PROF_LIST';
                    IF l_function_params.count() = 5
                    THEN
                        IF NOT pk_list.get_prof_list(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_speciality    => l_function_params(3).param_value,
                                                     i_category      => l_function_params(4).param_value,
                                                     i_dep_clin_serv => l_function_params(5).param_value,
                                                     o_prof          => c_domain,
                                                     o_error         => o_error)
                        THEN
                            RETURN FALSE;
                        ELSE
                        
                            FETCH c_domain BULK COLLECT
                                INTO o_data, o_label;
                            CLOSE c_domain;
                        
                            --This function doesn't have icons, then fill the field as null
                            o_icon := table_varchar2();
                            o_icon.extend(o_data.count);
                        END IF;
                    
                    ELSE
                        g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') INVALID PARAMETERS NUMBER';
                        RAISE g_exception;
                    END IF;
                    --Institution lise
                WHEN 'PREGNANCY.GET_INST_DOMAIN_TEMPLATE' THEN
                    g_error := 'CALL PREGNANCY.GET_INST_DOMAIN_TEMPLATE';
                    IF l_function_params.count() = 4
                    THEN
                        IF NOT pk_pregnancy.get_inst_domain_template(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_flg_type    => l_function_params(3).param_value,
                                                                     i_flg_context => l_function_params(4).param_value,
                                                                     o_inst        => c_domain,
                                                                     o_error       => o_error)
                        THEN
                            RETURN FALSE;
                        ELSE
                            FETCH c_domain BULK COLLECT
                                INTO l_tab_dummy1, o_data, o_label, l_tab_dummy3, l_tab_dummy4, l_tab_dummy2;
                            CLOSE c_domain;
                        
                            --This function doesn't have icons, then fill the field as null
                            o_icon := table_varchar2();
                            o_icon.extend(o_data.count);
                        END IF;
                    ELSE
                        g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') INVALID PARAMETERS NUMBER';
                        RAISE g_exception;
                    END IF;
                ELSE
                    g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') NOT SUPPORTED';
                    RAISE g_exception;
                
            END CASE;
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_GET_DYNAMIC_DOMAIN');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                
                END;
        END inner_get_dynamic_domain;
    
    BEGIN
    
        g_error := 'GET CURSOR O_EPIS_DOCUMENT';
        OPEN o_epis_document FOR
            SELECT edd.id_doc_element,
                   edd.id_doc_element_crit,
                   CASE de.flg_type
                       WHEN g_elem_flg_type_comp_date THEN
                       --For date elements display at timezone institution
                        get_date_value_insttimezone(i_lang, i_prof, edd.value, edd.value_properties)
                       WHEN g_elem_flg_type_comp_numeric THEN
                       --For numeric elements check if has an unit of measure related and then concatenate value with UOM ID
                        decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                       WHEN g_elem_flg_type_comp_ref_value THEN
                       --For numeric elements with reference values verifies that it has properties, then concatenate them
                        decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                       WHEN g_elem_flg_type_vital_sign THEN
                       -- For vital sign elements,  related id_vital_sign_read(s) saved in value_properties field are returned
                        edd.value_properties
                       ELSE
                        edd.value
                   END VALUE,
                   edd.id_documentation,
                   ed.notes notes_docum,
                   edq.id_doc_element_qualif,
                   deq.id_doc_qualification,
                   deq.id_doc_criteria,
                   deq.id_doc_quantification
              FROM epis_documentation ed
              LEFT JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
              LEFT JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
              LEFT JOIN documentation d
                ON d.id_documentation = de.id_documentation
              LEFT JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
              LEFT JOIN epis_documentation_qualif edq
                ON edd.id_epis_documentation_det = edq.id_epis_documentation_det
              LEFT JOIN doc_element_qualif deq
                ON edq.id_doc_element_qualif = deq.id_doc_element_qualif
             WHERE ed.id_epis_documentation = i_epis_document
             ORDER BY dtad.rank, de.rank;
    
        --Retrieves dynamic elements domain
        l_idx                := 1;
        l_tab_dynamic_domain := t_table_rec_element_domain();
    
        g_error := 'OPEN c_dynamic_functions';
        OPEN c_dynamic_functions;
        LOOP
            FETCH c_dynamic_functions
                INTO l_doc_element, l_function, c_function_params;
            EXIT WHEN c_dynamic_functions%NOTFOUND;
        
            IF NOT inner_get_dynamic_domain(l_function, c_function_params, l_data, l_label, l_icon, o_error)
            THEN
                pk_types.open_my_cursor(o_epis_document);
                pk_types.open_my_cursor(o_element_domain);
                RETURN FALSE;
            ELSE
                FOR i IN 1 .. l_data.count
                LOOP
                    l_tab_dynamic_domain.extend;
                    l_tab_dynamic_domain(l_idx) := t_rec_element_domain(id_doc_element => l_doc_element,
                                                                        data           => l_data(i),
                                                                        label          => l_label(i),
                                                                        icon           => l_icon(i),
                                                                        rank           => NULL);
                    l_idx := l_idx + 1;
                END LOOP;
            END IF;
        END LOOP;
        CLOSE c_dynamic_functions;
    
        g_error := 'GET CURSOR O_ELEMENT_DOMAIN ';
    
        OPEN o_element_domain FOR
        --Domain for sysdomain elements
            SELECT de.id_doc_element, sd.val data, sd.desc_val label, sd.img_name icon, sd.rank
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
              LEFT JOIN sys_domain sd
                ON sd.code_domain = de.code_element_domain
             WHERE ed.id_epis_documentation = i_epis_document
               AND de.flg_element_domain_type = g_flg_element_domain_sysdomain
               AND sd.flg_available = g_available
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
            
            UNION ALL
            --Domain for dynamic elements
            SELECT t.id_doc_element, t.data data, t.label, t.icon, t.rank
              FROM TABLE(l_tab_dynamic_domain) t
            
             ORDER BY id_doc_element, rank, label;
    
        g_error := 'GET list of vital_sign_read ids';
        BEGIN
            SELECT id_episode,
                   pk_episode.get_id_patient(id_episode) id_patient,
                   pk_string_utils.str_split(ltrim(REPLACE(MAX(sys_connect_by_path(value_properties, ',')), ',', '|'),
                                                   '|'),
                                             '|') accnt1
              INTO l_id_episode, l_id_patient, l_tbl_vsr
              FROM (SELECT ed.id_episode, edd.value_properties, rownum rn
                      FROM epis_documentation ed
                     INNER JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                     INNER JOIN doc_element de
                        ON de.id_doc_element = edd.id_doc_element
                     WHERE ed.id_epis_documentation = i_epis_document
                       AND de.flg_type = g_elem_flg_type_vital_sign)
            CONNECT BY rn = PRIOR rn + 1
             START WITH rn = 1
             GROUP BY id_episode;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_episode := NULL;
                l_id_patient := NULL;
                l_tbl_vsr    := NULL;
        END;
    
        IF (l_tbl_vsr IS NOT NULL AND l_tbl_vsr.count > 0)
        THEN
            g_error := 'GET pk_api_vital_sign.get_vital_sign_read_info';
            IF NOT pk_api_vital_sign.get_vital_sign_read_info(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => l_id_patient,
                                                              i_episode => l_id_episode,
                                                              i_tbl_vsr => l_tbl_vsr,
                                                              o_vs_info => o_vs_info,
                                                              o_error   => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_vs_info);
        END IF;
    
        g_error := 'GET CURSOR O_ADDITIONAL_INFO';
        OPEN o_additional_info FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, ed.dt_clinical, i_prof) dt_clinical
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = i_epis_document;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                pk_types.open_my_cursor(o_epis_document);
                pk_types.open_my_cursor(o_element_domain);
                pk_types.open_my_cursor(o_vs_info);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENTATION');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_documentation;

    /********************************************************************************************
    * Devolver os valores registados numa área(doc_area) para um episódio
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_epis_document     the documentation episode id
    * @param o_epis_document     array with values of documentation    
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda, based on pk_documentation.get_epis_bartchart
    * @version                   1.0    
    * @since                     2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    *
    *                             Ariel Machado
    *                             1.2 (2.4.3)
    *                             2008/05/30
    *                             Returns dynamics element's domain from functions and sysdomain
    ********************************************************************************************/
    FUNCTION get_epis_documentation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_document  IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_document  OUT pk_types.cursor_type,
        o_element_domain OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dummy      pk_types.cursor_type;
        l_dummy_info pk_types.cursor_type;
    BEGIN
    
        g_error := 'GET pk_api_vital_sign.get_vital_sign_read_info';
        IF NOT get_epis_documentation(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_epis_document   => i_epis_document,
                                      o_epis_document   => o_epis_document,
                                      o_element_domain  => o_element_domain,
                                      o_vs_info         => l_dummy,
                                      o_additional_info => l_dummy_info,
                                      o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_dummy%ISOPEN
        THEN
            CLOSE l_dummy;
        END IF;
        IF l_dummy_info%ISOPEN
        THEN
            CLOSE l_dummy_info;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                pk_types.open_my_cursor(o_epis_document);
                pk_types.open_my_cursor(o_element_domain);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENTATION');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_documentation;

    /**
    * Gives information about the latest update done in a set of doc_areas that use touch-option templates framework to save records.
    * This function lets you set the scope of latest update: per patient, visit or episode.
    *
    * @param i_lang         Language ID
    * @param i_prof         Current professional
    * @param i_scope_type   Scope type (by Patient, by Visit, by Episode)
    * @param i_scope        Scope ID (id_patient, id_visit, id_episode)
    * @param i_doc_area     Array with doc_area IDs
    * @param o_last_update  Cursor containing information about last update
    *
    * @param o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10
    */
    FUNCTION get_epis_document_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope_type  IN VARCHAR2,
        i_scope       IN NUMBER,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_scope_type EXCEPTION;
        l_episode            episode.id_episode%TYPE;
        l_visit              visit.id_visit%TYPE;
        l_patient            patient.id_patient%TYPE;
    BEGIN
    
        IF i_scope IS NOT NULL
           AND i_scope_type IS NOT NULL
        THEN
            pk_alertlog.log_debug(sub_object_name => 'GET_EPIS_DOCUMENT_LAST_UPDATE',
                                  text            => 'institution:' || i_prof.institution || ' software:' ||
                                                     i_prof.software || 'i_scope_type: ' || i_scope_type || ' i_scope: ' ||
                                                     i_scope || 'i_doc_area: (' ||
                                                     pk_utils.concat_table(i_doc_area, ',') || ')');
        
            g_error := 'ANALYSING SCOPE TYPE';
            IF NOT get_scope_vars(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_scope      => i_scope,
                                  i_scope_type => i_scope_type,
                                  o_patient    => l_patient,
                                  o_visit      => l_visit,
                                  o_episode    => l_episode,
                                  o_error      => o_error)
            THEN
                RAISE e_invalid_scope_type;
            END IF;
        
            g_error := 'OPEN LAST_UPDATE';
            OPEN o_last_update FOR
                SELECT pk_message.get_message(i_lang, 'DOCUMENTATION_T001') title,
                       t.dt_last_update,
                       t.nick_name,
                       t.desc_speciality,
                       t.date_target,
                       t.hour_target,
                       t.date_hour_target
                  FROM (SELECT row_number() over(ORDER BY ed.dt_last_update_tstz DESC) rn,
                               pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_prof_last_update) nick_name,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                ed.id_prof_last_update,
                                                                ed.dt_last_update_tstz,
                                                                ed.id_episode) desc_speciality,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                ed.dt_last_update_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) hour_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           ed.dt_last_update_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) date_hour_target
                          FROM epis_documentation ed
                         INNER JOIN episode e
                            ON e.id_episode = ed.id_episode
                         WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table c rows=1)*/
                                                   c.column_value
                                                    FROM TABLE(i_doc_area) c)
                           AND ((i_scope_type = pk_alert_constant.g_scope_type_episode AND e.id_episode = l_episode) OR
                               (i_scope_type = pk_alert_constant.g_scope_type_visit AND e.id_visit = l_visit) OR
                               (i_scope_type = pk_alert_constant.g_scope_type_patient))
                           AND e.id_patient = l_patient) t
                 WHERE t.rn = 1;
        ELSE
            pk_types.open_my_cursor(o_last_update);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_scope_type THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'The i_scope_type parameter has an unexpected value for scope type',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'get_epis_document_last_update');
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_last_update);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'get_epis_document_last_update');
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_last_update);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_epis_document_last_update;
    --
    --
    /********************************************************************************************
    * Devolver o profissional que efectou a última alteração e respectiva data. 
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
    * @author                         Emília Taborda
    * @version                        1.0   
    * @since                          2007/06/01
    * @Deprecated : get_epis_document_last_update(with i_scope_type) should be used instead.
    **********************************************************************************************/
    FUNCTION get_epis_document_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_doc_area    IN table_number,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scope_type VARCHAR2(1 CHAR);
        l_scope      episode.id_episode%TYPE;
        l_ret        BOOLEAN;
    
    BEGIN
        l_ret := TRUE;
        IF i_doc_area IS NOT NULL
           AND i_doc_area.count > 0
           AND i_episode IS NOT NULL
        THEN
            -- documentation per visit
            IF i_doc_area(1) = g_doc_area_pat_belong
            THEN
                g_error      := 'GET ID_VISIT';
                l_scope      := pk_episode.get_id_visit(i_episode);
                l_scope_type := pk_alert_constant.g_scope_type_visit;
            ELSE
                l_scope      := i_episode;
                l_scope_type := pk_alert_constant.g_scope_type_episode;
            END IF;
        
            g_error := 'CALL GET_EPIS_DOCUMENT_LAST_UPDATE';
            l_ret   := get_epis_document_last_update(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_scope_type  => l_scope_type,
                                                     i_scope       => l_scope,
                                                     i_doc_area    => i_doc_area,
                                                     o_last_update => o_last_update,
                                                     o_error       => o_error);
        
        ELSE
            pk_types.open_my_cursor(o_last_update);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                pk_types.open_my_cursor(o_last_update);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENT_LAST_UPDATE');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_document_last_update;
    --
    /********************************************************************************************
    * Cancel an episode documentation
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
    * @author                         Emília Taborda, based on pk_documentation.sr_cancel_epis_documentation
    * @version                        1.0   
    * @since                          2007/06/01
    * @Deprecated : cancel_epis_documentation (with i_cancel_reason) should be used instead.
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
    BEGIN
    
        RETURN cancel_epis_documentation(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_epis_doc   => i_id_epis_doc,
                                         i_notes         => i_notes,
                                         i_test          => i_test,
                                         i_cancel_reason => NULL,
                                         o_flg_show      => o_flg_show,
                                         o_msg_title     => o_msg_title,
                                         o_msg_text      => o_msg_text,
                                         o_button        => o_button,
                                         o_error         => o_error);
    
    END cancel_epis_documentation;

    --
    /********************************************************************************************
    * Cancel an episode documentation
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param i_cancel_reason          Cancel reason ID. Default NULL
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda, based on pk_documentation.sr_cancel_epis_documentation
    * @version                        1.0   
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION cancel_epis_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        i_cancel_reason IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT cancel_epis_doc_no_commit(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_epis_doc   => i_id_epis_doc,
                                         i_notes         => i_notes,
                                         i_test          => i_test,
                                         i_cancel_reason => i_cancel_reason,
                                         o_flg_show      => o_flg_show,
                                         o_msg_title     => o_msg_title,
                                         o_msg_text      => o_msg_text,
                                         o_button        => o_button,
                                         o_error         => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_EPIS_DOCUMENTATION');
                ROLLBACK;
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
    END cancel_epis_documentation;
    --
    /********************************************************************************************
    * Cancelar um episódio documentation 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_notes                  Cancel Notes
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param i_cancel_reason          Cancel reason ID. Default NULL
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado                            
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Emília Taborda, based on pk_documentation.sr_cancel_epis_documentation
    * @version                        1.0   
    * @since                          2007/06/01
    **********************************************************************************************/
    FUNCTION cancel_epis_doc_no_commit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_epis_doc   IN epis_documentation.id_epis_documentation%TYPE,
        i_notes         IN VARCHAR2,
        i_test          IN VARCHAR2,
        i_cancel_reason IN epis_documentation.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'cancel_epis_doc_no_commit';
        l_rows_out    table_varchar;
        l_patient     patient.id_patient%TYPE;
        l_episode     episode.id_episode%TYPE;
        l_flg_printed epis_documentation.flg_printed%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        --Verifica se é para mostrar mensagem de confirmação
        IF i_test = 'Y'
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'DOCUMENTATION_T006');
            o_msg_text  := pk_message.get_message(i_lang, 'DOCUMENTATION_M013');
            o_button    := 'NC';
            RETURN TRUE;
        END IF;
        --
        g_error := 'UPDATING EPIS_DOCUMENTATION';
        ts_epis_documentation.upd(id_epis_documentation_in => i_id_epis_doc,
                                  flg_status_in            => g_canceled,
                                  id_prof_cancel_in        => i_prof.id,
                                  notes_cancel_in          => i_notes,
                                  id_cancel_reason_in      => i_cancel_reason,
                                  dt_cancel_tstz_in        => g_sysdate_tstz,
                                  rows_out                 => l_rows_out);
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DOCUMENTATION',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'Get episode and patient IDs';
        SELECT ed.id_episode, e.id_patient
          INTO l_episode, l_patient
          FROM epis_documentation ed
         INNER JOIN episode e
            ON e.id_episode = ed.id_episode
         WHERE ed.id_epis_documentation = i_id_epis_doc;
    
        -- Remove documentation entry from print list (if exists)         
        g_error := 'Call REMOVE_PRINT_LIST_JOBS';
        IF NOT remove_print_list_jobs(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_patient            => l_patient,
                                      i_episode            => l_episode,
                                      i_epis_documentation => i_id_epis_doc,
                                      o_error              => o_error)
        THEN
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
        g_error := 'Call flg_printed';
        --Call cancel event if flg_printed='P' in epis_documentation 
        SELECT ed.flg_printed
          INTO l_flg_printed
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = i_id_epis_doc;
    
        IF l_flg_printed = g_flg_printed
        THEN
            pk_ia_event_common.sick_leave_cancel(i_id_institution        => i_prof.institution,
                                                 i_id_epis_documentation => i_id_epis_doc);
        END IF;
    
        -- CANCEL VITAL SIGNS REGISTERED BY TOUCH OPTION 
        IF NOT pk_touch_option_ti.cancel_epis_vital_sign(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_epis_documentation => i_id_epis_doc,
                                                         i_id_episode         => l_episode,
                                                         i_id_cancel_reason   => i_cancel_reason,
                                                         i_notes              => i_notes,
                                                         o_error              => o_error)
        THEN
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_touch_option_core.e_function_call_error THEN
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'CONTEXT',
                                            value_in           => g_error);
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'PACKAGE',
                                            value_in           => g_package_name);
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'METHOD',
                                            value_in           => k_function_name);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, k_function_name);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END cancel_epis_doc_no_commit;
    --
    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_document      the documentation episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    ********************************************************************************************/
    FUNCTION get_epis_documentation_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_doc                table_number;
        l_cancel_notes_code_trans translation.code_translation%TYPE := 'CANCEL_REASON.CODE_CANCEL_REASON.';
        --
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
            SELECT ed.id_epis_documentation,
                   ed.id_doc_template,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality,
                   ed.id_doc_area,
                   ed.flg_status,
                   pk_sysdomain.get_domain(g_domain_epis_doc_flg_status, ed.flg_status, i_lang) desc_status,
                   ed.notes notes,
                   decode(ed.flg_status, 'C', ed.notes_cancel, NULL) cancel_notes,
                   decode(ed.flg_status,
                          'C',
                          pk_translation.get_translation(i_lang, l_cancel_notes_code_trans || ed.id_cancel_reason),
                          NULL) cancel_reason
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(l_epis_doc) t)
             ORDER BY dt_last_update_tstz DESC;
        --
        g_error := 'GET CURSOR O_EPIS_DOCUMENT_VAL';
        OPEN o_epis_document_val FOR
            SELECT ed.id_epis_documentation,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                   get_element_description(i_lang,
                                           i_prof,
                                           de.flg_type,
                                           edd.value,
                                           edd.value_properties,
                                           decr.id_doc_element_crit,
                                           de.id_unit_measure_reference,
                                           de.id_master_item,
                                           decr.code_element_close) desc_element,
                   get_formatted_value(i_lang,
                                       i_prof,
                                       de.flg_type,
                                       edd.value,
                                       edd.value_properties,
                                       de.input_mask,
                                       de.flg_optional_value,
                                       de.flg_element_domain_type,
                                       de.code_element_domain,
                                       edd.dt_creation_tstz) VALUE,
                   ed.id_doc_area,
                   dtad.rank rank_component,
                   de.rank rank_element,
                   pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                   pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                   pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification
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
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(l_epis_doc) t)
             ORDER BY id_epis_documentation, rank_component, rank_element;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENTATION_DET');
                pk_types.open_my_cursor(o_epis_doc_register);
                pk_types.open_my_cursor(o_epis_document_val);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_documentation_det;
    --
    /********************************************************************************************
    * Returns previous records done in a component for defined scope and filter criteria
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_flg_show          Applied filter for previous records
    * @param i_documentation     Component ID      
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional     
    * @param o_prev_records      Cursor containing info about previous records done 
    * @param o_error             Error message
    *                        
    * @value i_flg_show          {*} 'SA' - Show All previous records {*} 'SL' - Show Last previous record {*} 'SM' - Show My previous records {*} 'SML' - Show My Last previous record
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    ********************************************************************************************/
    FUNCTION get_document_previous_records
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_flg_show      IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        g_all_previous_records    CONSTANT VARCHAR(2 CHAR) := 'SA'; --Show All previous records
        g_last_previous_record    CONSTANT VARCHAR(2 CHAR) := 'SL'; --Show Last previous record
        g_my_previous_records     CONSTANT VARCHAR(2 CHAR) := 'SM'; --Show My previous records
        g_my_last_previous_record CONSTANT VARCHAR(3 CHAR) := 'SML'; --Show My Last previous record
    
    BEGIN
        IF i_flg_show = g_all_previous_records
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_PREV_RECORD_ALL';
            IF NOT pk_touch_option.get_doc_prev_record_all(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_scope         => i_scope,
                                                           i_scope_type    => i_scope_type,
                                                           i_documentation => i_documentation,
                                                           o_last_doc_det  => o_last_doc_det,
                                                           o_prev_records  => o_prev_records,
                                                           o_error         => o_error)
            THEN
                pk_types.open_my_cursor(o_prev_records);
                RETURN FALSE;
            END IF;
        
        ELSIF i_flg_show = g_last_previous_record
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_PREV_RECORD_LAST';
            IF NOT pk_touch_option.get_doc_prev_record_last(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_scope         => i_scope,
                                                            i_scope_type    => i_scope_type,
                                                            i_documentation => i_documentation,
                                                            o_last_doc_det  => o_last_doc_det,
                                                            o_prev_records  => o_prev_records,
                                                            o_error         => o_error)
            THEN
                pk_types.open_my_cursor(o_prev_records);
                RETURN FALSE;
            END IF;
        
        ELSIF i_flg_show = g_my_previous_records
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_PREV_RECORD_MY';
            IF NOT pk_touch_option.get_doc_prev_record_my(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_scope         => i_scope,
                                                          i_scope_type    => i_scope_type,
                                                          i_documentation => i_documentation,
                                                          o_last_doc_det  => o_last_doc_det,
                                                          o_prev_records  => o_prev_records,
                                                          o_error         => o_error)
            THEN
                pk_types.open_my_cursor(o_prev_records);
                RETURN FALSE;
            END IF;
        
        ELSIF i_flg_show = g_my_last_previous_record
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_PREV_RECORD_MAY_LAST';
            IF NOT pk_touch_option.get_doc_prev_record_may_last(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_scope         => i_scope,
                                                                i_scope_type    => i_scope_type,
                                                                i_documentation => i_documentation,
                                                                o_last_doc_det  => o_last_doc_det,
                                                                o_prev_records  => o_prev_records,
                                                                o_error         => o_error)
            THEN
                pk_types.open_my_cursor(o_prev_records);
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOCUMENT_PREVIOUS_RECORDS');
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_document_previous_records;
    --
    /**
    * Returns all previous records done in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about previous records
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_prev_record_all';
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
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
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_EPIS_DOC_PROF';
        IF NOT get_last_epis_doc_prof(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => l_patient,
                                      i_visit         => l_visit,
                                      i_episode       => l_episode,
                                      i_documentation => i_documentation,
                                      o_last_doc_det  => o_last_doc_det,
                                      o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_prev_records);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN O_PREV_RECORDS';
        OPEN o_prev_records FOR
            SELECT /*+ opt_estimate(table t rows=1) */
             1 rec_order,
             ed.flg_status,
             edd.dt_creation_tstz,
             de.rank,
             pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
             edd.id_epis_documentation_det,
             edd.id_documentation,
             edd.id_doc_element_crit,
             NULL desc_doc_component,
             pk_touch_option_ti.get_element_description(i_lang,
                                                        i_prof,
                                                        de.flg_type,
                                                        de.id_master_item,
                                                        decr.code_element_close) desc_element_close,
             get_formatted_value(i_lang,
                                 i_prof,
                                 de.flg_type,
                                 edd.value,
                                 edd.value_properties,
                                 de.input_mask,
                                 de.flg_optional_value,
                                 de.flg_element_domain_type,
                                 de.code_element_domain,
                                 edd.dt_creation_tstz) VALUE,
             de.flg_type flg_type_element,
             pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
             pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
             pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
             pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
             pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
             pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
             de.display_format,
             de.separator
              FROM epis_documentation ed
              JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
              JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
              JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
              JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                ON t.id_episode = ed.id_episode
             WHERE edd.id_documentation = i_documentation
               AND t.ed_flg_status != pk_alert_constant.g_cancelled
               AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel
            ----------
            UNION ALL
            --Thematic Workflow
            SELECT /*+ opt_estimate(table t rows=1) */
             2 rec_order,
             ed.flg_status,
             edd.dt_creation_tstz,
             de.rank,
             pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
             edd.id_epis_documentation_det,
             edd.id_documentation,
             edd.id_doc_element_crit,
             pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
             decode(dcr.flg_criteria,
                    'I',
                    NULL,
                    pk_touch_option_ti.get_element_description(i_lang,
                                                               i_prof,
                                                               de.flg_type,
                                                               de.id_master_item,
                                                               decr.code_element_close)) desc_element_close,
             edd.value,
             de.flg_type flg_type_element,
             pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
             pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
             pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
             pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
             pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
             pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
             NULL display_format,
             NULL separator
              FROM epis_documentation ed
              JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
              JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
              JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
              JOIN documentation d
                ON d.id_documentation = de.id_documentation
              JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
              JOIN doc_criteria dcr
                ON dcr.id_doc_criteria = decr.id_doc_criteria
              JOIN documentation_rel dr
                ON dr.id_documentation_action = d.id_documentation
              JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                ON t.id_episode = ed.id_episode
             WHERE dr.id_documentation = i_documentation
               AND dr.flg_action = g_flg_workflow
               AND t.ed_flg_status != pk_alert_constant.g_cancelled
               AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel
             ORDER BY rec_order, id_documentation, dt_creation_tstz DESC, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, l_function_name);
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_doc_prev_record_all;
    --
    /**
    * Returns the last previous record done in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about last previous record
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_last
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_prev_record_last';
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
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
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_EPIS_DOC_PROF';
        IF NOT get_last_epis_doc_prof(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => l_patient,
                                      i_visit         => l_visit,
                                      i_episode       => l_episode,
                                      i_documentation => i_documentation,
                                      o_last_doc_det  => o_last_doc_det,
                                      o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_prev_records);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN O_PREV_RECORDS';
        OPEN o_prev_records FOR
            SELECT rec_order,
                   flg_status,
                   dt_creation_tstz,
                   rank,
                   dt_creation,
                   id_epis_documentation_det,
                   id_documentation,
                   id_doc_element_crit,
                   desc_doc_component,
                   desc_element_close,
                   VALUE,
                   flg_type_element,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   desc_quantifier,
                   desc_quantification,
                   desc_qualification,
                   display_format,
                   separator
              FROM (SELECT /*+ opt_estimate(table t rows=1) */
                     1 rec_order,
                     ed.flg_status,
                     edd.dt_creation_tstz,
                     de.rank,
                     pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
                     edd.id_epis_documentation_det,
                     edd.id_documentation,
                     edd.id_doc_element_crit,
                     NULL desc_doc_component,
                     pk_touch_option_ti.get_element_description(i_lang,
                                                                i_prof,
                                                                de.flg_type,
                                                                de.id_master_item,
                                                                decr.code_element_close) desc_element_close,
                     get_formatted_value(i_lang,
                                         i_prof,
                                         de.flg_type,
                                         edd.value,
                                         edd.value_properties,
                                         de.input_mask,
                                         de.flg_optional_value,
                                         de.flg_element_domain_type,
                                         de.code_element_domain,
                                         edd.dt_creation_tstz) VALUE,
                     de.flg_type flg_type_element,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      ed.id_professional,
                                                      ed.dt_creation_tstz,
                                                      ed.id_episode) desc_speciality,
                     pk_date_utils.date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
                     pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                     pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                     pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                     pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                     de.display_format,
                     de.separator,
                     rank() over(ORDER BY ed.dt_creation_tstz DESC NULLS LAST) srlno
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                      JOIN doc_element_crit decr
                        ON decr.id_doc_element_crit = edd.id_doc_element_crit
                      JOIN doc_element de
                        ON de.id_doc_element = decr.id_doc_element
                      JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                        ON t.id_episode = ed.id_episode
                     WHERE edd.id_documentation = i_documentation
                       AND t.ed_flg_status != pk_alert_constant.g_cancelled
                       AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel)
             WHERE srlno = 1
            UNION ALL
            --Thematic Workflow
            SELECT rec_order,
                   flg_status,
                   dt_creation_tstz,
                   rank,
                   dt_creation,
                   id_epis_documentation_det,
                   id_documentation,
                   id_doc_element_crit,
                   desc_doc_component,
                   desc_element_close,
                   VALUE,
                   flg_type_element,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   desc_quantifier,
                   desc_quantification,
                   desc_qualification,
                   display_format,
                   separator
              FROM (SELECT /*+ opt_estimate(table t rows=1) */
                     2 rec_order,
                     ed.flg_status,
                     edd.dt_creation_tstz,
                     de.rank,
                     pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
                     edd.id_epis_documentation_det,
                     edd.id_documentation,
                     edd.id_doc_element_crit,
                     pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                     decode(dcr.flg_criteria,
                            'I',
                            NULL,
                            pk_touch_option_ti.get_element_description(i_lang,
                                                                       i_prof,
                                                                       de.flg_type,
                                                                       de.id_master_item,
                                                                       decr.code_element_close)) desc_element_close,
                     edd.value,
                     de.flg_type flg_type_element,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      ed.id_professional,
                                                      ed.dt_creation_tstz,
                                                      ed.id_episode) desc_speciality,
                     pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
                     pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                     pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                     pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                     pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                     de.display_format,
                     de.separator,
                     rank() over(ORDER BY ed.dt_creation_tstz DESC NULLS LAST) srlno
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                      JOIN doc_element_crit decr
                        ON decr.id_doc_element_crit = edd.id_doc_element_crit
                      JOIN doc_element de
                        ON de.id_doc_element = decr.id_doc_element
                      JOIN documentation d
                        ON d.id_documentation = de.id_documentation
                      JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                      JOIN doc_criteria dcr
                        ON dcr.id_doc_criteria = decr.id_doc_criteria
                      JOIN documentation_rel dr
                        ON dr.id_documentation_action = d.id_documentation
                      JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                        ON t.id_episode = ed.id_episode
                     WHERE dr.id_documentation = i_documentation
                       AND dr.flg_action = g_flg_workflow
                       AND t.ed_flg_status != pk_alert_constant.g_cancelled
                       AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel)
             WHERE srlno = 1
             ORDER BY rec_order, id_documentation, dt_creation_tstz DESC, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, l_function_name);
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_doc_prev_record_last;
    --
    /**
    * Returns all previous records done by current professional in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about all previous records done by professional
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_my
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_prev_record_my';
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
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
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_EPIS_DOC_PROF';
        IF NOT get_last_epis_doc_prof(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => l_patient,
                                      i_visit         => l_visit,
                                      i_episode       => l_episode,
                                      i_documentation => i_documentation,
                                      o_last_doc_det  => o_last_doc_det,
                                      o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_prev_records);
            RETURN FALSE;
        END IF;
    
        g_error := 'GET LAST_DOC_DET';
        OPEN o_prev_records FOR
            SELECT /*+ opt_estimate(table t rows=1) */
             1 rec_order,
             ed.flg_status,
             edd.dt_creation_tstz,
             de.rank,
             pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
             edd.id_epis_documentation_det,
             edd.id_documentation,
             edd.id_doc_element_crit,
             NULL desc_doc_component,
             pk_touch_option_ti.get_element_description(i_lang,
                                                        i_prof,
                                                        de.flg_type,
                                                        de.id_master_item,
                                                        decr.code_element_close) desc_element_close,
             get_formatted_value(i_lang,
                                 i_prof,
                                 de.flg_type,
                                 edd.value,
                                 edd.value_properties,
                                 de.input_mask,
                                 de.flg_optional_value,
                                 de.flg_element_domain_type,
                                 de.code_element_domain,
                                 edd.dt_creation_tstz) VALUE,
             de.flg_type flg_type_element,
             pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
             pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
             pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
             pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
             pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
             pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
             de.display_format,
             de.separator
              FROM epis_documentation ed
              JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
              JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
              JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
              JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                ON t.id_episode = ed.id_episode
             WHERE edd.id_documentation = i_documentation
               AND ed.id_professional = i_prof.id
               AND t.ed_flg_status != pk_alert_constant.g_cancelled
               AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel
            UNION ALL
            --Thematic Workflow
            SELECT /*+ opt_estimate(table t rows=1) */
             2 rec_order,
             ed.flg_status,
             edd.dt_creation_tstz,
             de.rank,
             pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
             edd.id_epis_documentation_det,
             edd.id_documentation,
             edd.id_doc_element_crit,
             pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
             decode(dcr.flg_criteria,
                    'I',
                    NULL,
                    pk_touch_option_ti.get_element_description(i_lang,
                                                               i_prof,
                                                               de.flg_type,
                                                               de.id_master_item,
                                                               decr.code_element_close)) desc_element_close,
             edd.value,
             de.flg_type flg_type_element,
             pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
             pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
             pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
             pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
             pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
             pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
             NULL display_format,
             NULL separator
              FROM epis_documentation ed
              JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
              JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
              JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
              JOIN documentation d
                ON d.id_documentation = de.id_documentation
              JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
              JOIN doc_criteria dcr
                ON dcr.id_doc_criteria = decr.id_doc_criteria
              JOIN documentation_rel dr
                ON dr.id_documentation_action = d.id_documentation
              JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                ON t.id_episode = ed.id_episode
             WHERE dr.id_documentation = i_documentation
               AND ed.id_professional = i_prof.id
               AND dr.flg_action = g_flg_workflow
               AND t.ed_flg_status != pk_alert_constant.g_cancelled
               AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel
             ORDER BY rec_order, id_documentation, dt_creation_tstz DESC, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, l_function_name);
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_doc_prev_record_my;

    /**
    * Returns the last previous record done by current professional in a component for defined scope
    *
    * @param i_lang              Professional preferred language
    * @param i_prof              Professional identification and its context (institution and software)
    * @param i_scope             Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type        Scope type (by episode; by visit; by patient)
    * @param i_documentation     Component ID  
    * @param o_last_doc_det      Last id_epis_documentation_det of component registered by current profissional
    * @param o_prev_records      Cursor containing info about the last previous record done by professional
    * @param o_error             Error message
    *                        
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO (code refactoring)
    * @version 2.6.0.4
    * @since   11/25/2010
    */
    FUNCTION get_doc_prev_record_may_last
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_documentation IN documentation.id_documentation%TYPE,
        o_last_doc_det  OUT epis_documentation_det.id_epis_documentation_det%TYPE,
        o_prev_records  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_prev_record_may_last';
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
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
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_EPIS_DOC_PROF';
        IF NOT get_last_epis_doc_prof(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => l_patient,
                                      i_visit         => l_visit,
                                      i_episode       => l_episode,
                                      i_documentation => i_documentation,
                                      o_last_doc_det  => o_last_doc_det,
                                      o_error         => o_error)
        THEN
            pk_types.open_my_cursor(o_prev_records);
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN O_PREV_RECORDSx';
        OPEN o_prev_records FOR
            SELECT rec_order,
                   flg_status,
                   dt_creation_tstz,
                   rank,
                   dt_creation,
                   id_epis_documentation_det,
                   id_documentation,
                   id_doc_element_crit,
                   desc_doc_component,
                   desc_element_close,
                   VALUE,
                   flg_type_element,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   desc_quantifier,
                   desc_quantification,
                   desc_qualification,
                   display_format,
                   separator
              FROM (SELECT /*+ opt_estimate(table t rows=1) */
                     1 rec_order,
                     ed.flg_status,
                     edd.dt_creation_tstz,
                     de.rank,
                     pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
                     edd.id_epis_documentation_det,
                     edd.id_documentation,
                     edd.id_doc_element_crit,
                     NULL desc_doc_component,
                     pk_touch_option_ti.get_element_description(i_lang,
                                                                i_prof,
                                                                de.flg_type,
                                                                de.id_master_item,
                                                                decr.code_element_close) desc_element_close,
                     get_formatted_value(i_lang,
                                         i_prof,
                                         de.flg_type,
                                         edd.value,
                                         edd.value_properties,
                                         de.input_mask,
                                         de.flg_optional_value,
                                         de.flg_element_domain_type,
                                         de.code_element_domain,
                                         edd.dt_creation_tstz) VALUE,
                     de.flg_type flg_type_element,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      ed.id_professional,
                                                      ed.dt_creation_tstz,
                                                      ed.id_episode) desc_speciality,
                     pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
                     pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                     pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                     pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                     pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                     de.display_format,
                     de.separator,
                     rank() over(ORDER BY ed.dt_creation_tstz DESC NULLS LAST) srlno
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                      JOIN doc_element_crit decr
                        ON decr.id_doc_element_crit = edd.id_doc_element_crit
                      JOIN doc_element de
                        ON de.id_doc_element = decr.id_doc_element
                      JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                        ON t.id_episode = ed.id_episode
                     WHERE edd.id_documentation = i_documentation
                       AND ed.id_professional = i_prof.id
                       AND t.ed_flg_status != pk_alert_constant.g_cancelled
                       AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel)
             WHERE srlno = 1
            UNION ALL
            --Thematic Workflow
            SELECT rec_order,
                   flg_status,
                   dt_creation_tstz,
                   rank,
                   dt_creation,
                   id_epis_documentation_det,
                   id_documentation,
                   id_doc_element_crit,
                   desc_doc_component,
                   desc_element_close,
                   VALUE,
                   flg_type_element,
                   nick_name,
                   desc_speciality,
                   date_target,
                   hour_target,
                   desc_quantifier,
                   desc_quantification,
                   desc_qualification,
                   display_format,
                   separator
              FROM (SELECT /*+ opt_estimate(table t rows=1) */
                     2 rec_order,
                     ed.flg_status,
                     edd.dt_creation_tstz,
                     de.rank,
                     pk_date_utils.date_send_tsz(i_lang, edd.dt_creation_tstz, i_prof) dt_creation,
                     edd.id_epis_documentation_det,
                     edd.id_documentation,
                     edd.id_doc_element_crit,
                     pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                     decode(dcr.flg_criteria,
                            'I',
                            NULL,
                            pk_touch_option_ti.get_element_description(i_lang,
                                                                       i_prof,
                                                                       de.flg_type,
                                                                       de.id_master_item,
                                                                       decr.code_element_close)) desc_element_close,
                     edd.value,
                     de.flg_type flg_type_element,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, edd.id_professional) nick_name,
                     pk_prof_utils.get_spec_signature(i_lang,
                                                      i_prof,
                                                      ed.id_professional,
                                                      ed.dt_creation_tstz,
                                                      ed.id_episode) desc_speciality,
                     pk_date_utils. date_chr_short_read_tsz(i_lang, edd.dt_creation_tstz, i_prof) date_target,
                     pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_creation_tstz, i_prof.institution, i_prof.software) hour_target,
                     pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                     pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                     pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                     de.display_format,
                     de.separator,
                     rank() over(ORDER BY ed.dt_creation_tstz DESC NULLS LAST) srlno
                      FROM epis_documentation ed
                      JOIN epis_documentation_det edd
                        ON ed.id_epis_documentation = edd.id_epis_documentation
                      JOIN doc_element_crit decr
                        ON decr.id_doc_element_crit = edd.id_doc_element_crit
                      JOIN doc_element de
                        ON de.id_doc_element = decr.id_doc_element
                      JOIN documentation d
                        ON d.id_documentation = de.id_documentation
                      JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                      JOIN doc_criteria dcr
                        ON dcr.id_doc_criteria = decr.id_doc_criteria
                      JOIN documentation_rel dr
                        ON dr.id_documentation_action = d.id_documentation
                      JOIN TABLE(tf_epis_documentation(i_lang, i_prof, l_patient, l_episode, l_visit)) t
                        ON t.id_episode = ed.id_episode
                     WHERE dr.id_documentation = i_documentation
                       AND ed.id_professional = i_prof.id
                       AND dr.flg_action = g_flg_workflow
                       AND t.ed_flg_status != pk_alert_constant.g_cancelled
                       AND t.e_flg_status != pk_alert_constant.g_epis_status_cancel)
             WHERE srlno = 1
             ORDER BY rec_order, id_documentation, dt_creation_tstz DESC, rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'An input parameter has an unexpected value',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   l_function_name);
            
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_PREV_RECORD_MAY_LAST');
                /* Open out cursors */
                pk_types.open_my_cursor(o_prev_records);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
    END get_doc_prev_record_may_last;
    --
    /********************************************************************************************
    * Checks if a advanced directives has registers in an episode.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_doc_area          the doc area id    
    * @param o_advanced          array with info advanced directives
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emília Taborda
    * @version                   1.0    
    * @since                     2007/07/18
    ********************************************************************************************/
    FUNCTION get_advanced_directives_exists
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_advanced OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_has_adv_directives VARCHAR2(1 CHAR) := g_no;
        l_adv_directive_sh   sys_shortcut.id_sys_shortcut%TYPE;
        l_id_patient         patient.id_patient%TYPE;
    
    BEGIN
        -- <DENORM_EPISODE_JOSE_BRITO>
        g_error := 'GET PATIENT ID';
        BEGIN
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_patient := NULL;
        END;
    
        g_error := 'CALL PK_ADVANCED_DIRECTIVES.GET_ADV_DIRECTIVES_FOR_HEADER';
        IF NOT pk_advanced_directives.get_adv_directives_for_header(i_lang,
                                                                    i_prof,
                                                                    l_id_patient,
                                                                    i_episode,
                                                                    l_has_adv_directives,
                                                                    l_adv_directive_sh,
                                                                    o_error)
        THEN
            pk_types.open_my_cursor(o_advanced);
            RETURN FALSE;
        ELSIF l_has_adv_directives = g_yes
        THEN
            OPEN o_advanced FOR
                SELECT pk_message.get_message(i_lang, 'ADVANCED_DIRECTIVES_M001') desc_advanced,
                       l_adv_directive_sh id_sys_shortcut
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_advanced);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_ADVANCED_DIRECTIVES_EXISTS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_advanced);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_advanced_directives_exists;

    /**
    * Returns the touch option mode type for the given professional and doc area
    *
    * @param i_prof              professional, software and institution ids
    * @param i_doc_area          documentation area
    *
    * @return                    the touch option mode type
    *
    * @author                    Eduardo Lourenco
    * @version                   2.5.0.7.2
    * @since                     2009/11/21
    */
    FUNCTION get_touch_option_type
    (
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN VARCHAR2 IS
        l_type doc_area_inst_soft.flg_type%TYPE;
    BEGIN
        SELECT flg_type
          INTO l_type
          FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_prof.institution, i_prof.software))
         WHERE rownum <= 1;
        RETURN l_type;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_touch_option_type;

    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_flg_type          type of identifier
    * @param o_templates         A cursor with the doc templates
    * @param o_error             Error message
    *
    * @value i_flg_type  {*} 'C' Complaint {*} 'I' Intervention {*} 'A' Appointment {*} 'D' Doc area {*} 'S' Specialty {*} 'E' Exam {*} 'T' Schedule event {*} 'M' Medication
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Luís Gaspar
    * @version                   1.0
    * @since                     2007/08/31
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/04/03
    *                             Added i_flg_type parameter
    *
    * @deprecated Use get_doc_template_list with id_doc_area argument instead.
    ********************************************************************************************/
    FUNCTION get_doc_template_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN doc_template_context.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_template profile_template.id_profile_template%TYPE;
        l_type             doc_template_context.flg_type%TYPE;
        l_gender           patient.gender%TYPE;
        l_age              patient.age%TYPE;
    BEGIN
    
        g_error            := 'GET PROFESSIONAL''S TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'GET DOCUMENTATION TYPE XPTO - ' || i_flg_type;
        l_type  := i_flg_type;
        /*l_type  := get_touch_option_type(i_prof, pk_summary_page.g_doc_area_hist_ill);
        IF l_type IS NULL
        THEN
            l_type := get_touch_option_type(i_prof, pk_summary_page.g_doc_area_rev_sys);
            IF l_type IS NULL
            THEN
                l_type := get_touch_option_type(i_prof, pk_summary_page.g_doc_area_phy_exam);
                IF l_type IS NULL
                THEN
                    l_type := get_touch_option_type(i_prof, pk_summary_page.g_doc_area_phy_assess);
                END IF;
            END IF;
        END IF;*/
    
        --
    
        g_error := 'CALLING GET_PAT_INFO_BY_EPISODE';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang, i_episode, l_gender, l_age)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_type = g_flg_type_complaint_sch_evnt
        THEN
            g_error := 'OPEN O_TEMPLATES BY COMPLAINT / SCH EVENT';
            OPEN o_templates FOR
                SELECT dt.id_doc_template,
                       pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                       edt.id_epis_doc_template,
                       decode(edt.id_epis_doc_template, NULL, NULL, 'HandSelectedIcon') flg_icon
                  FROM doc_template dt
                  LEFT JOIN epis_doc_template edt
                    ON dt.id_doc_template = edt.id_doc_template
                   AND edt.id_episode = i_episode
                   AND edt.id_prof_cancel IS NULL -- exclude cancelled doc templates
                   AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL) --Selected template is applicable to current profile
                 WHERE dt.flg_available = g_available
                   AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                   AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                   AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                   AND dt.id_doc_template IN
                       (SELECT dtc.id_doc_template
                          FROM doc_template_context dtc
                         WHERE dtc.flg_type IN (g_flg_type_complaint_sch_evnt, g_flg_type_appointment)
                           AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
                           AND dtc.id_institution IN (0, i_prof.institution)
                           AND dtc.id_software IN (0, i_prof.software))
                 ORDER BY flg_icon, 2;
        
        ELSE
            g_error := 'OPEN O_TEMPLATES BY APPOINTMENT';
            OPEN o_templates FOR
                SELECT DISTINCT dt.id_doc_template,
                                pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                                edt.id_epis_doc_template,
                                decode(edt.id_epis_doc_template, NULL, NULL, 'HandSelectedIcon') flg_icon
                  FROM doc_template dt
                 INNER JOIN doc_template_context dtc
                    ON dt.id_doc_template = dtc.id_doc_template
                  LEFT JOIN epis_doc_template edt
                    ON dt.id_doc_template = edt.id_doc_template
                   AND edt.id_episode = i_episode
                   AND edt.id_prof_cancel IS NULL -- exclude cancelled doc templates
                   AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL) --Selected template is applicable to current profile
                 WHERE ((dtc.flg_type = l_type AND l_type != g_flg_type_complaint_sch_evnt) OR
                       (l_type = g_flg_type_complaint_sch_evnt AND
                       dtc.flg_type IN (g_flg_type_complaint_sch_evnt, g_flg_type_appointment)))
                   AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
                   AND dtc.id_institution IN (0, i_prof.institution)
                   AND dtc.id_software IN (0, i_prof.software)
                   AND dt.flg_available = g_available
                   AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                   AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                   AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)
                 ORDER BY flg_icon, 2;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_LIST');
                /* Open out cursors */
                pk_types.open_my_cursor(o_templates);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_list;
    --
    /********************************************************************************************
    * Sets a new doc template list to the episode. Calls set_epis_doc_templ_no_commit.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2007/10/16
    ********************************************************************************************/
    FUNCTION set_epis_doc_template_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_epis_doc_templ_no_commit(i_lang,
                                            i_prof,
                                            i_episode,
                                            i_doc_template_in,
                                            i_epis_doc_template_out,
                                            NULL,
                                            o_epis_doc_template,
                                            o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_EPIS_DOC_TEMPLATE_LIST');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Rollback changes */
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_epis_doc_template_list;
    --
    /********************************************************************************************
    * Sets a new doc template list to the episode. Calls set_epis_doc_templ_no_commit.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param i_doc_area               Doc area identifier
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2007/10/16
    ********************************************************************************************/
    FUNCTION set_epis_doc_template_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT set_epis_doc_templ_no_commit(i_lang,
                                            i_prof,
                                            i_episode,
                                            i_doc_template_in,
                                            i_epis_doc_template_out,
                                            i_doc_area,
                                            o_epis_doc_template,
                                            o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_EPIS_DOC_TEMPLATE_LIST');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Rollback changes */
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_epis_doc_template_list;
    --    
    /********************************************************************************************
    * Sets a new doc template list to the episode.
    *
    * @param i_lang                   language id
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                the episode id
    * @param i_doc_template_in        the new doc templates id selected
    * @param i_epis_doc_template_out  the existing epis doc templates id to cancel
    * @param o_epis_doc_template      The new epis_doc_template ids created
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author                         Luís Gaspar
    * @version                        1.0   
    * @since                          2007/08/31
    ********************************************************************************************/
    FUNCTION set_epis_doc_templ_no_commit
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_template_in       IN table_number,
        i_epis_doc_template_out IN table_number,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_epis_doc_template     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_template  profile_template.id_profile_template%TYPE;
        l_epis_doc_template epis_doc_template.id_epis_doc_template%TYPE;
    
    BEGIN
        o_epis_doc_template := table_number();
        g_sysdate_tstz      := current_timestamp;
        --    
        g_error := 'FIND profile template';
        SELECT ppt.id_profile_template
          INTO l_profile_template
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND pt.id_profile_template = ppt.id_profile_template
           AND pt.id_software = i_prof.software;
        --
        IF i_doc_template_in.count > 0
        THEN
            FOR i IN i_doc_template_in.first .. i_doc_template_in.last
            LOOP
                g_error := 'GET EPIS_DOC_TEMPLATE ID(' || i || ')';
                SELECT seq_epis_doc_template.nextval
                  INTO l_epis_doc_template
                  FROM dual;
                --
                g_error := 'INSERT INTO epis_doc_template(' || i || ')';
                INSERT INTO epis_doc_template
                    (id_epis_doc_template,
                     dt_register,
                     id_prof_register,
                     id_episode,
                     id_doc_template,
                     id_profile_template,
                     id_doc_area)
                VALUES
                    (l_epis_doc_template,
                     g_sysdate_tstz,
                     i_prof.id,
                     i_episode,
                     i_doc_template_in(i),
                     l_profile_template,
                     i_doc_area);
                --
                o_epis_doc_template.extend(1);
                o_epis_doc_template(i) := l_epis_doc_template;
            END LOOP;
        END IF;
        --
        IF i_epis_doc_template_out.count > 0
        THEN
            FOR i IN i_epis_doc_template_out.first .. i_epis_doc_template_out.last
            LOOP
                g_error := 'updating epis_doc_template(' || i || ')';
                UPDATE epis_doc_template edt
                   SET edt.dt_cancel = g_sysdate_tstz, edt.id_prof_cancel = i_prof.id
                 WHERE edt.id_epis_doc_template = i_epis_doc_template_out(i);
                --
                -- check the update alter just one line
                IF (SQL%ROWCOUNT != 1)
                THEN
                    g_error := 'unexpected update rowcount(' || i || ') : ' || SQL%ROWCOUNT || ' rows updated.';
                    RAISE g_exception;
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_EPIS_DOC_TEMPL_NO_COMMIT');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                /* Rollback changes */
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_epis_doc_templ_no_commit;
    --

    /********************************************************************************************
    * Gets doc_template criteria. 
    *
    * @param i_criteria          the criteria key we are looking for
    * @param i_criterias         the criterias keys
    * @param i_values            the criterias values
    *
    * @return                    criteria value(key)
    *
    * @author                    Luís Gaspar 
    * @since                     14-Set-2007
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template_criteria
    (
        i_criteria  IN VARCHAR2,
        i_criterias IN table_varchar,
        i_values    IN table_varchar
    ) RETURN VARCHAR2 IS
        l_value VARCHAR2(200 CHAR);
    BEGIN
        FOR i IN i_criterias.first .. i_criterias.last
        LOOP
            IF (i_criterias(i) = i_criteria)
            THEN
                l_value := i_values(i);
                EXIT;
            END IF;
        END LOOP;
        RETURN l_value;
    END get_doc_template_criteria;

    --
    /********************************************************************************************
    * Gets doc_template for complaint criteria. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id,
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Luís Gaspar 
    * @since                     14-Set-2007
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template_by_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_gender            IN VARCHAR2,
        i_age               IN VARCHAR2,
        i_doc_area_flg_type IN doc_area_inst_soft.flg_type%TYPE,
        i_ignore_profile    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        function_call_excep EXCEPTION;
        l_complaint         table_number;
        l_comp_filter       sys_config.value%TYPE;
        l_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin_serv IS
            SELECT ei.id_dcs_requested
              FROM epis_info ei
             INNER JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE e.id_episode = i_episode;
    
    BEGIN
        g_error       := 'GET CONFIG';
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
        --    
        g_error := 'GET_COMPLAINT';
        IF NOT pk_complaint.get_epis_act_complaint(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   o_id_complaint => l_complaint,
                                                   o_error        => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        IF (l_complaint IS NULL)
        THEN
            g_error := 'EPISODE HAS NO ACTIVE COMPLAINT';
            RAISE g_exception;
        END IF;
    
        IF l_comp_filter = pk_complaint.g_comp_filter_prf
        THEN
            -- Template by Complaint 
            g_error := 'GET_APPLICABLE_TEMPLATES BY COMPLAINT';
            IF NOT get_applicable_templates(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_gender         => i_gender,
                                            i_age            => i_age,
                                            i_flg_type       => i_doc_area_flg_type,
                                            i_context        => l_complaint,
                                            i_ignore_profile => i_ignore_profile,
                                            o_templates      => o_templates,
                                            o_error          => o_error)
            
            THEN
                RAISE function_call_excep;
            END IF;
        
        ELSIF l_comp_filter = pk_complaint.g_comp_filter_dcs
        THEN
            -- Template by Complaint and ID_DEP_CLIN_SERV
            g_error := 'OPEN C_DEP_CLIN_SERV';
            OPEN c_dep_clin_serv;
            FETCH c_dep_clin_serv
                INTO l_dep_clin_serv;
            CLOSE c_dep_clin_serv;
        
            g_error := 'GET_APPLICABLE_TEMPLATES BY COMPLAINT + DEP_CLIN_SERV';
            IF NOT get_applicable_templates(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_gender         => i_gender,
                                            i_age            => i_age,
                                            i_flg_type       => i_doc_area_flg_type,
                                            i_context        => l_complaint,
                                            i_dep_clin_serv  => l_dep_clin_serv,
                                            i_ignore_profile => i_ignore_profile,
                                            o_templates      => o_templates,
                                            o_error          => o_error)
            
            THEN
                RAISE function_call_excep;
            END IF;
        
        ELSE
            g_error := 'NO SYS_CONFIG: COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software ||
                       ') DEFINED!';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_COMPLAINT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_COMPLAINT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_complaint;

    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by appointment (flg_type = A)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param i_ignore_profile    Ignore professional profile? (Y/N) (default N)
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Luís Gaspar
    * @version                   1.0   
    * @since                     2007/08/31
    *
    * @changes 
    * 2009/04/17(Ariel Machado) - Renamed function name to be more expressive
    ********************************************************************************************/
    FUNCTION get_doc_template_by_appnt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_gender         IN VARCHAR2,
        i_age            IN VARCHAR2,
        i_ignore_profile IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_templates      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_clin_serv IS
            SELECT e.id_clinical_service
              FROM episode e
             WHERE e.id_episode = i_episode;
        l_id_clin_serv clinical_service.id_clinical_service%TYPE;
    BEGIN
        g_error := 'GET CLIN_SERV';
        OPEN c_clin_serv;
        FETCH c_clin_serv
            INTO l_id_clin_serv;
        CLOSE c_clin_serv;
    
        g_error := 'GET APPLICABLE_TEMPLATES BY APPOINTMENT';
        RETURN get_applicable_templates(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_gender         => i_gender,
                                        i_age            => i_age,
                                        i_flg_type       => g_flg_type_appointment,
                                        i_context        => table_number(l_id_clin_serv),
                                        i_ignore_profile => i_ignore_profile,
                                        o_templates      => o_templates,
                                        o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_APPNT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_appnt;
    --
    /********************************************************************************************
    * Gets the list of doc_templates for doc_area criteria. 
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_area          the doc_area id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Luís Gaspar 
    * @since                     14-Set-2007
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template_by_area
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET APPLICABLE_TEMPLATES BY AREA';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_doc_area,
                                        i_context   => table_number(i_doc_area),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_AREA');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_area;
    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by clinical service from epis_info.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Luís Gaspar
    * @version                   1.0   
    * @since                     2007/10/02
    ********************************************************************************************/
    FUNCTION get_doc_template_by_sch_dcs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_sch_dcs IS
            SELECT id_dcs_requested
              FROM epis_info epo
             WHERE epo.id_episode = i_episode;
    
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
    BEGIN
        -- This applied method to implement this type of parametrization doesn't make sense because doesn't use id_context
        -- but id_dep_clin_serv. Instead, why not use this putting id_dep_clin_serv value into id_context?
        -- Already done, then id_context is NULL.
    
        g_error := 'GET SCHEDULED DEP_CLIN_SERV';
        OPEN c_sch_dcs;
        FETCH c_sch_dcs
            INTO l_dep_clin_serv;
        CLOSE c_sch_dcs;
    
        g_error := 'GET_APPLICABLE_TEMPLATES BY SCHEDULED DEP_CLIN_SERV';
        RETURN get_applicable_templates(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_gender        => i_gender,
                                        i_age           => i_age,
                                        i_flg_type      => g_flg_type_sch_dep_clin_serv,
                                        i_context       => NULL,
                                        i_dep_clin_serv => l_dep_clin_serv,
                                        o_templates     => o_templates,
                                        o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_SCH_DCS');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_sch_dcs;
    --
    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Luís Gaspar 
    * @since                     14-Set-2007
    * @version                   1.0
    *
    * @deprecated: Use get_doc_template with flg_type argument
    **********************************************************************************************/
    FUNCTION get_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_doc_template(i_lang,
                                i_prof,
                                i_patient,
                                i_episode,
                                i_doc_area,
                                i_context,
                                NULL,
                                o_templates,
                                o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE(flg_type)');
                /* Open out cursors */
                pk_types.open_my_cursor(o_templates);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template;
    --
    /**
    * Obter softwares a que o utilizador tem acesso        
    *
    * @param i_lang id da lingua
    * @param i_prof objecto do utilizador
    * @param i_inst id da instituição
    * @param o_list lista de softwares
    * @param o_erro variavel com mensagem de erro
    * @return                    true (sucess), false (error)
    *
    * @author João Eiras, 26-09-2007
    * @since 2.4.0
    * @version 1.0
    */
    FUNCTION get_touch_option_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT s.name, s.desc_software, s.id_software
              FROM prof_soft_inst psi, software s
             WHERE psi.id_professional = i_prof.id
               AND psi.id_institution = i_inst
               AND s.id_software = psi.id_software
               AND s.id_software != 0
               AND s.flg_mni = 'Y'
               AND EXISTS (SELECT 1
                      FROM doc_area da
                      JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, psi.id_institution, s.id_software)) dais
                        ON da.id_doc_area = dais.id_doc_area
                     WHERE dais.id_software = psi.id_software
                       AND dais.id_institution = psi.id_institution)
             ORDER BY id_software;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_TOUCH_OPTION_SOFTWARE');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
    END get_touch_option_software;
    --
    /********************************************************************************************
    * Devolve a última documentation de um episódio
    *
    * @param i_lang                id da lingua
    * @param i_prof                utilizador autenticado
    * @param i_episode             id do episódio 
    * @param i_doc_area            id da doc_area da qual se verificam se foram feitos registos
    * @param o_last_epis_doc       Last documentation episode ID 
    * @param o_last_date_epis_doc  Data do último episódio
    * @param o_error               Error message
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/01
    *
    * @deprecated                  Use get_last_doc_area with i_doc_template=NULL instead 
    **********************************************************************************************/
    /*
    FUNCTION get_last_doc_area
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Calling get_last_doc_area from deprecated function';
        RETURN get_last_doc_area(i_lang,
                                 i_prof,
                                 i_episode,
                                 i_doc_area,
                                 NULL,
                                 o_last_epis_doc,
                                 o_last_date_epis_doc,
                                 o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_LAST_DOC_AREA');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
    END get_last_doc_area;
    */
    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by intervention.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_context           the context id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emilia Taborda
    * @version                   1.0   
    * @since                     2007/10/12
    ********************************************************************************************/
    FUNCTION get_doc_template_by_interv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET APPLICABLE_TEMPLATES BY INTERVENTION';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_intervention,
                                        i_context   => table_number(i_context),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_INTERV');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_interv;

    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by intervention.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_context           the context id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emilia Taborda
    * @version                   1.0   
    * @since                     2007/10/12
    ********************************************************************************************/
    FUNCTION get_doc_template_by_comm_order
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_flg_type  IN doc_template_context.flg_type%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET APPLICABLE_TEMPLATES BY COMMUNICATION OR MEDICAL ORDER';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => i_flg_type,
                                        i_context   => table_number(i_context),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_COMM_ORDER');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_comm_order;
    --
    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    *
    * @return                    number
    *
    * @author                    Emilia Taborda 
    * @version                   1.0
    * @since                     2007/10/15
    **********************************************************************************************/
    FUNCTION get_doc_template_internal
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_context  IN doc_template_context.id_context%TYPE
    ) RETURN VARCHAR2 IS
        l_c_doc_template pk_types.cursor_type;
        l_doc_template   doc_template.id_doc_template%TYPE;
        l_desc_template  pk_translation.t_desc_translation;
        l_error          t_error_out;
    
    BEGIN
        g_error := 'CALL get_doc_template';
        IF NOT get_doc_template(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                i_episode   => i_episode,
                                i_doc_area  => i_doc_area,
                                i_context   => i_context,
                                o_templates => l_c_doc_template,
                                o_error     => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        FETCH l_c_doc_template
            INTO l_doc_template, l_desc_template;
        CLOSE l_c_doc_template;
        --
        RETURN l_doc_template;
    END;
    --
    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel by exam.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_context           the context id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Emilia Taborda
    * @version                   1.0   
    * @since                     2007/10/15
    ********************************************************************************************/
    FUNCTION get_doc_template_by_exam
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_APPLICABLE_TEMPLATES BY EXAM';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_exam,
                                        i_context   => table_number(i_context),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_EXAM');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_exam;

    /********************************************************************************************
    * Returns a list of available doc templates for selection or cancel for Exams and Others Exams at Results Interpretation Area.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_context           the context id
    * @param i_gender            the patient gender
    * @param i_age               the patient age
    * @param o_doc_template      the doc template id
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Teresa Coutinho
    * @version                   1.0   
    * @since                     2013/10/12
    ********************************************************************************************/
    FUNCTION get_doc_template_by_exam_res
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_gender    IN VARCHAR2,
        i_age       IN VARCHAR2,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_APPLICABLE_TEMPLATES BY EXAM RESULT';
        RETURN get_applicable_templates(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_gender    => i_gender,
                                        i_age       => i_age,
                                        i_flg_type  => g_flg_type_exam_result,
                                        i_context   => table_number(i_context),
                                        o_templates => o_templates,
                                        o_error     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE_BY_EXAM_RES');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_doc_template_by_exam_res;
    --
    /********************************************************************************************
    * Checks if an episode has template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      José Silva (replacing pk_complaint.get_complaint_template_exists)
    * @version                     1.0
    * @since                       22-10-2007
    **********************************************************************************************/
    FUNCTION get_template_exists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        o_flg_data              OUT VARCHAR2,
        o_sys_shortcut          OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_default_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_default_template OUT pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count            NUMBER;
        l_flg_type         doc_area_inst_soft.flg_type%TYPE;
        l_flg_multiple     doc_area_inst_soft.flg_multiple%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_gender           patient.gender%TYPE;
        l_age              patient.age%TYPE;
    
        l_exception EXCEPTION;
    
        CURSOR c_doc_area IS
            SELECT dis.flg_type, dis.flg_multiple, dis.id_sys_shortcut_error
              FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_prof.institution, i_prof.software)) dis;
    
    BEGIN
    
        g_error := 'find profile template';
        SELECT ppt.id_profile_template
          INTO l_profile_template
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_profile_template = pt.id_profile_template
           AND pt.id_software = i_prof.software;
    
        g_error := 'GET DOC_AREA INFO';
        OPEN c_doc_area;
        FETCH c_doc_area
            INTO l_flg_type, l_flg_multiple, o_sys_shortcut;
        CLOSE c_doc_area;
    
        --According to CONTENT team, flg_multiple=Y is only supported for doc_areas with flag C and CT
        IF l_flg_multiple = g_yes
           AND l_flg_type IN (g_flg_type_complaint, g_flg_type_complaint_sch_evnt)
        THEN
        
            g_error := 'CALLING GET_PAT_INFO_BY_EPISODE';
            IF NOT pk_patient.get_pat_info_by_episode(i_lang, i_episode, l_gender, l_age)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'COUNT REGISTRIES epis_doc_template';
            SELECT COUNT(1)
              INTO l_count
              FROM doc_template dt
             INNER JOIN doc_template_context dtc
                ON dt.id_doc_template = dtc.id_doc_template
             INNER JOIN epis_doc_template edt
                ON dt.id_doc_template = edt.id_doc_template
               AND edt.id_episode = i_episode
               AND edt.id_prof_cancel IS NULL -- exclude cancelled doc templates
               AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL) --Selected template is applicable to current profile
             WHERE dtc.flg_type = l_flg_type
               AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
               AND (
                   -- COMMENT : Se o criterio for área + algo então limito os templates pre-seleccionados igual à doc_area da qual pretendo obter templates
                    (l_flg_type IN (g_flg_type_doc_area_appointmt,
                                    g_flg_type_doc_area_service,
                                    g_flg_type_doc_area_complaint,
                                    g_flg_type_doc_area) AND edt.id_doc_area = i_doc_area) OR
                   -- COMMENT : Se o criterio NÃO for área + algo então simplesmente se filtra pelo flg_type
                    (l_flg_type NOT IN (g_flg_type_doc_area_appointmt,
                                        g_flg_type_doc_area_service,
                                        g_flg_type_doc_area_complaint,
                                        g_flg_type_doc_area)))
               AND dtc.id_institution IN (0, i_prof.institution)
               AND dtc.id_software IN (0, i_prof.software)
               AND dt.flg_available = g_available
               AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
               AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
               AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL);
        
            IF l_count < 1
            THEN
                -- template search mode is by complaint/schedule event,
                -- and no templates were set in epis_doc_template:
                -- search again by appointment
                g_error := 'COUNT REGISTRIES epis_doc_template';
                SELECT COUNT(1)
                  INTO l_count
                  FROM doc_template dt
                 INNER JOIN doc_template_context dtc
                    ON dt.id_doc_template = dtc.id_doc_template
                 INNER JOIN epis_doc_template edt
                    ON dt.id_doc_template = edt.id_doc_template
                   AND edt.id_episode = i_episode
                   AND edt.id_prof_cancel IS NULL -- exclude cancelled doc templates
                   AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL) --Selected template is applicable to current profile
                 WHERE dtc.flg_type = g_flg_type_appointment
                   AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
                   AND dtc.id_institution IN (0, i_prof.institution)
                   AND dtc.id_software IN (0, i_prof.software)
                   AND dt.flg_available = g_available
                   AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                   AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                   AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL);
            END IF;
        ELSE
            l_count := 1;
        END IF;
        --
        IF l_count > 0
        THEN
            o_flg_data := g_yes;
        ELSE
            o_flg_data := g_no;
        
            --The default template verification is only being used for g_flg_type_complaint_sch_evnt   
            IF NOT get_default_template(i_lang,
                                        i_prof,
                                        i_episode,
                                        i_doc_area,
                                        o_id_default_template,
                                        o_desc_default_template,
                                        o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_TEMPLATE_EXISTS');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_template_exists;
    --

    /********************************************************************************************
    * Checks if an episode has template
    *
    * @param i_lang                language id
    * @param i_prof                professional, software and institution ids
    * @param i_episode             episode id
    * @i_flg_type                  flg_type 
    * @param o_flg_data            Y if there are data, F when no date found
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *    
    * @author                      Carlos Ferreira 
    * @version                     1.0
    * @since                       15-05-2008
    *
    * @Deprecated : get_template_exists (without i_flg_type) should be used instead.
    **********************************************************************************************/
    FUNCTION get_template_exists
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_flg_type              IN doc_area_inst_soft.flg_type%TYPE,
        o_flg_data              OUT VARCHAR2,
        o_sys_shortcut          OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_id_default_template   OUT doc_template.id_doc_template%TYPE,
        o_desc_default_template OUT pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_template_exists(i_lang,
                                   i_prof,
                                   i_episode,
                                   i_doc_area,
                                   o_flg_data,
                                   o_sys_shortcut,
                                   o_id_default_template,
                                   o_desc_default_template,
                                   o_error);
    
    END get_template_exists;

    /********************************************************************************************
    * Detalhe de um episódio de documentation num dado contexto.
      Ex de contexto: Intervention; Exam; Analysis; Drugs
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_context       array with id_epis_context
    * @param i_doc_area           documentation area
    * @param o_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/10/23
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1   
    *                             2008/05/05
    *                             Added i_doc_area parameter
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    ********************************************************************************************/
    FUNCTION get_epis_documentation_context
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_context      IN table_number,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_EPIS_DOC_REGISTER';
        OPEN o_epis_doc_register FOR
            SELECT ed.id_epis_documentation,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                   ed.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality,
                   ed.id_doc_area,
                   ed.flg_status,
                   pk_sysdomain.get_domain(g_domain_epis_doc_flg_status, ed.flg_status, i_lang) desc_status,
                   ed.notes,
                   ed.id_epis_context
              FROM epis_documentation ed
             WHERE ed.id_doc_area = i_doc_area
               AND ed.id_epis_context IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(i_epis_context) t)
             ORDER BY dt_last_update_tstz ASC;
        --
        g_error := 'GET CURSOR O_EPIS_DOCUMENT_VAL';
        OPEN o_epis_document_val FOR
            SELECT ed.id_epis_documentation,
                   d.id_documentation,
                   d.id_doc_component,
                   decr.id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   get_element_description(i_lang,
                                           i_prof,
                                           de.flg_type,
                                           edd.value,
                                           edd.value_properties,
                                           decr.id_doc_element_crit,
                                           de.id_unit_measure_reference,
                                           de.id_master_item,
                                           decr.code_element_close) desc_element,
                   TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
                   get_formatted_value(i_lang,
                                       i_prof,
                                       de.flg_type,
                                       edd.value,
                                       edd.value_properties,
                                       de.input_mask,
                                       de.flg_optional_value,
                                       de.flg_element_domain_type,
                                       de.code_element_domain,
                                       edd.dt_creation_tstz) VALUE,
                   de.flg_type flg_type_element,
                   ed.id_doc_area,
                   dtad.rank rank_component,
                   de.rank rank_element,
                   pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                   pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                   pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                   de.display_format,
                   de.separator
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
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE ed.id_doc_area = i_doc_area
               AND ed.id_epis_context IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(i_epis_context) t)
             ORDER BY id_epis_documentation, rank_component, rank_element;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENTATION_CONTEXT');
            
                pk_types.open_my_cursor(o_epis_doc_register);
                pk_types.open_my_cursor(o_epis_document_val);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_documentation_context;

    /********************************************************************************************
    * Detalhe de um episódio de documentation num dado contexto.
      Ex de contexto: Intervention; Exam; Analysis; Drugs
    *
    * @param i_lang               language id
    * @param i_prof_id            professional
    * @param i_prof_inst          institution
    * @param i_prof_soft          software
    * @param i_epis_context       array with id_epis_context
    * @param i_doc_area           documentation area
    * @param o_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Rui Spratley
    * @version                    2.4.1.0   
    * @since                      2007/12/04
    *
    * Changes:
    *                             Ariel Machado
    *                             2.4.3   
    *                             2008/05/05
    *                             Added i_doc_area parameter
    ********************************************************************************************/
    FUNCTION get_epis_doc_context_reports
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN NUMBER,
        i_prof_inst         IN NUMBER,
        i_prof_soft         IN NUMBER,
        i_epis_context      IN table_number,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        i_prof profissional;
    
    BEGIN
        i_prof := profissional(i_prof_id, i_prof_inst, i_prof_soft);
    
        IF NOT get_epis_documentation_context(i_lang,
                                              i_prof,
                                              i_epis_context,
                                              i_doc_area,
                                              o_epis_doc_register,
                                              o_epis_document_val,
                                              o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOC_CONTEXT_REPORTS');
            
                pk_types.open_my_cursor(o_epis_doc_register);
                pk_types.open_my_cursor(o_epis_document_val);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_doc_context_reports;

    /********************************************************************************************
    * Gets doc_template for any criteria. 
    * Currently criterias are obtained from i_doc_area and i_episode and i_flg_type.
    * When needed new criterias, (name X value) pairs might be added as input parameters.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_patient           the patient id,
    * @param i_episode           the episode id,
    * @param i_doc_area          the doc_area id
    * @param i_context           the context id
    * @param i_flg_type          indica tipo de acesso à Touch option
    
    * @param
    * @param o_doc_template      the doc template id
    *
    *
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Carlos Ferreira
    * @since                     14-05-2008
    * @version                   1.0
    **********************************************************************************************/
    FUNCTION get_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_flg_type  IN doc_area_inst_soft.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_doc_area IS
            SELECT dis.flg_type, dis.flg_multiple
              FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_doc_area, i_prof.institution, i_prof.software)) dis;
    
        l_gender            patient.gender%TYPE;
        l_age               patient.age%TYPE;
        l_doc_area_flg_type doc_area_inst_soft.flg_type%TYPE;
        l_flg_multiple      doc_area_inst_soft.flg_multiple%TYPE;
        l_profile_template  profile_template.id_profile_template%TYPE;
        l_flg_mode          doc_area_inst_soft.flg_mode%TYPE;
        l_flg_switch_mode   doc_area_inst_soft.flg_switch_mode%TYPE;
        l_count             NUMBER;
    
        no_template_configured_excep EXCEPTION;
        function_call_excep          EXCEPTION;
    BEGIN
    
        g_error := 'find profile template';
        SELECT ppt.id_profile_template
          INTO l_profile_template
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_profile_template = pt.id_profile_template
           AND pt.id_software = i_prof.software;
    
        g_error := 'CALLING GET_PAT_INFO_BY_PATIENT';
        IF NOT pk_patient.get_pat_info_by_patient(i_lang, i_patient, l_gender, l_age)
        THEN
            RAISE g_exception;
        END IF;
        --
        g_error := 'GET DOC_AREA FLG_TYPE';
        OPEN c_doc_area;
        FETCH c_doc_area
            INTO l_doc_area_flg_type, l_flg_multiple;
        IF c_doc_area%NOTFOUND
        THEN
            g_error := 'NO DOC_AREA_INST_SOFT CONFIGURATION';
            RAISE g_exception;
        END IF;
        CLOSE c_doc_area;
    
        g_error := 'GET DOC_TEMPLATE';
        --According to CONTENT team, flg_multiple=Y is only supported for doc_areas with flag C and CT
        IF l_flg_multiple = pk_alert_constant.g_yes
           AND l_doc_area_flg_type IN (g_flg_type_complaint, g_flg_type_complaint_sch_evnt)
        THEN
            --Notes about flg_multiple and multiple templates: Currently any template context criteria (by Complaint,by Area, etc.)
            -- allow multiple templates simply parameterizing more than one template on DOC_TEMPLATE_CONTEXT by these criteria.
            -- The flg_multiple behavior is used to allow find pre-selected templates on EPIS_DOC_TEMPLATE instead of use DOC_TEMPLATE_CONTEXT.
            g_error := 'get_selected_doc_template_list';
            IF NOT get_selected_doc_template_list(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_episode   => i_episode,
                                                  i_flg_type  => l_doc_area_flg_type,
                                                  i_doc_area  => i_doc_area,
                                                  o_templates => o_templates,
                                                  o_error     => o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        ELSE
            IF l_doc_area_flg_type IS NULL
               AND i_context IS NULL
            THEN
                g_error := 'CHECK DOC_AREA_INST_SOFT CONFIGURATION OR INPUT CONTEXT';
                RAISE g_exception;
            END IF;
        
            CASE l_doc_area_flg_type
            
            -- Template by Appointment
                WHEN g_flg_type_appointment THEN
                    g_error := 'get_doc_template_by_appnt';
                    IF NOT get_doc_template_by_appnt(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_episode   => i_episode,
                                                     i_gender    => l_gender,
                                                     i_age       => l_age,
                                                     o_templates => o_templates,
                                                     o_error     => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- It isn't a template type. Used by Nursing areas on EDIS to load a specific default template if no template has been parameterized)
                WHEN g_flg_type_nursingedis_service THEN
                
                    g_error := 'GET DOC_TEMPLATE_BY_SERV';
                    IF NOT get_doc_template_by_serv(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_episode,
                                                    i_gender    => l_gender,
                                                    i_age       => l_age,
                                                    o_templates => o_templates,
                                                    o_error     => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                    -- Luís Maia - 09-05-2008
                    -- g_flg_type_nursing_assessment_service_type := 'SN' (Caso específico para as avaliações de enfermagem no EDIS)
                    -- (No caso específico do EDIS se não encontrar template deverá "Carregar" order by template 58 por defeito)
                    IF o_templates IS NULL
                    THEN
                        OPEN o_templates FOR
                            SELECT dt.id_doc_template,
                                   pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc
                              FROM doc_template dt
                             WHERE dt.id_doc_template = g_doc_template_nursingedis_def
                             ORDER BY template_desc;
                    END IF;
                
            -- Template by Clinical service
                WHEN g_flg_type_clin_serv THEN
                    g_error := 'GET_DOC_TEMPLATE_BY_SERV';
                    IF NOT get_doc_template_by_serv(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_episode   => i_episode,
                                                    i_gender    => l_gender,
                                                    i_age       => l_age,
                                                    o_templates => o_templates,
                                                    o_error     => o_error)
                    
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Area
                WHEN g_flg_type_doc_area THEN
                    g_error := 'get_doc_template_doc_area';
                    IF NOT get_doc_template_by_area(i_lang, i_prof, i_doc_area, l_gender, l_age, o_templates, o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                    -- Template by Area and Appointment
                WHEN g_flg_type_doc_area_appointmt THEN
                    g_error := 'get_doc_template_by_area_appnt';
                    IF NOT get_doc_template_by_area_appnt(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_episode   => i_episode,
                                                          i_doc_area  => i_doc_area,
                                                          i_gender    => l_gender,
                                                          i_age       => l_age,
                                                          o_templates => o_templates,
                                                          o_error     => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Area and Clinical Service
                WHEN g_flg_type_doc_area_service THEN
                    g_error := 'GET DOC_TEMPLATE_BY_AREA_SERV';
                    IF NOT get_doc_template_by_area_serv(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => i_episode,
                                                         i_doc_area  => i_doc_area,
                                                         i_gender    => l_gender,
                                                         i_age       => l_age,
                                                         o_templates => o_templates,
                                                         o_error     => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                    -- Template by Area and Complaint
                WHEN g_flg_type_doc_area_complaint THEN
                    g_error := 'GET DOC_TEMPLATE_BY_AREA_CPLNT';
                    IF NOT get_doc_template_by_area_cplnt(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_episode   => i_episode,
                                                          i_doc_area  => i_doc_area,
                                                          i_gender    => l_gender,
                                                          i_age       => l_age,
                                                          o_templates => o_templates,
                                                          o_error     => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            --Template by Complaint
                WHEN g_flg_type_complaint THEN
                    g_error := 'pk_complaint.get_complaint_template';
                    IF NOT get_doc_template_by_complaint(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_episode           => i_episode,
                                                         i_gender            => l_gender,
                                                         i_age               => l_age,
                                                         i_doc_area_flg_type => l_doc_area_flg_type,
                                                         o_templates         => o_templates,
                                                         o_error             => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            --Template by Complaint + Template
                WHEN g_flg_type_complaint_sch_evnt THEN
                    g_error := 'pk_complaint.get_complaint_template';
                    IF NOT get_doc_template_by_complaint(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_episode           => i_episode,
                                                         i_gender            => l_gender,
                                                         i_age               => l_age,
                                                         i_doc_area_flg_type => l_doc_area_flg_type,
                                                         o_templates         => o_templates,
                                                         o_error             => o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Scheduled Department-clinical service
                WHEN g_flg_type_sch_dep_clin_serv THEN
                    g_error := 'get_doc_template_by_sch_dcs';
                    IF NOT get_doc_template_by_sch_dcs(i_lang, i_prof, i_episode, l_gender, l_age, o_templates, o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Intervention
                WHEN g_flg_type_intervention THEN
                    g_error := 'get_doc_template_by_interv';
                    IF NOT get_doc_template_by_interv(i_lang,
                                                      i_prof,
                                                      i_episode,
                                                      i_context,
                                                      l_gender,
                                                      l_age,
                                                      o_templates,
                                                      o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Communication
                WHEN g_flg_type_communication THEN
                    g_error := 'get_doc_template_by_interv';
                    IF NOT get_doc_template_by_comm_order(i_lang,
                                                          i_prof,
                                                          i_episode,
                                                          i_context,
                                                          g_flg_type_communication,
                                                          l_gender,
                                                          l_age,
                                                          o_templates,
                                                          o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Medical order
                WHEN g_flg_type_medical_order THEN
                    g_error := 'get_doc_template_by_interv';
                    IF NOT get_doc_template_by_comm_order(i_lang,
                                                          i_prof,
                                                          i_episode,
                                                          i_context,
                                                          g_flg_type_medical_order,
                                                          l_gender,
                                                          l_age,
                                                          o_templates,
                                                          o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Exam
                WHEN g_flg_type_exam THEN
                    g_error := 'get_doc_template_exam';
                    IF NOT get_doc_template_by_exam(i_lang,
                                                    i_prof,
                                                    i_episode,
                                                    i_context,
                                                    l_gender,
                                                    l_age,
                                                    o_templates,
                                                    o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by Exam Result
                WHEN g_flg_type_exam_result THEN
                    g_error := 'get_doc_template_exam';
                    IF NOT get_doc_template_by_exam_res(i_lang,
                                                        i_prof,
                                                        i_episode,
                                                        i_context,
                                                        l_gender,
                                                        l_age,
                                                        o_templates,
                                                        o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                    -- Template by Area + Surgical procedure 
                WHEN g_flg_type_doc_area_surg_proc THEN
                    g_error := 'get_doc_template_by_area_surg';
                    IF NOT get_doc_template_by_area_surg(i_lang,
                                                         i_prof,
                                                         i_episode,
                                                         i_doc_area,
                                                         l_gender,
                                                         l_age,
                                                         o_templates,
                                                         o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Template by CIPE
                WHEN g_flg_type_cipe THEN
                    g_error := 'get_doc_template_by_cipe';
                    IF NOT get_doc_template_by_cipe(i_lang,
                                                    i_prof,
                                                    i_episode,
                                                    i_context,
                                                    l_gender,
                                                    l_age,
                                                    o_templates,
                                                    o_error)
                    THEN
                        RAISE function_call_excep;
                    END IF;
                
            -- Unknow... a new unexpected type?
                ELSE
                    g_error := 'UNKNOWN DOC_AREA_SOFT_INST FLG_TYPE: ' || l_doc_area_flg_type;
                    RAISE g_exception;
            END CASE;
        END IF;
    
        -- CHECK DOC_TEMPLATE CONFIG.
        IF (o_templates IS NULL)
        THEN
            -- AM 24/07/2008: If has permission to switch to free-text then sends templates to null as no error
            g_error := 'get_touch_option_mode';
            IF NOT get_touch_option_mode(i_lang, i_prof, i_doc_area, l_flg_mode, l_flg_switch_mode, o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        
            IF (l_flg_switch_mode = g_yes)
            THEN
                -- Flash checks in case that o_templates is empty then switch to free-text             
                -- (ALERT-10252) Because other functions (like get_doc_template_internal) fetch this output cursor, must create a two field cursor without rows
                OPEN o_templates FOR
                    SELECT NULL id_doc_template, NULL template_desc
                      FROM dual
                     WHERE 1 = 0;
            
                pk_alertlog.log_warn('get_doc_template: Hasn''t template configured, but has permissions to switch to free-text. Switched to Free-Text mode' ||
                                     chr(10) || 'Arguments: id_doc_area: ' || i_doc_area || '; dais.flg_type: ' ||
                                     l_doc_area_flg_type,
                                     g_package_name);
            
            ELSE
                -- Hasn't template configured and hasn't permissions to switch to free-text, then sends an error
                RAISE no_template_configured_excep;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE(flg_type)');
                /* Open out cursors */
                pk_types.open_my_cursor(o_templates);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
        WHEN no_template_configured_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                g_error := 'NO TEMPLATE CONFIGURED for input parameters (id_doc_area = ' || to_char(i_doc_area) ||
                           ', flg_type = ' || nvl(l_doc_area_flg_type, 'NULL') || ', flg_multiple = ' ||
                           nvl(l_flg_multiple, 'NULL') || ', id_context = ' || to_char(i_context) || ')';
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'NO TEMPLATE CONFIGURED',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE(flg_type)');
                /* Open out cursors */
                pk_types.open_my_cursor(o_templates);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state();
                RETURN l_ret;
            
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_TEMPLATE(flg_type)');
                /* Open out cursors */
                pk_types.open_my_cursor(o_templates);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_doc_template;

    /********************************************************************************************
    * Sets the default touch option templates. 
    * An episode migth have several default templates, one for each profile_template
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_episode            the episode id
    * @param i_flg_type           type of identifier
    * @param o_epis_doc_templates An array with the touch option templates associated to the episode
    * @param o_error              Error message
    *
    * @value i_flg_type          'A' Appointment {*} 'S' Clinical Service 
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Luís Gaspar
    * @version                    1.0   
    * @since                      2007/08/31
    *
    * Changes:
    *                             Ariel Machado 
    *                             1.1   
    *                             2008/04/03
    *                             Added i_flg_type parameter
    ********************************************************************************************/
    FUNCTION set_default_epis_doc_templates
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN doc_template_context.flg_type%TYPE,
        o_epis_doc_templates OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_default_epis_doc_templates';
        function_call_excep          EXCEPTION;
        l_gender                     patient.gender%TYPE;
        l_age                        patient.age%TYPE;
        l_touchoption_def_tmpl_apply sys_config.value%TYPE;
        l_clin_serv                  clinical_service.id_clinical_service%TYPE;
        l_templates                  pk_types.cursor_type;
        l_tab_templates_set          table_number;
        l_tab_templates_set_name     table_varchar;
        l_debug                      episode.id_episode%TYPE;
    
        /**
        * Sets default touch option templates for areas 
        *
        * @param   i_lang              Professional preferred language
        * @param   i_prof              Professional identification and its context (institution and software)        
        * @param   i_episode           Episode ID
        * @param   i_gender            Patient gender
        * @param   i_age               Patient age
        * @param   i_flg_type          Templates context criterion to set default templates
        * @param   o_error             Error information
        *
        * @value i_flg_type {*} 'DA' Templates by Area + Appointment. {*} 'DS' Templates by Area + Clinical service
        *
        * @return  True or False on success or error
        *
        * @author  ARIEL.MACHADO
        * @version 2.6.1
        * @since   5/23/2011
        */
        FUNCTION inner_set_default_by_areas
        (
            i_lang     IN language.id_language%TYPE,
            i_prof     IN profissional,
            i_episode  IN episode.id_episode%TYPE,
            i_gender   IN VARCHAR2,
            i_age      IN VARCHAR2,
            i_flg_type IN doc_area_inst_soft.flg_type%TYPE,
            o_error    OUT t_error_out
        ) RETURN BOOLEAN IS
            co_function_name CONSTANT VARCHAR2(30 CHAR) := 'inner_set_default_by_areas';
            function_call_excep  EXCEPTION;
            l_market             market.id_market%TYPE;
            l_subject            sys_config.value%TYPE;
            l_da_area_list       table_number;
            l_templates          pk_types.cursor_type;
            l_template_list      table_number;
            l_template_name_list table_varchar;
            l_aux_list           table_number;
        BEGIN
        
            -- Default templates for areas just has support for: DA - "DocArea + Appointment" and DS - "Doc Area + Service"
            IF i_flg_type NOT IN (g_flg_type_doc_area_appointmt, g_flg_type_doc_area_service)
            THEN
                g_error := 'Invalid argument. Input argument ''i_flg_type'' is not a valid value';
                RAISE g_exception;
            END IF;
        
            g_error  := 'Retrieving institution market';
            l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            g_error := 'Retrieving a list of areas that are configured to use templates per episode';
            SELECT da.id_doc_area
              BULK COLLECT
              INTO l_da_area_list
              FROM doc_area da
              JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, i_prof.software)) dais
                ON da.id_doc_area = dais.id_doc_area
             WHERE dais.flg_multiple = pk_alert_constant.g_yes -- <-- This area uses templates per episode
               AND dais.flg_type = i_flg_type;
        
            g_error := 'Set default templates by area';
            FOR i IN 1 .. l_da_area_list.count()
            LOOP
                CASE i_flg_type
                
                    WHEN g_flg_type_doc_area_appointmt THEN
                        g_error := 'get_doc_template_by_area_appnt';
                        IF NOT get_doc_template_by_area_appnt(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_doc_area       => l_da_area_list(i),
                                                              i_gender         => i_gender,
                                                              i_age            => i_age,
                                                              i_ignore_profile => pk_alert_constant.g_yes,
                                                              o_templates      => l_templates,
                                                              o_error          => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                    WHEN g_flg_type_doc_area_service THEN
                        g_error := 'get_doc_template_by_area_serv';
                        IF NOT get_doc_template_by_area_serv(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_episode        => i_episode,
                                                             i_doc_area       => l_da_area_list(i),
                                                             i_gender         => i_gender,
                                                             i_age            => i_age,
                                                             i_ignore_profile => pk_alert_constant.g_yes,
                                                             o_templates      => l_templates,
                                                             o_error          => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                END CASE;
            
                IF l_templates IS NOT NULL
                THEN
                    g_error := 'FETCH DEFAULT TEMPLATES';
                    FETCH l_templates BULK COLLECT
                        INTO l_template_list, l_template_name_list;
                    CLOSE l_templates;
                
                    -- For physical exam area we need to filter templates that are applicable to current E/M Guideline in use (USA)
                    IF l_da_area_list(i) = pk_summary_page.g_doc_area_phy_exam
                    THEN
                        g_error := 'Retrieve E/M Documentation guideline';
                        IF NOT get_doc_guideline(i_lang => i_lang, i_prof => i_prof, o_subject => l_subject)
                        THEN
                            l_subject := NULL;
                        END IF;
                    
                        IF l_subject IS NOT NULL
                        THEN
                            -- If one E/M Documentation Guideline is enabled, then filters the templates only those that apply to it
                            SELECT DISTINCT dts.id_doc_template
                              BULK COLLECT
                              INTO l_aux_list
                              FROM doc_system ds
                             INNER JOIN doc_template_system dts
                                ON ds.id_doc_system = dts.id_doc_system
                             INNER JOIN TABLE(l_template_list) dt
                                ON dt.column_value = dts.id_doc_template
                             WHERE ds.subject = l_subject;
                            l_template_list := l_aux_list;
                        END IF;
                    END IF;
                
                    g_error := 'INSERT DEFAULT TEMPLATES';
                    FORALL x IN 1 .. l_template_list.count
                        INSERT INTO epis_doc_template
                            (id_epis_doc_template,
                             dt_register,
                             id_prof_register,
                             id_episode,
                             id_doc_template,
                             id_profile_template,
                             id_doc_area)
                        VALUES
                            (seq_epis_doc_template.nextval,
                             g_sysdate_tstz,
                             i_prof.id,
                             i_episode,
                             l_template_list(x),
                             NULL,
                             l_da_area_list(i));
                END IF;
            
            END LOOP;
        
            RETURN TRUE;
        EXCEPTION
            WHEN function_call_excep THEN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => co_function_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  co_function_name,
                                                  o_error);
                RETURN FALSE;
        END inner_set_default_by_areas;
    BEGIN
        g_error                      := 'TOUCH OPTION DEFAULT TEMPLATES APPLY?';
        l_touchoption_def_tmpl_apply := pk_sysconfig.get_config(g_touch_option_def_template, i_prof);
        g_sysdate_tstz               := current_timestamp;
    
        g_error := 'Input parameters (i_episode = ' || to_char(i_episode) || ', flg_type = ' || nvl(i_flg_type, 'NULL') || ')';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
        --
        IF l_touchoption_def_tmpl_apply = g_yes
        THEN
            BEGIN
                g_error := 'FIND clinical service';
                SELECT dcs.id_clinical_service
                  INTO l_clin_serv
                  FROM dep_clin_serv dcs
                 INNER JOIN epis_info ei
                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                 INNER JOIN episode e
                    ON ei.id_episode = e.id_episode
                 WHERE e.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_clin_serv := NULL;
            END;
        
            IF l_clin_serv IS NOT NULL
            THEN
            
                g_error := 'pk_patient.get_pat_info_by_episode';
                IF NOT pk_patient.get_pat_info_by_episode(i_lang, i_episode, l_gender, l_age)
                THEN
                    RAISE function_call_excep;
                END IF;
            
                --Cancels all active default templates to avoid duplication.
                g_error := 'cancel previous default touch option templates';
                UPDATE epis_doc_template edt
                   SET edt.dt_cancel = g_sysdate_tstz, edt.id_prof_cancel = i_prof.id
                 WHERE edt.id_episode = i_episode
                   AND edt.id_prof_cancel IS NULL;
            
                CASE i_flg_type
                -- Default templates by episode's appointment
                    WHEN g_flg_type_appointment THEN
                    
                        -- Set default templates for "(D)ocAreas + (A)ppointment"
                        g_error := 'inner_set_default_by_areas (by Appointment)';
                        IF NOT inner_set_default_by_areas(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_episode  => i_episode,
                                                          i_gender   => l_gender,
                                                          i_age      => l_age,
                                                          i_flg_type => g_flg_type_doc_area_appointmt,
                                                          o_error    => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                        -- Get default templates for "(A)ppointment"
                        g_error := 'get_doc_template_by_appnt';
                        IF NOT get_doc_template_by_appnt(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_episode        => i_episode,
                                                         i_gender         => l_gender,
                                                         i_age            => l_age,
                                                         i_ignore_profile => pk_alert_constant.g_yes,
                                                         o_templates      => l_templates,
                                                         o_error          => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                -- Default templates by episode's clinical-service
                    WHEN g_flg_type_clin_serv THEN
                    
                        -- Set default templates for "(D)ocAreas + Clinical (S)ervice"
                        g_error := 'inner_set_default_by_areas (by Service)';
                        IF NOT inner_set_default_by_areas(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_episode  => i_episode,
                                                          i_gender   => l_gender,
                                                          i_age      => l_age,
                                                          i_flg_type => g_flg_type_doc_area_service,
                                                          o_error    => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                        -- Get default templates for "Clinical (S)ervice"
                        g_error := 'get_doc_template_by_serv';
                        IF NOT get_doc_template_by_serv(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => i_episode,
                                                        i_gender         => l_gender,
                                                        i_age            => l_age,
                                                        i_ignore_profile => pk_alert_constant.g_yes,
                                                        o_templates      => l_templates,
                                                        o_error          => o_error)
                        THEN
                            RAISE function_call_excep;
                        END IF;
                        -- Unknow... a new unexpected type used for default templates?
                    ELSE
                        g_error := 'UNKNOWN FLG_TYPE for default templates: ' || i_flg_type;
                        pk_alertlog.log_error(text            => g_error,
                                              object_name     => g_package_name,
                                              sub_object_name => co_function_name);
                        RAISE g_exception;
                END CASE;
            
                IF l_templates IS NOT NULL
                THEN
                    g_error := 'FETCH DEFAULT TEMPLATES';
                    FETCH l_templates BULK COLLECT
                        INTO l_tab_templates_set, l_tab_templates_set_name;
                    CLOSE l_templates;
                
                    g_error := 'INSERT DEFAULT TEMPLATES';
                    FORALL i IN 1 .. l_tab_templates_set.count
                        INSERT INTO epis_doc_template
                            (id_epis_doc_template,
                             dt_register,
                             id_prof_register,
                             id_episode,
                             id_doc_template,
                             id_profile_template)
                        VALUES
                            (seq_epis_doc_template.nextval,
                             g_sysdate_tstz,
                             i_prof.id,
                             i_episode,
                             l_tab_templates_set(i),
                             NULL);
                END IF;
            
            ELSE
                g_error := 'No available id_clinical_service in DEP_CLIN_SERV for episode = ' || to_char(i_episode);
                pk_alertlog.log_warn(text            => g_error,
                                     object_name     => g_package_name,
                                     sub_object_name => co_function_name);
            
                SELECT COUNT(0)
                  INTO l_debug
                  FROM episode e
                 WHERE e.id_episode = i_episode;
                g_error := 'Episode exists in EPISODE table? : ' || to_char(l_debug);
                pk_alertlog.log_warn(text            => g_error,
                                     object_name     => g_package_name,
                                     sub_object_name => co_function_name);
            
                SELECT COUNT(0)
                  INTO l_debug
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
                g_error := 'Episode exists in EPIS_INFO table? : ' || to_char(l_debug);
                pk_alertlog.log_warn(text            => g_error,
                                     object_name     => g_package_name,
                                     sub_object_name => co_function_name);
            
                IF l_debug != 0
                THEN
                    SELECT ei.id_dep_clin_serv
                      INTO l_debug
                      FROM epis_info ei
                     WHERE ei.id_episode = i_episode;
                    g_error := 'id_dep_clin_serv in EPIS_INFO table : ' || nvl(to_char(l_debug), 'NULL');
                    pk_alertlog.log_warn(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => co_function_name);
                END IF;
            
            END IF;
        
        ELSE
            pk_alertlog.log_warn('Default templates apply configuration is ''' || l_touchoption_def_tmpl_apply ||
                                 chr(10) || '''. Check that this value of sys_config entry (' ||
                                 g_touch_option_def_template ||
                                 ') is what you want. Input parameters: id_institution:' || i_prof.institution ||
                                 ' ; id_software:' || i_prof.software,
                                 g_package_name);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN function_call_excep THEN
            g_error := 'The call to function ' || g_error || ' returned an error ';
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_DEFAULT_EPIS_DOC_TEMPLATES');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes();
                RETURN l_ret;
            END;
    END set_default_epis_doc_templates;

    /********************************************************************************************
    * Returns a list of selected doc templates to an episode.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           the episode id
    * @param i_flg_type          indica tipo de acesso à Touch option
    * @param o_templates         A cursor with the doc templates
    * @param o_error             Error message
    *                        
    * @return                    true or false on success or error
    *
    * @author                    Carlos Ferreira
    * @version                   1.0   
    * @since                     2008/05/15
    ********************************************************************************************/
    FUNCTION get_selected_doc_template_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN doc_template_context.flg_type%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE DEFAULT NULL,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_template epis_doc_template.id_profile_template%TYPE;
        l_count            PLS_INTEGER;
    BEGIN
        --
        g_error            := 'find profile template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        --
        g_error := 'GET COUNT';
        SELECT COUNT(*)
          INTO l_count
          FROM epis_doc_template edt
         INNER JOIN doc_template dt
            ON edt.id_doc_template = dt.id_doc_template
         INNER JOIN doc_template_context dtc
            ON dt.id_doc_template = dtc.id_doc_template
          JOIN doc_template_area da
            ON dt.id_doc_template = da.id_doc_template
           AND da.id_doc_area = i_doc_area
         WHERE edt.id_episode = i_episode
           AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL)
           AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL)
           AND edt.id_prof_cancel IS NULL
           AND ((edt.id_doc_area IS NULL AND
               i_flg_type NOT IN (g_flg_type_doc_area_appointmt,
                                    g_flg_type_doc_area_service,
                                    g_flg_type_doc_area_complaint,
                                    g_flg_type_doc_area)) OR EXISTS
                (SELECT 1
                   FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(edt.id_doc_area, i_prof.institution, i_prof.software)) aux
                  WHERE aux.flg_type = i_flg_type) AND
                (
                -- COMMENT : Se o criterio for área + algo então limito os templates pre-seleccionados igual à doc_area da qual pretendo obter templates
                 (i_flg_type IN (g_flg_type_doc_area_appointmt,
                                 g_flg_type_doc_area_service,
                                 g_flg_type_doc_area_complaint,
                                 g_flg_type_doc_area) AND edt.id_doc_area = i_doc_area) OR
                -- COMMENT : Se o criterio NÃO for área + algo então simplesmente se filtra pelo flg_type
                 (i_flg_type NOT IN (g_flg_type_doc_area_appointmt,
                                     g_flg_type_doc_area_service,
                                     g_flg_type_doc_area_complaint,
                                     g_flg_type_doc_area))))
           AND dtc.id_institution IN (0, i_prof.institution)
           AND dtc.id_software IN (0, i_prof.software)
              -- COMMENT : Se o criterio for CT pesquisa os templates por CT + Appointment
           AND ((dtc.flg_type = i_flg_type AND i_flg_type != g_flg_type_complaint_sch_evnt) OR
               (i_flg_type = g_flg_type_complaint_sch_evnt AND
               dtc.flg_type IN (g_flg_type_complaint_sch_evnt, g_flg_type_appointment)));
    
        --If no records returns a null cursor (avoids to do a fetch to know if it's empty)
        IF l_count > 0
        THEN
            g_error := 'OPEN CURSOR';
            --AM Aug 21,2008: Returns a list of selected templates if they are in doc_template_context 
            OPEN o_templates FOR
                SELECT DISTINCT dt.id_doc_template,
                                pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc
                  FROM epis_doc_template edt
                 INNER JOIN doc_template dt
                    ON edt.id_doc_template = dt.id_doc_template
                 INNER JOIN doc_template_context dtc
                    ON dt.id_doc_template = dtc.id_doc_template
                  JOIN doc_template_area da
                    ON dt.id_doc_template = da.id_doc_template
                   AND da.id_doc_area = i_doc_area
                
                 WHERE edt.id_episode = i_episode
                   AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL)
                   AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL)
                   AND edt.id_prof_cancel IS NULL
                   AND ((edt.id_doc_area IS NULL AND
                       i_flg_type NOT IN (g_flg_type_doc_area_appointmt,
                                            g_flg_type_doc_area_service,
                                            g_flg_type_doc_area_complaint,
                                            g_flg_type_doc_area)) OR EXISTS
                        (SELECT 1
                           FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(edt.id_doc_area,
                                                                            i_prof.institution,
                                                                            i_prof.software)) aux
                          WHERE aux.flg_type = i_flg_type) AND
                        (
                        -- COMMENT : Se o criterio for área + algo então limito os templates pre-seleccionados igual à doc_area da qual pretendo obter templates
                         (i_flg_type IN (g_flg_type_doc_area_appointmt,
                                         g_flg_type_doc_area_service,
                                         g_flg_type_doc_area_complaint,
                                         g_flg_type_doc_area) AND edt.id_doc_area = i_doc_area) OR
                        -- COMMENT : Se o criterio NÃO for área + algo então simplesmente se filtra pelo flg_type
                         (i_flg_type NOT IN (g_flg_type_doc_area_appointmt,
                                             g_flg_type_doc_area_service,
                                             g_flg_type_doc_area_complaint,
                                             g_flg_type_doc_area))))
                   AND dtc.id_institution IN (0, i_prof.institution)
                   AND dtc.id_software IN (0, i_prof.software)
                      -- COMMENT : Se o criterio for CT pesquisa os templates por CT + Appointment
                   AND ((dtc.flg_type = i_flg_type AND i_flg_type != g_flg_type_complaint_sch_evnt) OR
                       (i_flg_type = g_flg_type_complaint_sch_evnt AND
                       dtc.flg_type IN (g_flg_type_complaint_sch_evnt, g_flg_type_appointment)))
                 ORDER BY template_desc;
        ELSIF i_flg_type = g_flg_type_complaint_sch_evnt
        THEN
            -- when search mode is complaint/schedule event, and no templates are set,
            -- attempt a search in type of appointment mode
            g_error := 'get_selected_doc_template_list ' || g_flg_type_appointment;
            IF NOT get_selected_doc_template_list(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_episode   => i_episode,
                                                  i_flg_type  => g_flg_type_appointment,
                                                  o_templates => o_templates,
                                                  o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_SELECTED_DOC_TEMPLATE_LIST');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_selected_doc_template_list;

    /********************************************************************************************
    * Returns a element domain info about a code_element_domain                                                                                                 
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param o_element_domain         Element domain list                                                                                      
    * @param o_error                  Output error                                                                                             
    *                                                                                                                                          
    *                                                                                                                                          
    * @return                         Return false if exist an error and true otherwise                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_domains
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        o_element_domain      OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ELEMENT_DOMAINS';
        OPEN o_element_domain FOR
            SELECT ded.desc_val label, ded.val data, ded.img_name icon, ded.rank
              FROM doc_element_domain ded
             WHERE ded.flg_available = g_available
               AND ded.code_element_domain = i_code_element_domain
               AND ded.id_language = i_lang;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_ELEMENT_DOMAINS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_element_domain);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_element_domains;

    /********************************************************************************************
    * Returns a description about a value for code_element_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_val                    Element domain value                                                                                      
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_desc_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        i_val                 IN doc_element_domain.val%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_val doc_element_domain.desc_val%TYPE;
    
    BEGIN
    
        g_error := 'GET ELEMENT_DOMAIN';
        SELECT ded.desc_val
          INTO l_desc_val
          FROM doc_element_domain ded
         WHERE ded.flg_available = g_available
           AND ded.code_element_domain = i_code_element_domain
           AND ded.val = i_val
           AND ded.id_language = i_lang;
    
        RETURN l_desc_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_element_desc_domain;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for code_element_domain                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_code_element_domain    Element domain ID                                                                                        
    * @param i_vals                   Element domain values separated by i_delim_in (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_element_desc_domain_set
    (
        i_lang                IN language.id_language%TYPE,
        i_code_element_domain IN doc_element_domain.code_element_domain%TYPE,
        i_vals                IN VARCHAR2,
        i_delim_in            IN VARCHAR2 DEFAULT '|',
        i_delim_out           IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2 IS
        l_vals_tab  table_varchar2;
        l_descs_tab table_varchar;
        l_return    VARCHAR2(32767);
    
    BEGIN
        g_error := 'REPLACE DELIMITER';
    
        l_vals_tab := pk_utils.str_split(i_vals, i_delim_in);
    
        g_error := 'GET ELEMENT DOMAIN_';
        SELECT ded.desc_val
          BULK COLLECT
          INTO l_descs_tab
          FROM doc_element_domain ded
         WHERE ded.flg_available = g_available
           AND ded.code_element_domain = i_code_element_domain
           AND ded.val IN (SELECT /*+ opt_estimate(table t rows=1)*/
                            t.column_value
                             FROM TABLE(l_vals_tab) t)
           AND ded.id_language = i_lang;
    
        g_error  := 'CONCAT_TABLE';
        l_return := pk_utils.concat_table(i_tab       => l_descs_tab,
                                          i_delim     => i_delim_out,
                                          i_start_off => 1,
                                          i_length    => -1);
        IF l_descs_tab.count > 1
        THEN
            l_return := '(' || l_return || ')';
        END IF;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_ELEMENT_DESC_DOMAIN_SET');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_element_desc_domain_set;

    /********************************************************************************************
    * Returns a description about a value for a dynamic domain function                                                                                                 
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_doc_function           Function ID (name)                                                                                        
    * @param i_val                    Element domain value                                                                                      
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/20                                                                                               
    ********************************************************************************************/

    FUNCTION get_dynamic_desc_domain
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_function IN doc_function.id_doc_function%TYPE,
        i_val          IN doc_element_domain.val%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_val     doc_element_domain.desc_val%TYPE;
        l_doc_function doc_function.id_doc_function%TYPE;
        l_code_domain_i CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.DESC_INTERVENTION';
    
    BEGIN
        g_error := 'GET ELEMENT_DOMAIN';
    
        l_doc_function := upper(i_doc_function);
    
        CASE l_doc_function
        
            WHEN 'LIST.GET_CAT_LIST' THEN
            
                SELECT pk_translation.get_translation(i_lang, c.code_category)
                  INTO l_desc_val
                  FROM category c
                 WHERE c.id_category = i_val;
            
            WHEN 'LIST.GET_PROF_LIST' THEN
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, i_val) nick_name
                  INTO l_desc_val
                  FROM dual;
            WHEN 'PREGNANCY.GET_INST_DOMAIN_TEMPLATE' THEN
                IF i_val = '-1'
                THEN
                    l_desc_val := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T114');
                ELSIF i_val IN ('D', 'O')
                THEN
                    l_desc_val := pk_sysdomain.get_domain(l_code_domain_i, i_val, i_lang);
                ELSE
                    SELECT pk_translation.get_translation(i_lang, i.code_institution)
                      INTO l_desc_val
                      FROM institution i
                     WHERE i.id_institution = i_val;
                END IF;
            ELSE
                g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') NOT SUPPORTED';
                RAISE g_exception;
        END CASE;
    
        RETURN l_desc_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DYNAMIC_DESC_DOMAIN');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
        
    END get_dynamic_desc_domain;

    /********************************************************************************************
    * Returns concatenate descriptions about a set of values separated by delimiter for dynamic domain function                                                                                                
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_doc_function           Function ID (name)                                                                                                                                                                                
    * @param i_vals                   Element domain values separated by i_delim_in (e.g. 1|2|3)                                                                                       
    * @param i_delim_in               Input delimiter(e.g. '|')                                                                                       
    * @param i_delim_out              Output delimiter(e.g. ';')                                                                                       
    * 
    *                                                                                                                                         
    * @return                         Returns value description                                                        
    *                                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/05/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_dynamic_desc_domain_set
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_function IN doc_function.id_doc_function%TYPE,
        i_vals         IN VARCHAR2,
        i_delim_in     IN VARCHAR2 DEFAULT '|',
        i_delim_out    IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2 IS
        l_vals_tab     table_varchar2;
        l_descs_tab    table_varchar;
        l_doc_function doc_function.id_doc_function%TYPE;
        l_return       VARCHAR2(32767);
    
    BEGIN
    
        g_error    := 'SPLIT VALS';
        l_vals_tab := pk_utils.str_split(i_vals, i_delim_in);
    
        l_doc_function := upper(i_doc_function);
    
        CASE l_doc_function
        
            WHEN 'LIST.GET_CAT_LIST' THEN
            
                g_error := 'GET CATEGORY LIST';
            
                SELECT pk_translation.get_translation(i_lang, c.code_category)
                  BULK COLLECT
                  INTO l_descs_tab
                  FROM category c
                 WHERE c.id_category IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(l_vals_tab) t);
            
            WHEN 'LIST.GET_PROF_LIST' THEN
            
                g_error := 'GET PROF LIST';
            
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
                  BULK COLLECT
                  INTO l_descs_tab
                  FROM professional p
                 WHERE p.id_professional IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(l_vals_tab) t);
            ELSE
                g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') NOT SUPPORTED';
                RAISE g_exception;
            
        END CASE;
    
        g_error  := 'CONCAT_TABLE';
        l_return := pk_utils.concat_table(i_tab       => l_descs_tab,
                                          i_delim     => i_delim_out,
                                          i_start_off => 1,
                                          i_length    => -1);
        IF l_descs_tab.count > 1
        THEN
            l_return := '(' || l_return || ')';
        END IF;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DYNAMIC_DESC_DOMAIN_SET');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
    END get_dynamic_desc_domain_set;

    /********************************************************************************************
    * Checks if the elements of a template has translations
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_doc_area               Doc area
    * @param i_doc_template           Template                                                                                       
    * @param o_is_translated          Output about template translation status
    *                                                                                                                                         
    * @return                         true or false on success or error                                                        
    *                                                                                                                          
    * @value o_is_translated          {*} 'Y'  Has translations {*} 'N' Has no translations  
                   
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3)                                                                                                     
    * @since                          2008/07/25                                                                                               
    ********************************************************************************************/

    FUNCTION get_template_translated
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        o_is_translated OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error         := 'Call to pk_touch_option_core.get_template_translated';
        o_is_translated := pk_touch_option_core.get_template_translated(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_doc_area     => i_doc_area,
                                                                        i_doc_template => i_doc_template);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_TEMPLATE_TRANSLATED');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_template_translated;

    /********************************************************************************************
    * Extracts the value through the type of element. Example: for element of type numeric with 
    * unit of measure (UOM) it can strip the UOM ID, retuning the numeric value only
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Current profissional
    * @param i_element_type           Element type (Comp. element date, etc.)
    * @param i_element_value          Element value
    * 
    * @return                         Value from element value
    *
    * @author                         Ariel Geraldo Machado
    * @version                        2.5
    * @since                          25/Jun/2009
    **********************************************************************************************/
    FUNCTION get_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_element_type  IN doc_element.flg_type%TYPE,
        i_element_value IN epis_documentation_det.value%TYPE
    ) RETURN VARCHAR2 IS
        l_value         epis_documentation_det.value%TYPE;
        l_element_value table_varchar2;
    BEGIN
        CASE i_element_type
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
            
                -- Checks if number has an unit of measure (UOM). 
                -- Format <num_value>|<UOM>
                l_element_value := pk_utils.str_split(i_element_value, '|');
                l_value         := l_element_value(1);
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
            
                -- Checks if number has an unit of measure (UOM) and/or reference values
                -- Format <num_value>|<id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_min>|<ref_val_max>
                l_element_value := pk_utils.str_split(i_element_value, '|');
                l_value         := l_element_value(1);
            WHEN 'M' THEN
                l_value := '';
            ELSE
                l_value := i_element_value;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'GET_VALUE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
        
    END get_value;

    /********************************************************************************************
    * Extracts the properties for value through the type of element, 
    * example: for elements of type date it returns time zone property.
    *                                                                                                                                          
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids
    * @param i_element_type           Element type (Comp. element date, etc. )
    * @param i_element_value          Element value
    * @param i_element                Element ID
    * @param i_element_vs_list        List of elements ID and respective collection of saved vital sign measurement
    *                                                                                                                                         
    * @return                         Value properties from element value                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_value_properties
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_element_type    IN doc_element.flg_type%TYPE,
        i_element_value   IN epis_documentation_det.value%TYPE,
        i_element         IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_element_vs_list IN pk_touch_option_ti.t_coll_doc_element_vs DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_properties epis_documentation_det.value_properties%TYPE;
        l_value      table_varchar2;
    
        /**
        * For vital-sign-related elements, this function returns the associated vital sign read IDs (VSR)
         The association between element and VSR will be done in set_epis_documentation, filling the field EPIS_DOCUMENTATION_DET.VALUE_PROPERTIES with this output
        *
        * @return  A string that concatenates each id_vital_sign_read associated to the element with pipes
        *
        * @author  ARIEL.MACHADO
        * @version 2.6.1
        * @since   3/31/2011
        */
        FUNCTION inner_get_vs_element_props RETURN VARCHAR2 IS
            l_ret epis_documentation_det.value_properties%TYPE;
        BEGIN
            IF i_element_vs_list IS NOT NULL
            THEN
                <<find_element>>
                FOR x IN 1 .. i_element_vs_list.count
                LOOP
                
                    IF i_element_vs_list(x).id_doc_element = i_element
                    THEN
                        l_ret := pk_utils.concat_table(i_tab   => i_element_vs_list(x).vital_sign_read_list,
                                                       i_delim => '|');
                    END IF;
                
                    EXIT find_element WHEN i_element_vs_list(x).id_doc_element = i_element;
                END LOOP find_element;
            END IF;
            RETURN l_ret;
        END inner_get_vs_element_props;
    
    BEGIN
        CASE i_element_type
            WHEN g_elem_flg_type_comp_date THEN
                --Compound date element
                IF (instr(upper(i_element_value), upper(pk_date_utils.g_dateformat)) != 0)
                THEN
                    --If it's a date and hour value then the property value is the timezone
                    l_properties := pk_date_utils.get_timezone(i_lang, i_prof);
                ELSE
                    l_properties := NULL;
                END IF;
            
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
            
                -- Checks if number has an unit of measure (UOM). 
                -- Format <num_value>|<UOM>
                l_value := pk_utils.str_split(i_element_value, '|');
                IF l_value.count != 2
                THEN
                    l_properties := NULL;
                ELSE
                    l_properties := l_value(2);
                END IF;
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
            
                -- Checks if number has an unit of measure (UOM) and/or reference values 
                -- Format <num_value>|<id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_min>|<ref_val_max>
                l_value := pk_utils.str_split(i_element_value, '|');
                IF l_value.count != 6
                THEN
                    pk_alertlog.log_error(text            => 'Unexpected number of properties for numeric element with reference values (CR): ' ||
                                                             i_element_value,
                                          object_name     => g_package_name,
                                          sub_object_name => 'get_value_properties');
                    l_properties := NULL;
                ELSE
                    l_properties := l_value(2) || '|' || l_value(3) || '|' || l_value(4) || '|' || l_value(5) || '|' ||
                                    l_value(6);
                END IF;
            WHEN g_elem_flg_type_vital_sign THEN
                --Concatenate id_vital_sign_reads associated to this element
                l_properties := inner_get_vs_element_props();
            ELSE
                l_properties := NULL;
        END CASE;
    
        RETURN l_properties;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_VALUE_PROPERTIES');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
        
    END get_value_properties;

    /**
    * Extract value properties from a string returning a record structure where each discrete property is filled. 
      This function is a (semi) "reverse version" of get_value_properties()
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_element_type      Element type (Comp. element date, etc. ) 
    * @param   i_value_properties  Value properties from element value
    *
    * @return  A record structure with each property filled
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   14-06-2011
    */
    FUNCTION expand_value_properties
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_element_type     IN doc_element.flg_type%TYPE,
        i_value_properties IN epis_documentation_det.value_properties%TYPE
    ) RETURN t_rec_value_properties IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'expand_value_properties';
        l_rec_value_properties t_rec_value_properties;
        l_lst_properties       table_varchar2;
        l_vsr_list             table_number;
    BEGIN
        /* TODO: Implementation here! */
    
        CASE i_element_type
        
            WHEN g_elem_flg_type_comp_date THEN
                --Compound date element
            
                IF i_value_properties IS NOT NULL
                THEN
                    -- If defined is because it's a date and hour value then the property value is the timezone
                    l_rec_value_properties.timezone_region := i_value_properties;
                END IF;
            
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
                IF i_value_properties IS NOT NULL
                   AND pk_utils.is_number(i_value_properties) = pk_alert_constant.g_yes
                THEN
                    --If defined is because this number has an unit of measure (UOM).
                    l_rec_value_properties.id_unit_measure := to_number(i_value_properties);
                
                END IF;
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
                --Format: <id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_min>|<ref_val_max>
                l_lst_properties := pk_utils.str_split(i_value_properties, '|');
            
                l_rec_value_properties.id_unit_measure := CASE l_lst_properties.exists(1)
                                                              WHEN TRUE THEN
                                                               to_number(l_lst_properties(1))
                                                              ELSE
                                                               NULL
                                                          END;
                l_rec_value_properties.flg_ref_op_min  := CASE l_lst_properties.exists(2)
                                                              WHEN TRUE THEN
                                                               l_lst_properties(2)
                                                              ELSE
                                                               NULL
                                                          END;
                l_rec_value_properties.ref_val_min     := CASE l_lst_properties.exists(3)
                                                              WHEN TRUE THEN
                                                               to_number(REPLACE(l_lst_properties(3), '+', NULL),
                                                                         k_to_number_mask)
                                                              ELSE
                                                               NULL
                                                          END;
                l_rec_value_properties.flg_ref_op_max  := CASE l_lst_properties.exists(4)
                                                              WHEN TRUE THEN
                                                               l_lst_properties(4)
                                                              ELSE
                                                               NULL
                                                          END;
                l_rec_value_properties.ref_val_max     := CASE l_lst_properties.exists(5)
                                                              WHEN TRUE THEN
                                                               to_number(REPLACE(l_lst_properties(5), '+', NULL),
                                                                         k_to_number_mask)
                                                              ELSE
                                                               NULL
                                                          END;
            
            WHEN g_elem_flg_type_vital_sign THEN
                -- An element associated to a vital sign
                --id_vital_sign_reads associated to this element are saved in the value_properties field separating each ID by pipes
                l_lst_properties := pk_utils.str_split(i_value_properties, '|');
            
                IF l_lst_properties.count > 0
                THEN
                    l_vsr_list := table_number();
                    l_vsr_list.extend(l_lst_properties.count);
                    FOR i IN 1 .. l_lst_properties.count
                    LOOP
                        l_vsr_list(i) := to_number(l_lst_properties(i));
                    END LOOP;
                    l_rec_value_properties.vital_sign_read_list := l_vsr_list;
                END IF;
            
            ELSE
                --No other elements are using value properties
                l_rec_value_properties := NULL;
        END CASE;
    
        RETURN l_rec_value_properties;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => co_function_name,
                                                  o_error    => l_error);
                RAISE;
            END;
    END expand_value_properties;

    /********************************************************************************************
    * Returns the date formats used in Touch-option templates 
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    *                                                                                                                                         
    * @param o_date_formats           Date formats
    * @param o_error                  Error message
    *
    * @return                         True or False on success or error
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_formats
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_date_formats OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_aux                          VARCHAR2(32467);
        l_tab_date_format              t_table_rec_touch_date_format := t_table_rec_touch_date_format();
        l_tab_invalid_date_format_cfgs t_table_rec_touch_date_format := t_table_rec_touch_date_format();
        l_rec_date_format              t_rec_touch_date_format := t_rec_touch_date_format(NULL, NULL, NULL, NULL);
    
        misconfiguration_exception EXCEPTION;
    
    BEGIN
        --The constant k_touchoption_date_types represent different date types that can be used in Touch-option templates
        FOR x IN 1 .. k_touchoption_date_types.count
        LOOP
            l_rec_date_format.date_type := k_touchoption_date_types(x);
            --Indirect sys_config ID to obtain the format representation for a date type: TO_FMT_YYYY, TO_FMT_MM, TO_FMT_YYYYMM,... 
            l_rec_date_format.date_type_config := 'TO_FMT_' || k_touchoption_date_types(x);
        
            --sys_config ID to obtain format representation: DATE_YEAR, DATE_MONTH,... 
            SELECT pk_sysconfig.get_config(l_rec_date_format.date_type_config, i_prof.institution, i_prof.software)
              INTO l_rec_date_format.format_config
              FROM dual;
        
            --Format representation: YYYY, Month, DD-Mon-YYYY,...
            SELECT pk_sysconfig.get_config(l_rec_date_format.format_config, i_prof.institution, i_prof.software)
              INTO l_rec_date_format.format
              FROM dual;
        
            l_tab_date_format.extend;
            l_tab_date_format(l_tab_date_format.last) := l_rec_date_format;
        END LOOP;
    
        --Sanity check: misconfiguration on SYS_CONFIG can provocates a null format as return. 
        SELECT t_rec_touch_date_format(date_type, date_type_config, format_config, format)
          BULK COLLECT
          INTO l_tab_invalid_date_format_cfgs
          FROM TABLE(l_tab_date_format)
         WHERE format IS NULL;
    
        IF l_tab_invalid_date_format_cfgs.count > 0
        THEN
            RAISE misconfiguration_exception;
        END IF;
    
        --Returns the formats for each date type
        OPEN o_date_formats FOR
            SELECT t.date_type, t.format
              FROM TABLE(l_tab_date_format) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN misconfiguration_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_aux := 'Invalid sys_config parameterization for Touch-option date formats: ';
                FOR i IN 1 .. l_tab_invalid_date_format_cfgs.count
                LOOP
                    l_aux := l_aux || chr(10) || l_tab_invalid_date_format_cfgs(i).date_type || ' = ' ||
                             nvl(l_tab_invalid_date_format_cfgs(i).date_type_config, 'NULL') || ' ==> ' ||
                             nvl(l_tab_invalid_date_format_cfgs(i).format_config, 'NULL') || ' = ' ||
                             nvl(l_tab_invalid_date_format_cfgs(i).format, 'NULL');
                END LOOP;
            
                l_error_in.set_all(i_lang, NULL, NULL, l_aux, g_package_owner, g_package_name, 'GET_DATE_FORMATS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_date_formats);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DATE_FORMATS');
                /* Open out cursors */
                pk_types.open_my_cursor(o_date_formats);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_date_formats;

    /********************************************************************************************
    * Returns the date type stored in the element value
    * 
    * @param i_value                  Element value                                                                                              
    *
    * @return                         Element date type (See pk_touch_option.k_touchoption_date_types)
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/01/26                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_type(i_value IN epis_documentation_det.value%TYPE) RETURN VARCHAR2 IS
        l_value table_varchar2;
        l_type  VARCHAR2(200 CHAR);
    BEGIN
        -- <date_value>|<date_type>
        l_value := pk_utils.str_split(i_value, '|');
    
        IF l_value.count != 2
        THEN
        
            raise_application_error(-20010,
                                    'Date value has invalid format. Expected format: <date_value>|<date_type> ');
        ELSE
            IF l_value(2) NOT MEMBER OF pk_touch_option.k_touchoption_date_types
            THEN
                raise_application_error(-20011, 'The value has an invalid date type: ''' || l_value(2) || '''');
            ELSE
                l_type := l_value(2);
            END IF;
        END IF;
        RETURN l_type;
    END get_date_type;

    /********************************************************************************************
    * Returns the value in a respective data type
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_type                   Element type
    * @param i_value                  Element value
    * @param i_properties             Properties for the element value 
    * @param i_input_mask             Input mask used by element to introduce the value
    * @param i_optional_value         Element value may be optional
    * @param i_domain_type            Element domain type
    * @param i_code_element_domain    Element domain code
    *
    * @return                         A self describing object with the value
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/02                                                                                               
    ********************************************************************************************/

    FUNCTION get_real_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_type                IN doc_element.flg_type%TYPE,
        i_value               IN epis_documentation_det.value%TYPE,
        i_properties          IN epis_documentation_det.value_properties%TYPE,
        i_input_mask          IN doc_element.input_mask%TYPE,
        i_optional_value      IN doc_element.flg_optional_value%TYPE,
        i_domain_type         IN doc_element.flg_element_domain_type%TYPE,
        i_code_element_domain IN doc_element.code_element_domain%TYPE
    ) RETURN anydata IS
    
        l_real_value  anydata;
        l_value_parts table_varchar2;
    
        invalid_value_exception        EXCEPTION;
        invalid_value_format_exception EXCEPTION;
    BEGIN
    
        CASE i_type
        -- Element type: compound element for dates
            WHEN g_elem_flg_type_comp_date THEN
            
                -- <date_value>|<date_type>
                l_value_parts := pk_utils.str_split(i_value, '|');
            
                IF l_value_parts.count != 2
                THEN
                    raise_application_error(-20010,
                                            'Date value has invalid format. Expected format: <date_value>|<date_type> ');
                ELSE
                
                    IF l_value_parts(2) NOT MEMBER OF pk_touch_option.k_touchoption_date_types
                    THEN
                        RAISE invalid_value_format_exception;
                    END IF;
                
                    IF i_properties IS NOT NULL
                    THEN
                        l_real_value := anydata.converttimestamptz(to_timestamp_tz(l_value_parts(1) || ' ' ||
                                                                                   i_properties,
                                                                                   l_value_parts(2) || ' TZR'));
                    ELSE
                        l_real_value := anydata.converttimestamp(to_timestamp(l_value_parts(1), l_value_parts(2)));
                    END IF;
                
                END IF;
            
        --Element type: compound element for number
            WHEN g_elem_flg_type_comp_numeric THEN
                l_real_value := anydata.convertnumber(to_number(REPLACE(i_value, '+', NULL), k_to_number_mask));
                --Element type: compound element for number with reference values
            WHEN g_elem_flg_type_comp_ref_value THEN
                l_real_value := anydata.convertnumber(to_number(REPLACE(i_value, '+', NULL), k_to_number_mask));
            ELSE
                l_real_value := anydata.convertvarchar2(i_value);
            
        END CASE;
    
        RETURN l_real_value;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_err_instance_id PLS_INTEGER;
                l_ret             BOOLEAN;
                l_error_in        t_error_in := t_error_in();
                l_error_out       t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_REAL_VALUE');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
            
                l_err_instance_id := l_error_out.err_instance_id_out;
            
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'INSTITUTION',
                                                value_in           => i_prof.institution);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'SOFTWARE',
                                                value_in           => i_prof.software);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'VALUE',
                                                value_in           => i_value);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'PROPERTIES',
                                                value_in           => i_properties);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'INPUT_MASK',
                                                value_in           => i_input_mask);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'OPTIONAL_VALUE',
                                                value_in           => i_optional_value);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'DOMAIN_TYPE',
                                                value_in           => i_domain_type);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'CODE_ELEMENT_DOMAIN',
                                                value_in           => i_code_element_domain);
            
                pk_alert_exceptions.reset_error_state;
                RETURN NULL;
            
            END;
        
    END get_real_value;

    /********************************************************************************************
    * Returns a formatted string that represents the element value
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_type                   Element type
    * @param i_value                  Element value
    * @param i_properties             Properties for the element value 
    * @param i_input_mask             Input mask used by element to introduce the value
    * @param i_optional_value         Element value may be optional
    * @param i_domain_type            Element domain type
    * @param i_code_element_domain    Element domain code,
    * @param i_dt_creation            Timestamp of template's element (Optional)
    *
    * @return                         A formatted string value
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/02                                                                                               
    ********************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_type                IN doc_element.flg_type%TYPE,
        i_value               IN epis_documentation_det.value%TYPE,
        i_properties          IN epis_documentation_det.value_properties%TYPE,
        i_input_mask          IN doc_element.input_mask%TYPE,
        i_optional_value      IN doc_element.flg_optional_value%TYPE,
        i_domain_type         IN doc_element.flg_element_domain_type%TYPE,
        i_code_element_domain IN doc_element.code_element_domain%TYPE,
        i_dt_creation         IN epis_documentation_det.dt_creation_tstz%TYPE := NULL
    ) RETURN VARCHAR2 IS
        l_sys_cfg_ref_value_msk  CONSTANT sys_config.id_sys_config%TYPE := 'TO_REFERENCE_VALUE_MASK';
        l_code_domain_ref_op_min CONSTANT sys_domain.code_domain%TYPE := 'DOC_ELEMENT.FLG_REF_OP_MIN';
        l_code_domain_ref_op_max CONSTANT sys_domain.code_domain%TYPE := 'DOC_ELEMENT.FLG_REF_OP_MAX';
        l_code_msg_lbl_ref_range CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M045';
        l_code_msg_lbl_to        CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M046';
        l_msk_tag_lbl_ref_range  CONSTANT VARCHAR2(30 CHAR) := '<LBL_REF_RANGE>';
        l_msk_tag_lbl_to         CONSTANT VARCHAR2(30 CHAR) := '<LBL_TO>';
        l_msk_tag_ref_op_min     CONSTANT VARCHAR2(30 CHAR) := '<REF_OP_MIN>';
        l_msk_tag_ref_op_max     CONSTANT VARCHAR2(30 CHAR) := '<REF_OP_MAX>';
        l_msk_tag_ref_val_min    CONSTANT VARCHAR2(30 CHAR) := '<REF_VAL_MIN>';
        l_msk_tag_ref_val_max    CONSTANT VARCHAR2(30 CHAR) := '<REF_VAL_MAX>';
    
        function_call_excep    EXCEPTION;
        l_lbl_ref_range        sys_message.desc_message%TYPE;
        l_lbl_ref_to           sys_message.desc_message%TYPE;
        l_date_type            sys_config.id_sys_config%TYPE;
        l_date_format          sys_config.value%TYPE;
        l_decimal_separator    sys_config.value%TYPE;
        l_date_formats         pk_types.cursor_type;
        l_uom_abbrev           pk_translation.t_desc_translation;
        l_error_out            t_error_out;
        l_formatted_value      VARCHAR2(32767);
        l_formatted_ref_value  VARCHAR2(32767);
        l_format_string        VARCHAR2(32767);
        l_value_type           VARCHAR2(200 CHAR);
        l_ref_val_min          VARCHAR2(200 CHAR);
        l_ref_val_max          VARCHAR2(200 CHAR);
        l_value_tstz           TIMESTAMP WITH TIME ZONE;
        l_real_value           anydata;
        l_ret                  BOOLEAN;
        l_rec_value_properties t_rec_value_properties;
    BEGIN
    
        IF nvl(i_optional_value, g_no) = g_yes
           AND i_value IS NULL
        THEN
            --An optional value not filled
            l_formatted_value := NULL;
        ELSE
            --Non optional value
        
            g_error                := 'EXPANDING VALUE_PROPERTIES';
            l_rec_value_properties := expand_value_properties(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_element_type     => i_type,
                                                              i_value_properties => i_properties);
        
            CASE i_type
            -- Element type: compound element for dates
                WHEN g_elem_flg_type_comp_date THEN
                
                    l_value_type := get_date_type(i_value);
                
                    --Check if already exists format in cache
                    IF NOT g_touchoption_date_type_format.exists(l_value_type || '|' || i_prof.institution || '|' ||
                                                                 i_prof.software)
                    THEN
                        --Update cache with date formats used by Touch-option mechanism (by soft/inst)
                        l_ret := get_date_formats(i_lang, i_prof, l_date_formats, l_error_out);
                        IF l_ret = FALSE
                        THEN
                            RAISE function_call_excep;
                        END IF;
                    
                        LOOP
                            FETCH l_date_formats
                                INTO l_date_type, l_date_format;
                            EXIT WHEN l_date_formats%NOTFOUND;
                            g_touchoption_date_type_format(l_date_type || '|' || i_prof.institution || '|' || i_prof.software) := l_date_format;
                        END LOOP;
                        CLOSE l_date_formats;
                    END IF;
                
                    l_format_string := g_touchoption_date_type_format(l_value_type || '|' || i_prof.institution || '|' ||
                                                                      i_prof.software);
                
                    --Obtain the value in the right data type
                    l_real_value := get_real_value(i_lang,
                                                   i_prof,
                                                   i_type,
                                                   i_value,
                                                   i_properties,
                                                   i_input_mask,
                                                   i_optional_value,
                                                   i_domain_type,
                                                   i_code_element_domain);
                
                    CASE l_real_value.gettypename()
                        WHEN 'SYS.TIMESTAMP_WITH_TIMEZONE' THEN
                            l_value_tstz      := pk_anydata_utils.get_timestamp_tz(l_real_value);
                            l_formatted_value := pk_date_utils.to_char_insttimezone(i_lang,
                                                                                    i_prof,
                                                                                    l_value_tstz,
                                                                                    l_format_string);
                        
                        WHEN 'SYS.TIMESTAMP' THEN
                            l_value_tstz      := pk_anydata_utils.get_timestamp(l_real_value);
                            l_formatted_value := pk_date_utils.to_char_timezone(i_lang, l_value_tstz, l_format_string);
                        
                        ELSE
                            pk_alert_exceptions.raise_error(error_name_in => 'Unexpected typename for a date element');
                    END CASE;
                
            --Element type: compound element for number
                WHEN g_elem_flg_type_comp_numeric THEN
                    IF instr(i_value, '.') = 0
                    THEN
                        l_formatted_value := i_value;
                    ELSE
                        --TODO: To improve the performance, evaluate the advantage of doing a cache of sys_config value
                        l_decimal_separator := pk_sysconfig.get_config(g_scfg_decimal_separator, i_prof);
                    
                        l_formatted_value := REPLACE(to_char(to_number(REPLACE(i_value, '+', NULL), k_to_number_mask),
                                                             i_input_mask),
                                                     '.',
                                                     l_decimal_separator);
                    
                        -- Format the input value in case we have an invalid number (like 999.)
                        IF substr(l_formatted_value, length(l_formatted_value), 1) = l_decimal_separator
                        THEN
                            l_formatted_value := substr(l_formatted_value, 1, length(l_formatted_value) - 1);
                        END IF;
                    END IF;
                
                    --Checks if number has an unit of measure (UOM) on value_properties field. 
                    IF l_rec_value_properties.id_unit_measure IS NOT NULL
                    THEN
                        l_uom_abbrev := pk_unit_measure.get_uom_abbreviation(i_lang,
                                                                             i_prof,
                                                                             l_rec_value_properties.id_unit_measure);
                        IF l_uom_abbrev IS NOT NULL
                        THEN
                            l_formatted_value := l_formatted_value || ' ' || l_uom_abbrev;
                        END IF;
                    END IF;
                
            --Element type: compound element multichoice singleselect
                WHEN g_elem_flg_type_mchoice_single THEN
                
                    CASE i_domain_type
                    -- element domain: Template
                        WHEN g_flg_element_domain_template THEN
                            l_formatted_value := pk_touch_option.get_element_desc_domain(i_lang,
                                                                                         i_code_element_domain,
                                                                                         i_value); -- element template value
                    
                    -- element domain: SysDomain
                        WHEN g_flg_element_domain_sysdomain THEN
                            l_formatted_value := pk_sysdomain.get_domain(i_code_element_domain, i_value, i_lang); -- element sys_domain value
                    
                    -- element domain: Dynamic
                        WHEN g_flg_element_domain_dynamic THEN
                            l_formatted_value := pk_touch_option.get_dynamic_desc_domain(i_lang,
                                                                                         i_prof,
                                                                                         i_code_element_domain,
                                                                                         i_value); -- element dynamic value
                    
                    -- Other element domain for multichoice (singleselect)
                        ELSE
                            l_formatted_value := i_value;
                    END CASE;
                
            --Element type: compound element multichoice multiselect    
                WHEN g_elem_flg_type_mchoice_multpl THEN
                
                    CASE i_domain_type
                    -- element domain: Template
                        WHEN g_flg_element_domain_template THEN
                            -- element template value set
                            l_formatted_value := pk_touch_option.get_element_desc_domain_set(i_lang,
                                                                                             i_code_element_domain,
                                                                                             i_value);
                        
                    -- element domain: SysDomain
                        WHEN g_flg_element_domain_sysdomain THEN
                            -- element template values set
                            l_formatted_value := pk_sysdomain.get_desc_domain_set(i_lang,
                                                                                  i_code_element_domain,
                                                                                  i_value);
                            IF instr(i_value, '|') > 0
                            THEN
                                l_formatted_value := '(' || l_formatted_value || ')';
                            END IF;
                        
                    -- element domain: Dynamic
                        WHEN g_flg_element_domain_dynamic THEN
                            -- element dynamic values set
                            l_formatted_value := pk_touch_option.get_dynamic_desc_domain_set(i_lang,
                                                                                             i_prof,
                                                                                             i_code_element_domain,
                                                                                             i_value);
                        
                    -- Other element domain for multichoice (singleselect)
                        ELSE
                            l_formatted_value := i_value;
                    END CASE;
                
            --Element type: compound element for number with reference values
                WHEN g_elem_flg_type_comp_ref_value THEN
                
                    IF instr(i_value, '.') = 0
                    THEN
                        l_formatted_value := i_value;
                    ELSE
                        --TODO: To improve the performance, evaluate the advantage of doing a cache of sys_config value
                        l_decimal_separator := pk_sysconfig.get_config(g_scfg_decimal_separator, i_prof);
                        l_formatted_value   := REPLACE(to_char(to_number(REPLACE(i_value, '+', NULL), k_to_number_mask),
                                                               i_input_mask),
                                                       '.',
                                                       l_decimal_separator);
                    
                        -- Check and remove decimal separator in case we have an invalid number (like 999.)
                        IF substr(l_formatted_value, length(l_formatted_value), 1) = l_decimal_separator
                        THEN
                            l_formatted_value := substr(l_formatted_value, 1, length(l_formatted_value) - 1);
                        END IF;
                    END IF;
                
                    --Checks if number has an unit of measure (UOM) and reference values in value_properties field. 
                    IF i_properties IS NOT NULL
                    THEN
                        -- Format <id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_max>|<ref_val_max>
                    
                        IF l_rec_value_properties.id_unit_measure IS NOT NULL
                        THEN
                            --Retrieves UoM abbreviation
                            l_uom_abbrev := pk_unit_measure.get_uom_abbreviation(i_lang,
                                                                                 i_prof,
                                                                                 l_rec_value_properties.id_unit_measure);
                        
                            --Append UoM to value
                            l_formatted_value := pk_string_utils.concat_if_exists(l_formatted_value, l_uom_abbrev, ' ');
                        END IF;
                    
                        -- Formatting lower boundary of reference value (minimum)
                        IF l_rec_value_properties.ref_val_min IS NOT NULL
                        THEN
                            -- Format numeric value
                            l_ref_val_min := REPLACE(to_char(l_rec_value_properties.ref_val_min, i_input_mask),
                                                     '.',
                                                     l_decimal_separator);
                            -- Check and remove decimal separator in case we have an invalid number (like 999.)
                            IF substr(l_ref_val_min, length(l_ref_val_min), 1) = l_decimal_separator
                            THEN
                                l_ref_val_min := substr(l_ref_val_min, 1, length(l_ref_val_min) - 1);
                            END IF;
                        
                            --Append UoM to value
                            l_ref_val_min := pk_string_utils.concat_if_exists(l_ref_val_min, l_uom_abbrev, ' ');
                        
                        END IF;
                    
                        -- Formatting upper boundary of reference value (maximum)
                        IF l_rec_value_properties.ref_val_max IS NOT NULL
                        THEN
                            -- Format numeric value
                            l_ref_val_max := REPLACE(to_char(l_rec_value_properties.ref_val_max, i_input_mask),
                                                     '.',
                                                     l_decimal_separator);
                            -- Check and remove decimal separator in case we have an invalid number (like 999.)
                            IF substr(l_ref_val_max, length(l_ref_val_max), 1) = l_decimal_separator
                            THEN
                                l_ref_val_max := substr(l_ref_val_max, 1, length(l_ref_val_max) - 1);
                            END IF;
                        
                            --Append UoM to value
                            l_ref_val_max := pk_string_utils.concat_if_exists(l_ref_val_max, l_uom_abbrev, ' ');
                        
                        END IF;
                    
                        -- Append Ref. Values 
                        IF (length(l_ref_val_min) > 0 OR length(l_ref_val_max) > 0)
                        THEN
                        
                            -- Retrieves formatting mask to expressing values with reference values
                            -- Example: (<LBL_REF_RANGE> <REF_OP_MIN><REF_VAL_MIN> <LBL_TO> <REF_OP_MAX><REF_VAL_MAX>)
                            l_formatted_ref_value := pk_sysconfig.get_config(l_sys_cfg_ref_value_msk, i_prof);
                        
                            -- "ref.value" label
                            l_lbl_ref_range       := pk_message.get_message(i_lang, l_code_msg_lbl_ref_range);
                            l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                             l_msk_tag_lbl_ref_range,
                                                             l_lbl_ref_range);
                        
                            -- Op min ref.value
                            l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                             l_msk_tag_ref_op_min,
                                                             pk_sysdomain.get_domain_cached(i_lang,
                                                                                            l_rec_value_properties.flg_ref_op_min,
                                                                                            l_code_domain_ref_op_min));
                            -- Op max ref.value
                            l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                             l_msk_tag_ref_op_max,
                                                             pk_sysdomain.get_domain_cached(i_lang,
                                                                                            l_rec_value_properties.flg_ref_op_max,
                                                                                            l_code_domain_ref_op_max));
                            -- Min ref.value
                            l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                             l_msk_tag_ref_val_min,
                                                             l_ref_val_min);
                            -- Max ref.value
                            l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                             l_msk_tag_ref_val_max,
                                                             l_ref_val_max);
                        
                            -- "to" label (if both ref.values are defined) or none
                            IF length(l_ref_val_min) > 0
                               AND length(l_ref_val_max) > 0
                            THEN
                                l_lbl_ref_to          := pk_message.get_message(i_lang, l_code_msg_lbl_to);
                                l_formatted_ref_value := REPLACE(l_formatted_ref_value,
                                                                 l_msk_tag_lbl_to,
                                                                 nvl(l_lbl_ref_to, '—'));
                            ELSE
                                l_formatted_ref_value := REPLACE(l_formatted_ref_value, l_msk_tag_lbl_to, NULL);
                            END IF;
                        
                            --replace all multiple spaces with one space
                            l_formatted_ref_value := regexp_replace(l_formatted_ref_value, '  *', ' ');
                        
                            -- Final string = Formatted value + Formatted ref.values
                            l_formatted_value := l_formatted_value || ' ' || l_formatted_ref_value;
                        END IF;
                    END IF;
                
            --Element type: vital sign
                WHEN g_elem_flg_type_vital_sign THEN
                    -- Composite vital signs like blood pressure have two or more ID_VITAL_SIGN_READ.
                    -- These IDs are saved in the value_properties field separating each ID by pipes.
                    -- The function that retrieves the formatted value just need one ID.
                    IF l_rec_value_properties.vital_sign_read_list IS NOT NULL
                       AND l_rec_value_properties.vital_sign_read_list.count() > 0
                    THEN
                        l_formatted_value := pk_touch_option_ti.get_formatted_vsread(i_lang        => i_lang,
                                                                                     i_prof        => i_prof,
                                                                                     i_vsread      => l_rec_value_properties.vital_sign_read_list(1),
                                                                                     i_dt_creation => i_dt_creation);
                    END IF;
                WHEN g_elem_flg_type_simple_float THEN
                    IF i_input_mask IS NULL
                    THEN
                        l_formatted_value := i_value;
                    ELSE
                        IF instr(i_value, '.') = 0
                        THEN
                            l_formatted_value := i_value;
                        ELSE
                            l_decimal_separator := pk_sysconfig.get_config(g_scfg_decimal_separator, i_prof);
                            l_formatted_value   := REPLACE(to_char(to_number(REPLACE(REPLACE(i_value, '+', NULL),
                                                                                     ',',
                                                                                     '.'),
                                                                             k_to_number_mask),
                                                                   i_input_mask),
                                                           '.',
                                                           l_decimal_separator);
                        
                            -- Format the input value in case we have an invalid number (like 999.)
                            IF substr(l_formatted_value, length(l_formatted_value), 1) = l_decimal_separator
                            THEN
                                l_formatted_value := substr(l_formatted_value, 1, length(l_formatted_value) - 1);
                            END IF;
                        END IF;
                    END IF;
                WHEN g_elem_flg_type_simple_number THEN
                    IF i_input_mask IS NULL
                    THEN
                        l_formatted_value := i_value;
                    ELSE
                        IF instr(i_value, '.') = 0
                        THEN
                            l_formatted_value := i_value;
                        ELSE
                            l_decimal_separator := pk_sysconfig.get_config(g_scfg_decimal_separator, i_prof);
                            l_formatted_value   := REPLACE(to_char(to_number(REPLACE(REPLACE(i_value, '+', NULL),
                                                                                     ',',
                                                                                     '.'),
                                                                             k_to_number_mask),
                                                                   i_input_mask),
                                                           '.',
                                                           l_decimal_separator);
                        
                            -- Format the input value in case we have an invalid number (like 999.)
                            IF substr(l_formatted_value, length(l_formatted_value), 1) = l_decimal_separator
                            THEN
                                l_formatted_value := substr(l_formatted_value, 1, length(l_formatted_value) - 1);
                            END IF;
                        END IF;
                    END IF;
                WHEN g_elem_flg_type_simple_neg THEN
                    IF i_input_mask IS NULL
                    THEN
                        l_formatted_value := i_value;
                    ELSE
                        IF instr(i_value, '.') = 0
                        THEN
                            l_formatted_value := i_value;
                        ELSE
                            l_decimal_separator := pk_sysconfig.get_config(g_scfg_decimal_separator, i_prof);
                            l_formatted_value   := REPLACE(to_char(to_number(REPLACE(REPLACE(i_value, '+', NULL),
                                                                                     ',',
                                                                                     '.'),
                                                                             k_to_number_mask),
                                                                   i_input_mask),
                                                           '.',
                                                           l_decimal_separator);
                        
                            -- Format the input value in case we have an invalid number (like 999.)
                            IF substr(l_formatted_value, length(l_formatted_value), 1) = l_decimal_separator
                            THEN
                                l_formatted_value := substr(l_formatted_value, 1, length(l_formatted_value) - 1);
                            END IF;
                        END IF;
                    END IF;
                ELSE
                    --Other data types...
                    l_formatted_value := i_value;
            END CASE;
        
        END IF;
        RETURN TRIM(l_formatted_value);
    
    EXCEPTION
        WHEN function_call_excep THEN
            --o_error already logged by called function
            RETURN NULL;
        
        WHEN OTHERS THEN
            DECLARE
                l_err_instance_id PLS_INTEGER;
                l_ret             BOOLEAN;
                l_error_in        t_error_in := t_error_in();
                l_error_out       t_error_out;
            
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_FORMATED_VALUE');
            
                l_ret             := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                l_err_instance_id := l_error_out.err_instance_id_out;
            
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'INSTITUTION',
                                                value_in           => i_prof.institution);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'SOFTWARE',
                                                value_in           => i_prof.software);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'VALUE',
                                                value_in           => i_value);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'PROPERTIES',
                                                value_in           => i_properties);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'INPUT_MASK',
                                                value_in           => i_input_mask);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'OPTIONAL_VALUE',
                                                value_in           => i_optional_value);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'DOMAIN_TYPE',
                                                value_in           => i_domain_type);
                pk_alert_exceptions.add_context(err_instance_id_in => l_err_instance_id,
                                                name_in            => 'CODE_ELEMENT_DOMAIN',
                                                value_in           => i_code_element_domain);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN NULL;
            END;
    END get_formatted_value;

    /********************************************************************************************
    * Returns a timestamp that represents the element value
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_element_crit       Element criteria ID
    * @param i_epis_documentation     The documentation episode id
    *
    * @return                         A timestamp value
    *                                                                                                                          
    * @author                         José Silva                                                                              
    * @version                        1.0 (2.5)                                                                                                     
    * @since                          2009/05/06                                                                                               
    ********************************************************************************************/
    FUNCTION get_value_tstz
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_element_crit   IN doc_element_crit.id_doc_element_crit%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_real_value anydata;
        l_value_tstz TIMESTAMP WITH TIME ZONE;
    
        l_type                doc_element.flg_type%TYPE;
        l_value               epis_documentation_det.value%TYPE;
        l_properties          epis_documentation_det.value_properties%TYPE;
        l_input_mask          doc_element.input_mask%TYPE;
        l_optional_value      doc_element.flg_optional_value%TYPE;
        l_domain_type         doc_element.flg_element_domain_type%TYPE;
        l_code_element_domain doc_element.code_element_domain%TYPE;
    
    BEGIN
    
        g_error := 'GET REAL VALUE PARAMETERS';
        SELECT edd.value,
               edd.value_properties,
               de.flg_type,
               de.input_mask,
               de.flg_optional_value,
               de.flg_element_domain_type,
               de.code_element_domain
          INTO l_value, l_properties, l_type, l_input_mask, l_optional_value, l_domain_type, l_code_element_domain
          FROM epis_documentation_det edd
          JOIN doc_element de
            ON de.id_doc_element = edd.id_doc_element
         WHERE edd.id_epis_documentation = i_epis_documentation
           AND edd.id_doc_element_crit = i_doc_element_crit;
    
        g_error := 'GET REAL VALUE';
        --Obtain the value in the right data type
        l_real_value := get_real_value(i_lang,
                                       i_prof,
                                       l_type,
                                       l_value,
                                       l_properties,
                                       l_input_mask,
                                       l_optional_value,
                                       l_domain_type,
                                       l_code_element_domain);
    
        g_error := 'CONVERT REAL VALUE';
        CASE l_real_value.gettypename()
            WHEN 'SYS.TIMESTAMP_WITH_TIMEZONE' THEN
                l_value_tstz := pk_anydata_utils.get_timestamp_tz(l_real_value);
            WHEN 'SYS.TIMESTAMP' THEN
                l_value_tstz := pk_anydata_utils.get_timestamp(l_real_value);
            ELSE
                l_value_tstz := NULL;
        END CASE;
    
        RETURN l_value_tstz;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_VALUE_TSTZ');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
    END get_value_tstz;

    /********************************************************************************************
    * Returns a string that represents the date value at institution timezone
    * The i_value and returned string are in Flash/DB interchange format with partial date support
    * ( <date_value>|<date_type>)
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_value                  Element value (<date_value>|<date_type>)
    * @param i_properties             Properties for the element value 
    *
    * @return                         A <date_value>|<date_type> string at timezone institution
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/04                                                                                               
    ********************************************************************************************/
    FUNCTION get_date_value_insttimezone
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN epis_documentation_det.value%TYPE,
        i_properties IN epis_documentation_det.value_properties%TYPE
        
    ) RETURN VARCHAR2 IS
        l_return          VARCHAR2(100 CHAR);
        l_date_type       VARCHAR2(100 CHAR);
        l_real_value      anydata;
        l_real_value_tstz TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error     := 'CALL GET_DATE_TYPE';
        l_date_type := get_date_type(i_value);
    
        g_error := 'CALL GET_REAL_VALUE';
        --Obtain the value in the right data type
        l_real_value := get_real_value(i_lang,
                                       i_prof,
                                       g_elem_flg_type_comp_date,
                                       i_value,
                                       i_properties,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL);
    
        g_error := 'ANALYZING VALUE TYPE';
        CASE l_real_value.gettypename()
            WHEN 'SYS.TIMESTAMP_WITH_TIMEZONE' THEN
                g_error           := 'TIMESTAMP WITH TIME ZONE TO CHAR';
                l_real_value_tstz := pk_anydata_utils.get_timestamp_tz(l_real_value);
                l_return          := pk_date_utils.to_char_insttimezone(i_lang, i_prof, l_real_value_tstz, l_date_type);
            WHEN 'SYS.TIMESTAMP' THEN
                g_error           := 'TIMESTAMP TO CHAR';
                l_real_value_tstz := pk_anydata_utils.get_timestamp(l_real_value);
                l_return          := pk_date_utils.to_char_timezone(i_lang, l_real_value_tstz, l_date_type);
            
            ELSE
                pk_alert_exceptions.raise_error(error_name_in => 'Unexpected typename for a date element');
        END CASE;
    
        -- return <date_value>|<date_type>
        l_return := l_return || '|' || l_date_type;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DATE_VALUE_INSTTIMEZONE');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
    END get_date_value_insttimezone;

    /********************************************************************************************
    * Returns available actions info for Action Button" relatated menu 
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
    * @param i_doc_area               Area ID
    * @param i_doc_template           Template ID 
    * @param o_template_actions       Actions info 
    * @param o_error                  Error info
    *
    * @return                         true or false on success or error
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/03/19                                                                                               
    ********************************************************************************************/
    FUNCTION get_template_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_doc_template     IN doc_template.id_doc_template%TYPE,
        o_template_actions OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_template_actions FOR
            SELECT a.id_action,
                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                   da.flg_context,
                   da.flg_type,
                   CAST(MULTISET (SELECT dad.id_group || '|' || dad.id_documentation
                           FROM doc_action_documentation dad
                          WHERE da.id_action = dad.id_action) AS table_varchar) groups_blocks
              FROM doc_template_area dta
             INNER JOIN action a
                ON dta.action_subject = a.subject
             INNER JOIN doc_action da
                ON da.id_action = a.id_action
             WHERE dta.id_doc_template = i_doc_template
               AND dta.id_doc_area = i_doc_area
             ORDER BY a.rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'get_template_actions');
                /* Open out cursors */
                pk_types.open_my_cursor(o_template_actions);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_template_actions;

    /********************************************************************************************
    * Returns last documentation for an area, episode and template(optional)
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param o_last_epis_doc       Last documentation ID 
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Ariel Machado (based on Emilia Taborda code)
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION get_last_doc_area
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_last_doc_area';
    BEGIN
        g_error := 'Call pk_touch_option.get_last_doc_area(with scope)';
        RETURN pk_touch_option_core.get_last_doc_area(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_scope              => i_episode,
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_doc_area           => i_doc_area,
                                                      i_doc_template       => i_doc_template,
                                                      o_last_epis_doc      => o_last_epis_doc,
                                                      o_last_date_epis_doc => o_last_date_epis_doc,
                                                      o_error              => o_error);
    
    EXCEPTION
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

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_doc_area            Area ID where check if registers were done
    * @param i_doc_template        (Optional) Template ID. Null = All templates
    * @param i_table_element_keys  Array of elements keys to retrieve their values
    * @param i_key_type            Type of key (ID, Internal Name, ID Content, etc)
    * @param o_last_epis_doc       Last documentation ID 
    * @param o_last_date_epis_doc  Date of last epis documentation
    * @param o_element_values      Element values
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @value i_key_type  {*} 'K' Element's key (id_doc_element) {*} 'N' Element's internal name 
    *
    * @autor                       Ariel Machado
    * @version                     1.0
    * @since                       2009/03/19
    **********************************************************************************************/
    FUNCTION get_last_doc_area_elem_values
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE DEFAULT NULL,
        i_table_element_keys IN table_varchar,
        i_key_type           IN VARCHAR2,
        o_last_epis_doc      OUT epis_documentation.id_epis_documentation%TYPE,
        o_last_date_epis_doc OUT epis_documentation.dt_creation_tstz%TYPE,
        o_element_values     OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'OPEN C_LAST_EPIS_DOC';
        IF NOT pk_touch_option.get_last_doc_area(i_lang,
                                                 i_prof,
                                                 i_episode,
                                                 i_doc_area,
                                                 i_doc_template,
                                                 o_last_epis_doc,
                                                 o_last_date_epis_doc,
                                                 o_error)
        THEN
            RAISE g_exception;
        END IF;
        IF o_last_epis_doc IS NOT NULL
        THEN
            CASE i_key_type
                WHEN 'K' THEN
                    -- doc_element key
                    OPEN o_element_values FOR
                        SELECT de.id_doc_element,
                               de.internal_name,
                               de.flg_type,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_view) desc_element_view,
                               edd.value,
                               edd.value_properties,
                               pk_touch_option.get_formatted_value(i_lang,
                                                                   i_prof,
                                                                   de.flg_type,
                                                                   edd.value,
                                                                   edd.value_properties,
                                                                   de.input_mask,
                                                                   de.flg_optional_value,
                                                                   de.flg_element_domain_type,
                                                                   de.code_element_domain) formatted_value,
                               de.id_content
                          FROM epis_documentation_det edd
                         INNER JOIN doc_element de
                            ON edd.id_doc_element = de.id_doc_element
                          LEFT JOIN doc_element_crit decr
                            ON edd.id_doc_element_crit = decr.id_doc_element_crit
                         INNER JOIN documentation d
                            ON d.id_documentation = de.id_documentation
                         INNER JOIN doc_component dc
                            ON dc.id_doc_component = d.id_doc_component
                         WHERE edd.id_epis_documentation = o_last_epis_doc
                           AND de.id_doc_element IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                      to_number(t.column_value)
                                                       FROM TABLE(i_table_element_keys) t);
                
                WHEN 'N' THEN
                    -- internal_name key
                    OPEN o_element_values FOR
                        SELECT de.id_doc_element,
                               de.internal_name,
                               de.flg_type,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_view) desc_element_view,
                               edd.value,
                               edd.value_properties,
                               pk_touch_option.get_formatted_value(i_lang,
                                                                   i_prof,
                                                                   de.flg_type,
                                                                   edd.value,
                                                                   edd.value_properties,
                                                                   de.input_mask,
                                                                   de.flg_optional_value,
                                                                   de.flg_element_domain_type,
                                                                   de.code_element_domain) formatted_value,
                               de.id_content
                          FROM epis_documentation_det edd
                         INNER JOIN doc_element de
                            ON edd.id_doc_element = de.id_doc_element
                          LEFT JOIN doc_element_crit decr
                            ON edd.id_doc_element_crit = decr.id_doc_element_crit
                         INNER JOIN documentation d
                            ON d.id_documentation = de.id_documentation
                         INNER JOIN doc_component dc
                            ON dc.id_doc_component = d.id_doc_component
                         WHERE edd.id_epis_documentation = o_last_epis_doc
                           AND de.internal_name IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(i_table_element_keys) t);
                
                WHEN 'C' THEN
                    --  id_content key 
                    OPEN o_element_values FOR
                        SELECT de.id_doc_element,
                               de.internal_name,
                               de.flg_type,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_view) desc_element_view,
                               edd.value,
                               edd.value_properties,
                               pk_touch_option.get_formatted_value(i_lang,
                                                                   i_prof,
                                                                   de.flg_type,
                                                                   edd.value,
                                                                   edd.value_properties,
                                                                   de.input_mask,
                                                                   de.flg_optional_value,
                                                                   de.flg_element_domain_type,
                                                                   de.code_element_domain) formatted_value,
                               de.id_content
                          FROM epis_documentation_det edd
                         INNER JOIN doc_element de
                            ON edd.id_doc_element = de.id_doc_element
                          LEFT JOIN doc_element_crit decr
                            ON edd.id_doc_element_crit = decr.id_doc_element_crit
                         INNER JOIN documentation d
                            ON d.id_documentation = de.id_documentation
                         INNER JOIN doc_component dc
                            ON dc.id_doc_component = d.id_doc_component
                         WHERE edd.id_epis_documentation = o_last_epis_doc
                           AND de.id_content IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                  t.column_value
                                                   FROM TABLE(i_table_element_keys) t);
                
                ELSE
                    g_error := 'I_KEY_TYPE (' || i_key_type || ') NOT SUPPORTED';
                    RAISE g_exception;
                
            END CASE;
        
        ELSE
            pk_types.open_my_cursor(o_element_values);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_LAST_DOC_AREA_ELEM_VALUES');
                /* Open out cursors */
                pk_types.open_my_cursor(o_element_values);
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_last_doc_area_elem_values;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_episode            the documentation episode id
    * @param i_doc_area           the doc_area id
    * @param o_epis_last_template array with the episodes templates    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Teresa Coutinho
    * @version                    1.0   
    * @since                      2009/03/18
    *     
    ********************************************************************************************/
    FUNCTION get_epis_last_templates_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_doc_area            IN table_number,
        o_epis_last_templates OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_EPIS_LAST_TEMPLATES';
        OPEN o_epis_last_templates FOR
            SELECT t.id_epis_documentation,
                   t.id_doc_template,
                   (SELECT pk_translation.get_translation(i_lang, dt.code_doc_template)
                      FROM doc_template dt
                     WHERE dt.id_doc_template = t.id_doc_template) title
              FROM (SELECT ed.id_epis_documentation,
                           ed.id_doc_template,
                           ed.dt_creation_tstz,
                           row_number() over(PARTITION BY ed.id_doc_template ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                     WHERE ed.id_episode = i_episode
                       AND ed.flg_status = g_active
                       AND ed.id_doc_area IN (SELECT /*+ opt_estimate(table x rows=1) */
                                               x.column_value
                                                FROM TABLE(i_doc_area) x)
                    UNION
                    SELECT ed.id_epis_documentation,
                           ed.id_doc_template,
                           ed.dt_creation_tstz,
                           row_number() over(PARTITION BY ed.id_doc_template ORDER BY ed.dt_creation_tstz DESC) rn
                      FROM epis_documentation ed
                     WHERE ed.id_episode_context = i_episode
                       AND ed.flg_status = g_active
                       AND ed.id_doc_area IN (SELECT /*+ opt_estimate(table x rows=1) */
                                               x.column_value
                                                FROM TABLE(i_doc_area) x)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_LAST_TEMPLATE_DOC');
                pk_types.open_my_cursor(o_epis_last_templates);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_epis_document      the documentation episode id
    * @param i_epis_doc_register  array with the detail info register
    * @param o_epis_document_val  array with detail of documentation    
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Emília Taborda
    * @version                    1.0   
    * @since                      2007/06/01
    *
    * Changes:
    *                             Ariel Machado
    *                             1.1 (2.4.3)
    *                             2008/05/26
    *                             For composite element date&hour(timezone) returns data in format expected by the Flash layer 
    ********************************************************************************************/
    FUNCTION get_epis_documentation_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document     IN table_number,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_free_text sys_message.desc_message%TYPE;
    BEGIN
        l_msg_free_text := pk_message.get_message(i_lang, 'PROGRESS_NOTES_M001');
    
        g_error := 'GET CURSOR O_EPIS_DOC_REGISTER';
        OPEN o_epis_doc_register FOR
            SELECT /*+ index(ed epis_documentation(id_epis_documentation)) */
             ed.id_epis_documentation,
             ed.id_doc_template,
             pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_creation,
             pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
             pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
             ed.id_professional,
             pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
             ed.id_doc_area,
             ed.flg_status,
             pk_sysdomain.get_domain(g_domain_epis_doc_flg_status, ed.flg_status, i_lang) desc_status,
             ed.notes,
             decode(ed.id_doc_template,
                    NULL,
                    l_msg_free_text,
                    decode((SELECT pk_translation.get_translation(i_lang, dt.code_doc_template)
                             FROM doc_template dt
                            WHERE dt.id_doc_template = ed.id_doc_template),
                           NULL,
                           (SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section)
                              FROM summary_page_section sps
                             WHERE sps.id_doc_area = ed.id_doc_area
                               AND rownum < 2),
                           (SELECT pk_translation.get_translation(i_lang, dt.code_doc_template)
                              FROM doc_template dt
                             WHERE dt.id_doc_template = ed.id_doc_template))) title,
             decode((SELECT 0
                      FROM epis_documentation_det edd
                     WHERE edd.id_epis_documentation = ed.id_epis_documentation
                       AND rownum < 2),
                    NULL,
                    pk_summary_page.g_free_text,
                    pk_summary_page.g_touch_option) flg_type_register
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(i_epis_document) t)
             ORDER BY dt_last_update_tstz DESC;
        --
        g_error := 'GET CURSOR O_EPIS_DOCUMENT_VAL';
        OPEN o_epis_document_val FOR
            SELECT /*+ index(ed epis_documentation(id_epis_documentation)) */
             ed.id_epis_documentation,
             ed.id_doc_template,
             d.id_documentation,
             d.id_doc_component,
             decr.id_doc_element_crit,
             pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
             pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
             decode(sdv.value,
                    NULL,
                    get_element_description(i_lang,
                                            i_prof,
                                            de.flg_type,
                                            edd.value,
                                            edd.value_properties,
                                            decr.id_doc_element_crit,
                                            de.id_unit_measure_reference,
                                            de.id_master_item,
                                            decr.code_element_close),
                    sdv.value || pk_translation.get_translation(i_lang, s.code_scale_score) || ' - ' ||
                    get_element_description(i_lang,
                                            i_prof,
                                            de.flg_type,
                                            edd.value,
                                            edd.value_properties,
                                            decr.id_doc_element_crit,
                                            de.id_unit_measure_reference,
                                            de.id_master_item,
                                            decr.code_element_close)) desc_element,
             pk_touch_option.get_formatted_value(i_lang,
                                                 i_prof,
                                                 de.flg_type,
                                                 edd.value,
                                                 edd.value_properties,
                                                 de.input_mask,
                                                 de.flg_optional_value,
                                                 de.flg_element_domain_type,
                                                 de.code_element_domain,
                                                 edd.dt_creation_tstz) VALUE,
             ed.id_doc_area,
             dtad.rank rank_component,
             de.rank rank_element,
             pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
             pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
             pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification
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
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
              LEFT JOIN scales_doc_value sdv
                ON de.id_doc_element = sdv.id_doc_element
              LEFT JOIN scales s
                ON sdv.id_scales = s.id_scales
             WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value
                                                  FROM TABLE(i_epis_document) t)
             ORDER BY id_epis_documentation, rank_component, rank_element;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_EPIS_DOCUMENTATION_DET');
                pk_types.open_my_cursor(o_epis_doc_register);
                pk_types.open_my_cursor(o_epis_document_val);
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
    END get_epis_documentation_det;

    /******************************************************************************************
    * Gets the question concatenated with the actual answer for a specific                    *
    * id_epis_documentation and id_doc_component                                              *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_epis_documentation         epis documentation id                               *
    * @param i_doc_component              doc component id                                    *
    * @param i_is_bold                    should component be bold? (DEFAULT YES)             *
    * @param i_has_title                  should component title be shown (DEFAULT YES)       *    
    *                                                                                         *
    * @return                         Returns concatenated string                             *
    *                                                                                         *
    * @author                         Gustavo Serrano                                         *
    * @version                        1.0                                                     *
    * @since                          2009/10/14                                              *
    ******************************************************************************************/
    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_component      IN doc_component.id_doc_component%TYPE,
        i_is_bold            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_output VARCHAR2(32767);
        l_error  t_error_out;
    BEGIN
    
        g_error := 'GET epis_doc_component_desc';
        SELECT decode(i_has_title,
                      'Y',
                      (decode(i_is_bold, 'Y', '<B>', '') || t.desc_component || decode(i_is_bold, 'Y', '</B> ', '')),
                      '') || t.desc_element ||
               decode(i_has_title, 'Y', decode(instr(t.desc_element, '.', length(t.desc_element)), 0, '.', ''), '')
          INTO l_output
          FROM (SELECT DISTINCT dc.id_doc_component,
                                ed.id_episode,
                                pk_translation.get_translation(i_lang, dc.code_doc_component) || ': ' desc_component,
                                pk_utils.concatenate_list(CURSOR
                                                          (SELECT nvl2(edd1.value,
                                                                       nvl2(get_element_description(i_lang,
                                                                                                    i_prof,
                                                                                                    de.flg_type,
                                                                                                    edd1.value,
                                                                                                    edd1.value_properties,
                                                                                                    sec1.id_doc_element_crit,
                                                                                                    de.id_unit_measure_reference,
                                                                                                    de.id_master_item,
                                                                                                    sec1.code_element_close),
                                                                            get_element_description(i_lang,
                                                                                                    i_prof,
                                                                                                    de.flg_type,
                                                                                                    edd1.value,
                                                                                                    edd1.value_properties,
                                                                                                    sec1.id_doc_element_crit,
                                                                                                    de.id_unit_measure_reference,
                                                                                                    de.id_master_item,
                                                                                                    sec1.code_element_close) || ': ',
                                                                            NULL) ||
                                                                       pk_touch_option.get_formatted_value(i_lang,
                                                                                                           i_prof,
                                                                                                           de.flg_type,
                                                                                                           edd1.value,
                                                                                                           edd1.value_properties,
                                                                                                           de.input_mask,
                                                                                                           de.flg_optional_value,
                                                                                                           de.flg_element_domain_type,
                                                                                                           de.code_element_domain,
                                                                                                           edd.dt_creation_tstz),
                                                                       get_element_description(i_lang,
                                                                                               i_prof,
                                                                                               de.flg_type,
                                                                                               edd1.value,
                                                                                               edd1.value_properties,
                                                                                               sec1.id_doc_element_crit,
                                                                                               de.id_unit_measure_reference,
                                                                                               de.id_master_item,
                                                                                               sec1.code_element_close)) ||
                                                                  pk_summary_page.get_epis_doc_qualif(i_lang,
                                                                                                      edd1.id_epis_documentation_det) desc_qualification
                                                             FROM epis_documentation     ed1,
                                                                  epis_documentation_det edd1,
                                                                  documentation          sd1,
                                                                  doc_element_crit       sec1,
                                                                  doc_element            de
                                                            WHERE ed1.id_epis_documentation = edd1.id_epis_documentation
                                                              AND edd1.id_epis_documentation = edd.id_epis_documentation
                                                              AND sd1.id_documentation = edd1.id_documentation
                                                              AND edd1.id_doc_element_crit = sec1.id_doc_element_crit
                                                              AND sd1.id_doc_component = dc.id_doc_component
                                                              AND de.id_doc_element = edd1.id_doc_element
                                                            ORDER BY ed1.dt_creation_tstz DESC, sd1.rank, de.rank),
                                                          ', ') desc_element,
                                sd.rank
                  FROM epis_documentation ed
                 INNER JOIN epis_documentation_det edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                 INNER JOIN documentation sd
                    ON sd.id_documentation = edd.id_documentation
                 INNER JOIN doc_component dc
                    ON dc.id_doc_component = sd.id_doc_component
                 WHERE edd.id_epis_documentation = i_epis_documentation
                   AND dc.id_doc_component = i_doc_component) t;
    
        RETURN l_output;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_DOC_COMPONENT_DESC',
                                              l_error);
            RETURN NULL;
    END get_epis_doc_component_desc;

    /********************************************************************************************
    * Updates the list of complaint's templates to be used by episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param i_episode                   Episode ID
    * @param i_epis_complaint            Epis_Complaint ID (default NULL)
    * @param i_do_commit                 Transaction Commit? (default YES)
    * @param o_error                     Error message
                     
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION update_epis_tmplt_by_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_complaint IN epis_complaint.id_epis_complaint%TYPE DEFAULT NULL,
        i_do_commit      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        function_call_excep          EXCEPTION;
        l_gender                     patient.gender%TYPE;
        l_age                        patient.age%TYPE;
        l_subject                    sys_config.value%TYPE;
        l_templates                  pk_types.cursor_type;
        l_tab_epis_doc_template      table_number;
        l_tab_epis_doc_template_remv table_number;
        l_tab_templates_aux          table_number;
        l_tab_templates_set          table_number;
        l_tab_templates_set_name     table_varchar;
        l_tab_areas                  table_number;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'get_pat_info_by_episode';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang, i_episode, l_gender, l_age)
        THEN
            RAISE function_call_excep;
        END IF;
    
        --Get available complaint's templates (ignoring the profile in order to retrieves templates for all possible profiles)
        g_error := 'get_doc_template_by_complaint';
        IF NOT get_doc_template_by_complaint(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_episode           => i_episode,
                                             i_gender            => l_gender,
                                             i_age               => l_age,
                                             i_doc_area_flg_type => g_flg_type_complaint,
                                             i_ignore_profile    => pk_alert_constant.g_yes,
                                             o_templates         => l_templates,
                                             o_error             => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        IF l_templates IS NOT NULL
        THEN
            g_error := 'FETCH COMPLAINT TEMPLATES';
            FETCH l_templates BULK COLLECT
                INTO l_tab_templates_set, l_tab_templates_set_name;
            CLOSE l_templates;
        
            --Current selected templates for this episode (in order to be removed)
        
            g_error := 'Retrieving a list of areas that are configured to use templates per episode and by Complaint';
            SELECT da.id_doc_area
              BULK COLLECT
              INTO l_tab_areas
              FROM doc_area da
              JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, i_prof.software)) dais
                ON da.id_doc_area = dais.id_doc_area
             WHERE dais.flg_multiple = pk_alert_constant.g_yes
               AND dais.flg_type = g_flg_type_complaint;
        
            --Cancels active templates for the area to avoid duplication.
            g_error := 'Cancels previous touch option templates associated with the episode';
            UPDATE epis_doc_template edt
               SET edt.dt_cancel = g_sysdate_tstz, edt.id_prof_cancel = i_prof.id
             WHERE edt.id_episode = i_episode
               AND edt.id_prof_cancel IS NULL
               AND (edt.id_doc_area IS NULL OR
                   edt.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(l_tab_areas) t));
        
            g_error := 'INSERT TEMPLATES';
            FORALL x IN 1 .. l_tab_templates_set.count
                INSERT INTO epis_doc_template
                    (id_epis_doc_template,
                     dt_register,
                     id_prof_register,
                     id_episode,
                     id_epis_complaint,
                     id_doc_template,
                     id_profile_template,
                     id_doc_area)
                VALUES
                    (seq_epis_doc_template.nextval,
                     g_sysdate_tstz,
                     i_prof.id,
                     i_episode,
                     i_epis_complaint,
                     l_tab_templates_set(x),
                     NULL,
                     NULL);
        
        END IF;
    
        g_error := 'Retrieving a list of areas that are configured to use templates per episode and by Area + Complaint';
        SELECT da.id_doc_area
          BULK COLLECT
          INTO l_tab_areas
          FROM doc_area da
          JOIN TABLE(pk_touch_option.tf_doc_area_inst_soft(da.id_doc_area, i_prof.institution, i_prof.software)) dais
            ON da.id_doc_area = dais.id_doc_area
         WHERE dais.flg_multiple = pk_alert_constant.g_yes
           AND dais.flg_type = g_flg_type_doc_area_complaint;
    
        g_error := 'Set templates by area + complaint';
        FOR i IN 1 .. l_tab_areas.count()
        LOOP
            g_error := 'get_doc_template_by_area_cplnt for area: ' || to_char(l_tab_areas(i));
            IF NOT get_doc_template_by_area_cplnt(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_episode        => i_episode,
                                                  i_doc_area       => l_tab_areas(i),
                                                  i_gender         => l_gender,
                                                  i_age            => l_age,
                                                  i_ignore_profile => pk_alert_constant.g_yes,
                                                  o_templates      => l_templates,
                                                  o_error          => o_error)
            THEN
                RAISE function_call_excep;
            END IF;
        
            IF l_templates IS NOT NULL
            THEN
                g_error := 'FETCH DEFAULT TEMPLATES';
                FETCH l_templates BULK COLLECT
                    INTO l_tab_templates_set, l_tab_templates_set_name;
                CLOSE l_templates;
            
                -- For physical exam area we need to filter templates that are applicable to current E/M Guideline in use (USA)
                IF l_tab_areas(i) = pk_summary_page.g_doc_area_phy_exam
                THEN
                    g_error := 'Retrieve E/M Documentation guideline';
                    IF NOT get_doc_guideline(i_lang => i_lang, i_prof => i_prof, o_subject => l_subject)
                    THEN
                        l_subject := NULL;
                    END IF;
                
                    IF l_subject IS NOT NULL
                    THEN
                        -- If one E/M Documentation Guideline is enabled, then filters the templates only those that apply to it
                        SELECT DISTINCT dts.id_doc_template
                          BULK COLLECT
                          INTO l_tab_templates_aux
                          FROM doc_system ds
                         INNER JOIN doc_template_system dts
                            ON ds.id_doc_system = dts.id_doc_system
                         INNER JOIN TABLE(l_tab_templates_set) dt
                            ON dt.column_value = dts.id_doc_template
                         WHERE ds.subject = l_subject;
                        l_tab_templates_set := l_tab_templates_aux;
                    END IF;
                END IF;
            
                --Cancels active templates for the area to avoid duplication.
                g_error := 'Cancels previous touch option templates associated with the episode';
                UPDATE epis_doc_template edt
                   SET edt.dt_cancel = g_sysdate_tstz, edt.id_prof_cancel = i_prof.id
                 WHERE edt.id_episode = i_episode
                   AND edt.id_doc_area = l_tab_areas(i)
                   AND edt.id_prof_cancel IS NULL;
            
                g_error := 'INSERT TEMPLATES';
                FORALL x IN 1 .. l_tab_templates_set.count
                    INSERT INTO epis_doc_template
                        (id_epis_doc_template,
                         dt_register,
                         id_prof_register,
                         id_episode,
                         id_epis_complaint,
                         id_doc_template,
                         id_profile_template,
                         id_doc_area)
                    VALUES
                        (seq_epis_doc_template.nextval,
                         g_sysdate_tstz,
                         i_prof.id,
                         i_episode,
                         i_epis_complaint,
                         l_tab_templates_set(x),
                         NULL,
                         l_tab_areas(i));
            END IF;
        
        END LOOP;
    
        IF i_do_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN function_call_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                l_error_in.set_all(i_lang, '', '', g_error, g_package_owner, g_package_name, '');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, '');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END update_epis_tmplt_by_complaint;

    /**
    * Get a full phrase associated to an element quantified
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  Full phrase associated with the element quantified (example: "Mild pain")
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_quantification
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
    BEGIN
        -- We need to create a new field instead of reusing CODE_DOC_ELEM_QUALIF_CLOSE for compatibility reasons 
        -- to deal with old templates that have in this field the quantifier only (example: "mild") 
        -- and new templates that will use a phrase for the element quantified (example: "Mild pain")
        BEGIN
            SELECT pk_translation.get_translation(i_lang, deq.code_doc_element_quantif_close) desc_quantification
              INTO l_result
              FROM epis_documentation_qualif edq
             INNER JOIN doc_element_qualif deq
                ON deq.id_doc_element_qualif = edq.id_doc_element_qualif
             WHERE edq.id_epis_documentation_det = i_epis_document_det
               AND deq.id_doc_quantification IS NOT NULL
               AND deq.id_doc_qualification IS NULL
               AND deq.code_doc_element_quantif_close IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_result := NULL;
        END;
    
        RETURN TRIM(TRIM(trailing chr(10) FROM l_result));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'get_epis_doc_quantification',
                                                  o_error    => l_error);
            END;
            RETURN NULL;
    END get_epis_doc_quantification;

    /**
    * Gets a concatenated list of qualifications associated with an element in parentheses
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  String with concatenated list of qualifications
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_qualification
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
        l_qualif VARCHAR2(32767);
    BEGIN
        SELECT desc_qualif
          INTO l_qualif
          FROM (SELECT pk_utils.concatenate_list(CURSOR (SELECT TRIM(TRIM(trailing chr(10) FROM
                                                                   pk_translation.get_translation(i_lang,
                                                                                                  deq.code_doc_elem_qualif_close)))
                                                    FROM epis_documentation_qualif edq
                                                   INNER JOIN doc_element_qualif deq
                                                      ON deq.id_doc_element_qualif = edq.id_doc_element_qualif
                                                   WHERE edq.id_epis_documentation_det = i_epis_document_det
                                                     AND deq.id_doc_qualification IS NOT NULL),
                                                 '; ') desc_qualif
                  FROM dual) qll;
        IF l_qualif IS NOT NULL
        THEN
            l_result := ' (' || l_qualif || ')';
        ELSE
            l_result := l_qualif;
        END IF;
        RETURN l_result;
    END get_epis_doc_qualification;

    /**
    * Get the quantifier description associated to an element quantified
    *
    * This function is used for compatibility purposes to deal with old descriptions for element's quantifier in templates.
    * In new template's elements that make use of quantifiers this function should return null values, 
    * and the new function get_epis_doc_quantification() return the full description for an element quantified.
    *
    * @param   i_lang         Professional preferred language
    * i_epis_document_det     Documentation detail ID
    *
    * @return  Description associated with the quantifier (example: "mild")
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_epis_doc_quantifier
    (
        i_lang              IN language.id_language%TYPE,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, deq.code_doc_elem_qualif_close) desc_quantifier
              INTO l_result
              FROM epis_documentation_qualif edq
             INNER JOIN doc_element_qualif deq
                ON deq.id_doc_element_qualif = edq.id_doc_element_qualif
             WHERE edq.id_epis_documentation_det = i_epis_document_det
               AND deq.id_doc_quantification IS NOT NULL
               AND deq.id_doc_qualification IS NULL
               AND deq.code_doc_elem_qualif_close IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_result := NULL;
        END;
    
        RETURN TRIM(TRIM(trailing chr(10) FROM l_result));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'get_epis_doc_quantifier',
                                                  o_error    => l_error);
            END;
            RETURN NULL;
    END get_epis_doc_quantifier;

    /**
    * Get adjective placement rule for input language. 
    * This flag is used to identify the rule that is applied in this language for adjective placement before/after the noun. 
    * Used for compatibility purposes in Touch-option templates in order to define the position of element's quantification. 
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   o_flg_placement Adjective placement rule
    * @param   o_error         Error information
    *
    * @value   o_flg_placement {*} 'B' Quantification is placed before the element {*} 'A' Quantification is placed after the element
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/11/2010
    */
    FUNCTION get_quantif_placement
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_flg_placement OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_quantif_placement';
    BEGIN
    
        g_error := 'Get FLG_QUANTIF_PLACEMENT for language ID:' || i_lang;
        SELECT l.flg_quantif_placement
          INTO o_flg_placement
          FROM LANGUAGE l
         WHERE l.id_language = i_lang;
    
        IF o_flg_placement IS NULL
        THEN
            --No rule defined for this language, then using a arbitrary default rule: quantifier come after the noun.
            o_flg_placement := 'A';
            g_error         := 'The id_language = ' || i_lang ||
                               ' does not have an adjective placement rule defined in table LANGUAGE.FLG_QUANTIF_PLACEMENT. Using as default rule: ' ||
                               o_flg_placement;
            pk_alertlog.log_warn(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_quantif_placement;

    /**
    * Returns a formatted string representing the description of a template's element recorded (description, quantifier, qualifier, value, etc).
    *
    * This function is intended to be used where is necessary to have in an unique string the description 
    * of an element without formatting or special treatments that commonly are used in Flash layer to build the phrase.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_document_det  Documentation detail ID
    * @param   i_use_html_format    Use HTML tags to format output. Default: No
    *
    * @value   i_use_html_format    {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags    
    *
    * @return  A formatted string representing the description of the element with quantifier, qualifiers, value, etc.
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   10/12/2010
    */
    FUNCTION get_epis_formatted_element
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_document_det IN epis_documentation_det.id_epis_documentation_det%TYPE,
        i_use_html_format   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        co_function_name          CONSTANT VARCHAR2(30) := 'get_epis_formatted_element';
        co_default_display_format CONSTANT doc_element.display_format%TYPE := '<DESCRIPTION>: <VALUE>';
        co_msk_tag_description    CONSTANT VARCHAR2(30 CHAR) := '<DESCRIPTION>';
        co_msk_tag_value          CONSTANT VARCHAR2(30 CHAR) := '<VALUE>';
        function_call_excep     EXCEPTION;
        l_error                 t_error_out;
        l_flg_quantif_placement language.flg_quantif_placement%TYPE;
        l_value                 VARCHAR2(32767);
        l_desc_element          VARCHAR2(32767);
        l_desc_quantifier       VARCHAR2(32767);
        l_desc_quantification   VARCHAR2(32767);
        l_desc_qualification    VARCHAR2(32767);
        l_formatted_element     VARCHAR2(32767);
        l_display_format        doc_element.display_format%TYPE;
        l_flg_type              doc_element.flg_type%TYPE;
    
        l_description VARCHAR2(32767);
    
    BEGIN
    
        g_error := 'Get formatted value';
        SELECT get_formatted_value(i_lang,
                                   i_prof,
                                   de.flg_type,
                                   edd.value,
                                   edd.value_properties,
                                   de.input_mask,
                                   de.flg_optional_value,
                                   de.flg_element_domain_type,
                                   de.code_element_domain,
                                   edd.dt_creation_tstz) VALUE,
               get_element_description(i_lang,
                                       i_prof,
                                       de.flg_type,
                                       edd.value,
                                       edd.value_properties,
                                       decr.id_doc_element_crit,
                                       de.id_unit_measure_reference,
                                       de.id_master_item,
                                       decr.code_element_close) desc_element,
               get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
               get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
               get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
               de.display_format,
               de.flg_type
          INTO l_value,
               l_desc_element,
               l_desc_quantifier,
               l_desc_quantification,
               l_desc_qualification,
               l_display_format,
               l_flg_type
          FROM epis_documentation_det edd
         INNER JOIN doc_element de
            ON de.id_doc_element = edd.id_doc_element
         INNER JOIN doc_element_crit decr
            ON decr.id_doc_element_crit = edd.id_doc_element_crit
         WHERE edd.id_epis_documentation_det = i_epis_document_det;
    
        l_value               := TRIM(l_value);
        l_desc_element        := TRIM(l_desc_element);
        l_desc_quantifier     := TRIM(l_desc_quantifier);
        l_desc_quantification := TRIM(l_desc_quantification);
        l_desc_qualification  := TRIM(l_desc_qualification);
    
        IF i_use_html_format = pk_alert_constant.g_yes
        THEN
            l_value               := htf.escape_sc(l_value);
            l_desc_element        := htf.escape_sc(l_desc_element);
            l_desc_quantifier     := htf.escape_sc(l_desc_quantifier);
            l_desc_quantification := htf.escape_sc(l_desc_quantification);
            l_desc_qualification  := htf.escape_sc(l_desc_qualification);
        
            IF l_value IS NOT NULL
               AND l_flg_type IN (pk_touch_option.g_elem_flg_type_comp_text,
                                  pk_touch_option.g_elem_flg_type_text,
                                  pk_touch_option.g_elem_flg_type_text_other)
            THEN
                l_value := htf.italic(l_value);
            END IF;
        END IF;
    
        IF l_desc_quantification IS NOT NULL
        
        THEN
            --An element with fully quantified description
            l_description := l_desc_quantification;
        ELSIF l_desc_quantifier IS NOT NULL
        THEN
            --An element with quantifier description
            g_error := 'get_quantif_placement';
            IF NOT pk_touch_option.get_quantif_placement(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         o_flg_placement => l_flg_quantif_placement,
                                                         o_error         => l_error)
            THEN
                RAISE function_call_excep;
            END IF;
        
            g_error := 'Applying adjective placement rule';
            CASE l_flg_quantif_placement
                WHEN 'A' THEN
                    l_description := pk_string_utils.concat_if_exists(l_desc_element, l_desc_quantifier, ' ');
                WHEN 'B' THEN
                    l_description := pk_string_utils.concat_if_exists(l_desc_quantifier, l_desc_element, ' ');
            END CASE;
            --Uppercase first char to evit "Moderate Pain"
            l_description := upper(substr(l_description, 1, 1)) || substr(l_description, 2);
        
        ELSE
            --An element without quantification
            l_description := l_desc_element;
        END IF;
    
        IF l_desc_qualification IS NOT NULL
        THEN
            --Has qualifications
            l_description := pk_string_utils.concat_if_exists(l_description, l_desc_qualification, ' ');
        END IF;
    
        IF l_display_format IS NULL
        THEN
        
            IF l_value IS NULL
            THEN
                --Has no value
                l_formatted_element := l_description;
            
            ELSE
                --Has value
                l_formatted_element := pk_string_utils.concat_if_exists(l_description, l_value, ': ');
            END IF;
        
        ELSE
            l_formatted_element := REPLACE(l_display_format, co_msk_tag_description, l_description);
            l_formatted_element := REPLACE(l_formatted_element, co_msk_tag_value, l_value);
        END IF;
    
        RETURN l_formatted_element;
    
    EXCEPTION
        WHEN function_call_excep THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                g_error := 'The call to function ' || g_error || ' returned an error ';
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   'Error calling internal function',
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   co_function_name);
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error);
                RETURN NULL;
            
            END;
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
    END get_epis_formatted_element;

    /**
    * Retrieves variables to be applied in queries using scope orientation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_scope        Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type   Scope type (by episode; by visit; by patient)
    * @param   o_patient      Patient ID
    * @param   o_visit        Visit ID
    * @param   o_episode      Episode ID
    * @param   o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.2
    * @since   11/5/2010
    */
    FUNCTION get_scope_vars
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR,
        o_patient    OUT patient.id_patient%TYPE,
        o_visit      OUT visit.id_visit%TYPE,
        o_episode    OUT episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_scope_vars';
        e_invalid_scope_type EXCEPTION;
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_patient THEN
                o_patient := i_scope;
                o_visit   := NULL;
                o_episode := NULL;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                o_visit := i_scope;
                SELECT v.id_patient
                  INTO o_patient
                  FROM visit v
                 WHERE v.id_visit = i_scope;
                o_episode := NULL;
            
            WHEN pk_alert_constant.g_scope_type_episode THEN
                o_episode := i_scope;
                SELECT e.id_visit, e.id_patient
                  INTO o_visit, o_patient
                  FROM episode e
                 WHERE e.id_episode = i_scope;
                o_visit := NULL;
            ELSE
                RAISE e_invalid_scope_type;
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN e_invalid_scope_type THEN
            DECLARE
                l_error_message VARCHAR2(4000 CHAR);
            BEGIN
                l_error_message := 'The i_scope_type parameter has an unexpected value for scope type';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => l_error_message,
                                                  i_message  => l_error_message,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_function_name,
                                                  o_error    => o_error);
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_scope_vars;

    /**
    * Retrieves variables to be applied in queries using scope orientation
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_scope        Scope ID (Episode IDs; Visit IDs; Patient IDs)
    * @param   i_scope_type   Scope type (by episode; by visit; by patient)
    * @param   o_patient      Patient IDs
    * @param   o_visit        Visit IDs
    * @param   o_episode      Episode IDs
    * @param   o_error        Error information
    *
    * @value i_scope_type {*} g_scope_type_patient (P) {*} g_scope_type_visit (V) {*} g_scope_type_episode (E)
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes (based on ARIEL.MACHADO code)
    * @version 2.5
    * @since   21/03/2013
    */
    FUNCTION get_scope_vars_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN table_number,
        i_scope_type IN VARCHAR,
        o_patient    OUT table_number,
        o_visit      OUT table_number,
        o_episode    OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_scope_vars_list';
        e_invalid_scope_type EXCEPTION;
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_patient THEN
                o_patient := i_scope;
                o_visit   := NULL;
                o_episode := NULL;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                o_visit := i_scope;
                SELECT v.id_patient
                  BULK COLLECT
                  INTO o_patient
                  FROM visit v
                 WHERE v.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(i_scope) t);
                o_episode := NULL;
            
            WHEN pk_alert_constant.g_scope_type_episode THEN
                o_episode := i_scope;
                SELECT DISTINCT e.id_patient
                  BULK COLLECT
                  INTO o_patient
                  FROM episode e
                 WHERE e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                         t.column_value
                                          FROM TABLE(i_scope) t);
                o_visit := NULL;
            
            ELSE
                RAISE e_invalid_scope_type;
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN e_invalid_scope_type THEN
            DECLARE
                l_error_message VARCHAR2(4000 CHAR);
            BEGIN
                l_error_message := 'The i_scope_type parameter has an unexpected value for scope type';
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => l_error_message,
                                                  i_message  => l_error_message,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_function_name,
                                                  o_error    => o_error);
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_scope_vars_list;

    /**
    * Returns a set of IDs records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_coll_epis_doc      Table number with id_epis_documentation        
    * @param   o_coll_epis_anamn    Table number with id_epis_anamnesis        
    * @param   o_coll_epis_rev_sys  Table number with id_epis_review_systems        
    * @param   o_coll_epis_obs      Table number with id_epis_observation        
    * @param   o_coll_epis_past_fsh Table number with id_pat_fam_soc_hist        
    * @param   o_coll_epis_recomend Table number with id_epis_recomend 
    * @param   o_error              Error message 
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.1
    * @since   15/05/2012
    */
    FUNCTION get_doc_area_value_ids
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN table_number,
        i_scope              IN table_number,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_fltr_status        IN VARCHAR2 DEFAULT 'AOC',
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_record_count       OUT NUMBER,
        o_coll_epis_doc      OUT NOCOPY table_number,
        o_coll_epis_anamn    OUT NOCOPY table_number,
        o_coll_epis_rev_sys  OUT NOCOPY table_number,
        o_coll_epis_obs      OUT NOCOPY table_number,
        o_coll_epis_past_fsh OUT NOCOPY table_number,
        o_coll_epis_recomend OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_rec_doc_entry IS RECORD(
            table_origin VARCHAR2(1 CHAR),
            record_key   NUMBER(24));
        TYPE t_coll_doc_entry IS TABLE OF t_rec_doc_entry;
    
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value_ids';
    
        l_start_record   NUMBER(24);
        l_end_record     NUMBER(24);
        l_episode        table_number;
        l_visit          table_number;
        l_patient        table_number;
        l_coll_doc_entry t_coll_doc_entry;
    BEGIN
    
        g_error := 'LOGGING INPUT ARGUMENTS';
        pk_alertlog.log_debug(sub_object_name => l_function_name,
                              text            => 'i_lang: ' || i_lang || ' institution:' || i_prof.institution ||
                                                 ' software:' || i_prof.software || ' i_doc_area: ' ||
                                                -- to_char(i_doc_area) || --' i_scope: ' || to_char(i_scope) ||
                                                 ' i_scope_type: ' || i_scope_type || ' i_fltr_status:' || i_fltr_status ||
                                                 ' i_order:' || i_order || ' i_fltr_start_date:' ||
                                                 to_char(i_fltr_start_date) || ' i_fltr_end_date:' ||
                                                 to_char(i_fltr_end_date) || ' i_paging:' || i_paging ||
                                                 ' i_start_record:' || to_char(i_start_record) || ' i_num_records:' ||
                                                 to_char(i_num_records));
    
        g_error := 'ANALYSING INPUT ARGUMENTS';
        IF i_doc_area IS empty
           OR i_scope IS NULL
           OR i_scope_type IS NULL
           OR i_fltr_status IS NULL
           OR i_order IS NULL
           OR i_paging IS NULL
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE. get_scope_vars_list';
        IF NOT pk_touch_option.get_scope_vars_list(i_lang       => i_lang,
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
    
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_episode THEN
                --By Episode          
                SELECT table_origin, record_key
                  BULK COLLECT
                  INTO l_coll_doc_entry
                  FROM (
                        --Entries done in Touch-option model (by episode)
                        SELECT g_flg_tab_origin_epis_doc table_origin,
                                ed.id_epis_documentation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ed.dt_last_update_tstz) order_by_default
                          FROM epis_documentation ed
                         WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table d rows=1)*/
                                                   d.column_value id_doc_area
                                                    FROM TABLE(i_doc_area) d)
                           AND ed.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                  t.column_value id_episode
                                                   FROM TABLE(l_episode) t)
                           AND instr(i_fltr_status, ed.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ed.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ed.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        --Entries done in Touch-option model (by episode_context)
                        SELECT g_flg_tab_origin_epis_doc table_origin,
                                ed.id_epis_documentation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ed.dt_last_update_tstz) order_by_default
                          FROM epis_documentation ed
                         WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table d rows=1)*/
                                                   d.column_value id_doc_area
                                                    FROM TABLE(i_doc_area) d)
                           AND ed.id_episode_context IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                          t.column_value id_episode
                                                           FROM TABLE(l_episode) t)
                           AND ed.id_episode_context != ed.id_episode -- ignore rows already returned in the previous query (filter by episode)
                           AND instr(i_fltr_status, ed.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ed.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ed.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free-text entries for Complaint area that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_complaint IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free-text entries for HPI area that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free-text entries for Review of System area that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_rev_sys table_origin,
                                ers.id_epis_review_systems record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ers.dt_creation_tstz) order_by_default
                          FROM epis_review_systems ers
                         INNER JOIN episode e
                            ON ers.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_rev_sys IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND instr(i_fltr_status, ers.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ers.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ers.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Physical Exam areas that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_obs table_origin,
                                eo.id_epis_observation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - eo.dt_epis_observation_tstz) order_by_default
                          FROM epis_observation eo
                         INNER JOIN episode e
                            ON eo.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND instr(i_fltr_status, eo.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND eo.dt_epis_observation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND eo.dt_epis_observation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_fam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_fam
                              
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_soc IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_soc
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Subjective (HPI) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Objective (PE) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                        UNION ALL
                        -- Free text entries for Nursing Notes(EDIS/PP/OUTP/CARE/ORIS) 
                        -- that were done out of Touch-option model (Old free-text entries) (by episode)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_nursing_notes IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = 'N'
                           AND EXISTS (SELECT 1
                                  FROM notes_config ncfg
                                 WHERE ncfg.id_notes_config = er.id_notes_config
                                   AND ncfg.notes_code NOT IN
                                       (pk_clinical_notes.g_begin_session, pk_clinical_notes.g_end_session))
                           AND e.id_episode IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_episode
                                                  FROM TABLE(l_episode) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND
                               er.dt_epis_recomend_tstz >= i_fltr_start_date) OR i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_episode
                         ORDER BY order_by_default);
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                --By Visit             
                SELECT table_origin, record_key
                  BULK COLLECT
                  INTO l_coll_doc_entry
                  FROM (
                        --Entries done in Touch-option model (by visit)
                        SELECT g_flg_tab_origin_epis_doc table_origin,
                                ed.id_epis_documentation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ed.dt_last_update_tstz) order_by_default
                          FROM epis_documentation ed
                         INNER JOIN episode e
                            ON ed.id_episode = e.id_episode
                         WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table d rows=1)*/
                                                   d.column_value id_doc_area
                                                    FROM TABLE(i_doc_area) d)
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND instr(i_fltr_status, ed.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ed.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ed.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free-text entries for Complaint area that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_complaint IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free-text entries for HPI area that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free-text entries for Review of System area that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_rev_sys table_origin,
                                ers.id_epis_review_systems record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ers.dt_creation_tstz) order_by_default
                          FROM epis_review_systems ers
                         INNER JOIN episode e
                            ON ers.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_rev_sys IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND instr(i_fltr_status, ers.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ers.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ers.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Physical Exam areas that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_obs table_origin,
                                eo.id_epis_observation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - eo.dt_epis_observation_tstz) order_by_default
                          FROM epis_observation eo
                         INNER JOIN episode e
                            ON eo.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND instr(i_fltr_status, eo.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND eo.dt_epis_observation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND eo.dt_epis_observation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_fam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_fam
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_soc IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_soc
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Subjective (HPI) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Objective (PE) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                        UNION ALL
                        -- Free text entries for Nursing Notes(EDIS/PP/OUTP/CARE/ORIS) 
                        -- that were done out of Touch-option model (Old free-text entries) (by visit)
                        SELECT g_flg_tab_origin_epis_recomend table_origin,
                                er.id_epis_recomend record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_nursing_notes IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = 'N'
                           AND EXISTS (SELECT 1
                                  FROM notes_config ncfg
                                 WHERE ncfg.id_notes_config = er.id_notes_config
                                   AND ncfg.notes_code NOT IN
                                       (pk_clinical_notes.g_begin_session, pk_clinical_notes.g_end_session))
                           AND e.id_visit IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               t.column_value id_visit
                                                FROM TABLE(l_visit) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND
                               er.dt_epis_recomend_tstz >= i_fltr_start_date) OR i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_visit
                         ORDER BY order_by_default);
            
            WHEN pk_alert_constant.g_scope_type_patient THEN
                --By Patient              
                SELECT table_origin, record_key
                  BULK COLLECT
                  INTO l_coll_doc_entry
                  FROM (
                        --Entries done in Touch-option model (by patient)
                        SELECT /* opt_estimate(table t rows=1)*/
                         g_flg_tab_origin_epis_doc table_origin,
                          ed.id_epis_documentation record_key,
                          decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ed.dt_last_update_tstz) order_by_default
                          FROM epis_documentation ed
                         INNER JOIN episode e
                            ON ed.id_episode = e.id_episode
                         INNER JOIN TABLE(l_patient) t
                            ON t.column_value = e.id_patient
                         WHERE ed.id_doc_area IN (SELECT /*+ opt_estimate(table d rows=1)*/
                                                   d.column_value id_doc_area
                                                    FROM TABLE(i_doc_area) d)
                           AND instr(i_fltr_status, ed.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ed.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ed.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free-text entries for Complaint area that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_complaint IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_c
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free-text entries for HPI area that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_anamn table_origin,
                                ea.id_epis_anamnesis record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default
                          FROM epis_anamnesis ea
                         INNER JOIN episode e
                            ON ea.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND ea.flg_type = pk_summary_page.g_epis_anam_flg_type_a
                           AND instr(i_fltr_status, ea.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ea.dt_epis_anamnesis_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free-text entries for Review of System area that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_rev_sys table_origin,
                                ers.id_epis_review_systems record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ers.dt_creation_tstz) order_by_default
                          FROM epis_review_systems ers
                         INNER JOIN episode e
                            ON ers.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_rev_sys IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND instr(i_fltr_status, ers.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND ers.dt_creation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND ers.dt_creation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Physical Exam areas that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_obs table_origin,
                                eo.id_epis_observation record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - eo.dt_epis_observation_tstz) order_by_default
                          FROM epis_observation eo
                         INNER JOIN episode e
                            ON eo.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=5)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND eo.flg_type = pk_summary_page.g_epis_obs_flg_type_e
                           AND instr(i_fltr_status, eo.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND eo.dt_epis_observation_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND eo.dt_epis_observation_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_fam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_fam
                              
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Past familiar and Social history areas that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT g_flg_tab_origin_epis_past_fsh table_origin,
                                pfsh.id_pat_fam_soc_hist record_key,
                                decode(i_order, 'DESC', 1, 'ASC', -1, 1) *
                                (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default
                          FROM pat_fam_soc_hist pfsh
                         INNER JOIN episode e
                            ON e.id_episode = pfsh.id_episode
                         WHERE pk_summary_page.g_doc_area_past_soc IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND pfsh.flg_type = pk_summary_page.g_alert_diag_type_soc
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND instr(i_fltr_status, pfsh.flg_status) > 0
                           AND ((i_fltr_start_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND pfsh.dt_pat_fam_soc_hist_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Subjective (HPI) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT /*+ index(er ernd_epis_type_temp_dt_idx)*/
                         g_flg_tab_origin_epis_recomend table_origin,
                          er.id_epis_recomend record_key,
                          decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_hist_ill IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_subjective
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Objective (PE) from Progress Notes(SOAP)
                        -- that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT /*+ index(er ernd_epis_type_temp_dt_idx)*/
                         g_flg_tab_origin_epis_recomend table_origin,
                          er.id_epis_recomend record_key,
                          decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_phy_exam IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = pk_progress_notes.g_type_objective
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND er.dt_epis_recomend_tstz >= i_fltr_start_date) OR
                               i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                        UNION ALL
                        -- Free text entries for Nursing Notes(EDIS/PP/OUTP/CARE/ORIS) 
                        -- that were done out of Touch-option model (Old free-text entries) (by patient)
                        SELECT /*+ index(er ernd_epis_type_temp_dt_idx)*/
                         g_flg_tab_origin_epis_recomend table_origin,
                          er.id_epis_recomend record_key,
                          decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default
                          FROM epis_recomend er
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                         WHERE pk_summary_page.g_doc_area_nursing_notes IN
                               (SELECT /*+ opt_estimate(table d rows=1)*/
                                 d.column_value id_doc_area
                                  FROM TABLE(i_doc_area) d)
                           AND er.flg_type = 'N'
                           AND EXISTS (SELECT 1
                                  FROM notes_config ncfg
                                 WHERE ncfg.id_notes_config = er.id_notes_config
                                   AND ncfg.notes_code NOT IN
                                       (pk_clinical_notes.g_begin_session, pk_clinical_notes.g_end_session))
                           AND e.id_patient IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                 t.column_value id_patient
                                                  FROM TABLE(l_patient) t)
                           AND (instr(i_fltr_status, er.flg_status) > 0 OR er.flg_status IS NULL)
                           AND ((i_fltr_start_date IS NOT NULL AND
                               er.dt_epis_recomend_tstz >= i_fltr_start_date) OR i_fltr_start_date IS NULL)
                           AND ((i_fltr_end_date IS NOT NULL AND er.dt_epis_recomend_tstz <= i_fltr_end_date) OR
                               i_fltr_end_date IS NULL)
                           AND instr(i_fltr_status,
                                     decode(er.flg_temp,
                                            pk_summary_page.g_flg_temp_h,
                                            pk_alert_constant.g_outdated,
                                            pk_alert_constant.g_active)) > 0
                           AND i_scope_type = pk_alert_constant.g_scope_type_patient
                         ORDER BY order_by_default);
            ELSE
                RAISE e_invalid_argument;
        END CASE;
    
        o_record_count := l_coll_doc_entry.count;
    
        IF i_paging = 'N'
        THEN
            -- Returns all the resultset
            l_start_record := 1;
            l_end_record   := l_coll_doc_entry.count;
        ELSE
            l_start_record := i_start_record;
            l_end_record   := i_start_record + i_num_records - 1;
        
            IF l_start_record < 1
            THEN
                -- Minimum inbound 
                l_start_record := 1;
            END IF;
        
            IF l_start_record > l_coll_doc_entry.count
            THEN
                -- Force to not return data
                l_start_record := l_coll_doc_entry.count + 1;
            END IF;
        
            IF l_end_record > l_coll_doc_entry.count
            THEN
                -- Maximum outbound 
                l_end_record := l_coll_doc_entry.count;
            END IF;
        END IF;
    
        o_coll_epis_doc      := table_number();
        o_coll_epis_anamn    := table_number();
        o_coll_epis_rev_sys  := table_number();
        o_coll_epis_obs      := table_number();
        o_coll_epis_past_fsh := table_number();
        o_coll_epis_recomend := table_number();
    
        FOR i IN l_start_record .. l_end_record
        LOOP
            CASE l_coll_doc_entry(i).table_origin
                WHEN pk_touch_option.g_flg_tab_origin_epis_doc THEN
                    o_coll_epis_doc.extend;
                    o_coll_epis_doc(o_coll_epis_doc.last) := l_coll_doc_entry(i).record_key;
                
                WHEN pk_touch_option.g_flg_tab_origin_epis_anamn THEN
                    o_coll_epis_anamn.extend;
                    o_coll_epis_anamn(o_coll_epis_anamn.last) := l_coll_doc_entry(i).record_key;
                
                WHEN pk_touch_option.g_flg_tab_origin_epis_rev_sys THEN
                    o_coll_epis_rev_sys.extend;
                    o_coll_epis_rev_sys(o_coll_epis_rev_sys.last) := l_coll_doc_entry(i).record_key;
                
                WHEN pk_touch_option.g_flg_tab_origin_epis_obs THEN
                    o_coll_epis_obs.extend;
                    o_coll_epis_obs(o_coll_epis_obs.last) := l_coll_doc_entry(i).record_key;
                
                WHEN pk_touch_option.g_flg_tab_origin_epis_past_fsh THEN
                    o_coll_epis_past_fsh.extend;
                    o_coll_epis_past_fsh(o_coll_epis_past_fsh.last) := l_coll_doc_entry(i).record_key;
                
                WHEN pk_touch_option.g_flg_tab_origin_epis_recomend THEN
                    o_coll_epis_recomend.extend;
                    o_coll_epis_recomend(o_coll_epis_recomend.last) := l_coll_doc_entry(i).record_key;
            END CASE;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'An input parameter has an unexpected value',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_doc_area_value_ids;
    /**
    * Returns a set of records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info for episode
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message 
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   11/09/2010
    */
    FUNCTION get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_current_episode    IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_fltr_status        IN VARCHAR2 DEFAULT 'AOC',
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        o_doc_area_register  OUT t_cur_doc_area_register,
        o_doc_area_val       OUT t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_argument EXCEPTION;
        k_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value';
    
        l_episode            episode.id_episode%TYPE;
        l_visit              visit.id_visit%TYPE;
        l_patient            patient.id_patient%TYPE;
        l_coll_epis_doc      table_number;
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
    BEGIN
    
        g_error := 'LOGGING INPUT ARGUMENTS';
        pk_alertlog.log_debug(sub_object_name => k_function_name,
                              text            => 'i_lang: ' || i_lang || ' institution:' || i_prof.institution ||
                                                 ' software:' || i_prof.software || ' i_doc_area: ' ||
                                                 to_char(i_doc_area) || ' i_scope: ' || to_char(i_scope) ||
                                                 ' i_scope_type: ' || i_scope_type || ' i_fltr_status:' || i_fltr_status ||
                                                 ' i_order:' || i_order || ' i_fltr_start_date:' ||
                                                 to_char(i_fltr_start_date) || ' i_fltr_end_date:' ||
                                                 to_char(i_fltr_end_date) || ' i_paging:' || i_paging ||
                                                 ' i_start_record:' || to_char(i_start_record) || ' i_num_records:' ||
                                                 to_char(i_num_records));
    
        g_error := 'ANALYSING INPUT ARGUMENTS';
        IF i_doc_area IS NULL
           OR i_scope IS NULL
           OR i_scope_type IS NULL
           OR i_fltr_status IS NULL
           OR i_order IS NULL
           OR i_paging IS NULL
        THEN
            RAISE pk_touch_option_core.e_invalid_parameter;
        END IF;
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE pk_touch_option_core.e_invalid_parameter;
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
            RAISE pk_touch_option_core.e_invalid_parameter;
        END IF;
    
        g_error := 'CALL pk_touch_option.get_doc_area_value_ids function';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => table_number(i_doc_area),
                                                      i_scope              => table_number(i_scope),
                                                      i_scope_type         => i_scope_type,
                                                      i_fltr_status        => i_fltr_status,
                                                      i_order              => i_order,
                                                      i_fltr_start_date    => i_fltr_start_date,
                                                      i_fltr_end_date      => i_fltr_end_date,
                                                      i_paging             => i_paging,
                                                      i_start_record       => i_start_record,
                                                      i_num_records        => i_num_records,
                                                      o_record_count       => o_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        THEN
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
    
        g_error := 'CALL pk_touch_option.get_doc_area_value_internal';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT get_doc_area_value_internal(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_id_episode         => i_current_episode,
                                           i_id_patient         => l_patient,
                                           i_doc_area           => i_doc_area,
                                           i_epis_doc           => l_coll_epis_doc,
                                           i_epis_anamn         => l_coll_epis_anamn,
                                           i_epis_rev_sys       => l_coll_epis_rev_sys,
                                           i_epis_obs           => l_coll_epis_obs,
                                           i_epis_past_fsh      => l_coll_epis_past_fsh,
                                           i_epis_recomend      => l_coll_epis_recomend,
                                           i_flg_show_fm        => pk_alert_constant.g_yes,
                                           i_order              => i_order,
                                           o_doc_area_register  => o_doc_area_register,
                                           o_doc_area_val       => o_doc_area_val,
                                           o_template_layouts   => o_template_layouts,
                                           o_doc_area_component => o_doc_area_component,
                                           o_error              => o_error)
        THEN
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_touch_option_core.e_invalid_parameter THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'An input parameter has an unexpected value',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
        
            /* Open out cursors */
            -- We cannot use open_my_cursor method to open a strong cursor. 
            open_cur_doc_area_register(o_doc_area_register);
            open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
        
        WHEN pk_touch_option_core.e_function_call_error THEN
        
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'PACKAGE',
                                            value_in           => g_package_name);
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'METHOD',
                                            value_in           => k_function_name);
        
            /* Open out cursors */
            -- We cannot use open_my_cursor method to open a strong cursor. 
            open_cur_doc_area_register(o_doc_area_register);
            open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
            /* Open out cursors */
            -- We cannot use open_my_cursor method to open a strong cursor. 
            open_cur_doc_area_register(o_doc_area_register);
            open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_doc_area_value;

    /**************************************************************************        
    * Return cursor with records for touch option area        
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_epis_anamn             Table number with id_epis_anamnesis        
    * @param i_epis_rev_sys           Table number with id_epis_review_systems        
    * @param i_epis_obs               Table number with id_epis_observation        
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist        
    * @param i_epis_recomend          Table number with id_epis_recomend        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)        
    * @param o_doc_area_register      Cursor with the doc area info register        
    * @param o_doc_area_val           Cursor containing the completed info for episode        
    * @param o_template_layouts       Cursor containing the layout for each template used        
    * @param o_doc_area_component     Cursor containing the components for each template used        
    * @param o_error                  Error message        
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                        
    * @since                          2011/02/17                                        
    **************************************************************************/
    FUNCTION get_doc_area_value_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_doc           IN table_number,
        i_epis_anamn         IN table_number,
        i_epis_rev_sys       IN table_number,
        i_epis_obs           IN table_number,
        i_epis_past_fsh      IN table_number,
        i_epis_recomend      IN table_number,
        i_flg_show_fm        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT NOCOPY t_cur_doc_area_register,
        o_doc_area_val       OUT NOCOPY t_cur_doc_area_val,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30 CHAR) := 'GET_DOC_AREA_VALUE_INTERNAL';
    BEGIN
    
        g_error := 'OPEN O_DOC_AREA_REGISTER CURSOR';
        pk_alertlog.log_debug(g_error);
    
        --Returns records that meet the criteria arguments
        OPEN o_doc_area_register FOR
            SELECT t.order_by_default,
                   t.order_default,
                   t.id_epis_documentation,
                   t.parent,
                   t.id_doc_template,
                   t.template_desc,
                   t.dt_creation,
                   t.dt_creation_tstz,
                   t.dt_register,
                   t.id_professional,
                   t.nick_name,
                   t.desc_speciality,
                   t.id_doc_area,
                   t.flg_status,
                   t.desc_status,
                   t.id_episode,
                   t.flg_current_episode,
                   t.notes,
                   t.dt_last_update,
                   t.dt_last_update_tstz,
                   t.flg_detail,
                   t.flg_external,
                   t.flg_type_register,
                   t.flg_table_origin,
                   t.flg_reviewed,
                   t.id_prof_cancel,
                   t.dt_cancel_tstz,
                   t.id_cancel_reason,
                   t.cancel_reason,
                   t.cancel_notes,
                   t.flg_edition_type,
                   t.nick_name_prof_create,
                   t.desc_speciality_prof_create,
                   t.dt_clinical,
                   t.dt_clinical_rep,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      t.id_episode,
                                                      t.dt_last_update_tstz,
                                                      t.id_professional) signature
              FROM (SELECT dar.*, row_number() over(PARTITION BY dar.id_doc_area ORDER BY dar.order_by_default) AS rn
                      FROM TABLE(pk_touch_option.tf_get_doc_area_register(i_lang,
                                                                          i_prof,
                                                                          i_id_episode,
                                                                          i_id_patient,
                                                                          i_doc_area,
                                                                          i_epis_doc,
                                                                          i_epis_anamn,
                                                                          i_epis_rev_sys,
                                                                          i_epis_obs,
                                                                          i_epis_past_fsh,
                                                                          i_epis_recomend,
                                                                          i_flg_show_fm,
                                                                          i_order)) dar) t
             WHERE (t.rn <= i_num_record_show AND i_num_record_show IS NOT NULL)
                OR i_num_record_show IS NULL;
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        pk_alertlog.log_debug(g_error);
    
        IF i_num_record_show IS NOT NULL
        THEN
            OPEN o_doc_area_val FOR
                SELECT dav.id_epis_documentation,
                       dav.parent,
                       dav.id_documentation,
                       dav.id_doc_component,
                       dav.id_doc_element_crit,
                       dav.dt_reg,
                       dav.desc_doc_component,
                       dav.flg_type,
                       dav.desc_element,
                       dav.desc_element_view,
                       dav.value,
                       dav.flg_type_element,
                       dav.id_doc_area,
                       dav.rank_component,
                       dav.rank_element,
                       dav.internal_name,
                       dav.desc_quantifier,
                       dav.desc_quantification,
                       dav.desc_qualification,
                       dav.display_format,
                       dav.separator,
                       dav.flg_table_origin,
                       dav.flg_status,
                       dav.value_id,
                       NULL signature
                  FROM (SELECT dgav.*
                          FROM TABLE(pk_touch_option.tf_get_doc_area_val(i_lang,
                                                                         i_prof,
                                                                         i_id_episode,
                                                                         i_id_patient,
                                                                         i_doc_area,
                                                                         i_epis_doc,
                                                                         i_flg_show_fm)) dgav
                        
                          JOIN (SELECT dar.id_epis_documentation,
                                      row_number() over(PARTITION BY dar.id_doc_area ORDER BY dar.order_by_default DESC) AS rn
                                 FROM TABLE(tf_get_doc_area_register(i_lang,
                                                                     i_prof,
                                                                     i_id_episode,
                                                                     i_id_patient,
                                                                     i_doc_area,
                                                                     i_epis_doc,
                                                                     i_epis_anamn,
                                                                     i_epis_rev_sys,
                                                                     i_epis_obs,
                                                                     i_epis_past_fsh,
                                                                     i_epis_recomend,
                                                                     i_flg_show_fm,
                                                                     i_order)) dar) t
                            ON t.id_epis_documentation = dgav.id_epis_documentation
                         WHERE (t.rn <= i_num_record_show AND i_num_record_show IS NOT NULL)
                            OR i_num_record_show IS NULL) dav;
        
        ELSE
            OPEN o_doc_area_val FOR
                SELECT dav.id_epis_documentation,
                       dav.parent,
                       dav.id_documentation,
                       dav.id_doc_component,
                       dav.id_doc_element_crit,
                       dav.dt_reg,
                       dav.desc_doc_component,
                       dav.flg_type,
                       dav.desc_element,
                       dav.desc_element_view,
                       dav.value,
                       dav.flg_type_element,
                       dav.id_doc_area,
                       dav.rank_component,
                       dav.rank_element,
                       dav.internal_name,
                       dav.desc_quantifier,
                       dav.desc_quantification,
                       dav.desc_qualification,
                       dav.display_format,
                       dav.separator,
                       dav.flg_table_origin,
                       dav.flg_status,
                       dav.value_id,
                       NULL signature
                  FROM TABLE(pk_touch_option.tf_get_doc_area_val(i_lang,
                                                                 i_prof,
                                                                 i_id_episode,
                                                                 i_id_patient,
                                                                 i_doc_area,
                                                                 i_epis_doc,
                                                                 i_flg_show_fm)) dav;
        END IF;
    
        /*SELECT \*+ index(ed epis_documentation(id_epis_documentation)) *\
                 ed.id_epis_documentation,
                 ed.id_epis_documentation_parent PARENT,
                 d.id_documentation,
                 d.id_doc_component,
                 decr.id_doc_element_crit,
                 pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                 TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                 dc.flg_type,
                 get_element_description(i_lang,
                                         i_prof,
                                         de.flg_type,
                                         edd.value,
                                         edd.value_properties,
                                         decr.id_doc_element_crit,
                                         de.id_unit_measure_reference,
                                         de.id_master_item,
                                         decr.code_element_close) desc_element,
                 TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
                 pk_touch_option.get_formatted_value(i_lang,
                                                     i_prof,
                                                     de.flg_type,
                                                     edd.value,
                                                     edd.value_properties,
                                                     de.input_mask,
                                                     de.flg_optional_value,
                                                     de.flg_element_domain_type,
                                                     de.code_element_domain,
                                                     edd.dt_creation_tstz) VALUE,
                 de.flg_type flg_type_element,
                 ed.id_doc_area,
                 dtad.rank rank_component,
                 de.rank rank_element,
                 de.internal_name,
                 pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                 pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                 pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                 de.display_format,
                 de.separator,
                 pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
                 'A' flg_status, --TODO: Change this code, 
                 edd.value value_id
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
                    ON dc.id_doc_component = d.id_doc_component
                 INNER JOIN doc_element_crit decr
                    ON decr.id_doc_element_crit = edd.id_doc_element_crit
                 INNER JOIN doc_element de
                    ON de.id_doc_element = decr.id_doc_element
                 WHERE (ed.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                   AND ed.id_epis_documentation IN (SELECT \*+ opt_estimate(table t rows=1)*\
                                                     t.column_value
                                                      FROM TABLE(i_epis_doc) t)
                UNION ALL
                SELECT epis_d.id_epis_documentation,
                       NULL PARENT,
                       d.id_documentation,
                       dc.id_doc_component,
                       NULL id_doc_element_crit,
                       NULL dt_reg,
                       TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                       dc.flg_type,
                       NULL desc_element,
                       NULL desc_element_view,
                       NULL VALUE,
                       NULL flg_type_element,
                       epis_d.id_doc_area,
                       dtad.rank rank_component,
                       NULL rank_element,
                       NULL internal_name,
                       NULL desc_quantifier,
                       NULL desc_quantification,
                       NULL desc_qualification,
                       NULL display_format,
                       NULL separator,
                       pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
                       pk_alert_constant.g_active flg_status,
                       NULL value_id
                  FROM documentation d
                 INNER JOIN doc_component dc
                    ON d.id_doc_component = dc.id_doc_component
                 INNER JOIN (SELECT DISTINCT ed.id_epis_documentation,
                                             ed.id_doc_template,
                                             ed.id_doc_area,
                                             d.id_documentation_parent
                               FROM documentation d
                              INNER JOIN epis_documentation_det edd
                                 ON d.id_documentation = edd.id_documentation
                              INNER JOIN epis_documentation ed
                                 ON edd.id_epis_documentation = ed.id_epis_documentation
                              INNER JOIN doc_element_crit decr
                                 ON edd.id_doc_element_crit = decr.id_doc_element_crit
                              WHERE (ed.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                                AND ed.id_epis_documentation IN (SELECT \*+ opt_estimate(table t rows=1)*\
                                                                  t.column_value
                                                                   FROM TABLE(i_epis_doc) t)
                                AND d.flg_available = pk_touch_option.g_available
                                AND d.id_documentation_parent IS NOT NULL) epis_d
                    ON d.id_documentation = epis_d.id_documentation_parent
                 INNER JOIN doc_template_area_doc dtad
                    ON epis_d.id_doc_template = dtad.id_doc_template
                   AND epis_d.id_doc_area = dtad.id_doc_area
                   AND d.id_documentation = dtad.id_documentation
                 WHERE dc.flg_type = pk_summary_page.g_doc_title
                   AND dc.flg_available = pk_alert_constant.g_available
                   AND d.flg_available = pk_alert_constant.g_available
                UNION ALL
                --Discharge diagnosis of patient's family members to show in Past family history area
                SELECT pfm.id_epis_documentation,
                       pfm.parent,
                       pfm.id_documentation,
                       pfm.id_doc_component,
                       pfm.id_doc_element_crit,
                       pfm.dt_reg,
                       pfm.desc_doc_component,
                       pfm.flg_type,
                       pfm.desc_element,
                       pfm.desc_element_view,
                       pfm.value,
                       pfm.flg_type_element,
                       pfm.id_doc_area,
                       pfm.rank_component,
                       pfm.rank_element,
                       NULL                                        internal_name,
                       pfm.desc_quantifier,
                       pfm.desc_quantification,
                       pfm.desc_qualification,
                       pfm.display_format,
                       pfm.separator,
                       pk_touch_option.g_flg_tab_origin_epis_diags flg_table_origin,
                       pk_alert_constant.g_active                  flg_status,
                       NULL                                        value_id
                  FROM TABLE(pk_diagnosis_core.tf_final_diag_pat_family_val(i_lang, i_prof, i_id_patient)) pfm
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                   AND i_flg_show_fm = pk_alert_constant.g_yes
                UNION ALL
                --Surgeries done of patient's family members to show in Past family history area
                SELECT spf.id_epis_documentation,
                       spf.parent,
                       spf.id_documentation,
                       spf.id_doc_component,
                       spf.id_doc_element_crit,
                       spf.dt_reg,
                       spf.desc_doc_component,
                       spf.flg_type,
                       spf.desc_element,
                       spf.desc_element_view,
                       spf.value,
                       spf.flg_type_element,
                       spf.id_doc_area,
                       spf.rank_component,
                       spf.rank_element,
                       NULL                                         internal_name,
                       spf.desc_quantifier,
                       spf.desc_quantification,
                       spf.desc_qualification,
                       spf.display_format,
                       spf.separator,
                       pk_touch_option.g_flg_tab_origin_surg_record flg_table_origin,
                       pk_alert_constant.g_active                   flg_status,
                       NULL                                         value_id
                  FROM TABLE(pk_sr_surg_record.tf_surgery_pat_family_val(i_lang, i_prof, i_id_patient)) spf
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                   AND i_flg_show_fm = pk_alert_constant.g_yes
                 ORDER BY id_epis_documentation, rank_component, rank_element;
        */
        g_error := 'GET CURSOR O_TEMPLATE_LAYOUTS';
        pk_alertlog.log_debug(g_error);
        OPEN o_template_layouts FOR
            SELECT dt.id_doc_template,
                   xmlquery('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]' passing dt.template_layout AS "layout", CAST(d.id_doc_area AS NUMBER) AS "id_doc_area", CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template" RETURNING content).getclobval() layout,
                   pk_prof_utils.get_detail_signature(i_lang,
                                                      i_prof,
                                                      NULL,
                                                      d.dt_last_update_tstz,
                                                      d.id_prof_last_update) signature
              FROM doc_template dt
              JOIN (SELECT DISTINCT ed.id_doc_template, ed.id_doc_area, ed.id_prof_last_update, ed.dt_last_update_tstz
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                         t.column_value
                                                          FROM TABLE(i_epis_doc) t)) d
                ON d.id_doc_template = dt.id_doc_template
             WHERE xmlexists('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]'
                             passing dt.template_layout AS "layout",
                             CAST(d.id_doc_area AS NUMBER) AS "id_doc_area",
                             CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template");
    
        g_error := 'GET CURSOR O_DOC_AREA_COMPONENT';
        pk_alertlog.log_debug(g_error);
        OPEN o_doc_area_component FOR
            SELECT d.id_documentation,
                   dc.flg_type,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   d.id_doc_area
              FROM documentation d
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             WHERE d.flg_available = pk_alert_constant.g_available
               AND dc.flg_available = pk_alert_constant.g_available
               AND (dtad.id_doc_area, dtad.id_doc_template) IN
                   (SELECT DISTINCT ed.id_doc_area, ed.id_doc_template
                      FROM epis_documentation ed
                     WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                         t.column_value
                                                          FROM TABLE(i_epis_doc) t));
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
            -- We cannot use open_my_cursor method to open a strong cursor. 
            open_cur_doc_area_register(o_doc_area_register);
            open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_doc_area_value_internal;

    /**
    * Returns the settings of an area according to the institution, market and software.
    *
    * @param   i_doc_area         Area ID
    * @param   i_institution      Institution ID
    * @param   i_market           Market ID
    * @param   i_software         Software ID
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/19/2010
    */
    FUNCTION tf_doc_area_inst_soft
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_market      IN market.id_market%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN t_coll_doc_area_inst_soft
        PIPELINED IS
    
        r_dais doc_area_inst_soft%ROWTYPE;
    
    BEGIN
    
        FOR r_dais IN (SELECT /*+ result_cache */
                        d.*
                         FROM doc_area_inst_soft d
                        INNER JOIN (SELECT dais.id_doc_area_inst_soft,
                                          rank() over(PARTITION BY dais.id_doc_area ORDER BY dais.id_institution DESC, dais.id_market DESC, dais.id_software DESC) precedence_level
                                     FROM doc_area_inst_soft dais
                                    WHERE dais.id_doc_area = i_doc_area
                                      AND dais.id_institution IN (i_institution, 0)
                                      AND (dais.id_market IN (i_market, 0) OR dais.id_market IS NULL)
                                      AND dais.id_software IN (i_software, 0)) t
                           ON d.id_doc_area_inst_soft = t.id_doc_area_inst_soft
                        WHERE t.precedence_level = 1)
        LOOP
            PIPE ROW(r_dais);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN no_data_needed THEN
            -- when we run a pipelined function without exhausting it we see this exception being rased to clean up (releasing any resources that need be released).
            -- In this case no cleanup code is needed, so just return
            RETURN;
    END tf_doc_area_inst_soft;

    /**
    * Returns the settings of an area according to the institution, market and software.
    *
    * @param   i_doc_area         Area ID
    * @param   i_institution      Institution ID
    * @param   i_software         Software ID
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/19/2010
    */
    FUNCTION tf_doc_area_inst_soft
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN t_coll_doc_area_inst_soft
        PIPELINED IS
        r_dais   doc_area_inst_soft%ROWTYPE;
        l_market market.id_market%TYPE;
        r_dais   doc_area_inst_soft%ROWTYPE;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_institution);
    
        FOR r_dais IN (SELECT /*+ result_cache */
                        *
                         FROM TABLE(tf_doc_area_inst_soft(i_doc_area, i_institution, l_market, i_software)))
        LOOP
            PIPE ROW(r_dais);
        END LOOP;
    
        RETURN;
    EXCEPTION
        WHEN no_data_needed THEN
            -- when we run a pipelined function without exhausting it we see this exception being rased to clean up (releasing any resources that need be released).
            -- In this case no cleanup code is needed, so just return
            RETURN;
    END tf_doc_area_inst_soft;

    /**
    * Get the last element of a given list, that was registered in the patient 
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID         
    * @param   i_doc_elements List of elements
    * @param   o_doc_element  Last selected element
    * @param   o_error        Error information
    *
    *
    * @return  True or False on success or error
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_pat_last_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_doc_elements IN table_number,
        o_doc_element  OUT doc_element.id_doc_element%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_pat_last_record';
    
        CURSOR c_pat_doc IS
            SELECT /*+opt_estimate(table elem rows=5)*/
             edd.id_doc_element
              FROM episode e
              JOIN epis_documentation ed
                ON ed.id_episode = e.id_episode
              JOIN epis_documentation_det edd
                ON edd.id_epis_documentation = ed.id_epis_documentation
              JOIN TABLE(i_doc_elements) elem
                ON elem.column_value = edd.id_doc_element
             WHERE e.id_patient = i_patient
               AND ed.flg_status = pk_alert_constant.g_active
             ORDER BY ed.dt_last_update_tstz DESC;
    
    BEGIN
    
        OPEN c_pat_doc;
        FETCH c_pat_doc
            INTO o_doc_element;
        CLOSE c_pat_doc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_last_record;

    /**************************************************************************
    * Return doc_area value from epis_documentation id
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_epis_doc               Epis Documentation Identifier
    *
    * @param o_doc_area               Doc area identifier
    * @param o_error                  Error message
    *                                                                         
    * @author                         Rui Spratley
    * @version                        2.6.0.5                                 
    * @since                          2011/03/03
    **************************************************************************/
    FUNCTION get_doc_area_from_epis_doc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_doc_area OUT doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30 CHAR) := 'GET_DOC_AREA_FROM_EPIS_DOC';
    
        CURSOR c_doc_area IS
            SELECT ed.id_doc_area
              FROM epis_documentation ed
             WHERE ed.id_epis_documentation = i_epis_doc;
    BEGIN
    
        g_error := 'Open cursor doc_area for epis doc id: ' || i_epis_doc;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_doc_area;
        FETCH c_doc_area
            INTO o_doc_area;
        CLOSE c_doc_area;
    
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
        
            o_doc_area := NULL;
        
            RETURN FALSE;
    END get_doc_area_from_epis_doc;

    /**************************************************************************
     * Get list of actions for a specified subject and state.                 *
     * Based on pk_action.get_actions function.                               *
     *                                                                        *
     * @param i_lang                   Preferred language ID for this         *
     *                                 professional                           *
     * @param i_prof                   Object (professional ID,               *
     *                                 institution ID, software ID)           *
     * @param i_subject                Subject                                *
     *                                                                        *
     * @return                         Table with documentation systems info  *
     *                                                                        *
     * @author                         Gustavo Serrano                        *
     * @version                        2.6.1                                  *
     * @since                          08-Fev-2011                            *
    **************************************************************************/
    FUNCTION tf_get_doc_system
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subject IN doc_system.subject%TYPE
    ) RETURN t_coll_action IS
        l_function_name CONSTANT VARCHAR2(30) := 'tf_get_doc_system';
        l_tbl_doc_sys t_coll_action;
        l_error       t_error_out;
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        SELECT t_rec_action(ds.id_doc_system, --id_action
                            ds.id_parent, --id_parent
                            LEVEL, --level_nr
                            NULL, --from_state
                            NULL, --to_state
                            pk_translation.get_translation(i_lang, ds.code_doc_system), --desc_action
                            NULL, --icon
                            NULL, --flg_default
                            NULL, --action
                            flg_available) --flg_active
          BULK COLLECT
          INTO l_tbl_doc_sys
          FROM doc_system ds
         WHERE ds.subject = i_subject
           AND ds.flg_available = pk_alert_constant.g_yes
        CONNECT BY PRIOR ds.id_doc_system = ds.id_parent
         START WITH ds.id_parent IS NULL
         ORDER BY LEVEL, ds.rank, pk_translation.get_translation(i_lang, ds.code_doc_system);
    
        RETURN l_tbl_doc_sys;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END tf_get_doc_system;

    /**
    * Get a list of templates respecting a hierarchical structure of levels according to a subject
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    * @param   i_doc_area     Documentation area ID
    * @param   i_context      the context id
    * @param   i_flg_type     Access type to touch_option functionality
    * @param   o_templates    List of templates in an hierarchical structure of levels
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Gustavo Serrano
    * @version 2.6.1
    * @since   2/08/2011
    */
    FUNCTION get_doc_template_extended
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_context   IN doc_template_context.id_context%TYPE,
        i_flg_type  IN doc_area_inst_soft.flg_type%TYPE,
        o_templates OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_template_extended';
    
        l_subject               sys_config.value%TYPE;
        l_templates             pk_types.cursor_type;
        l_tbl_id_doc_template   table_number;
        l_tbl_desc_doc_template table_varchar;
        l_error                 t_error_out;
    
    BEGIN
    
        g_error := 'CALL get_doc_template';
        IF NOT get_doc_template(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_patient   => i_patient,
                                i_episode   => i_episode,
                                i_doc_area  => i_doc_area,
                                i_context   => i_context,
                                o_templates => l_templates,
                                o_error     => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Fetch get_doc_template cursor';
        FETCH l_templates BULK COLLECT
            INTO l_tbl_id_doc_template, l_tbl_desc_doc_template;
        CLOSE l_templates;
    
        g_error := 'Call get_doc_guideline config';
        IF NOT get_doc_guideline(i_lang => i_lang, i_prof => i_prof, o_subject => l_subject)
        THEN
            -- No configuration for guideline usage
            -- Use get_doc_template result simulating the output in an hierarchical structure (one level)
            pk_alertlog.log_debug(text            => 'GET_DOC_GUIDELINE - SYS_CONFIG MISSING',
                                  object_name     => g_package_name,
                                  sub_object_name => l_function_name);
            --RAISE g_exception;
            OPEN o_templates FOR
                SELECT rownum id_doc_system,
                       NULL id_parent,
                       1 level_nr,
                       1 rank,
                       NULL desc_doc_system,
                       table_number(id.column_value) id_doc_template,
                       table_varchar(des.column_value) desc_doc_template,
                       1 count_dt_leaf,
                       1 count_dt_total
                  FROM (SELECT rownum rown, column_value
                          FROM TABLE(l_tbl_id_doc_template)) id
                  JOIN (SELECT rownum rown, column_value
                          FROM TABLE(l_tbl_desc_doc_template)) des
                    ON id.rown = des.rown
                 ORDER BY des.column_value;
        ELSE
        
            g_error := 'Fetch actions';
            OPEN o_templates FOR
                SELECT t1.id_doc_system,
                       MIN(t1.id_parent) id_parent,
                       MIN(t1.level_nr) level_nr,
                       MIN(t1.rank) rank,
                       pk_translation.get_translation(i_lang, 'DOC_SYSTEM.CODE_DOC_SYSTEM.' || t1.id_doc_system) desc_doc_system,
                       CASE MIN(t1.isleaf)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            CAST(COLLECT(to_number(nvl(t1.id_doc_template, g_null_number)) ORDER BY
                                         nvl(pk_translation.get_translation(i_lang,
                                                                            k_code_doc_template || t1.id_doc_template),
                                             g_null_varchar),
                                         t1.id_doc_template) AS table_number)
                       END id_doc_template,
                       CASE MIN(t1.isleaf)
                           WHEN 0 THEN
                            NULL
                           ELSE
                            CAST(COLLECT(to_char(nvl(pk_translation.get_translation(i_lang,
                                                                                    k_code_doc_template ||
                                                                                    t1.id_doc_template),
                                                     g_null_varchar)) ORDER BY
                                         nvl(pk_translation.get_translation(i_lang,
                                                                            k_code_doc_template || t1.id_doc_template),
                                             g_null_varchar),
                                         t1.id_doc_template) AS table_varchar)
                       END desc_doc_template,
                       CASE MIN(t1.isleaf)
                           WHEN 0 THEN
                            MIN(count_dt_total)
                           ELSE
                            MIN(count_dt_leaf)
                       END count_dt_leaf
                  FROM (SELECT t.id_doc_system,
                               t.id_parent id_parent,
                               t.level_nr level_nr,
                               t.rank rank,
                               t.isleaf,
                               dts.id_doc_template,
                               first_value(dts.id_doc_template ignore NULLS) over(PARTITION BY t.id_root) flg_show,
                               COUNT(dts.id_doc_template) over(PARTITION BY t.id_root, t.id_doc_system) count_dt_leaf,
                               COUNT(dts.id_doc_template) over(PARTITION BY t.id_root) count_dt_total
                          FROM (SELECT ds.id_doc_system,
                                       ds.id_parent,
                                       LEVEL             level_nr,
                                       ds.rank,
                                       connect_by_isleaf isleaf,
                                       connect_by_root   id_doc_system id_root
                                  FROM doc_system ds
                                 WHERE ds.subject = l_subject
                                   AND ds.flg_available = pk_alert_constant.g_available
                                CONNECT BY PRIOR ds.id_doc_system = ds.id_parent
                                 START WITH ds.id_parent IS NULL) t
                          LEFT JOIN doc_template_system dts
                            ON dts.id_doc_system = t.id_doc_system
                         WHERE ((isleaf = 1 AND
                               dts.id_doc_template IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                          t.column_value
                                                           FROM TABLE(l_tbl_id_doc_template) t)) OR isleaf = 0)) t1
                 WHERE t1.flg_show IS NOT NULL
                 GROUP BY t1.id_doc_system
                 ORDER BY level_nr, rank, desc_doc_system;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error.ora_sqlcode,
                                              i_sqlerrm  => l_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            /* Open out cursors */
            pk_types.open_my_cursor(o_templates);
        
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_templates);
        
            RETURN FALSE;
    END get_doc_template_extended;

    /*************************************************************************
    * Get list of actions for create button for a specified subject.         *
    *                                                                        *
    * @param i_lang                Preferred language ID for this            *
    *                              professional                              *
    * @param i_prof                Object (professional ID,                  *
    *                              institution ID, software ID)              *
    * @param i_subject             Subject                                   *
    * @param i_episode             the episode id                            *
    * @param i_doc_area            the doc_area id                           *
    *                                                                        *
    * @return                      Table with documentation systems info     *
    *                                                                        *
    * @author                      Gustavo Serrano                           *
    * @version                     2.6.1                                     *
    * @since                       03-Mar-2011                               *
    **************************************************************************/
    FUNCTION get_doc_template_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subject  IN action.subject%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_titles   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name      CONSTANT VARCHAR2(30) := 'get_doc_template_list';
        co_code_tmplt        CONSTANT translation.code_translation%TYPE := k_code_doc_template;
        co_code_systm        CONSTANT translation.code_translation%TYPE := 'DOC_SYSTEM.CODE_DOC_SYSTEM.';
        co_code_msg_template CONSTANT sys_message.code_message%TYPE := 'DOCUMENTATION_M040';
        co_icon_selected     CONSTANT sys_button.icon%TYPE := 'HandSelectedIcon';
    
        l_subject          sys_config.value%TYPE;
        l_type             doc_area_inst_soft.flg_type%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_gender           patient.gender%TYPE;
        l_age              patient.age%TYPE;
        l_error            t_error_out;
        l_level_titles     table_varchar;
    BEGIN
        g_error := 'Fetch sys_config config';
        IF NOT get_doc_guideline(i_lang => i_lang, i_prof => i_prof, o_subject => l_subject)
        THEN
            l_subject := NULL;
            pk_alertlog.log_debug(text            => 'GET_DOC_GUIDELINE - SYS_CONFIG MISSING',
                                  object_name     => g_package_name,
                                  sub_object_name => l_function_name);
        END IF;
    
        g_error := 'GET DOC_AREA FLG_TYPE';
        l_type  := get_touch_option_type(i_prof, i_doc_area);
    
        g_error            := 'GET PROFESSIONAL''S TEMPLATE';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'CALLING GET_PAT_INFO_BY_EPISODE';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang, i_episode, l_gender, l_age)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Fetch list';
        OPEN o_list FOR
            SELECT t1.id_doc_system,
                   MIN(t1.id_parent) id_parent,
                   MIN(t1.level_nr) level_nr,
                   MIN(t1.rank) rank,
                   pk_translation.get_translation(i_lang, co_code_systm || t1.id_doc_system) desc_doc_system,
                   CASE MIN(t1.isleaf)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        CAST(COLLECT(to_number(nvl(t1.id_doc_template, g_null_number)) ORDER BY
                                     pk_translation.get_translation(i_lang, co_code_tmplt || t1.id_doc_template)) AS
                             table_number)
                   END id_doc_template,
                   CASE MIN(t1.isleaf)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        CAST(COLLECT(to_char(nvl(pk_translation.get_translation(i_lang,
                                                                                co_code_tmplt || t1.id_doc_template),
                                                 g_null_varchar)) ORDER BY
                                     pk_translation.get_translation(i_lang, co_code_tmplt || t1.id_doc_template)) AS
                             table_varchar)
                   END desc_doc_template,
                   CASE MIN(t1.isleaf)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        CAST(COLLECT(to_number(decode(t1.id_epis_doc_template,
                                                      NULL,
                                                      g_null_number,
                                                      t1.id_epis_doc_template)) ORDER BY
                                     pk_translation.get_translation(i_lang, co_code_tmplt || t1.id_doc_template)) AS
                             table_number)
                   END id_epis_doc_template,
                   CASE MIN(t1.isleaf)
                       WHEN 0 THEN
                        NULL
                       ELSE
                        CAST(COLLECT(to_char(nvl(t1.flg_icon, g_null_varchar)) ORDER BY
                                     pk_translation.get_translation(i_lang, co_code_tmplt || t1.id_doc_template)) AS
                             table_varchar)
                   END flg_icon,
                   CASE MIN(t1.isleaf)
                       WHEN 0 THEN
                        MIN(count_dt_total)
                       ELSE
                        MIN(count_dt_leaf)
                   END count_dt_leaf
            
              FROM (SELECT t.id_doc_system,
                           t.id_parent id_parent,
                           t.level_nr level_nr,
                           t.rank rank,
                           t.isleaf,
                           t.subject,
                           dt_aux.id_doc_template,
                           dt_aux.id_epis_doc_template,
                           dt_aux.flg_icon,
                           first_value(dt_aux.id_doc_template ignore NULLS) over(PARTITION BY t.id_root) flg_show,
                           COUNT(dt_aux.id_doc_template) over(PARTITION BY t.id_root, t.id_doc_system) count_dt_leaf,
                           COUNT(dt_aux.id_doc_template) over(PARTITION BY t.id_root) count_dt_total
                      FROM (SELECT /*+ NO_USE_NL(dtc dt) */
                            DISTINCT dt.id_doc_template,
                                     edt.id_epis_doc_template,
                                     pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                                     decode(edt.id_epis_doc_template, NULL, NULL, co_icon_selected) flg_icon
                              FROM doc_template dt
                             INNER JOIN doc_template_context dtc
                                ON dt.id_doc_template = dtc.id_doc_template
                              JOIN doc_template_area da
                                ON dt.id_doc_template = da.id_doc_template
                               AND da.id_doc_area = i_doc_area
                              LEFT JOIN epis_doc_template edt
                                ON dt.id_doc_template = edt.id_doc_template
                               AND edt.id_episode = i_episode
                               AND edt.id_prof_cancel IS NULL -- exclude cancelled doc templates
                               AND (edt.id_profile_template = l_profile_template OR edt.id_profile_template IS NULL) --Selected template is applicable to current profile
                               AND ((edt.id_doc_area IS NULL AND
                                   l_type NOT IN (g_flg_type_doc_area_appointmt,
                                                    g_flg_type_doc_area_service,
                                                    g_flg_type_doc_area_complaint,
                                                    g_flg_type_doc_area)) OR EXISTS
                                    (SELECT 1
                                       FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(edt.id_doc_area,
                                                                                        i_prof.institution,
                                                                                        i_prof.software)) aux
                                      WHERE aux.flg_type = l_type) AND
                                    (
                                    -- COMMENT : Se o criterio for área + algo então limito os templates pre-seleccionados igual à doc_area da qual pretendo obter templates
                                     (l_type IN (g_flg_type_doc_area_appointmt,
                                                 g_flg_type_doc_area_service,
                                                 g_flg_type_doc_area_complaint,
                                                 g_flg_type_doc_area) AND edt.id_doc_area = i_doc_area) OR
                                    -- COMMENT : Se o criterio NÃO for área + algo então simplesmente se filtra pelo flg_type
                                     (l_type NOT IN (g_flg_type_doc_area_appointmt,
                                                     g_flg_type_doc_area_service,
                                                     g_flg_type_doc_area_complaint,
                                                     g_flg_type_doc_area))))
                            
                            -- COMMENT : Se o criterio for CT pesquisa os templates por CT + Appointment
                             WHERE ((dtc.flg_type = l_type AND l_type != g_flg_type_complaint_sch_evnt) OR
                                   (l_type = g_flg_type_complaint_sch_evnt AND
                                   dtc.flg_type IN (g_flg_type_complaint_sch_evnt, g_flg_type_appointment)))
                               AND (
                                   -- COMMENT : Se o criterio for área + algo então limito os templates cujo o id_context é igual à doc_area da qual pretendo obter templates
                                    (l_type IN (g_flg_type_doc_area_appointmt,
                                                g_flg_type_doc_area_service,
                                                g_flg_type_doc_area_complaint,
                                                g_flg_type_doc_area) AND dtc.id_context = i_doc_area) OR
                                   -- COMMENT : Se o criterio NÃO for área + algo então simplesmente se filtra pelo flg_type
                                    l_type NOT IN (g_flg_type_doc_area_appointmt,
                                                   g_flg_type_doc_area_service,
                                                   g_flg_type_doc_area_complaint,
                                                   g_flg_type_doc_area))
                               AND (dtc.id_profile_template = l_profile_template OR dtc.id_profile_template IS NULL) --Available templates applicable to current profile
                               AND dtc.id_institution IN (0, i_prof.institution)
                               AND dtc.id_software IN (0, i_prof.software)
                               AND dt.flg_available = pk_alert_constant.g_yes
                               AND pk_patient.validate_pat_gender(l_gender, dt.flg_gender) = 1
                               AND (dt.age_min <= l_age OR dt.age_min IS NULL OR l_age IS NULL)
                               AND (dt.age_max >= l_age OR dt.age_max IS NULL OR l_age IS NULL)) dt_aux --
                      LEFT JOIN doc_template_system dts
                        ON dts.id_doc_template = dt_aux.id_doc_template
                      FULL OUTER JOIN (SELECT ds.id_doc_system,
                                             ds.id_parent,
                                             LEVEL             level_nr,
                                             ds.rank,
                                             ds.subject,
                                             connect_by_isleaf isleaf,
                                             connect_by_root   id_doc_system id_root
                                        FROM doc_system ds
                                       WHERE ds.flg_available = pk_alert_constant.g_yes
                                      CONNECT BY PRIOR ds.id_doc_system = ds.id_parent
                                       START WITH ds.id_parent IS NULL) t
                        ON t.id_doc_system = dts.id_doc_system
                     WHERE ((nvl(isleaf, 1) = 1 AND dt_aux.id_doc_template IS NOT NULL) OR isleaf = 0)) t1
             WHERE t1.flg_show IS NOT NULL
               AND ((l_subject IS NOT NULL AND t1.subject = l_subject) OR (l_subject IS NULL) OR (t1.subject IS NULL))
             GROUP BY t1.id_doc_system
             ORDER BY level_nr, rank, desc_doc_system;
    
        IF l_subject IS NOT NULL
        THEN
            --Labels for columns of the search grid . They are in according with the guideline (subject) and their hierarchical level
            --Format:  'DOC_SYSTEM.<SUBJECT>.<LEVEL>'
            SELECT DISTINCT 'DOC_SYSTEM.' || ds.subject || '.' || LEVEL
              BULK COLLECT
              INTO l_level_titles
              FROM doc_system ds
             WHERE ds.subject = l_subject
               AND ds.flg_available = pk_alert_constant.g_yes
            CONNECT BY PRIOR ds.id_doc_system = ds.id_parent
             START WITH ds.id_parent IS NULL;
        
        ELSE
            l_level_titles := table_varchar();
        END IF;
    
        -- Append the label "Template" for leaf levels
        l_level_titles.extend();
        l_level_titles(l_level_titles.last) := co_code_msg_template;
    
        g_error := 'CALLING GET_MESSAGE_ARRAY';
        IF NOT
            pk_message.get_message_array(i_lang => i_lang, i_code_msg_arr => l_level_titles, o_desc_msg_arr => o_titles)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error.ora_sqlcode,
                                              i_sqlerrm  => l_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            /* Open out cursors */
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_titles);
        
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_titles);
            RETURN FALSE;
    END get_doc_template_list;

    /**
    * Get a description of the element under conditions such as its value, its value respect to reference values, etc.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional identification and its context (institution and software)
    * @param i_type            Element type
    * @param i_value           Element value
    * @param i_properties      Properties for the element value 
    * @param i_element_crit    Element criteria ID
    * @param i_uom_reference   Unit of measurement used as base/reference
    * @param i_description     Default description for this element
    *
    * @return  Conditional description if applicable or the default description in other cases
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   14-06-2011
    */
    FUNCTION get_element_conditional_descr
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN doc_element.flg_type%TYPE,
        i_value         IN epis_documentation_det.value%TYPE,
        i_properties    IN epis_documentation_det.value_properties%TYPE,
        i_element_crit  IN doc_element_crit.id_doc_element_crit%TYPE,
        i_uom_reference IN doc_element.id_unit_measure_reference%TYPE,
        i_description   IN pk_translation.t_desc_translation
    ) RETURN pk_translation.t_desc_translation IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_element_conditional_descr';
        l_description          pk_translation.t_desc_translation;
        l_num_value            doc_element.ref_val_max%TYPE;
        l_num_converted_value  doc_element.ref_val_max%TYPE;
        l_rec_value_properties t_rec_value_properties;
        l_error                t_error_out;
    
        /**
        * Obtains description of a numeric element according its value
        *
        * @param   i_val   Value
        *
        * @return  Conditional description if applicable or NULL in other cases
        *
        * @author  ARIEL.MACHADO
        * @version 2.6.1.2
        * @since   17-06-2011
        */
        FUNCTION inner_get_interv_desc(i_val IN doc_element_crit_int.max_value%TYPE)
            RETURN pk_translation.t_desc_translation IS
            co_function_name CONSTANT VARCHAR2(30 CHAR) := 'inner_get_interv_desc';
            l_interv_desc pk_translation.t_desc_translation;
        BEGIN
            SELECT pk_translation.get_translation(i_lang, t.code_element_close) desc_element_close
              INTO l_interv_desc
              FROM (SELECT deci.id_doc_element_crit,
                           deci.min_value,
                           deci.max_value,
                           deci.code_element_close,
                           deci.code_ref_val_above,
                           deci.code_ref_val_below,
                           deci.code_ref_val_normal,
                           row_number() over(PARTITION BY deci.id_doc_element_crit ORDER BY deci.min_value, deci.max_value) rank
                      FROM doc_element_crit_int deci
                     WHERE deci.id_doc_element_crit = i_element_crit
                       AND i_val BETWEEN nvl(deci.min_value, i_val) AND nvl(deci.max_value, i_val)
                       AND deci.flg_available = pk_alert_constant.g_yes) t
             WHERE t.rank = 1;
            RETURN l_interv_desc;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
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
        END inner_get_interv_desc;
    
        /**
        * Obtains description of the numeric element with reference values according to its value in relation to their reference values
        *
        * @param   i_val                Value
        * @param   i_value_properties   Value properties
        *
        * @return  Conditional description if applicable or NULL in other cases
        *
        * @author  ARIEL.MACHADO
        * @version 2.6.1.2
        * @since   17-06-2011
        */
        FUNCTION inner_get_ref_val_desc
        (
            i_val              IN doc_element_crit_int.max_value%TYPE,
            i_value_properties IN t_rec_value_properties
        ) RETURN pk_translation.t_desc_translation IS
            co_function_name CONSTANT VARCHAR2(30 CHAR) := 'inner_get_ref_val_desc';
            l_rev_val_desc        pk_translation.t_desc_translation;
            l_desc_ref_val_above  pk_translation.t_desc_translation;
            l_desc_ref_val_below  pk_translation.t_desc_translation;
            l_desc_ref_val_normal pk_translation.t_desc_translation;
        BEGIN
            SELECT pk_translation.get_translation(i_lang, t.code_ref_val_above) desc_ref_val_above,
                   pk_translation.get_translation(i_lang, t.code_ref_val_below) desc_ref_val_below,
                   pk_translation.get_translation(i_lang, t.code_ref_val_normal) desc_ref_val_normal
              INTO l_desc_ref_val_above, l_desc_ref_val_below, l_desc_ref_val_normal
              FROM (SELECT deci.id_doc_element_crit,
                           deci.min_value,
                           deci.max_value,
                           deci.code_element_close,
                           deci.code_ref_val_above,
                           deci.code_ref_val_below,
                           deci.code_ref_val_normal,
                           row_number() over(PARTITION BY deci.id_doc_element_crit ORDER BY deci.min_value, deci.max_value) rank
                      FROM doc_element_crit_int deci
                     WHERE deci.id_doc_element_crit = i_element_crit
                       AND deci.flg_available = pk_alert_constant.g_yes) t
             WHERE t.rank = 1;
        
            IF (i_val < i_value_properties.ref_val_min)
               OR (i_val = i_value_properties.ref_val_min AND i_value_properties.flg_ref_op_min = 'G')
            THEN
                -- The value is below of minimum reference value
                l_rev_val_desc := l_desc_ref_val_below;
            
            ELSIF (i_val > i_value_properties.ref_val_max)
                  OR (i_val = i_value_properties.ref_val_max AND i_value_properties.flg_ref_op_max = 'L')
            THEN
                -- The value is above of maximum reference value
                l_rev_val_desc := l_desc_ref_val_above;
            ELSE
                -- The value is according reference values
                l_rev_val_desc := l_desc_ref_val_normal;
            END IF;
        
            RETURN l_rev_val_desc;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
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
        END inner_get_ref_val_desc;
    
        /**
        * Obtains equivalent values for different units of measurement
        *
        * @param   i_val        Value to convert
        * @param   i_from_uom   Unit to convert from
        * @param   i_to_uom     Unit to convert to
        *
        * @return  Converted value
        *
        * @author  ARIEL.MACHADO
        * @version 2.6.1.2
        * @since   15-06-2011
        */
        FUNCTION inner_get_converted_value
        (
            i_val      IN doc_element.ref_val_max%TYPE,
            i_from_uom IN unit_measure.id_unit_measure%TYPE,
            i_to_uom   IN unit_measure.id_unit_measure%TYPE
        ) RETURN doc_element.ref_val_max%TYPE IS
            co_function_name CONSTANT VARCHAR2(30 CHAR) := 'inner_get_converted_value';
            l_converted_value doc_element.ref_val_max%TYPE;
            l_error           t_error_out;
        BEGIN
            IF i_from_uom IS NOT NULL
               AND i_to_uom IS NOT NULL
            THEN
                -- Convert the value to UOM reference (base)
                l_converted_value := pk_unit_measure.get_unit_mea_conversion(i_value         => i_val,
                                                                             i_unit_meas     => i_from_uom,
                                                                             i_unit_meas_def => i_to_uom);
                IF l_converted_value IS NULL
                THEN
                    g_error := 'Convert Units of Measurement: No conversion formula between the following id_unit_measure: ' ||
                               i_from_uom || ' -> ' || i_to_uom;
                    pk_alertlog.log_error(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => co_function_name);
                
                    -- Returns original value
                    l_converted_value := i_val;
                END IF;
            ELSE
                -- Returns original value
                l_converted_value := i_val;
            END IF;
            RETURN l_converted_value;
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
        END inner_get_converted_value;
    BEGIN
    
        CASE i_type
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
            
                g_error                := 'EXPANDING VALUE_PROPERTIES';
                l_rec_value_properties := expand_value_properties(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_element_type     => i_type,
                                                                  i_value_properties => i_properties);
            
                l_num_value := to_number(REPLACE(i_value, '+', NULL), k_to_number_mask);
            
                -- Normalize the value of the element according to UOM of reference
                l_num_converted_value := inner_get_converted_value(i_val      => l_num_value,
                                                                   i_from_uom => l_rec_value_properties.id_unit_measure,
                                                                   i_to_uom   => i_uom_reference);
            
                -- Retrieve the description according to the normalized value
                l_description := inner_get_interv_desc(l_num_converted_value);
            
                -- If descriptions by interval is not applicable for this element then return the default description
                IF l_description IS NULL
                THEN
                    l_description := i_description;
                END IF;
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
                g_error                := 'EXPANDING VALUE_PROPERTIES';
                l_rec_value_properties := expand_value_properties(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_element_type     => i_type,
                                                                  i_value_properties => i_properties);
            
                l_num_value := to_number(REPLACE(i_value, '+', NULL), k_to_number_mask);
            
                -- Retrieve the description according to the value
                l_description := inner_get_ref_val_desc(l_num_value, l_rec_value_properties);
            
                -- If descriptions by ref value is not applicable for this element then return the default description
                IF l_description IS NULL
                THEN
                    l_description := i_description;
                END IF;
            ELSE
                l_description := i_description;
        END CASE;
    
        RETURN l_description;
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
            RAISE;
    END get_element_conditional_descr;

    /**
    * Returns element description
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_flg_type        Element type
    * @param   i_value           Element value
    * @param   i_properties      Properties for the element value 
    * @param   i_element_crit    Element criteria ID
    * @param   i_uom_reference   Unit of measurement used as base/reference
    * @param   i_master_item     ID of an item in a master area that is represented by this element
    * @param   i_code_trans      Code used to retrieve default translation of element
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   20-06-2011
    */
    FUNCTION get_element_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN doc_element.flg_type%TYPE,
        i_value         IN epis_documentation_det.value%TYPE,
        i_properties    IN epis_documentation_det.value_properties%TYPE,
        i_element_crit  IN doc_element_crit.id_doc_element_crit%TYPE,
        i_uom_reference IN doc_element.id_unit_measure_reference%TYPE,
        i_master_item   IN doc_element.id_master_item%TYPE,
        i_code_trans    IN translation.code_translation%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_element_description';
        l_description    pk_translation.t_desc_translation;
        l_ti_description pk_translation.t_desc_translation;
        l_error          t_error_out;
    BEGIN
        --Returns the item's description in case of an element that refers to a value in an external functionallity
        l_ti_description := pk_touch_option_ti.get_element_description(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_flg_type    => i_type,
                                                                       i_master_item => i_master_item,
                                                                       i_code_trans  => i_code_trans);
    
        --Returns the item's description under conditions such as its value
        l_description := get_element_conditional_descr(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_type          => i_type,
                                                       i_value         => i_value,
                                                       i_properties    => i_properties,
                                                       i_element_crit  => i_element_crit,
                                                       i_uom_reference => i_uom_reference,
                                                       i_description   => l_ti_description);
        RETURN TRIM(l_description);
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
    END get_element_description;

    /**
    * Concatenate a list of descriptions using a delimiter that is defined in the cursor itself
    *
    * @param   p_cursor         Cursor with two fields: Description, Delimiter
    * @return  Returns the concatenated list
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.2
    * @since   21-06-2011
    */
    FUNCTION concat_element_list(p_cursor IN SYS_REFCURSOR) RETURN VARCHAR2 IS
        l_return VARCHAR2(32767);
        l_temp   VARCHAR2(32767);
        l_delim  VARCHAR2(32767);
        l_first  BOOLEAN := TRUE;
    BEGIN
    
        LOOP
            FETCH p_cursor
                INTO l_temp, l_delim;
            EXIT WHEN p_cursor%NOTFOUND;
            IF l_temp IS NOT NULL
            THEN
                IF l_first
                THEN
                    l_return := l_temp;
                    l_first  := FALSE;
                ELSE
                    l_return := l_return || l_delim || l_temp;
                END IF;
            END IF;
        END LOOP;
        CLOSE p_cursor;
    
        RETURN l_return;
    END concat_element_list;

    /**
    * Gets information about print list job related to Touch-option documentation
    * Used by print list
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_print_list_job  Print list job identifier, related to the documentation
    *
    * @return  t_rec_print_list_job Print list job information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/12/2014
    */
    FUNCTION tf_get_print_job_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_print_list_job IN print_list_job.id_print_list_job%TYPE
    ) RETURN t_rec_print_list_job IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'tf_get_print_job_info';
        l_params                pk_types.t_huge_byte;
        l_result                t_rec_print_list_job;
        l_context_data          print_list_job.context_data%TYPE;
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
    BEGIN
        l_params := 'Input arguments:';
        l_params := l_params || ' i_prof = ' || pk_utils.to_string(i_prof);
        l_params := l_params || ' i_id_print_list_job = ' || coalesce(to_char(i_id_print_list_job), '<null>');
        pk_alertlog.log_debug(text => l_params, object_name => g_package_name, sub_object_name => k_function_name);
    
        l_result := t_rec_print_list_job();
    
        g_error := 'get context data / ' || l_params;
        -- getting context data of this print list job
        SELECT v.context_data
          INTO l_context_data
          FROM v_print_list_context_data v
         WHERE v.id_print_list_job = i_id_print_list_job;
    
        -- getting information of this id_epis_documentation
        g_error                 := 'l_id_epis_documentation / ' || l_params;
        l_id_epis_documentation := to_number(l_context_data);
    
        g_error := 'l_id_epis_documentation  = ' || l_id_epis_documentation;
        -- Setting the output type
        SELECT i_id_print_list_job id_print_list_job,
               pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                 i_software => i_prof.software,
                                                 i_doc_area => ed.id_doc_area) area_name,
               pk_translation.get_translation(i_lang, k_code_doc_template || ed.id_doc_template) template_title
          INTO l_result.id_print_list_job, l_result.title_desc, l_result.subtitle_desc
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = l_id_epis_documentation;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM || ' / ' || g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name,
                                  owner           => g_package_owner);
            RETURN t_rec_print_list_job();
    END tf_get_print_job_info;

    /**
    * Compares if a print list job context data is similar to the array of print list jobs
    *
    * @param   i_lang                         Professional preferred language
    * @param   i_prof                         Professional identification and its context (institution and software)
    * @param   i_print_job_context_data       Print list job context data
    * @param   i_print_list_jobs              Array of print list job identifiers
    *
    * @return  table_number                   Array of print list jobs that are similar
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION tf_compare_print_jobs
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_print_job_context_data IN print_list_job.context_data%TYPE,
        i_print_list_jobs        IN table_number
    ) RETURN table_number IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'tf_compare_print_jobs';
        l_params pk_types.t_huge_byte;
        l_result table_number;
    BEGIN
        l_params := 'Input arguments:';
        l_params := l_params || ' i_prof = ' || pk_utils.to_string(i_prof);
        l_params := l_params || ' i_print_job_context_data = ' || coalesce(to_char(i_print_job_context_data), '<null>');
        l_params := l_params || ' i_print_list_jobs = ' || coalesce(pk_utils.to_string(i_print_list_jobs), '<null>');
        pk_alertlog.log_debug(text => l_params, object_name => g_package_name, sub_object_name => k_function_name);
    
        -- getting all id_print_list_jobs from i_print_list_jobs that have the same context_data (id_epis_documentation) as i_print_list_job
        SELECT t.id_print_list_job
          BULK COLLECT
          INTO l_result
          FROM (SELECT /*+opt_estimate (table t rows=1)*/
                 v2.id_print_list_job
                  FROM v_print_list_context_data v2
                  JOIN TABLE(CAST(i_print_list_jobs AS table_number)) t
                    ON t.column_value = v2.id_print_list_job
                 WHERE dbms_lob.compare(v2.context_data, i_print_job_context_data) = 0) t;
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM || ' / ' || g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => k_function_name,
                                  owner           => g_package_owner);
            RETURN table_number();
    END tf_compare_print_jobs;
    /**
    * Gets doc area info register
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_epis_anamn             Table number with id_epis_anamnesis        
    * @param i_epis_rev_sys           Table number with id_epis_review_systems        
    * @param i_epis_obs               Table number with id_epis_observation        
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist        
    * @param i_epis_recomend          Table number with id_epis_recomend        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)      
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/07/16
    */
    FUNCTION tf_get_doc_area_register
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_epis_doc      IN table_number,
        i_epis_anamn    IN table_number,
        i_epis_rev_sys  IN table_number,
        i_epis_obs      IN table_number,
        i_epis_past_fsh IN table_number,
        i_epis_recomend IN table_number,
        i_flg_show_fm   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_order         IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN t_tbl_doc_area_register IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'tf_get_doc_area_register';
        l_tbl_doc_area_reg t_tbl_doc_area_register;
        l_error            t_error_out;
    
    BEGIN
        pk_alertlog.log_debug('tf_get_doc_area_register:' || pk_utils.to_string(i_epis_doc));
        g_error := 'GET CURSOR o_doc_area_register';
        SELECT t_obj_doc_area_register(order_by_default,
                                       order_default,
                                       id_epis_documentation,
                                       PARENT,
                                       id_doc_template,
                                       template_desc,
                                       dt_creation,
                                       dt_creation_tstz,
                                       dt_register,
                                       id_professional,
                                       nick_name,
                                       desc_speciality,
                                       id_doc_area,
                                       flg_status,
                                       desc_status,
                                       id_episode,
                                       flg_current_episode,
                                       notes,
                                       dt_last_update,
                                       dt_last_update_tstz,
                                       flg_detail,
                                       flg_external,
                                       flg_type_register,
                                       flg_table_origin,
                                       flg_reviewed,
                                       id_prof_cancel,
                                       dt_cancel_tstz,
                                       id_cancel_reason,
                                       cancel_reason,
                                       cancel_notes,
                                       flg_edition_type,
                                       nick_name_prof_create,
                                       desc_speciality_prof_create,
                                       dt_clinical,
                                       dt_clinical_chr)
          BULK COLLECT
          INTO l_tbl_doc_area_reg
          FROM (SELECT /*+ index(ed epis_documentation(id_epis_documentation)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ed.dt_last_update_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 ed.id_epis_documentation,
                 ed.id_epis_documentation_parent PARENT,
                 ed.id_doc_template,
                 pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                 pk_date_utils.date_send_tsz(i_lang,
                                             (SELECT pk_touch_option_core.get_dt_create_ed(ed.id_epis_documentation)
                                                FROM dual),
                                             i_prof) dt_creation,
                 (SELECT pk_touch_option_core.get_dt_create_ed(ed.id_epis_documentation)
                    FROM dual) dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                 ed.id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang, i_prof, ed.id_professional, ed.dt_creation_tstz, ed.id_episode) desc_speciality,
                 ed.id_doc_area,
                 ed.flg_status,
                 decode(ed.flg_status,
                        pk_alert_constant.g_active,
                        NULL,
                        pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS', ed.flg_status, i_lang)) desc_status,
                 ed.id_episode,
                 decode(ed.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 ed.notes,
                 pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                 ed.dt_last_update_tstz,
                 pk_alert_constant.g_yes flg_detail,
                 pk_alert_constant.g_no flg_external,
                 decode(ed.id_doc_template, NULL, pk_summary_page.g_free_text, pk_summary_page.g_touch_option) flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin, -- Record has its origin in the epis_documentation table
                 pk_past_history.get_review_info(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_id_episode,
                                                 i_id_record_area => ed.id_epis_documentation,
                                                 i_flg_context    => pk_review.get_template_context()) flg_reviewed,
                 ed.id_prof_cancel,
                 ed.dt_cancel_tstz,
                 ed.id_cancel_reason,
                 decode(ed.flg_status,
                        pk_alert_constant.g_cancelled,
                        pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_id_cancel_reason => ed.id_cancel_reason),
                        NULL) cancel_reason,
                 ed.notes_cancel cancel_notes,
                 ed.flg_edition_type flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang,
                                                  i_prof,
                                                  (SELECT pk_touch_option_core.get_id_prof_create_ed(ed.id_epis_documentation)
                                                     FROM dual)) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  (SELECT pk_touch_option_core.get_id_prof_create_ed(ed.id_epis_documentation)
                                                     FROM dual),
                                                  ed.dt_creation_tstz,
                                                  ed.id_episode) desc_speciality_prof_create,
                 pk_date_utils.date_send_tsz(i_lang, ed.dt_clinical, i_prof) dt_clinical,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_clinical, i_prof.institution, i_prof.software) dt_clinical_chr
                  FROM epis_documentation ed
                  LEFT JOIN doc_template dt
                    ON ed.id_doc_template = dt.id_doc_template
                 WHERE (ed.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                   AND ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(i_epis_doc) t)
                
                UNION ALL
                -- Free-text entries for Complaint  HPI areas that were done out of Touch-option model (Old free-text entries)
                SELECT /* +index(ea epis_anamnesis(id_epis_anamnesis)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ea.dt_epis_anamnesis_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 ea.id_epis_anamnesis id_epis_documentation,
                 ea.id_epis_anamnesis_parent PARENT,
                 NULL id_doc_template,
                 NULL template_desc,
                 pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_creation,
                 ea.dt_epis_anamnesis_tstz dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof.institution, i_prof.software) dt_register,
                 ea.id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ea.id_professional,
                                                  ea.dt_epis_anamnesis_tstz,
                                                  ea.id_episode) desc_speciality,
                 decode(ea.flg_type,
                        pk_summary_page.g_epis_anam_flg_type_c,
                        pk_summary_page.g_doc_area_complaint,
                        pk_summary_page.g_doc_area_hist_ill) id_doc_area,
                 ea.flg_status flg_status,
                 decode(ea.flg_status,
                        g_active,
                        NULL,
                        pk_sysdomain.get_domain('EPIS_ANAMNESIS.FLG_STATUS', ea.flg_status, i_lang)) desc_status,
                 ea.id_episode,
                 decode(ea.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 ea.desc_epis_anamnesis notes,
                 pk_date_utils.date_send_tsz(i_lang, ea.dt_epis_anamnesis_tstz, i_prof) dt_last_update,
                 ea.dt_epis_anamnesis_tstz dt_last_update_tstz,
                 pk_alert_constant.g_no flg_detail,
                 pk_alert_constant.g_yes flg_external,
                 pk_summary_page.g_free_text flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_anamn flg_table_origin, -- Record has its origin in the epis_anamnesis table
                 NULL flg_reviewed,
                 NULL id_prof_cancel,
                 NULL dt_cancel_tstz,
                 NULL id_cancel_reason,
                 NULL cancel_reason,
                 NULL cancel_notes,
                 NULL flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ea.id_professional) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ea.id_professional,
                                                  ea.dt_epis_anamnesis_tstz,
                                                  ea.id_episode) desc_speciality_prof_create,
                 NULL dt_clinical,
                 NULL dt_clinical_chr
                  FROM epis_anamnesis ea
                 WHERE (i_doc_area IN (pk_summary_page.g_doc_area_complaint, pk_summary_page.g_doc_area_hist_ill) OR
                       i_doc_area IS NULL)
                   AND ea.id_epis_anamnesis IN (SELECT /* +opt_estimate(TABLE t rows = 1) */
                                                 t.column_value
                                                  FROM TABLE(i_epis_anamn) t)
                
                UNION ALL
                -- Free-text entries for Review of System area that were done out of Touch-option model (Old free-text entries)
                SELECT /* +index(ers epis_review_systems(id_epis_review_systems)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - ers.dt_creation_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 ers.id_epis_review_systems id_epis_documentation,
                 ers.id_epis_review_systems_parent PARENT,
                 NULL id_doc_template,
                 NULL template_desc,
                 pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_creation,
                 ers.dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, ers.dt_creation_tstz, i_prof.institution, i_prof.software) dt_register,
                 ers.id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ers.id_professional,
                                                  ers.dt_creation_tstz,
                                                  ers.id_episode) desc_speciality,
                 pk_summary_page.g_doc_area_rev_sys id_doc_area,
                 ers.flg_status flg_status,
                 decode(ers.flg_status,
                        g_active,
                        NULL,
                        pk_sysdomain.get_domain('EPIS_REVIEW_SYSTEMS.FLG_STATUS', ers.flg_status, i_lang)) desc_status,
                 ers.id_episode,
                 decode(ers.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 to_clob(ers.desc_review_systems) notes,
                 pk_date_utils.date_send_tsz(i_lang, ers.dt_creation_tstz, i_prof) dt_last_update,
                 ers.dt_creation_tstz dt_last_update_tstz,
                 pk_alert_constant.g_no flg_detail,
                 pk_alert_constant.g_yes flg_external,
                 pk_summary_page.g_free_text flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_rev_sys flg_table_origin, -- Record has its origin in the epis_review_systems table
                 NULL flg_reviewed,
                 NULL id_prof_cancel,
                 NULL dt_cancel_tstz,
                 NULL id_cancel_reason,
                 NULL cancel_reason,
                 NULL cancel_notes,
                 NULL flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ers.id_professional) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ers.id_professional,
                                                  ers.dt_creation_tstz,
                                                  ers.id_episode) desc_speciality_prof_create,
                 NULL dt_clinical,
                 NULL dt_clinical_chr
                  FROM epis_review_systems ers
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_rev_sys OR i_doc_area IS NULL)
                   AND ers.id_epis_review_systems IN (SELECT /* +opt_estimate(TABLE t rows = 1) */
                                                       t.column_value
                                                        FROM TABLE(i_epis_rev_sys) t)
                UNION ALL
                -- Free text entries for Physical Exam Physical Assessment areas that were done out of Touch-option model (Old free-text entries)
                SELECT /* +index(eo epis_observation(id_epis_observation)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - eo.dt_epis_observation_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 eo.id_epis_observation id_epis_documentation,
                 eo.id_epis_observation_parent PARENT,
                 NULL id_doc_template,
                 NULL template_desc,
                 pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_creation,
                 eo.dt_epis_observation_tstz dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof.institution, i_prof.software) dt_register,
                 eo.id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  eo.id_professional,
                                                  eo.dt_epis_observation_tstz,
                                                  eo.id_episode) desc_speciality,
                 
                 pk_summary_page.g_doc_area_phy_exam id_doc_area,
                 eo.flg_status flg_status,
                 decode(eo.flg_status,
                        g_active,
                        NULL,
                        pk_sysdomain.get_domain('EPIS_OBSERVATION.FLG_STATUS', eo.flg_status, i_lang)) desc_status,
                 eo.id_episode,
                 decode(eo.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 to_clob(eo.desc_epis_observation) notes,
                 pk_date_utils.date_send_tsz(i_lang, eo.dt_epis_observation_tstz, i_prof) dt_last_update,
                 eo.dt_epis_observation_tstz dt_last_update_tstz,
                 pk_alert_constant.g_no flg_detail,
                 pk_alert_constant.g_yes flg_external,
                 pk_summary_page.g_free_text flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_obs flg_table_origin, -- Record has its origin in the epis_observation table
                 NULL flg_reviewed,
                 NULL id_prof_cancel,
                 NULL dt_cancel_tstz,
                 NULL id_cancel_reason,
                 NULL cancel_reason,
                 NULL cancel_notes,
                 NULL flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, eo.id_professional) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  eo.id_professional,
                                                  eo.dt_epis_observation_tstz,
                                                  eo.id_episode) desc_speciality_prof_create,
                 NULL dt_clinical,
                 NULL dt_clinical_chr
                  FROM epis_observation eo
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_phy_exam OR i_doc_area IS NULL)
                   AND eo.id_epis_observation IN (SELECT /* +opt_estimate(TABLE t rows = 1) */
                                                   t.column_value
                                                    FROM TABLE(i_epis_obs) t)
                UNION ALL
                -- Free text entries for Past familiar  Social history areas that were done out of Touch-option model (Old free-text entries)
                SELECT /* +index(pfsh pat_fam_soc_hist(id_pat_fam_soc_hist)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - pfsh.dt_pat_fam_soc_hist_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 pfsh.id_pat_fam_soc_hist id_epis_documentation,
                 NULL PARENT,
                 NULL id_doc_template,
                 NULL template_desc,
                 pk_date_utils.date_send_tsz(i_lang, pfsh.dt_pat_fam_soc_hist_tstz, i_prof) dt_creation,
                 pfsh.dt_pat_fam_soc_hist_tstz dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, pfsh.dt_pat_fam_soc_hist_tstz, i_prof.institution, i_prof.software) dt_register,
                 pfsh.id_prof_write id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, pfsh.id_prof_write) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  pfsh.id_prof_write,
                                                  pfsh.dt_pat_fam_soc_hist_tstz,
                                                  pfsh.id_episode) desc_speciality,
                 decode(pfsh.flg_type,
                        pk_summary_page.g_alert_diag_type_fam,
                        pk_summary_page.g_doc_area_past_fam,
                        pk_summary_page.g_doc_area_past_soc) id_doc_area,
                 pfsh.flg_status flg_status,
                 pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pfsh.flg_status, i_lang) desc_status,
                 pfsh.id_episode,
                 decode(pfsh.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 to_clob(pfsh.notes) notes,
                 pk_date_utils.date_send_tsz(i_lang, pfsh.dt_pat_fam_soc_hist_tstz, i_prof) dt_last_update,
                 pfsh.dt_pat_fam_soc_hist_tstz dt_last_update_tstz,
                 pk_alert_constant.g_no flg_detail,
                 pk_alert_constant.g_yes flg_external,
                 pk_summary_page.g_free_text flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_past_fsh flg_table_origin,
                 NULL flg_reviewed,
                 NULL id_prof_cancel,
                 NULL dt_cancel_tstz,
                 NULL id_cancel_reason,
                 NULL cancel_reason,
                 NULL cancel_notes,
                 NULL flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, pfsh.id_prof_write) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  pfsh.id_prof_write,
                                                  pfsh.dt_pat_fam_soc_hist_tstz,
                                                  pfsh.id_episode) desc_speciality_prof_create,
                 NULL dt_clinical,
                 NULL dt_clinical_chr
                  FROM pat_fam_soc_hist pfsh
                 WHERE (i_doc_area IN (pk_summary_page.g_doc_area_past_fam, pk_summary_page.g_doc_area_past_soc) OR
                       i_doc_area IS NULL)
                   AND pfsh.id_pat_fam_soc_hist IN (SELECT /* +opt_estimate(TABLE t rows = 1) */
                                                     t.column_value
                                                      FROM TABLE(i_epis_past_fsh) t)
                UNION ALL
                --Discharge diagnosis of patient's family members to show in Past family history area
                 SELECT pfm.order_by_default,
                        pfm.order_default,
                        pfm.id_epis_documentation,
                        pfm.parent,
                        pfm.id_doc_template,
                        pfm.template_desc,
                        pfm.dt_creation,
                        pfm.dt_creation_tstz,
                        pfm.dt_register,
                        pfm.id_professional,
                        pfm.nick_name,
                        pfm.desc_speciality,
                        pfm.id_doc_area,
                        pfm.flg_status,
                        pfm.desc_status,
                        pfm.id_episode,
                        pfm.flg_current_episode,
                        pfm.notes,
                        pfm.dt_last_update,
                        pfm.dt_last_update_tstz,
                        pfm.flg_detail,
                        pfm.flg_external,
                        pfm.flg_type_register,
                        pfm.flg_table_origin,
                        NULL                      flg_reviewed,
                        NULL                      id_prof_cancel,
                        NULL                      dt_cancel_tstz,
                        NULL                      id_cancel_reason,
                        NULL                      cancel_reason,
                        NULL                      cancel_notes,
                        NULL                      flg_edition_type,
                        pfm.nick_name             nick_name_prof_create,
                        pfm.desc_speciality       desc_speciality_prof_create,
                        NULL                      dt_clinical,
                        NULL                      dt_clinical_chr
                   FROM TABLE(pk_diagnosis_core.tf_final_diag_pat_family_reg(i_lang, i_prof, i_id_episode, i_id_patient)) pfm
                  WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                    AND i_flg_show_fm = pk_alert_constant.g_yes
                 UNION ALL
                 --Surgeries done of patient's family members to show in Past family history area
                SELECT spf.order_by_default,
                       spf.order_default,
                       spf.id_epis_documentation,
                       spf.parent,
                       spf.id_doc_template,
                       spf.template_desc,
                       spf.dt_creation,
                       spf.dt_creation_tstz,
                       spf.dt_register,
                       spf.id_professional,
                       spf.nick_name,
                       spf.desc_speciality,
                       spf.id_doc_area,
                       spf.flg_status,
                       spf.desc_status,
                       spf.id_episode,
                       spf.flg_current_episode,
                       spf.notes,
                       spf.dt_last_update,
                       spf.dt_last_update_tstz,
                       spf.flg_detail,
                       spf.flg_external,
                       spf.flg_type_register,
                       spf.flg_table_origin,
                       NULL                      flg_reviewed,
                       NULL                      id_prof_cancel,
                       NULL                      dt_cancel_tstz,
                       NULL                      id_cancel_reason,
                       NULL                      cancel_reason,
                       NULL                      cancel_notes,
                       NULL                      flg_edition_type,
                       spf.nick_name             nick_name_prof_create,
                       spf.desc_speciality       desc_speciality_prof_create,
                       NULL                      dt_clinical,
                       NULL                      dt_clinical_chr
                  FROM TABLE(pk_sr_surg_record.tf_surgery_pat_family_reg(i_lang, i_prof, i_id_episode, i_id_patient)) spf
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                   AND i_flg_show_fm = pk_alert_constant.g_yes
                UNION ALL
                -- Free text entries for Subjective and Objective from Progress Notes(SOAP) & Nursing Notes(EDIS/PP/OUTP/CARE/ORIS) that were done out of Touch-option model        
                SELECT /* +index(er epis_recomend(id_epis_anamnesis)) */
                 decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - er.dt_epis_recomend_tstz) order_by_default,
                 trunc(SYSDATE) order_default,
                 er.id_epis_recomend id_epis_documentation,
                 er.id_epis_recomend_parent PARENT,
                 NULL id_doc_template,
                 NULL template_desc,
                 pk_date_utils.date_send_tsz(i_lang, er.dt_epis_recomend_tstz, i_prof) dt_creation,
                 er.dt_epis_recomend_tstz dt_creation_tstz,
                 pk_date_utils.date_char_tsz(i_lang, er.dt_epis_recomend_tstz, i_prof.institution, i_prof.software) dt_register,
                 er.id_professional,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) nick_name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  er.id_professional,
                                                  er.dt_epis_recomend_tstz,
                                                  er.id_episode) desc_speciality,
                 decode(er.flg_type,
                        pk_progress_notes.g_type_subjective,
                        pk_summary_page.g_doc_area_hist_ill,
                        pk_progress_notes.g_type_objective,
                        pk_summary_page.g_doc_area_phy_exam,
                        'N',
                        pk_summary_page.g_doc_area_nursing_notes) id_doc_area,
                 er.flg_status,
                 pk_sysdomain.get_domain('EPIS_DOCUMENTATION.FLG_STATUS', er.flg_status, i_lang) desc_status,
                 er.id_episode,
                 decode(er.id_episode, i_id_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                 er.desc_epis_recomend_clob notes,
                 pk_date_utils.date_send_tsz(i_lang, er.dt_epis_recomend_tstz, i_prof) dt_last_update,
                 er.dt_epis_recomend_tstz dt_last_update_tstz,
                 pk_alert_constant.g_no flg_detail,
                 pk_alert_constant.g_yes flg_external,
                 pk_summary_page.g_free_text flg_type_register,
                 pk_touch_option.g_flg_tab_origin_epis_recomend flg_table_origin, -- Record has its origin in the epis_recomend table
                 NULL flg_reviewed,
                 NULL id_prof_cancel,
                 NULL dt_cancel_tstz,
                 NULL id_cancel_reason,
                 NULL cancel_reason,
                 NULL cancel_notes,
                 NULL flg_edition_type,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) nick_name_prof_create,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  er.id_professional,
                                                  er.dt_epis_recomend_tstz,
                                                  er.id_episode) desc_speciality_prof_create,
                 NULL dt_clinical,
                 NULL dt_clinical_chr
                  FROM epis_recomend er
                 WHERE (i_doc_area IN (pk_summary_page.g_doc_area_hist_ill,
                                       pk_summary_page.g_doc_area_phy_exam,
                                       pk_summary_page.g_doc_area_nursing_notes) OR i_doc_area IS NULL)
                   AND er.id_epis_recomend IN (SELECT /* +opt_estimate(TABLE t rows = 1) */
                                                t.column_value
                                                 FROM TABLE(i_epis_recomend) t)
                
                 ORDER BY order_by_default);
    
        RETURN l_tbl_doc_area_reg;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END tf_get_doc_area_register;
    /**
    * Gets doc area values
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param o_error                  Error message        
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/07/16
    */

    FUNCTION tf_get_doc_area_val
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_epis_doc    IN table_number,
        i_flg_show_fm IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN t_tbl_doc_area_val IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'tf_get_doc_area_val';
        l_tbl_doc_area_val t_tbl_doc_area_val;
        l_error            t_error_out;
    
    BEGIN
    
        g_error := 'GET CURSOR o_doc_area_val';
        SELECT t_rec_doc_area_val(id_epis_documentation,
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
                                  internal_name,
                                  desc_quantifier,
                                  desc_quantification,
                                  desc_qualification,
                                  display_format,
                                  separator,
                                  flg_table_origin,
                                  flg_status,
                                  value_id,
                                  signature)
          BULK COLLECT
          INTO l_tbl_doc_area_val
          FROM (SELECT /*+ index(ed epis_documentation(id_epis_documentation)) */
                 ed.id_epis_documentation,
                 ed.id_epis_documentation_parent PARENT,
                 d.id_documentation,
                 d.id_doc_component,
                 decr.id_doc_element_crit,
                 pk_date_utils.date_send_tsz(i_lang, ed.dt_creation_tstz, i_prof) dt_reg,
                 TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                 dc.flg_type,
                 get_element_description(i_lang,
                                         i_prof,
                                         de.flg_type,
                                         edd.value,
                                         edd.value_properties,
                                         decr.id_doc_element_crit,
                                         de.id_unit_measure_reference,
                                         de.id_master_item,
                                         decr.code_element_close) desc_element,
                 TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
                 pk_touch_option.get_formatted_value(i_lang,
                                                     i_prof,
                                                     de.flg_type,
                                                     edd.value,
                                                     edd.value_properties,
                                                     de.input_mask,
                                                     de.flg_optional_value,
                                                     de.flg_element_domain_type,
                                                     de.code_element_domain,
                                                     edd.dt_creation_tstz) VALUE,
                 de.flg_type flg_type_element,
                 ed.id_doc_area,
                 dtad.rank rank_component,
                 de.rank rank_element,
                 de.internal_name,
                 pk_touch_option.get_epis_doc_quantifier(i_lang, edd.id_epis_documentation_det) desc_quantifier,
                 pk_touch_option.get_epis_doc_quantification(i_lang, edd.id_epis_documentation_det) desc_quantification,
                 pk_touch_option.get_epis_doc_qualification(i_lang, edd.id_epis_documentation_det) desc_qualification,
                 de.display_format,
                 de.separator,
                 pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
                 'A' flg_status, --TODO: Change this code, 
                 edd.value value_id,
                 pk_prof_utils.get_detail_signature(i_lang,
                                                    i_prof,
                                                    ed.id_episode,
                                                    ed.dt_last_update_tstz,
                                                    ed.id_prof_last_update) signature
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
                    ON dc.id_doc_component = d.id_doc_component
                 INNER JOIN doc_element_crit decr
                    ON decr.id_doc_element_crit = edd.id_doc_element_crit
                 INNER JOIN doc_element de
                    ON de.id_doc_element = decr.id_doc_element
                 WHERE (ed.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                   AND ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                     t.column_value
                                                      FROM TABLE(i_epis_doc) t)
                UNION ALL
                SELECT epis_d.id_epis_documentation,
                       NULL PARENT,
                       d.id_documentation,
                       dc.id_doc_component,
                       NULL id_doc_element_crit,
                       NULL dt_reg,
                       TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                       dc.flg_type,
                       NULL desc_element,
                       NULL desc_element_view,
                       NULL VALUE,
                       NULL flg_type_element,
                       epis_d.id_doc_area,
                       dtad.rank rank_component,
                       NULL rank_element,
                       NULL internal_name,
                       NULL desc_quantifier,
                       NULL desc_quantification,
                       NULL desc_qualification,
                       NULL display_format,
                       NULL separator,
                       pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
                       pk_alert_constant.g_active flg_status,
                       NULL value_id, --,
                       pk_prof_utils.get_detail_signature(i_lang,
                                                          i_prof,
                                                          NULL,
                                                          epis_d.dt_last_update_tstz,
                                                          epis_d.id_prof_last_update) signature
                  FROM documentation d
                 INNER JOIN doc_component dc
                    ON d.id_doc_component = dc.id_doc_component
                 INNER JOIN (SELECT DISTINCT ed.id_epis_documentation,
                                            ed.id_doc_template,
                                            ed.id_doc_area,
                                            d.id_documentation_parent,
                                            ed.id_prof_last_update,
                                            ed.dt_last_update_tstz
                              FROM documentation d
                             INNER JOIN epis_documentation_det edd
                                ON d.id_documentation = edd.id_documentation
                             INNER JOIN epis_documentation ed
                                ON edd.id_epis_documentation = ed.id_epis_documentation
                             INNER JOIN doc_element_crit decr
                                ON edd.id_doc_element_crit = decr.id_doc_element_crit
                             WHERE (ed.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                               AND ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                 t.column_value
                                                                  FROM TABLE(i_epis_doc) t)
                               AND d.flg_available = pk_touch_option.g_available
                               AND d.id_documentation_parent IS NOT NULL) epis_d
                    ON d.id_documentation = epis_d.id_documentation_parent
                 INNER JOIN doc_template_area_doc dtad
                    ON epis_d.id_doc_template = dtad.id_doc_template
                   AND epis_d.id_doc_area = dtad.id_doc_area
                   AND d.id_documentation = dtad.id_documentation
                 WHERE dc.flg_type = pk_summary_page.g_doc_title
                   AND dc.flg_available = pk_alert_constant.g_available
                   AND d.flg_available = pk_alert_constant.g_available
                UNION ALL
                --Discharge diagnosis of patient's family members to show in Past family history area
                 SELECT pfm.id_epis_documentation,
                        pfm.parent,
                        pfm.id_documentation,
                        pfm.id_doc_component,
                        pfm.id_doc_element_crit,
                        pfm.dt_reg,
                        pfm.desc_doc_component,
                        pfm.flg_type,
                        pfm.desc_element,
                        pfm.desc_element_view,
                        pfm.value,
                        pfm.flg_type_element,
                        pfm.id_doc_area,
                        pfm.rank_component,
                        pfm.rank_element,
                        NULL                                        internal_name,
                        pfm.desc_quantifier,
                        pfm.desc_quantification,
                        pfm.desc_qualification,
                        pfm.display_format,
                        pfm.separator,
                        pk_touch_option.g_flg_tab_origin_epis_diags flg_table_origin,
                        pk_alert_constant.g_active                  flg_status,
                        NULL                                        value_id,
                        NULL                                        signature
                   FROM TABLE(pk_diagnosis_core.tf_final_diag_pat_family_val(i_lang, i_prof, i_id_patient)) pfm
                  WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                    AND i_flg_show_fm = pk_alert_constant.g_yes
                 UNION ALL
                 --Surgeries done of patient's family members to show in Past family history area
                SELECT spf.id_epis_documentation,
                       spf.parent,
                       spf.id_documentation,
                       spf.id_doc_component,
                       spf.id_doc_element_crit,
                       spf.dt_reg,
                       spf.desc_doc_component,
                       spf.flg_type,
                       spf.desc_element,
                       spf.desc_element_view,
                       spf.value,
                       spf.flg_type_element,
                       spf.id_doc_area,
                       spf.rank_component,
                       spf.rank_element,
                       NULL                                         internal_name,
                       spf.desc_quantifier,
                       spf.desc_quantification,
                       spf.desc_qualification,
                       spf.display_format,
                       spf.separator,
                       pk_touch_option.g_flg_tab_origin_surg_record flg_table_origin,
                       pk_alert_constant.g_active                   flg_status,
                       NULL                                         value_id,
                       NULL                                         signature
                  FROM TABLE(pk_sr_surg_record.tf_surgery_pat_family_val(i_lang, i_prof, i_id_patient)) spf
                 WHERE (i_doc_area = pk_summary_page.g_doc_area_past_fam OR i_doc_area IS NULL)
                   AND i_flg_show_fm = pk_alert_constant.g_yes
                 ORDER BY id_epis_documentation, rank_component, rank_element);
    
        RETURN l_tbl_doc_area_val;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END tf_get_doc_area_val;

    /**
    * Adds documentation entries to the print list
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_id_epis_docs       List of epis_documentation identifiers to  be added to the print list
    * @param   i_print_arguments    List of print arguments necessary to print the jobs
    * @param   o_print_list_jobs    List of print list job identifiers
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION add_print_list_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_epis_docs    IN table_number,
        i_print_arguments IN table_varchar,
        o_print_list_job  OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'add_print_list_jobs';
        l_params           pk_types.t_huge_byte;
        l_context_data     table_clob;
        l_print_list_areas table_number;
    BEGIN
        l_params := 'Input arguments:';
        l_params := l_params || ' i_prof = ' || pk_utils.to_string(i_prof);
        l_params := l_params || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        l_params := l_params || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        l_params := l_params || ' i_id_epis_docs = ' || coalesce(pk_utils.to_string(i_id_epis_docs), '<null>');
        pk_alertlog.log_debug(text => l_params, object_name => g_package_name, sub_object_name => k_function_name);
    
        l_context_data     := table_clob();
        l_print_list_areas := table_number();
    
        -- getting context data
        IF i_id_epis_docs.count = 0
           OR i_id_epis_docs.count != i_print_arguments.count
        THEN
            g_error := 'Invalid parameters / ' || l_params;
            RAISE g_exception;
        END IF;
    
        l_context_data.extend(i_id_epis_docs.count);
        l_print_list_areas.extend(i_id_epis_docs.count);
        FOR i IN 1 .. i_id_epis_docs.count
        LOOP
            l_context_data(i) := to_clob(i_id_epis_docs(i));
            l_print_list_areas(i) := pk_print_list_db.g_print_list_area_touch_option;
        END LOOP;
    
        -- call function to add job to the print list
        g_error := 'Call pk_print_list_db.add_print_jobs / ' || l_params;
        RETURN pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_episode          => i_episode,
                                               i_print_list_areas => l_print_list_areas,
                                               i_context_data     => l_context_data,
                                               i_print_arguments  => i_print_arguments,
                                               o_print_list_jobs  => o_print_list_job,
                                               o_error            => o_error);
    
    EXCEPTION
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
    END add_print_list_jobs;

    /**
    * Removes documentation entry from print list (if exists)
    *
    * @param   i_lang               preferred language id for this professional
    * @param   i_prof               professional id structure
    * @param   i_patient            Patient identifier
    * @param   i_episode            Episode identifier
    * @param   i_epis_documentation Documentation ID
    * @param   o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    11/12/2014
    */
    FUNCTION remove_print_list_jobs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'remove_print_list_jobs';
        l_params             pk_types.t_huge_byte;
        l_id_print_list_jobs table_number;
        l_print_list_jobs    table_number;
        l_exception_np       EXCEPTION;
    BEGIN
        l_params := 'Input arguments:';
        l_params := l_params || ' i_prof = ' || pk_utils.to_string(i_prof);
        l_params := l_params || ' i_patient = ' || coalesce(to_char(i_patient), '<null>');
        l_params := l_params || ' i_episode = ' || coalesce(to_char(i_episode), '<null>');
        l_params := l_params || ' i_epis_documentation = ' || coalesce(to_char(i_epis_documentation), '<null>');
        pk_alertlog.log_debug(text => l_params, object_name => g_package_name, sub_object_name => k_function_name);
    
        -- getting id_print_list_job related to this referral
        g_error              := 'Call pk_print_list_db.get_similar_print_list_jobs / ' || l_params;
        l_id_print_list_jobs := pk_print_list_db.get_similar_print_list_jobs(i_lang                   => i_lang,
                                                                             i_prof                   => i_prof,
                                                                             i_patient                => i_patient,
                                                                             i_episode                => i_episode,
                                                                             i_print_list_area        => pk_print_list_db.g_print_list_area_touch_option,
                                                                             i_print_job_context_data => to_clob(i_epis_documentation));
    
        IF l_id_print_list_jobs IS NOT NULL
           AND l_id_print_list_jobs.count > 0
        THEN
            g_error := 'Call pk_print_list_db.set_print_jobs_cancel / ' || l_params;
            IF NOT pk_print_list_db.set_print_jobs_cancel(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_print_list_job => l_id_print_list_jobs,
                                                          o_id_print_list_job => l_print_list_jobs,
                                                          o_error             => o_error)
            
            THEN
                RAISE pk_touch_option_core.e_function_call_error;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_touch_option_core.e_function_call_error THEN
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'CONTEXT',
                                            value_in           => g_error);
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'PACKAGE',
                                            value_in           => g_package_name);
            pk_alert_exceptions.add_context(err_instance_id_in => o_error.err_instance_id_out,
                                            name_in            => 'METHOD',
                                            value_in           => k_function_name);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => k_function_name,
                                                     o_error    => o_error);
    END remove_print_list_jobs;

    /**
    * Gets print list completion options
    *
    * @param i_lang                  Language associated to the professional executing the request
    * @param i_prof                  Professional, institution and software identification
    * @param i_doc_area              Documentation area ID
    * @param o_options               Documentation completion options
    * @param o_flg_show_popup        Flag that indicates if the pop-up is shown or not. If not, default option is assumed
    * @param o_error                 An error message, set when return=false
    *
    * @value   o_flg_show_popup     {*} 'Y' the pop-up is shown 
    *                               {*} 'N' otherwise
    *    
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/12/2014
    */
    FUNCTION get_completion_options
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_options        OUT pk_types.cursor_type,
        o_flg_show_popup OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT pk_types.t_internal_name_byte := 'get_completion_options';
        -- Group of options displayed at conclusion popup
        k_syslist_completion_options CONSTANT sys_list_group.internal_name%TYPE := 'TOUCH_OPTION_COMPLETION_OPTIONS';
        -- Default completion option save
        k_config_default_option_save CONSTANT sys_config.id_sys_config%TYPE := 'TO_DEFAULT_COMPLETION_OPTION_SAVE';
    
        -- Enable/disable the visualization of completion popup in the Touch-option documentation area
        k_config_show_completion_popup CONSTANT sys_config.id_sys_config%TYPE := 'SHOW_CONCLUSION_POPUP_TOUCH_OPTION';
    
        k_compl_opt_save_print_list CONSTANT sys_list.internal_name%TYPE := 'SAVE_PRINT_LIST';
        k_compl_opt_save            CONSTANT sys_list.internal_name%TYPE := 'SAVE';
    
        l_show_concl_popup     sys_config.value%TYPE;
        l_default_option_save  sys_config.value%TYPE;
        l_default_print_option sys_list.internal_name%TYPE;
        l_can_add              VARCHAR2(1 CHAR);
    
        l_id_report reports.id_reports%TYPE;
        l_exception EXCEPTION;
        l_error     t_error_out;
        l_dummy     pk_types.t_low_char;
    BEGIN
    
        g_error := 'Get the report ID used in a documentation area';
        IF NOT pk_reports_api.get_id_report(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_epis_doc      => NULL,
                                            i_doc_area      => i_doc_area,
                                            o_id_report     => l_id_report,
                                            o_flg_available => l_dummy,
                                            o_error         => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_id_report IS NULL
        THEN
            -- No report available, so no print nor printing list available for this area, just save is available
            o_flg_show_popup := pk_alert_constant.g_no;
        
            OPEN o_options FOR
                SELECT tbl_opt.flg_context val_option,
                       tbl_opt.desc_list desc_option,
                       decode(tbl_opt.sys_list_internal_name, k_compl_opt_save, NULL, l_id_report) id_report,
                       decode(tbl_opt.sys_list_internal_name,
                              k_compl_opt_save,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) flg_default,
                       tbl_opt.rank rank,
                       decode(tbl_opt.sys_list_internal_name,
                              k_compl_opt_save,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) flg_available
                  FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_internal_name => k_syslist_completion_options)) tbl_opt;
        
            RETURN TRUE;
        END IF;
    
        g_error            := 'Get configuration value - SHOW_CONCLUSION_POPUP_TOUCH_OPTION';
        l_show_concl_popup := nvl(pk_sysconfig.get_config(i_code_cf => k_config_show_completion_popup, i_prof => i_prof),
                                  pk_alert_constant.g_yes);
    
        g_error               := 'Get configuration value - TO_DEFAULT_COMPLETION_OPTION_SAVE';
        l_default_option_save := nvl(pk_sysconfig.get_config(i_code_cf => k_config_default_option_save,
                                                             i_prof    => i_prof),
                                     pk_alert_constant.g_yes);
    
        -- Verify if patient have permissions to add to the printing list
        g_error := 'Call PK_PRINT_LIST_DB.CHECK_FUNC_CAN_ADD';
        IF NOT pk_print_list_db.check_func_can_add(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   o_flg_can_add => l_can_add,
                                                   o_error       => o_error)
        THEN
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
    
        -- getting default option of print list configured in sys_list data model
        g_error := 'Call PK_PRINT_LIST_DB.GET_PRINT_LIST_DEF_OPTION';
        IF NOT pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_print_list_area => pk_print_list_db.g_print_list_area_touch_option,
                                                          o_default_option  => l_default_print_option,
                                                          o_error           => o_error)
        THEN
        
            RAISE pk_touch_option_core.e_function_call_error;
        END IF;
    
        -- If exists a default "Save" option configured in sys_config 
        -- this setting overrides the default behaviour of the print list
        IF l_default_option_save = pk_alert_constant.g_yes
        THEN
            l_default_print_option := k_compl_opt_save;
        END IF;
    
        g_error := 'Get completion options';
        OPEN o_options FOR
            SELECT tbl_opt.flg_context val_option,
                   tbl_opt.desc_list desc_option,
                   decode(tbl_opt.sys_list_internal_name, k_compl_opt_save, NULL, l_id_report) id_report,
                   decode(tbl_opt.sys_list_internal_name,
                          l_default_print_option,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_default,
                   tbl_opt.rank rank,
                   decode(tbl_opt.sys_list_internal_name,
                          k_compl_opt_save_print_list,
                          decode(l_can_add, pk_alert_constant.g_yes, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                          pk_alert_constant.g_yes) flg_available
              FROM TABLE(pk_sys_list.tf_sys_list_values(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_internal_name => k_syslist_completion_options)) tbl_opt;
    
        o_flg_show_popup := l_show_concl_popup;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END get_completion_options;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_id_episode         episode id
    * @param i_id_doc_area        doc_area id
    * @param o_epis_document_val  array with detail current information details
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Nuno Alves
    * @version                    1.0   
    * @since                      2015/01/06
    ********************************************************************************************/
    FUNCTION get_epis_docum_det_pn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_area_desc   IN sys_message.desc_message%TYPE,
        o_history     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(30) := 'GET_EPIS_DOCUM_DET_PN';
    
        -- Blocks info (each template) 
        l_doc_area_register     t_cur_doc_area_register;
        l_doc_area_register_row pk_touch_option.t_rec_doc_area_register;
        l_doc_area_register_tab pk_touch_option.t_coll_doc_area_register;
    
        l_blocks_count NUMBER;
    
        -- All records from each block (mapped by id_epis_documentation)
        l_doc_area_val     pk_types.cursor_type;
        l_doc_area_val_row pk_touch_option.t_rec_doc_area_val;
        l_doc_area_val_tab pk_touch_option.t_coll_doc_area_val;
    
        -- Needed for pk_touch_option.get_doc_area_value_internal API output
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    
        l_label sys_message.desc_message%TYPE;
        l_value CLOB;
    
        e_doc_area_value_ids EXCEPTION;
        e_doc_area_value     EXCEPTION;
        e_scales_list        EXCEPTION;
        e_doc_not_register   EXCEPTION;
    
        l_order_by sys_config.value%TYPE;
    
        -- id_epis_documentation table_number from pk_touch_option.get_doc_area_value_ids
        l_coll_epis_doc table_number;
        -- Needed for pk_touch_option.get_doc_area_value_ids API output
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
        l_id_patient patient.id_patient%TYPE;
    
        -- Labels ********************************************************************
        l_cancel_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M072');
        l_cancel_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M073');
        l_documented    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_updated       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'EDIS_CHIEF_COMPLAINT_T009');
    
        l_doc_area_desc sys_message.desc_message%TYPE := i_area_desc;
        -- ***************************************************************************
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => k_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_IDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => table_number(i_id_doc_area),
                                                      i_scope              => table_number(i_id_episode),
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_order              => l_order_by,
                                                      i_fltr_start_date    => NULL,
                                                      i_fltr_end_date      => NULL,
                                                      i_paging             => pk_alert_constant.g_no,
                                                      i_start_record       => NULL,
                                                      i_num_records        => NULL,
                                                      o_record_count       => l_blocks_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        
        THEN
            RAISE e_doc_area_value_ids;
        END IF;
    
        g_error := 'CALL pk_episode.get_id_patient: i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => i_id_doc_area,
                                                           i_epis_doc           => l_coll_epis_doc,
                                                           i_epis_anamn         => NULL,
                                                           i_epis_rev_sys       => NULL,
                                                           i_epis_obs           => NULL,
                                                           i_epis_past_fsh      => NULL,
                                                           i_epis_recomend      => NULL,
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           i_order              => l_order_by,
                                                           o_doc_area_register  => l_doc_area_register,
                                                           o_doc_area_val       => l_doc_area_val,
                                                           o_template_layouts   => l_template_layouts,
                                                           o_doc_area_component => l_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE e_doc_area_value;
        END IF;
    
        g_error := 'fetch o_doc_area_register cursor';
        FETCH l_doc_area_register BULK COLLECT
            INTO l_doc_area_register_tab;
    
        g_error := 'Initialize history table';
        pk_edis_hist.init_vars;
    
        -- The magic happens here
        FOR i IN l_doc_area_register_tab.first .. l_doc_area_register_tab.last
        LOOP
            IF l_doc_area_register_tab(i).flg_status <> pk_touch_option.g_epis_bartchart_out
            THEN
                g_error := 'Create a new line in history table with current history record ';
                pk_edis_hist.add_line(i_history        => l_doc_area_register_tab(i).id_epis_documentation,
                                      i_dt_hist        => l_doc_area_register_tab(i).dt_creation_tstz,
                                      i_record_state   => l_doc_area_register_tab(i).flg_status,
                                      i_desc_rec_state => l_doc_area_register_tab(i).desc_status);
            
                g_error := 'Add title';
                pk_edis_hist.add_value(i_label => l_doc_area_desc,
                                       i_value => CASE
                                                      WHEN l_doc_area_register_tab(i).flg_status = pk_alert_constant.g_cancelled THEN
                                                       ' (' || l_doc_area_register_tab(i).desc_status || ')'
                                                      ELSE
                                                       ' '
                                                  END,
                                       i_type  => pk_edis_hist.g_type_title);
            
                l_value := l_doc_area_register_tab(i).template_desc || chr(10) || '  ' ||
                            REPLACE(REPLACE(pk_touch_option_core.get_plain_text_entry(i_lang               => i_lang,
                                                                                                                i_prof               => i_prof,
                                                                                                                i_epis_documentation => l_doc_area_register_tab(i).id_epis_documentation,
                                                                                                                i_use_html_format    => pk_alert_constant.g_yes),
                                                                      chr(13),
                                                                      chr(10)),
                                                              chr(10),
                                                              chr(10) || '  ');
            
                pk_edis_hist.add_value_if_not_null(i_label => CASE
                                                                  WHEN l_doc_area_register_tab(i)
                                                                   .flg_type_register = pk_touch_option.g_documentation_n THEN
                                                                   pk_message.get_message(i_lang      => i_lang,
                                                                                          i_prof      => i_prof,
                                                                                          i_code_mess => 'DOCUMENTATION_M054')
                                                                  ELSE
                                                                   pk_message.get_message(i_lang      => i_lang,
                                                                                          i_prof      => i_prof,
                                                                                          i_code_mess => 'DOCUMENTATION_M040')
                                                              END,
                                                   i_value => l_value,
                                                   i_type  => pk_edis_hist.g_type_content);
            
                --Cancel reasons
                IF l_doc_area_register_tab(i).flg_status = pk_alert_constant.g_cancelled
                THEN
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                       i_value => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                          i_prof             => i_prof,
                                                                                                          i_id_cancel_reason => l_doc_area_register_tab(i).id_cancel_reason),
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                       i_value => l_doc_area_register_tab(i).cancel_notes,
                                                       i_type  => pk_edis_hist.g_type_content);
                END IF;
            
                g_error := 'Add signature';
                pk_edis_hist.add_value(i_label => CASE
                                                      WHEN l_doc_area_register_tab(i)
                                                       .parent IS NOT NULL
                                                            OR l_doc_area_register_tab(i).flg_status = pk_alert_constant.g_cancelled THEN
                                                       l_updated
                                                      ELSE
                                                       l_documented
                                                  END,
                                       i_value => CASE
                                                      WHEN l_doc_area_register_tab(i).flg_status = pk_alert_constant.g_cancelled THEN
                                                       pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                        i_prof    => i_prof,
                                                                                        i_prof_id => l_doc_area_register_tab(i).id_prof_cancel) || '; ' ||
                                                       pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                   i_date => l_doc_area_register_tab(i).dt_cancel_tstz,
                                                                                   i_inst => i_prof.institution,
                                                                                   i_soft => i_prof.software)
                                                      ELSE
                                                       l_doc_area_register_tab(i).nick_name || '; ' || l_doc_area_register_tab(i).dt_register
                                                  END,
                                       i_type  => pk_edis_hist.g_type_signature);
            
                IF i <> l_doc_area_register_tab.last
                THEN
                    g_error := ' Add white line';
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_white_line);
                END IF;
            END IF;
        END LOOP;
    
        -- The output must be in this format
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_docum_det_pn;

    /********************************************************************************************
    * Detalhe de uma área(doc_area) de um episódio. 
    *
    * @param i_lang               language id
    * @param i_prof               professional, software and institution ids
    * @param i_id_episode         episode id
    * @param i_id_doc_area        doc_area id
    * @param o_epis_document_val  array with detail current information details
    * @param o_error              Error message
    *                        
    * @return                     true or false on success or error
    *
    * @author                     Nuno Alves
    * @version                    1.0   
    * @since                      2015/01/06
    ********************************************************************************************/
    FUNCTION get_epis_docum_det_pn_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_history     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(30) := 'GET_EPIS_DOCUM_DET_PN';
    
        -- Number of Blocks
        l_blocks_count NUMBER;
        -- Blocks info (each template) 
        l_doc_area_register         t_cur_doc_area_register;
        l_doc_area_register_row     pk_touch_option.t_rec_doc_area_register;
        l_doc_area_register_row_aux pk_touch_option.t_rec_doc_area_register;
        l_doc_area_register_tab     pk_touch_option.t_coll_doc_area_register;
    
        tb_tree_ids  table_number;
        l_add_record CHAR(1);
    
        -- Number of records
        l_block_record_count NUMBER;
        -- All records from each block (mapped by id_epis_documentation)
        l_doc_area_val     pk_types.cursor_type;
        l_doc_area_val_row pk_touch_option.t_rec_doc_area_val;
        l_doc_area_val_tab pk_touch_option.t_coll_doc_area_val;
    
        -- Needed for pk_touch_option.get_doc_area_value_internal API output
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    
        l_label sys_message.desc_message%TYPE;
        l_value CLOB;
    
        l_counter NUMBER := 1;
    
        e_doc_area_value_ids EXCEPTION;
        e_doc_area_value     EXCEPTION;
    
        l_order_by sys_config.value%TYPE;
    
        -- id_epis_documentation table_number from pk_touch_option.get_doc_area_value_ids
        l_coll_epis_doc table_number;
        -- Needed for pk_touch_option.get_doc_area_value_ids API output
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
        l_id_patient patient.id_patient%TYPE;
    
        -- Labels ********************************************************************
        l_cancel_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M072');
        l_cancel_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M073');
        l_documented    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_updated       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'EDIS_CHIEF_COMPLAINT_T009');
        l_cancellation  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_T032');
        l_creation      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_T030');
        l_edition       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_T029');
        -- ***************************************************************************
    BEGIN
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => k_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_IDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => table_number(i_id_doc_area),
                                                      i_scope              => table_number(i_id_episode),
                                                      i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                      i_order              => l_order_by,
                                                      i_fltr_start_date    => NULL,
                                                      i_fltr_end_date      => NULL,
                                                      i_paging             => pk_alert_constant.g_no,
                                                      i_start_record       => NULL,
                                                      i_num_records        => NULL,
                                                      o_record_count       => l_blocks_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        
        THEN
            RAISE e_doc_area_value_ids;
        END IF;
    
        g_error := 'CALL pk_episode.get_id_patient: i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => i_id_doc_area,
                                                           i_epis_doc           => l_coll_epis_doc,
                                                           i_epis_anamn         => NULL,
                                                           i_epis_rev_sys       => NULL,
                                                           i_epis_obs           => NULL,
                                                           i_epis_past_fsh      => NULL,
                                                           i_epis_recomend      => NULL,
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           i_order              => l_order_by,
                                                           o_doc_area_register  => l_doc_area_register,
                                                           o_doc_area_val       => l_doc_area_val,
                                                           o_template_layouts   => l_template_layouts,
                                                           o_doc_area_component => l_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE e_doc_area_value;
        END IF;
    
        -- Fill l_doc_area_register_tab with l_doc_area_register cursor records
        -- duplicate cancelled records and mark one of them as OUTDATED (when cancelling templates only the flg_status is updated)
        l_doc_area_register_tab := pk_touch_option.t_coll_doc_area_register();
        l_counter               := 1;
        LOOP
            FETCH l_doc_area_register
                INTO l_doc_area_register_row;
            EXIT WHEN l_doc_area_register%NOTFOUND;
            IF l_doc_area_register_row.flg_status = pk_alert_constant.g_cancelled
            THEN
                l_doc_area_register_row_aux                  := l_doc_area_register_row;
                l_doc_area_register_row_aux.parent           := l_doc_area_register_row.id_epis_documentation;
                l_doc_area_register_row_aux.flg_edition_type := 'E';
            
                l_doc_area_register_row.flg_status       := pk_touch_option.g_epis_bartchart_out;
                l_doc_area_register_row.id_prof_cancel   := NULL;
                l_doc_area_register_row.dt_cancel_tstz   := NULL;
                l_doc_area_register_row.id_cancel_reason := NULL;
                l_doc_area_register_row.cancel_notes     := NULL;
                l_doc_area_register_tab.extend;
                l_doc_area_register_tab(l_counter) := l_doc_area_register_row_aux;
                l_counter := l_counter + 1;
            END IF;
            l_doc_area_register_tab.extend;
            l_doc_area_register_tab(l_counter) := l_doc_area_register_row;
            l_counter := l_counter + 1;
        END LOOP;
        CLOSE l_doc_area_register;
    
        g_error := 'Initialize history table';
        pk_edis_hist.init_vars;
    
        -- The magic happens here
        FOR i IN l_doc_area_register_tab.first .. l_doc_area_register_tab.last
        LOOP
            -- Creation records are identified by flg_edition_type ('N' for new ones and 'U' for the copy, review and update)
            IF l_doc_area_register_tab(i)
             .flg_edition_type IN (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_update)
            THEN
                tb_tree_ids := table_number();
                BEGIN
                    SELECT aux.tb_ids
                      INTO tb_tree_ids
                      FROM (SELECT pk_utils.str_split_n(substr(sys_connect_by_path(ed.id_epis_documentation, ','), 2),
                                                        ',') tb_ids,
                                   connect_by_isleaf isleaf
                              FROM epis_documentation ed
                             WHERE ed.id_episode = i_id_episode
                            CONNECT BY ed.id_epis_documentation_parent = PRIOR ed.id_epis_documentation
                                   AND ed.flg_edition_type <> pk_touch_option.g_flg_edition_type_update
                             START WITH ed.id_epis_documentation = l_doc_area_register_tab(i).id_epis_documentation) aux
                     WHERE aux.isleaf = 1
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        tb_tree_ids := table_number();
                END;
            
                FOR j IN l_doc_area_register_tab.first .. l_doc_area_register_tab.last
                LOOP
                    l_add_record := pk_alert_constant.g_no;
                    FOR rec IN (SELECT *
                                  FROM TABLE(tb_tree_ids))
                    LOOP
                        IF rec.column_value = l_doc_area_register_tab(j).id_epis_documentation
                        THEN
                            l_add_record := pk_alert_constant.g_yes;
                        END IF;
                    END LOOP;
                
                    IF l_add_record = pk_alert_constant.g_yes
                    THEN
                        g_error := 'Create a new line in history table with current history record ';
                        pk_edis_hist.add_line(i_history        => l_doc_area_register_tab(j).id_epis_documentation,
                                              i_dt_hist        => l_doc_area_register_tab(j).dt_creation_tstz,
                                              i_record_state   => l_doc_area_register_tab(j).flg_status,
                                              i_desc_rec_state => l_doc_area_register_tab(j).desc_status);
                    
                        g_error := 'Add title';
                        pk_edis_hist.add_value(i_label => CASE
                                                              WHEN l_doc_area_register_tab(j).flg_edition_type IN
                                                                    (pk_touch_option.g_flg_edition_type_new,
                                                                     pk_touch_option.g_flg_edition_type_update) THEN
                                                               l_creation
                                                              WHEN l_doc_area_register_tab(j).flg_status = pk_alert_constant.g_cancelled THEN
                                                               l_cancellation
                                                              ELSE
                                                               l_edition
                                                          END,
                                               i_value => ' ',
                                               i_type  => pk_edis_hist.g_type_title);
                    
                        l_value := REPLACE(REPLACE(pk_touch_option_core.get_plain_text_entry(i_lang               => i_lang,
                                                                                             i_prof               => i_prof,
                                                                                             i_epis_documentation => l_doc_area_register_tab(j).id_epis_documentation,
                                                                                             i_use_html_format    => pk_alert_constant.g_yes),
                                                   chr(13),
                                                   chr(10)),
                                           chr(10),
                                           chr(10) || '  ');
                    
                        pk_edis_hist.add_value_if_not_null(i_label => CASE
                                                                          WHEN l_doc_area_register_tab(j)
                                                                           .flg_type_register = pk_touch_option.g_documentation_n THEN
                                                                           pk_message.get_message(i_lang      => i_lang,
                                                                                                  i_prof      => i_prof,
                                                                                                  i_code_mess => 'DOCUMENTATION_M054')
                                                                          ELSE
                                                                           pk_message.get_message(i_lang      => i_lang,
                                                                                                  i_prof      => i_prof,
                                                                                                  i_code_mess => 'DOCUMENTATION_M040')
                                                                      END,
                                                           i_value => l_doc_area_register_tab(j).template_desc || chr(10) || '  ' || l_value,
                                                           i_type  => pk_edis_hist.g_type_content);
                    
                        --Cancelled records
                        IF l_doc_area_register_tab(j).flg_status = pk_alert_constant.g_cancelled
                        THEN
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                               i_value => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                                  i_prof             => i_prof,
                                                                                                                  i_id_cancel_reason => l_doc_area_register_tab(j).id_cancel_reason),
                                                               i_type  => pk_edis_hist.g_type_content);
                        
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                               i_value => l_doc_area_register_tab(j).cancel_notes,
                                                               i_type  => pk_edis_hist.g_type_content);
                        
                            g_error := 'Add signature';
                            pk_edis_hist.add_value(i_label => l_documented,
                                                   i_value => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                               i_prof    => i_prof,
                                                                                               i_prof_id => l_doc_area_register_tab(j).id_prof_cancel) || '; ' ||
                                                              pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                                          i_date => l_doc_area_register_tab(j).dt_cancel_tstz,
                                                                                          i_inst => i_prof.institution,
                                                                                          i_soft => i_prof.software),
                                                   i_type  => pk_edis_hist.g_type_signature);
                            -- other
                        ELSE
                            g_error := 'Add signature';
                            pk_edis_hist.add_value(i_label => l_documented,
                                                   i_value => l_doc_area_register_tab(j).nick_name || '; ' || l_doc_area_register_tab(j).dt_register,
                                                   i_type  => pk_edis_hist.g_type_signature);
                        END IF;
                    
                        g_error := 'Add empty line';
                        pk_edis_hist.add_value(i_label => NULL,
                                               i_value => NULL,
                                               i_type  => pk_edis_hist.g_type_empty_line);
                    
                        IF l_doc_area_register_tab(j)
                         .flg_edition_type NOT IN
                            (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_update) -- creation or copy and review records, no slash line
                        THEN
                            g_error := 'Add slash line';
                            pk_edis_hist.add_value(i_label => NULL,
                                                   i_value => NULL,
                                                   i_type  => pk_edis_hist.g_type_slash_line);
                        END IF;
                        IF i <> l_doc_area_register_tab.last
                           AND l_doc_area_register_tab(j)
                          .flg_edition_type IN
                           (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_update)
                        THEN
                            g_error := ' Add white line';
                            pk_edis_hist.add_value(i_label => NULL,
                                                   i_value => NULL,
                                                   i_type  => pk_edis_hist.g_type_white_line);
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        -- The output must be in this format
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(l_doc_area_component);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_function_name,
                                              o_error);
            RETURN FALSE;
    END get_epis_docum_det_pn_hist;

    FUNCTION get_doc_element_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN doc_element.flg_type%TYPE,
        i_value             IN epis_documentation_det.value%TYPE,
        i_id_content        IN doc_element_crit.id_content%TYPE,
        i_mask              IN VARCHAR2 DEFAULT NULL,
        i_doc_element       IN doc_element.id_doc_element%TYPE DEFAULT NULL,
        i_doc_comp_internal IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal IN doc_element.internal_name%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_value            VARCHAR2(4000 CHAR);
        l_value_parts      table_varchar2;
        l_int_name_elem_99 table_varchar := table_varchar();
        l_si_99            NUMBER := 99;
    BEGIN
        CASE
            WHEN i_flg_type = g_elem_flg_type_comp_date THEN
                l_value_parts := pk_utils.str_split(i_value, '|');
                l_value       := to_char(to_timestamp(l_value_parts(1), l_value_parts(2)),
                                         nvl(i_mask, 'YYYYMMDDHH24MISS'));
            WHEN i_flg_type IN (g_elem_flg_type_comp_numeric,
                                g_elem_flg_type_simple_number,
                                g_elem_flg_type_text,
                                g_elem_flg_type_comp_text) THEN
                l_value := i_value;
            WHEN i_doc_elem_internal IN (pk_delivery.g_int_name_survivor_si,
                                         pk_delivery.g_int_name_born_alive_si,
                                         pk_delivery.g_int_name_born_death_si,
                                         pk_delivery.g_int_name_pregn_num_si) THEN
                l_value := l_si_99;
            WHEN i_doc_comp_internal = pk_delivery.g_int_name_prev_alive THEN
                CASE i_doc_elem_internal
                    WHEN pk_delivery.g_int_name_prev_alive_y THEN
                        l_value := 1;
                    WHEN pk_delivery.g_int_name_prev_alive_n THEN
                        l_value := 2;
                    WHEN pk_delivery.g_int_name_prev_alive_si THEN
                        l_value := 9;
                    WHEN pk_delivery.g_int_name_prev_alive_ne THEN
                        l_value := 8;
                    ELSE
                        l_value := 0;
                END CASE;
            WHEN i_doc_comp_internal = pk_delivery.g_int_name_prev_cond THEN
                CASE i_doc_elem_internal
                    WHEN pk_delivery.g_int_name_prev_cond_viv THEN
                        l_value := 1;
                    WHEN pk_delivery.g_int_name_prev_cond_mue THEN
                        l_value := 2;
                    WHEN pk_delivery.g_int_name_prev_cond_no THEN
                        l_value := 3;
                    WHEN pk_delivery.g_int_name_prev_cond_ne THEN
                        l_value := 8;
                    WHEN pk_delivery.g_int_name_prev_cond_si THEN
                        l_value := 9;
                END CASE;
            WHEN i_doc_comp_internal = pk_delivery.g_int_prenatal_trim THEN
                CASE i_doc_elem_internal
                    WHEN pk_delivery.g_int_prenatal_trim_1 THEN
                        l_value := 1;
                    WHEN pk_delivery.g_int_prenatal_trim_2 THEN
                        l_value := 2;
                    WHEN pk_delivery.g_int_prenatal_trim_3 THEN
                        l_value := 3;
                    WHEN pk_delivery.g_int_prenatal_trim_ne THEN
                        l_value := 8;
                    WHEN pk_delivery.g_int_prenatal_trim_si THEN
                        l_value := 9;
                END CASE;
            WHEN i_doc_comp_internal = pk_delivery.g_int_prenatal_aten THEN
                CASE i_doc_elem_internal
                    WHEN pk_delivery.g_int_prenatal_aten_s THEN
                        l_value := 1;
                    WHEN pk_delivery.g_int_prenatal_aten_n THEN
                        l_value := 2;
                    WHEN pk_delivery.g_int_prenatal_aten_ne THEN
                        l_value := 8;
                    WHEN pk_delivery.g_int_prenatal_aten_si THEN
                        l_value := 9;
                END CASE;
            WHEN i_flg_type = g_elem_flg_type_mchoice_single THEN
                --HIJO_ANTE
                IF i_doc_element = 2788771
                THEN
                    CASE i_value
                        WHEN '1' THEN
                            l_value := 'A';
                        WHEN '2' THEN
                            l_value := 'D';
                        WHEN '3' THEN
                            l_value := 'AS';
                        WHEN '8' THEN
                            l_value := 'NE';
                        WHEN '9' THEN
                            l_value := 'SI';
                        ELSE
                            l_value := i_value;
                    END CASE;
                    --VIVE_AUN
                ELSIF i_doc_element = 2788772
                THEN
                    CASE i_value
                        WHEN '0' THEN
                            l_value := 'NA';
                        WHEN '1' THEN
                            l_value := 'Y';
                        WHEN '2' THEN
                            l_value := 'N';
                        WHEN '8' THEN
                            l_value := 'NE';
                        WHEN '9' THEN
                            l_value := 'I';
                        ELSE
                            l_value := i_value;
                    END CASE;
                ELSE
                    CASE
                        WHEN i_value IN ('1', 'S') THEN
                            l_value := 'Y';
                        WHEN i_value IN ('2', 'N') THEN
                            l_value := 'N';
                        WHEN i_value IN ('3', 'NE') THEN
                            l_value := 'NE';
                        WHEN i_value = 'SE' THEN
                            l_value := 'SI';
                        ELSE
                            l_value := i_value;
                    END CASE;
                END IF;
            ELSE
                l_value := i_id_content;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_ret       BOOLEAN;
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_ELEMENT_VALUE');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            
            END;
        
    END get_doc_element_value;

    PROCEDURE get_dais_cfg_vars
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_summary_page IN summary_page.id_summary_page%TYPE,
        o_market       OUT institution.id_market%TYPE,
        o_inst         OUT institution.id_institution%TYPE,
        o_soft         OUT software.id_software%TYPE
    ) IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DAIS_CFG_VARS';
        --
        l_inst_market institution.id_market%TYPE;
    BEGIN
        g_error := 'Getting the default market';
        pk_alertlog.log_debug(g_error);
        l_inst_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        BEGIN
            g_error := 'GET DOC_AREA_INST_SOFT CFG_VARS';
            pk_alertlog.log_debug(g_error);
            SELECT id_market, id_institution, id_software
              INTO o_market, o_inst, o_soft
              FROM (SELECT nvl(dais.id_market, 0) id_market,
                           dais.id_institution,
                           dais.id_software,
                           row_number() over(ORDER BY decode(dais.id_market, l_inst_market, 1, 2), --
                           decode(dais.id_institution, i_prof.institution, 1, 2), --
                           decode(dais.id_software, i_prof.software, 1, 2)) line_number
                      FROM doc_area_inst_soft dais
                      JOIN summary_page_section sps
                        ON dais.id_doc_area = sps.id_doc_area
                     WHERE sps.id_summary_page = i_summary_page
                       AND dais.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND dais.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND nvl(dais.id_market, 0) IN (pk_alert_constant.g_id_market_all, l_inst_market))
             WHERE line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_market := l_inst_market;
                o_inst   := i_prof.institution;
                o_soft   := i_prof.software;
        END;
    END get_dais_cfg_vars;

    FUNCTION get_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_type           IN doc_element.flg_type%TYPE,
        i_value              IN epis_documentation_det.value%TYPE,
        i_id_content         IN doc_element_crit.id_content%TYPE,
        i_mask               IN VARCHAR2 DEFAULT NULL,
        i_doc_comp_internal  IN documentation.internal_name%TYPE DEFAULT NULL,
        i_doc_elem_internal  IN doc_element.internal_name%TYPE DEFAULT NULL,
        i_show_internal      IN VARCHAR2 DEFAULT NULL,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_show_id_content    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_doc_title     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_value       VARCHAR2(4000 CHAR);
        l_value_parts table_varchar2;
        l_error_out   t_error_out;
    BEGIN
        CASE
            WHEN i_flg_type = pk_touch_option.g_elem_flg_type_comp_date THEN
                l_value_parts := pk_utils.str_split(i_value, '|');
                l_value       := to_char(to_timestamp(l_value_parts(1), l_value_parts(2)),
                                         nvl(i_mask, 'YYYYMMDDHH24MISS'));
            WHEN i_flg_type IN (pk_touch_option.g_elem_flg_type_comp_numeric,
                                pk_touch_option.g_elem_flg_type_simple_number,
                                pk_touch_option.g_elem_flg_type_text,
                                pk_touch_option.g_elem_flg_type_comp_text) THEN
                l_value := i_value;
            
            WHEN i_show_internal = pk_alert_constant.g_yes THEN
                l_value := i_doc_elem_internal;
            WHEN i_flg_type = pk_touch_option.g_elem_flg_type_mchoice_single THEN
            
                l_value := i_value;
            WHEN (i_flg_type = pk_touch_option.g_elem_flg_type_touch AND i_doc_comp_internal IS NOT NULL AND
                 i_show_id_content <> pk_alert_constant.g_yes) THEN
                l_value := pk_touch_option.get_epis_doc_component_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_epis_documentation => i_epis_documentation,
                                                                       i_doc_int_name       => i_doc_comp_internal,
                                                                       i_has_title          => i_show_doc_title);
            ELSE
                l_value := i_id_content;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_value;

    FUNCTION get_template_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_element_int_name   IN VARCHAR2 DEFAULT NULL,
        i_show_internal      IN VARCHAR2 DEFAULT NULL,
        i_scope_type         IN VARCHAR2 DEFAULT 'E',
        i_mask               IN VARCHAR2 DEFAULT NULL,
        i_field_type         IN VARCHAR2 DEFAULT NULL,
        i_show_id_content    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_show_doc_title     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_return   VARCHAR2(4000 CHAR);
        tbl_return table_varchar;
        tbl_prof   table_number;
        l_episode  table_number;
        k_prof     VARCHAR2(50 CHAR) := 'PROF_ID';
    BEGIN
    
        --find list of episodes    
        l_episode := pk_patient.get_episode_list(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_patient        => i_patient,
                                                 i_id_episode        => i_episode,
                                                 i_flg_visit_or_epis => i_scope_type);
    
        SELECT pk_touch_option.get_value(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_flg_type           => t.flg_type,
                                         i_value              => t.value,
                                         i_id_content         => t.id_content,
                                         i_mask               => i_mask,
                                         i_doc_comp_internal  => comp_internal,
                                         i_doc_elem_internal  => element_internal,
                                         i_show_internal      => i_show_internal,
                                         i_epis_documentation => t.id_epis_documentation,
                                         i_show_id_content    => i_show_id_content,
                                         i_show_doc_title     => i_show_doc_title),
               id_professional
          BULK COLLECT
          INTO tbl_return, tbl_prof
          FROM (SELECT de.flg_type,
                       edd.value,
                       c.id_content,
                       d.internal_name comp_internal,
                       de.internal_name element_internal,
                       ed.id_professional,
                       ed.id_epis_documentation,
                       row_number() over(PARTITION BY ed.id_doc_area ORDER BY ed.dt_creation_tstz DESC) rn
                  FROM epis_documentation ed
                  JOIN epis_documentation_det edd
                    ON edd.id_epis_documentation = ed.id_epis_documentation
                  JOIN documentation d
                    ON d.id_documentation = edd.id_documentation
                  JOIN doc_element de
                    ON de.id_doc_element = edd.id_doc_element
                  JOIN doc_element_crit c
                    ON c.id_doc_element_crit = edd.id_doc_element_crit
                 WHERE ed.flg_status = g_active
                   AND ed.id_doc_area = i_doc_area
                   AND ed.id_episode IN (SELECT /*+OPT_ESTIMATE (TABLE j ROWS=0.00000000001)*/
                                          j.column_value
                                           FROM TABLE(l_episode) j)
                   AND (d.internal_name = i_doc_int_name OR i_doc_int_name IS NULL)
                   AND (de.internal_name = i_element_int_name OR i_element_int_name IS NULL)
                   AND (ed.id_epis_documentation = i_epis_documentation OR i_epis_documentation IS NULL)) t
         WHERE t.rn = 1;
    
        IF tbl_return.count > 0
        THEN
            IF i_field_type = k_prof
            THEN
                l_return := tbl_prof(1);
            ELSE
                l_return := tbl_return(1);
            END IF;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_template_value;

    FUNCTION get_doc_templ_by_epis_doc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN NUMBER IS
        l_id_doc_template epis_documentation.id_doc_template%TYPE;
    BEGIN
        SELECT id_doc_template
          INTO l_id_doc_template
          FROM epis_documentation
         WHERE id_epis_documentation = i_id_epis_documentation;
    
        RETURN l_id_doc_template;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_doc_templ_by_epis_doc;

    FUNCTION check_documentation_has_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN VARCHAR2 IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM epis_documentation_det
         WHERE id_epis_documentation = i_id_epis_documentation;
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    END check_documentation_has_detail;

    /******************************************************************************************
    * Gets the question concatenated with the actual answer for a specific                    *
    * id_epis_documentation and id_doc_component                                              *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_epis_documentation         epis documentation id                               *
    * @param i_doc_int_name               doc component internal name                         *
    * @param i_is_bold                    should component be bold?              *
    *                                                                                         *
    * @return                         Returns concatenated string                             *
    *                                                                                         *
    * @author                         Anna Kurowska                                           *
    * @version                        1.0                                                     *
    * @since                          2018/03/05                                              *
    ******************************************************************************************/
    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_is_bold            IN VARCHAR2 DEFAULT NULL,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
        l_doc_component table_number;
        l_error         t_error_out;
    BEGIN
    
        SELECT d.id_doc_component
          BULK COLLECT
          INTO l_doc_component
          FROM documentation d
         WHERE d.internal_name = i_doc_int_name;
    
        IF l_doc_component.count > 0
        THEN
            g_error := 'GET get_epis_doc_component_desc';
            RETURN pk_touch_option.get_epis_doc_component_desc(i_lang               => i_lang,
                                                               i_prof               => i_prof,
                                                               i_epis_documentation => i_epis_documentation,
                                                               i_doc_component      => l_doc_component(1),
                                                               i_is_bold            => i_is_bold,
                                                               i_has_title          => i_has_title);
        ELSE
            RETURN '';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_DOC_COMPONENT_DESC',
                                              l_error);
            RETURN NULL;
    END get_epis_doc_component_desc;

    /**
    * Get epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *  
    * @return flg_printed             from epis_documentation: P - printed; M - Migrated
    *                                                                                 
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION get_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_printed OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    
    BEGIN
        g_error := 'GET_EPIS_DOC_FLG_PRINTED';
    
        SELECT nvl(ed.flg_printed, 'N')
          INTO o_flg_printed
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = i_id_epis_doc
           AND ed.id_doc_area = g_doc_area_sick_leave;
    
        RETURN o_flg_printed;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_DOC_FLG_PRINTED',
                                              l_error);
            RETURN NULL;
    END get_epis_doc_flg_printed;

    /**
    * Set epis documentation flg printed
    *
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_epis_doc            the documentation episode id
    *
    * @return                         Returns boolean    
    *                                                                               
    * @author                         Ana Moita                                   
    * @version                        2.8.0                                        
    * @since                          2019/08/22
    */
    FUNCTION set_epis_doc_flg_printed
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        UPDATE epis_documentation ep
           SET ep.flg_printed = g_flg_printed
         WHERE ep.id_epis_documentation = i_id_epis_doc
           AND ep.id_doc_area = g_doc_area_sick_leave
           AND ep.flg_printed IS NULL;
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
                                              'SET_EPIS_DOC_FLG_PRINTED',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_epis_doc_flg_printed;
    /******************************************************************************************
    * Check if doc_area has scores                                                            *                
    *                                                                                         *
    * @param i_lang                       language id                                         *
    * @param i_prof                       professional, software and                          *
    *                                     institution ids                                     *
    * @param i_id_doc_area                doc area id                                         *
    *                                                                                         *
    * @return                         Returns boolean                                         *
    *                                                                                         *
    * @author                         Anna Kurowska                                           *
    * @version                        1.0                                                     *
    * @since                          2018/07/25                                              *
    ******************************************************************************************/
    FUNCTION check_score_by_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE
    ) RETURN BOOLEAN IS
        l_ret       BOOLEAN;
        l_flg_score VARCHAR2(1);
    BEGIN
        l_ret := FALSE;
        BEGIN
            SELECT d.flg_score
              INTO l_flg_score
              FROM doc_area d
             WHERE d.id_doc_area = i_id_doc_area;
        EXCEPTION
            WHEN no_data_found THEN
                l_ret := NULL;
        END;
    
        IF l_flg_score = pk_alert_constant.get_yes
        THEN
            l_ret := TRUE;
        END IF;
    
        RETURN l_ret;
    
    END check_score_by_area;

    -- CMF

    FUNCTION init_header RETURN VARCHAR2 IS
    BEGIN
    
        RETURN 'SELECT t_epis_documentation(id_episode, ed_flg_status, e_flg_status)
    FROM (SELECT distinct id_episode, ed_flg_status, e_flg_status
    FROM (SELECT e.id_episode, e.id_visit, ed.id_episode_context, ed.flg_status ed_flg_status, e.flg_status e_flg_status
    FROM epis_documentation ed
    JOIN episode e
    ON e.id_episode = ed.id_episode
    WHERE e.id_patient = :i_id_patient
    AND rownum > 0) t
    WHERE 1 = 1';
    
    END init_header;

    FUNCTION tf_epis_documentation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_visit   IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN t_tbl_epis_documentation IS
        l_out_rec        t_tbl_epis_documentation := t_tbl_epis_documentation(NULL);
        l_sql_header     VARCHAR2(32767);
        l_sql_inner      VARCHAR2(32767);
        l_sql_footer     VARCHAR2(32767) := ' )';
        l_sql_stmt       CLOB;
        l_curid          NUMBER;
        l_ret            NUMBER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_EPIS_DOCUMENTATION';
    
        PROCEDURE add_expression
        (
            i_value      IN NUMBER,
            i_expression IN VARCHAR2
        ) IS
        BEGIN
        
            IF i_value IS NOT NULL
            THEN
                l_sql_inner := l_sql_inner || i_expression;
            
            END IF;
        
        END add_expression;
    
        PROCEDURE add_bind
        (
            i_value IN NUMBER,
            i_name  IN VARCHAR2
        ) IS
        BEGIN
        
            IF i_value IS NOT NULL
            THEN
                --dbms_sql.bind_variable(l_curid, i_name, i_value);
                l_sql_inner  := REPLACE(l_sql_inner, i_name, i_value);
                l_sql_header := REPLACE(l_sql_header, i_name, i_value);
                l_sql_footer := REPLACE(l_sql_footer, i_name, i_value);
            ELSE
                l_sql_inner  := REPLACE(l_sql_inner, i_name, 'NULL');
                l_sql_header := REPLACE(l_sql_header, i_name, 'NULL');
                l_sql_footer := REPLACE(l_sql_footer, i_name, 'NULL');
            END IF;
        
        END add_bind;
    
    BEGIN
    
        l_sql_header := init_header();
    
        add_expression(i_id_episode, ' AND (t.id_episode = :i_id_episode OR t.id_episode_context = :i_id_episode)');
        add_expression(i_id_visit, ' AND t.id_visit = :i_id_visit');
    
        add_bind(i_id_patient, ':i_id_patient');
        add_bind(i_id_episode, ':i_id_episode');
        add_bind(i_id_visit, ':i_id_visit');
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
    
        OPEN l_cursor FOR l_sql_stmt;
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        CLOSE l_cursor;
    
        RETURN l_out_rec;
    
    END tf_epis_documentation;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_touch_option;
/
