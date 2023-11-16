/*-- Last Change Revision: $Rev: 2027624 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_reports IS

    --
    -- SUBTYPES
    -- 

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(4000 CHAR);

    --
    -- CONSTANTS
    -- 

    -- Package info
    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    -- Default values
    c_default_config CONSTANT PLS_INTEGER := 0;
    g_undefined      CONSTANT VARCHAR2(1) := 'U';
    g_error VARCHAR2(4000);

    --
    -- FUNCTIONS
    -- 

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
        i_id_rep_section      IN table_number,
        o_rep_ux_section_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_UX_SECTION';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        l_dbg_msg := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                     i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section.count:' ||
                     i_id_rep_section.count;
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dbg_msg := 'GET REPORT SECTION UX CURSOR';
        OPEN o_rep_ux_section_list FOR
            SELECT rui.rep_unique_identifier,
                   nvl(ux.flg_active, pk_alert_constant.g_active) flg_active,
                   rui.id_rep_section
              FROM rep_unique_identifier rui
              LEFT JOIN (SELECT rx.rep_unique_identifier,
                                decode(rx.flg_exclude,
                                       pk_alert_constant.g_yes,
                                       pk_alert_constant.g_inactive,
                                       pk_alert_constant.g_no,
                                       pk_alert_constant.g_active) flg_active
                           FROM (SELECT rank() over(PARTITION BY ruie.rep_unique_identifier ORDER BY ruie.id_institution DESC, ruie.id_market DESC, ruie.id_reports DESC,CASE
                                            WHEN ruie.flg_report_type =
                                                 g_undefined THEN
                                             0
                                            ELSE
                                             1
                                        END DESC, ruie.id_software DESC) rank,
                                        ruie.flg_exclude,
                                        ruie.rep_unique_identifier
                                   FROM rep_unique_identifier_excep ruie
                                  WHERE ruie.id_software IN (0, i_id_software)
                                    AND (ruie.flg_report_type =
                                        (SELECT r.flg_report_type
                                            FROM reports r
                                           WHERE r.id_reports = i_id_reports) OR ruie.flg_report_type = g_undefined)
                                    AND ruie.id_reports IN (0, i_id_reports)
                                    AND ruie.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                                    AND ruie.id_institution IN (0, i_id_institution)) rx
                          WHERE rx.rank = 1) ux
                ON ux.rep_unique_identifier = rui.rep_unique_identifier
             WHERE rui.id_rep_section IN (SELECT t.column_value /*+opt_estimate(table,t,scale_rows=0.0000000001)*/
                                            FROM TABLE(i_id_rep_section) t)
             ORDER BY rui.id_rep_section;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_rep_ux_section_list);
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_rep_ux_section_list);
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
        i_id_rep_section         IN table_number,
        o_rep_rules_section_list OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_RULES_SECTION';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        l_dbg_msg := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                     i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section.count:' ||
                     i_id_rep_section.count;
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dbg_msg := 'GET RULES REPORT CURSOR';
        OPEN o_rep_rules_section_list FOR
            SELECT pk_translation.get_translation(i_lang, rr.code_rep_rule) rule_desc,
                   rr.id_rep_rule,
                   decode(rl.flg_active,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_active,
                          pk_alert_constant.g_inactive) flg_active,
                   rl.id_rep_section
              FROM (SELECT rrs.id_rep_rule, rul.flg_active, rrs.id_rep_section
                      FROM rep_rule_section rrs
                      LEFT JOIN (SELECT rel.id_rep_rule, rel.flg_active, rel.id_rep_section
                                  FROM (SELECT rank() over(PARTITION BY rrr.id_rep_section, rrr.id_rep_rule ORDER BY rrr.id_institution DESC, rrr.id_market DESC, rrr.id_reports DESC,CASE
                                                   WHEN rrr.flg_report_type =
                                                        g_undefined THEN
                                                    0
                                                   ELSE
                                                    1
                                               END DESC, rrr.id_software DESC) rank,
                                               rrr.flg_active,
                                               rrr.id_rep_rule,
                                               rrr.id_rep_section
                                          FROM rep_rule_rel rrr
                                         WHERE rrr.id_software IN (0, i_id_software)
                                           AND rrr.id_reports IN (0, i_id_reports)
                                           AND (rrr.flg_report_type =
                                               (SELECT r.flg_report_type
                                                   FROM reports r
                                                  WHERE r.id_reports = i_id_reports) OR
                                               rrr.flg_report_type = g_undefined)
                                           AND rrr.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                                           AND rrr.id_institution IN (0, i_id_institution)
                                           AND rrr.id_rep_section IN
                                               (SELECT t1.column_value /*+opt_estimate(table,t1,scale_rows=0.0000000001)*/
                                                  FROM TABLE(i_id_rep_section) t1)) rel
                                 WHERE rel.rank = 1) rul
                        ON rul.id_rep_rule = rrs.id_rep_rule
                       AND rul.id_rep_section = rrs.id_rep_section
                     WHERE rrs.id_rep_section IN (SELECT t2.column_value /*+opt_estimate(table,t2,scale_rows=0.0000000001)*/
                                                    FROM TABLE(i_id_rep_section) t2)) rl
             INNER JOIN rep_rule rr
                ON rl.id_rep_rule = rr.id_rep_rule
             ORDER BY rl.id_rep_section, rule_desc ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_rep_rules_section_list);
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_rep_rules_section_list);
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
        i_id_rep_section          IN table_number,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_LAYOUT_SECTION';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        l_dbg_msg := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                     i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section.count:' ||
                     i_id_rep_section.count;
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dbg_msg := 'GET LAYOUT REPORT CURSOR';
        OPEN o_rep_layout_section_list FOR
            SELECT pk_translation.get_translation(i_lang, rl.code_rep_layout) layout_desc,
                   rl.id_rep_layout,
                   l.flg_active,
                   l.layout_sample,
                   l.id_rep_section
              FROM (SELECT rls.id_rep_layout,
                           rls.id_rep_section,
                           rls.layout_sample,
                           decode(lyt.flg_active,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_active,
                                  pk_alert_constant.g_inactive) flg_active
                      FROM rep_layout_section rls
                      LEFT JOIN (SELECT rly.id_rep_layout, rly.id_rep_section, pk_alert_constant.g_yes flg_active
                                  FROM (SELECT rank() over(PARTITION BY rlr.id_rep_section ORDER BY rlr.id_institution DESC, rlr.id_market DESC, rlr.id_reports DESC,CASE
                                                   WHEN rlr.flg_report_type =
                                                        g_undefined THEN
                                                    0
                                                   ELSE
                                                    1
                                               END DESC, rlr.id_software DESC) rank,
                                               rlr.id_rep_layout,
                                               rlr.id_rep_section
                                          FROM rep_layout_rel rlr
                                         WHERE rlr.id_software IN (0, i_id_software)
                                           AND rlr.id_reports IN (0, i_id_reports)
                                           AND (rlr.flg_report_type =
                                               (SELECT r.flg_report_type
                                                   FROM reports r
                                                  WHERE r.id_reports = i_id_reports) OR
                                               rlr.flg_report_type = g_undefined)
                                           AND rlr.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                                           AND rlr.id_institution IN (0, i_id_institution)
                                           AND rlr.id_rep_section IN
                                               (SELECT t1.column_value /*+opt_estimate(table,t1,scale_rows=0.0000000001)*/
                                                  FROM TABLE(i_id_rep_section) t1)) rly
                                 WHERE rly.rank = 1) lyt
                        ON lyt.id_rep_layout = rls.id_rep_layout
                       AND lyt.id_rep_section = rls.id_rep_section
                     WHERE rls.id_rep_section IN (SELECT t2.column_value /*+opt_estimate(table,t2,scale_rows=0.0000000001)*/
                                                    FROM TABLE(i_id_rep_section) t2)) l
             INNER JOIN rep_layout rl
                ON l.id_rep_layout = rl.id_rep_layout
             ORDER BY l.id_rep_section, layout_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_rep_layout_section_list);
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_rep_layout_section_list);
            RETURN FALSE;
        
    END get_rep_layout_section;

    /********************************************************************************************
    * Get list of UX, rules and layout for a report.
    *
    * @param i_lang                            Prefered language ID
    * @param i_prof                            Professional, software and institution ids
    * @param i_id_software                     Software ID
    * @param i_id_reports                      Reports ID
    * @param i_id_institution                  Institution ID
    * @param o_rep_layout_list                 Report Layout List cursor
    * @param o_rep_unique_identifier_list      Report UX Sections List cursor
    * @param o_rep_rule_list                   Report Rules Sections List cursor
    
    
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Jorge Canossa
    * @version                                 0.1
    * @since                                   2010/06/12
    ********************************************************************************************/
    FUNCTION get_rep_section_config
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_software             IN software.id_software%TYPE,
        i_id_reports              IN reports.id_reports%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_rep_section          IN table_number,
        o_rep_layout_section_list OUT pk_types.cursor_type,
        o_rep_ux_section_list     OUT pk_types.cursor_type,
        o_rep_rules_section_list  OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_SECTION_CONFIG';
        l_dbg_msg debug_msg;
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
        l_dbg_msg := 'i_lang:' || i_lang || ' i_id_institution:' || i_id_institution || ' i_id_software:' ||
                     i_id_software || ' i_id_reports:' || i_id_reports || ' i_id_rep_section.count:' ||
                     i_id_rep_section.count;
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        l_dbg_msg := 'CALL GET_REP_UX_SECTION';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_reports.get_rep_ux_section(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_institution      => i_id_institution,
                                             i_id_software         => i_id_software,
                                             i_id_reports          => i_id_reports,
                                             i_id_rep_section      => i_id_rep_section,
                                             o_rep_ux_section_list => o_rep_ux_section_list,
                                             o_error               => l_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'CALL GET_REP_RULES_SECTION';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_reports.get_rep_rules_section(i_lang                   => i_lang,
                                                i_prof                   => i_prof,
                                                i_id_institution         => i_id_institution,
                                                i_id_software            => i_id_software,
                                                i_id_reports             => i_id_reports,
                                                i_id_rep_section         => i_id_rep_section,
                                                o_rep_rules_section_list => o_rep_rules_section_list,
                                                o_error                  => l_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'CALL GET_REP_LAYOUT_SECTION';
        pk_alertlog.log_debug(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF NOT pk_reports.get_rep_layout_section(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_id_institution          => i_id_institution,
                                                 i_id_software             => i_id_software,
                                                 i_id_reports              => i_id_reports,
                                                 i_id_rep_section          => i_id_rep_section,
                                                 o_rep_layout_section_list => o_rep_layout_section_list,
                                                 o_error                   => l_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error.ora_sqlcode,
                                              i_sqlerrm  => l_error.ora_sqlerrm,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => l_error);
            pk_types.open_my_cursor(i_cursor => o_rep_layout_section_list);
            pk_types.open_my_cursor(i_cursor => o_rep_ux_section_list);
            pk_types.open_my_cursor(i_cursor => o_rep_rules_section_list);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_rep_layout_section_list);
            pk_types.open_my_cursor(i_cursor => o_rep_ux_section_list);
            pk_types.open_my_cursor(i_cursor => o_rep_rules_section_list);
            RETURN FALSE;
        
    END get_rep_section_config;

    /********************************************************************************************
    * Get scope for report sections (episode, patient, visit)
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/05
    ********************************************************************************************/
    FUNCTION get_report_scope
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_report         IN reports.id_reports%TYPE,
        i_id_rep_section IN table_number,
        i_report_type    IN rep_scope_inst_soft_market.flg_report_type%TYPE,
        o_report_scope   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REPORT_SCOPE';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
    BEGIN
        l_dbg_msg := 'get market id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        l_dbg_msg := 'get report scope config';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_report_scope FOR
            SELECT r.id_reports, r.id_rep_section, r.flg_scope
              FROM (SELECT /*+opt_Estimate(table t rows=1)*/
                     rs.id_reports,
                     t.column_value AS id_rep_section,
                     rs.flg_scope,
                     rank() over(PARTITION BY t.column_value --
                      ORDER BY --
                      rs.id_rep_section DESC, --
                      rs.id_institution DESC, --
                      rs.id_market DESC, --
                      rs.id_reports DESC, --
                     CASE
                         WHEN rs.flg_report_type = g_undefined THEN
                          0
                         ELSE
                          1
                     END DESC, --
                      rs.id_software DESC) AS rnk
                      FROM TABLE(i_id_rep_section) t
                     INNER JOIN rep_scope_inst_soft_market rs
                        ON rs.id_rep_section IN (c_default_config, t.column_value)
                     WHERE rs.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND rs.id_market IN (pk_alert_constant.g_id_market_all, l_market)
                       AND rs.id_reports IN (c_default_config, i_report)
                       AND (rs.flg_report_type = i_report_type OR rs.flg_report_type = g_undefined)
                       AND rs.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) r
             WHERE r.rnk = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_report_scope);
            RETURN FALSE;
        
    END get_report_scope;

    /********************************************************************************************
    * Crearte configuration for report scope (episode, patient, visit)
    *
    * @author                                  Rui Duarte
    * @version                                 0.1
    * @since                                   2010/11/05
    ********************************************************************************************/
    FUNCTION insert_into_report_scope
    (
        i_lang           IN language.id_language%TYPE,
        i_report         IN reports.id_reports%TYPE,
        i_section        IN rep_section.id_rep_section%TYPE,
        i_report_type    IN rep_scope_inst_soft_market.flg_report_type%TYPE,
        i_report_scope   IN rep_scope_inst_soft_market.flg_scope%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_market      IN market.id_market%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'INSERT_INTO_REPORT_SCOPE';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'INSERT_INTO_REPORT_SCOPE';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        MERGE INTO rep_scope_inst_soft_market rs_ism
        USING (SELECT i_report         id_reports,
                      i_section        id_rep_section,
                      i_report_type    flg_type,
                      i_id_institution id_institution,
                      i_id_software    id_software,
                      i_id_market      id_market
                 FROM dual) args
        ON (rs_ism.id_reports = args.id_reports AND rs_ism.id_rep_section = args.id_rep_section AND rs_ism.id_institution = args.id_institution AND rs_ism.id_software = args.id_software AND rs_ism.id_market = args.id_market)
        WHEN MATCHED THEN
            UPDATE
               SET rs_ism.flg_scope = i_report_scope
        WHEN NOT MATCHED THEN
            INSERT
                (id_rep_scope_ism,
                 id_reports,
                 id_rep_section,
                 flg_report_type,
                 flg_scope,
                 id_institution,
                 id_software,
                 id_market)
            VALUES
                (sec_rep_scope_ism.nextval,
                 args.id_reports,
                 args.id_rep_section,
                 args.flg_type,
                 i_report_scope,
                 args.id_institution,
                 args.id_software,
                 args.id_market);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END insert_into_report_scope;

    /********************************************************************************************
    * Get metadata for an array of rep_section. Called by Java.
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/02/15
    ********************************************************************************************/
    FUNCTION get_rep_section_metadata
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_report         IN reports.id_reports%TYPE,
        i_id_rep_section IN table_number,
        o_rep_metadata   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_REP_SECTION_METADATA';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
    BEGIN
        l_dbg_msg := 'get market id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        l_dbg_msg := 'get rep_section metadata';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        OPEN o_rep_metadata FOR
            SELECT r.id_rep_section_det, r.id_reports, r.id_rep_section, r.rank, r.iterable
              FROM (SELECT /*+opt_Estimate(table t rows=1)*/
                     rsd.id_rep_section_det,
                     rsd.id_reports,
                     rsd.rank,
                     rs.iterable,
                     t.column_value AS id_rep_section,
                     rank() over(PARTITION BY t.column_value --
                     ORDER BY --
                     rsd.id_rep_section DESC, --
                     rsd.id_institution DESC, --
                     rsd.id_market DESC, --
                     rsd.id_reports DESC, --
                     rsd.id_software DESC) AS rnk
                      FROM TABLE(i_id_rep_section) t
                     INNER JOIN rep_section_det rsd
                        ON rsd.id_rep_section IN (c_default_config, t.column_value)
                     INNER JOIN rep_section rs
                        ON rsd.id_rep_section = rs.id_rep_section
                     WHERE rsd.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                       AND (rsd.id_market IN (pk_alert_constant.g_id_market_all, l_market) OR rsd.id_market IS NULL)
                       AND rsd.id_reports IN (c_default_config, i_report)
                       AND rsd.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)) r
             WHERE r.rnk = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_rep_metadata);
            RETURN FALSE;
        
    END get_rep_section_metadata;

    /********************************************************************************************
    * Set report as assynchronous and generate alert accordingly.
    *
    * @param i_lang                Language Id
    * @param i_prof                ID professional that generates the report
    * @param i_id_episode          ID episode of Record to insert
    * @param i_id_epis_report      ID of the record related do the espisode and report (table EPIS_REPORT)
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Pedro Maia
    * @version                     2.5.1
    * @since                       2010/12/16
    ********************************************************************************************/
    FUNCTION set_alert_report_asynchronous
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_episode     IN epis_report.id_episode%TYPE,
        i_id_epis_report IN epis_report.id_epis_report%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_rep_message     VARCHAR2(4000);
    
        CURSOR c_alert_assync IS
            SELECT s.id_sys_alert
              FROM sys_alert s
             WHERE s.intern_name = 'REPORT_GENERATED';
    
        CURSOR c_epis_patient IS
            SELECT e.id_visit, e.id_patient
              FROM episode e
             WHERE e.id_episode = i_id_episode;
    BEGIN
    
        OPEN c_alert_assync;
        FETCH c_alert_assync
            INTO l_alert_event_row.id_sys_alert;
    
        CLOSE c_alert_assync;
    
        -- Update report as assynchronous
        g_error := 'UPDATE REPORT TO ASSYNCHRONOUS ON EPIS_REPORT';
        UPDATE epis_report ep
           SET ep.flg_background = g_yes
         WHERE ep.id_epis_report = i_id_epis_report
           AND ep.id_episode = i_id_episode
           AND ep.id_professional = i_prof.id;
    
        l_rep_message := pk_message.get_message(i_lang, 'REPORT_BACKGROUND_M001');
    
        l_alert_event_row.id_sys_alert        := l_alert_event_row.id_sys_alert;
        l_alert_event_row.id_software         := i_prof.software;
        l_alert_event_row.id_institution      := i_prof.institution;
        l_alert_event_row.id_episode          := i_id_episode;
        l_alert_event_row.id_record           := i_id_epis_report;
        l_alert_event_row.dt_record           := current_timestamp;
        l_alert_event_row.id_professional     := i_prof.id;
        l_alert_event_row.replace1            := l_rep_message;
        l_alert_event_row.id_room             := NULL;
        l_alert_event_row.id_clinical_service := NULL;
    
        OPEN c_epis_patient;
        FETCH c_epis_patient
            INTO l_alert_event_row.id_visit, l_alert_event_row.id_patient;
        CLOSE c_epis_patient;
    
        RETURN pk_alerts.insert_sys_alert_event(i_lang, i_prof, l_alert_event_row, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_ALERT_REPORT_ASSYNCHRONOUS',
                                              o_error);
            RETURN FALSE;
    END set_alert_report_asynchronous;

    /********************************************************************************************
    * Get the id_context to be printed on each report. Called by Java.
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2014/06/06
    ********************************************************************************************/
    FUNCTION get_order_by_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_context         IN table_number,
        i_task_type       IN table_number,
        o_order_by_report OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_ORDER_BY_REPORT';
        l_dbg_msg debug_msg;
    
        l_market market.id_market%TYPE;
    
        l_temp_id_reports table_number := table_number();
        l_temp_id_context table_number := table_number();
    
        l_id_reports reports.id_reports%TYPE;
    
    BEGIN
        l_dbg_msg := 'get market id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        l_dbg_msg := 'get_order_by_report';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
        IF i_context.count > 0
        THEN
            /* validate of there is a specific id_report associated with a element of the i_context list */
            FOR j IN 1 .. i_context.count
            LOOP
                l_id_reports := NULL;
                BEGIN
                    SELECT rrois.id_reports
                      INTO l_id_reports
                      FROM rep_report_order_ins_sft rrois, reports r
                     WHERE rrois.id_context = i_context(j)
                       AND rrois.id_institution =
                           decode((SELECT COUNT(*) num
                                    FROM rep_report_order_ins_sft rrois2
                                   WHERE rrois2.id_context = i_context(j)
                                     AND rrois2.id_institution = i_prof.institution
                                     AND rrois2.id_market IN (l_market, pk_alert_constant.g_id_market_all)
                                     AND rrois2.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                     AND rrois2.id_reports = r.id_reports),
                                  0,
                                  pk_alert_constant.g_inst_all,
                                  i_prof.institution)
                       AND rrois.id_market =
                           decode((SELECT COUNT(*) num
                                    FROM rep_report_order_ins_sft rrois2
                                   WHERE rrois2.id_context = i_context(j)
                                     AND rrois2.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                     AND rrois2.id_market = l_market
                                     AND rrois2.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                                     AND rrois2.id_reports = r.id_reports),
                                  0,
                                  pk_alert_constant.g_id_market_all,
                                  l_market)
                       AND rrois.id_software =
                           decode((SELECT COUNT(*) num
                                    FROM rep_report_order_ins_sft rrois2
                                   WHERE rrois2.id_context = i_context(j)
                                     AND rrois2.id_institution IN (i_prof.institution, pk_alert_constant.g_inst_all)
                                     AND rrois2.id_market IN (l_market, pk_alert_constant.g_id_market_all)
                                     AND rrois2.id_software = i_prof.software
                                     AND rrois2.id_reports = r.id_reports),
                                  0,
                                  pk_alert_constant.g_soft_all,
                                  i_prof.software)
                       AND rrois.id_reports = r.id_reports
                       AND rrois.id_task_type_context = i_task_type(j);
                EXCEPTION
                    -- This happens if there are no sections for that institution/software
                    WHEN no_data_found THEN
                        l_id_reports := NULL;
                    WHEN OTHERS THEN
                        l_id_reports := NULL;
                END;
            
                IF l_id_reports IS NULL
                THEN
                    BEGIN
                        SELECT rroms.id_reports
                          INTO l_id_reports
                          FROM rep_report_order_mkt_sft rroms
                         INNER JOIN reports r
                            ON rroms.id_reports = r.id_reports
                         WHERE rroms.id_market IN (l_market, pk_alert_constant.g_id_market_all)
                           AND rroms.id_software IN (i_prof.software, pk_alert_constant.g_soft_all)
                           AND r.id_task_type = i_task_type(j)
                           AND r.flg_available = pk_alert_constant.get_yes;
                    EXCEPTION
                        -- This happens if there are no sections for that institution/software
                        WHEN no_data_found THEN
                            l_id_reports := NULL;
                        WHEN OTHERS THEN
                            l_id_reports := NULL;
                    END;
                END IF;
            
                l_temp_id_reports.extend;
                l_temp_id_context.extend;
                l_temp_id_reports(j) := l_id_reports;
                l_temp_id_context(j) := i_context(j);
                dbms_output.put_line('--------------------------------');
                dbms_output.put_line('id_report=' || l_id_reports || ' -> id_contect=' || i_context(j));
            END LOOP;
        
            -- insert elements to return cursor
            OPEN o_order_by_report FOR
                SELECT ti.column_value id_reports, tn.column_value id_context
                  FROM (SELECT column_value, rownum AS id
                          FROM TABLE(l_temp_id_reports)) ti,
                       (SELECT column_value, rownum AS id
                          FROM TABLE(l_temp_id_context)) tn
                 WHERE tn.id = ti.id;
        
            --ELSE
            /* no i_context sent */
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_order_by_report);
            RETURN FALSE;
        
    END get_order_by_report;

    /********************************************************************************************
    * Insert a id_context of a order to be printed on a specific report. Called by Java.
    * @author                                  Ricardo Pires
    * @version                                 0.1
    * @since                                   2014/08/20
    ********************************************************************************************/
    FUNCTION insert_order_by_report
    (
        i_lang              IN language.id_language%TYPE,
        i_reports           IN reports.id_reports%TYPE,
        i_market            IN market.id_market%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_software          IN software.id_software%TYPE,
        i_context           IN NUMBER,
        i_task_type_context IN task_type.id_task_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'INSERT_ORDER_BY_REPORTS';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'INSERT_ORDER_BY_REPORTS';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => c_package_name, sub_object_name => c_function_name);
    
        MERGE INTO rep_report_order_ins_sft rrois
        USING (SELECT i_reports           id_reports,
                      i_market            id_market,
                      i_institution       id_institution,
                      i_software          id_software,
                      i_context           id_context,
                      i_task_type_context id_task_type_context
                 FROM dual) args
        ON (rrois.id_reports = args.id_reports AND rrois.id_market = args.id_market AND rrois.id_institution = args.id_institution AND rrois.id_software = args.id_software AND rrois.id_context = args.id_context AND rrois.id_task_type_context = args.id_task_type_context)
        WHEN NOT MATCHED THEN
            INSERT
                (id_rep_rpt_order_ins_sft,
                 id_reports,
                 id_market,
                 id_institution,
                 id_software,
                 id_context,
                 id_task_type_context)
            VALUES
                (seq_rep_report_order_ins_sft.nextval,
                 args.id_reports,
                 args.id_market,
                 args.id_institution,
                 args.id_software,
                 args.id_context,
                 args.id_task_type_context);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => c_package_owner,
                                              i_package  => c_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END insert_order_by_report;

--
-- INITIALIZATION SECTION
-- 

BEGIN
    -- Initializes log context
    pk_alertlog.log_init(object_name => c_package_name);

END pk_reports;
/
