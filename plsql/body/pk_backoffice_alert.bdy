/*-- Last Change Revision: $Rev: 1863528 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2018-09-06 15:24:31 +0100 (qui, 06 set 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_alert IS

    -- Author  : RUI.GOMES
    -- Created : 05-11-2012 10:57:45
    -- Purpose : Backoffice logics when managing alerts
    --------------> STATIC VARS
    g_error VARCHAR2(1000 CHAR);
    -- Package info
    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE_ALERT';
    g_function_name VARCHAR(30);
    ---- END of STATIC VARIABLES --<
    -- private methods
    /********************************************************************************************
    * Get Software List by Dept/Service configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_dept                Department ID
    * @param i_service             Service ID   
    * @param o_error               Error
    *
    *
    * @return                      A list o software configured for a specific dept (service)
    *
    * @author                      RMMG
    * @version                     2.6.3.1
    * @since                       2012/12/03
    ********************************************************************************************/
    FUNCTION get_dept_software
    (
        i_lang    IN language.id_language%TYPE,
        i_dept    IN dept.id_dept%TYPE,
        i_service IN department.id_department%TYPE,
        o_error   OUT t_error_out
    ) RETURN table_number IS
        l_result_table table_number := table_number();
    BEGIN
        IF i_service IS NOT NULL
        THEN
            SELECT sd.id_software
              BULK COLLECT
              INTO l_result_table
              FROM software_dept sd
             INNER JOIN dept d
                ON (d.id_dept = sd.id_dept AND d.flg_available = g_flg_available)
             WHERE d.id_dept = (SELECT s.id_dept
                                  FROM department s
                                 WHERE s.id_department = i_service
                                   AND s.flg_available = g_flg_available);
        ELSE
            SELECT sd.id_software
              BULK COLLECT
              INTO l_result_table
              FROM software_dept sd
             INNER JOIN dept d
                ON (d.id_dept = sd.id_dept AND d.flg_available = g_flg_available)
             WHERE d.id_dept = i_dept;
        END IF;
        RETURN l_result_table;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_result_table;
    END get_dept_software;
    -- public methods
    /********************************************************************************************
    * Get Alert List Service configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional array
    * @param i_service             Service ID
    * @param i_dept                Department ID
    * @param o_info                Cursor with alerts configuration information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION get_service_alert_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_service IN department.id_department%TYPE,
        i_dept    IN dept.id_dept%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- system configuration
        l_id_scfg        sys_config.id_sys_config%TYPE := 'NO_ALERTS_BY_DEFAULT';
        l_def_alerts_val sys_config.value%TYPE;
        -- auxiliar cursor
        c_profile_input pk_types.cursor_type;
        -- auxiliar vars  
        l_alerts_clob       CLOB;
        l_functs_clob       CLOB;
        l_cur_dept          department.id_dept%TYPE := NULL;
        l_idx               NUMBER := 1;
        l_service_count     NUMBER := 0;
        l_stg_service_count NUMBER := 0;
        l_inst_profs        NUMBER := 0;
        l_generic_id        NUMBER := 0;
        l_sw_list           table_number := table_number();
        l_market_id         market.id_market%TYPE := NULL;
    
        -- auxiliar arrays
        l_tbl_profile_id   table_number;
        l_tbl_profile_desc table_varchar;
    
        -- final arrays
        tn_software_id  table_number := table_number();
        tv_profile_desc table_varchar := table_varchar();
        tc_alert_clob   table_clob := table_clob();
        tc_funct_clob   table_clob := table_clob();
    
        -- EXCEPTIONS
        l_profile_nok EXCEPTION;
    
    BEGIN
        l_alerts_clob    := '';
        l_functs_clob    := '';
        l_market_id      := pk_utils.get_institution_market(i_lang, i_prof.institution);
        g_error          := 'GET DEFAULT ALERTS SYSTEM CONFIGURATION';
        l_def_alerts_val := pk_sysconfig.get_config(l_id_scfg, i_prof.institution, i_prof.software);
    
        IF (i_service IS NULL AND i_dept IS NOT NULL)
        THEN
            g_error   := 'GET SERVICE/ DEPT SOFTWARE LIST';
            l_sw_list := get_dept_software(i_lang, i_dept, NULL, o_error);
        
            FOR sw IN 1 .. l_sw_list.count
            LOOP
                l_tbl_profile_id   := table_number();
                l_tbl_profile_desc := table_varchar();
                g_error            := 'GET PROFILE DEFAULT CONFIGURATION';
                IF NOT pk_backoffice.get_profile_template_list(i_lang,
                                                               i_prof.institution,
                                                               l_sw_list(sw),
                                                               c_profile_input,
                                                               o_error)
                THEN
                    g_error := 'ERROR GETTING PROFILES IN SOFTWARE ' || l_sw_list(sw);
                    RAISE l_profile_nok;
                ELSE
                    FETCH c_profile_input BULK COLLECT
                        INTO l_tbl_profile_id, l_tbl_profile_desc;
                
                    FOR pt IN 1 .. l_tbl_profile_id.count
                    LOOP
                        g_error := 'GET PROFILE DEFAULT ALERTS CONFIGURATION IN SW ' || l_sw_list(sw) ||
                                   ' AND PROFILE ' || l_tbl_profile_id(pt);
                        SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                      ',sa.code_alert)
																															FROM sys_alert sa
																														 WHERE EXISTS (SELECT 0
																																			FROM sys_alert_config sac
																																		 WHERE sac.id_software = ' ||
                                                      l_sw_list(sw) || '
																																			 AND sac.id_institution IN (0,' ||
                                                      i_prof.institution || ')
																																			 AND sac.id_profile_template = ' ||
                                                      l_tbl_profile_id(pt) || '
																																			 AND sac.id_sys_alert = sa.id_sys_alert)
                                                                       and pk_translation.get_translation(' ||
                                                      i_lang || ',sa.code_alert) is not null
																														 ORDER BY 1',
                                                      ';')
                          INTO l_alerts_clob
                          FROM dual;
                    
                        g_error := 'SET PROFILE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                   l_tbl_profile_id(pt);
                        IF length(l_alerts_clob) > 0
                        THEN
                        
                            tc_alert_clob.extend;
                            tc_alert_clob(l_idx) := l_alerts_clob;
                        
                            tv_profile_desc.extend;
                            tn_software_id.extend;
                            tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                            tn_software_id(l_idx) := l_sw_list(sw);
                            l_idx := l_idx + 1;
                        END IF;
                    END LOOP;
                    CLOSE c_profile_input;
                END IF;
            END LOOP;
        ELSIF (i_service IS NOT NULL AND i_dept IS NULL)
        THEN
            g_error   := 'GET SERVICE/ DEPT SOFTWARE LIST';
            l_sw_list := get_dept_software(i_lang, NULL, i_service, o_error);
        
            g_error := 'GET SERVICE DEFAULT CONFIGURATION COUNT';
            SELECT COUNT(*)
              INTO l_service_count
              FROM sys_alert_department sad
             WHERE sad.id_institution = i_prof.institution
               AND sad.id_department = i_service;
        
            g_error := 'GET TEMPORARY SERVICE DEFAULT CONFIGURATION COUNT';
            SELECT COUNT(*)
              INTO l_stg_service_count
              FROM stg_sys_alert_department ssad
             WHERE ssad.id_institution = i_prof.institution
               AND ssad.id_department = i_service;
        
            FOR sw IN 1 .. l_sw_list.count
            LOOP
                l_tbl_profile_id   := table_number();
                l_tbl_profile_desc := table_varchar();
                g_error            := 'GET PROFILE DEFAULT CONFIGURATION';
                IF NOT pk_backoffice.get_profile_template_list(i_lang,
                                                               i_prof.institution,
                                                               l_sw_list(sw),
                                                               c_profile_input,
                                                               o_error)
                THEN
                    g_error := 'ERROR GETTING PROFILES IN SOFTWARE ' || l_sw_list(sw);
                    RAISE l_profile_nok;
                ELSE
                    FETCH c_profile_input BULK COLLECT
                        INTO l_tbl_profile_id, l_tbl_profile_desc;
                
                    IF (l_service_count = l_generic_id AND l_stg_service_count = l_generic_id)
                    THEN
                    
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET PROFILE DEFAULT ALERTS CONFIGURATION IN SW ' || l_sw_list(sw) ||
                                       ' AND PROFILE ' || l_tbl_profile_id(pt);
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ',sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM sys_alert_config sac
																																				 WHERE sac.id_software = ' ||
                                                          l_sw_list(sw) || '
																																					 AND sac.id_institution IN (0,' ||
                                                          i_prof.institution || ')
																																					 AND sac.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND sac.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                        
                            g_error := 'SET PROFILE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    
                    ELSIF (l_service_count > l_generic_id AND l_stg_service_count = l_generic_id)
                    THEN
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET SERVICE DEFAULT CONFIGURATION';
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ',sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM sys_alert_department sad
																																				 WHERE sad.id_department = ' ||
                                                          i_service || ' 
																																					 AND sad.id_institution = ' ||
                                                          i_prof.institution || '
																																					 AND sad.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND sad.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                            g_error := 'SET SERVICE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    ELSE
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                        
                            g_error := 'GET SERVICE STG DEFAULT CONFIGURATION';
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ',sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM stg_sys_alert_department ssad
																																				 WHERE ssad.id_department = ' ||
                                                          i_service || ' 
																																					 AND ssad.id_institution = ' ||
                                                          i_prof.institution || '
																																					 AND ssad.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND ssad.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                        
                            g_error := 'SET SERVICE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    END IF;
                    CLOSE c_profile_input;
                END IF;
            END LOOP;
        ELSIF (i_service IS NOT NULL AND i_dept IS NOT NULL)
        THEN
            g_error := 'GET CURRENT DEPT SERVICE';
            SELECT s.id_dept
              INTO l_cur_dept
              FROM department s
             WHERE s.id_department = i_service;
        
            g_error := 'GET SERVICE DEFAULT CONFIGURATION COUNT';
            SELECT COUNT(*)
              INTO l_service_count
              FROM sys_alert_department sad
             WHERE sad.id_institution = i_prof.institution
               AND sad.id_department = i_service;
        
            g_error   := 'GET SERVICE/ DEPT SOFTWARE LIST';
            l_sw_list := get_dept_software(i_lang, i_dept, NULL, o_error);
        
            FOR sw IN 1 .. l_sw_list.count
            LOOP
                l_tbl_profile_id   := table_number();
                l_tbl_profile_desc := table_varchar();
                g_error            := 'GET PROFILE DEFAULT CONFIGURATION';
                IF NOT pk_backoffice.get_profile_template_list(i_lang,
                                                               i_prof.institution,
                                                               l_sw_list(sw),
                                                               c_profile_input,
                                                               o_error)
                THEN
                    g_error := 'ERROR GETTING PROFILES IN SOFTWARE ' || l_sw_list(sw);
                    RAISE l_profile_nok;
                ELSE
                    FETCH c_profile_input BULK COLLECT
                        INTO l_tbl_profile_id, l_tbl_profile_desc;
                
                    IF (l_service_count = l_generic_id)
                    THEN
                    
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET PROFILE DEFAULT ALERTS CONFIGURATION IN SW ' || l_sw_list(sw) ||
                                       ' AND PROFILE ' || l_tbl_profile_id(pt);
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ',sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM sys_alert_config sac
																																				 WHERE sac.id_software = ' ||
                                                          l_sw_list(sw) || '
																																					 AND sac.id_institution in (0, ' ||
                                                          i_prof.institution || ')
																																					 AND sac.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND sac.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                        
                            g_error := 'SET PROFILE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    
                    ELSE
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET SERVICE DEFAULT CONFIGURATION';
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ', sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM (SELECT sad.id_sys_alert
																																									FROM sys_alert_department sad
																																								 WHERE sad.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																									 AND sad.id_institution = ' ||
                                                          i_prof.institution || '
																																									 AND sad.id_department = ' ||
                                                          i_service || '
																																								UNION
																																								SELECT sac.id_sys_alert
																																									FROM sys_alert_config sac
																																								 WHERE sac.id_software = ' ||
                                                          l_sw_list(sw) || '
																																									 AND sac.id_institution IN (0,' ||
                                                          i_prof.institution || ')
																																									 AND sac.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																									 AND NOT EXISTS
																																								 (SELECT 0
																																													FROM sys_alert_department sad1
																																												 WHERE sad1.id_profile_template = sac.id_profile_template
																																													 AND sad1.id_sys_alert = sac.id_sys_alert
																																													 AND sad1.id_institution = ' ||
                                                          i_prof.institution || '
																																													 AND sad1.id_department = ' ||
                                                          i_service ||
                                                          ')) list1
																																				 WHERE list1.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ', sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                            g_error := 'SET SERVICE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    END IF;
                    CLOSE c_profile_input;
                END IF;
            END LOOP;
        ELSIF i_id_prof IS NOT NULL
        THEN
        
            l_tbl_profile_id   := table_number();
            l_tbl_profile_desc := table_varchar();
        
            SELECT COUNT(*)
              INTO l_inst_profs
              FROM profile_template_inst pti
             WHERE pti.id_institution = i_prof.institution;
        
            IF l_inst_profs = 0
            THEN
                g_error := 'GET PROFESSIONAL ALERT LIST';
                SELECT pt.id_profile_template,
                       decode(ptm.id_market,
                              l_generic_id,
                              pk_message.get_message(i_lang, pt.code_profile_template),
                              pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                              pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                       ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                       ptm.id_market || '',
                                                       ',') || ')'),
                       pt.id_software
                  BULK COLLECT
                  INTO l_tbl_profile_id, l_tbl_profile_desc, l_sw_list
                  FROM profile_template pt
                 INNER JOIN profile_template_market ptm
                    ON (ptm.id_profile_template = pt.id_profile_template)
                 INNER JOIN profile_template_inst pti
                    ON (pti.id_profile_template = pt.id_profile_template AND pti.id_institution = l_generic_id)
                 WHERE ptm.id_market IN (l_market_id, l_generic_id)
                   AND EXISTS (SELECT 0
                          FROM software s
                         WHERE s.id_software = pt.id_software
                           AND s.flg_viewer = 'N')
                   AND EXISTS (SELECT 0
                          FROM prof_profile_template ppt
                         WHERE ppt.id_profile_template = pt.id_profile_template
                           AND ppt.id_professional = i_id_prof
                           AND ppt.id_institution = i_prof.institution);
            ELSE
                g_error := 'GET PROFESSIONAL ALERT LIST';
            
                SELECT pt.id_profile_template,
                       decode(ptm.id_market,
                              l_generic_id,
                              pk_message.get_message(i_lang, pt.code_profile_template),
                              pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                              pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                       ', m.code_market) 
                               FROM market m WHERE m.id_market =' ||
                                                       ptm.id_market || '',
                                                       ',') || ')'),
                       pt.id_software
                  BULK COLLECT
                  INTO l_tbl_profile_id, l_tbl_profile_desc, l_sw_list
                  FROM profile_template pt
                 INNER JOIN profile_template_market ptm
                    ON (ptm.id_profile_template = pt.id_profile_template)
                 INNER JOIN profile_template_inst pti
                    ON (pti.id_profile_template = pt.id_profile_template AND pti.id_institution = i_prof.institution)
                 WHERE ptm.id_market IN (l_market_id, l_generic_id)
                   AND EXISTS (SELECT 0
                          FROM software s
                         WHERE s.id_software = pt.id_software
                           AND s.flg_viewer = 'N')
                   AND EXISTS (SELECT 0
                          FROM prof_profile_template ppt
                         WHERE ppt.id_profile_template = pt.id_profile_template
                           AND ppt.id_professional = i_id_prof
                           AND ppt.id_institution = i_prof.institution);
            
            END IF;
        
            FOR sw IN 1 .. l_sw_list.count
            LOOP
                g_error := 'GET PROFILE DEFAULT ALERTS CONFIGURATION IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                           l_tbl_profile_id(sw);
                SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                              ', sa.code_alert)
																									FROM sys_alert sa
																								 WHERE EXISTS (SELECT 0
																													FROM sys_alert_prof sap
																												 WHERE sap.id_software = ' || l_sw_list(sw) || '
																													 AND sap.id_institution IN (0, ' ||
                                              i_prof.institution || ')
																													 AND sap.id_professional = ' || i_id_prof || '
																													 AND sap.id_profile_template = ' ||
                                              l_tbl_profile_id(sw) || '
																													 AND sap.id_sys_alert = sa.id_sys_alert)
																								 and pk_translation.get_translation(' || i_lang ||
                                              ', sa.code_alert) is not null
                                                 ORDER BY 1',
                                              ';')
                  INTO l_alerts_clob
                  FROM dual;
            
                SELECT pk_utils.query_to_clob(' SELECT DISTINCT pk_translation.get_translation(' || i_lang ||
                                              ', sf.code_functionality) func
              FROM prof_func pf, sys_functionality sf
             WHERE pf.id_professional = ' || i_id_prof || '
               AND pf.id_institution = ' || i_prof.institution || '
               AND sf.id_software IN (' || l_sw_list(sw) ||
                                              ', 0)
               AND sf.id_functionality = pf.id_functionality
               AND sf.flg_available = ''Y'' and pk_translation.get_translation(' ||
                                              i_lang || ', sf.code_functionality) is not null order by 1',
                                              ';')
                  INTO l_functs_clob
                  FROM dual;
            
                g_error := 'SET PROFILE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' || l_tbl_profile_id(sw);
            
                tc_alert_clob.extend;
                tc_alert_clob(l_idx) := l_alerts_clob;
            
                tc_funct_clob.extend;
                tc_funct_clob(l_idx) := l_functs_clob;
            
                tv_profile_desc.extend;
                tn_software_id.extend;
                tv_profile_desc(l_idx) := l_tbl_profile_desc(sw);
                tn_software_id(l_idx) := l_sw_list(sw);
                l_idx := l_idx + 1;
            
            END LOOP;
        ELSE
            g_error := 'GET INSTITUTION SOFTWARE LIST';
            SELECT si.id_software
              BULK COLLECT
              INTO l_sw_list
              FROM software_institution si
             WHERE si.id_institution = i_prof.institution;
        
            FOR sw IN 1 .. l_sw_list.count
            LOOP
                l_tbl_profile_id   := table_number();
                l_tbl_profile_desc := table_varchar();
                g_error            := 'GET PROFILE DEFAULT CONFIGURATION';
                IF NOT pk_backoffice.get_profile_template_list(i_lang,
                                                               i_prof.institution,
                                                               l_sw_list(sw),
                                                               c_profile_input,
                                                               o_error)
                THEN
                    g_error := 'ERROR GETTING PROFILES IN SOFTWARE ' || l_sw_list(sw);
                    RAISE l_profile_nok;
                ELSE
                    FETCH c_profile_input BULK COLLECT
                        INTO l_tbl_profile_id, l_tbl_profile_desc;
                
                    g_error := 'GET SERVICE DEFAULT CONFIGURATION COUNT';
                    SELECT COUNT(*)
                      INTO l_service_count
                      FROM sys_alert_department sad
                     WHERE sad.id_institution = i_prof.institution
                       AND sad.id_department = i_service;
                
                    IF (l_service_count = l_generic_id)
                    THEN
                    
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET PROFILE DEFAULT ALERTS CONFIGURATION IN SW ' || l_sw_list(sw) ||
                                       ' AND PROFILE ' || l_tbl_profile_id(pt);
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ', sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM sys_alert_config sac
																																				 WHERE sac.id_software = ' ||
                                                          l_sw_list(sw) || '
																																					 AND sac.id_institution IN (0, ' ||
                                                          i_prof.institution || ')
																																					 AND sac.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND sac.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ', sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                        
                            g_error := 'SET PROFILE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    
                    ELSE
                        FOR pt IN 1 .. l_tbl_profile_id.count
                        LOOP
                            g_error := 'GET SERVICE DEFAULT CONFIGURATION';
                            SELECT pk_utils.query_to_clob('SELECT pk_translation.get_translation(' || i_lang ||
                                                          ', sa.code_alert)
																																	FROM sys_alert sa
																																 WHERE EXISTS (SELECT 0
																																					FROM sys_alert_department sad
																																				 WHERE sad.id_institution = ' ||
                                                          i_prof.institution || '
																																					 AND sad.id_department = ' ||
                                                          i_service || '
																																					 AND sad.id_profile_template = ' ||
                                                          l_tbl_profile_id(pt) || '
																																					 AND sad.id_sys_alert = sa.id_sys_alert)
																																 and pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ', sa.code_alert) is not null
                                                                 ORDER BY 1',
                                                          ';')
                              INTO l_alerts_clob
                              FROM dual;
                            g_error := 'SET SERVICE ARRAYS IN SW ' || l_sw_list(sw) || ' AND PROFILE ' ||
                                       l_tbl_profile_id(pt);
                            IF length(l_alerts_clob) > 0
                            THEN
                                tc_alert_clob.extend;
                                tc_alert_clob(l_idx) := l_alerts_clob;
                            
                                tv_profile_desc.extend;
                                tn_software_id.extend;
                                tv_profile_desc(l_idx) := l_tbl_profile_desc(pt);
                                tn_software_id(l_idx) := l_sw_list(sw);
                                l_idx := l_idx + 1;
                            END IF;
                        END LOOP;
                    END IF;
                    CLOSE c_profile_input;
                END IF;
            END LOOP;
        END IF;
        IF l_def_alerts_val = g_flg_available
        THEN
            IF i_id_prof IS NULL
            THEN
                g_error := 'SEND INFORMATION CURSOR TO UI';
                OPEN o_info FOR
                    SELECT sw_id.column_value id_software,
                           (SELECT s.name
                              FROM software s
                             WHERE s.id_software = sw_id.column_value) software_name,
                           pt_desc.column_value profile_name,
                           alert_desc.column_value alert_list,
                           NULL funct_list
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(tn_software_id)) sw_id
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tv_profile_desc)) pt_desc
                        ON (pt_desc.id = sw_id.id)
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tc_alert_clob)) alert_desc
                        ON (alert_desc.id = sw_id.id);
            
            ELSE
                g_error := 'SEND INFORMATION CURSOR TO UI';
                OPEN o_info FOR
                    SELECT sw_id.column_value id_software,
                           (SELECT s.name
                              FROM software s
                             WHERE s.id_software = sw_id.column_value) software_name,
                           pt_desc.column_value profile_name,
                           alert_desc.column_value alert_list,
                           funct_desc.column_value funct_list
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(tn_software_id)) sw_id
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tv_profile_desc)) pt_desc
                        ON (pt_desc.id = sw_id.id)
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tc_alert_clob)) alert_desc
                        ON (alert_desc.id = sw_id.id)
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tc_funct_clob)) funct_desc
                        ON (funct_desc.id = sw_id.id);
            
            END IF;
        ELSE
            IF i_id_prof IS NULL
            THEN
                g_error := 'SEND INFORMATION CURSOR TO UI';
                OPEN o_info FOR
                    SELECT sw_id.column_value id_software,
                           (SELECT s.name
                              FROM software s
                             WHERE s.id_software = sw_id.column_value) software_name,
                           pt_desc.column_value profile_name,
                           NULL alert_list,
                           NULL funct_list
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(tn_software_id)) sw_id
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tv_profile_desc)) pt_desc
                        ON (pt_desc.id = sw_id.id);
            
            ELSE
                g_error := 'SEND INFORMATION CURSOR TO UI';
                OPEN o_info FOR
                    SELECT sw_id.column_value id_software,
                           (SELECT s.name
                              FROM software s
                             WHERE s.id_software = sw_id.column_value) software_name,
                           pt_desc.column_value profile_name,
                           NULL alert_list,
                           funct_desc.column_value funct_list
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(tn_software_id)) sw_id
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tv_profile_desc)) pt_desc
                        ON (pt_desc.id = sw_id.id)
                     INNER JOIN (SELECT column_value, rownum AS id
                                   FROM TABLE(tc_funct_clob)) funct_desc
                        ON (funct_desc.id = sw_id.id);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_profile_nok THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_service_alert_det;
    /********************************************************************************************
    * Get Alert List Service configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_profile_template Profile template ID            
    * @param i_id_service          Service ID
    * @param o_list                Cursor with alerts configuration information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION get_serv_sys_alert_pt
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN professional.id_professional%TYPE,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_service_count     NUMBER := 0;
        l_tmp_service_count NUMBER := 0;
        l_generic_id        NUMBER := 0;
    BEGIN
        g_function_name := 'GET_PROFILE_SYS_ALERT';
        g_error         := 'CHECK TEMPORARY CONFIG BY SERVICE ID';
        SELECT COUNT(*)
          INTO l_tmp_service_count
          FROM stg_sys_alert_department ssad
         WHERE ssad.id_institution = i_id_institution
           AND ssad.id_department = i_id_service
           AND ssad.id_profile_template = i_id_profile_template;
    
        g_error := 'CHECK CONFIG BY SERVICE ID';
        SELECT COUNT(*)
          INTO l_service_count
          FROM sys_alert_department sad
         WHERE sad.id_institution = i_id_institution
           AND sad.id_department = i_id_service
           AND sad.id_profile_template = i_id_profile_template;
    
        IF (l_tmp_service_count = l_generic_id)
        THEN
            IF (l_service_count = l_generic_id)
            THEN
                g_error := 'GET DEFAULT CURSOR BY PROFILE ID';
                OPEN o_list FOR
                    SELECT sac.id_sys_alert,
                           pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                           'A' flg_select
                      FROM sys_alert_config sac
                     INNER JOIN sys_alert sa
                        ON (sa.id_sys_alert = sac.id_sys_alert)
                     WHERE sac.id_software IN (l_generic_id, i_id_software)
                       AND sac.id_institution IN (l_generic_id, i_id_institution)
                       AND sac.id_profile_template = i_id_profile_template
                    UNION
                    SELECT sac.id_sys_alert,
                           pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                           'I' flg_select
                      FROM sys_alert_config sac
                     INNER JOIN sys_alert sa
                        ON (sa.id_sys_alert = sac.id_sys_alert)
                     WHERE sac.id_software IN (l_generic_id, i_id_software)
                       AND sac.id_institution IN (l_generic_id, i_id_institution)
                       AND sac.id_profile_template = l_generic_id
                     ORDER BY sys_alert;
            
            ELSE
                OPEN o_list FOR
                    SELECT sad.id_sys_alert,
                           pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                           'A' flg_select
                      FROM sys_alert_department sad
                     INNER JOIN sys_alert sa
                        ON (sa.id_sys_alert = sad.id_sys_alert)
                     WHERE sad.id_profile_template = i_id_profile_template
                       AND sad.id_institution = i_id_institution
                       AND sad.id_department = i_id_service
                    UNION
                    SELECT sac.id_sys_alert,
                           pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                           'I' flg_select
                      FROM sys_alert_config sac
                     INNER JOIN sys_alert sa
                        ON (sa.id_sys_alert = sac.id_sys_alert)
                     WHERE sac.id_profile_template IN (l_generic_id, i_id_profile_template)
                       AND sac.id_institution IN (l_generic_id, i_id_institution)
                       AND sac.id_software IN (l_generic_id, i_id_software)
                       AND NOT EXISTS
                     (SELECT 0
                              FROM sys_alert_department sad
                             WHERE sad.id_sys_alert = sac.id_sys_alert
                               AND sad.id_profile_template = decode(sac.id_profile_template,
                                                                    l_generic_id,
                                                                    i_id_profile_template,
                                                                    sac.id_profile_template)
                               AND sad.id_institution = i_id_institution
                               AND sad.id_department = i_id_service)
                     ORDER BY sys_alert;
            
            END IF;
        ELSE
            OPEN o_list FOR
                SELECT ssad.id_sys_alert,
                       pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                       'A' flg_select
                  FROM stg_sys_alert_department ssad
                 INNER JOIN sys_alert sa
                    ON (sa.id_sys_alert = ssad.id_sys_alert)
                 WHERE ssad.id_profile_template = i_id_profile_template
                   AND ssad.id_institution = i_id_institution
                   AND ssad.id_department = i_id_service
                UNION
                SELECT sac.id_sys_alert,
                       pk_translation.get_translation(i_lang, sa.code_alert) sys_alert,
                       'I' flg_select
                  FROM sys_alert_config sac
                 INNER JOIN sys_alert sa
                    ON (sa.id_sys_alert = sac.id_sys_alert)
                 WHERE sac.id_profile_template IN (l_generic_id, i_id_profile_template)
                   AND sac.id_institution IN (l_generic_id, i_id_institution)
                   AND sac.id_software IN (l_generic_id, i_id_software)
                   AND NOT EXISTS
                 (SELECT 0
                          FROM stg_sys_alert_department ssad
                         WHERE ssad.id_sys_alert = sac.id_sys_alert
                           AND ssad.id_profile_template = decode(sac.id_profile_template,
                                                                 l_generic_id,
                                                                 i_id_profile_template,
                                                                 sac.id_profile_template)
                           AND ssad.id_institution = i_id_institution
                           AND ssad.id_department = i_id_service)
                 ORDER BY sys_alert;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_serv_sys_alert_pt;
    /********************************************************************************************
    * Saves Service Alerts Configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution           Institution ID
    * @param o_error                 Error info
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/08/29
    **********************************************************************************************/
    FUNCTION set_serv_alert_conf
    (
        i_lang          IN language.id_language%TYPE,
        i_service       IN department.id_department%TYPE,
        i_institution   IN department.id_institution%TYPE,
        i_template_list IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function_name := upper('set_serv_alert_conf');
    
        g_error := 'REMOVE INVALID ALERT CONFIG LIST BY SERVICE/ PROFILE' || i_service;
        DELETE FROM sys_alert_department sad
         WHERE sad.id_department = i_service
           AND sad.id_institution = i_institution
           AND NOT EXISTS (SELECT 0
                  FROM stg_sys_alert_department ssad
                 WHERE ssad.id_sys_alert = sad.id_sys_alert
                   AND ssad.id_department = sad.id_department
                   AND ssad.id_profile_template = sad.id_profile_template
                   AND ssad.id_institution = sad.id_institution);
    
        g_error := 'INSERT ALERT CONFIG LIST BY SERVICE/ PROFILE ' || i_service;
        INSERT INTO sys_alert_department
            (id_sys_alert_department, id_sys_alert, id_profile_template, id_institution, id_department, flg_no_alert)
            SELECT seq_sys_alert_department.nextval,
                   ssad.id_sys_alert,
                   ssad.id_profile_template,
                   ssad.id_institution,
                   ssad.id_department,
                   ssad.flg_no_alert
              FROM stg_sys_alert_department ssad
             WHERE ssad.id_department = i_service
               AND ssad.id_institution = i_institution
               AND NOT EXISTS (SELECT 0
                      FROM sys_alert_department sad
                     WHERE sad.id_sys_alert = ssad.id_sys_alert
                       AND sad.id_profile_template = ssad.id_profile_template
                       AND sad.id_institution = ssad.id_institution
                       AND sad.id_department = ssad.id_department);
    
        g_error := 'REMOVE TEMPORARY CONFIGURATION AFTER SAVE ' || i_service;
        DELETE FROM stg_sys_alert_department ssad
         WHERE ssad.id_department = i_service
           AND ssad.id_institution = i_institution;
    
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
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_serv_alert_conf;
    /********************************************************************************************
    * Set temporary alert configuration before saving service complete information
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_service             Service ID
    * @param i_profile_list        List of profiles to save
    * @param i_alert_list          List of alerts to save (synch with profiles list)
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/11/05
    ********************************************************************************************/
    FUNCTION set_alert_by_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_service      IN department.id_department%TYPE,
        i_profile_list IN table_number,
        i_alert_list   IN table_number,
        i_flg_alert    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sw_list table_number := table_number();
    BEGIN
        g_function_name := 'SET_ALERT_BY_SERV';
    
        g_error := 'DELETE PREVIOUS NOT NEEDED RECORDS';
        DELETE FROM stg_sys_alert_department ssad
         WHERE ssad.id_institution = i_institution
           AND ssad.id_department = i_service
           AND ssad.id_profile_template IN
               (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                 column_value
                  FROM TABLE(CAST(i_profile_list AS table_number)) p);
    
        g_error   := 'GET SERVICE/ DEPT SOFTWARE LIST';
        l_sw_list := get_dept_software(i_lang, NULL, i_service, o_error);
    
        g_error := 'SET ALERT/PROFILE/SERVICE IN TEMPORARY TABLES';
        INSERT INTO stg_sys_alert_department
            (id_stg_sys_alert_depart, id_sys_alert, id_department, id_profile_template, id_institution, flg_no_alert)
            SELECT seq_stg_sys_alert_department.nextval,
                   config_list.id_alert,
                   config_list.id_service,
                   config_list.id_profile,
                   config_list.id_institution,
                   config_list.flg_cfg
              FROM (SELECT alert_list.column_value id_alert,
                           i_service id_service,
                           templ_list.column_value id_profile,
                           i_institution id_institution,
                           nvl(flg_noalert.column_value, 'N') flg_cfg,
                           pt.id_software id_software
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(i_profile_list)) templ_list
                     INNER JOIN (SELECT column_value, rownum AS id
                                  FROM TABLE(i_alert_list)) alert_list
                        ON (templ_list.id = alert_list.id)
                     INNER JOIN (SELECT column_value, rownum AS id
                                  FROM TABLE(i_flg_alert)) flg_noalert
                        ON (templ_list.id = flg_noalert.id)
                     INNER JOIN profile_template pt
                        ON (pt.id_profile_template = templ_list.column_value AND pt.flg_available = g_flg_available)
                    UNION
                    SELECT sad.id_sys_alert        id_alert,
                           sad.id_department       id_service,
                           sad.id_profile_template id_profile,
                           sad.id_institution      id_institution,
                           sad.flg_no_alert        flg_cfg,
                           pt.id_software          id_software
                      FROM sys_alert_department sad
                     INNER JOIN profile_template pt
                        ON (pt.id_profile_template = sad.id_profile_template AND pt.flg_available = g_flg_available)
                     WHERE sad.id_institution = i_institution
                       AND sad.id_department = i_service
                       AND sad.id_profile_template NOT IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                             column_value
                              FROM TABLE(CAST(i_profile_list AS table_number)) p)
                    UNION
                    SELECT sac.id_sys_alert id_alert,
                           i_service id_service,
                           sac.id_profile_template id_profile,
                           i_institution id_institution,
                           'N' flg_cfg,
                           sac.id_software id_software
                      FROM sys_alert_config sac
                     WHERE sac.id_institution IN (0, i_institution)
                       AND sac.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                column_value
                                                 FROM TABLE(CAST(l_sw_list AS table_number)) p)
                       AND sac.id_profile_template NOT IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                             column_value
                              FROM TABLE(CAST(i_profile_list AS table_number)) p)
                       AND NOT EXISTS (SELECT 0
                              FROM sys_alert_department sad
                             WHERE sad.id_profile_template = sac.id_profile_template
                               AND sad.id_department = i_service
                               AND sad.id_institution = i_institution)) config_list
             WHERE NOT EXISTS (SELECT 0
                      FROM stg_sys_alert_department ssad
                     WHERE ssad.id_profile_template = config_list.id_profile
                       AND ssad.id_department = config_list.id_service
                       AND ssad.id_institution = config_list.id_institution)
               AND EXISTS (SELECT 0
                      FROM profile_template pt
                     INNER JOIN profile_template_market ptm
                        ON (ptm.id_profile_template = pt.id_profile_template AND
                           ptm.id_market IN (0, pk_utils.get_institution_market(i_lang, i_institution)))
                     WHERE pt.id_profile_template = config_list.id_profile
                       AND pt.id_software = config_list.id_software);
    
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
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_alert_by_serv;
    /********************************************************************************************
    * reset all professional alert configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/08/29
    **********************************************************************************************/
    FUNCTION reset_all_prof_alert
    (
        i_lang          IN language.id_language%TYPE,
        i_service       IN department.id_department%TYPE,
        i_institution   IN department.id_institution%TYPE,
        i_template_list IN table_number
    ) RETURN BOOLEAN IS
        l_profile_list  table_number := table_number();
        l_prof_id_list  table_number := table_number();
        l_software_list table_number := table_number();
    
        l_dept_id         department.id_dept%TYPE := NULL;
        l_dept_softw_list table_number := table_number();
    
        l_alert_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
        g_function_name := upper('reset_all_prof_alert');
        g_error         := 'GET SERVICE ' || i_service || ' DEPARTMENT';
        SELECT d.id_dept
          INTO l_dept_id
          FROM department d
         WHERE d.id_department = i_service;
    
        g_error           := 'GET DEPARTMENT ' || l_dept_id || ' SOFTWARE LIST';
        l_dept_softw_list := get_dept_software(i_lang, l_dept_id, NULL, l_error);
    
        g_error := 'GET PROFESSIONAL PROFILE LIST IN SERVICE ' || i_service;
        SELECT ppt.id_professional, ppt.id_profile_template, ppt.id_software
          BULK COLLECT
          INTO l_prof_id_list, l_profile_list, l_software_list
          FROM prof_profile_template ppt
         WHERE ppt.id_institution = i_institution
           AND ppt.id_profile_template IN
               (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                 column_value
                  FROM TABLE(CAST(i_template_list AS table_number)) p)
           AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                    column_value
                                     FROM TABLE(CAST(l_dept_softw_list AS table_number)) p)
           AND EXISTS (SELECT 0
                  FROM sys_alert_department sad
                 WHERE sad.id_profile_template = ppt.id_profile_template
                   AND sad.id_institution = ppt.id_institution
                   AND sad.id_department = i_service)
           AND EXISTS
         (SELECT 0
                  FROM prof_dep_clin_serv pdcs
                  JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_flg_available)
                 WHERE pdcs.id_professional = ppt.id_professional
                   AND pdcs.id_institution = i_institution
                   AND dcs.id_department = i_service);
    
        FOR pt IN 1 .. l_profile_list.count
        LOOP
            IF NOT pk_access.del_prof_alerts(i_lang,
                                             profissional(l_prof_id_list(pt), i_institution, l_software_list(pt)),
                                             l_profile_list(pt),
                                             l_error)
            THEN
                g_error := 'ERROR DELETING ALERT LIST';
                RAISE l_alert_exception;
            END IF;
            g_error := 'SET PROFESSIONAL NEW ALERT LIST';
            IF NOT pk_access.set_prof_alerts(i_lang,
                                             profissional(l_prof_id_list(pt), i_institution, l_software_list(pt)),
                                             l_profile_list(pt),
                                             i_service,
                                             l_error)
            THEN
                g_error := 'ERROR SETTING ALERT LIST';
                RAISE l_alert_exception;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN l_alert_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END reset_all_prof_alert;
    /********************************************************************************************
    * delete service alert configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION reset_default_alerts
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN department.id_department%TYPE,
        i_institution IN department.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function_name := upper('reset_default_alerts');
        g_error         := 'REMOVE DEFAULT SERVICE CONFIGURATIONS';
        DELETE FROM sys_alert_department sad
         WHERE sad.id_department = i_service
           AND sad.id_institution = i_institution;
    
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
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END reset_default_alerts;
    /********************************************************************************************
    * Get prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_list                   Output structured Information List
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION get_prof_serv_alert
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN table_number,
        i_institution IN department.id_institution%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_flg_change  IN table_varchar,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_list table_number := table_number();
        l_sw_list      table_number := table_number();
    
        tn_id_software   table_number := table_number();
        tv_desc_software table_varchar := table_varchar();
        tn_id_profile    table_number := table_number();
        tv_desc_profile  table_varchar := table_varchar();
        tn_id_sysalert   table_number := table_number();
        tv_desc_sysalert table_varchar := table_varchar();
    
        tn_id_software_all   table_number := table_number();
        tv_desc_software_all table_varchar := table_varchar();
        tn_id_profile_all    table_number := table_number();
        tv_desc_profile_all  table_varchar := table_varchar();
        tn_id_sysalert_all   table_number := table_number();
        tv_desc_sysalert_all table_varchar := table_varchar();
    BEGIN
        g_function_name := upper('get_prof_serv_alert');
    
        FOR sv IN 1 .. i_service.count
        LOOP
            g_error   := 'GET SERVICE ' || i_service(sv) || '/ DEPT SOFTWARE LIST';
            l_sw_list := get_dept_software(i_lang, NULL, i_service(sv), o_error);
        
            g_error := 'GET PROFESSIONAL ' || i_id_prof || '/ PROFILE LIST';
            SELECT ppt.id_profile_template
              BULK COLLECT
              INTO l_profile_list
              FROM prof_profile_template ppt
             INNER JOIN profile_template pt
                ON (pt.id_profile_template = ppt.id_profile_template AND pt.id_software = ppt.id_software AND
                   pt.flg_available = 'Y')
             INNER JOIN software s
                ON (s.id_software = ppt.id_software AND s.flg_viewer != g_flg_available)
             WHERE ppt.id_professional = i_id_prof
               AND ppt.id_institution = i_institution
               AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                        column_value
                                         FROM TABLE(CAST(l_sw_list AS table_number)) p);
        
            g_error := 'GET PROFESSIONAL ' || i_id_prof || '/ ALERT LIST';
            SELECT norm_data.id_software,
                   norm_data.desc_software,
                   norm_data.id_profile_template,
                   norm_data.desc_profile,
                   norm_data.id_sys_alert,
                   norm_data.desc_alert
              BULK COLLECT
              INTO tn_id_software, tv_desc_software, tn_id_profile, tv_desc_profile, tn_id_sysalert, tv_desc_sysalert
              FROM (SELECT ppt.id_software,
                           (SELECT /*pk_translation.get_translation(i_lang, s.code_software)*/
                             s.name
                              FROM profile_template pt
                              JOIN software s
                                ON (s.id_software = pt.id_software)
                             WHERE pt.id_profile_template = sad.id_profile_template) desc_software,
                           ppt.id_profile_template,
                           (SELECT pk_message.get_message(i_lang, pt1.code_profile_template)
                              FROM profile_template pt1
                             WHERE pt1.id_profile_template = sad.id_profile_template) desc_profile,
                           sad.id_sys_alert,
                           (SELECT pk_translation.get_translation(i_lang, sa.code_alert)
                              FROM sys_alert sa
                             WHERE sa.id_sys_alert = sad.id_sys_alert) desc_alert
                      FROM prof_profile_template ppt
                     INNER JOIN sys_alert_department sad
                        ON (sad.id_profile_template = ppt.id_profile_template AND
                           sad.id_institution = ppt.id_institution)
                     WHERE ppt.id_professional = i_id_prof
                       AND ppt.id_institution = i_institution
                       AND ppt.id_profile_template IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                             column_value
                              FROM TABLE(CAST(l_profile_list AS table_number)) p)
                       AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                column_value
                                                 FROM TABLE(CAST(l_sw_list AS table_number)) p)
                       AND sad.id_department = i_service(sv)
                       AND i_flg_change(sv) = g_flg_available
                    UNION
                    SELECT ppt.id_software,
                           (SELECT /*pk_translation.get_translation(i_lang, s.code_software)*/
                             s.name
                              FROM profile_template pt
                              JOIN software s
                                ON (s.id_software = pt.id_software)
                             WHERE pt.id_profile_template = sad.id_profile_template) desc_software,
                           ppt.id_profile_template,
                           (SELECT pk_message.get_message(i_lang, pt1.code_profile_template)
                              FROM profile_template pt1
                             WHERE pt1.id_profile_template = sad.id_profile_template) desc_profile,
                           sad.id_sys_alert,
                           (SELECT pk_translation.get_translation(i_lang, sa.code_alert)
                              FROM sys_alert sa
                             WHERE sa.id_sys_alert = sad.id_sys_alert) desc_alert
                      FROM prof_profile_template ppt
                     INNER JOIN sys_alert_department sad
                        ON (sad.id_profile_template = ppt.id_profile_template AND
                           sad.id_institution = ppt.id_institution)
                     WHERE ppt.id_professional = i_id_prof
                       AND ppt.id_institution = i_institution
                       AND ppt.id_profile_template IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                             column_value
                              FROM TABLE(CAST(l_profile_list AS table_number)) p)
                       AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                column_value
                                                 FROM TABLE(CAST(l_sw_list AS table_number)) p)
                       AND sad.id_department != i_service(sv)
                       AND NOT EXISTS (SELECT 0
                              FROM (SELECT column_value, rownum AS id
                                      FROM TABLE(i_service)) serv_id_list
                             INNER JOIN (SELECT column_value, rownum AS id
                                          FROM TABLE(i_flg_change)) flg_chg_list
                                ON (flg_chg_list.id = serv_id_list.id)
                             WHERE serv_id_list.column_value = sad.id_department)
                       AND EXISTS
                     (SELECT 0
                              FROM prof_dep_clin_serv pdcs
                             INNER JOIN dep_clin_serv dcs
                                ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_flg_available)
                             INNER JOIN department sv
                                ON (sv.id_department = dcs.id_department AND sv.flg_available = g_flg_available)
                             INNER JOIN clinical_service cs
                                ON (cs.id_clinical_service = dcs.id_clinical_service AND
                                   cs.flg_available = g_flg_available)
                             WHERE pdcs.id_professional = ppt.id_professional
                               AND dcs.id_department = sad.id_department)) norm_data;
        
            tn_id_software_all   := tn_id_software_all MULTISET UNION tn_id_software;
            tv_desc_software_all := tv_desc_software_all MULTISET UNION tv_desc_software;
            tn_id_profile_all    := tn_id_profile_all MULTISET UNION tn_id_profile;
            tv_desc_profile_all  := tv_desc_profile_all MULTISET UNION tv_desc_profile;
            tn_id_sysalert_all   := tn_id_sysalert_all MULTISET UNION tn_id_sysalert;
            tv_desc_sysalert_all := tv_desc_sysalert_all MULTISET UNION tv_desc_sysalert;
        
        END LOOP;
    
        OPEN o_list FOR
            SELECT softw_id_list.column_value   software_id,
                   softw_desc_list.column_value software_desc,
                   profl_id_list.column_value   profile_id,
                   profl_desc_list.column_value profile_desc,
                   alert_id_list.column_value   id_alert,
                   alert_desc_list.column_value alert_desc
              FROM (SELECT column_value, rownum AS id
                      FROM TABLE(tn_id_software_all)) softw_id_list
             INNER JOIN (SELECT column_value, rownum AS id
                           FROM TABLE(tv_desc_software_all)) softw_desc_list
                ON (softw_desc_list.id = softw_id_list.id)
             INNER JOIN (SELECT column_value, rownum AS id
                           FROM TABLE(tn_id_profile_all)) profl_id_list
                ON (profl_id_list.id = softw_id_list.id)
             INNER JOIN (SELECT column_value, rownum AS id
                           FROM TABLE(tv_desc_profile_all)) profl_desc_list
                ON (profl_desc_list.id = softw_id_list.id)
             INNER JOIN (SELECT column_value, rownum AS id
                           FROM TABLE(tn_id_sysalert_all)) alert_id_list
                ON (alert_id_list.id = softw_id_list.id)
             INNER JOIN (SELECT column_value, rownum AS id
                           FROM TABLE(tv_desc_sysalert_all)) alert_desc_list
                ON (alert_desc_list.id = softw_id_list.id)
             GROUP BY softw_id_list.column_value,
                      profl_id_list.column_value,
                      alert_id_list.column_value,
                      softw_desc_list.column_value,
                      profl_desc_list.column_value,
                      alert_desc_list.column_value
             ORDER BY softw_desc_list.column_value, profl_desc_list.column_value, alert_desc_list.column_value;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_serv_alert;
    /********************************************************************************************
    * Set prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION set_prof_serv_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_service         IN table_number,
        i_institution     IN department.id_institution%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_flg_change      IN table_varchar,
        i_flg_change_prof IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_list  table_number := table_number();
        l_software_list table_number := table_number();
        l_dept_sw_list  table_number := table_number();
        l_error         t_error_out;
        l_alert_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_prof_serv_alert');
        IF i_flg_change_prof = g_flg_available
        THEN
            FOR sv IN 1 .. i_service.count
            LOOP
            
                g_error        := 'GET DEPARTMENT SOFTWARE CONFIGURATION';
                l_dept_sw_list := get_dept_software(i_lang, NULL, i_service(sv), o_error);
            
                g_error := 'GET PROFESSIONAL PROFILES';
                SELECT ppt.id_profile_template, ppt.id_software
                  BULK COLLECT
                  INTO l_profile_list, l_software_list
                  FROM prof_profile_template ppt
                 WHERE ppt.id_professional = i_id_prof
                   AND ppt.id_institution = i_institution
                   AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                            column_value
                                             FROM TABLE(CAST(l_dept_sw_list AS table_number)) p)
                   AND EXISTS (SELECT 0
                          FROM profile_template pt
                         WHERE pt.id_profile_template = ppt.id_profile_template
                           AND pt.id_software = ppt.id_software
                           AND pt.flg_available = g_flg_available);
                IF i_flg_change(sv) = g_flg_available
                THEN
                    FOR pt IN 1 .. l_profile_list.count
                    LOOP
                        g_error := 'DELETE PROFESSIONAL ALERT LIST';
                        IF NOT pk_access.del_prof_alerts(i_lang,
                                                         profissional(i_id_prof, i_institution, l_software_list(pt)),
                                                         l_profile_list(pt),
                                                         l_error)
                        THEN
                            g_error := 'ERROR DELETING ALERT LIST';
                            RAISE l_alert_exception;
                        END IF;
                    
                        g_error := 'INSERT PROFESSIONAL ALERT LIST';
                        IF NOT pk_access.set_prof_alerts(i_lang,
                                                         profissional(i_id_prof, i_institution, l_software_list(pt)),
                                                         l_profile_list(pt),
                                                         i_service(sv),
                                                         l_error)
                        THEN
                            g_error := 'ERROR DELETING ALERT LIST';
                            RAISE l_alert_exception;
                        END IF;
                    
                    END LOOP;
                ELSE
                    FOR pt IN 1 .. l_profile_list.count
                    LOOP
                        g_error := 'DELETE PROFESSIONAL ALERT LIST';
                        IF NOT pk_access.del_prof_alerts(i_lang,
                                                         profissional(i_id_prof, i_institution, l_software_list(pt)),
                                                         l_profile_list(pt),
                                                         l_error)
                        THEN
                            g_error := 'ERROR DELETING ALERT LIST';
                            RAISE l_alert_exception;
                        END IF;
                    
                        g_error := 'INSERT PROFESSIONAL ALERT LIST';
                        IF NOT pk_access.set_prof_alerts(i_lang,
                                                         profissional(i_id_prof, i_institution, l_software_list(pt)),
                                                         l_profile_list(pt),
                                                         NULL,
                                                         l_error)
                        THEN
                            g_error := 'ERROR DELETING ALERT LIST';
                            RAISE l_alert_exception;
                        END IF;
                    
                    END LOOP;
                END IF;
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
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_prof_serv_alert;
    /********************************************************************************************
    * Set prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_result_count           Number of profiles count
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION check_prof_profile
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN department.id_institution%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_service      IN table_number,
        i_flg_change   IN table_varchar,
        o_result_count OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile_list             table_number := table_number();
        l_sw_list                  table_number := table_number();
        l_shared_profile_serv_list table_number := table_number();
    
        l_valid_config   NUMBER := 1;
        l_invalid_config NUMBER := 0;
    
        l_serv_config_count  NUMBER := 0;
        l_overall_serv_count NUMBER := 0;
    BEGIN
    
        FOR sv IN 1 .. i_service.count
        LOOP
            g_error   := 'GET SERVICE ' || i_service(sv) || '/ DEPT SOFTWARE LIST';
            l_sw_list := pk_backoffice_alert.get_dept_software(i_lang, NULL, i_service(sv), o_error);
        
            g_error := 'GET PROFESSIONAL ' || i_id_prof || ' PROFILE TEMPLATE LIST RELATED TO SERVICE SOFTWARE LIST ' ||
                       i_service(sv);
            SELECT ppt.id_profile_template
              BULK COLLECT
              INTO l_profile_list
              FROM prof_profile_template ppt
             INNER JOIN profile_template pt
                ON (pt.id_profile_template = ppt.id_profile_template AND pt.id_software = ppt.id_software)
             WHERE ppt.id_professional = i_id_prof
               AND ppt.id_institution = i_institution
               AND ppt.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                        column_value
                                         FROM TABLE(CAST(l_sw_list AS table_number)) p);
        
            g_error := 'GET SERVICES THAT ARE SHARING PROFILE CONFIGURATION ' || i_service(sv);
            SELECT serv.id_department
              BULK COLLECT
              INTO l_shared_profile_serv_list
              FROM department serv
             WHERE serv.flg_available = g_flg_available
               AND serv.id_institution = i_institution
               AND EXISTS
             (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                     INNER JOIN dep_clin_serv dcs
                        ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_flg_available)
                     INNER JOIN department sv
                        ON (sv.id_department = dcs.id_department AND sv.flg_available = g_flg_available)
                     INNER JOIN clinical_service cs
                        ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_flg_available)
                     WHERE pdcs.id_professional = i_id_prof
                       AND dcs.id_department = serv.id_department)
               AND EXISTS
             (SELECT 0
                      FROM software_dept sd
                     INNER JOIN profile_template pt
                        ON (pt.id_software = sd.id_software)
                     WHERE sd.id_dept = serv.id_dept
                       AND sd.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                               column_value
                                                FROM TABLE(CAST(l_sw_list AS table_number)) p)
                       AND EXISTS (SELECT 0
                              FROM prof_profile_template ppt
                             WHERE ppt.id_profile_template = pt.id_profile_template
                               AND ppt.id_software = pt.id_software
                               AND ppt.id_professional = i_id_prof
                               AND ppt.id_institution = i_institution))
               AND NOT EXISTS (SELECT 0
                      FROM (SELECT column_value, rownum AS id
                              FROM TABLE(i_service)) service_id_list
                     INNER JOIN (SELECT column_value, rownum AS id
                                  FROM TABLE(i_flg_change)) flg_change_list
                        ON (flg_change_list.id = service_id_list.id)
                     WHERE flg_change_list.column_value = 'N'
                       AND service_id_list.column_value = serv.id_department);
        
            IF i_flg_change(sv) = g_flg_available
            THEN
                IF l_profile_list.count > l_invalid_config
                THEN
                    l_serv_config_count := l_valid_config;
                ELSE
                    l_serv_config_count := l_invalid_config;
                END IF;
            
            ELSE
                IF (l_profile_list.count > l_invalid_config AND l_shared_profile_serv_list.count > l_invalid_config)
                THEN
                    l_serv_config_count := l_valid_config;
                ELSE
                    l_serv_config_count := l_invalid_config;
                END IF;
            END IF;
            l_overall_serv_count := l_overall_serv_count + l_serv_config_count;
        END LOOP;
        o_result_count := l_overall_serv_count;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_prof_profile;
    /********************************************************************************************
    * Delete temporary Alerts config for the service
    *
    * @param i_lang                   Language ID
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/19
    **********************************************************************************************/
    FUNCTION delete_service_temp_alert
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN department.id_department%TYPE,
        i_institution IN department.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_delete_cfg NUMBER := 0;
    BEGIN
        SELECT COUNT(*)
          INTO l_delete_cfg
          FROM stg_sys_alert_department ssad
         WHERE ssad.id_department = i_service
           AND ssad.id_institution = i_institution;
    
        IF l_delete_cfg > 0
        THEN
            DELETE FROM stg_sys_alert_department ssad
             WHERE ssad.id_department = i_service
               AND ssad.id_institution = i_institution;
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
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END delete_service_temp_alert;
    /********************************************************************************************
    * Check if professioanl associations have permissions to choose alerts
    *
    * @param i_lang                   Language ID
    * @param i_id_profissional        Professional ID   
    * @param i_institution            Institution ID
    * @param o_result                 Number of Results availabel (0 list not available, > 0 list ok)
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/20
    **********************************************************************************************/
    FUNCTION validate_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN professional.id_professional%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_result          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function_name := upper('validate_alerts');
        g_error         := 'GET RESULTS IF PROFESSIONAL CAN BE ASSOCIATED TO AN ALERT';
        SELECT COUNT(*)
          INTO o_result
          FROM prof_profile_template ppt
         INNER JOIN profile_template pt
            ON (pt.id_profile_template = ppt.id_profile_template AND pt.flg_available = g_flg_available)
         WHERE ppt.id_professional = i_id_profissional
           AND ppt.id_institution = i_institution
           AND EXISTS (SELECT 0
                  FROM software s
                 WHERE s.id_software = ppt.id_software
                   AND s.flg_viewer != g_flg_available)
           AND EXISTS (SELECT 0
                  FROM sys_alert_config sac
                 WHERE sac.id_profile_template = ppt.id_profile_template
                   AND sac.id_software IN (0, ppt.id_software)
                   AND sac.id_institution IN (0, ppt.id_institution));
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_alerts;
    /********************************************************************************************
    * Check if professioanl associations have permissions to choose functionalities
    *
    * @param i_lang                   Language ID
    * @param i_id_profissional        Professional ID   
    * @param i_institution            Institution ID
    * @param o_result                 Number of Results availabel (0 list not available, > 0 list ok)
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/20
    **********************************************************************************************/
    FUNCTION validate_functs
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN professional.id_professional%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_result          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function_name := upper('validate_functs');
        g_error         := 'GET RESULTS IF PROFESSIONAL CAN BE ASSOCIATED TO A FUNCTIONALITY';
        SELECT COUNT(*)
          INTO o_result
          FROM prof_soft_inst psi
         WHERE psi.id_professional = i_id_profissional
           AND psi.id_institution = i_institution
           AND EXISTS (SELECT 0
                  FROM software s
                 WHERE s.id_software = psi.id_software
                   AND s.flg_viewer != g_flg_available)
           AND EXISTS (SELECT 0
                  FROM sys_functionality sf
                 WHERE sf.id_software = psi.id_software
                   AND sf.flg_available = g_flg_available);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_functs;

BEGIN
    -- Initializes log context
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);
    g_flg_available := pk_alert_constant.get_available;

END pk_backoffice_alert;
/
