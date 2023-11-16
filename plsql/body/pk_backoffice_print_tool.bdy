/*-- Last Change Revision: $Rev: 2026798 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_print_tool IS

    /********************************************************************************************
    * Get a list of report profiles by software and institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_rep_profile         Reports Profile List cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Sérgio Cunha
    * @version                     0.1
    * @since                       2009/01/06
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/25
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_rep_profile_instit_soft
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_rep_profile    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
    
        l_id_market := get_id_market_soft_inst(i_lang, i_id_software, i_id_institution);
    
        g_error := 'GET REPORT PROFILE CURSOR';
    
        OPEN o_rep_profile FOR
            SELECT DISTINCT rpt.id_rep_profile_template,
                            pk_utils.concat_table(CAST(MULTISET
                                                       (SELECT DISTINCT pk_message.get_message(i_lang,
                                                                                               'PROFILE_TEMPLATE.CODE_PROFILE_TEMPLATE.' ||
                                                                                               rpta.id_profile_template) ||
                                                                        decode(rpt.id_rep_profile_template,
                                                                               0,
                                                                               '',
                                                                               decode(m.id_market,
                                                                                      0,
                                                                                      '',
                                                                                      
                                                                                      ' (' ||
                                                                                      pk_translation.get_translation(i_lang,
                                                                                                                     m.code_market) || ')'))
                                                        
                                                          FROM rep_prof_templ_access   rpta,
                                                               profile_template        pt,
                                                               profile_template_market ptm,
                                                               market                  m
                                                         WHERE rpta.id_rep_profile_template =
                                                               rpt.id_rep_profile_template
                                                           AND rpta.id_profile_template = pt.id_profile_template
                                                           AND pt.id_profile_template = ptm.id_profile_template
                                                           AND ptm.id_market IN (0, l_id_market)
                                                           AND pt.id_software IN (i_id_software, 0)
                                                              -- JR: allow the default profile
                                                           AND (pt.flg_available = pk_alert_constant.g_available OR
                                                               rpt.id_rep_profile_template = 0)
                                                           AND ptm.id_market = m.id_market(+)
                                                         ORDER BY 1) AS table_varchar),
                                                  ', ') name
              FROM rep_profile_template rpt
              JOIN rep_prof_templ_access rpta
                ON rpta.id_rep_profile_template = rpt.id_rep_profile_template
              JOIN profile_template pt
                ON pt.id_profile_template = rpta.id_profile_template
              JOIN profile_template_market ptm
                ON ptm.id_profile_template = pt.id_profile_template
             WHERE rpt.id_software IN (i_id_software, 0)
               AND rpt.id_institution IN (i_id_institution, 0)
               AND ptm.id_market IN (l_id_market, 0)
                  -- JR: because the profile = 0 on ALERT has FLG_AVAILABLE = N we should allow this profile for report sections
               AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_profile);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REP_PROFILE_INSTIT_SOFT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_rep_profile_instit_soft;

    /********************************************************************************************
    * Get a list of reports available and selected by profile
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile ID
    * @param o_rep_list                        Reports Profile List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/07
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/25
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_rep_soft
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE,
        o_rep_list                OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
    
        l_id_market := get_id_market_soft_inst(i_lang, i_id_software, i_id_institution);
    
        g_error := 'GET PROFILE TEMPLATE REPORT CURSOR';
    
        OPEN o_rep_list FOR
            SELECT rptd.id_reports id,
                   nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) name,
                   rptd.flg_available flg_status,
                   nvl(rptd.flg_disclosure, pk_alert_constant.g_no) flg_disclosure
              FROM rep_profile_template_det rptd
              JOIN reports r
                ON rptd.id_reports = r.id_reports
               AND rptd.id_rep_profile_template = i_id_rep_profile_template
               AND rptd.flg_area_report = 'R'
               AND rptd.flg_available IN (pk_alert_constant.g_yes, g_flg_unavailable)
               AND r.flg_available = pk_alert_constant.g_yes
               AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
               AND rptd.id_reports IN
                   (SELECT rptd.id_reports
                      FROM rep_profile_template     rpt,
                           rep_prof_templ_access    rpta,
                           profile_template         pt,
                           profile_template_market  ptm,
                           rep_profile_template_det rptd
                     WHERE rpt.id_rep_profile_template = rpta.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND pt.id_software = i_id_software
                       AND ptm.id_market IN (0, l_id_market)
                          -- JR: because the profile = 0 on ALERT has FLG_AVAILABLE = N we should allow this profile for report sections
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND rptd.id_rep_profile_template = rpt.id_rep_profile_template)
            UNION
            SELECT rptd.id_reports id,
                   nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) name,
                   rptd.flg_available flg_status,
                   nvl(rptd.flg_disclosure, pk_alert_constant.g_no) flg_disclosure
              FROM rep_profile_template_det rptd
              JOIN reports r
                ON rptd.id_reports = r.id_reports
             WHERE rptd.id_rep_profile_template = i_id_rep_profile_template
               AND rptd.flg_area_report = 'R'
               AND rptd.flg_available = pk_alert_constant.g_yes
               AND r.flg_available = pk_alert_constant.g_yes
               AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
               AND rptd.id_reports NOT IN
                   (SELECT rptd.id_reports
                      FROM rep_profile_template_det rptd
                     WHERE rptd.id_rep_profile_template = i_id_rep_profile_template
                       AND rptd.flg_area_report = 'R'
                       AND rptd.flg_available IN (pk_alert_constant.g_yes, g_flg_unavailable))
               AND rptd.id_reports IN
                   (SELECT rptd.id_reports
                      FROM rep_profile_template     rpt,
                           rep_prof_templ_access    rpta,
                           profile_template         pt,
                           profile_template_market  ptm,
                           rep_profile_template_det rptd
                     WHERE rpt.id_rep_profile_template = rpta.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND pt.id_software = i_id_software
                       AND ptm.id_market IN (0, l_id_market)
                          -- JR: because the profile = 0 on ALERT has FLG_AVAILABLE = N we should allow this profile for report sections
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND rptd.id_rep_profile_template = rpt.id_rep_profile_template)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REP_SOFT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_rep_soft;

    /********************************************************************************************
    * Get a list of sections available by report
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param o_rep_section_list                Report Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/07
    ********************************************************************************************/
    FUNCTION get_print_tool_rep_details
    (
        i_lang             IN language.id_language%TYPE,
        i_id_software      IN software.id_software%TYPE,
        i_id_reports       IN reports.id_reports%TYPE,
        o_rep_section_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET REPORT SECTIONS CURSOR';
    
        OPEN o_rep_section_list FOR
            SELECT pk_message.get_message(i_lang, 'REP_SECTION.CODE_REP_SECTION.' || rsd.id_rep_section) name, rs.rank
              FROM rep_section_det rsd
              JOIN rep_section rs
                ON rsd.id_rep_section = rs.id_rep_section
             WHERE rsd.id_reports = i_id_reports
               AND rsd.id_institution = 0
               AND rsd.id_software IN (i_id_software, 0)
               AND rs.flg_available = pk_alert_constant.g_yes
               AND rsd.flg_visible = pk_alert_constant.g_yes
             ORDER BY rs.rank, name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_section_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REP_PRINT_TOOL_REP_DETAILS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_print_tool_rep_details;

    /********************************************************************************************
    * Get a list of reports available by software
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_institution                  Institution ID
    * @param o_rep_list                        Reports by software List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/08
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/25
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_reports_soft
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_rep_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
        -- arrays
        v_temp_id_rep   table_number := table_number();
        v_temp_name_rep table_varchar := table_varchar();
    
        v_final_id_rep   table_number := table_number();
        v_final_name_rep table_varchar := table_varchar();
        -- array index
        l_index NUMBER;
        -- changed in order to avoid duplication in the grid
    
        CURSOR c_generic_reports(i_reps table_number) IS
            SELECT DISTINCT r.id_reports,
                            nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                                pk_translation.get_translation(i_lang, r.code_reports)) name
              FROM (SELECT rptd.id_reports
                      FROM rep_profile_template_det rptd,
                           rep_prof_templ_access    rpta,
                           profile_template_market  ptm,
                           profile_template         pt
                     WHERE rptd.flg_area_report IN ('R', 'E', 'CR', 'C')
                       AND rptd.flg_available IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
                       AND rptd.id_rep_profile_template IN
                           (SELECT rpt.id_rep_profile_template
                              FROM rep_profile_template rpt
                             WHERE rpt.id_software = i_id_software)
                       AND rpta.id_rep_profile_template = rptd.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND ptm.id_market = 0
                       AND pt.id_profile_template = ptm.id_profile_template
                          -- JR: allow profile = 0
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND pt.id_software = i_id_software
                    UNION ALL
                    SELECT rptd.id_reports
                      FROM rep_profile_template_det rptd,
                           rep_prof_templ_access    rpta,
                           profile_template_market  ptm,
                           profile_template         pt
                     WHERE rptd.flg_available IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
                          -- 19/04/2011 RMGM: add new areas
                       AND rptd.flg_area_report IN ('R', 'E', 'CR', 'C')
                       AND rpta.id_rep_profile_template = rptd.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND ptm.id_market = 0
                       AND pt.id_profile_template = ptm.id_profile_template
                          -- JR: allow profile = 0
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND pt.id_software = i_id_software
                     GROUP BY rptd.id_reports
                    HAVING COUNT(1) = (SELECT COUNT(DISTINCT id_software)
                                        FROM rep_profile_template rpt)) rep
             INNER JOIN reports r
                ON (r.id_reports = rep.id_reports)
             INNER JOIN rep_section_det rsd
                ON (rsd.id_reports = r.id_reports)
             WHERE r.flg_available = pk_alert_constant.g_yes
               AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
               AND rsd.id_software IN (0, i_id_software)
               AND rsd.id_institution IN (0, i_id_institution)
               AND r.id_reports NOT IN (SELECT column_value id_reports
                                          FROM TABLE(i_reps));
    
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
    
        l_id_market := get_id_market_soft_inst(i_lang, i_id_software, i_id_institution);
    
        g_error := 'GET REPORTS SOFTWARE BY MARKET';
        pk_alertlog.log_debug(g_error);
    
        IF i_id_software = 0
        THEN
            SELECT DISTINCT r.id_reports,
                            concat(nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                                       pk_translation.get_translation(i_lang, r.code_reports)),
                                   decode(l_id_market,
                                          0,
                                          '',
                                          ' (' || (SELECT pk_translation.get_translation(i_lang, m.code_market)
                                                     FROM market m
                                                    WHERE m.id_market = l_id_market) || ')')) name
              BULK COLLECT
              INTO v_temp_id_rep, v_temp_name_rep
              FROM (SELECT rptd.id_reports
                      FROM rep_profile_template_det rptd,
                           rep_prof_templ_access    rpta,
                           profile_template_market  ptm,
                           profile_template         pt
                     WHERE rptd.flg_available IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
                          -- 19/04/2011 RMGM: add new areas
                       AND rptd.flg_area_report IN ('R', 'E', 'CR', 'C')
                       AND rpta.id_rep_profile_template = rptd.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND ptm.id_market = l_id_market
                       AND pt.id_profile_template = ptm.id_profile_template
                          -- JR: because the profile = 0 on ALERT has FLG_AVAILABLE = N we should allow this profile for report sections
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND pt.id_software = i_id_software
                     GROUP BY rptd.id_reports
                    HAVING COUNT(1) = (SELECT COUNT(DISTINCT id_software)
                                        FROM rep_profile_template rpt)) rep
             INNER JOIN reports r
                ON (r.id_reports = rep.id_reports)
             INNER JOIN rep_section_det rsd
                ON (rsd.id_reports = r.id_reports)
             WHERE r.flg_available = pk_alert_constant.g_yes
               AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
               AND rsd.id_software IN (0, i_id_software)
               AND rsd.id_institution IN (0, i_id_institution);
        ELSE
            SELECT DISTINCT r.id_reports,
                            concat(nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                                       pk_translation.get_translation(i_lang, r.code_reports)),
                                   decode(l_id_market,
                                          0,
                                          '',
                                          ' (' || (SELECT pk_translation.get_translation(i_lang, m.code_market)
                                                     FROM market m
                                                    WHERE m.id_market = l_id_market) || ')')) name
              BULK COLLECT
              INTO v_temp_id_rep, v_temp_name_rep
              FROM (SELECT rptd.id_reports
                      FROM rep_profile_template_det rptd,
                           rep_prof_templ_access    rpta,
                           profile_template_market  ptm,
                           profile_template         pt
                     WHERE rptd.flg_area_report IN ('R', 'E', 'CR', 'C')
                       AND rptd.flg_available IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
                       AND rptd.id_rep_profile_template IN
                           (SELECT rpt.id_rep_profile_template
                              FROM rep_profile_template rpt
                             WHERE rpt.id_software = i_id_software)
                       AND rpta.id_rep_profile_template = rptd.id_rep_profile_template
                       AND rpta.id_profile_template = ptm.id_profile_template
                       AND ptm.id_market = l_id_market
                       AND pt.id_profile_template = ptm.id_profile_template
                          -- JR: because the profile = 0 on ALERT has FLG_AVAILABLE = N we should allow this profile for report sections
                       AND (pt.flg_available = pk_alert_constant.g_yes OR pt.id_profile_template = 0)
                       AND pt.id_software = i_id_software) rep
             INNER JOIN reports r
                ON (r.id_reports = rep.id_reports)
             INNER JOIN rep_section_det rsd
                ON (rsd.id_reports = r.id_reports)
             WHERE r.flg_available = pk_alert_constant.g_yes
               AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                       pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
               AND rsd.id_software IN (0, i_id_software)
               AND rsd.id_institution IN (0, i_id_institution);
        END IF;
    
        g_error := 'GET REPORTS SOFTWARE GENERIC';
        pk_alertlog.log_debug(g_error);
    
        FOR repx IN c_generic_reports(v_temp_id_rep)
        LOOP
            -- add to existing array?
            l_index := v_temp_id_rep.count + 1;
            v_temp_id_rep.extend;
            v_temp_name_rep.extend;
            v_temp_id_rep(l_index) := repx.id_reports;
            v_temp_name_rep(l_index) := repx.name;
        END LOOP;
    
        g_error := 'GET REPORTS SOFTWARE CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_rep_list FOR
            SELECT ti.column_value id, tn.column_value name
              FROM (SELECT column_value, rownum AS id
                      FROM TABLE(v_temp_id_rep)) ti,
                   (SELECT column_value, rownum AS id
                      FROM TABLE(v_temp_name_rep)) tn
             WHERE tn.id = ti.id
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REPORTS_SOFT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_reports_soft;

    /********************************************************************************************
    * Get a list of sections available by profile
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param i_section_visibility              Flag indicating whether virtual sections should also be returned ('A' = All, 'Y' = Visible, 'N' = Invisible)
    * @param o_rep_section_list                Report Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/08
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/26
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_rep_section_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE DEFAULT 0,
        i_section_visibility      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_rep_section_list        OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
        l_prof      profissional;
    
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution);
        --l_id_market := get_id_market_soft_inst(i_lang, i_id_software, i_id_institution);
    
        l_prof := profissional(0, i_id_institution, i_id_software);
    
        g_error := 'GET REPORT SECTIONS CURSOR';
    
        OPEN o_rep_section_list FOR
            SELECT rsd.id_rep_section id,
                   rsd.id_institution,
                   rsd.id_software,
                   rsd.id_rep_profile_template,
                   pk_message.get_message(i_lang, l_prof, 'REP_SECTION.CODE_REP_SECTION.' || rsd.id_rep_section) name,
                   rsd.rank,
                   decode(rsd.flg_default,
                          NULL,
                          'Y',
                          decode(rsd.flg_default, pk_alert_constant.g_active, pk_alert_constant.g_yes, g_flg_unavailable)) flg_status
              FROM rep_section_det rsd
              JOIN rep_section rs
                ON rsd.id_rep_section = rs.id_rep_section
              JOIN rep_profile_template_det rptd
                ON rptd.id_reports = rsd.id_reports
              JOIN rep_prof_templ_access rpta
                ON rpta.id_rep_profile_template = rptd.id_rep_profile_template
              JOIN profile_template_market ptm
                ON ptm.id_profile_template = rpta.id_profile_template
            
             WHERE rsd.id_reports = i_id_reports
               AND nvl(rs.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND rsd.id_software = i_id_software
               AND rsd.id_institution = i_id_institution
               AND rsd.id_rep_profile_template =
                   decode((SELECT COUNT(*) num
                            FROM rep_section_det rsd2
                           WHERE rsd2.id_reports = i_id_reports
                             AND rsd2.id_institution IN (i_id_institution, pk_alert_constant.g_inst_all)
                             AND rsd2.id_software IN (i_id_software, pk_alert_constant.g_soft_all)
                             AND rsd2.id_rep_section = rsd.id_rep_section
                             AND rsd2.id_market IN (l_id_market, 0)
                             AND rsd2.id_rep_profile_template = i_id_rep_profile_template),
                          0,
                          0,
                          i_id_rep_profile_template)
               AND rsd.id_market =
                   decode((SELECT COUNT(*) num
                            FROM rep_section_det rsd2
                           WHERE rsd2.id_reports = i_id_reports
                             AND rsd2.id_institution IN (i_id_institution, pk_alert_constant.g_inst_all)
                             AND rsd2.id_software IN (i_id_software, pk_alert_constant.g_soft_all)
                             AND rsd2.id_rep_section = rsd.id_rep_section
                             AND rsd2.id_market = l_id_market),
                          0,
                          pk_alert_constant.g_soft_all,
                          l_id_market)
               AND (i_section_visibility = g_flg_all OR i_section_visibility = rsd.flg_visible)
            ------------------------------
            UNION
            SELECT rsd.id_rep_section id,
                   rsd.id_institution,
                   rsd.id_software,
                   rsd.id_rep_profile_template,
                   pk_message.get_message(i_lang, l_prof, 'REP_SECTION.CODE_REP_SECTION.' || rsd.id_rep_section) name,
                   rsd.rank,
                   decode(rsd.flg_default,
                          NULL,
                          'Y',
                          decode(rsd.flg_default, pk_alert_constant.g_active, pk_alert_constant.g_yes, g_flg_unavailable)) flg_status
              FROM rep_section_det rsd
              JOIN rep_section rs
                ON rsd.id_rep_section = rs.id_rep_section
              JOIN rep_profile_template_det rptd
                ON rptd.id_reports = rsd.id_reports
              JOIN rep_prof_templ_access rpta
                ON rpta.id_rep_profile_template = rptd.id_rep_profile_template
              JOIN profile_template_market ptm
                ON ptm.id_profile_template = rpta.id_profile_template
            
             WHERE rsd.id_reports = i_id_reports
               AND nvl(rs.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND rsd.id_software = 0
               AND rsd.id_institution = i_id_institution
                  -- JR: only profile sections should be returned or sections which belong to profile = 0 (ALL)
               AND (rsd.id_rep_profile_template = i_id_rep_profile_template OR rsd.id_rep_profile_template = 0)
               AND rsd.id_rep_section NOT IN
                   (SELECT rsd.id_rep_section
                      FROM rep_section_det rsd
                     WHERE rsd.id_reports = i_id_reports
                       AND id_software = i_id_software
                       AND id_institution = i_id_institution
                       AND (rsd.id_rep_profile_template IN (i_id_rep_profile_template, 0)))
               AND ptm.id_market IN (0, l_id_market)
               AND rsd.id_market =
                   decode((SELECT COUNT(*) num
                            FROM rep_section_det rsd2
                           WHERE rsd2.id_reports = i_id_reports
                             AND rsd2.id_institution IN (i_id_institution, pk_alert_constant.g_inst_all)
                             AND rsd2.id_software IN (i_id_software, pk_alert_constant.g_soft_all)
                             AND rsd2.id_rep_section = rsd.id_rep_section
                             AND rsd2.id_market = l_id_market),
                          0,
                          pk_alert_constant.g_soft_all,
                          l_id_market)
               AND (i_section_visibility = g_flg_all OR i_section_visibility = rsd.flg_visible)
            -------------------------------------
            UNION
            SELECT rsd.id_rep_section id,
                   rsd.id_institution,
                   rsd.id_software,
                   rsd.id_rep_profile_template,
                   pk_message.get_message(i_lang, l_prof, 'REP_SECTION.CODE_REP_SECTION.' || rsd.id_rep_section) name,
                   rsd.rank,
                   decode(rsd.flg_default,
                          NULL,
                          'Y',
                          decode(rsd.flg_default, pk_alert_constant.g_active, pk_alert_constant.g_yes, g_flg_unavailable)) flg_status
              FROM rep_section_det rsd
              JOIN rep_section rs
                ON rsd.id_rep_section = rs.id_rep_section
              JOIN rep_profile_template_det rptd
                ON rptd.id_reports = rsd.id_reports
              JOIN rep_prof_templ_access rpta
                ON rpta.id_rep_profile_template = rptd.id_rep_profile_template
              JOIN profile_template_market ptm
                ON ptm.id_profile_template = rpta.id_profile_template
            
             WHERE rsd.id_reports = i_id_reports
               AND nvl(rs.flg_available, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
               AND rsd.id_software IN (i_id_software, 0)
               AND rsd.id_institution = 0
                  -- JR: only profile sections should be returned or sections which belong to profile = 0 (ALL)
               AND (rsd.id_rep_profile_template = i_id_rep_profile_template OR rsd.id_rep_profile_template = 0)
               AND rsd.id_rep_section NOT IN
                   (SELECT rsd.id_rep_section
                      FROM rep_section_det rsd
                     WHERE rsd.id_reports = i_id_reports
                       AND id_software IN (i_id_software, 0)
                       AND id_institution = i_id_institution
                       AND (rsd.id_rep_profile_template IN (i_id_rep_profile_template, 0)))
               AND ptm.id_market IN (0, l_id_market)
               AND rsd.id_market =
                   decode((SELECT COUNT(*) num
                            FROM rep_section_det rsd2
                           WHERE rsd2.id_reports = i_id_reports
                             AND rsd2.id_institution IN (i_id_institution, pk_alert_constant.g_inst_all)
                             AND rsd2.id_software IN (i_id_software, pk_alert_constant.g_soft_all)
                             AND rsd2.id_rep_section = rsd.id_rep_section
                             AND rsd2.id_market = l_id_market),
                          0,
                          pk_alert_constant.g_soft_all,
                          l_id_market)
               AND (i_section_visibility = g_flg_all OR i_section_visibility = rsd.flg_visible)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_section_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REPORTS_SOFT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_rep_section_det;

    /********************************************************************************************
    * Updates the selected reports for a given profile.
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile Template ID
    * @param i_id_reports                      Table with selected Reports ID's
    * @param i_flg_available                   Table with selected value for each report
    * @param i_rep_institution                 Table with institution ID for each report
    * @param i_flg_area_report                 Table with flg_area for each report
    * @param o_rep_profile_template_det        Array with inserted/updated ids    
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Rui Gomes
    * @version                                 0.2
    * @since                                   2009/04/19
    ********************************************************************************************/
    FUNCTION set_rep_profile_template_det
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_software              IN software.id_software%TYPE,
        i_id_rep_profile_template  IN table_number,
        i_id_reports               IN table_table_number,
        i_flg_available            IN table_table_varchar,
        i_rep_institution          IN table_table_number,
        i_flg_disclosure           IN table_table_varchar,
        i_flg_area_report          IN table_table_varchar,
        o_rep_profile_template_det OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_rep_profile_template_det := table_number();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_PRINT_TOOL',
                                              'SET_REP_PROFILE_TEMPLATE_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END set_rep_profile_template_det;

    /********************************************************************************************
    * Updates the selected sections for a given report.
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Array with selected Reports ID's
    * @param i_id_rep_section                  Table with selected Report Sections ID's    
    * @param i_flg_active                      Table with selected value for each report section
    * @param i_rep_institution                 Table with institution ID for each report section
    * @param i_rep_software                    Table with software ID for each report section
    * @param i_software                        Array with software ID
    * @param o_rep_section_det                 Array with inserted/updated ids
    * @param o_error                           Error
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/09
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/26
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION set_rep_section_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE DEFAULT 0,
        i_id_reports              IN table_number,
        i_id_rep_section          IN table_table_number,
        i_flg_active              IN table_table_varchar,
        i_rep_institution         IN table_table_number,
        i_rep_software            IN table_table_number,
        i_software                IN table_number,
        o_rep_section_det         OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count              PLS_INTEGER := 0;
        l_rsd_count          PLS_INTEGER := 0;
        l_err_id             PLS_INTEGER;
        l_id_rep_section_det rep_section_det.id_rep_section_det%TYPE;
        l_section_rank       rep_section_det.rank%TYPE;
    
    BEGIN
    
        o_rep_section_det := table_number();
    
        IF i_id_reports.count > 0
        THEN
            FOR i IN i_id_reports.first .. i_id_reports.last
            LOOP
                FOR j IN i_id_rep_section(i).first .. i_id_rep_section(i).last
                LOOP
                    IF i_id_software = 0
                    THEN
                        FOR k IN i_software.first .. i_software.last
                        LOOP
                            IF i_software(k) != 0
                            THEN
                                l_id_rep_section_det := NULL;
                                g_error              := 'GET ID_REP_SECTION_DET_1';
                                pk_alertlog.log_debug(g_error);
                                BEGIN
                                    SELECT rsd.id_rep_section_det
                                      INTO l_id_rep_section_det
                                      FROM rep_section_det rsd
                                     WHERE rsd.id_reports = i_id_reports(i)
                                       AND rsd.id_rep_section = i_id_rep_section(i)
                                     (j)
                                       AND rsd.id_institution = i_id_institution
                                       AND rsd.id_software = i_software(k);
                                EXCEPTION
                                    -- This happens if there are no sections for that institution/software
                                    WHEN no_data_found THEN
                                        l_id_rep_section_det := NULL;
                                    WHEN OTHERS THEN
                                        l_id_rep_section_det := NULL;
                                END;
                            
                                IF l_id_rep_section_det IS NULL
                                THEN
                                
                                    SELECT COUNT(rsd.id_rep_section_det)
                                      INTO l_rsd_count
                                      FROM rep_section_det rsd
                                     WHERE rsd.id_reports = i_id_reports(i)
                                       AND rsd.id_rep_section = i_id_rep_section(i)
                                     (j)
                                       AND rsd.id_software = i_software(k)
                                       AND rsd.id_institution = i_id_institution
                                       AND rsd.id_rep_profile_template = i_id_rep_profile_template;
                                
                                    IF l_rsd_count = 0
                                    THEN
                                    
                                        g_error := 'GET ID_REP_SECTION_DET.NEXTVAL';
                                        pk_alertlog.log_debug(g_error);
                                        BEGIN
                                            SELECT seq_rep_section_det.nextval
                                              INTO l_id_rep_section_det
                                              FROM dual;
                                        END;
                                    
                                        g_error := 'GET RANK_1';
                                        pk_alertlog.log_debug(g_error);
                                        -- get the rank from the default parametrization
                                        BEGIN
                                            SELECT rsd.rank
                                              INTO l_section_rank
                                              FROM rep_section_det rsd
                                             WHERE rsd.id_reports = i_id_reports(i)
                                               AND rsd.id_rep_section = i_id_rep_section(i) (j)
                                               AND rsd.id_institution = 0
                                               AND rsd.id_software = 0;
                                        EXCEPTION
                                            WHEN no_data_found THEN
                                                l_section_rank := 0;
                                            WHEN OTHERS THEN
                                                l_section_rank := 0;
                                        END;
                                    
                                        g_error := 'INSERT INTO rep_section_det_1';
                                        pk_alertlog.log_debug(g_error);
                                        INSERT INTO rep_section_det
                                            (id_rep_section_det,
                                             id_reports,
                                             id_rep_section,
                                             id_software,
                                             id_institution,
                                             rank,
                                             flg_default,
                                             id_rep_profile_template)
                                        VALUES
                                            (l_id_rep_section_det,
                                             i_id_reports(i),
                                             i_id_rep_section(i) (j),
                                             i_software(k), -- Current software
                                             i_id_institution, -- Current institution
                                             l_section_rank,
                                             decode(i_flg_active(i) (j),
                                                    pk_alert_constant.g_yes,
                                                    pk_alert_constant.g_active,
                                                    pk_alert_constant.g_inactive),
                                             -- JR: set user profile for this section
                                             i_id_rep_profile_template);
                                    
                                    END IF;
                                ELSE
                                    -- If already exists data on the current institution, we
                                    -- update existing data on REP_SECTION_DET
                                    g_error := 'UPDATE rep_section_det';
                                    pk_alertlog.log_debug(g_error);
                                    UPDATE rep_section_det rsd
                                       SET rsd.flg_default = decode(i_flg_active(i) (j),
                                                                    pk_alert_constant.g_yes,
                                                                    pk_alert_constant.g_active,
                                                                    pk_alert_constant.g_inactive),
                                           -- JR: set user profile for this section
                                           rsd.id_rep_profile_template = i_id_rep_profile_template
                                     WHERE rsd.id_rep_section_det = l_id_rep_section_det;
                                END IF;
                            END IF;
                            o_rep_section_det.extend;
                            l_count := l_count + 1;
                            o_rep_section_det(l_count) := l_id_rep_section_det;
                        END LOOP;
                    ELSIF i_rep_institution(i) (j) = 0
                          OR i_rep_software(i) (j) != i_id_software
                    THEN
                    
                        SELECT COUNT(rsd.id_rep_section_det)
                          INTO l_rsd_count
                          FROM rep_section_det rsd
                         WHERE rsd.id_reports = i_id_reports(i)
                           AND rsd.id_rep_section = i_id_rep_section(i)
                         (j)
                           AND rsd.id_software = i_id_software
                           AND rsd.id_institution = i_id_institution
                           AND rsd.id_rep_profile_template = i_id_rep_profile_template;
                    
                        IF l_rsd_count = 0
                        THEN
                        
                            -- If the current report section only exists on institution 0, a new
                            -- record must be created on the current institution and software
                            g_error := 'GET ID_REP_SECTION_DET.NEXTVAL';
                            pk_alertlog.log_debug(g_error);
                            BEGIN
                                SELECT seq_rep_section_det.nextval
                                  INTO l_id_rep_section_det
                                  FROM dual;
                            END;
                        
                            g_error := 'GET RANK_2';
                            pk_alertlog.log_debug(g_error);
                            -- get the rank from the default parametrization
                            BEGIN
                                SELECT rsd.rank
                                  INTO l_section_rank
                                  FROM rep_section_det rsd
                                 WHERE rsd.id_reports = i_id_reports(i)
                                   AND rsd.id_rep_section = i_id_rep_section(i) (j)
                                   AND rsd.id_institution = 0
                                   AND rsd.id_software = 0;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_section_rank := 0;
                                WHEN OTHERS THEN
                                    l_section_rank := 0;
                            END;
                        
                            g_error := 'INSERT INTO rep_section_det';
                            pk_alertlog.log_debug(g_error);
                            INSERT INTO rep_section_det
                                (id_rep_section_det,
                                 id_reports,
                                 id_rep_section,
                                 id_software,
                                 id_institution,
                                 rank,
                                 flg_default,
                                 id_rep_profile_template)
                            VALUES
                                (l_id_rep_section_det,
                                 i_id_reports(i),
                                 i_id_rep_section(i) (j),
                                 i_id_software, -- Current software
                                 i_id_institution, -- Current institution
                                 l_section_rank,
                                 decode(i_flg_active(i) (j),
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_active,
                                        pk_alert_constant.g_inactive),
                                 -- JR: set user profile for this section
                                 i_id_rep_profile_template);
                        
                            o_rep_section_det.extend;
                            l_count := l_count + 1;
                            o_rep_section_det(l_count) := l_id_rep_section_det;
                        
                        END IF;
                    
                    ELSIF i_rep_institution(i) (j) = i_id_institution
                          AND i_rep_software(i) (j) = i_id_software
                    THEN
                        -- If already exists data on the current institution, we
                        -- update existing data on REP_SECTION_DET
                        g_error := 'GET ID REP_SECTION_DET';
                        pk_alertlog.log_debug(g_error);
                        BEGIN
                            SELECT id_rep_section_det
                              INTO l_id_rep_section_det
                              FROM rep_section_det rsd
                             WHERE rsd.id_reports = i_id_reports(i)
                               AND rsd.id_rep_section = i_id_rep_section(i)
                             (j)
                               AND rsd.id_software = i_id_software
                               AND rsd.id_institution = i_id_institution
                               AND rsd.id_rep_profile_template = i_id_rep_profile_template;
                        
                        EXCEPTION
                            -- This happens if there are no sections for that institution/software
                            WHEN no_data_found THEN
                                l_id_rep_section_det := NULL;
                            WHEN OTHERS THEN
                                l_id_rep_section_det := NULL;
                        END;
                    
                        IF l_id_rep_section_det IS NULL
                        THEN
                            -- record must be created on the current institution and software
                            g_error := 'GET ID_REP_SECTION_DET.NEXTVAL';
                            pk_alertlog.log_debug(g_error);
                            BEGIN
                                SELECT seq_rep_section_det.nextval
                                  INTO l_id_rep_section_det
                                  FROM dual;
                            END;
                        
                            g_error := 'GET RANK_2';
                            pk_alertlog.log_debug(g_error);
                            -- get the rank from the default parametrization
                            BEGIN
                                SELECT rsd.rank
                                  INTO l_section_rank
                                  FROM rep_section_det rsd
                                 WHERE rsd.id_reports = i_id_reports(i)
                                   AND rsd.id_rep_section = i_id_rep_section(i) (j)
                                   AND rsd.id_institution = 0
                                   AND rsd.id_software = 0;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_section_rank := 0;
                                WHEN OTHERS THEN
                                    l_section_rank := 0;
                            END;
                        
                            g_error := 'INSERT INTO rep_section_det';
                            pk_alertlog.log_debug(g_error);
                            INSERT INTO rep_section_det
                                (id_rep_section_det,
                                 id_reports,
                                 id_rep_section,
                                 id_software,
                                 id_institution,
                                 rank,
                                 flg_default,
                                 id_rep_profile_template)
                            VALUES
                                (l_id_rep_section_det,
                                 i_id_reports(i),
                                 i_id_rep_section(i) (j),
                                 i_id_software, -- Current software
                                 i_id_institution, -- Current institution
                                 l_section_rank,
                                 decode(i_flg_active(i) (j),
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_active,
                                        pk_alert_constant.g_inactive),
                                 -- JR: set user profile for this section
                                 i_id_rep_profile_template);
                        
                            o_rep_section_det.extend;
                            l_count := l_count + 1;
                            o_rep_section_det(l_count) := l_id_rep_section_det;
                        ELSE
                            g_error := 'UPDATE rep_section_det';
                            pk_alertlog.log_debug(g_error);
                            UPDATE rep_section_det rsd
                               SET rsd.flg_default = decode(i_flg_active(i) (j),
                                                            pk_alert_constant.g_yes,
                                                            pk_alert_constant.g_active,
                                                            pk_alert_constant.g_inactive),
                                   -- JR: set user profile for this section
                                   rsd.id_rep_profile_template = i_id_rep_profile_template
                             WHERE rsd.id_rep_section_det = l_id_rep_section_det;
                        
                            o_rep_section_det.extend;
                            l_count := l_count + 1;
                            o_rep_section_det(l_count) := l_id_rep_section_det;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        
            COMMIT;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'SET_REP_SECTION_DET2');
            
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END set_rep_section_det;

    /********************************************************************************************
    * Get the software available for the institution, including the "All" softwares clause
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID    
    * @param o_software                        Software ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/27
    ********************************************************************************************/
    FUNCTION get_instit_soft_rep_section
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'o_software';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_software FOR
            SELECT DISTINCT s.id_software id, s.name name
              FROM software_institution si
              JOIN software s
                ON si.id_software = s.id_software
              JOIN rep_profile_template rpt
                ON si.id_software = rpt.id_software
              JOIN rep_profile_template_det rpdt
                ON rpdt.id_rep_profile_template = rpt.id_rep_profile_template
              JOIN reports r
                ON rpdt.id_reports = r.id_reports
              JOIN rep_section_det rsd
                ON rsd.id_reports = r.id_reports
             WHERE s.flg_mni = pk_alert_constant.g_yes
               AND rpdt.flg_available = pk_alert_constant.g_yes
               AND r.flg_available = pk_alert_constant.g_yes
               AND rpdt.flg_area_report IN ('R', 'E')
               AND si.id_institution = i_id_institution
               AND s.id_software != 26
               AND rsd.id_institution IN (0, i_id_institution)
               AND rsd.flg_visible = pk_alert_constant.g_yes
            
            UNION
            SELECT 0 id, '<b>' || pk_message.get_message(i_lang, 'ADMINISTRATOR_T228') || '</b>'
              FROM dual
             ORDER BY id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_software);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_INSTIT_SOFT_REP_SECTION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_instit_soft_rep_section;

    /********************************************************************************************
    * Get the software available for the institution that have reports associated to profiles
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID    
    * @param o_software                        Software ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/02/16
    ********************************************************************************************/
    FUNCTION get_instit_soft_rep_profile
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'o_software';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_software FOR
            SELECT DISTINCT s.id_software id, s.name name
              FROM software_institution si
              JOIN software s
                ON si.id_software = s.id_software
              JOIN rep_profile_template rpt
                ON si.id_software = rpt.id_software
              JOIN rep_profile_template_det rpdt
                ON rpdt.id_rep_profile_template = rpt.id_rep_profile_template
              JOIN reports r
                ON rpdt.id_reports = r.id_reports
             WHERE s.flg_mni = pk_alert_constant.g_yes
               AND rpdt.flg_available = pk_alert_constant.g_yes
               AND r.flg_available = pk_alert_constant.g_yes
               AND rpdt.flg_area_report IN ('R', 'E')
               AND si.id_institution = i_id_institution
               AND s.id_software != 26
             ORDER BY id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_software);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_INSTIT_SOFT_REP_PROFILE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_instit_soft_rep_profile;

    /********************************************************************************************
    * Get MARKET ID by giving the software ID and institution ID
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_software                     Software ID
    * @param i_id_institution                  Institution ID
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Susana Silva
    * @version                                 2.6
    * @since                                   2010/02/11
    ********************************************************************************************/
    FUNCTION get_id_market_soft_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN NUMBER IS
    
        l_id_market market.id_market%TYPE;
        l_count     NUMBER := 0;
        l_error     t_error_out;
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_id_market
          FROM dual;
    
        IF l_id_market != 0
        THEN
        
            SELECT COUNT(*)
              INTO l_count
              FROM profile_template_market ptm, profile_template pt
             WHERE ptm.id_market = l_id_market
               AND ptm.id_profile_template = pt.id_profile_template
               AND pt.id_software = i_id_software
               AND pt.flg_available = pk_alert_constant.g_yes;
        
            IF l_count = 0
            THEN
                l_id_market := 0;
            END IF;
        
        END IF;
    
        RETURN l_id_market;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'get_count_profiles_market');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN l_count;
            END;
        
    END get_id_market_soft_inst;

    /********************************************************************************************
    * Get a list of ux available by section
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids        
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param i_id_rep_section                  ID section
    * @param o_rep_ux_section_list             Report UX Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/01
    ********************************************************************************************/
    FUNCTION get_rep_ux_section
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_reports          IN reports.id_reports%TYPE,
        i_id_rep_section      IN rep_section.id_rep_section%TYPE,
        o_rep_ux_section_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_REP_UX_SECTION';
        l_error         t_error_out;
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL GET_REP_UX_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_reports.get_rep_ux_section(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_institution      => i_id_institution,
                                             i_id_software         => i_id_software,
                                             i_id_reports          => i_id_reports,
                                             i_id_rep_section      => table_number(i_id_rep_section),
                                             o_rep_ux_section_list => o_rep_ux_section_list,
                                             o_error               => l_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_types.open_my_cursor(o_rep_ux_section_list);
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
            pk_types.open_my_cursor(o_rep_ux_section_list);
            RETURN FALSE;
        
    END get_rep_ux_section;

    /********************************************************************************************
    * Get a list of rules available by section
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param i_id_rep_section                  ID section
    * @param o_rep_rules_section_list          Report Rules Sections List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/03
    ********************************************************************************************/
    FUNCTION get_rep_rules_section
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN institution.id_institution%TYPE,
        i_id_software            IN software.id_software%TYPE,
        i_id_reports             IN reports.id_reports%TYPE,
        i_id_rep_section         IN rep_section.id_rep_section%TYPE,
        o_rep_rules_section_list OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_REP_RULES_SECTION';
        l_error         t_error_out;
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL GET_REP_RULES_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_reports.get_rep_rules_section(i_lang                   => i_lang,
                                                i_prof                   => i_prof,
                                                i_id_institution         => i_id_institution,
                                                i_id_software            => i_id_software,
                                                i_id_reports             => i_id_reports,
                                                i_id_rep_section         => table_number(i_id_rep_section),
                                                o_rep_rules_section_list => o_rep_rules_section_list,
                                                o_error                  => l_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_types.open_my_cursor(o_rep_rules_section_list);
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
            pk_types.open_my_cursor(o_rep_rules_section_list);
            RETURN FALSE;
        
    END get_rep_rules_section;

    /********************************************************************************************
    * Get a list of layout available by section
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports Profile ID
    * @param i_id_rep_section                  ID section
    * @param o_rep_layout_section_list         Report Layout List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/03
    ********************************************************************************************/
    FUNCTION get_rep_layout_section
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_rep_section          IN rep_section.id_rep_section%TYPE,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_REP_LAYOUT_SECTION';
        l_error         t_error_out;
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL GET_REP_LAYOUT_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_reports.get_rep_layout_section(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_id_institution          => i_id_institution,
                                                 i_id_software             => i_id_software,
                                                 i_id_reports              => i_id_reports,
                                                 i_id_rep_section          => table_number(i_id_rep_section),
                                                 o_rep_layout_section_list => o_rep_layout_section_list,
                                                 o_error                   => l_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            pk_types.open_my_cursor(o_rep_layout_section_list);
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
            pk_types.open_my_cursor(o_rep_layout_section_list);
            RETURN FALSE;
        
    END get_rep_layout_section;

    /********************************************************************************************
    * Updates the selected UX for a report section.
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports ID
    * @param i_id_institution                  Institution ID
    * @param i_rep_unique_identifier           Table with list of Ux for a report section
    * @param i_flg_active                      Table with selected values of Ux for a report section
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/03
    ********************************************************************************************/
    FUNCTION set_rep_ux_section
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_software           IN software.id_software%TYPE,
        i_id_reports            IN reports.id_reports%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_rep_unique_identifier IN table_varchar,
        i_flg_active            IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_REP_UX_SECTION';
    
        l_market market.id_market%TYPE;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_rep_unique_identifier.count:' ||
                   i_rep_unique_identifier.count || ' i_flg_active.count:' || i_flg_active.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF i_rep_unique_identifier.count > 0
        THEN
            FOR i IN i_rep_unique_identifier.first .. i_rep_unique_identifier.last
            LOOP
                g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                           i_id_software || ' i_id_reports:' || i_id_reports || ' i_rep_unique_identifier(' || i || '):' ||
                           i_rep_unique_identifier(i) || ' i_flg_active.count(' || i || '):' || i_flg_active(i);
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_function_name);
            
                MERGE INTO rep_unique_identifier_excep ruie
                USING (SELECT i_id_software id_software,
                              i_id_reports id_reports,
                              i_id_institution id_institution,
                              i_rep_unique_identifier(i) rep_unique_identifier,
                              decode(i_flg_active(i),
                                     pk_alert_constant.g_active,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_inactive,
                                     pk_alert_constant.g_yes) flg_exclude
                         FROM dual) new_v
                ON (ruie.id_software = new_v.id_software AND ruie.id_reports = new_v.id_reports AND ruie.id_institution = new_v.id_institution AND ruie.rep_unique_identifier = new_v.rep_unique_identifier)
                
                WHEN MATCHED THEN
                    UPDATE
                       SET ruie.flg_exclude = new_v.flg_exclude
                     WHERE ruie.flg_exclude <> new_v.flg_exclude
                    
                
                WHEN NOT MATCHED THEN
                    INSERT
                        (ruie.id_software,
                         ruie.id_reports,
                         ruie.id_institution,
                         ruie.rep_unique_identifier,
                         ruie.flg_exclude,
                         ruie.id_market)
                    VALUES
                        (new_v.id_software,
                         new_v.id_reports,
                         new_v.id_institution,
                         new_v.rep_unique_identifier,
                         new_v.flg_exclude,
                         l_market);
            
            END LOOP;
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
        
            RETURN FALSE;
    END set_rep_ux_section;

    /********************************************************************************************
    * Updates the selected Layout for a report section.
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports ID
    * @param i_id_institution                  Institution ID
    * @param i_id_rep_section                  Rep_section ID
    * @param i_id_rep_layout                   Layout ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/03
    ********************************************************************************************/
    FUNCTION set_rep_layout_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_software    IN software.id_software%TYPE,
        i_id_reports     IN reports.id_reports%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_rep_section IN rep_section.id_rep_section%TYPE,
        i_id_rep_layout  IN rep_layout.id_rep_layout%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_REP_LAYOUT_SECTION';
    
        l_market market.id_market%TYPE;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section ||
                   ' i_id_rep_layout:' || i_id_rep_layout;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF i_id_rep_layout IS NOT NULL
        THEN
        
            MERGE INTO rep_layout_rel rlr
            USING (SELECT i_id_software    id_software,
                          i_id_reports     id_reports,
                          i_id_institution id_institution,
                          i_id_rep_section id_rep_section,
                          i_id_rep_layout  id_rep_layout
                     FROM dual) new_v
            ON (rlr.id_software = new_v.id_software AND rlr.id_reports = new_v.id_reports AND rlr.id_institution = new_v.id_institution AND rlr.id_rep_section = new_v.id_rep_section)
            
            WHEN MATCHED THEN
                UPDATE
                   SET rlr.id_rep_layout = new_v.id_rep_layout
                 WHERE rlr.id_rep_layout <> new_v.id_rep_layout
                
            
            WHEN NOT MATCHED THEN
                INSERT
                    (rlr.id_software,
                     rlr.id_reports,
                     rlr.id_institution,
                     rlr.id_rep_section,
                     rlr.id_rep_layout,
                     rlr.id_market)
                VALUES
                    (new_v.id_software,
                     new_v.id_reports,
                     new_v.id_institution,
                     new_v.id_rep_section,
                     new_v.id_rep_layout,
                     l_market);
        
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
        
            RETURN FALSE;
    END set_rep_layout_section;

    /********************************************************************************************
    * Updates the selected Rules for a report section.
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports ID
    * @param i_id_institution                  Institution ID
    * @param i_id_rep_section                  Rep_section ID
    * @param i_id_rep_rule                     Table with list of Rules for a report section
    * @param i_flg_active                      Table with selected values of Rules for a report section
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/03
    ********************************************************************************************/
    FUNCTION set_rep_rule_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_software    IN software.id_software%TYPE,
        i_id_reports     IN reports.id_reports%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_rep_section IN rep_section.id_rep_section%TYPE,
        i_id_rep_rule    IN table_varchar,
        i_flg_active     IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_REP_RULE_SECTION';
    
        l_market market.id_market%TYPE;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section ||
                   ' i_id_rep_rule.count:' || i_id_rep_rule.count || ' i_flg_active.count:' || i_flg_active.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF i_id_rep_rule.count > 0
        THEN
            FOR i IN i_id_rep_rule.first .. i_id_rep_rule.last
            LOOP
                g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                           i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' ||
                           i_id_rep_section || ' i_id_rep_rule.count(' || i || '):' || i_id_rep_rule(i) ||
                           ' i_flg_active.count(' || i || '):' || i_flg_active(i);
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => l_function_name);
            
                MERGE INTO rep_rule_rel rlr
                USING (SELECT i_id_software id_software,
                              i_id_reports id_reports,
                              i_id_institution id_institution,
                              i_id_rep_section id_rep_section,
                              i_id_rep_rule(i) id_rep_rule,
                              decode(i_flg_active(i),
                                     pk_alert_constant.g_active,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no) flg_active
                         FROM dual) new_v
                ON (rlr.id_software = new_v.id_software AND rlr.id_reports = new_v.id_reports AND rlr.id_institution = new_v.id_institution AND rlr.id_rep_section = new_v.id_rep_section AND rlr.id_rep_rule = new_v.id_rep_rule)
                
                WHEN MATCHED THEN
                    UPDATE
                       SET rlr.flg_active = new_v.flg_active
                     WHERE rlr.flg_active <> new_v.flg_active
                    
                
                WHEN NOT MATCHED THEN
                    INSERT
                        (rlr.id_software,
                         rlr.id_reports,
                         rlr.id_institution,
                         rlr.id_rep_section,
                         rlr.id_rep_rule,
                         rlr.flg_active,
                         rlr.id_market)
                    VALUES
                        (new_v.id_software,
                         new_v.id_reports,
                         new_v.id_institution,
                         new_v.id_rep_section,
                         new_v.id_rep_rule,
                         new_v.flg_active,
                         l_market);
            
            END LOOP;
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
        
            RETURN FALSE;
    END set_rep_rule_section;

    /********************************************************************************************
    * Updates the selected UX, Rules and Layout for a report section.
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports ID
    * @param i_id_institution                  Institution ID
    * @param i_id_rep_section                  Rep_section ID
    * @param i_id_rep_layout                   Layout ID
    * @param i_rep_unique_identifier           Table with list of Ux for a report section
    * @param i_ux_flg_active                   Table with selected values of Ux for a report section
    * @param i_id_rep_rule                     Table with list of Rules for a report section
    * @param i_rule_flg_active                 Table with selected values of Rules for a report section
    
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/07
    ********************************************************************************************/
    FUNCTION set_rep_section_config
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_software           IN software.id_software%TYPE,
        i_id_reports            IN reports.id_reports%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_rep_section        IN rep_section.id_rep_section%TYPE,
        i_id_rep_layout         IN rep_layout.id_rep_layout%TYPE,
        i_rep_unique_identifier IN table_varchar,
        i_ux_flg_active         IN table_varchar,
        i_id_rep_rule           IN table_varchar,
        i_rule_flg_active       IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_REP_SECTION_CONFIG';
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                   i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section:' || i_id_rep_section ||
                   ' i_id_rep_layout:' || i_id_rep_layout || ' i_rep_unique_identifier.count:' ||
                   i_rep_unique_identifier.count || ' i_ux_flg_active.count:' || i_ux_flg_active.count ||
                   ' i_id_rep_rule.count:' || i_id_rep_rule.count || ' i_rule_flg_active.count:' ||
                   i_rule_flg_active.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL SET_REP_UX_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT set_rep_ux_section(i_lang                  => i_lang,
                                  i_prof                  => i_prof,
                                  i_id_software           => i_id_software,
                                  i_id_reports            => i_id_reports,
                                  i_id_institution        => i_id_institution,
                                  i_rep_unique_identifier => i_rep_unique_identifier,
                                  i_flg_active            => i_ux_flg_active,
                                  o_error                 => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL SET_REP_RULE_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT set_rep_rule_section(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_id_software    => i_id_software,
                                    i_id_reports     => i_id_reports,
                                    i_id_institution => i_id_institution,
                                    i_id_rep_section => i_id_rep_section,
                                    i_id_rep_rule    => i_id_rep_rule,
                                    i_flg_active     => i_rule_flg_active,
                                    o_error          => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL SET_REP_LAYOUT_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT set_rep_layout_section(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_software    => i_id_software,
                                      i_id_reports     => i_id_reports,
                                      i_id_institution => i_id_institution,
                                      i_id_rep_section => i_id_rep_section,
                                      i_id_rep_layout  => i_id_rep_layout,
                                      o_error          => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        -- C O M M I T
        COMMIT;
        -- /C O M M I T
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
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
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_rep_section_config;
    /********************************************************************************************
    * Get the list of specific parameterized messages of confidentiality for this institution
    *
    * @param i_lang                    Preferred language ID for this professional 
    * @param i_id_institution          Institution ID
    * @param o_rep_disclosure          Predifined messages of confidentiality
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          Mauro Sousa
    * @version                         2.6.1
    * @since                           2011/02/04
    **********************************************************************************************/
    FUNCTION get_rep_inst_disclosure
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_rep_disclosure  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count         NUMBER;
        l_function_name VARCHAR2(30) := 'GET_REP_INST_DISCLOSURE';
    
    BEGIN
    
        g_error := 'COUNT DISCLOSURE FOR INSTITUTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        --                
        SELECT COUNT(rid.id_rep_inst_disclosure)
          INTO l_count
          FROM rep_inst_disclosure rid
         WHERE rid.id_institution = i_id_institutiton
           AND rid.flg_available = pk_alert_constant.g_yes;
    
        IF l_count != 0
        THEN
            g_error := 'OPEN REP_DISCLOSURE FOR INSTITUTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            OPEN o_rep_disclosure FOR
                SELECT rid.desc_disclosure rep_general
                  FROM rep_inst_disclosure rid
                 WHERE rid.id_institution = i_id_institutiton
                   AND rid.flg_available = pk_alert_constant.g_yes;
        ELSE
            g_error := 'OPEN REP_DISCLOSURE FOR INSTITUTION = 0';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            OPEN o_rep_disclosure FOR
                SELECT pk_message.get_message(i_lang, 'ADMINISTRATOR_T862') rep_general
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_rep_disclosure);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_rep_inst_disclosure;
    /********************************************************************************************
    * Edit existing messages of confidentiality for this institution
    *
    * @param i_lang                    Preferred language ID for this professional 
    * @param i_id_institution          Institution ID
    * @param o_rep_disclosure          Predifined messages of confidentiality
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          Mauro Sousa
    * @version                         2.6.1
    * @since                           2011/02/04
    **********************************************************************************************/
    FUNCTION set_rep_inst_disclosure
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        --
        i_desc_discl IN rep_inst_disclosure.desc_disclosure%TYPE,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count         NUMBER;
        l_function_name VARCHAR2(30) := 'SET_REP_INST_DISCLOSURE';
    
    BEGIN
        g_error := 'COUNT DISCLOSURE FOR INSTITUTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        --                
        SELECT COUNT(rid.id_rep_inst_disclosure)
          INTO l_count
          FROM rep_inst_disclosure rid
         WHERE rid.id_institution = i_id_institution
           AND rid.flg_available = pk_alert_constant.g_yes;
    
        IF l_count = 0
        THEN
            INSERT INTO rep_inst_disclosure
                (id_rep_inst_disclosure, desc_disclosure, id_institution, flg_available)
            VALUES
                (seq_rep_inst_disclosure.nextval, i_desc_discl, i_id_institution, pk_alert_constant.get_yes);
        
        ELSE
            UPDATE rep_inst_disclosure rid
               SET rid.desc_disclosure = i_desc_discl
             WHERE rid.id_institution = i_id_institution
               AND rid.flg_available = pk_alert_constant.get_yes;
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_function_name,
                                                     o_error);
        
    END set_rep_inst_disclosure;

    /********************************************************************************************
    * Create REP_UNIQUE_IDENTIFIER
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional
    * @param i_id_section                      Section ID
    * @param i_rep_unique_identifier           REP_UNIQUE_IDENTIFIER list to create
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Tiago Lourenço
    * @version                                 2.6.1.8.4
    * @since                                   15-June-2012
    ********************************************************************************************/
    FUNCTION set_rep_unique_identifier
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_section            IN rep_section.id_rep_section%TYPE,
        i_rep_unique_identifier IN table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30 CHAR);
    BEGIN
        l_function_name := 'SET_REP_UNIQUE_IDENTIFIER';
    
        MERGE INTO rep_unique_identifier rui
        USING (SELECT DISTINCT column_value, i_id_section id_rep_section
                 FROM TABLE(i_rep_unique_identifier)) t
        ON (rui.rep_unique_identifier = t.column_value AND rui.id_rep_section = t.id_rep_section)
        WHEN NOT MATCHED THEN
            INSERT
                (rui.rep_unique_identifier, rui.id_rep_section)
            VALUES
                (t.column_value, t.id_rep_section);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     l_function_name,
                                                     o_error);
    END set_rep_unique_identifier;

    /********************************************************************************************
    * Get a list of reports available and selected by profile / adapted to report config
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID
    * @param i_id_software                     Software ID
    * @param i_id_rep_profile_template         Reports Profile ID
    * @param o_rep_list                        Reports Profile List cursor
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Rui Gomes
    * @version                                 0.1
    * @since                                   2011/04/15
    *
    * @author     João Reis
    * @version    2.6.1.2       2011/07/25
    * @change     Add default profile logic (rep_profile_template.id_profile_template = 0)
    ********************************************************************************************/
    FUNCTION get_reps_soft
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_software             IN software.id_software%TYPE,
        i_id_rep_profile_template IN rep_profile_template.id_rep_profile_template%TYPE,
        o_rep_list                OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET_INSTITUTION_MARKET with institution: ' || i_id_institution;
        pk_alertlog.log_debug(g_error);
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution);
        pk_alertlog.log_info('pk_backoffice_print_tool.get_reps_soft idMarket returned:' || l_id_market);
    
        g_error := 'GET PROFILE TEMPLATE REPORT CURSOR';
    
        OPEN o_rep_list FOR
            SELECT rptd.id_reports id,
                   nvl(pk_translation.get_translation(i_lang, r.code_reports),
                       pk_translation.get_translation(i_lang, r.code_reports_title)) ||
                   decode(i_id_software,
                          pk_alert_constant.g_soft_adt,
                          get_rep_epis_type_desc(i_lang, i_id_institution, rptd.id_reports),
                          NULL) name,
                   rptd.flg_available flg_status,
                   nvl(rptd.flg_disclosure, pk_alert_constant.g_no) flg_disclosure,
                   -- 19/04/2011 RMGM: add report area
                   rptd.flg_area_report
              FROM rep_profile_template_det rptd
              JOIN reports r
                ON rptd.id_reports = r.id_reports
             INNER JOIN rep_report_mkt rpm
                ON rpm.id_reports = r.id_reports
             WHERE
            -- 25-07-2011 JR: added default profile concept. This means that reports configured for id_rep_profile_template = 0 should also
            -- be included
             rptd.id_rep_profile_template IN (i_id_rep_profile_template, 0)
             AND rptd.id_rep_profile_template_det NOT IN
             (SELECT t.id_rep_profile_template_det
                FROM rep_profile_template_det t
               WHERE t.id_rep_profile_template = 0
                 AND t.id_reports IN (SELECT t2.id_reports
                                        FROM rep_profile_template_det t2
                                       WHERE t2.id_rep_profile_template = i_id_rep_profile_template))
            -- 25-07-2011 JR: the reports which are configured for id_institution = 0 should also be included because are common to
            -- all institutions.
            /*AND rptd.id_institution = decode((SELECT 1
              FROM rep_profile_template_det rpt
             WHERE rpt.id_rep_profile_template = rptd.id_rep_profile_template
               AND rpt.id_reports = rptd.id_reports
               AND rpt.flg_area_report = rptd.flg_area_report
               AND rpt.id_institution = i_id_institution),
            1,
            i_id_institution,
            0)*/
            -- 19/04/2011 RMGM: add new areas
             AND rptd.flg_area_report IN ('R', 'E', 'CR', 'C')
             AND rptd.flg_available IN (pk_alert_constant.g_yes, g_flg_unavailable)
             AND r.flg_available = pk_alert_constant.g_yes
             AND nvl(pk_translation.get_translation(i_lang, r.code_reports_title),
                 pk_translation.get_translation(i_lang, r.code_reports)) IS NOT NULL
             AND rptd.id_reports IN (SELECT rptd.id_reports
                                   FROM rep_profile_template     rpt,
                                        rep_prof_templ_access    rpta,
                                        profile_template         pt,
                                        profile_template_market  ptm,
                                        rep_profile_template_det rptd
                                  WHERE rpt.id_rep_profile_template = rpta.id_rep_profile_template
                                    AND rpta.id_profile_template = ptm.id_profile_template
                                    AND pt.id_software = i_id_software
                                    AND ptm.id_market IN (0, l_id_market)
                                    AND pt.flg_available = pk_alert_constant.g_yes
                                    AND rptd.id_rep_profile_template = rpt.id_rep_profile_template)
             AND rpm.id_market = decode((SELECT COUNT(*) num
                                      FROM rep_report_mkt rrm2
                                     WHERE rrm2.id_market = l_id_market
                                       AND rrm2.id_reports = r.id_reports),
                                    0,
                                    pk_alert_constant.g_id_market_all,
                                    l_id_market)
             ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_rep_list);
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_PRINT_TOOL',
                                   'GET_REPS_SOFT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END;
        
    END get_reps_soft;

    FUNCTION get_rep_epis_type_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_id_reports  IN reports.id_reports%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count          NUMBER := 0;
        l_num_rec        NUMBER := 0;
        l_epis_type_desc translation.desc_lang_1%TYPE;
        l_soft_desc      translation.desc_lang_1%TYPE;
        l_ret            VARCHAR2(1000) := NULL;
    
        CURSOR c IS
            SELECT *
              FROM (SELECT pk_translation.get_translation(i_lang, et.code_epis_type) epis_type_desc,
                           pk_utils.get_software_name(i_lang,
                                                      (pk_episode.get_soft_by_epis_type(et.id_epis_type, i_institution))) soft_desc
                      FROM epis_type_reports etr
                      JOIN epis_type et
                        ON et.id_epis_type = etr.id_epis_type
                     WHERE etr.id_reports = i_id_reports
                       AND etr.id_epis_type NOT IN (-1, 0)) t
             WHERE t.epis_type_desc IS NOT NULL;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_type_reports etr
          JOIN epis_type et
            ON et.id_epis_type = etr.id_epis_type
         WHERE etr.id_reports = i_id_reports
           AND etr.id_epis_type NOT IN (-1, 0)
           AND pk_translation.get_translation(i_lang, et.code_epis_type) IS NOT NULL;
    
        IF l_count = 0
        THEN
            RETURN NULL;
        ELSE
            OPEN c;
            l_ret := l_ret || g_open_parenthesis;
            LOOP
                FETCH c
                    INTO l_epis_type_desc, l_soft_desc;
                EXIT WHEN c%NOTFOUND;
            
                l_num_rec := l_num_rec + 1;
                IF l_num_rec > 1
                THEN
                    l_ret := l_ret || g_dash;
                END IF;
            
                l_ret := l_ret || l_epis_type_desc || g_flg_sep || l_soft_desc;
            
            END LOOP;
            l_ret := l_ret || g_close_parenthesis;
            CLOSE c;
            RETURN l_ret;
        END IF;
    END get_rep_epis_type_desc;

BEGIN

    g_flg_unavailable := 'U';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_backoffice_print_tool;
/
