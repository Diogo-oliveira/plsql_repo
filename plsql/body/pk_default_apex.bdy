/*-- Last Change Revision: $Rev: 1790427 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2017-07-14 16:27:32 +0100 (sex, 14 jul 2017) $*/

CREATE OR REPLACE PACKAGE BODY pk_default_apex IS
    /* initialization environment local common vars */
    c_apex_list_id_separator CONSTANT VARCHAR2(10) := ' - ';

    PROCEDURE init_vars IS
    BEGIN
        g_flg_available := pk_alert_constant.g_available;
        g_no            := pk_alert_constant.g_no;
        g_active        := pk_alert_constant.g_active;
    END init_vars;

    FUNCTION get_lov_id_format(i_id_string IN table_varchar) RETURN VARCHAR2 IS
        l_data_begin VARCHAR2(100) := ' - [';
        l_data_end   VARCHAR2(10) := ']';
    BEGIN
    
        RETURN l_data_begin || pk_utils.concat_table(i_id_string, c_apex_list_id_separator) || l_data_end;
    
    END get_lov_id_format;
    -- private methods
    --**************************************************************************************
    FUNCTION get_lang(i_tbl_lang IN table_number DEFAULT NULL) RETURN table_number IS
        l_tbl_lang table_number;
    BEGIN
    
        IF i_tbl_lang.exists(1)
        THEN
            l_tbl_lang := i_tbl_lang;
        ELSE
        
            SELECT id_language BULK COLLECT
              INTO l_tbl_lang
              FROM LANGUAGE
             WHERE flg_available = g_flg_available;
        
        END IF;
    
        RETURN l_tbl_lang;
    
    END get_lang;
    /********************************************************************************************
    * Send request to IA services in order to do insert codification content
    *
    * @param i_value  Value
    * @param i_institution  Institution ID
    * @param i_software  Software ID
    *
    * @author                        RMGM
    * @version                       2.6.4.3
    * @since                         2015/02/19
    ********************************************************************************************/
    /*PROCEDURE migra_new_sr_procedures_apssch
    (
        i_value       IN sys_config.value%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) IS
        CURSOR c_sr_interv_content IS
            SELECT si_dcs.id_sr_interv_dep_clin_serv, si_dcs.id_institution
              FROM interv_dep_clin_serv si_dcs
             INNER JOIN intervention si
                ON (si.id_intervention = si_dcs.id_intervention)
             INNER JOIN interv_codification ic
                ON ic.id_intervention = si.id_intervention
             INNER JOIN codification c
                ON c.id_codification = ic.id_codification
             WHERE c. = i_value
                  \*and si_dcs.id_software = i_software*\
               AND si_dcs.id_institution = i_institution;
    BEGIN
        FOR sr_res IN c_sr_interv_content
        LOOP
            pk_ia_event_backoffice.sr_interv_dep_clin_serv_new(sr_res.id_sr_interv_dep_clin_serv,
                                                               sr_res.id_institution);
        END LOOP;
        COMMIT;
    END migra_new_sr_procedures_apssch;*/

    /********************************************************************************************
    * Get display for apex LOV (Market)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_market_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        -- get_markets_lov
        l_def_market market.id_market%TYPE := 0;
    BEGIN
        BEGIN
            SELECT id_market
              INTO l_def_market
              FROM institution
             WHERE id_institution = i_institution;
        EXCEPTION
            WHEN no_data_found THEN
                l_def_market := 0;
        END;
    
        SELECT /*+ dynamic_sampling(trl,2) */
         t_rec_lov('', m.id_ab_market, trl.desc_translation) BULK COLLECT
          INTO o_tbl_res
          FROM TABLE(pk_translation.get_table_translation(i_lang, 'AB_MARKET')) trl
         INNER JOIN ab_market m
            ON (m.code_ab_market = trl.code_translation)
         WHERE m.id_ab_market > 0
         ORDER BY decode(m.id_ab_market, l_def_market, '', desc_translation) NULLS FIRST;
    
    END;
    /********************************************************************************************
    * Get display for apex LOV (DEfault Versions)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_version_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
        -- get_versions_lov
    BEGIN
        SELECT t_rec_lov('', d, r) BULK COLLECT
        
          INTO o_tbl_res
          FROM (SELECT DISTINCT version d, version r
                  FROM alert_default.content_market_version
                 ORDER BY decode(version, 'DEFAULT', '', d) NULLS FIRST);
    
    END get_version_list;
    /********************************************************************************************
    * Get display for apex LOV (Institution)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_institution_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
        -- get_institutions_lov
    BEGIN
        SELECT t_rec_lov('', id_institution, desc_instit) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT pk_utils.get_institution_name(pk_utils.get_institution_language(i.id_institution),
                                                     i.id_institution) desc_instit,
                       i.id_institution
                  FROM institution i
                 WHERE i.flg_available = g_flg_available
                   AND i.flg_external = g_no
                   AND i.id_market IS NOT NULL
                      /* AND EXISTS (SELECT 0
                       FROM software_institution si
                      WHERE si.id_institution = i.id_institution)*/
                   AND EXISTS (SELECT 0
                          FROM institution_language il
                         WHERE il.id_institution = i.id_institution)
                 ORDER BY desc_instit);
    
    END get_institution_list;
    /********************************************************************************************
    * Get display for apex LOV (Software)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_software_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    
    BEGIN
        IF i_institution IS NOT NULL
        THEN
            SELECT t_rec_lov('', id_software, name) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT DISTINCT coalesce(e.description,
                                             pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                            e.code_software)) name,
                                    a.id_software
                      FROM software_dept a, ab_software e
                     WHERE a.id_software IN (SELECT id_software
                                               FROM software_institution b
                                              WHERE b.id_institution = i_institution)
                       AND a.id_dept IN (SELECT id_dept
                                           FROM alert.dept
                                          WHERE id_institution = i_institution)
                       AND a.id_software = e.id_ab_software
                     ORDER BY name);
        ELSE
            SELECT t_rec_lov('', id_ab_software, name) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT coalesce(s.description, pk_translation.get_translation(i_lang, s.code_software)) name,
                           s.id_ab_software
                      FROM ab_software s
                     WHERE s.flg_viewer != g_flg_available
                     ORDER BY name);
        END IF;
    END get_software_list;

    PROCEDURE get_soft_list_no_struct
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_show_id     IN table_varchar,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_check NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_check
          FROM TABLE(i_show_id) p
         WHERE p.column_value = g_flg_available;
        IF i_institution = 0
        THEN
        
            SELECT t_rec_lov('',
                             id,
                             name || decode(l_check, 0, '', pk_default_apex.get_lov_id_format(table_varchar(id)))) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT DISTINCT coalesce(s.description,
                                             pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                            s.code_software)) name,
                                    s.id_ab_software id
                      FROM software_institution si, ab_software s
                     WHERE s.flg_mni = g_flg_available
                       AND si.id_software = s.id_ab_software
                     ORDER BY name);
        ELSIF i_institution IS NOT NULL
        THEN
            SELECT t_rec_lov('',
                             id,
                             name || decode(l_check, 0, '', pk_default_apex.get_lov_id_format(table_varchar(id)))) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT coalesce(s.description,
                                    pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                   s.code_software)) name,
                           s.id_ab_software id
                      FROM software_institution si, ab_software s
                     WHERE s.flg_mni = g_flg_available
                       AND si.id_software = s.id_ab_software
                       AND si.id_institution = i_institution
                     ORDER BY name);
        ELSE
            SELECT t_rec_lov('',
                             id,
                             name || decode(l_check, 0, '', pk_default_apex.get_lov_id_format(table_varchar(id)))) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT DISTINCT coalesce(s.description,
                                             pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                            s.code_software)) name,
                                    s.id_ab_software id
                      FROM software_institution si, ab_software s
                     WHERE s.flg_mni = g_flg_available
                       AND si.id_software = s.id_ab_software
                     ORDER BY name);
        END IF;
    END get_soft_list_no_struct;
    /********************************************************************************************
    * Get display for apex LOV (Language)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_language_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
        -- get_languages_lov
    BEGIN
        SELECT t_rec_lov('', id_language, desc_translation) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 trl.desc_translation, z.id_language
                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'LANGUAGE', g_no)) trl
                 INNER JOIN LANGUAGE z
                    ON (z.code_language = trl.code_translation)
                 WHERE z.flg_available = g_flg_available
                 ORDER BY trl.desc_translation);
    
    END get_language_list;

    /********************************************************************************************
    * Get display for apex LOV (Currency)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_currency_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
        l_cur          pk_types.cursor_type;
        l_error        t_error_out;
        l_abrev        table_varchar;
        l_ret          BOOLEAN;
        l_display_id   table_varchar;
        l_display_desc table_varchar;
    BEGIN
        l_ret     := pk_backoffice.get_currency_list(i_lang, l_cur, l_error);
        o_tbl_res := t_tbl_lov();
        FETCH l_cur BULK COLLECT
            INTO l_display_id, l_abrev, l_display_desc;
        CLOSE l_cur;
    
        FOR i IN 1 .. l_display_id.count
        LOOP
            o_tbl_res.extend();
            o_tbl_res(i) := t_rec_lov('', l_abrev(i), coalesce(l_display_desc(i), l_abrev(i)));
        END LOOP;
    
    END get_currency_list;
    /********************************************************************************************
    * Get display for apex LOV (Speciality)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_specialties_list
    (
        i_lang                IN language.id_language%TYPE,
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN table_number,
        i_show_soft_separator IN table_varchar,
        o_tbl_res             OUT t_tbl_lov
    ) IS
        -- get_specialties_per_soft_lov
        -- get_specialties_lov
        l_show_soft   VARCHAR2(100);
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        IF i_show_soft_separator.count = 0
        THEN
            l_show_soft := 'N';
        ELSE
            l_show_soft := i_show_soft_separator(1);
        END IF;
    
        IF i_software.count > 0
        THEN
            SELECT t_rec_lov(name, d3, d4) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT DISTINCT '' name,
                                    decode(l_show_soft,
                                           'N',
                                           '',
                                           (SELECT pk_utils.get_software_name(i_lang => i_lang, i_id_software => soft)
                                              FROM dual) || l_show_soft) || (dept_trans || ' | ' || d1 || ' | ' || d2) ||
                                    pk_default_apex.get_lov_id_format(table_varchar(d3)) d4,
                                    d3
                      FROM (SELECT (SELECT pk_translation.get_translation(l_instit_lang, d.code_department)
                                      FROM dual) d1,
                                   (SELECT pk_translation.get_translation(l_instit_lang, cs.code_clinical_service)
                                      FROM dual) d2,
                                   (SELECT pk_translation.get_translation(l_instit_lang, dp.code_dept)
                                      FROM dual) dept_trans,
                                   dcs.id_dep_clin_serv d3,
                                   sd.id_software soft
                              FROM dep_clin_serv dcs, department d, alert.dept dp, software_dept sd, clinical_service cs
                             WHERE dcs.id_department = d.id_department
                               AND dcs.id_clinical_service = cs.id_clinical_service
                               AND d.id_dept = dp.id_dept
                               AND dp.id_dept = sd.id_dept
                               AND dcs.flg_available = g_flg_available
                               AND d.flg_available = g_flg_available
                               AND dp.flg_available = g_flg_available
                               AND cs.flg_available = g_flg_available
                               AND d.id_institution = i_institution
                               AND d.id_institution = dp.id_institution
                               AND sd.id_software IN (SELECT column_value
                                                        FROM TABLE(CAST(i_software AS table_number))))
                     WHERE d1 IS NOT NULL
                       AND d2 IS NOT NULL
                       AND dept_trans IS NOT NULL
                    
                     ORDER BY upper(d4)) res;
        ELSE
            SELECT t_rec_lov(name, d3, d4) BULK COLLECT
              INTO o_tbl_res
              FROM (SELECT DISTINCT '' name,
                                    decode(l_show_soft, 'N', '', soft || l_show_soft) ||
                                    (dept_trans || ' | ' || d1 || ' | ' || d2) ||
                                    pk_default_apex.get_lov_id_format(table_varchar(d3)) d4,
                                    d3
                      FROM (SELECT (SELECT pk_translation.get_translation(l_instit_lang, d.code_department)
                                      FROM dual) d1,
                                   (SELECT pk_translation.get_translation(l_instit_lang, cs.code_clinical_service)
                                      FROM dual) d2,
                                   (SELECT pk_translation.get_translation(l_instit_lang, dp.code_dept)
                                      FROM dual) dept_trans,
                                   dcs.id_dep_clin_serv d3,
                                   (SELECT pk_utils.get_software_name(i_lang => i_lang, i_id_software => sd.id_software)
                                      FROM dual) soft
                              FROM dep_clin_serv dcs, department d, alert.dept dp, software_dept sd, clinical_service cs
                            
                             WHERE dcs.id_department = d.id_department
                               AND dcs.id_clinical_service = cs.id_clinical_service
                               AND d.id_dept = dp.id_dept
                               AND dp.id_dept = sd.id_dept
                               AND dcs.flg_available = g_flg_available
                               AND d.flg_available = g_flg_available
                               AND dp.flg_available = g_flg_available
                               AND cs.flg_available = g_flg_available
                               AND d.id_institution = i_institution
                               AND d.id_institution = dp.id_institution)
                     WHERE d1 IS NOT NULL
                       AND d2 IS NOT NULL
                       AND dept_trans IS NOT NULL
                     ORDER BY upper(d4));
        END IF;
    
    END get_specialties_list;

    -- 
    /********************************************************************************************
    * Get display for apex LOV (Unit measures)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_unit_measure_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 coalesce(trl.desc_translation, internal_name) ||
                 pk_default_apex.get_lov_id_format(table_varchar(um.id_unit_measure, um.id_content)) d,
                 id_unit_measure r
                  FROM unit_measure um
                  LEFT JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'UNIT_MEASURE')) trl
                    ON trl.code_translation = um.code_unit_measure
                 WHERE flg_available = g_flg_available
                 ORDER BY 1 DESC) res;
    END get_unit_measure_list;

    /********************************************************************************************
    * Get display for apex LOV (Unit measure types)
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2015/02/02
    ********************************************************************************************/
    PROCEDURE get_unit_measure_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('',
                         id_unit_measure_type,
                         coalesce(pk_translation.get_translation(l_instit_lang, code_unit_measure_type), internal_name)) BULK COLLECT
          INTO o_tbl_res
          FROM unit_measure_type
         WHERE flg_available = g_flg_available;
    
    END get_unit_measure_type_list;

    /********************************************************************************************
    * Get display for apex LOV (Unit measure types)
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2015/02/02
    ********************************************************************************************/
    PROCEDURE get_unit_measure_subtype_list
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_unit_measure_type IN table_varchar,
        o_tbl_res           OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_umt_count   NUMBER := i_unit_measure_type.count;
    BEGIN
    
        IF i_unit_measure_type.exists(1)
        THEN
            SELECT t_rec_lov('',
                             id_unit_measure_subtype,
                             coalesce(pk_translation.get_translation(l_instit_lang, code_unit_measure_subtype),
                                      internal_name)) BULK COLLECT
              INTO o_tbl_res
              FROM alert.unit_measure_subtype
             WHERE id_unit_measure_type = i_unit_measure_type(1);
        ELSE
            SELECT t_rec_lov('',
                             id_unit_measure_subtype,
                             coalesce(pk_translation.get_translation(l_instit_lang, code_unit_measure_subtype),
                                      internal_name)) BULK COLLECT
              INTO o_tbl_res
              FROM alert.unit_measure_subtype;
        END IF;
    END get_unit_measure_subtype_list;

    /********************************************************************************************
    * Get display for apex LOV (Vital Signs)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_vital_sign_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2)*/
                 coalesce(trl.desc_translation, vs.intern_name_vital_sign) ||
                 get_lov_id_format(table_varchar(vs.id_vital_sign, vs.id_content)) d,
                 id_vital_sign r
                  FROM vital_sign vs
                  LEFT JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'VITAL_SIGN')) trl
                    ON trl.code_translation = vs.code_vital_sign
                 WHERE flg_available = g_flg_available
                 ORDER BY 1 DESC) res;
    END get_vital_sign_list;

    -- 
    /********************************************************************************************
    * Get display for apex LOV (Country)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_country_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
        SELECT t_rec_lov('', z.id_country, trl.desc_translation) BULK COLLECT
          INTO o_tbl_res
          FROM TABLE(pk_translation.get_table_translation(i_lang, 'COUNTRY', g_no)) trl
         INNER JOIN country z
            ON (z.code_country = trl.code_translation)
         WHERE z.flg_available = g_flg_available
         ORDER BY trl.desc_translation;
    END get_country_list;
    /********************************************************************************************
    * Get display for apex LOV (Professional Category)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_category_list
    (
        i_lang             IN language.id_language%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE,
        o_tbl_res          OUT t_tbl_lov
    ) IS
    BEGIN
        IF i_profile_template IS NOT NULL
        THEN
        
            SELECT /*+ dynamic_sampling(trl,2) */
             t_rec_lov('',
                       z.id_category,
                       trl.desc_translation || get_lov_id_format(table_varchar(z.id_category, z.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'CATEGORY', g_no)) trl
             INNER JOIN category z
                ON (z.code_category = trl.code_translation)
             WHERE z.flg_available = g_flg_available
               AND z.flg_prof = g_flg_available
               AND EXISTS (SELECT 0
                      FROM profile_template_category ptc
                     WHERE ptc.id_category = z.id_category
                       AND ptc.id_profile_template = i_profile_template)
             ORDER BY trl.desc_translation;
        
        ELSE
            SELECT /*+ dynamic_sampling(trl,2) */
             t_rec_lov('',
                       z.id_category,
                       trl.desc_translation || get_lov_id_format(table_varchar(z.id_category, z.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'CATEGORY', g_no)) trl
             INNER JOIN category z
                ON (z.code_category = trl.code_translation)
             WHERE z.flg_available = g_flg_available
               AND z.flg_prof = g_flg_available
               AND EXISTS (SELECT 0
                      FROM profile_template_category ptc
                     WHERE ptc.id_category = z.id_category)
             ORDER BY trl.desc_translation;
        END IF;
    END get_category_list;

    /********************************************************************************************
    * Get display for apex LOV (DOC TEMPLATE)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_doc_template_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT coalesce((SELECT pk_translation.get_translation(l_instit_lang, dt.code_doc_template)
                                  FROM dual),
                                dt.internal_name) || get_lov_id_format(table_varchar(id_doc_template, dt.id_content)) d,
                       id_doc_template r
                  FROM doc_template dt
                 WHERE flg_available = g_flg_available
                 ORDER BY 1) res;
    
    END get_doc_template_list;

    /********************************************************************************************
    * Get display for apex LOV (EXAMS)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_exam_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        i_flg_type    IN VARCHAR2 DEFAULT NULL,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang    language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_software_count NUMBER := i_software.count;
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT d, r
                  FROM (SELECT /*+ dynamic_sampling(trl,2)*/
                         trl.desc_translation,
                         trl.desc_translation || get_lov_id_format(table_varchar(e.id_exam, e.id_content)) d,
                         e.id_exam r
                          FROM alert.exam e
                          LEFT JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'EXAM')) trl
                            ON trl.code_translation = e.code_exam
                          JOIN alert.exam_dep_clin_serv edcs
                            ON edcs.id_exam = e.id_exam
                           AND edcs.flg_type = 'P'
                              --specific exam type?
                           AND (i_flg_type IS NULL OR e.flg_type = i_flg_type)
                           AND --searchables
                               (l_software_count = 0 OR
                               edcs.id_software IN (SELECT /*+ dynamic_sampling(soft,2)*/
                                                      column_value
                                                       FROM TABLE(i_software) soft))
                           AND edcs.id_institution = i_institution
                         WHERE e.flg_available = g_flg_available)
                 GROUP BY r, d, desc_translation
                 ORDER BY desc_translation NULLS LAST) res;
    
    END get_exam_list;

    /********************************************************************************************
    * Get display for apex LOV (INTERVENTION)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_intervention_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang    language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_software_count NUMBER := i_software.count;
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT d, r
                  FROM (SELECT /*+ dynamic_sampling(trl,2)*/
                         trl.desc_translation,
                         trl.desc_translation || get_lov_id_format(table_varchar(i.id_intervention, i.id_content)) d,
                         i.id_intervention r
                          FROM alert.intervention i
                        /*LEFT*/
                          JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'INTERVENTION')) trl
                            ON trl.code_translation = i.code_intervention
                          JOIN alert.interv_dep_clin_serv idcs
                            ON idcs.id_intervention = i.id_intervention
                           AND (l_software_count = 0 OR
                               (idcs.id_software IN (SELECT /*+ dynamic_sampling(softs,2)*/
                                                       column_value
                                                        FROM TABLE(i_software) softs
                                                      UNION ALL
                                                      SELECT 0
                                                        FROM dual)))
                           AND idcs.id_institution IN (0, i_institution)
                         WHERE i.flg_status = g_active)
                /* WHERE desc_translation IS NOT NULL*/ --trying to improve performance
                 GROUP BY r, d, desc_translation
                 ORDER BY desc_translation /*NULLS LAST*/
                ) res;
    
    END get_intervention_list;

    /********************************************************************************************
    * Get display for apex LOV (SR_INTERVENTION)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_sr_intervention_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_flg_coding  VARCHAR2(1) := pk_sysconfig.get_config('SURGICAL_PROCEDURES_CODING',
                                                             profissional(0, i_institution, 0));
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT d, r
                  FROM (SELECT /*+ dynamic_sampling(trl,2)*/
                         trl.desc_translation,
                         trl.desc_translation || get_lov_id_format(table_varchar(sr.id_sr_intervention, sr.id_content)) d,
                         sr.id_sr_intervention r
                          FROM alert.sr_intervention sr
                          LEFT JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'SR_INTERVENTION')) trl
                            ON trl.code_translation = sr.code_sr_intervention
                          JOIN alert.sr_interv_dep_clin_serv srdcs
                            ON srdcs.id_sr_intervention = sr.id_sr_intervention
                           AND srdcs.id_software IN (SELECT /*+ dynamic_sampling(softs,2)*/
                                                      column_value
                                                       FROM TABLE(i_software) softs)
                           AND srdcs.id_institution = i_institution
                         WHERE sr.flg_status = g_active
                           AND sr.flg_coding = l_flg_coding)
                
                 GROUP BY r, d, desc_translation
                 ORDER BY desc_translation NULLS LAST) res;
    
    END get_sr_intervention_list;

    /********************************************************************************************
    * Get list of possible values for sys_config ALLERGY_PRESC_TYPE
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    FUNCTION get_allergy_presc_type_vals RETURN table_varchar IS
        l_values table_varchar;
    BEGIN
    
        RETURN l_values;
    END get_allergy_presc_type_vals;

    /********************************************************************************************
    * Get display for apex LOV (REHAB_AREA)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_rehab_area_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.desc_translation || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT pk_translation.get_translation(l_instit_lang, ra.code_rehab_area) desc_translation,
                       get_lov_id_format(table_varchar(ra.id_rehab_area, ra.id_content)) codes,
                       ra.id_rehab_area r
                  FROM alert.rehab_area ra
                 WHERE EXISTS (SELECT 1
                          FROM alert.rehab_area_inst rai
                         WHERE rai.id_rehab_area = ra.id_rehab_area
                           AND rai.id_institution = i_institution)
                 ORDER BY desc_translation NULLS LAST) res;
    
    END get_rehab_area_list;

    /********************************************************************************************
    * Get display for apex LOV (REHAB_AREA)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_doc_area_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT coalesce((SELECT pk_translation.get_translation(l_instit_lang, da.code_doc_area)
                                  FROM dual),
                                da.internal_name) || get_lov_id_format(table_varchar(da.id_doc_area, da.id_content)) d,
                       id_doc_area r
                  FROM doc_area da
                 WHERE flg_available = g_flg_available
                 ORDER BY 1) res;
    
    END get_doc_area_list;

    /********************************************************************************************
    * Get display for apex LOV (COMPLAINT)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_complaint_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.desc_translation || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT pk_translation.get_translation(l_instit_lang, c.code_complaint) desc_translation,
                       get_lov_id_format(table_varchar(c.id_complaint, c.id_content)) codes,
                       c.id_complaint r
                  FROM alert.complaint c
                 WHERE c.flg_available = g_flg_available
                 ORDER BY desc_translation NULLS LAST) res;
    
    END get_complaint_list;

    /********************************************************************************************
    * Get available health_programs for apex LOV (po_param_sets)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_available_hpg_content_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang    language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_software_count NUMBER := i_software.count;
    BEGIN
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT DISTINCT hp.id_content id,
                                pk_translation.get_translation(l_instit_lang, hp.code_health_program) ||
                                pk_default_apex.get_lov_id_format(table_varchar(hp.id_health_program, hp.id_content)) descr
                  FROM health_program hp
                  JOIN health_program_soft_inst hpsi
                    ON hp.id_health_program = hpsi.id_health_program
                 WHERE hpsi.id_institution = i_institution
                   AND (l_software_count = 0 OR
                       id_software IN (SELECT column_value
                                          FROM TABLE(i_software)))
                   AND hpsi.flg_active = g_flg_available) res;
    
    END get_available_hpg_content_list;

    /********************************************************************************************
    * Get available health_programs for apex LOV (po_param_sets)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_available_hpg_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang    language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_software_count NUMBER := i_software.count;
    BEGIN
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT DISTINCT hp.id_health_program id,
                                pk_translation.get_translation(l_instit_lang, hp.code_health_program) ||
                                pk_default_apex.get_lov_id_format(table_varchar(hp.id_health_program, hp.id_content)) descr
                  FROM health_program hp
                  JOIN health_program_soft_inst hpsi
                    ON hp.id_health_program = hpsi.id_health_program
                 WHERE hpsi.id_institution = i_institution
                   AND (l_software_count = 0 OR
                       id_software IN (SELECT column_value
                                          FROM TABLE(i_software)))
                   AND hpsi.flg_active = g_flg_available) res;
    
    END get_available_hpg_list;

    /* function get_po_param_type(i_lang in language.id_language%type,i_flg_type in varchar2) return varchar2 is 
      
    begin
       select       
    end get_po_param_type;*/

    /********************************************************************************************
    * Get display for apex LOV (PO_PARAM)
    *
    * @author                        JM
    * @version                       2.6.4.3
    * @since                         2015/02/02
    ********************************************************************************************/
    PROCEDURE get_po_param_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        --records per page
        lnum_record_max  NUMBER := alert_apex_tools.pk_apex_common.g_max_records_per_page;
        lnum_number_page NUMBER;
    
        l_vs_desc       VARCHAR2(100) := pk_message.get_message(i_lang, 'MONITOR_T006');
        l_habit_desc    VARCHAR2(100) := pk_message.get_message(i_lang, 'PROBLEMS_M006');
        l_analysis_desc VARCHAR2(100) := pk_message.get_message(i_lang, 'LAB_TESTS_T115');
    
    BEGIN
        /*   --check input
        IF (i_search = '#PAGINATION#')
        THEN
            lnum_number_page := 0;
        ELSIF (i_search = '#PAGINATION_ALL#')
        THEN
            BEGIN
                lnum_number_page := 0;
                SELECT COUNT(*)
                  INTO lnum_record_max
                  FROM alert.po_param;
            END;
        ELSE
            lnum_number_page := to_number(i_search);
        END IF;*/
    
        SELECT t_rec_lov('', res.r, res.desc_translation || ' - ' || res.flg_type || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT *
                  FROM (SELECT /*+ dynamic_sampling(t_pop,2) */
                         t_pop.desc_translation,
                         pk_default_apex.get_lov_id_format(table_varchar(c.id_po_param, c.id_content)) codes,
                         (SELECT pk_translation.get_translation(i_lang, pop_type.code_periodic_param_type)
                            FROM dual) flg_type,
                         c.id_po_param r
                          FROM alert.po_param c
                          JOIN periodic_param_type pop_type
                            ON pop_type.flg_periodic_param_type = c.flg_type
                          JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'PO_PARAM', 'N')) t_pop
                            ON c.code_po_param = t_pop.code_translation
                         WHERE c.flg_available = g_flg_available
                           AND c.id_inst_owner = 0
                           AND c.flg_type = 'O'
                        
                        UNION ALL --A       
                        SELECT (SELECT pk_translation.get_translation(l_instit_lang,
                                                                      'ANALYSIS.CODE_ANALYSIS.' || c.id_parameter)
                                  FROM dual) desc_translation,
                               pk_default_apex.get_lov_id_format(table_varchar(c.id_po_param, c.id_content)) codes,
                               l_analysis_desc flg_type,
                               c.id_po_param r
                          FROM alert.po_param c
                        
                         WHERE c.flg_available = g_flg_available
                           AND c.id_inst_owner = 0
                           AND c.flg_type = 'A'
                        
                        UNION ALL --VS   
                        SELECT (SELECT pk_translation.get_translation(l_instit_lang,
                                                                      'VITAL_SIGN.CODE_VITAL_SIGN.' || c.id_parameter)
                                  FROM dual) desc_translation,
                               pk_default_apex.get_lov_id_format(table_varchar(c.id_po_param, c.id_content)) codes,
                               l_vs_desc flg_type,
                               c.id_po_param r
                          FROM alert.po_param c
                        
                         WHERE c.flg_available = g_flg_available
                           AND c.id_inst_owner = 0
                           AND c.flg_type = 'VS'
                        UNION ALL --H
                        SELECT (SELECT pk_translation.get_translation(l_instit_lang, 'HABIT.CODE_HABIT.' || c.id_parameter)
                                  FROM dual) desc_translation,
                               pk_default_apex.get_lov_id_format(table_varchar(c.id_po_param, c.id_content)) codes,
                               l_habit_desc flg_type,
                               c.id_po_param r
                          FROM alert.po_param c
                        
                         WHERE c.flg_available = g_flg_available
                           AND c.id_inst_owner = 0
                           AND c.flg_type = 'H')
                 WHERE desc_translation IS NOT NULL
                 ORDER BY desc_translation) res;
    END get_po_param_list;
    /********************************************************************************************
    * Get display for apex LOV (PO_PARAM)
    *
    * @author                        JM
    * @version                       2.6.4.3
    * @since                         2015/02/02
    ********************************************************************************************/
    PROCEDURE get_po_param_mc_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        SELECT t_rec_lov('', res.r, res.desc_po_param_mc || res.desc_icon || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT *
                  FROM (SELECT DISTINCT pk_translation.get_translation(l_instit_lang, c.code_po_param_mc) desc_po_param_mc,
                                        pk_translation.get_translation(l_instit_lang, c.code_icon) desc_icon,
                                        pk_default_apex.get_lov_id_format(table_varchar(c.id_content)) codes,
                                        c.id_content r
                          FROM alert.po_param_mc c
                         WHERE c.flg_available = g_flg_available
                           AND (pk_translation.get_translation(l_instit_lang, c.code_po_param_mc) IS NOT NULL AND
                               pk_translation.get_translation(l_instit_lang, c.code_icon) IS NULL)
                            OR (pk_translation.get_translation(l_instit_lang, c.code_po_param_mc) IS NULL AND
                               pk_translation.get_translation(l_instit_lang, c.code_icon) IS NOT NULL)) tab
                 ORDER BY tab.desc_po_param_mc) res;
    END get_po_param_mc_list;

    PROCEDURE get_pp_tt_content_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_task_type   IN table_varchar,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        IF i_task_type(1) = pk_periodic_observation.g_task_type_hpg
        THEN
            get_available_hpg_content_list(i_lang, i_institution, table_number(), o_tbl_res);
        ELSIF i_task_type(1) = pk_periodic_observation.g_task_type_exam
        THEN
            get_exam_list(i_lang, i_institution, table_number(), 'I', o_tbl_res);
        
        ELSIF i_task_type(1) = pk_periodic_observation.g_task_type_oth_exams
        THEN
            get_exam_list(i_lang, i_institution, table_number(), 'E', o_tbl_res);
        
        ELSIF i_task_type(1) = pk_periodic_observation.g_task_type_interv
        THEN
            get_intervention_list(i_lang, i_institution, table_number(), o_tbl_res);
        
        END IF;
    
    END get_pp_tt_content_list;
    /********************************************************************************************
    * Get display for apex LOV (SCH_EVENT)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_sch_event_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT coalesce(pk_translation.get_translation(l_instit_lang, se.code_sch_event), se.intern_name) ||
                       get_lov_id_format(table_varchar(se.id_sch_event, se.id_content)) d,
                       se.id_sch_event r
                  FROM alert.sch_event se
                 WHERE se.id_sch_event IN (1, 2, 6, 9)
                 ORDER BY 1) res;
    
    END get_sch_event_list;

    /********************************************************************************************
    * Get display for apex LOV (SCH_EVENT)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_ped_area_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', res.r, res.d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT coalesce((SELECT pk_translation.get_translation(l_instit_lang, paa.code_ped_area_add)
                                  FROM dual),
                                (SELECT pk_translation.get_translation(l_instit_lang, dt.code_doc_template)
                                   FROM dual),
                                dt.internal_name) ||
                       get_lov_id_format(table_varchar(paa.id_ped_area_add, paa.id_content)) d,
                       paa.id_ped_area_add r
                  FROM alert.ped_area_add paa
                  LEFT JOIN doc_template dt
                    ON dt.id_doc_template = paa.id_doc_template
                 ORDER BY 1) res;
    
    END get_ped_area_list;

    /********************************************************************************************
    * Get display for apex LOV (Room All)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_room_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        SELECT t_rec_lov('', id_room, d || additional_vals) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT (SELECT pk_translation.get_translation(l_instit_lang, r.code_room)
                          FROM dual) d,
                       ' [' || (SELECT pk_translation.get_translation(l_instit_lang, d.code_department)
                                  FROM dual) || ']' additional_vals,
                       r.id_room
                  FROM room r
                 INNER JOIN department d
                    ON (d.id_department = r.id_department)
                 WHERE r.flg_available = g_flg_available
                   AND d.flg_available = g_flg_available
                   AND d.id_institution = i_institution
                 ORDER BY d)
         WHERE d IS NOT NULL;
    
    END get_room_list;
    /********************************************************************************************
    * Get display for apex LOV (TRANSLATED Clinical Services)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/25
    ********************************************************************************************/
    PROCEDURE get_clinical_service_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        g_error := 'GET CLINICAL_SERVICES TRANSLATED AND AVAILABLE';
        SELECT /*+ dynamic_sampling(t_cs,2) */
         t_rec_lov('', res.id_clinical_service, res.desc_translation || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT t_cs.desc_translation,
                       get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content)) codes,
                       cs.id_clinical_service
                  FROM TABLE(pk_translation.get_table_translation(l_instit_lang, 'CLINICAL_SERVICE', g_no)) t_cs
                 INNER JOIN clinical_service cs
                    ON (cs.code_clinical_service = t_cs.code_translation)
                 INNER JOIN alert_default.clinical_service def_cs
                    ON (def_cs.id_content = cs.id_content)
                 WHERE cs.flg_available = g_flg_available
                   AND def_cs.flg_available = g_flg_available
                 ORDER BY desc_translation) res;
    
    END get_clinical_service_list;

    /********************************************************************************************
    * Get display for apex LOV (TRANSLATED Clinical Services for i_instituion or 0)
    *
    * @author                        RMGM
    * @version                       2.6.4.3
    * @since                         2015/02/10
    ********************************************************************************************/
    PROCEDURE get_all_clinical_service_list
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_software_list IN table_number,
        o_tbl_res       OUT t_tbl_lov
    ) IS
        l_instit_lang     language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_softwares_final table_number;
    BEGIN
    
        IF i_software_list.count = 0
        THEN
            l_softwares_final := NULL;
        ELSE
            l_softwares_final := i_software_list;
        END IF;
    
        g_error := 'GET CLINICAL_SERVICES TRANSLATED AND AVAILABLE';
        SELECT /*+ dynamic_sampling(t_cs,2) */
         t_rec_lov('', res.id_clinical_service, res.desc_translation || res.codes) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT DISTINCT t_cs.desc_translation,
                                get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content)) codes,
                                cs.id_clinical_service
                  FROM TABLE(pk_translation.get_table_translation(l_instit_lang, 'CLINICAL_SERVICE', g_no)) t_cs
                 INNER JOIN clinical_service cs
                    ON (cs.code_clinical_service = t_cs.code_translation)
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_clinical_service = cs.id_clinical_service)
                 INNER JOIN department dp
                    ON (dcs.id_department = dp.id_department)
                 INNER JOIN dept d
                    ON d.id_dept = dp.id_dept
                 INNER JOIN software_dept sd
                    ON sd.id_dept = d.id_dept
                
                 WHERE (l_softwares_final IS NULL OR
                       sd.id_software IN (SELECT column_value
                                             FROM TABLE(l_softwares_final)))
                   AND cs.flg_available = g_flg_available
                   AND dp.id_institution IN (0, i_institution)
                 ORDER BY desc_translation) res;
    
    END get_all_clinical_service_list;
    /********************************************************************************************
    * Get display for apex LOV (TRANSLATED Services)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/25
    ********************************************************************************************/
    PROCEDURE get_department_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_instit_lang language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        g_error := 'GET SERVICES TRANSLATED AND AVAILABLE';
        SELECT /*+ dynamic_sampling(t_serv,2) */ /*+ dynamic_sampling(t_dept,2) */
         t_rec_lov('', d.id_department, t_serv.desc_translation || ' (' || t_dept.desc_translation || ')') BULK COLLECT
          INTO o_tbl_res
          FROM TABLE(pk_translation.get_table_translation(l_instit_lang, 'DEPARTMENT', g_no)) t_serv
         INNER JOIN department d
            ON (d.code_department = t_serv.code_translation)
          JOIN dept dept
            ON d.id_dept = dept.id_dept
          JOIN TABLE(pk_translation.get_table_translation(l_instit_lang, 'DEPT', g_no)) t_dept
            ON dept.code_dept = t_dept.code_translation
         WHERE d.flg_available = g_flg_available
           AND d.id_institution = i_institution
         ORDER BY t_serv.desc_translation;
    
    END get_department_list;
    /********************************************************************************************
    * Get display for apex LOV (Profile_template)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/25
    ********************************************************************************************/
    PROCEDURE get_bo_profile_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_cfg_validation NUMBER := 0;
    BEGIN
        SELECT COUNT(*)
          INTO l_cfg_validation
          FROM profile_template pt
         WHERE pt.flg_available = g_flg_available
           AND pt.id_software = 26
           AND EXISTS (SELECT 0
                  FROM profile_template_inst pti
                 WHERE pti.id_profile_template = pt.id_profile_template
                   AND pti.id_institution = i_institution);
    
        IF l_cfg_validation = 0
        THEN
            SELECT t_rec_lov('', id_profile_template, intern_name_templ) BULK COLLECT
              INTO o_tbl_res
              FROM profile_template pt
             WHERE pt.flg_available = g_flg_available
               AND pt.id_software = 26
               AND EXISTS (SELECT 0
                      FROM profile_template_inst pti
                     WHERE pti.id_profile_template = pt.id_profile_template
                       AND pti.id_institution = 0)
             ORDER BY intern_name_templ;
        ELSE
            SELECT t_rec_lov('', id_profile_template, intern_name_templ) BULK COLLECT
              INTO o_tbl_res
              FROM profile_template pt
             WHERE pt.flg_available = g_flg_available
               AND pt.id_software = 26
               AND EXISTS (SELECT 0
                      FROM profile_template_inst pti
                     WHERE pti.id_profile_template = pt.id_profile_template
                       AND pti.id_institution = i_institution)
             ORDER BY intern_name_templ;
        END IF;
    
    END get_bo_profile_list;

    /********************************************************************************************
    * Get display for apex LOV (Profile_template),BASED ON CATEGORY AND SOFTWARE
    *
    * @author                        LCRS               
    * @version                       2.6.4
    * @since                         2013/09/29
    ********************************************************************************************/

    FUNCTION get_profile_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN VARCHAR2,
        i_category    IN VARCHAR2
    ) RETURN t_tbl_lov IS
        l_tbl_res         t_tbl_lov;
        l_instit_language institution.id_institution%TYPE := pk_utils.get_institution_language(i_institution);
        l_instit_market   NUMBER := pk_utils.get_institution_market(l_instit_language, i_institution);
    BEGIN
        SELECT t_rec_lov('', r, desc_translation || other_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT pt.id_profile_template r,
                       (SELECT pk_translation.get_translation(l_instit_language, pt.code_profile_template)
                          FROM dual) desc_translation,
                       decode(ptm.id_market,
                              0,
                              '',
                              ' (' || (SELECT pk_translation.get_translation(l_instit_language, m.code_market)
                                         FROM market m
                                        WHERE m.id_market = ptm.id_market) || ')') || c_apex_list_id_separator ||
                       s.intern_name || get_lov_id_format(table_varchar(pt.id_profile_template)) other_desc,
                       row_number() over(PARTITION BY pt.id_profile_template ORDER BY 1) row_number
                  FROM alert.profile_template          pt,
                       alert.profile_template_inst     pti,
                       alert.profile_template_market   ptm,
                       alert.profile_template_category ptc,
                       software                        s
                 WHERE (i_software IS NULL OR
                       pt.id_software IN
                       (SELECT /*+ dynamic_sampling(p 2)*/
                          column_value
                           FROM TABLE(CAST(pk_utils.str_split_n(i_software, ':') AS table_number)) p))
                   AND (i_category IS NULL OR
                       ptc.id_category IN
                       (SELECT /*+ dynamic_sampling(p 2)*/
                          column_value
                           FROM TABLE(CAST(pk_utils.str_split_n(i_category, ':') AS table_number)) p))
                   AND pt.flg_available = g_flg_available
                   AND coalesce(pt.id_institution, i_institution) LIKE coalesce(to_char(i_institution), '%')
                   AND pti.id_institution = 0
                   AND ptc.id_profile_template = pti.id_profile_template
                   AND pti.id_profile_template = pt.id_profile_template
                   AND ptm.id_profile_template = pti.id_profile_template
                   AND ptm.id_market IN (0, l_instit_market)
                   AND s.id_software = pt.id_software
                   AND s.flg_viewer = g_no
                   AND s.flg_mni = g_flg_available)
         WHERE row_number = 1
         ORDER BY desc_translation NULLS LAST;
    
        RETURN l_tbl_res;
    
    END get_profile_list;
    /********************************************************************************************
    * Get display for apex LOV (DOMAINS -> i_domain needed code)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/25
    ********************************************************************************************/
    PROCEDURE get_sysdomain_list
    (
        i_lang        IN language.id_language%TYPE,
        i_domain      IN sys_domain.code_domain%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    BEGIN
        g_error := 'GET DOMAIN LIST FOR ' || i_domain;
        SELECT t_rec_lov('', val, desc_val) BULK COLLECT
          INTO o_tbl_res
          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(pk_utils.get_institution_language(i_institution),
                                                              profissional(0, i_institution, 0),
                                                              i_domain,
                                                              NULL)) e
         ORDER BY desc_val;
    END get_sysdomain_list;
    /********************************************************************************************
    * Get display for apex LOV (System configuration)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    PROCEDURE get_sysconfig_list
    (
        i_lang        IN language.id_language%TYPE,
        i_sysconfig   IN sys_config.id_sys_config%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        o_tbl_lov     OUT t_tbl_lov
    ) IS
    
        l_institution_language language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
        l_transport_label      VARCHAR2(200) := pk_message.get_message(i_lang, 'DISCHARGE_T012');
        l_type_label           VARCHAR2(200) := pk_message.get_message(i_lang, 'ID_TYPE'); --tipo
    BEGIN
    
        IF i_sysconfig IN ('BIRD_EYE_VIEW_DEP', 'SURGERY_ROOM_DEPT', 'PHYSIOTERAPY_DEPT')
        THEN
            SELECT /*+ dynamic_sampling(t_serv,2) */ /*+ dynamic_sampling(t_dept,2) */
             t_rec_lov('', d.id_department, t_serv.desc_translation || ' (' || t_dept.desc_translation || ')') BULK COLLECT
              INTO o_tbl_lov
              FROM TABLE(pk_translation.get_table_translation(l_institution_language, 'DEPARTMENT', g_no)) t_serv
             INNER JOIN department d
                ON (d.code_department = t_serv.code_translation)
              JOIN dept dept
                ON d.id_dept = dept.id_dept
              JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'DEPT', g_no)) t_dept
                ON dept.code_dept = t_dept.code_translation
             WHERE d.flg_available = g_flg_available
               AND d.id_institution = i_institution
             ORDER BY t_serv.desc_translation;
        
        ELSIF i_sysconfig = 'PARAMEDICAL_REQUESTS_DEFAULT_DEP_CLIN_SERV'
        THEN
            get_specialties_list(l_institution_language,
                                 i_institution,
                                 table_number(),
                                 table_varchar(c_apex_list_id_separator),
                                 o_tbl_lov);
        ELSIF i_sysconfig = 'ID_COUNTRY'
        THEN
            get_country_list(i_lang, o_tbl_lov);
        ELSIF i_sysconfig = 'AUTO_PRINT_TRIAGE_REPORT_ID'
        THEN
            SELECT t_rec_lov('', r, d) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, code_reports)
                              FROM dual) d,
                           id_reports r
                      FROM reports
                     WHERE flg_available = g_flg_available
                     ORDER BY d)
             WHERE d IS NOT NULL;
        
        ELSIF i_sysconfig = 'LANGUAGE'
        THEN
            get_language_list(i_lang, o_tbl_lov);
        ELSIF i_sysconfig = 'CURRENCY_UNIT'
        THEN
            get_currency_list(i_lang, o_tbl_lov);
        ELSIF i_sysconfig IN ('SURGICAL_PROCEDURES_CODING',
                              'TRIAGE_WIZARD_DEST',
                              'ADMIN_INP_EPISODES',
                              'VS_PAST_X_FROM_VISIT',
                              'VS_PAST_X',
                              'PER_OBS_VS_DATE_SORT',
                              'PASSWORD_BUTTON',
                              'DISCHARGE_INTERVENTION',
                              'TRIAGE_ID_BOARD',
                              'DISCHARGE_ADMIN'
                              /*NOVOS_VALORES_VITALSIGN*/,
                              'VS_BIOMETRIC_BMI_AUTOCOMPLETE',
                              'VS_CLINICAL_DATE',
                              'VS_BIOMETRIC_BSA_AUTOCOMPLETE',
                              'VS_BMI_CALC',
                              'VITAL_SIGNS_ALLOWED_ON_INACT',
                              'VITAL_SIGNS_ALLOWED_ON_SCH',
                              'VITAL_SIGNS_ALLOWED_ON_EHR',
                              /*NEW_VALUES_PERIODIC_OBS */
                              'PER_OBS_SHOW_REF_VALS',
                              'PER_OBS_VALUE_SCOPE',
                              'PER_OBS_DISABLE_PARAM',
                              'PER_OBS_PREGN_DEFAULT_VIEW',
                              'PER_OBS_COL_AGGREGATE',
                              'PER_OBS_COL_CREATE',
                              'PER_OBS_DEFAULT_VIEW',
                              'PER_OBS_ENABLE_LAB_TEST_RESULTS',
                              'PER_OBS_VS_DATE_SORT',
                              'OBSERVATIONS_ENABLE_IT')
        THEN
            SELECT t_rec_lov('', val, desc_val) BULK COLLECT
              INTO o_tbl_lov
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(l_institution_language,
                                                                  profissional(0, 0, 0),
                                                                  i_sysconfig,
                                                                  NULL))
             ORDER BY desc_val;
        ELSIF i_sysconfig IN ('ADMIN_DEFAULT_ROOM', 'SR_DEFAULT_ROOM')
        THEN
            get_room_list(l_institution_language, i_institution, o_tbl_lov);
        ELSIF i_sysconfig = 'DEFAULT_TRANSP_ENT_INST'
        THEN
            SELECT t_rec_lov('', r, d || flags) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, te.code_transp_entity)
                              FROM dual) d,
                           ' [' || l_transport_label || ':' ||
                           pk_sysdomain.get_domain('TRANSP_ENTITY.FLG_TRANSP', te.flg_transp, l_institution_language) ||
                           c_apex_list_id_separator || l_type_label || ':' ||
                           pk_sysdomain.get_domain('TRANSP_ENTITY.FLG_TYPE', te.flg_type, l_institution_language) || ']' flags,
                           tei.id_transp_ent_inst r
                      FROM transp_ent_inst tei
                      JOIN transp_entity te
                        ON tei.id_transp_entity = te.id_transp_entity
                     WHERE tei.id_institution = i_institution
                       AND tei.flg_available = g_flg_available
                       AND te.flg_available = g_flg_available
                       AND te.id_institution IN (i_institution, 0)
                     ORDER BY d)
             WHERE d IS NOT NULL;
        
        ELSIF i_sysconfig = 'DEFAULT_DISCH_REAS_DEST_TEHARPIST'
        THEN
            SELECT t_rec_lov('', r, d) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, dr.code_discharge_reason)
                              FROM dual) || c_apex_list_id_separator ||
                           (SELECT pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                  dd.code_discharge_dest)
                              FROM dual) d,
                           drd.id_disch_reas_dest r
                      FROM disch_reas_dest drd
                      JOIN discharge_reason dr
                        ON drd.id_discharge_reason = dr.id_discharge_reason
                      JOIN discharge_dest dd
                        ON drd.id_discharge_dest = dd.id_discharge_dest
                     WHERE drd.id_software_param = pk_alert_constant.g_soft_rehab
                       AND dr.id_content = 'TMP39.5'
                       AND dr.flg_available = g_flg_available
                       AND drd.flg_active = g_active
                       AND dd.flg_available = g_flg_available
                       AND drd.id_instit_param = i_institution
                     ORDER BY d)
             WHERE d IS NOT NULL;
        ELSIF i_sysconfig IN ('DEFAULT_DISCH_REAS_DEST', 'DEFAULT_DISCH_REAS_DEST_NUTRITIONIST')
        THEN
            SELECT t_rec_lov('', r, d || additional_attributes) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, dr.code_discharge_reason)
                              FROM dual) || c_apex_list_id_separator ||
                           (SELECT pk_translation.get_translation(l_institution_language, dd.code_discharge_dest)
                              FROM dual) d,
                           get_lov_id_format(table_varchar(dr.id_content, dd.id_content)) additional_attributes,
                           drd.id_disch_reas_dest r
                      FROM disch_reas_dest drd
                      JOIN discharge_reason dr
                        ON drd.id_discharge_reason = dr.id_discharge_reason
                      JOIN discharge_dest dd
                        ON drd.id_discharge_dest = dd.id_discharge_dest
                     WHERE dr.flg_available = g_flg_available
                       AND drd.flg_active = g_active
                       AND dd.flg_available = g_flg_available
                       AND drd.id_instit_param = i_institution
                       AND drd.id_software_param = i_software
                     ORDER BY d)
            
             WHERE d IS NOT NULL;
        
        ELSIF i_sysconfig IN ('DEFAULT_DISCHARGE_REASON')
        THEN
            SELECT t_rec_lov('', r, d || additional_vals) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, dr.code_discharge_reason)
                              FROM dual) d,
                           get_lov_id_format(table_varchar(dr.id_content)) additional_vals,
                           dr.id_discharge_reason r
                      FROM discharge_reason dr
                     WHERE dr.flg_available = g_flg_available)
             WHERE d IS NOT NULL
             ORDER BY d;
        
        ELSIF i_sysconfig = 'CARE_DISCHARGE_REASON'
        THEN
            SELECT t_rec_lov('', r, d || additional_attributes) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT (SELECT pk_translation.get_translation(l_institution_language, dr.code_discharge_reason)
                              FROM dual) || c_apex_list_id_separator ||
                           (SELECT pk_translation.get_translation(l_institution_language, dd.code_discharge_dest)
                              FROM dual) d,
                           decode(dcs.id_dep_clin_serv,
                                  NULL,
                                  '',
                                  get_lov_id_format(table_varchar(pk_translation.get_translation(l_institution_language,
                                                                                                 dd.code_department),
                                                                  pk_translation.get_translation(l_institution_language,
                                                                                                 cs.code_clinical_service)))) additional_attributes,
                           dr.id_discharge_reason r
                      FROM disch_reas_dest drd
                      JOIN discharge_reason dr
                        ON drd.id_discharge_reason = dr.id_discharge_reason
                      JOIN discharge_dest dd
                        ON drd.id_discharge_dest = dd.id_discharge_dest
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = drd.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service
                      LEFT JOIN department dd
                        ON dd.id_department = dcs.id_department
                     WHERE drd.id_software_param = pk_alert_constant.g_soft_primary_care
                       AND dr.flg_available = g_flg_available
                       AND drd.flg_active = g_active
                       AND dd.flg_available = g_flg_available
                       AND drd.id_instit_param = i_institution
                     ORDER BY d)
             WHERE d IS NOT NULL;
        
        ELSIF i_sysconfig = 'ADT_NATIONAL_HEALTH_PLAN_ID'
        THEN
        
            SELECT /*+ dynamic_sampling(trl,2) */
             t_rec_lov('', hp.id_health_plan, trl.desc_translation) BULK COLLECT
              INTO o_tbl_lov
              FROM TABLE(pk_translation.get_table_translation(l_institution_language, 'HEALTH_PLAN')) trl
             INNER JOIN health_plan hp
                ON (hp.code_health_plan = trl.code_translation)
             INNER JOIN health_plan_entity hpe
                ON (hpe.id_health_plan_entity = hp.id_health_plan_entity)
             WHERE hp.flg_available = g_flg_available
               AND hpe.flg_available = g_flg_available
               AND EXISTS (SELECT 0
                      FROM health_plan_instit hpi
                     WHERE hpi.id_health_plan = hp.id_health_plan
                       AND hpi.id_institution = i_institution)
               AND EXISTS (SELECT 0
                      FROM health_plan_entity_instit hpei
                     WHERE hpei.id_health_plan_entity = hpe.id_health_plan_entity
                       AND hpei.id_institution = i_institution)
               AND trl.desc_translation IS NOT NULL
             ORDER BY desc_translation;
        
        ELSIF i_sysconfig IN ( /*NOVOS_VALORES_VITALSIGN*/'VS_MANDATORY_EDIT_REASON',
                              'VS_BSA_CALC',
                              'VITAL_SIGN_UNIT_MEASURE_CONVERT',
                              'VITAL_SIGNS_ALLOWED_ON_CONS',
                              'VITAL_SIGN_ATTRIBUTES',
                              /*NEW_VALUES_PERIODIC_OBS */
                              'FLOW_SHEETS_SETS_SHOW_REF_VALUE',
                              'FLOW_SHEETS_SHOW_REF_VALUE',
                              'WOMEN_HEALTH_SHOW_REF_VALUE')
        THEN
            SELECT t_rec_lov('', val, desc_val) BULK COLLECT
              INTO o_tbl_lov
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, profissional(0, 0, 0), 'YES_NO', NULL));
        
        ELSIF i_sysconfig = 'ALLERGY_PRESC_TYPE'
        THEN
            SELECT t_rec_lov('', id_allergy_standard, id_allergy_standard) BULK COLLECT
              INTO o_tbl_lov
              FROM (SELECT DISTINCT id_allergy_standard
                      FROM allergy);
        
        ELSIF i_sysconfig = 'WOMEN_HEALTH_HPG_ID'
        THEN
            get_available_hpg_list(i_lang, i_institution, table_number(), o_tbl_lov);
        END IF;
    END get_sysconfig_list;
    /********************************************************************************************
    * Get display for apex LOV (TRANSLATED triage type)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/25
    ********************************************************************************************/
    PROCEDURE get_triagetype_list
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    BEGIN
        g_error := 'GET TRIAGE TYPE TRANSLATED AND AVAILABLE';
        SELECT t_rec_lov('', r, d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 trl.desc_translation || c_apex_list_id_separator || tt.acronym d, tt.id_triage_type r
                  FROM TABLE(pk_translation.get_table_translation(pk_utils.get_institution_language(i_institution),
                                                                  'TRIAGE_TYPE',
                                                                  g_no)) trl
                 INNER JOIN triage_type tt
                    ON (tt.code_triage_type = trl.code_translation)
                 WHERE tt.flg_available = g_flg_available
                 ORDER BY d);
    END get_triagetype_list;
    /********************************************************************************************
    * Get display for apex LOV (Software list ignoring viewer)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_all_software_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
        SELECT t_rec_lov('', r, d) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT s.id_ab_software r,
                       coalesce(s.description,
                                (SELECT pk_translation.get_translation(i_lang, s.code_software)
                                   FROM dual)) d
                  FROM ab_software s
                 WHERE (s.flg_viewer != g_flg_available OR s.flg_viewer IS NULL)
                   AND s.id_ab_software NOT IN (0, -1)
                 ORDER BY d);
    
    END get_all_software_list;
    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_all_institution_list
    (
        i_lang    IN language.id_language%TYPE,
        i_market  IN table_varchar DEFAULT NULL,
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
        IF i_market.count = 0
        THEN
            SELECT /*+ dynamic_sampling(trl,2) */
             t_rec_lov('', z.id_ab_institution, trl.desc_translation) BULK COLLECT
              INTO o_tbl_res
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'AB_INSTITUTION', 'N')) trl
             INNER JOIN ab_institution z
                ON (z.code_institution = trl.code_translation)
             WHERE z.flg_available = g_flg_available
               AND z.flg_external = g_no
             ORDER BY desc_translation;
        ELSE
            SELECT /*+ dynamic_sampling(trl,2) */
             t_rec_lov('', z.id_ab_institution, trl.desc_translation) BULK COLLECT
              INTO o_tbl_res
              FROM TABLE(pk_translation.get_table_translation(i_lang, 'AB_INSTITUTION', 'N')) trl
             INNER JOIN ab_institution z
                ON (z.code_institution = trl.code_translation)
             WHERE z.flg_available = g_flg_available
               AND z.flg_external = g_no
               AND z.id_ab_market = i_market(1)
             ORDER BY desc_translation;
        END IF;
    
    END get_all_institution_list;
    /********************************************************************************************
    * Get display for apex LOV (Timezones)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_timezone_list
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
        l_cur          pk_types.cursor_type;
        l_error        t_error_out;
        l_ret          BOOLEAN;
        l_display_id   table_varchar;
        l_display_desc table_varchar;
    
    BEGIN
        l_ret     := pk_backoffice.get_timezone_region_list(i_lang, l_cur, l_error);
        o_tbl_res := t_tbl_lov();
        FETCH l_cur BULK COLLECT
            INTO l_display_id, l_display_desc;
        CLOSE l_cur;
    
        FOR i IN 1 .. l_display_id.count
        LOOP
            o_tbl_res.extend();
            o_tbl_res(i) := t_rec_lov('', l_display_id(i), l_display_desc(i));
        END LOOP;
    
    END get_timezone_list;

    /********************************************************************************************
    * Get display for apex LOV (Building current list)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    PROCEDURE get_building_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_institution_language language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
    
        SELECT t_rec_lov('', id_building, desc_translation) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 (SELECT pk_utils.get_institution_name(i_lang, i_institution)
                    FROM dual) || c_apex_list_id_separator || trl.desc_translation ||
                 get_lov_id_format(table_varchar(b.id_building)) desc_translation,
                 b.id_building
                  FROM floors_institution fi
                  JOIN institution i
                    ON fi.id_institution = i.id_institution
                  JOIN building b
                    ON fi.id_building = b.id_building
                  JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                    ON trl.code_translation = b.code_building
                 WHERE b.flg_available = g_flg_available
                   AND (fi.id_institution = i_institution)
                
                UNION
                SELECT /*+ dynamic_sampling(trl,2) */
                 '- ' || trl.desc_translation || get_lov_id_format(table_varchar(b.id_building)), b.id_building
                  FROM building b
                  JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                    ON trl.code_translation = b.code_building
                 WHERE b.flg_available = g_flg_available
                   AND id_building NOT IN (SELECT id_building
                                             FROM floors_institution fi
                                            WHERE fi.id_building IS NOT NULL)
                UNION
                
                SELECT /*+ dynamic_sampling(trl,2) */
                 (SELECT pk_utils.get_institution_name(i_lang, fi.id_institution)
                    FROM dual) || c_apex_list_id_separator || trl.desc_translation ||
                 get_lov_id_format(table_varchar(b.id_building)) desc_translation,
                 b.id_building
                  FROM floors_institution fi
                  JOIN institution i
                    ON fi.id_institution = i.id_institution
                  JOIN building b
                    ON fi.id_building = b.id_building
                  JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                    ON trl.code_translation = b.code_building
                 WHERE b.flg_available = g_flg_available
                   AND fi.id_institution IN
                       (SELECT id_institution
                          FROM institution
                         WHERE id_parent = (SELECT id_parent
                                              FROM institution
                                             WHERE id_institution = i_institution)));
    
    END get_building_lov;
    /********************************************************************************************
    * Get display for apex LOV (Institution Group Select information)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/19
    ********************************************************************************************/
    PROCEDURE get_inst_group_lov
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
        SELECT t_rec_lov('', final_data.id_group, final_data.group_info) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT group_res.flg_relation || ':' || pk_utils.concat_table(inst_list, '; ') group_info,
                       group_res.flg_relation || ';' || group_res.id_group id_group
                  FROM (SELECT ig.id_group,
                               ig.flg_relation,
                               CAST(MULTISET (SELECT (SELECT pk_translation.get_translation(i_lang, i.code_institution)
                                               FROM dual)
                                       FROM institution i
                                      INNER JOIN institution_group d
                                         ON (d.id_institution = i.id_institution)
                                      WHERE d.flg_relation = ig.flg_relation
                                        AND d.id_group = ig.id_group) AS table_varchar) inst_list
                          FROM institution_group ig
                         GROUP BY id_group, flg_relation) group_res) final_data
         ORDER BY final_data.group_info;
    END get_inst_group_lov;
    /* get dcs lov to join in pre exec report */
    PROCEDURE get_dcs_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    BEGIN
        SELECT t_rec_lov('', id_dep_clin_serv, dep_clin_serv) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT (SELECT pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                              d.code_department)
                          FROM dual) || ' | ' || (SELECT pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                                        cs.code_clinical_service)
                                                    FROM dual) dep_clin_serv,
                       dcs.id_dep_clin_serv
                  FROM dep_clin_serv dcs
                 INNER JOIN department d
                    ON (d.id_department = dcs.id_department)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = dcs.id_clinical_service)
                 WHERE d.id_institution = i_institution
                 ORDER BY dep_clin_serv);
    
    END get_dcs_lov;
    /********************************************************************************************
    * Get display for apex LOV (get_dept|department|dcs list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_dcs_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    
        aux NUMBER;
    BEGIN
        --check if it is has digit
        SELECT COUNT(*)
          INTO aux
          FROM dual
         WHERE regexp_like(i_search, '[[:digit:]]');
        --if no filter, bring all
        IF i_search IS NULL
        THEN
        
            SELECT t_rec_lov('',
                             dcs.id_dep_clin_serv,
                             
                             pk_translation.get_translation(i_lang, d.code_dept) || '|' ||
                             pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                             pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                             pk_default_apex.get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.clinical_service cs
             INNER JOIN alert.dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN alert.department dpt
                ON dcs.id_department = dpt.id_department
             INNER JOIN alert.dept d
                ON d.id_dept = dpt.id_dept
             INNER JOIN alert.software_dept sd
                ON sd.id_dept = d.id_dept
             WHERE sd.id_software = i_software(1)
               AND d.id_institution = i_institution;
        ELSIF pk_utils.is_number(i_search) = g_flg_available
        THEN
            --if its a number, bring all by number
            SELECT t_rec_lov('',
                             dcs.id_dep_clin_serv,
                             pk_translation.get_translation(i_lang, d.code_dept) || '|' ||
                             pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                             pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                             pk_default_apex.get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.clinical_service cs
             INNER JOIN alert.dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN alert.department dpt
                ON dcs.id_department = dpt.id_department
             INNER JOIN alert.dept d
                ON d.id_dept = dpt.id_dept
             INNER JOIN alert.software_dept sd
                ON sd.id_dept = d.id_dept
             WHERE sd.id_software = i_software(1)
               AND d.id_institution = i_institution
               AND cs.id_clinical_service = i_search;
        ELSIF (pk_utils.is_number(i_search) = g_no AND aux = 1)
        THEN
            --if has number but its not a number, bring all by id_content
            SELECT t_rec_lov('',
                             dcs.id_dep_clin_serv,
                             pk_translation.get_translation(i_lang, d.code_dept) || '|' ||
                             pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                             pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                             pk_default_apex.get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.clinical_service cs
             INNER JOIN alert.dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN alert.department dpt
                ON dcs.id_department = dpt.id_department
             INNER JOIN alert.dept d
                ON d.id_dept = dpt.id_dept
             INNER JOIN alert.software_dept sd
                ON sd.id_dept = d.id_dept
             WHERE sd.id_software = i_software(1)
               AND d.id_institution = i_institution
               AND cs.id_content = i_search;
        ELSE
            --if has number but its not a number, bring all by id_content
        
            SELECT t_rec_lov('',
                             dcs.id_dep_clin_serv,
                             pk_translation.get_translation(i_lang, d.code_dept) || '|' ||
                             pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                             pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                             pk_default_apex.get_lov_id_format(table_varchar(cs.id_clinical_service, cs.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.clinical_service cs
             INNER JOIN alert.dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
             INNER JOIN alert.department dpt
                ON dcs.id_department = dpt.id_department
             INNER JOIN alert.dept d
                ON d.id_dept = dpt.id_dept
             INNER JOIN alert.software_dept sd
                ON sd.id_dept = d.id_dept
             WHERE sd.id_software = i_software(1)
               AND d.id_institution = i_institution
               AND upper(pk_translation.get_translation(i_lang, cs.code_clinical_service)) LIKE
                   '%' || upper(i_search) || '%';
        
        END IF;
    
    END get_dcs_list_lov;

    /********************************************************************************************
    * Get display for apex LOV (complaint list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_complaint_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution NUMBER,
        i_software    IN table_number,
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    
        aux           NUMBER;
        l_flg_type_c  VARCHAR(1) := 'C';
        l_flg_type_ct VARCHAR(2) := 'CT';
        l_zero        NUMBER := 0;
    BEGIN
        --check if it is has digit
        SELECT COUNT(*)
          INTO aux
          FROM dual
         WHERE regexp_like(i_search, '[[:digit:]]');
        dbms_output.put_line(1);
        IF i_search IS NULL
        THEN
            --if no filter, bring all
            SELECT t_rec_lov('',
                             c.id_complaint,
                             pk_translation.get_translation(i_lang, c.code_complaint) ||
                             pk_default_apex.get_lov_id_format(table_varchar(c.id_complaint, c.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.complaint c
             WHERE c.flg_available = g_flg_available
               AND EXISTS (SELECT 1
                      FROM alert.doc_template_context dtc
                     WHERE dtc.id_institution IN (i_institution, l_zero)
                       AND dtc.id_software IN (i_software(1), l_zero)
                       AND dtc.flg_type IN (l_flg_type_ct, l_flg_type_c)
                       AND dtc.id_context = c.id_complaint);
        
        ELSIF pk_utils.is_number(i_search) = g_flg_available
        THEN
            --if its a number, bring all by number
        
            SELECT t_rec_lov('',
                             c.id_complaint,
                             
                             pk_translation.get_translation(i_lang, c.code_complaint) ||
                             pk_default_apex.get_lov_id_format(table_varchar(c.id_complaint, c.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.complaint c
             WHERE c.flg_available = g_flg_available
               AND c.id_complaint = i_search
               AND EXISTS (SELECT 1
                      FROM alert.doc_template_context dtc
                     WHERE dtc.id_institution IN (i_institution, l_zero)
                       AND dtc.id_software IN (i_software(1), l_zero)
                       AND dtc.flg_type IN (l_flg_type_ct, l_flg_type_c)
                       AND dtc.id_context = c.id_complaint);
        
        ELSIF (pk_utils.is_number(i_search) = g_no AND aux = 1)
        THEN
            --if has number but its not a number, bring all by id_content
        
            SELECT t_rec_lov('',
                             c.id_complaint,
                             
                             pk_translation.get_translation(i_lang, c.code_complaint) ||
                             pk_default_apex.get_lov_id_format(table_varchar(c.id_complaint, c.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.complaint c
             WHERE c.flg_available = g_flg_available
               AND c.id_content = i_search
               AND EXISTS (SELECT 1
                      FROM alert.doc_template_context dtc
                     WHERE dtc.id_institution IN (i_institution, l_zero)
                       AND dtc.id_software IN (i_software(1), l_zero)
                       AND dtc.flg_type IN (l_flg_type_ct, l_flg_type_c)
                       AND dtc.id_context = c.id_complaint);
        
        ELSE
            --if has number but its not a number, bring all by id_content
            SELECT t_rec_lov('',
                             c.id_complaint,
                             
                             pk_translation.get_translation(i_lang, c.code_complaint) ||
                             pk_default_apex.get_lov_id_format(table_varchar(c.id_complaint, c.id_content))) BULK COLLECT
              INTO o_tbl_res
              FROM alert.complaint c
             WHERE c.flg_available = g_flg_available
                  
               AND upper(pk_translation.get_translation(i_lang, c.code_complaint) ||
                         pk_default_apex.get_lov_id_format(table_varchar(c.id_complaint, c.id_content))) LIKE
                   '%' || upper(i_search) || '%'
               AND EXISTS (SELECT 1
                      FROM alert.doc_template_context dtc
                     WHERE dtc.id_institution IN (i_institution, l_zero)
                       AND dtc.id_software IN (i_software(1), l_zero)
                       AND dtc.flg_type IN (l_flg_type_ct, l_flg_type_c)
                       AND dtc.id_context = c.id_complaint);
        
        END IF;
    
    END get_complaint_list_lov;
    /********************************************************************************************
    * Get display for apex LOV (get_content list)
    *
    * @author                        JM
    * @version                       2.6.3
    * @since                         2013/11/24
    ********************************************************************************************/
    PROCEDURE get_content_list_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_condition   IN table_varchar DEFAULT table_varchar(),
        i_search      IN VARCHAR,
        o_tbl_res     OUT t_tbl_lov
    ) IS
    
        aux_table table_varchar;
    
        l_flg_lab_test_condition      VARCHAR(1) := 'A';
        l_flg_lab_group_condition     VARCHAR(2) := 'AG';
        l_flg_img_exam_condition      VARCHAR(1) := 'I';
        l_flg_other_exam_condition    VARCHAR(1) := 'O';
        l_flg_diag_condition          VARCHAR(1) := 'D';
        l_flg_procedures_condition    VARCHAR(1) := 'P';
        l_flg_sr_procedures_condition VARCHAR(2) := 'SP';
        l_flg_complaint_condition     VARCHAR(1) := 'C';
        l_flg_sample_text_condition   VARCHAR(2) := 'ST';
        l_flg_rehab_condition         VARCHAR(1) := 'R';
        l_flg_body_diagrams_condition VARCHAR(2) := 'BD';
        l_flg_exam_cat_condition      VARCHAR(2) := 'EC';
        l_flg_order_sets_condition    VARCHAR(2) := 'OS';
    
        l_flg_img_exam   VARCHAR(1) := 'I';
        l_flg_other_exam VARCHAR(1) := 'E';
    
        l_order_set_t VARCHAR(1) := 'T';
        l_order_set_f VARCHAR(1) := 'F';
    
        l_condition VARCHAR2(100 CHAR);
    
    BEGIN
    
        IF i_condition.count = 0
        THEN
            l_condition := NULL;
        ELSE
            l_condition := i_condition(1);
        END IF;
    
        SELECT column_value BULK COLLECT
          INTO aux_table
          FROM TABLE(CAST((pk_utils.str_split(REPLACE(i_search, chr(10), chr(32)), chr(32))) AS table_varchar)) p;
    
        IF pk_utils.is_number(aux_table(1)) = g_flg_available
        THEN
        
            IF l_flg_lab_test_condition = l_condition
            THEN
                SELECT t_rec_lov('',
                                 a.id_analysis || '|' || st.id_sample_type,
                                 'L:' || pk_translation.get_translation(i_lang, a.code_analysis) || ' ST:' ||
                                 pk_translation.get_translation(i_lang, st.code_sample_type)) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.analysis_sample_type scr_table
                 INNER JOIN alert.analysis a
                    ON scr_table.id_analysis = a.id_analysis
                 INNER JOIN alert.sample_type st
                    ON st.id_sample_type = scr_table.id_sample_type
                 WHERE scr_table.flg_available = g_flg_available
                   AND a.flg_available = g_flg_available
                   AND st.flg_available = g_flg_available
                   AND scr_table.id_analysis IN (SELECT column_value
                                                   FROM TABLE(aux_table) p);
            
            ELSIF l_flg_lab_group_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_analysis_group,
                                 pk_translation.get_translation(i_lang, scr_table.code_analysis_group) ||
                                 get_lov_id_format(table_varchar(id_analysis_group, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.analysis_group scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_analysis_group IN (SELECT column_value
                                                         FROM TABLE(aux_table) p);
            
            ELSIF l_flg_img_exam_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam) ||
                                 get_lov_id_format(table_varchar(id_exam, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.flg_type = l_flg_img_exam
                   AND scr_table.id_exam IN (SELECT column_value
                                               FROM TABLE(aux_table) p);
            
            ELSIF l_flg_other_exam_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam) ||
                                 get_lov_id_format(table_varchar(id_exam, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.flg_type = l_flg_other_exam
                   AND scr_table.id_exam IN (SELECT column_value
                                               FROM TABLE(aux_table) p);
            
            ELSIF l_flg_diag_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_concept_version,
                                 pk_translation.get_translation(i_lang,
                                                                (CAST(pk_api_pfh_diagnosis_in.get_diag_preferred_term(scr_table.id_concept_version) AS
                                                                      VARCHAR2(200 CHAR)))) ||
                                 get_lov_id_format(table_varchar(id_concept_version))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert_core_data.concept_version scr_table
                 WHERE scr_table.id_concept_version IN (SELECT column_value
                                                          FROM TABLE(aux_table) p);
            
            ELSIF l_flg_procedures_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_intervention,
                                 pk_translation.get_translation(i_lang, scr_table.code_intervention) ||
                                 get_lov_id_format(table_varchar(id_intervention, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.intervention scr_table
                 WHERE scr_table.flg_status = g_active
                   AND scr_table.id_intervention IN (SELECT column_value
                                                       FROM TABLE(aux_table) p);
            
            ELSIF l_flg_sr_procedures_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_sr_intervention,
                                 pk_translation.get_translation(i_lang, scr_table.code_sr_intervention) ||
                                 get_lov_id_format(table_varchar(id_sr_intervention, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.sr_intervention scr_table
                 WHERE scr_table.flg_status = g_active
                   AND scr_table.id_sr_intervention IN (SELECT column_value
                                                          FROM TABLE(aux_table) p)
                
                ;
            
            ELSIF l_flg_complaint_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_complaint,
                                 pk_translation.get_translation(i_lang, scr_table.code_complaint) ||
                                 get_lov_id_format(table_varchar(id_complaint, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.complaint scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_complaint IN (SELECT column_value
                                                    FROM TABLE(aux_table) p);
            
            ELSIF l_flg_sample_text_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_sample_text,
                                 pk_translation.get_translation(i_lang, scr_table.code_title_sample_text) ||
                                 get_lov_id_format(table_varchar(id_sample_text, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.sample_text scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_sample_text IN (SELECT column_value
                                                      FROM TABLE(aux_table) p);
            
            ELSIF l_flg_body_diagrams_condition = l_condition
            THEN
                --dbms_output.put_line('OUTBD' || aux_table(1));
            
                SELECT t_rec_lov('',
                                 id_diagram_layout,
                                 pk_translation.get_translation(i_lang, scr_table.code_diagram_layout) ||
                                 get_lov_id_format(table_varchar(id_diagram_layout))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.diagram_layout scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_diagram_layout IN (SELECT column_value
                                                         FROM TABLE(aux_table) p);
            ELSIF l_flg_exam_cat_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam_cat,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam_cat) ||
                                 get_lov_id_format(table_varchar(id_exam_cat, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam_cat scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_exam_cat IN (SELECT column_value
                                                   FROM TABLE(aux_table) p);
            ELSIF l_flg_order_sets_condition = l_condition
            THEN
                --dbms_output.put_line('OUTOS' || aux_table(1));
            
                SELECT t_rec_lov('',
                                 id_order_set,
                                 scr_table.title || get_lov_id_format(table_varchar(id_order_set, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.order_set scr_table
                 WHERE scr_table.flg_status IN (l_order_set_f, l_order_set_t)
                   AND scr_table.id_institution = i_institution
                   AND scr_table.id_order_set IN (SELECT column_value
                                                    FROM TABLE(aux_table) p);
            ELSIF l_flg_rehab_condition = l_condition
                  AND aux_table(1) NOT LIKE '%TMP%'
            THEN
            
                SELECT t_rec_lov('',
                                 id_rehab_session_type,
                                 pk_translation.get_translation(i_lang, scr_table.code_rehab_session_type) ||
                                 get_lov_id_format(table_varchar(id_rehab_session_type, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.rehab_session_type scr_table
                 WHERE scr_table.id_rehab_session_type IN
                       (SELECT column_value
                          FROM TABLE(aux_table) p);
            
            ELSIF l_flg_rehab_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_rehab_session_type,
                                 pk_translation.get_translation(i_lang, scr_table.code_rehab_session_type) ||
                                 get_lov_id_format(table_varchar(id_rehab_session_type, scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.rehab_session_type scr_table
                 WHERE scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            END IF;
        ELSE
        
            IF l_flg_lab_test_condition = l_condition
            THEN
                SELECT t_rec_lov('',
                                 a.id_analysis || '|' || st.id_sample_type,
                                 'L:' || pk_translation.get_translation(i_lang, a.code_analysis) || ' ST:' ||
                                 pk_translation.get_translation(i_lang, st.code_sample_type) ||
                                 get_lov_id_format(table_varchar(a.id_analysis || '|' || st.id_sample_type,
                                                                 scr_table.id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.analysis_sample_type scr_table
                 INNER JOIN alert.analysis a
                    ON scr_table.id_analysis = a.id_analysis
                 INNER JOIN alert.sample_type st
                    ON st.id_sample_type = scr_table.id_sample_type
                 WHERE scr_table.flg_available = g_flg_available
                   AND a.flg_available = g_flg_available
                   AND st.flg_available = g_flg_available
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            ELSIF l_flg_lab_group_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_analysis_group,
                                 pk_translation.get_translation(i_lang, scr_table.code_analysis_group) ||
                                 get_lov_id_format(table_varchar(id_analysis_group, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.analysis_group scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_img_exam_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam) ||
                                 get_lov_id_format(table_varchar(id_exam, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.flg_type = l_flg_img_exam
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p)
                
                ;
            
            ELSIF l_flg_other_exam_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam) ||
                                 get_lov_id_format(table_varchar(id_exam, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.flg_type = l_flg_other_exam
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_procedures_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_intervention,
                                 pk_translation.get_translation(i_lang, scr_table.code_intervention) ||
                                 get_lov_id_format(table_varchar(id_intervention, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.intervention scr_table
                 WHERE scr_table.flg_status = g_active
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_sr_procedures_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_sr_intervention,
                                 pk_translation.get_translation(i_lang, scr_table.code_sr_intervention) ||
                                 get_lov_id_format(table_varchar(id_sr_intervention, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.sr_intervention scr_table
                 WHERE scr_table.flg_status = g_active
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_complaint_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_complaint,
                                 pk_translation.get_translation(i_lang, scr_table.code_complaint) ||
                                 get_lov_id_format(table_varchar(id_complaint, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.complaint scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_sample_text_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_sample_text,
                                 pk_translation.get_translation(i_lang, scr_table.code_title_sample_text) ||
                                 get_lov_id_format(table_varchar(id_sample_text, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.sample_text scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            
            ELSIF l_flg_exam_cat_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_exam_cat,
                                 pk_translation.get_translation(i_lang, scr_table.code_exam_cat) ||
                                 get_lov_id_format(table_varchar(id_exam_cat, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.exam_cat scr_table
                 WHERE scr_table.flg_available = g_flg_available
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            ELSIF l_flg_order_sets_condition = l_condition
            THEN
            
                SELECT t_rec_lov('',
                                 id_order_set,
                                 scr_table.title || get_lov_id_format(table_varchar(id_order_set, id_content))) BULK COLLECT
                  INTO o_tbl_res
                  FROM alert.order_set scr_table
                 WHERE scr_table.flg_status IN (l_order_set_f, l_order_set_t)
                   AND scr_table.id_institution = i_institution
                   AND scr_table.id_content IN (SELECT column_value
                                                  FROM TABLE(aux_table) p);
            END IF;
        END IF;
    END get_content_list_lov;
    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_visit_lov
    (
        i_lang         IN language.id_language%TYPE,
        i_patient_list IN table_varchar,
        
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT a.id_visit || '-' || a.flg_status || '-' || a.dt_creation descr, id_visit id
                  FROM visit a
                 WHERE a.id_patient IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                          FROM TABLE(i_patient_list) p)
                   AND a.id_visit NOT IN (0, -1)) res
         ORDER BY descr;
    
    END get_visit_lov;

    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_episode_lov
    (
        i_lang       IN language.id_language%TYPE,
        i_visit_list IN table_varchar,
        
        o_tbl_res OUT t_tbl_lov
    ) IS
    BEGIN
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT e.id_episode || '-' || e.id_visit || '-' || e.id_patient || '-' || e.flg_status || '-' ||
                       e.id_epis_type descr,
                       e.id_episode id
                  FROM episode e
                 WHERE e.id_visit IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                       column_value
                                        FROM TABLE(i_visit_list) p)
                   AND e.id_episode NOT IN (0, -1)) res
         ORDER BY descr;
    
    END get_episode_lov;

    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_patient_lov
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_condition   IN table_varchar,
        o_tbl_res     OUT t_tbl_lov
    ) IS
        l_check NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_check
          FROM TABLE(i_condition) p
         WHERE p.column_value = g_active;
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT p.name descr, p.id_patient id
                  FROM patient p
                 WHERE p.id_patient NOT IN (0, -1)
                   AND EXISTS
                 (SELECT 1
                          FROM visit v
                         WHERE v.id_patient = p.id_patient
                           AND v.id_institution = i_institution)
                   AND (l_check = 0 OR NOT EXISTS (SELECT 1
                                                     FROM visit v
                                                    WHERE v.id_patient = p.id_patient
                                                      AND v.id_institution != i_institution))) res
         ORDER BY descr;
    
    END get_patient_lov;

    ---
    PROCEDURE get_valid_dcs_for_softwares
    (
        i_lang        IN VARCHAR2,
        i_institution IN NUMBER,
        i_soft        IN table_number,
        i_dcs         IN table_number,
        o_dcs         OUT table_number
    ) IS
    BEGIN
        pk_api_backoffice_default.get_valid_dcs_for_softwares(i_lang, i_institution, i_soft, i_dcs, o_dcs);
    END get_valid_dcs_for_softwares;
    /********************************************************************************************
    * Pre Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION pre_default_content
    (
        i_lang        IN language.id_language%TYPE,
        i_sync_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lang   IN VARCHAR2 DEFAULT 'N',
        i_sequence    IN VARCHAR2 DEFAULT 'N',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_error_out t_error_out;
    BEGIN
        g_error := 'ROUTING TO ALERT DEFAULT CONTENT PKG';
        IF NOT pk_default_content.pre_default_content(i_lang,
                                                      i_sync_lucene,
                                                      i_drop_lucene,
                                                      i_drop_lang,
                                                      i_sequence,
                                                      l_error_out)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error_out.ora_sqlcode,
                                              l_error_out.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRE_DEFAULT_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRE_DEFAULT_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END pre_default_content;

    /********************************************************************************************
    * Post Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION post_default_content
    (
        i_create_lucene_all   IN VARCHAR2 DEFAULT 'N',
        i_create_lucene_byjob IN VARCHAR2 DEFAULT 'N',
        i_start_bylang        IN NUMBER DEFAULT NULL,
        i_sync_lucene         IN VARCHAR2 DEFAULT 'N',
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_error_out t_error_out;
    BEGIN
        g_error := 'ROUTING TO ALERT DEFAULT CONTENT PKG';
        IF NOT pk_default_content.post_default_content(i_create_lucene_all,
                                                       i_create_lucene_byjob,
                                                       i_start_bylang,
                                                       i_sync_lucene,
                                                       l_error_out)
        THEN
            RAISE l_exception;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(1,
                                              l_error_out.ora_sqlcode,
                                              l_error_out.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PRE_DEFAULT_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'POST_DEFAULT_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END post_default_content;
    /* Register Backoffice ADMIN User via Apex */
    PROCEDURE set_system_admin
    (
        i_lang        IN language.id_language%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_id_inst     IN institution.id_institution%TYPE,
        i_id_country  IN country.id_country%TYPE,
        i_title       IN professional.title%TYPE,
        i_nick_name   IN professional.nick_name%TYPE,
        i_gender      IN professional.gender%TYPE,
        i_dt_birth    IN VARCHAR2,
        i_email       IN professional.email%TYPE,
        i_work_phone  IN professional.num_contact%TYPE,
        i_cell_phone  IN professional.cell_phone%TYPE,
        i_fax         IN professional.fax%TYPE,
        i_first_name  IN professional.first_name%TYPE,
        i_middle_name IN professional.middle_name%TYPE,
        i_last_name   IN professional.last_name%TYPE,
        i_id_cat      IN category.id_category%TYPE,
        i_templ       IN profile_template.id_profile_template%TYPE,
        i_user        IN VARCHAR,
        i_pass        IN VARCHAR,
        o_id_prof     OUT professional.id_professional%TYPE,
        o_error       OUT t_error_out
    ) IS
        l_exception EXCEPTION;
        l_state               VARCHAR2(1) := '';
        l_icon                VARCHAR2(100) := '';
        l_backoffice_software NUMBER := 26;
        l_prof_institution    prof_institution.id_prof_institution%TYPE;
    BEGIN
        IF NOT pk_api_backoffice.set_institution_administrator(i_lang,
                                                               l_backoffice_software,
                                                               i_id_prof,
                                                               i_id_inst,
                                                               NULL,
                                                               i_title,
                                                               i_nick_name,
                                                               i_gender,
                                                               i_dt_birth,
                                                               i_email,
                                                               i_work_phone,
                                                               i_cell_phone,
                                                               i_fax,
                                                               i_first_name,
                                                               i_middle_name,
                                                               i_last_name,
                                                               i_id_cat,
                                                               TRUE,
                                                               o_id_prof,
                                                               o_error)
        THEN
            g_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
            RAISE l_exception;
        END IF;
    
        pk_api_ab_tables.upd_ins_into_ab_user_info(i_id_ab_user_info    => o_id_prof,
                                                   i_login              => i_user,
                                                   i_password           => i_pass,
                                                   i_import_code        => NULL,
                                                   i_record_status      => 'A',
                                                   i_institution_key    => i_id_inst,
                                                   i_flg_is_enable      => 'A',
                                                   i_first_name         => NULL,
                                                   i_last_name          => NULL,
                                                   i_full_name          => NULL,
                                                   i_external_system    => NULL,
                                                   i_external_system_id => NULL,
                                                   i_secret_quest       => NULL,
                                                   i_secret_answ        => NULL,
                                                   i_id_language        => i_lang,
                                                   i_flg_temporary      => 'N',
                                                   i_date_creation_tstz => NULL,
                                                   o_id_ab_user_info    => o_id_prof);
    
        /*        IF NOT pk_profile.save_prof_all_category(i_lang,
                                                 o_id_prof,
                                                 i_id_inst,
                                                 table_number(i_id_cat),
                                                 table_number(NULL),
                                                 table_number(),
                                                 l_user_cat,
                                                 o_error)
        THEN
            RAISE l_exception;
        END IF;*/
    
        IF NOT pk_api_backoffice.set_admin_template_list(i_lang             => i_lang,
                                                         i_id_prof          => nvl(i_id_prof, o_id_prof),
                                                         i_inst             => table_number(i_id_inst),
                                                         i_soft             => table_number(l_backoffice_software),
                                                         i_id_dep_clin_serv => NULL,
                                                         i_templ            => table_number(i_templ),
                                                         i_commit_at_end    => TRUE,
                                                         o_error            => o_error)
        THEN
            g_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
            RAISE l_exception;
        END IF;
    
        /*IF NOT pk_profile.set_current_profile(i_lang        => i_lang,
                                              i_prof        => profissional(o_id_prof, i_id_inst, l_backoffice_software),
                                              i_id_category => i_id_cat,
                                              i_flg_viewer  => g_flg_available,
                                              o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;*/
    
        /*IF NOT pk_api_backoffice.set_admin_app_user(i_lang            => i_lang,
                                                    i_user            => i_user,
                                                    i_pass            => i_pass,
                                                    i_sec_quest       => NULL,
                                                    i_sec_ans         => NULL,
                                                    i_id_professional => nvl(i_id_prof, o_id_prof),
                                                    i_finger          => table_clob(),
                                                    i_finger_type     => table_varchar(),
                                                    i_commit_at_end   => TRUE,
                                                    i_flg_tools       => g_no,
                                                    i_old_pass        => NULL,
                                                    i_id_institution  => i_id_inst,
                                                    o_error           => o_error)
        THEN
            g_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
            RAISE l_exception;
        END IF;*/
    
        IF NOT pk_api_backoffice.set_prof_institution_state(i_lang,
                                                            nvl(i_id_prof, o_id_prof),
                                                            i_id_inst,
                                                            g_active,
                                                            NULL,
                                                            l_state,
                                                            l_icon,
                                                            o_error)
        THEN
            g_error := 'PK_API_BACKOFFICE PROCESSING ERROR ' || o_error.log_id;
            RAISE l_exception;
        END IF;
        g_error := 'GET PROF_INSTITUTION ID (' || nvl(i_id_prof, o_id_prof) || ',' || i_id_inst || ')';
        SELECT nvl((SELECT pi.id_prof_institution
                     FROM prof_institution pi
                    WHERE pi.id_professional = nvl(i_id_prof, o_id_prof)
                      AND pi.id_institution = i_id_inst
                      AND pi.flg_state = 'A'
                      AND pi.dt_end_tstz IS NULL),
                   0)
          INTO l_prof_institution
          FROM dual;
    
        g_error := 'LAUNCH IA EVENT TO PROCESSOR ';
        alert_inter.pk_ia_event_backoffice.prof_schedule_info_update(l_prof_institution, i_id_inst);
        g_error := 'SET PROFESSIONAL CREDENTIALS';
        IF NOT alert_core_func.pk_idp_user_cfg.set_user_credentials(i_compl_name  => pk_backoffice.create_name_formated(i_lang           => i_lang,
                                                                                                                        i_id_institution => i_id_inst,
                                                                                                                        i_first_name     => i_first_name,
                                                                                                                        i_midle_name     => i_middle_name,
                                                                                                                        i_last_name      => i_last_name),
                                                                    i_email       => i_email,
                                                                    i_def_lang    => i_lang,
                                                                    i_first_name  => i_first_name,
                                                                    i_middle_name => i_middle_name,
                                                                    i_username    => i_user,
                                                                    i_password    => i_pass,
                                                                    i_sec_answer  => i_pass,
                                                                    o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SYSTEM_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SYSTEM_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END set_system_admin;
    /* Association between registered DB professional and institution*/
    PROCEDURE associate_system_admin
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_inst        IN institution.id_institution%TYPE,
        i_id_origin_inst IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) IS
        l_flg_state           prof_institution.flg_state%TYPE;
        l_icon                VARCHAR2(200);
        l_backoffice_software NUMBER := 26;
        l_exception EXCEPTION;
        l_templ NUMBER;
    
        l_user_cat prof_cat.id_category%TYPE := 0;
    BEGIN
        SELECT pt.id_profile_template
          INTO l_templ
          FROM professional p
          JOIN prof_profile_template ppt
            ON ppt.id_professional = p.id_professional
           AND ppt.id_software = l_backoffice_software
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
         WHERE nvl(p.flg_prof_test, g_no) = g_no
           AND p.id_professional = i_id_prof
           AND ppt.id_institution = i_id_origin_inst;
    
        BEGIN
            SELECT pc.id_category
              INTO l_user_cat
              FROM prof_cat pc
             WHERE pc.id_professional = i_id_prof
               AND pc.id_institution = i_id_origin_inst;
        EXCEPTION
            WHEN no_data_found THEN
                l_user_cat := 20;
        END;
    
        BEGIN
            INSERT INTO prof_cat
                (id_prof_cat, id_professional, id_category, id_institution, id_category_sub)
            VALUES
                (seq_prof_cat.nextval, i_id_prof, l_user_cat, i_id_inst, NULL);
        EXCEPTION
            WHEN dup_val_on_index THEN
                NULL;
        END;
    
        /*IF NOT pk_profile.save_prof_all_category(i_lang,
                                                 i_id_prof,
                                                 i_id_inst,
                                                 table_number(20),
                                                 table_number(NULL),
                                                 l_temp_array,
                                                 l_user_cat,
                                                 o_error)
        THEN
            RAISE l_exception;
        END IF;*/
    
        IF NOT pk_api_backoffice.intf_set_prof_institution(i_lang            => i_lang,
                                                           i_id_professional => i_id_prof,
                                                           i_id_institution  => i_id_inst,
                                                           i_flg_state       => g_active,
                                                           i_num_mecan       => NULL,
                                                           o_flg_state       => l_flg_state,
                                                           o_icon            => l_icon,
                                                           o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT pk_api_backoffice.set_admin_template_list(i_lang             => i_lang,
                                                         i_id_prof          => i_id_prof,
                                                         i_inst             => table_number(i_id_inst),
                                                         i_soft             => table_number(l_backoffice_software),
                                                         i_id_dep_clin_serv => NULL,
                                                         i_templ            => table_number(l_templ),
                                                         i_commit_at_end    => TRUE,
                                                         o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        /*IF NOT pk_profile.set_current_profile(i_lang        => i_lang,
                                              i_prof        => profissional(i_id_prof, i_id_inst, l_backoffice_software),
                                              i_id_category => 20,
                                              i_flg_viewer  => g_flg_available,
                                              o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;*/
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ASSOCIATE_SYSTEM_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ASSOCIATE_SYSTEM_ADMIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END associate_system_admin;
    FUNCTION get_inst_admins_lov
    (
        i_lang        language.id_language%TYPE,
        i_institution institution.id_institution%TYPE
    ) RETURN t_coll_professional IS
        l_professional_table  t_coll_professional;
        l_backoffice_software NUMBER := 26;
    BEGIN
    
        SELECT t_rec_professional(p.id_professional,
                                  p.nick_name,
                                  su.login,
                                  (SELECT pk_translation.get_translation(i_lang, pt.code_profile_template)
                                     FROM dual),
                                  (SELECT pk_sysdomain.get_domain('PROFESSIONAL.TITLE', p.title, i_lang)
                                     FROM dual),
                                  (SELECT pk_sysdomain.get_domain('PROFESSIONAL.GENDER', p.gender, i_lang)
                                     FROM dual),
                                  (SELECT pk_translation.get_translation(i_lang,
                                                                         'CATEGORY.CODE_CATEGORY.' || pc.id_category)
                                     FROM dual),
                                  NULL,
                                  NULL,
                                  NULL) BULK COLLECT
          INTO l_professional_table
          FROM professional p
          JOIN prof_cat pc
            ON p.id_professional = pc.id_professional
          JOIN prof_institution pi
            ON p.id_professional = pi.id_professional
          JOIN ab_user_info su
            ON su.id_ab_user_info = p.id_professional
          JOIN prof_profile_template ppt
            ON ppt.id_institution = pi.id_institution
           AND ppt.id_professional = p.id_professional
           AND ppt.id_software = l_backoffice_software
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
         WHERE p.flg_state = g_active
           AND pi.flg_state = p.flg_state
           AND pc.id_institution = pi.id_institution
           AND pi.id_institution = i_institution
           AND pi.dt_end_tstz IS NULL;
    
        RETURN l_professional_table;
    END get_inst_admins_lov;

    FUNCTION get_profs_all_lov
    (
        i_lang        language.id_language%TYPE,
        i_institution institution.id_institution%TYPE
    ) RETURN t_coll_professional IS
        l_professionals       t_coll_professional;
        l_backoffice_software NUMBER := 26;
    BEGIN
        SELECT t_rec_professional(p.id_professional,
                                  NULL,
                                  fsu.login,
                                  pt.code_profile_template,
                                  NULL,
                                  p.gender,
                                  'CATEGORY.CODE_CATEGORY.' || pc.id_category,
                                  MAX(ppt.id_institution),
                                  p.name,
                                  p.dt_birth) BULK COLLECT
          INTO l_professionals
          FROM professional p
          JOIN ab_user_info fsu
            ON (fsu.id_ab_user_info = p.id_professional)
        
          JOIN prof_cat pc
            ON p.id_professional = pc.id_professional
        
          JOIN prof_profile_template ppt
            ON ppt.id_professional = p.id_professional
           AND ppt.id_software = l_backoffice_software
        
          JOIN profile_template pt
            ON pt.id_profile_template = ppt.id_profile_template
         WHERE nvl(p.flg_prof_test, 'N') = 'N'
           AND NOT EXISTS (SELECT 0
                  FROM prof_institution pi
                 WHERE pi.id_institution = i_institution
                   AND pi.id_professional = p.id_professional
                   AND pi.dt_end_tstz IS NULL)
           AND EXISTS (SELECT 0
                  FROM prof_institution pi
                 WHERE pi.id_institution != i_institution
                   AND pi.dt_end_tstz IS NULL)
         GROUP BY p.id_professional, fsu.login, pt.code_profile_template, p.gender, pc.id_category, p.name, p.dt_birth;
    
        RETURN l_professionals;
    
    END get_profs_all_lov;

    /********************************************************************************************
    * Get display for apex LOV (FLG_OWNER on po_param_wh)
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    PROCEDURE get_ppw_flg_owner_lov
    (
        i_lang    IN language.id_language%TYPE,
        o_tbl_res OUT t_tbl_lov
    ) IS
    
        l_flg_mother VARCHAR2(200) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PREGNANCY_PO_T004');
        l_flg_fetus  VARCHAR2(200) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PREGNANCY_PO_T005');
    
    BEGIN
    
        SELECT t_rec_lov('', res.id, res.descr) BULK COLLECT
          INTO o_tbl_res
          FROM (SELECT l_flg_mother descr, 'M' id
                  FROM dual
                UNION
                SELECT l_flg_fetus descr, 'F' id
                  FROM dual) res
         ORDER BY descr;
    
    END get_ppw_flg_owner_lov;

    /********************************************************************************************
    * Fix sequences related to Default Process
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/06/28
    ********************************************************************************************/
    PROCEDURE fix_default_sequences
    (
        i_lang      IN language.id_language%TYPE,
        o_tables    OUT table_varchar,
        o_actions   OUT table_varchar,
        o_positions OUT table_number,
        o_error     OUT t_error_out
    ) IS
        l_seq_prefix CONSTANT VARCHAR2(4) := 'SEQ_';
        l_id_prefix  CONSTANT VARCHAR2(3) := 'ID_';
        l_avl_val   NUMBER(38); -- valor max na tabela, max_value de NUMBER tem 38 digitos
        l_id_exists NUMBER := 0;
        l_range CONSTANT NUMBER(6) := 20000;
        l_new_seq_value NUMBER(38);
        l_seq_max_val   NUMBER(38);
        l_max_number    NUMBER(38) := 99999999999999999999999999999999999999;
        l_col_precision NUMBER(6);
        l_owner_to_ignore CONSTANT VARCHAR2(20) := 'ALERT_DEFAULT';
        sequence_not_exist EXCEPTION;
        PRAGMA EXCEPTION_INIT(sequence_not_exist, -02289);
    
    BEGIN
        alert_core_func.pk_tool_utils.get_core_tables(i_lang            => i_lang,
                                                      o_tool_table_name => o_tables,
                                                      o_error           => o_error);
        o_actions   := table_varchar();
        o_positions := table_number();
    
        FOR i IN 1 .. o_tables.count
        LOOP
            o_actions.extend;
            o_positions.extend;
            SELECT COUNT(0)
              INTO l_id_exists
              FROM all_tab_columns cols
             WHERE cols.owner != l_owner_to_ignore
               AND cols.table_name = o_tables(i)
               AND cols.column_name = l_id_prefix || o_tables(i);
        
            IF l_id_exists = 1
            THEN
                BEGIN
                    EXECUTE IMMEDIATE 'select max(' || l_id_prefix || o_tables(i) || ') from ' || o_tables(i)
                        INTO l_avl_val;
                
                    SELECT max_value
                      INTO l_seq_max_val
                      FROM all_sequences
                     WHERE sequence_name = l_seq_prefix || o_tables(i);
                
                    IF l_avl_val > l_seq_max_val
                    THEN
                    
                        SELECT data_precision
                          INTO l_col_precision
                          FROM all_tab_columns cols
                         WHERE cols.table_name = o_tables(i)
                           AND cols.owner != l_owner_to_ignore
                           AND cols.column_name = l_id_prefix || o_tables(i);
                        o_actions(i) := 'Altering sequence to support column size';
                        o_positions(i) := substr(l_max_number, 1, l_col_precision);
                        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || l_seq_prefix || o_tables(i) || ' MAXVALUE ' ||
                                          substr(l_max_number, 1, l_col_precision);
                    
                    ELSIF l_seq_max_val - l_avl_val > l_range
                    --ver se existe um range decente ap?s este valor
                    THEN
                    
                        pk_utils.reset_sequence(seq_name => l_seq_prefix || o_tables(i), startvalue => l_avl_val + 1);
                        o_actions(i) := 'Sequence updated to current max id in table';
                        o_positions(i) := l_avl_val + 1;
                    ELSE
                        --else correr bloco para procurar um bom range o mais prox possivel
                        EXECUTE IMMEDIATE ' SELECT a.next_val
                  FROM (SELECT t.' || l_id_prefix || o_tables(i) ||
                                          ' + 1 next_val
                          FROM (SELECT ' || l_id_prefix || o_tables(i) || ',
                                       lead(' || l_id_prefix || o_tables(i) ||
                                          ', 1, 0) over(ORDER BY ' || l_id_prefix || o_tables(i) || ') - ' ||
                                          l_id_prefix || o_tables(i) || ' diff
                                  FROM ' || o_tables(i) || ') t
                         WHERE diff > ' || l_range || '
                         ORDER BY next_val) a
                 WHERE rownum = 1'
                            INTO l_new_seq_value;
                        o_actions(i) := 'Sequence updated to new range';
                        o_positions(i) := l_new_seq_value;
                        pk_utils.reset_sequence(seq_name => l_seq_prefix || o_tables(i), startvalue => l_new_seq_value);
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        o_actions(i) := ' Error: No data found in table or sequence info';
                    
                    WHEN invalid_number THEN
                        o_actions(i) := 'Error: Invalid id for sequence use';
                    WHEN sequence_not_exist THEN
                        o_actions(i) := 'Error: No privileges to alter sequence';
                END;
            ELSE
                o_actions(i) := 'Error, no matching id';
            END IF;
        END LOOP;
    
    END fix_default_sequences;

    /********************************************************************************************
    * Fix a sequence related to Default Process
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/06/28
    ********************************************************************************************/
    PROCEDURE fix_default_sequences
    (
        i_lang            IN language.id_language%TYPE,
        i_seq_name        IN VARCHAR2,
        i_table_name      IN VARCHAR2,
        i_use_past_values IN VARCHAR2 DEFAULT 'N',
        i_range           IN NUMBER DEFAULT 30000,
        o_tables          OUT table_varchar,
        o_actions         OUT table_varchar,
        o_positions       OUT table_number,
        o_error           OUT t_error_out
    ) IS
        l_id_prefix CONSTANT VARCHAR2(3) := 'ID_';
        l_avl_val   NUMBER(38); -- valor max na tabela, max_value de NUMBER tem 38 digitos
        l_id_exists NUMBER := 0;
        l_pk_count  NUMBER := 0;
        l_pk_id     VARCHAR2(100);
        -- l_range CONSTANT NUMBER(6) := 20000;
        l_new_seq_value NUMBER(38);
        l_seq_max_val   NUMBER(38);
        l_max_number    NUMBER(38) := 99999999999999999999999999999999999999;
        l_col_precision NUMBER(6);
        l_owner_to_ignore CONSTANT VARCHAR2(20) := 'ALERT_DEFAULT';
        l_exec_max_value  NUMBER;
        l_use_past_values VARCHAR2(1);
    BEGIN
    
        o_actions   := table_varchar();
        o_positions := table_number();
        o_tables    := table_varchar(i_table_name);
        o_actions.extend;
        o_positions.extend;
    
        SELECT COUNT(0)
          INTO l_id_exists
          FROM all_tab_columns cols
         WHERE cols.owner != l_owner_to_ignore
           AND cols.table_name = i_table_name
           AND cols.column_name = l_id_prefix || i_table_name;
    
        SELECT COUNT(0)
          INTO l_pk_count
          FROM all_constraints cons, all_cons_columns cols
         WHERE cons.constraint_type = 'P'
           AND cons.constraint_name = cols.constraint_name
           AND cons.owner = cols.owner
           AND cols.table_name = i_table_name
           AND cons.owner != l_owner_to_ignore
         GROUP BY cols.table_name
        HAVING COUNT(cols.table_name) = 1;
    
        IF i_use_past_values = 'Y'
        THEN
            --get max_value captured by past executions to preview possible insertion impact
            SELECT MAX(to_number(rec_inserted))
              INTO l_exec_max_value
              FROM v_exec_hist_details
             WHERE tool_table_name = i_table_name
               AND rec_inserted != 'N/A';
        END IF;
    
        IF l_exec_max_value IS NULL
        THEN
            l_use_past_values := 'N';
        ELSE
            l_use_past_values := 'Y';
        END IF;
    
        IF l_id_exists = 1
        THEN
            BEGIN
                EXECUTE IMMEDIATE 'select max(' || l_id_prefix || i_table_name || ') from ' || i_table_name
                    INTO l_avl_val;
            
                SELECT max_value
                  INTO l_seq_max_val
                  FROM all_sequences
                 WHERE sequence_name = i_seq_name;
            
                IF l_avl_val > l_seq_max_val
                THEN
                
                    SELECT data_precision
                      INTO l_col_precision
                      FROM all_tab_columns cols
                     WHERE cols.table_name = i_table_name
                       AND cols.owner != l_owner_to_ignore
                       AND cols.column_name = l_id_prefix || i_table_name;
                
                    EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || i_seq_name || ' MAXVALUE ' ||
                                      substr(l_max_number, 1, l_col_precision);
                    o_actions(1) := 'Altering sequence to support column size';
                    o_positions(1) := substr(l_max_number, 1, l_col_precision);
                ELSIF l_use_past_values = 'Y'
                      AND l_seq_max_val - l_avl_val > l_exec_max_value
                THEN
                
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_avl_val + 1);
                    o_actions(1) := 'Sequence updated to current max id in table';
                    o_positions(1) := l_avl_val + 1;
                ELSIF l_seq_max_val - l_avl_val > i_range
                --check if needed range exists after this value
                THEN
                
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_avl_val + 1);
                    o_actions(1) := 'Sequence updated to current max id in table';
                    o_positions(1) := l_avl_val + 1;
                ELSE
                    --else run block to find needed range as close as possible
                    EXECUTE IMMEDIATE ' SELECT a.next_val
                  FROM (SELECT t.' || l_id_prefix || i_table_name ||
                                      ' + 1 next_val
                          FROM (SELECT ' || l_id_prefix || i_table_name || ',
                                       lead(' || l_id_prefix || i_table_name ||
                                      ', 1, 0) over(ORDER BY ' || l_id_prefix || i_table_name || ') - ' || l_id_prefix ||
                                      i_table_name || ' diff
                                  FROM ' || i_table_name || ') t
                         WHERE diff > ' || CASE l_use_past_values
                                          WHEN 'Y' THEN
                                           nvl(l_exec_max_value, i_range)
                                          ELSE
                                           i_range
                                      END || '
                         ORDER BY next_val) a
                 WHERE rownum = 1'
                        INTO l_new_seq_value;
                    o_actions(1) := 'Sequence updated to new range';
                    o_positions(1) := l_new_seq_value;
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_new_seq_value);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_actions(1) := ' Error: No data found in table or sequence info';
                
                WHEN invalid_number THEN
                    o_actions(1) := 'Error: Invalid id for sequence use';
                WHEN OTHERS THEN
                    o_actions(1) := 'Sequence does not exists or can''t be accessed';
            END;
        ELSIF l_pk_count = 1
        THEN
            SELECT cols.column_name
              INTO l_pk_id
              FROM all_constraints cons, all_cons_columns cols
             WHERE cons.constraint_type = 'P'
               AND cons.constraint_name = cols.constraint_name
               AND cons.owner = cols.owner
               AND cols.table_name = i_table_name
               AND cons.owner != l_owner_to_ignore;
        
            BEGIN
                EXECUTE IMMEDIATE 'select max(' || l_pk_id || ') from ' || i_table_name
                    INTO l_avl_val;
            
                SELECT max_value
                  INTO l_seq_max_val
                  FROM all_sequences
                 WHERE sequence_name = i_seq_name;
            
                IF l_avl_val > l_seq_max_val
                THEN
                
                    SELECT data_precision
                      INTO l_col_precision
                      FROM all_tab_columns cols
                     WHERE cols.table_name = i_table_name
                       AND cols.owner != l_owner_to_ignore
                       AND cols.column_name = l_pk_id;
                
                    EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || i_seq_name || ' MAXVALUE ' ||
                                      substr(l_max_number, 1, l_col_precision);
                    o_actions(1) := 'Altering sequence to support column size';
                    o_positions(1) := substr(l_max_number, 1, l_col_precision);
                    --check if needed range exists after this value
                ELSIF l_use_past_values = 'Y'
                      AND l_seq_max_val - l_avl_val > l_exec_max_value
                THEN
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_avl_val);
                    o_actions(1) := 'Sequence updated to current max id in table';
                    o_positions(1) := l_avl_val;
                ELSIF l_seq_max_val - l_avl_val > i_range
                --check if needed range exists after this value
                THEN
                
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_avl_val);
                    o_actions(1) := 'Sequence updated to current max id in table';
                    o_positions(1) := l_avl_val;
                ELSE
                    --else run block to find needed range as close as possible
                    EXECUTE IMMEDIATE ' SELECT a.next_val
                  FROM (SELECT t.' || l_pk_id ||
                                      ' + 1 next_val
                          FROM (SELECT ' || l_pk_id || ',
                                       lead(' || l_pk_id ||
                                      ', 1, 0) over(ORDER BY ' || l_pk_id || ') - ' || l_pk_id ||
                                      ' diff
                                  FROM ' || i_table_name || ') t
                         WHERE diff > ' || CASE l_use_past_values
                                          WHEN 'Y' THEN
                                           nvl(l_exec_max_value, i_range)
                                          ELSE
                                           i_range
                                      END || '
                         ORDER BY next_val) a
                 WHERE rownum = 1'
                        INTO l_new_seq_value;
                    o_actions(1) := 'Sequence updated to new range';
                    o_positions(1) := l_new_seq_value;
                    pk_utils.reset_sequence(seq_name => i_seq_name, startvalue => l_new_seq_value);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_actions(1) := ' Error: No data found in table or sequence info';
                
                WHEN invalid_number THEN
                    o_actions(1) := 'Error: Invalid id for sequence use';
                WHEN OTHERS THEN
                    o_actions(1) := 'Sequence does not exists or can''t be accessed';
            END;
        ELSE
            o_actions(1) := 'Error, no matching id';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'fix_default_sequences',
                                              o_error);
            -- pk_alert_exceptions.reset_error_state;
    
    END fix_default_sequences;
    /********************************************************************************************
    * Get display for apex LOV (Main Method)
    *
    * @param i_lang                Log Language ID
    * @param i_institution         id_institution to configure
    * @param i_software            id_software array
    * @param i_dcs                 id_dcs id
    * @param i_profile_templ       profile template id
    * @param i_lov_type            LOV type (procedure name)
    * @param i_scfg_type           System configuration id
    * @param i_flg_null            Add option to array (A - ALL, N - Null, I - Ignore)
    * @param o_error               error output
    *
    * @result                      table of apex display type
    *
    * @author                      RMGM
    * @version                     2.6.3
    * @since                       2013/07/24
    ********************************************************************************************/
    FUNCTION build_alert_lov
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_lov_type      IN VARCHAR,
        i_software      IN table_number DEFAULT table_number(),
        i_dcs           IN NUMBER DEFAULT NULL,
        i_profile_templ IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_domain_type   IN VARCHAR2 DEFAULT NULL,
        i_condition     IN table_varchar DEFAULT table_varchar(),
        i_flg_null      IN VARCHAR2 DEFAULT NULL,
        i_null_desc     IN VARCHAR2 DEFAULT NULL,
        i_search        IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN t_tbl_lov IS
        l_tbl_res t_tbl_lov := t_tbl_lov();
    
        l_temp_tbl t_tbl_lov := t_tbl_lov();
    
        total_idx NUMBER := 0;
    BEGIN
    
        -- ADD Option Null
        IF i_flg_null = g_no
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '-1', i_null_desc);
        ELSIF i_flg_null = g_active
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '0', pk_message.get_message(i_lang, 'COMMON_M014'));
        ELSIF i_flg_null = 'O'
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '-1', pk_message.get_message(i_lang, 'COMMON_M096'));
        ELSIF i_flg_null = 'NULL'
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '', pk_message.get_message(i_lang, 'COMMON_M105'));
        ELSIF i_flg_null = '0' --zero, or "All"
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '0', pk_message.get_message(i_lang, 'APEX_T006'));
        ELSIF i_flg_null = '-999'
        THEN
            l_tbl_res.extend;
            total_idx := 1;
            l_tbl_res(total_idx) := t_rec_lov(i_lov_type, '-999', pk_message.get_message(i_lang, 'COMMON_M043'));
        
        END IF;
    
        IF upper(i_lov_type) = upper('get_specialties_list')
        THEN
            -- get_specialties_lov
            g_error := 'GET SPECIALITY LIST TO APEX CONSUMER';
            get_specialties_list(i_lang, i_institution, i_software, i_condition, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_software_list')
        THEN
            -- get_softwares_lov
            g_error := 'GET SOFTWARE LIST TO APEX CONSUMER';
            get_software_list(i_lang, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_version_list')
        THEN
            -- get_versions_lov
            g_error := 'GET VERSION LIST TO APEX CONSUMER';
            get_version_list(i_lang, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_language_list')
        THEN
            -- get_language_lov
            g_error := 'GET LANGUAGE LIST TO APEX CONSUMER';
            get_language_list(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_institution_list')
        THEN
            -- get_institution_lov
            g_error := 'GET INSTITUTION LIST TO APEX CONSUMER';
            get_institution_list(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_market_list')
        THEN
            -- get_markets_lov
            g_error := 'GET MARKET LIST TO APEX CONSUMER';
            get_market_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_sysconfig_list')
        THEN
            -- get_sysconfig_lov
            g_error := 'GET SYSCONFIG LIST TO APEX CONSUMER';
            get_sysconfig_list(i_lang, i_domain_type, i_institution, i_software(1), l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_category_list')
        THEN
            -- get_category_pipelined_lov
            g_error := 'GET CATEGORY LIST TO APEX CONSUMER';
            get_category_list(i_lang, i_profile_templ, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_country_list')
        THEN
            -- get_country_pipelined_lov
            g_error := 'GET COUNTRY LIST TO APEX CONSUMER';
            get_country_list(i_lang, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_bo_profile_list')
        THEN
            --BACKOFFICE_PROFILE_TEMPL_LOV
            g_error := 'GET BACKOFFICE PROFILE LIST TO APEX CONSUMER';
            get_bo_profile_list(i_lang, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_sysdomain_list')
        THEN
            g_error := 'GET BACKOFFICE DOMAINS ' || i_domain_type || ' TO APEX CONSUMER';
            get_sysdomain_list(i_lang, i_domain_type, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_ROOM_list')
        THEN
            g_error := 'GET ROOM LIST TO APEX CONSUMER';
            get_room_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_clinical_service_list')
        THEN
            g_error := 'GET CLINICAL SERVICE LIST TO APEX CONSUMER';
            get_clinical_service_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_all_clinical_service_list')
        THEN
            g_error := 'GET CLINICAL SERVICE LIST TO APEX CONSUMER';
            get_all_clinical_service_list(i_lang, i_institution, i_software, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_department_list')
        THEN
            g_error := 'GET SERVICE LIST TO APEX CONSUMER';
            get_department_list(i_lang, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_triagetype_list')
        THEN
            g_error := 'GET TRIAGE TYPE LIST TO APEX CONSUMER';
            get_triagetype_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_all_software_list')
        THEN
            g_error := 'GET ALL SOFTWARE LIST TO APEX CONSUMER';
            get_all_software_list(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_soft_list_no_struct')
        THEN
            g_error := 'GET SOFTWARE LIST NO STRUCT NEEDED TO APEX CONSUMER';
            get_soft_list_no_struct(i_lang, i_institution, i_condition, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_all_institution_list')
        THEN
            g_error := 'GET INSTITUTION LIST TO APEX CONSUMER';
            get_all_institution_list(i_lang, i_condition, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_timezone_list')
        THEN
            g_error := 'GET TIMEZONE LIST TO APEX CONSUMER';
            get_timezone_list(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_currency_list')
        THEN
            g_error := 'GET CURRENCY LIST TO APEX CONSUMER';
            get_currency_list(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_building_lov')
        THEN
            g_error := 'GET BUILDINGS LIST TO APEX CONSUMER';
            get_building_lov(i_lang, i_institution, l_temp_tbl);
            --get_inst_group_lov
        ELSIF upper(i_lov_type) = upper('get_inst_group_lov')
        THEN
            g_error := 'GET INSTITUTION GROUP LIST TO APEX CONSUMER';
            get_inst_group_lov(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_dcs_lov')
        THEN
            g_error := 'GET INSTITUTION GROUP LIST TO APEX CONSUMER';
            get_dcs_lov(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_visit_lov')
        THEN
            g_error := 'GET INSTITUTION GROUP LIST TO APEX CONSUMER';
            get_visit_lov(i_lang, i_condition, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_episode_lov')
        THEN
            g_error := 'GET INSTITUTION GROUP LIST TO APEX CONSUMER';
            get_episode_lov(i_lang, i_condition, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_patient_lov')
        THEN
            g_error := 'GET INSTITUTION GROUP LIST TO APEX CONSUMER';
            get_patient_lov(i_lang, i_institution, i_condition, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_unit_measure_list')
        THEN
            g_error := 'GET UNIT MEASURE LIST TO APEX CONSUMER';
            get_unit_measure_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_vital_sign_list')
        THEN
            g_error := 'GET VITAL SIGN LIST TO APEX CONSUMER';
            get_vital_sign_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_doc_template_list')
        THEN
            g_error := 'GET DOC_TEMPLATE LIST TO APEX CONSUMER';
            get_doc_template_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_exam_list')
        THEN
            g_error := 'GET EXAM LIST TO APEX CONSUMER';
            get_exam_list(i_lang, i_institution, i_software, NULL, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_intervention_list')
        THEN
            g_error := 'GET INTERVENTION LIST TO APEX CONSUMER';
            get_intervention_list(i_lang, i_institution, i_software, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_sr_intervention_list')
        THEN
            g_error := 'GET SURGICAL INTERVENTION LIST TO APEX CONSUMER';
            get_sr_intervention_list(i_lang, i_institution, i_software, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_rehab_area_list')
        THEN
            g_error := 'GET REHAB AREA LIST TO APEX CONSUMER';
            get_rehab_area_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_doc_area_list')
        THEN
            g_error := 'GET DOC AREA LIST TO APEX CONSUMER';
            get_doc_area_list(i_lang, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_COMPLAINT_list')
        THEN
            g_error := 'GET DOC AREA LIST TO APEX CONSUMER';
            get_complaint_list(i_lang, i_institution, l_temp_tbl);
        
        ELSIF upper(i_lov_type) = upper('get_sch_event_list')
        THEN
            g_error := 'GET DOC AREA LIST TO APEX CONSUMER';
            get_sch_event_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_ped_area_list')
        THEN
            g_error := 'GET PED_AREA LIST TO APEX CONSUMER';
            get_ped_area_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_dcs_list_lov')
        THEN
            g_error := 'GET DCS LIST TO APEX CONSUMER';
            get_dcs_list_lov(i_lang, i_institution, i_software, i_search, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_content_list_lov')
        THEN
            g_error := 'GET CONTENT LIST TO APEX CONSUMER';
            get_content_list_lov(i_lang, i_institution, i_condition, i_search, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_complaint_list_lov')
        THEN
            g_error := 'GET COMPLAINT LIST TO APEX CONSUMER';
            get_complaint_list_lov(i_lang, i_institution, i_software, i_search, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_po_param_list')
        THEN
            g_error := 'GET PO_PARAM LIST TO APEX CONSUMER';
            get_po_param_list(i_lang, i_institution, i_search, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_po_param_mc_list')
        THEN
            g_error := 'GET PO_PARAM_MC LIST TO APEX CONSUMER';
            get_po_param_mc_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_unit_measure_type_list')
        THEN
            g_error := 'GET UM_TYPE LIST TO APEX CONSUMER';
            get_unit_measure_type_list(i_lang, i_institution, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_unit_measure_subtype_list')
        THEN
            g_error := 'GET UM_SUBTYPE LIST TO APEX CONSUMER';
            get_unit_measure_subtype_list(i_lang, i_institution, i_condition, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('get_ppwh_flg_owner_list')
        THEN
            g_error := 'GET PO_PARAM_WH FLG_OWNER LIST TO APEX CONSUMER';
            get_ppw_flg_owner_lov(i_lang, l_temp_tbl);
        ELSIF upper(i_lov_type) = upper('GET_PO_TT_CONTENT_LIST')
        THEN
            g_error := 'GET po_param sets content TO APEX CONSUMER';
            get_pp_tt_content_list(i_lang, i_institution, i_condition, l_temp_tbl);
        
        END IF;
    
        IF l_tbl_res.count = 1
        THEN
            l_tbl_res := l_tbl_res MULTISET UNION l_temp_tbl;
        ELSE
            --returned table is table of results
            l_tbl_res := l_temp_tbl;
        END IF;
    
        RETURN l_tbl_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'BUILD_ALERT_LOV',
                                              o_error);
            -- pk_alert_exceptions.reset_error_state;
        
            RETURN l_tbl_res;
    END build_alert_lov;

    -- 
    FUNCTION get_cs_id_from_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_dcs  IN NUMBER
    ) RETURN NUMBER IS
        l_cs NUMBER;
    BEGIN
        SELECT dcs.id_clinical_service
          INTO l_cs
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
           AND cs.flg_available = g_flg_available
          JOIN alert_default.clinical_service ad_cs
        
            ON ad_cs.id_content = cs.id_content
         WHERE ad_cs.flg_available = g_flg_available
           AND cs.flg_available = g_flg_available
           AND dcs.id_dep_clin_serv = i_dcs
           AND dcs.flg_available = g_flg_available;
    
        RETURN l_cs;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_cs_id_from_dcs;

    FUNCTION get_sysconfig_value
    (
        i_lang        IN language.id_language%TYPE,
        i_sysconfig   IN VARCHAR2,
        i_institution IN NUMBER,
        i_software    IN NUMBER
    ) RETURN sys_config.value%TYPE IS
        l_error t_error_out;
    BEGIN
        RETURN pk_sysconfig.get_config(i_sysconfig, profissional(0, i_institution, i_software));
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_sysconfig_value',
                                              l_error);
            RETURN NULL;
            pk_alert_exceptions.reset_error_state;
    END get_sysconfig_value;
    -- room report

    FUNCTION get_exam_room
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mcdt_type   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res       t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_flg_type_desc VARCHAR2(200) := pk_sysdomain.get_domain('EXAM.FLG_TYPE', i_mcdt_type, i_lang);
    BEGIN
    
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.room_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl_rm,2) */
                 er.id_exam mcdt_id,
                 (SELECT pk_translation.get_translation(i_lang, e.code_exam)
                    FROM dual) mcdt_desc,
                 er.id_room room_id,
                 trl_rm.desc_translation room_desc,
                 er.flg_default default_flg,
                 e.flg_type item_type,
                 l_flg_type_desc item_type_desc
                  FROM exam_room er
                 INNER JOIN TABLE(pk_translation.get_table_translation(i_lang, 'ROOM', g_no)) trl_rm
                    ON (trl_rm.code_translation = 'ROOM.CODE_ROOM.' || er.id_room)
                  JOIN exam e
                    ON e.id_exam = er.id_exam
                 WHERE er.flg_available = g_flg_available
                   AND e.flg_type = i_mcdt_type
                   AND EXISTS (SELECT 0
                          FROM exam_dep_clin_serv edcs
                         WHERE edcs.id_exam = er.id_exam
                           AND edcs.flg_type = 'P'
                           AND edcs.id_institution = i_institution)
                   AND EXISTS (SELECT 0
                          FROM room r
                         INNER JOIN department d
                            ON (d.id_department = r.id_department)
                         WHERE r.id_room = er.id_room
                           AND r.flg_available = g_flg_available
                           AND d.id_institution = i_institution)) res_data;
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_exam_room',
                                              o_error);
            RETURN NULL;
        
    END get_exam_room;

    FUNCTION get_analysis_room
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mcdt_type   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res       t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_flg_type_desc VARCHAR2(200) := pk_sysdomain.get_domain('ANALYSIS_ROOM.FLG_TYPE', i_mcdt_type, i_lang);
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.room_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl_rm,2) */
                 ar.id_analysis mcdt_id,
                 (SELECT pk_translation.get_translation(i_lang, 'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis)
                    FROM dual) mcdt_desc,
                 ar.id_room room_id,
                 trl_rm.desc_translation room_desc,
                 ar.flg_default default_flg,
                 ar.flg_type item_type,
                 l_flg_type_desc item_type_desc
                  FROM analysis_room ar
                 INNER JOIN TABLE(pk_translation.get_table_translation(i_lang, 'ROOM', g_no)) trl_rm
                    ON (trl_rm.code_translation = 'ROOM.CODE_ROOM.' || ar.id_room)
                
                 WHERE ar.flg_available = g_flg_available
                   AND ar.flg_type = i_mcdt_type
                   AND ar.id_institution = i_institution
                   AND EXISTS (SELECT 0
                          FROM room r
                         INNER JOIN department d
                            ON (d.id_department = r.id_department)
                         WHERE r.id_room = ar.id_room
                           AND r.flg_available = g_flg_available
                           AND d.id_institution = i_institution)) res_data;
        RETURN l_tbl_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_analysis_room',
                                              o_error);
            RETURN NULL;
        
    END get_analysis_room;

    FUNCTION get_episode_room
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.room_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl_mcdt,2) */ /*+ dynamic_sampling(trl_rm,2) */
                 etr.id_epis_type          mcdt_id,
                 trl_mcdt.desc_translation mcdt_desc,
                 etr.id_room               room_id,
                 trl_rm.desc_translation   room_desc,
                 -- etr.id_dep_clin_serv,                       
                 g_flg_available default_flg,
                 'O' item_type,
                 'EPISODE DEFAULT ROOM' AS item_type_desc
                  FROM epis_type_room etr
                 INNER JOIN TABLE(pk_translation.get_table_translation(i_lang, 'EPIS_TYPE', g_no)) trl_mcdt
                    ON (trl_mcdt.code_translation = 'EPIS_TYPE.CODE_EPIS_TYPE.' || etr.id_epis_type)
                 INNER JOIN TABLE(pk_translation.get_table_translation(i_lang, 'ROOM', g_no)) trl_rm
                    ON (trl_rm.code_translation = 'ROOM.CODE_ROOM.' || etr.id_room)
                 WHERE etr.id_institution = i_institution
                   AND EXISTS (SELECT 0
                          FROM room r
                         INNER JOIN department d
                            ON (d.id_department = r.id_department)
                         WHERE r.id_room = etr.id_room
                           AND r.flg_available = g_flg_available
                           AND d.id_institution = i_institution)) res_data;
    
        RETURN l_tbl_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_episode_room',
                                              o_error);
            RETURN NULL;
        
    END get_episode_room;

    FUNCTION get_rooms_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mcdt_type   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
    
        IF i_mcdt_type = 'O' -- episode
        THEN
            RETURN get_episode_room(pk_utils.get_institution_language(i_institution), i_institution, o_error);
        ELSIF i_mcdt_type IN ('I', 'E') --exames
        THEN
            RETURN get_exam_room(pk_utils.get_institution_language(i_institution), i_institution, i_mcdt_type, o_error);
        ELSIF i_mcdt_type IN ('T', 'M') --lab
        THEN
            RETURN get_analysis_room(pk_utils.get_institution_language(i_institution),
                                     i_institution,
                                     i_mcdt_type,
                                     o_error);
        END IF;
    
        RETURN l_tbl_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_rooms report',
                                              o_error);
            RETURN NULL;
        
    END get_rooms_report;
    FUNCTION get_triage_serv_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(def_data.mcdt_desc,
                                     def_data.mcdt_id,
                                     def_data.room_desc,
                                     def_data.room_id,
                                     def_data.default_flg,
                                     def_data.item_type,
                                     def_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT *
                  FROM (SELECT td.id_department mcdt_id,
                               decode(td.id_department,
                                      -1,
                                      (SELECT pk_message.get_message(pk_utils.get_institution_language(i_institution),
                                                                     'COMMON_M014')
                                         FROM dual),
                                      (SELECT pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                             'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                             td.id_department)
                                         FROM dual)) mcdt_desc,
                               td.id_triage_type room_id,
                               (SELECT pk_translation.get_translation(pk_utils.get_institution_language(i_institution),
                                                                      'TRIAGE_TYPE.CODE_TRIAGE_TYPE.' || td.id_triage_type)
                                  FROM dual) || '(' ||
                               (SELECT tt.acronym
                                  FROM triage_type tt
                                 WHERE tt.id_triage_type = td.id_triage_type
                                   AND tt.flg_available = g_flg_available) || ')' room_desc,
                               td.flg_default default_flg,
                               NULL item_type,
                               NULL item_type_desc
                          FROM triage_department td
                         WHERE td.id_institution = i_institution
                           AND td.flg_available = g_flg_available) res_data) def_data
         WHERE (i_department IS NULL OR mcdt_desc LIKE '%' || i_department || '%');
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_triage_serv_report',
                                              o_error);
            RETURN l_tbl_res;
    END get_triage_serv_report;
    -- set analysis room by list of sw
    FUNCTION set_bulk_analysis_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        i_type          IN VARCHAR2,
        i_flg_default   IN NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --g_func_name := upper('set_bulk_analysis_room');
        g_error := 'INSERT ANALYSIS ROOM CONFIGURATION ';
        --dbms_output.put_line('Start - ' || g_error || ' --> ' || current_timestamp);
        --dbms_output.put_line('Info ' || i_type || ', ' || i_default_flg || ';');
        INSERT INTO analysis_room
            (id_analysis_room,
             id_analysis,
             id_room,
             rank,
             adw_last_update,
             flg_type,
             flg_available,
             flg_default,
             id_institution,
             id_sample_type)
            SELECT seq_analysis_room.nextval,
                   cfg_data.id_analysis,
                   r.column_value,
                   0,
                   SYSDATE,
                   i_type,
                   g_flg_available,
                   decode(r.column_value,
                          i_flg_default,
                          decode((SELECT COUNT(*)
                                   FROM analysis_room ar1
                                  WHERE ar1.id_analysis = cfg_data.id_analysis
                                    AND ar1.id_room = r.column_value
                                    AND ar1.flg_type = i_type
                                    AND ar1.id_sample_type = cfg_data.id_sample_type
                                    AND ar1.flg_default = g_flg_available),
                                 0,
                                 g_flg_available,
                                 g_no),
                          g_no),
                   i_institution,
                   cfg_data.id_sample_type
              FROM (SELECT ais.id_analysis,
                           ais.id_sample_type,
                           row_number() over(PARTITION BY ais.id_analysis, ais.id_sample_type ORDER BY ais.rowid) records_count
                      FROM analysis_instit_soft ais
                     WHERE ais.id_institution = i_institution
                       AND ais.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_software_list AS table_number)) p)
                       AND ais.flg_type = 'P'
                       AND ais.flg_available = g_flg_available
                       AND ais.id_analysis IS NOT NULL
                       AND ais.id_sample_type IS NOT NULL) cfg_data
              JOIN TABLE(CAST(i_room AS table_number)) r
                ON (1 = 1)
             WHERE cfg_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM analysis_room ar
                     WHERE ar.id_analysis = cfg_data.id_analysis
                       AND ar.id_sample_type = cfg_data.id_sample_type
                       AND ar.id_room = r.column_value
                       AND ar.id_institution = i_institution
                       AND ar.flg_type = i_type);
    
        --dbms_output.put_line('Inserted - ' || SQL%ROWCOUNT);
        --dbms_output.put_line('End - ' || current_timestamp);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_bulk_analysis_room',
                                              o_error);
            RETURN FALSE;
    END set_bulk_analysis_room;

    -- set exam room by list of sw
    FUNCTION set_bulk_exam_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        i_type          IN VARCHAR2,
        i_flg_default   IN NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exam_room_list table_number := table_number();
        l_exam_list      table_number := table_number();
        l_room_list      table_number := table_number();
        l_flg_def_list   table_varchar := table_varchar();
    BEGIN
    
        SELECT e.id_exam,
               r.column_value,
               decode(r.column_value,
                      i_flg_default,
                      decode((SELECT COUNT(*)
                               FROM exam_room er1
                              WHERE er1.id_exam = e.id_exam
                                AND er1.id_room = r.column_value
                                AND er1.flg_available = g_flg_available
                                AND er1.flg_default = g_flg_available),
                             0,
                             g_flg_available,
                             g_no),
                      g_no) BULK COLLECT
          INTO l_exam_list, l_room_list, l_flg_def_list
          FROM exam e
          JOIN TABLE(CAST(i_room AS table_number)) r
            ON (1 = 1)
         WHERE e.flg_type = i_type
           AND e.flg_available = g_flg_available
           AND EXISTS
         (SELECT 0
                  FROM exam_dep_clin_serv edcs
                 WHERE edcs.flg_type = 'P'
                   AND edcs.id_institution = i_institution
                   AND edcs.id_software IN (SELECT /*+ dynamic_sampling(p 2)*/
                                             column_value
                                              FROM TABLE(CAST(i_software_list AS table_number)) p)
                   AND edcs.id_exam = e.id_exam)
           AND NOT EXISTS (SELECT 0
                  FROM exam_room er
                 WHERE er.id_exam = e.id_exam
                   AND er.id_room = r.column_value
                   AND er.flg_available = g_flg_available);
    
        g_error := 'INSERT EXAM ROOM CONFIGURATION ';
        FORALL e IN 1 .. l_exam_list.count
            INSERT INTO exam_room
                (id_exam_room, id_exam, id_room, rank, adw_last_update, flg_available, flg_default)
            VALUES
                (seq_exam_room.nextval, l_exam_list(e), l_room_list(e), 0, SYSDATE, g_flg_available, l_flg_def_list(e))
            RETURNING id_exam_room BULK COLLECT INTO l_exam_room_list;
    
        FOR ers IN 1 .. l_exam_room_list.count
        LOOP
            alert_inter.pk_ia_event_backoffice.exam_room_new(i_id_exam_room   => l_exam_room_list(ers),
                                                             i_id_institution => i_institution);
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_bulk_exam_room',
                                              o_error);
            RETURN FALSE;
    END set_bulk_exam_room;
    -- set episode type room by list of sw
    FUNCTION set_bulk_epis_type_room
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN table_number,
        i_software_list IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type_list table_varchar := table_varchar();
        --l_epis_type_list1 table_varchar := table_varchar();
    
        l_epis_tr_pk epis_type_room.id_epis_type_room%TYPE := 0;
    BEGIN
        --dbms_output.put_line('Start - ' || g_error || ' --> ' || current_timestamp);
        FOR i IN 1 .. i_software_list.count
        LOOP
            l_epis_type_list.extend;
            l_epis_type_list(i) := pk_sysconfig.get_config('EPIS_TYPE', i_institution, i_software_list(i));
            --dbms_output.put_line('SW: ' || i_software_list(i) || ' ETR - ' || l_epis_type_list(i));
        END LOOP;
        -- l_epis_type_list1 := SET(l_epis_type_list);
        g_error := 'INSERT EPIS TYPE ROOM CONFIGURATION ';
        SELECT nvl((SELECT MAX(etr.id_epis_type_room)
                     FROM epis_type_room etr),
                   0)
          INTO l_epis_tr_pk
          FROM dual;
        INSERT INTO epis_type_room
            (id_epis_type_room, id_room, id_epis_type, id_institution)
        
            SELECT l_epis_tr_pk + rownum, r.column_value, data_by_sw.id_epis_type, i_institution
              FROM (SELECT column_value id_epis_type, rownum idx
                      FROM TABLE(CAST(l_epis_type_list AS table_varchar)) t2) data_by_sw
              JOIN TABLE(CAST(i_room AS table_number)) r
                ON (1 = 1)
             WHERE data_by_sw.id_epis_type IS NOT NULL
               AND NOT EXISTS (SELECT 0
                      FROM epis_type_room etr
                     WHERE etr.id_room = r.column_value
                       AND etr.id_epis_type = data_by_sw.id_epis_type
                       AND etr.id_institution = i_institution);
    
        -- dbms_output.put_line('Inserted - ' || SQL%ROWCOUNT);
        --dbms_output.put_line('End - ' || current_timestamp);
        --g_func_name := upper('set_bulk_epis_type_room');
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_bulk_epis_type_room',
                                              o_error);
            RETURN FALSE;
    END set_bulk_epis_type_room;

    -- Main room set (UI apex API)
    FUNCTION set_mcdt_def_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_context     IN VARCHAR2,
        i_room        IN table_number,
        i_software    IN table_number,
        i_flg_default IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_out t_error_out;
        l_room_cfg_exception EXCEPTION;
    BEGIN
    
        CASE
            WHEN i_context IN ('T', 'M') THEN
                -- set analysis_room(Lab)
                g_error := 'SET BULK ANALYSIS ROOM ';
                IF NOT set_bulk_analysis_room(i_lang,
                                              i_institution,
                                              i_room,
                                              i_software,
                                              i_context,
                                              i_flg_default,
                                              l_error_out)
                THEN
                    RAISE l_room_cfg_exception;
                END IF;
            
            WHEN i_context IN ('E', 'I') THEN
                -- set_exam_room(imaging)
                g_error := 'SET BULK EXAMS ROOM ';
                IF NOT
                    set_bulk_exam_room(i_lang, i_institution, i_room, i_software, i_context, i_flg_default, l_error_out)
                THEN
                    RAISE l_room_cfg_exception;
                END IF;
            
            WHEN i_context = 'O' THEN
                -- set_epis_type_room
                g_error := 'SET BULK EPISODE TYPE ROOM ';
                IF NOT set_bulk_epis_type_room(i_lang, i_institution, i_room, i_software, l_error_out)
                THEN
                    RAISE l_room_cfg_exception;
                END IF;
            ELSE
                NULL;
        END CASE;
        pk_api_order_sets.migrate_labs_and_exams(i_institution);
        RETURN TRUE;
    EXCEPTION
        WHEN l_room_cfg_exception THEN
            --g_func_name := upper('set_mcdt_def_rooms');
            pk_alert_exceptions.process_error(i_lang,
                                              l_error_out.ora_sqlcode,
                                              l_error_out.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_mcdt_def_rooms',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            -- g_func_name := upper('set_mcdt_def_rooms');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_mcdt_def_rooms',
                                              o_error);
            RETURN FALSE;
    END set_mcdt_def_rooms;

    FUNCTION delete_analysis_room
    
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_room        IN NUMBER,
        i_type        IN VARCHAR2,
        i_mcdt        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        DELETE FROM analysis_room
         WHERE id_analysis = i_mcdt
           AND id_room = i_room
           AND flg_type = i_type
           AND id_institution = i_institution;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'delete_analysis_room',
                                              o_error);
            RETURN FALSE;
    END delete_analysis_room;

    FUNCTION delete_episode_room
    
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_room        IN NUMBER,
        i_mcdt        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        DELETE FROM epis_type_room
         WHERE id_room = i_room
           AND id_epis_type = i_mcdt
           AND id_institution = i_institution
           AND id_dep_clin_serv IS NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'delete_episode_room',
                                              o_error);
            RETURN FALSE;
    END delete_episode_room;

    FUNCTION delete_exam_room
    
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_room        IN NUMBER,
        i_type        IN VARCHAR2,
        i_mcdt        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        DELETE FROM exam_room
         WHERE id_exam = i_mcdt
           AND id_room = i_room;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'delete_exam_room',
                                              o_error);
            RETURN FALSE;
    END delete_exam_room;

    FUNCTION delete_mcdt_def_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_context     IN VARCHAR2,
        i_room        IN NUMBER,
        i_mcdt        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_room_delete_exception EXCEPTION;
    BEGIN
        CASE
            WHEN i_context IN ('T', 'M') THEN
                -- set analysis_room(Lab)
                g_error := 'SET BULK ANALYSIS ROOM ';
                IF NOT delete_analysis_room(i_lang, i_institution, i_room, i_context, i_mcdt, o_error)
                THEN
                    RAISE l_room_delete_exception;
                END IF;
            
            WHEN i_context IN ('E', 'I') THEN
                -- set_exam_room(imaging)
                g_error := 'SET BULK EXAMS ROOM ';
                IF NOT delete_exam_room(i_lang, i_institution, i_room, i_context, i_mcdt, o_error)
                THEN
                    RAISE l_room_delete_exception;
                END IF;
            
            WHEN i_context = 'O' THEN
                -- set_epis_type_room
                g_error := 'SET BULK EPISODE TYPE ROOM ';
                IF NOT delete_episode_room(i_lang, i_institution, i_room, i_mcdt, o_error)
                THEN
                    RAISE l_room_delete_exception;
                END IF;
            ELSE
                NULL;
        END CASE;
        RETURN TRUE;
    EXCEPTION
        WHEN l_room_delete_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_mcdt_def_rooms',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_mcdt_def_rooms',
                                              o_error);
            RETURN FALSE;
        
    END delete_mcdt_def_rooms;

    --- set triage configurations
    FUNCTION set_triage_department
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_service     IN table_number,
        i_triage_type IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count NUMBER := 0;
    BEGIN
        FOR i IN 1 .. i_service.count
        LOOP
            g_error := 'CHECK TRIAGE DEPARTMENT CONFIGURATIONS ';
            SELECT COUNT(*)
              INTO l_count
              FROM triage_department td
             WHERE td.id_institution = i_institution
               AND td.id_department = i_service(i)
               AND td.id_triage_type = i_triage_type
               AND td.flg_available = g_flg_available;
            IF l_count = 0
            THEN
                g_error := 'INSERT TRIAGE DEPARTMENT CONFIGURATION ';
                INSERT INTO triage_department
                    (id_institution, id_department, id_triage_type, flg_default, flg_available)
                VALUES
                    (i_institution,
                     i_service(i),
                     i_triage_type,
                     decode((SELECT COUNT(*)
                              FROM triage_department td
                             WHERE td.id_institution = i_institution
                               AND td.id_department = i_service(i)
                               AND td.id_triage_type = i_triage_type
                               AND td.flg_available = g_flg_available
                               AND td.flg_default = g_flg_available),
                            0,
                            g_flg_available,
                            g_no),
                     g_flg_available);
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            --g_func_name := upper('set_triage_departmet');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_triage_department',
                                              o_error);
            RETURN FALSE;
    END set_triage_department;

    FUNCTION delete_triage_department
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_service     IN NUMBER,
        i_triage_type IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        DELETE FROM triage_department
         WHERE id_institution = i_institution
           AND i_service = id_department
           AND id_triage_type = i_triage_type;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'delete_triage_department',
                                              o_error);
            RETURN FALSE;
    END delete_triage_department;

    /********************************************************************************************  
    * Constructs a query according to the view asked by APEX
    * 
    * 
    * @param i_query               Query to be run
    * @param i_basic               Object with columns returned
    *  
    * @author                      LRS  
    * @version                     0.1  
    * @since                       2013/01/27  
    ********************************************************************************************/
    PROCEDURE get_content_report_view
    (
        i_query  IN VARCHAR2,
        l_struct OUT pk_tool_utils.t_tbl_struct
    ) IS
    
        o_error     t_error_out;
        v_cursor    pk_types.cursor_type;
        l_statement VARCHAR2(10000);
        l_max_rows CONSTANT NUMBER := 300;
    BEGIN
        l_statement := i_query;
    
        -- Open cursor & specify bind argument in USING clause:
        OPEN v_cursor FOR l_statement;
    
        FETCH v_cursor BULK COLLECT
            INTO l_struct LIMIT l_max_rows;
    
        CLOSE v_cursor;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_content_report_view',
                                              o_error);
            htp.p(o_error.log_id);
            --  dbms_output.put_line(o_error.log_id);
    END get_content_report_view;

    FUNCTION get_pks_and_others
    (
        i_table   IN VARCHAR2,
        o_columns OUT table_varchar
    ) RETURN VARCHAR2 IS
        l_result        table_varchar := table_varchar();
        l_result_string VARCHAR2(4000);
        o_error         t_error_out;
    BEGIN
        SELECT DISTINCT 'SUBSTR(' || i_table || '.' || cols.column_name || ',1,3000) ' || cols.column_name,
                        cols.column_name BULK COLLECT
          INTO l_result, o_columns
          FROM dba_constraints cons, dba_cons_columns cols
         WHERE cols.table_name = i_table
           AND (cons.constraint_type = 'P' OR cons.constraint_type = 'U' OR
               cols.column_name IN ('ID_CONTENT', 'ID_SOFTWARE'))
           AND cons.constraint_name = cols.constraint_name
           AND cons.owner = cols.owner
           AND cons.owner = g_package_owner;
    
        l_result_string := pk_utils.concat_table(i_tab => l_result, i_delim => ' , ');
    
        RETURN l_result_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_pks_and_others',
                                              o_error);
            RETURN NULL;
        
    END get_pks_and_others;

    FUNCTION get_trans_col(i_desc_table IN VARCHAR2) RETURN VARCHAR2 IS
        l_col VARCHAR2(4000);
    BEGIN
        SELECT column_name
          INTO l_col
          FROM (SELECT atc.column_name
                  FROM dba_tab_columns atc
                 WHERE atc.table_name = i_desc_table
                   AND atc.column_name NOT LIKE 'ID%'
                   AND atc.owner IN ('ALERT', 'ALERT_ADTCOD_CFG', 'ALERT_CORE_DATA')
                   AND (atc.column_name = 'CODE_' || atc.table_name OR atc.column_name LIKE ('CODE/_%') ESCAPE
                        '/' OR atc.column_name = 'CODE'))
         WHERE rownum = 1;
    
        RETURN l_col;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN '';
        
    END;

    FUNCTION get_desc_col(i_desc_table IN VARCHAR2) RETURN VARCHAR2 IS
        l_col VARCHAR2(4000);
    BEGIN
        SELECT column_name
          INTO l_col
          FROM (SELECT atc.column_name
                  FROM dba_tab_columns atc
                 WHERE atc.table_name = i_desc_table
                   AND atc.column_name NOT LIKE 'ID%'
                   AND atc.owner IN ('ALERT', 'ALERT_ADTCOD_CFG', 'ALERT_CORE_DATA')
                   AND (atc.column_name LIKE ('%\_DESC') ESCAPE '\' OR atc.column_name LIKE ('DESC\_%') ESCAPE
                        '\' OR atc.column_name = 'DESCRIPTION' OR atc.column_name = 'INTERNAL_NAME' OR
                        atc.column_name LIKE '%TITLE'))
         WHERE rownum = 1;
    
        RETURN l_col;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN '';
        
    END get_desc_col;

    FUNCTION get_all_trans_cols(i_desc_table IN VARCHAR2) RETURN table_varchar IS
        l_cols table_varchar;
    BEGIN
        SELECT atc.column_name BULK COLLECT
          INTO l_cols
          FROM dba_tab_columns atc
         WHERE atc.table_name = i_desc_table
           AND atc.owner IN ('ALERT', 'ALERT_ADTCOD_CFG', 'ALERT_CORE_DATA')
           AND atc.column_name NOT LIKE 'ID%'
           AND (atc.column_name LIKE 'CODE%' OR atc.column_name LIKE ('%\_DESC') ESCAPE
                '\' OR atc.column_name LIKE ('DESC\_%') ESCAPE
                '\' OR atc.column_name = 'DESCRIPTION' OR atc.column_name = 'INTERNAL_NAME' OR
                atc.column_name LIKE '%TITLE');
    
        RETURN l_cols;
    END get_all_trans_cols;

    FUNCTION check_field
    (
        i_table IN VARCHAR2,
        i_field IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_value NUMBER;
    BEGIN
        SELECT 0
          INTO l_value
          FROM dba_tab_columns cols
         WHERE cols.table_name = i_table
           AND cols.column_name = i_field
           AND cols.owner = g_package_owner;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        
    END check_field;

    FUNCTION get_table_schema(i_table IN VARCHAR2) RETURN VARCHAR2 IS
        l_owner VARCHAR2(200);
    BEGIN
    
        SELECT owner
          INTO l_owner
          FROM dba_tables dt
         WHERE dt.owner IN ('ALERT', 'ALERT_CORE_DATA', 'ALERT_ADTCOD_CFG')
           AND dt.table_name = i_table;
        RETURN l_owner;
    END get_table_schema;

    FUNCTION get_table_fk_tree
    (
        i_table         IN dba_tables.table_name%TYPE,
        o_ptbl_list     OUT table_varchar,
        o_pcns_list     OUT table_varchar,
        o_pcnstype_list OUT table_varchar,
        o_powner_list   OUT table_varchar,
        o_tbl_list      OUT table_varchar,
        o_tblcns_list   OUT table_varchar,
        o_level_list    OUT table_varchar,
        o_tblcol_list   OUT table_varchar,
        o_ptblcol_list  OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dummy table_number;
    BEGIN
    
        SELECT f2.*, MAX(lvl) over(PARTITION BY f2.child_table_name) max_lvl BULK COLLECT
          INTO o_ptbl_list,
               o_pcns_list,
               o_pcnstype_list,
               o_powner_list,
               o_tbl_list,
               o_tblcns_list,
               o_level_list,
               o_tblcol_list,
               o_ptblcol_list,
               l_dummy,
               l_dummy
          FROM (SELECT f1.child_table_name,
                       f1.parent_cns,
                       f1.child_cns_type,
                       f1.child_owner,
                       f1.parent_table_name,
                       f1.child_cns,
                       f1.lvl,
                       f1.column_name,
                       f1.column_name_parent,
                       row_number() over(PARTITION BY f1.parent_table_name, f1.child_cns, f1.column_name ORDER BY lvl DESC) rnk
                  FROM (SELECT cns1.table_name      AS parent_table_name,
                               cns1.constraint_name AS parent_cns,
                               cns2.table_name      AS child_table_name,
                               cns2.owner           AS child_owner,
                               cns2.constraint_name AS child_cns,
                               cns2.constraint_type AS child_cns_type,
                               
                               a.column_name,
                               b.column_name AS column_name_parent,
                               LEVEL         lvl
                          FROM all_constraints cns1
                          JOIN all_constraints cns2
                            ON (cns1.r_constraint_name = cns2.constraint_name AND cns1.owner = cns2.owner)
                          JOIN all_cons_columns a
                            ON (a.owner = cns1.owner AND a.constraint_name = cns2.constraint_name)
                          JOIN all_cons_columns b
                            ON (b.owner = cns2.owner AND b.constraint_name = cns1.constraint_name)
                         WHERE cns1.status = 'ENABLED'
                           AND cns1.owner != 'ALERT_DEFAULT'
                           AND b.owner IN ('ALERT', 'ALERT_CORE_DATA', 'ALERT_ADTCOD_CFG')
                           AND cns2.table_name NOT LIKE 'AB\_%' ESCAPE
                         '\'
                           AND a.position = b.position
                           AND cns1.table_name NOT IN
                               ('PROFESSIONAL', 'DEP_CLIN_SERV', 'ROOM', 'ICNP_APPLICATION_AREA', 'DEPARTMENT', 'REPORTS')
                           AND cns2.table_name NOT IN
                               ('PROFESSIONAL', 'DEP_CLIN_SERV', 'ROOM', 'ICNP_APPLICATION_AREA', 'DEPARTMENT', 'REPORTS')
                         START WITH cns1.table_name = upper(i_table)
                        CONNECT BY nocycle PRIOR cns2.table_name = cns1.table_name) f1
                 WHERE f1.column_name != 'ID_CONTENT') f2
         WHERE f2.rnk = 1
         ORDER BY max_lvl, f2.child_table_name, f2.parent_table_name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(o_error.log_id);
            RETURN FALSE;
    END get_table_fk_tree;

    /********************************************************************************************
    * Get display for apex LOV (Software Institution configuration)
    *
    * @param i_lang                      Language id
    * @param i_id_institution            Institution id
    * @param o_inst_attrib_id            Institution attributes id
    * @param o_institution_name          Institution name
    * @param o_parent_institution        Parent institution id
    * @param o_institution_type          Institution type
    * @param o_flg_available             Available
    * @param o_soc_security              Soc. Security no.
    * @param o_shortname                 Shortname
    * @param o_language                  Language id
    * @param o_currency                  Currency id
    * @param o_phone_num                 Phone no.
    * @param o_fax_num                   Fax no.
    * @param o_email                     Email
    * @param o_address                   Address
    * @param o_city                      City
    * @param o_state                     State
    * @param o_zipcode                   Zipcode
    * @param o_country                   Country id
    * @param o_timezone                  Timezone
    * @param o_market                    Market id
    * @param o_error                     Error output
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/07/24
    ********************************************************************************************/
    FUNCTION get_institution_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN ab_institution.id_ab_institution%TYPE,
        o_inst_attrib_id     OUT inst_attributes.id_inst_attributes%TYPE,
        o_institution_name   OUT VARCHAR2,
        o_parent_institution OUT ab_institution.id_ab_institution_parent%TYPE,
        o_institution_type   OUT ab_institution.flg_type%TYPE,
        o_flg_available      OUT ab_institution.flg_available%TYPE,
        o_soc_security       OUT inst_attributes.social_security_number%TYPE,
        o_shortname          OUT ab_institution.shortname%TYPE,
        o_language           OUT institution_language.id_language%TYPE,
        o_currency           OUT inst_attributes.id_currency%TYPE,
        o_phone_num          OUT ab_institution.phone_number%TYPE,
        o_fax_num            OUT ab_institution.fax_number%TYPE,
        o_email              OUT ab_institution.email%TYPE,
        o_address            OUT ab_institution.address1%TYPE,
        o_city               OUT ab_institution.address2%TYPE,
        o_state              OUT ab_institution.ine_location%TYPE,
        o_zipcode            OUT ab_institution.zip_code%TYPE,
        o_country            OUT inst_attributes.id_country%TYPE,
        o_timezone           OUT ab_institution.id_timezone_region%TYPE,
        o_market             OUT ab_institution.id_ab_market%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_inst_attr         pk_types.cursor_type;
        o_inst_affiliations pk_types.cursor_type;
    
        l_id_lang              NUMBER;
        l_facility_group       VARCHAR2(1000);
        l_facility_type        VARCHAR2(1000);
        l_language             VARCHAR2(1000);
        l_currency_desc        VARCHAR2(1000);
        l_currency             VARCHAR2(1000);
        l_adress_type          VARCHAR2(1000);
        l_adress_type_desc     VARCHAR2(1000);
        l_country              VARCHAR2(1000);
        l_id_location_tax      VARCHAR2(1000);
        l_desc_timezone_region VARCHAR2(1000);
        l_market_desc          VARCHAR2(1000);
        l_contact_det          VARCHAR2(1000);
        l_county               VARCHAR2(1000);
        l_address_other_name   VARCHAR2(1000);
        l_clues                VARCHAR2(1000);
        l_health_license       VARCHAR2(1000);
        l_id_street_type       VARCHAR2(1000);
        l_street_type          VARCHAR2(1000);
        l_street_name          VARCHAR2(1000);
        l_outdoor_number       VARCHAR2(1000);
        l_indoor_number        VARCHAR2(1000);
        l_id_settlement_type   VARCHAR2(1000);
        l_settlement_type      VARCHAR2(1000);
        l_id_settlement_name   VARCHAR2(1000);
        l_settlement_name      VARCHAR2(1000);
        l_id_entity            VARCHAR2(1000);
        l_desc_entity          VARCHAR2(1000);
        l_id_municip           VARCHAR2(1000);
        l_desc_municip         VARCHAR2(1000);
        l_id_localidad         VARCHAR2(1000);
        l_desc_localidad       VARCHAR2(1000);
        l_jurisdiction         VARCHAR2(1000);
        l_id_postal_code       VARCHAR2(1000);
        l_postal_code          VARCHAR2(1000);
    
    BEGIN
        IF NOT
            pk_backoffice.get_institution_attributes(i_lang, i_id_institution, o_inst_attr, o_inst_affiliations, o_error)
        THEN
            RETURN FALSE;
        
        END IF;
    
        FETCH o_inst_attr
            INTO o_inst_attrib_id,
                 l_id_lang,
                 o_institution_name,
                 o_parent_institution,
                 l_clues,
                 l_facility_group,
                 o_institution_type,
                 l_facility_type,
                 o_flg_available,
                 o_soc_security,
                 o_shortname,
                 o_language,
                 l_language,
                 o_currency,
                 l_currency_desc,
                 l_currency,
                 o_phone_num,
                 o_fax_num,
                 o_email,
                 l_health_license,
                 l_adress_type,
                 l_adress_type_desc,
                 o_address,
                 o_city,
                 o_state,
                 l_id_street_type,
                 l_street_type,
                 l_street_name,
                 l_outdoor_number,
                 l_indoor_number,
                 l_id_settlement_type,
                 l_settlement_type,
                 l_id_settlement_name,
                 l_settlement_name,
                 l_id_entity,
                 l_desc_entity,
                 l_id_municip,
                 l_desc_municip,
                 l_id_localidad,
                 l_desc_localidad,
                 l_id_postal_code,
                 l_postal_code,
                 o_zipcode,
                 o_country,
                 l_jurisdiction,
                 l_country,
                 l_id_location_tax,
                 o_timezone,
                 l_desc_timezone_region,
                 o_market,
                 l_market_desc,
                 l_contact_det,
                 l_county,
                 l_address_other_name;
    
        pk_types.close_cursor_if_opened(o_inst_attr);
    
        RETURN TRUE;
    
    END get_institution_attributes;

    /********************************************************************************************
    * Set New Institution (Main Method)
    *
    * @param i_lang                Log Language ID
    * @param i_id_institution      id_institution to configure Null if new
    * @param i_id_inst_att         id_institution attributes to update null if new
    * @param i_id_inst_lang        id_institution languate to update null if new
    * @param i_desc                Institution Name
    * @param i_id_parent           Institution parent id
    * @param i_flg_type            Institution Type
    * @param i_tax                 Institution Tax Id
    * @param i_abbreviation        Institution shortname
    * @param i_pref_lang           Institution predefined language
    * @param i_currency            Institution currency
    * @param i_phone_number        Institution phone number
    * @param i_fax                 Institution fax number
    * @param i_email               Institution email adress
    * @param i_adress              Institution adress
    * @param i_location            Institution adress city
    * @param i_geo_state           Institution adress state
    * @param i_zip_code            Institution zip code
    * @param i_country             Institution country
    * @param i_id_tz_region        Institution Timezone
    * @param i_id_market           Institution market
    * @param o_id_institution      Output id institution created or updated
    * @param o_error               error output
    *
    * @result                      true or false
    *
    * @author                      RMGM
    * @version                     2.6.3
    * @since                       2013/12/10
    ********************************************************************************************/
    FUNCTION set_institution_data
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN ab_institution.id_ab_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang   IN institution_language.id_institution_language%TYPE,
        i_desc           IN translation.desc_lang_1%TYPE,
        i_id_parent      IN ab_institution.id_ab_institution_parent%TYPE,
        i_flg_type       IN ab_institution.flg_type%TYPE,
        i_tax            IN inst_attributes.social_security_number%TYPE,
        i_abbreviation   IN ab_institution.shortname%TYPE,
        i_pref_lang      IN language.id_language%TYPE,
        i_currency       IN inst_attributes.id_currency%TYPE,
        i_phone_number   IN ab_institution.phone_number%TYPE,
        i_fax            IN ab_institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_adress         IN ab_institution.address1%TYPE,
        i_location       IN ab_institution.address2%TYPE,
        i_geo_state      IN ab_institution.address3%TYPE,
        i_zip_code       IN ab_institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_flg_available  IN VARCHAR2,
        i_id_tz_region   IN ab_institution.id_timezone_region%TYPE,
        i_id_market      IN ab_institution.id_ab_market%TYPE,
        o_id_institution OUT ab_institution.id_ab_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        o_id_inst_attributes inst_attributes.id_inst_attributes%TYPE := NULL;
        o_id_inst_lang       institution_language.id_institution_language%TYPE := NULL;
    
    BEGIN
        IF NOT pk_backoffice.set_institution_data(i_lang               => i_lang,
                                                  i_id_institution     => i_id_institution,
                                                  i_clues              => NULL,
                                                  i_id_inst_att        => i_id_inst_att,
                                                  i_id_inst_lang       => i_id_inst_lang,
                                                  i_desc               => i_desc,
                                                  i_id_parent          => i_id_parent,
                                                  i_flg_type           => i_flg_type,
                                                  i_tax                => i_tax,
                                                  i_abbreviation       => i_abbreviation,
                                                  i_pref_lang          => i_pref_lang,
                                                  i_currency           => i_currency,
                                                  i_phone_number       => i_phone_number,
                                                  i_fax                => i_fax,
                                                  i_email              => i_email,
                                                  i_health_license     => NULL,
                                                  i_adress             => i_adress,
                                                  i_location           => i_location,
                                                  i_geo_state          => i_geo_state,
                                                  i_id_street_type     => NULL,
                                                  i_street_name        => NULL,
                                                  i_outdoor_number     => NULL,
                                                  i_indoor_number      => NULL,
                                                  i_id_settlement_type => NULL,
                                                  i_id_settlement_name => NULL,
                                                  i_id_entity          => NULL,
                                                  i_id_municip         => NULL,
                                                  i_id_localidad       => NULL,
                                                  i_id_postal_code     => NULL,
                                                  i_zip_code           => i_zip_code,
                                                  i_country            => i_country,
                                                  i_jurisdiction       => NULL,
                                                  i_location_tax       => NULL,
                                                  i_lic_model          => NULL,
                                                  i_pay_sched          => NULL,
                                                  i_pay_opt            => NULL,
                                                  i_flg_available      => i_flg_available,
                                                  i_id_tz_region       => i_id_tz_region,
                                                  i_id_market          => i_id_market,
                                                  i_contact_det        => NULL,
                                                  i_commit_at_end      => TRUE,
                                                  o_id_institution     => o_id_institution,
                                                  o_id_inst_attributes => o_id_inst_attributes,
                                                  o_id_inst_lang       => o_id_inst_lang,
                                                  o_error              => o_error)
        THEN
            RETURN FALSE;
        ELSE
            pk_api_ab_tables.upd_ab_institution(id_ab_institution_in => o_id_institution,
                                                flg_external_nin     => TRUE,
                                                flg_external_in      => 'N');
            pk_sysconfig.insert_into_sysconfig(i_idsysconfig     => 'LANGUAGE',
                                               i_value           => i_pref_lang,
                                               i_institution     => o_id_institution,
                                               i_software        => 0,
                                               i_desc            => 'Language',
                                               i_fill_type       => 'K',
                                               i_client_config   => 'N',
                                               i_internal_config => 'N',
                                               i_global_config   => 'N',
                                               i_schema          => 'A');
            RETURN TRUE;
        END IF;
    END set_institution_data;
    /********************************************************************************************
    * Get display for apex LOV (Software Institution configuration)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION get_software_institution_list(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
    
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.inst_name,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT si.id_ab_software_institution mcdt_id,
                       coalesce(s.description,
                                (SELECT pk_translation.get_translation(pk_utils.get_institution_language(si.id_ab_institution),
                                                                       s.code_software)
                                   FROM dual)) mcdt_desc,
                       (SELECT pk_translation.get_translation(pk_utils.get_institution_language(si.id_ab_institution),
                                                              i.code_institution)
                          FROM dual) inst_name,
                       NULL room_id,
                       NULL default_flg,
                       NULL item_type,
                       NULL item_type_desc
                  FROM ab_software_institution si
                 INNER JOIN ab_institution i
                    ON (i.id_ab_institution = si.id_ab_institution)
                 INNER JOIN ab_software s
                    ON (s.id_ab_software = si.id_ab_software)
                 WHERE i.flg_available = g_flg_available
                   AND s.flg_viewer = g_no
                 ORDER BY inst_name, mcdt_desc) res_data;
    
        RETURN l_tbl_res;
    END get_software_institution_list;
    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION get_all_institution_report(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.inst_name,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 i.id_ab_institution  mcdt_id,
                 trl.desc_translation mcdt_desc,
                 NULL                 inst_name,
                 NULL                 room_id,
                 NULL                 default_flg,
                 NULL                 item_type,
                 NULL                 item_type_desc
                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'AB_INSTITUTION', g_flg_available)) trl
                 INNER JOIN ab_institution i
                    ON (i.code_institution = trl.code_translation)
                 WHERE i.flg_available = g_flg_available) res_data;
        RETURN l_tbl_res;
    END get_all_institution_report;

    FUNCTION get_institution_logo
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB IS
        l_img BLOB;
    BEGIN
        SELECT img_logo
          INTO l_img
          FROM institution_logo
         WHERE id_institution = i_id_institution;
    
        RETURN l_img;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_institution_logo;

    FUNCTION get_institution_banner
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB IS
        l_img BLOB;
    BEGIN
        SELECT img_banner
          INTO l_img
          FROM institution_logo
         WHERE id_institution = i_id_institution;
    
        RETURN l_img;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_institution_banner;

    FUNCTION get_institution_banner_small
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE
    ) RETURN BLOB IS
        l_img BLOB;
    BEGIN
        SELECT img_banner_small
          INTO l_img
          FROM institution_logo
         WHERE id_institution = i_id_institution;
    
        RETURN l_img;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_institution_banner_small;

    FUNCTION set_institution_logos
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution institution.id_institution%TYPE,
        i_logo           IN BLOB,
        i_banner         IN BLOB,
        i_banner_small   IN BLOB
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(0)
          INTO l_count
          FROM institution_logo
         WHERE id_institution = i_id_institution;
    
        IF l_count = 0
        THEN
            INSERT INTO institution_logo
                (id_institution_logo, id_institution, img_banner, img_banner_small, img_logo)
            VALUES
                (i_id_institution, i_id_institution, i_banner, i_banner_small, i_logo);
        ELSE
            IF i_banner IS NOT NULL
            THEN
                UPDATE institution_logo
                   SET img_banner = i_banner
                 WHERE id_institution = i_id_institution;
            
            END IF;
        
            IF i_banner_small IS NOT NULL
            THEN
                UPDATE institution_logo
                   SET img_banner_small = i_banner_small
                 WHERE id_institution = i_id_institution;
            
            END IF;
        
            IF i_logo IS NOT NULL
            THEN
                UPDATE institution_logo
                   SET img_logo = i_logo
                 WHERE id_institution = i_id_institution;
            
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN FALSE;
    END set_institution_logos;
    /********************************************************************************************
    * set list of softwares to be used in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/12
    ********************************************************************************************/
    FUNCTION set_institution_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN ab_institution.id_ab_institution%TYPE,
        i_software_list  IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_si_pk ab_software_institution.id_ab_software_institution%TYPE := NULL;
        o_si_pk ab_software_institution.id_ab_software_institution%TYPE := NULL;
    BEGIN
        FOR i IN 1 .. i_software_list.count
        LOOP
            SELECT nvl((SELECT si.id_software_institution
                         FROM software_institution si
                        WHERE si.id_institution = i_id_institution
                          AND si.id_software = i_software_list(i)),
                       NULL)
              INTO l_si_pk
              FROM dual;
            pk_api_ab_tables.upd_ins_into_ab_software_inst(l_si_pk,
                                                           NULL,
                                                           'A',
                                                           i_id_institution,
                                                           i_software_list(i),
                                                           o_si_pk);
            -- get_all roles available for software in institution configuration
        -- set role configuration in institution                                               
        -- pk_api_ab_tables.insert_into_ab_sw_inst_role(,i_id_institution,i_software_list(i),l_sir_pk);
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_institution_software',
                                              o_error);
            RETURN FALSE;
        
    END set_institution_software;
    /********************************************************************************************
    * Delete row of software institution configuration
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/12
    ********************************************************************************************/
    PROCEDURE delete_inst_soft
    (
        i_lang     IN language.id_language%TYPE,
        i_id_si_pk IN ab_software_institution.id_ab_software_institution%TYPE
    ) IS
        l_sup_str VARCHAR2(1000) := 'id_ab_software_institution =' || i_id_si_pk;
    BEGIN
        IF i_id_si_pk IS NOT NULL
        THEN
            pk_api_ab_tables.del_from_ab_software_inst(l_sup_str);
        END IF;
    END delete_inst_soft;
    /********************************************************************************************
    * Set building in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION set_building
    (
        i_lang          IN language.id_language%TYPE,
        i_building_id   IN building.id_building%TYPE,
        i_building_name IN translation.desc_lang_1%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_pk building.id_building%TYPE := 0;
        l_code       VARCHAR2(200) := 'BUILDING.CODE_BUILDING.';
        --lang_num     NUMBER := 0;
        l_langs table_number;
    BEGIN
    
        IF i_building_id IS NULL
        THEN
            l_current_pk := seq_building.nextval;
            l_code       := l_code || l_current_pk;
        
            INSERT INTO building
                (id_building, code_building, flg_available, adw_last_update)
            VALUES
                (l_current_pk, l_code, g_flg_available, SYSDATE);
        
        ELSE
            l_code := l_code || i_building_id;
        END IF;
    
        l_langs := get_lang();
        /*        SELECT COUNT(*)
         INTO lang_num
         FROM LANGUAGE l
        WHERE l.flg_available = g_flg_available;*/
    
        FOR i IN 1 .. l_langs.count
        LOOP
            pk_translation.insert_into_translation(l_langs(i), l_code, i_building_name);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_building',
                                              o_error);
            RETURN FALSE;
        
    END set_building;

    /********************************************************************************************
    * Update building description
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    PROCEDURE update_building_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_building_id   IN building.id_building%TYPE,
        i_building_name IN translation.desc_lang_1%TYPE
    ) IS
        l_code VARCHAR2(200) := 'BUILDING.CODE_BUILDING.';
        --lang_num NUMBER := 0;
        l_langs table_number;
    BEGIN
        l_langs := get_lang();
        /*  SELECT COUNT(*)
         INTO lang_num
         FROM LANGUAGE l
        WHERE l.flg_available = g_flg_available;*/
    
        l_code := l_code || i_building_id;
        FOR i IN 1 .. l_langs.count
        LOOP
            pk_translation.insert_into_translation(l_langs(i), l_code, i_building_name);
        END LOOP;
    END update_building_desc;
    /********************************************************************************************
    * Disable building record listed in apex
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    PROCEDURE disable_building
    (
        i_lang        IN language.id_language%TYPE,
        i_building_id IN building.id_building%TYPE
    ) IS
    BEGIN
        UPDATE building b
           SET b.flg_available = g_no
         WHERE b.id_building = i_building_id;
    END disable_building;

    /********************************************************************************************
    * Disable floor record listed in apex
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    PROCEDURE disable_floor
    (
        i_lang     IN language.id_language%TYPE,
        i_floor_id IN floors.id_floors%TYPE
    ) IS
    BEGIN
        UPDATE floors f
           SET f.flg_available = g_no
         WHERE f.id_floors = i_floor_id;
    END disable_floor;

    /********************************************************************************************
    * Get display for apex LOV (building report)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    FUNCTION get_building_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res              t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_institution_language language.id_language%TYPE := pk_utils.get_institution_language(i_institution);
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.institution_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                DISTINCT desc_translation mcdt_desc,
                         id_building      mcdt_id,
                         institution_desc,
                         NULL             room_id,
                         NULL             default_flg,
                         NULL             item_type,
                         NULL             item_type_desc
                  FROM (SELECT /*+ dynamic_sampling(trl,2) */
                         trl.desc_translation desc_translation,
                         b.id_building,
                         (SELECT pk_utils.get_institution_name(i_lang, fi.id_institution)
                            FROM dual) institution_desc
                          FROM floors_institution fi
                          JOIN institution i
                            ON fi.id_institution = i.id_institution
                          JOIN building b
                            ON fi.id_building = b.id_building
                          JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                            ON trl.code_translation = b.code_building
                         WHERE b.flg_available = g_flg_available
                           AND (fi.id_institution = i_institution)
                        
                        UNION
                        SELECT /*+ dynamic_sampling(trl,2) */
                         trl.desc_translation, b.id_building, '-' institution_desc
                          FROM building b
                          JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                            ON trl.code_translation = b.code_building
                         WHERE b.flg_available = g_flg_available
                           AND id_building NOT IN (SELECT id_building
                                                     FROM floors_institution fi
                                                    WHERE fi.id_building IS NOT NULL)
                        UNION
                        
                        SELECT /*+ dynamic_sampling(trl,2) */
                         trl.desc_translation desc_translation,
                         b.id_building,
                         (SELECT pk_utils.get_institution_name(i_lang, fi.id_institution)
                            FROM dual) institution_desc
                          FROM floors_institution fi
                          JOIN institution i
                            ON fi.id_institution = i.id_institution
                          JOIN building b
                            ON fi.id_building = b.id_building
                          JOIN TABLE(pk_translation.get_table_translation(l_institution_language, 'BUILDING', 'Y')) trl
                            ON trl.code_translation = b.code_building
                         WHERE b.flg_available = g_flg_available
                           AND fi.id_institution IN
                               (SELECT id_institution
                                  FROM institution
                                 WHERE id_parent = (SELECT id_parent
                                                      FROM institution
                                                     WHERE id_institution = i_institution)))) res_data;
        RETURN l_tbl_res;
    END get_building_report;
    /********************************************************************************************
    * Get display for apex LOV (Floors Institution report)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/13
    ********************************************************************************************/
    FUNCTION get_floors_report
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.room_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 f.id_floors mcdt_id,
                 trl.desc_translation mcdt_desc,
                 fi.id_institution room_id,
                 pk_translation.get_translation(i_lang, i.code_institution) room_desc,
                 fi.id_building item_type,
                 pk_translation.get_translation(i_lang, b.code_building) item_type_desc,
                 fi.id_floors_institution default_flg
                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'FLOORS', g_flg_available)) trl
                 INNER JOIN floors f
                    ON (f.code_floors = trl.code_translation)
                 INNER JOIN floors_institution fi
                    ON (fi.id_floors = f.id_floors)
                 INNER JOIN institution i
                    ON (i.id_institution = fi.id_institution)
                 INNER JOIN building b
                    ON (b.id_building = fi.id_building)
                 WHERE fi.id_institution = i_institution
                   AND fi.flg_available = g_flg_available
                   AND f.flg_available = g_flg_available
                   AND i.flg_available = g_flg_available
                   AND b.flg_available = g_flg_available) res_data;
    
        RETURN l_tbl_res;
    END get_floors_report;

    PROCEDURE get_floor_data
    (
        i_lang           IN language.id_language%TYPE,
        i_floor_id       IN floors.id_floors%TYPE,
        o_floor_name     OUT VARCHAR2,
        o_floor_image    OUT floors.image_plant%TYPE,
        o_floor_building OUT floors_institution.id_building%TYPE
    ) IS
    
    BEGIN
        o_floor_name := pk_translation.get_translation(i_lang, 'FLOORS.CODE_FLOORS.' || i_floor_id);
        SELECT f.image_plant
          INTO o_floor_image
          FROM floors f
         WHERE f.id_floors = i_floor_id;
    
        SELECT fi.id_building
          INTO o_floor_building
          FROM floors_institution fi
         WHERE fi.id_floors = i_floor_id;
    
    END get_floor_data;
    /********************************************************************************************
    * Set FLOORS in institution
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION set_floors_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_floor       IN floors.id_floors%TYPE,
        i_floor_name     IN translation.desc_lang_1%TYPE,
        i_image          IN floors.image_plant%TYPE,
        i_building       IN building.id_building%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_pk building.id_building%TYPE := 0;
        l_code       VARCHAR2(200) := 'FLOORS.CODE_FLOORS.';
        -- lang_num     NUMBER := 0;
        l_langs table_number;
    BEGIN
    
        IF i_id_floor IS NULL
        THEN
            l_current_pk := seq_floors.nextval;
            l_code       := l_code || l_current_pk;
            INSERT INTO floors
                (id_floors, code_floors, image_plant, rank, flg_available, adw_last_update)
            VALUES
                (l_current_pk, l_code, i_image, 0, g_flg_available, SYSDATE);
        
            INSERT INTO floors_institution
                (id_floors_institution, id_floors, id_institution, flg_available, adw_last_update, id_building)
            VALUES
                (seq_floors_institution.nextval, l_current_pk, i_id_institution, g_flg_available, SYSDATE, i_building);
        
        ELSE
            UPDATE floors f
               SET f.image_plant = i_image
             WHERE f.id_floors = i_id_floor;
        
            UPDATE floors_institution fi
               SET fi.id_building = i_building
             WHERE fi.id_floors = i_id_floor;
        
            l_code := l_code || i_id_floor;
        
        END IF;
    
        l_langs := get_lang();
    
        /*    SELECT COUNT(*)
         INTO lang_num
         FROM LANGUAGE l
        WHERE l.flg_available = g_flg_available;*/
    
        FOR i IN 1 .. l_langs.count
        LOOP
            pk_translation.insert_into_translation(l_langs(i), l_code, i_floor_name);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_floors_institution',
                                              o_error);
            RETURN FALSE;
    END set_floors_institution;
    /********************************************************************************************
    * Update or Insert institution group configuration record using apex (Institution Group config)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION set_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN table_number,
        i_id_group       IN table_number,
        i_flg_relation   IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        FOR i IN 1 .. i_id_institution.count
        LOOP
            FOR j IN 1 .. i_id_group.count
            LOOP
                g_error := 'UPDATE INSTITUTION GROUP FOR ' || i_id_institution(i) || ',' || i_id_group(j) || ',' ||
                           i_flg_relation(j);
                UPDATE institution_group ig
                   SET ig.id_group = i_id_group(j)
                 WHERE ig.id_institution = i_id_institution(i)
                   AND ig.flg_relation = i_flg_relation(j);
                IF SQL%ROWCOUNT = 0
                THEN
                    g_error := 'INSERT INSTITUTION GROUP FOR ' || i_id_institution(i) || ',' || i_id_group(j) || ',' ||
                               i_flg_relation(j);
                    INSERT INTO institution_group
                        (id_institution, flg_relation, id_group)
                    VALUES
                        (i_id_institution(i), i_flg_relation(j), i_id_group(j));
                END IF;
            END LOOP;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_institution_group',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_institution_group;
    /********************************************************************************************
    * Delete institution group configuration record using apex (Institution Group config)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION del_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_group       IN institution_group.id_group%TYPE,
        i_flg_relation   IN institution_group.flg_relation%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'DELETE INSTITUTION GROUP FOR ' || i_id_institution || ',' || i_id_group || ', ' || i_flg_relation;
        DELETE FROM institution_group ig
         WHERE ig.id_institution = i_id_institution
           AND ig.id_group = i_id_group
           AND ig.flg_relation = i_flg_relation;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'del_institution_group',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_institution_group;
    /********************************************************************************************
    * Get Report for apex (Institution Group information)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/18
    ********************************************************************************************/
    FUNCTION get_institution_group
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.room_desc,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT pk_translation.get_translation(i_lang, i.code_institution) mcdt_desc,
                       ig.id_institution mcdt_id,
                       ig.id_group room_id,
                       ig.flg_relation room_desc,
                       NULL default_flg,
                       NULL item_type,
                       NULL item_type_desc
                  FROM institution_group ig
                 INNER JOIN institution i
                    ON (i.id_institution = ig.id_institution)
                 WHERE (ig.id_institution = i_id_institution OR i_id_institution = -1)) res_data;
        RETURN l_tbl_res;
    END get_institution_group;

    PROCEDURE set_def_process_job_args
    (
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_market        IN table_number,
        i_version       IN table_varchar,
        i_software      IN table_number,
        i_dcs_full_list IN table_number,
        i_cs_full_list  IN table_number,
        o_config_type   OUT VARCHAR2,
        o_areas         OUT VARCHAR2,
        o_tables        OUT VARCHAR2,
        o_market        OUT VARCHAR2,
        o_version       OUT VARCHAR2,
        o_software      OUT VARCHAR2,
        o_dcs_full_list OUT VARCHAR2,
        o_cs_full_list  OUT VARCHAR2
    ) IS
    BEGIN
        o_config_type := 'table_varchar(''' || pk_utils.concat_table(i_config_type, ''',''') || ''')';
    
        IF i_areas.count = 0
        THEN
            o_areas := 'table_varchar()';
        ELSE
            o_areas := 'table_varchar(''' || pk_utils.concat_table(i_areas, ''',''') || ''')';
        END IF;
    
        IF i_tables.count = 0
        THEN
            o_tables := 'table_varchar()';
        ELSE
            o_tables := 'table_varchar(''' || pk_utils.concat_table(i_tables, ''',''') || ''')';
        END IF;
    
        IF i_market.count = 0
        THEN
            o_market := 'table_number()';
        ELSE
            o_market := 'table_number(' || pk_utils.concat_table(i_market, ',') || ')';
        END IF;
        IF i_version.count = 0
        THEN
            o_version := 'table_varchar()';
        ELSE
            o_version := 'table_varchar(''' || pk_utils.concat_table(i_version, ''',''') || ''')';
        END IF;
        IF i_software.count = 0
        THEN
            o_software := 'table_number()';
        ELSE
            o_software := 'table_number(' || pk_utils.concat_table(i_software, ',') || ')';
        END IF;
        IF i_dcs_full_list.count = 0
        THEN
            o_dcs_full_list := 'table_number()';
        ELSE
            o_dcs_full_list := 'table_number(' || pk_utils.concat_table(i_dcs_full_list, ',') || ')';
        END IF;
        IF i_cs_full_list.count = 0
        THEN
            o_cs_full_list := 'table_number()';
        ELSE
            o_cs_full_list := 'table_number(' || pk_utils.concat_table(i_cs_full_list, ',') || ')';
        END IF;
    END set_def_process_job_args;

    /* DEfault process execute by job - Apex area execution consumer */
    FUNCTION send_default_process_job_area
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_session_type  IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_dependencies  IN VARCHAR2,
        i_market        IN table_varchar,
        i_version       IN table_varchar,
        i_software      IN table_varchar,
        i_flg_dcs_all   IN table_varchar,
        i_dcs_full_list IN table_varchar,
        i_cs_full_list  IN table_varchar
    ) RETURN table_varchar IS
        l_sql           VARCHAR2(4000);
        new_job         sys.job;
        new_job_list    sys.job_array := sys.job_array();
        l_job_name      VARCHAR2(200);
        l_job_name_list table_varchar := table_varchar();
    
        l_enabled BOOLEAN;
    BEGIN
    
        FOR i IN 1 .. i_config_type.count
        LOOP
            l_job_name := dbms_scheduler.generate_job_name('DEF_');
            l_sql      := 'declare l_exec number; o_error t_error_out;' ||
                          ' BEGIN  alert_core_func.pk_tool_engine.g_type := ''' || i_session_type || ''';
                           alert_core_func.pk_tool_engine.g_author := ''' || i_author || ''';' ||
                          'alert_core_func.pk_tool_engine.set_default_configuration(i_lang  => ' || i_lang ||
                          ', i_market => table_number(' || i_market(i) || '),' || ' i_version => table_varchar(''' ||
                          i_version(i) || '''),' || ' i_institution => ' || i_institution ||
                          ' , i_d_institution => NULL,' || ' i_software => table_number(' || i_software(i) || '),' ||
                          ' i_flg_dcs_all => ''' || i_flg_dcs_all(i) || ''',' ||
                          ' i_id_clinical_service => table_number(' || i_cs_full_list(i) ||
                          '), i_dep_clin_serv  => table_number(' || i_dcs_full_list(i) || '), i_dependencies  => ''' ||
                          i_dependencies || ''', i_process_type => table_varchar(' || i_config_type(i) || '),';
        
            IF i_tables IS NULL
               OR i_tables.count = 0
            THEN
                l_sql := l_sql || 'i_areas   => table_varchar(''' || i_areas(i) || '''), i_tables => table_varchar(),';
            ELSE
            
                l_sql := l_sql || 'i_areas   => table_varchar(), i_tables => table_varchar(''' || i_tables(i) || '''),';
            END IF;
        
            l_sql := l_sql || ' o_execution_id => l_exec, o_error  => o_error);' || ' END;';
            -- only 1st job is enabled, remainig are being sequentialy enabled by apex dynamic action
            IF i = 1
            THEN
                l_enabled := TRUE;
            ELSE
                l_enabled := FALSE;
            END IF;
        
            new_job := sys.job(job_name       => l_job_name,
                               job_style      => 'REGULAR',
                               program_action => l_sql,
                               action_type    => 'PLSQL_BLOCK',
                               number_of_args => 0,
                               start_date     => current_timestamp,
                               comments       => 'Default process execution for area ' || i_areas(i),
                               max_failures   => 2,
                               auto_drop      => TRUE,
                               enabled        => l_enabled);
        
            l_job_name_list.extend;
            l_job_name_list(i) := l_job_name;
            new_job_list.extend;
            new_job_list(i) := new_job;
            pk_alertlog.log_debug('DEFAULT JOB name ' || l_job_name_list(i) || 'sent. Sql sent: ' || l_sql);
        
            dbms_output.put_line('DEFAULT JOB n? ' || l_job_name_list(i) || 'sent. Sql sent: ' || l_sql);
            l_sql := '';
        END LOOP;
        IF l_job_name_list.count > 0
        THEN
            dbms_scheduler.create_jobs(new_job_list);
        END IF;
    
        RETURN l_job_name_list;
    END send_default_process_job_area;

    /* DEfault process execute by job - Apex area execution consumer */
    FUNCTION send_default_process_job
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_session_type  IN VARCHAR2,
        i_author        IN VARCHAR2,
        i_config_type   IN table_varchar,
        i_areas         IN table_varchar,
        i_tables        IN table_varchar,
        i_dependencies  IN VARCHAR2,
        i_market        IN table_number,
        i_version       IN table_varchar,
        i_software      IN table_number,
        i_flg_dcs_all   IN VARCHAR2,
        i_dcs_full_list IN table_number,
        i_cs_full_list  IN table_number
    ) RETURN VARCHAR2 IS
        l_sql        VARCHAR2(4000);
        new_job      sys.job;
        l_job_name   VARCHAR2(200);
        new_job_list sys.job_array := sys.job_array();
    
        l_config_type   VARCHAR2(4000);
        l_areas         VARCHAR2(4000);
        l_tables        VARCHAR2(4000);
        l_market        VARCHAR2(4000);
        l_version       VARCHAR2(4000);
        l_software      VARCHAR2(4000);
        l_dcs_full_list VARCHAR2(4000);
        l_cs_full_list  VARCHAR2(4000);
    
    BEGIN
        l_job_name := dbms_scheduler.generate_job_name('DEF_');
    
        set_def_process_job_args(i_config_type   => i_config_type,
                                 i_areas         => i_areas,
                                 i_tables        => i_tables,
                                 i_market        => i_market,
                                 i_version       => i_version,
                                 i_software      => i_software,
                                 i_dcs_full_list => i_dcs_full_list,
                                 i_cs_full_list  => i_cs_full_list,
                                 o_config_type   => l_config_type,
                                 o_areas         => l_areas,
                                 o_tables        => l_tables,
                                 o_market        => l_market,
                                 o_version       => l_version,
                                 o_software      => l_software,
                                 o_dcs_full_list => l_dcs_full_list,
                                 o_cs_full_list  => l_cs_full_list);
    
        l_sql := 'DECLARE l_exec number; o_error t_error_out;' || '
				 BEGIN alert_core_func.pk_tool_engine.g_type := ''' || i_session_type || ''';
					alert_core_func.pk_tool_engine.g_author := ''' || i_author || ''';' ||
                 'alert_core_func.pk_tool_engine.set_default_configuration(i_lang  => ' || i_lang || '
				 ,i_market => ' || l_market || '
				 ,i_version => ' || l_version || '
				 ,i_institution => ' || i_institution || '
				 ,i_d_institution => NULL
				 ,i_software => ' || l_software || '
				 ,i_flg_dcs_all => ''' || i_flg_dcs_all || '''
				 ,i_id_clinical_service => ' || l_cs_full_list || '
				 ,i_dep_clin_serv  => ' || l_dcs_full_list || '
				 ,i_dependencies  => ''' || i_dependencies || '''
				 ,i_process_type => ' || l_config_type || '
				 ,i_areas   => ' || l_areas || '
				 ,i_tables =>  ' || l_tables || '
				 ,o_execution_id => l_exec
				 ,o_error  => o_error);' || ' END;';
    
        new_job := sys.job(job_name       => l_job_name,
                           job_style      => 'REGULAR',
                           program_action => l_sql,
                           action_type    => 'PLSQL_BLOCK',
                           number_of_args => 0,
                           start_date     => current_timestamp,
                           comments       => 'Default process execution',
                           max_failures   => 2,
                           auto_drop      => TRUE,
                           enabled        => TRUE);
    
        pk_alertlog.log_debug('DEFAULT JOB name ' || l_job_name || 'sent. Sql sent: ' || l_sql);
        dbms_output.put_line('DEFAULT JOB name ' || l_job_name || 'sent. Sql sent: ' || l_sql);
    
        new_job_list.extend;
        new_job_list(1) := new_job;
        dbms_scheduler.create_jobs(new_job_list);
    
        RETURN l_job_name;
    END send_default_process_job;

    /* Get info about current job and if they have finished the routine */
    FUNCTION get_job_status_complete(i_cur_job_name IN VARCHAR2) RETURN BOOLEAN IS
        l_temp_count NUMBER := 0;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_temp_count
          FROM dba_scheduler_job_log sjl
         WHERE sjl.job_name = i_cur_job_name;
    
        IF l_temp_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END get_job_status_complete;
    /* Enable job */
    PROCEDURE set_job_enable(i_cur_job_name IN VARCHAR2) IS
    BEGIN
        dbms_scheduler.enable(i_cur_job_name);
    END set_job_enable;

    FUNCTION synch_ncd_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_code_translation IN translation.code_translation%TYPE DEFAULT 'ALL',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_api_backoffice_default.synch_ncd_translation(i_lang, i_code_translation, o_error);
    
    END synch_ncd_translation;

    FUNCTION get_job_report(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields IS
        l_result t_tbl_apex_manyfields;
        l_error  t_error_out;
    BEGIN
        SELECT t_rec_apex_manyfields(job_name, status, flg_status, start_date, end_date, additional_info, NULL) BULK COLLECT
          INTO l_result
          FROM (SELECT job_name,
                       status,
                       CASE status
                           WHEN 'SUCCEEDED' THEN
                            'Y'
                           WHEN 'COMPLETED' THEN
                            'Y'
                           WHEN 'FAILED' THEN
                            'F'
                           WHEN 'STOPPED' THEN
                            'F'
                           WHEN 'BROKEN' THEN
                            'F'
                           WHEN 'RETRY SCHEDULED' THEN
                            'F'
                           ELSE
                            'W'
                       END flg_status,
                       pk_date_utils.dt_year_day_hour_chr_short(i_lang, actual_start_date, NULL) start_date,
                       pk_date_utils.dt_year_day_hour_chr_short(i_lang, end_date, NULL) end_date,
                       additional_info
                  FROM (SELECT jl.job_name,
                               jl.status,
                               jrd.actual_start_date,
                               jl.log_date           end_date,
                               jrd.additional_info   additional_info
                          FROM all_scheduler_job_log jl
                          JOIN all_scheduler_job_run_details jrd
                            ON jl.log_id = jrd.log_id
                         WHERE jl.job_name LIKE 'DEF\_%' ESCAPE '\'
                            OR jl.job_name LIKE 'POSTDEFMNT%'
                            OR jl.job_name LIKE 'MIG_APS\_%' ESCAPE '\'
                            OR jl.job_name LIKE 'NCD_SYNCH\_%' ESCAPE '\'
                        UNION ALL
                        SELECT j.job_name, j.state, j.start_date, NULL end_date, NULL additional_info
                          FROM all_scheduler_jobs j
                         WHERE j.job_name LIKE 'DEF\_%' ESCAPE '\'
                            OR j.job_name LIKE 'POSTDEFMNT%'
                            OR j.job_name LIKE 'MIG_APS\_%' ESCAPE '\'
                            OR j.job_name LIKE 'NCD_SYNCH\_%' ESCAPE '\')
                 ORDER BY actual_start_date DESC);
    
        RETURN l_result;
    
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
                                              'get_job_report',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_job_report;

    /********************************************************************************************
    * Get visit list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_visit_report
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_patient_list IN VARCHAR2,
        i_visit_list   IN VARCHAR2
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(data.id_visit,
                                     data.flg_status,
                                     data.id_external_cause,
                                     data.id_patient,
                                     data.id_origin,
                                     data.id_institution,
                                     data.barcode) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT v.id_visit,
                       v.flg_status,
                       v.id_external_cause,
                       v.id_patient,
                       v.id_origin,
                       v.id_institution,
                       v.barcode
                  FROM visit v
                 WHERE v.id_institution = i_institution
                   AND (i_patient_list IS NULL OR v.id_patient = i_patient_list)
                   AND (i_visit_list IS NULL OR
                       v.id_visit IN
                       (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                          column_value
                           FROM TABLE(CAST(pk_utils.str_split_n(i_visit_list, ':') AS table_number))))) data;
    
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_tbl_res;
    END get_visit_report;

    /********************************************************************************************
    * Get episode list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_episode_report
    (
        i_lang             IN language.id_language%TYPE,
        i_institution_list IN table_number,
        i_patient_list     IN table_number,
        i_visit_list       IN table_number,
        i_episode_list     IN table_number
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res       t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_instit_count  NUMBER := i_institution_list.count;
        l_patient_count NUMBER := i_patient_list.count;
        l_visit_count   NUMBER := i_visit_list.count;
        l_episode_count NUMBER := i_episode_list.count;
    BEGIN
        SELECT t_rec_apex_manyfields(data.id_episode,
                                     data.id_visit,
                                     data.id_clinical_service,
                                     data.flg_status,
                                     data.id_epis_type,
                                     data.barcode,
                                     data.id_prof_cancel) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT e.id_episode,
                       e.id_visit,
                       e.id_clinical_service,
                       e.flg_status,
                       e.id_epis_type,
                       e.barcode,
                       e.id_prof_cancel
                  FROM episode e
                 WHERE (l_instit_count = 0 OR
                       e.id_institution IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                              column_value
                                               FROM TABLE(i_institution_list)))
                   AND (l_patient_count = 0 OR
                       e.id_patient IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                          column_value
                                           FROM TABLE(i_patient_list)))
                   AND (l_visit_count = 0 OR
                       e.id_visit IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                        column_value
                                         FROM TABLE(i_visit_list)))
                   AND (l_episode_count = 0 OR
                       e.id_episode IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                          column_value
                                           FROM TABLE(i_episode_list)))) data;
    
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_tbl_res;
    END get_episode_report;

    /********************************************************************************************
    * Get visit list report
    *
    * @param i_lang  Language id
    * @param i_institution  Institution id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_patient_report
    (
        i_lang             IN language.id_language%TYPE,
        i_institution_list IN table_number,
        i_patient_list     IN table_number
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res       t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_patient_count NUMBER := i_patient_list.count;
    BEGIN
        SELECT t_rec_apex_manyfields(data.name,
                                     data.id_patient,
                                     data.id_person,
                                     data.gender,
                                     data.dt_birth,
                                     data.age,
                                     NULL) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT p.name, p.id_patient, p.id_person, p.gender, p.dt_birth, p.age
                  FROM patient p
                 WHERE (l_patient_count = 0 AND EXISTS
                        (SELECT 1
                           FROM visit v
                          WHERE v.id_patient = p.id_patient
                            AND v.id_institution IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                      column_value
                                                       FROM TABLE(i_institution_list))) OR
                        p.id_patient IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                          column_value
                                           FROM TABLE(i_patient_list)))) data;
    
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_tbl_res;
    END get_patient_report;

    /********************************************************************************************
    * Get all tables with id_content not from alerT_default
    *
    * @param i_lang  Language id
    *
    * @return table of results
    *
    * @author                        LCRS
    * @version                       2.6.4.x
    * @since                         2014/07/31
    ********************************************************************************************/
    FUNCTION get_tables_w_id_content_rep(i_lang IN language.id_language%TYPE) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(data.owner, data.table_name, NULL, NULL, NULL, NULL, NULL) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT DISTINCT a.owner, a.table_name
                  FROM dba_tab_cols a
                 WHERE a.owner != 'ALERT_DEFAULT'
                   AND a.column_name = 'ID_CONTENT'
                   AND EXISTS (SELECT 1
                          FROM dba_tab_cols b
                         WHERE b.owner = 'ALERT_DEFAULT'
                           AND b.column_name = a.column_name
                           AND a.table_name = b.table_name)
                 ORDER BY owner, table_name) data;
    
        RETURN l_tbl_res;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_tbl_res;
    END get_tables_w_id_content_rep;
    -- check if there are external institutions conection
    FUNCTION get_checkpoint_external_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_cfg_cnt  NUMBER(24) := 0;
        l_max_rows NUMBER(24) := 0;
    BEGIN
        SELECT COUNT(*)
          INTO l_max_rows
          FROM institution x
         WHERE x.id_market = pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_id_institution)
           AND x.flg_external = g_flg_available
           AND x.flg_available = g_flg_available;
    
        SELECT COUNT(*)
          INTO l_cfg_cnt
          FROM TABLE(pk_backoffice_ext_instit.get_ext_instit_list_data(i_lang, i_id_institution, NULL)) tbl;
    
        IF l_cfg_cnt > 0
        THEN
            RETURN g_flg_available;
        ELSE
            RETURN 'N';
        END IF;
    END get_checkpoint_external_inst;
    -- chech if institution is a discharge destination
    FUNCTION get_checkpoint_disch_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_cfg_cnt NUMBER(24) := 0;
    BEGIN
        SELECT COUNT(*)
          INTO l_cfg_cnt
          FROM disch_reas_dest drd
         WHERE drd.id_institution = i_id_institution;
    
        IF l_cfg_cnt > 0
        THEN
            RETURN g_flg_available;
        ELSE
            RETURN 'N';
        END IF;
    END get_checkpoint_disch_inst;
    -- check if institution is parent of other
    FUNCTION get_checkpoint_parent_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_cfg_cnt NUMBER(24) := 0;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_cfg_cnt
          FROM ab_institution i1
         WHERE i1.id_ab_institution_parent = i_id_institution;
    
        IF l_cfg_cnt > 0
        THEN
            RETURN g_flg_available;
        ELSE
            RETURN 'N';
        END IF;
    END get_checkpoint_parent_inst;
    -- check if institution is in same group as others
    FUNCTION get_checkpoint_group_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2 IS
        l_cfg_cnt NUMBER(24) := 0;
    BEGIN
        SELECT COUNT(*)
          INTO l_cfg_cnt
          FROM institution_group ig
         WHERE ig.id_institution = i_id_institution;
    
        IF l_cfg_cnt > 0
        THEN
            RETURN g_flg_available;
        ELSE
            RETURN 'N';
        END IF;
    END get_checkpoint_group_inst;

    /********************************************************************************************
    * Get display for apex LOV (Software not external)
    *
    * @author                        RMGM
    * @version                       2.6.3
    * @since                         2013/12/11
    ********************************************************************************************/
    FUNCTION get_institution_report
    (
        i_lang       IN language.id_language%TYPE,
        i_instit_chr IN VARCHAR2
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
        SELECT t_rec_apex_manyfields(res_data.mcdt_desc,
                                     res_data.mcdt_id,
                                     res_data.inst_name,
                                     res_data.room_id,
                                     res_data.default_flg,
                                     res_data.item_type,
                                     res_data.item_type_desc) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT /*+ dynamic_sampling(trl,2) */
                 i.id_ab_institution mcdt_id,
                 trl.desc_translation mcdt_desc,
                 pk_sysdomain.get_domain('AB_INSTITUTION.FLG_TYPE', i.flg_type, i_lang) inst_name,
                 i.id_ab_institution_parent room_id,
                 i.id_ab_market default_flg,
                 i.flg_external item_type,
                 NULL item_type_desc
                  FROM TABLE(pk_translation.get_table_translation(i_lang, 'AB_INSTITUTION', g_flg_available)) trl
                 INNER JOIN ab_institution i
                    ON (i.code_institution = trl.code_translation)
                 WHERE i.flg_available = g_flg_available
                   AND (i_instit_chr IS NULL OR
                       i.id_ab_institution IN
                       (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                          column_value
                           FROM TABLE(CAST(pk_utils.str_split_n(i_instit_chr, ':') AS table_number))))) res_data;
        RETURN l_tbl_res;
    END get_institution_report;
    /********************************************************************************************
    * Send request to IA services in order to do operations according to system configuration changes
    *
    * @param i_cfg_id  System configuration id
    * @param i_value  Value
    * @param i_institution  Institution ID
    * @param i_software  Software ID
    *
    * @author                        RMGM
    * @version                       2.6.4.3
    * @since                         2015/02/19
    ********************************************************************************************/
/*PROCEDURE set_ncd_updates
    (
        i_cfg_id      IN sys_config.id_sys_config%TYPE,
        i_value       IN sys_config.value%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) IS
        l_cfg_id sys_config.id_sys_config%TYPE := 'SURGICAL_PROCEDURES_CODING';
    BEGIN
        IF i_cfg_id = l_cfg_id
        THEN
            pk_ia_event_backoffice.sr_interv_disable_all(i_institution);
            COMMIT;
            migra_new_sr_procedures_apssch(i_value, i_institution, i_software);
        ELSE
            NULL;
        END IF;
    
    END set_ncd_updates;*/

BEGIN
    init_vars();
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_default_apex;
/
