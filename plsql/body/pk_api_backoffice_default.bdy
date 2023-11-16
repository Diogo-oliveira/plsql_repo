/*-- Last Change Revision: $Rev: 2026664 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:30 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_backoffice_default IS
    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_API_BACKOFFICE_DEFAULT';
    g_func_name     VARCHAR2(500);
    g_table_name    VARCHAR2(500) := '';
    /*
    * PROCESS ERRORS
    */
    PROCEDURE process_error
    (
        i_pckg  IN alert_default.logs.package%TYPE,
        i_funct IN alert_default.logs.funtion%TYPE
    ) IS
    
    BEGIN
        g_func_name := upper('');
        DELETE FROM alert_default.logs;
    
        INSERT INTO alert_default.logs
            (id_log, RESULT, PACKAGE, funtion)
        VALUES
            (alert_default.seq_logs.nextval, 0, i_pckg, i_funct);
        COMMIT;
    END process_error;

    /********************************************************************************************
    * Set EXAMS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_exams
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_exam_cat          OUT table_number,
        o_exams             OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_inst_exams pk_types.cursor_type;
        -->Freqs
        l_c_exams    pk_types.cursor_type;
        l_c_exam_cat pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_result NUMBER := 0;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT EXAM CATEGORIES';
            IF NOT pk_default_content.set_def_exam_categories(i_lang, o_exam_cat, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT EXAMS';
            IF NOT pk_default_content.set_def_exams(i_lang, o_exams, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT EXAMS COMPLAINT';
            IF NOT pk_default_content.load_exam_complaint_def(i_lang, l_result, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                    
                        g_error := 'SET INSTITUTION EXAMS';
                        IF NOT pk_backoffice_default.set_inst_exams(i_lang,
                                                                    table_number(i_market(j)),
                                                                    table_varchar(i_version(i)),
                                                                    i_id_institution,
                                                                    table_number(i_software(k)),
                                                                    l_c_inst_exams,
                                                                    l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END LOOP;
                END IF;
            
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                            g_error := 'SET MOST FREQUENT EXAMS';
                            IF NOT pk_default_inst_preferences.set_inst_exams_freq(i_lang,
                                                                                   i_market(j),
                                                                                   i_version(i),
                                                                                   i_id_institution,
                                                                                   i_software(k),
                                                                                   l_id_clinical_service,
                                                                                   i_id_dep_clin_serv,
                                                                                   l_c_exams,
                                                                                   o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            g_error := 'SET MOST FREQUENT EXAM CATEGORIES';
                            IF NOT pk_default_inst_preferences.set_inst_exam_cat_freq(i_lang,
                                                                                      i_market(j),
                                                                                      i_version(i),
                                                                                      l_id_clinical_service,
                                                                                      i_id_dep_clin_serv,
                                                                                      l_c_exam_cat,
                                                                                      o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        END IF;
                    
                    END LOOP;
                    --> MyPreferences by all Clinical Services
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                                g_error := 'SET MOST FREQUENT EXAMS';
                                IF NOT pk_default_inst_preferences.set_inst_exams_freq(i_lang,
                                                                                       i_market(j),
                                                                                       i_version(i),
                                                                                       i_id_institution,
                                                                                       i_software(k),
                                                                                       l_id_clinical_service,
                                                                                       i_id_dep_clin_serv_all,
                                                                                       l_c_exams,
                                                                                       o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                                g_error := 'SET MOST FREQUENT EXAM CATEGORIES';
                                IF NOT pk_default_inst_preferences.set_inst_exam_cat_freq(i_lang,
                                                                                          i_market(j),
                                                                                          i_version(i),
                                                                                          l_id_clinical_service,
                                                                                          i_id_dep_clin_serv_all,
                                                                                          l_c_exam_cat,
                                                                                          o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            END IF;
                        
                        END LOOP;
                        g_error := 'CLOSE C_DEP_CLIN CURSOR';
                        CLOSE c_dep_clin;
                    END LOOP;
                
                END IF; --<< end if my alerts
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_EXAMS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_EXAMS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_exams;
    /********************************************************************************************
    * Set INTERVENTIONS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_interventions
    (
        i_lang                  IN language.id_language%TYPE,
        i_content_universe      IN VARCHAR2 DEFAULT 'N',
        i_market                IN table_number,
        i_version               IN table_varchar,
        i_id_institution        IN institution.id_institution%TYPE,
        i_software              IN table_number,
        i_pesquisaveis          IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1     IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv      IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all     IN VARCHAR2 DEFAULT 'N',
        o_physiatry_area        OUT table_number,
        o_interv_physiatry_area OUT table_number,
        o_interv                OUT table_number,
        o_interv_cat            OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_c_inst_interv pk_types.cursor_type;
        l_c_interv      pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_result NUMBER := 0;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT PHYSIATRY_AREA';
            IF NOT pk_default_content.set_def_physiatry_area(i_lang, o_physiatry_area, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT INTERV_PHYSIATRY_AREA';
            IF NOT pk_default_content.set_def_interv_physiatry_area(i_lang, o_interv_physiatry_area, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT INTERVENTIONS';
            IF NOT pk_default_content.set_def_interventions(i_lang, o_interv, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        --> Pesquisáveis
        IF i_pesquisaveis = 'Y'
        THEN
        
            g_error := 'SET INSTITUTION INTERVENTIONS';
            IF NOT pk_backoffice_default.set_inst_interv_cat(i_lang,
                                                             i_market,
                                                             i_version,
                                                             i_id_institution,
                                                             i_software,
                                                             l_result,
                                                             l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET INSTITUTION INTERVENTIONS';
            IF NOT pk_backoffice_default.set_inst_interv(i_lang,
                                                         i_market,
                                                         i_version,
                                                         i_id_institution,
                                                         i_software,
                                                         l_c_inst_interv,
                                                         l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                        
                            g_error := 'SET MOST FREQUENT INTERVENTIONS';
                            IF NOT pk_default_inst_preferences.set_inst_interv_freq(i_lang,
                                                                                    i_market(j),
                                                                                    i_version(i),
                                                                                    i_id_institution,
                                                                                    i_software(k),
                                                                                    l_id_clinical_service,
                                                                                    i_id_dep_clin_serv,
                                                                                    l_c_interv,
                                                                                    o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    --> MyPreferences by all Clinical Services
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                            
                                g_error := 'SET MOST FREQUENT INTERVENTIONS';
                                IF NOT pk_default_inst_preferences.set_inst_interv_freq(i_lang,
                                                                                        i_market(j),
                                                                                        i_version(i),
                                                                                        i_id_institution,
                                                                                        i_software(k),
                                                                                        l_id_clinical_service,
                                                                                        i_id_dep_clin_serv_all,
                                                                                        l_c_interv,
                                                                                        o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                            END IF;
                        
                        END LOOP;
                        g_error := 'CLOSE C_DEP_CLIN CURSOR';
                        CLOSE c_dep_clin;
                    END LOOP;
                
                END IF; --<< end if my alerts
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_INTERVENTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_INTERVENTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_interventions;
    /********************************************************************************************
    * Set ANALYSIS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_content_universe       IN VARCHAR2 DEFAULT 'N',
        i_market                 IN table_number,
        i_version                IN table_varchar,
        i_id_institution         IN institution.id_institution%TYPE,
        i_software               IN table_number,
        i_pesquisaveis           IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1      IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all      IN VARCHAR2 DEFAULT 'N',
        o_analysis_parameters    OUT table_number,
        o_sample_types           OUT table_number,
        o_sample_rec             OUT table_number,
        o_exam_cat               OUT table_number,
        o_analysis               OUT table_number,
        o_analysis_res_calcs     OUT table_number,
        o_analysis_res_par_calcs OUT table_number,
        o_analysis_loinc         OUT table_number,
        o_analysis_desc          OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_c_inst_unit_measures  pk_types.cursor_type;
        l_c_inst_analysis       pk_types.cursor_type;
        l_c_inst_analysis_group pk_types.cursor_type;
    
        l_c_analysis   pk_types.cursor_type;
        l_c_labcol     pk_types.cursor_type;
        l_c_labcol_int pk_types.cursor_type;
    
        l_c_labt_st    pk_types.cursor_type;
        l_c_labt_bs    pk_types.cursor_type;
        l_c_labt_compl pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT ANALYSIS PARAMETERS';
            IF NOT pk_default_content.set_def_analysis_parameters(i_lang, o_analysis_parameters, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT SAMPLE TYPES';
            IF NOT pk_default_content.set_def_sample_types(i_lang, o_sample_types, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT SAMPLE RECIPIENTS';
            IF NOT pk_default_content.set_def_sample_recipients(i_lang, o_sample_rec, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT EXAM CATEGORIES';
            IF NOT pk_default_content.set_def_exam_categories(i_lang, o_exam_cat, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ANALYSIS';
            IF NOT pk_default_content.set_def_analysis(i_lang, o_analysis, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT LAB TEST SAMPLE TYPE';
            IF NOT pk_default_content.set_def_analysis_st(i_lang, l_c_labt_st, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ANALYSIS GROUPS';
            IF NOT pk_default_content.set_def_analysis_groups(i_lang, o_analysis, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ANALYSIS LOINCS';
            IF NOT pk_default_content.set_def_analysis_loinc(i_lang, o_analysis_loinc, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ANALYSIS DESC';
            IF NOT pk_default_content.set_def_analysis_desc(i_lang, o_analysis_desc, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            /*v263: ALERT-220404*/
        
            g_error := 'SET DEFAULT LAB TEST BODY STRUCTURE';
            IF NOT pk_default_content.set_def_analysis_bs(i_lang, l_c_labt_bs, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT LAB TEST COMPLAINT';
            IF NOT pk_default_content.set_def_analysis_complaint(i_lang, l_c_labt_compl, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            /*v2631: ALERT-248634*/
            g_error := 'SET DEFAULT ANALYSIS RES CALCULATORS';
            IF NOT pk_default_content.set_def_analysis_res_calcs(i_lang, o_analysis_res_calcs, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ANALYSIS RES PARAMETER CALCULATORS';
            IF NOT pk_default_content.set_def_analysis_res_par_calcs(i_lang, o_analysis_res_par_calcs, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    g_error := 'SET INSTITUTION UNIT MEASURES';
                    IF NOT pk_backoffice_default.set_inst_unit_measures(i_lang,
                                                                        table_number(i_market(j)),
                                                                        table_varchar(i_version(i)),
                                                                        i_id_institution,
                                                                        i_software,
                                                                        l_c_inst_unit_measures,
                                                                        l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION ANALYSIS';
                    IF NOT pk_backoffice_default.set_inst_analysis(i_lang,
                                                                   table_number(i_market(j)),
                                                                   table_varchar(i_version(i)),
                                                                   i_id_institution,
                                                                   i_software,
                                                                   l_c_inst_analysis,
                                                                   l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION ANALYSIS GROUPS';
                    IF NOT pk_backoffice_default.set_inst_analysis_group(i_lang,
                                                                         table_number(i_market(j)),
                                                                         table_varchar(i_version(i)),
                                                                         i_id_institution,
                                                                         i_software,
                                                                         l_c_inst_analysis_group,
                                                                         l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION ANALYSIS COLLECTION';
                    IF NOT pk_backoffice_default.set_inst_analysis_collection(i_lang,
                                                                              table_number(i_market(j)),
                                                                              table_varchar(i_version(i)),
                                                                              i_id_institution,
                                                                              i_software,
                                                                              l_c_labcol,
                                                                              l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION ANALYSIS COLLECTION INTERNAL';
                    IF NOT pk_backoffice_default.set_inst_lab_collection_int(i_lang,
                                                                             table_number(i_market(j)),
                                                                             table_varchar(i_version(i)),
                                                                             i_id_institution,
                                                                             i_software,
                                                                             l_c_labcol_int,
                                                                             l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF; --<< END IF - Pesquisáveis
            
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                        
                            g_error := 'SET MOST FREQUENT ANALYSIS';
                            IF NOT pk_default_inst_preferences.set_inst_analysis_freq(i_lang,
                                                                                      i_market(j),
                                                                                      i_version(i),
                                                                                      i_id_institution,
                                                                                      i_software(k),
                                                                                      l_id_clinical_service,
                                                                                      i_id_dep_clin_serv,
                                                                                      l_c_analysis,
                                                                                      o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    --> MyPreferences by all Clinical Services
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                                g_error := 'SET MOST FREQUENT ANALYSIS';
                                IF NOT pk_default_inst_preferences.set_inst_analysis_freq(i_lang,
                                                                                          i_market(j),
                                                                                          i_version(i),
                                                                                          i_id_institution,
                                                                                          i_software(k),
                                                                                          l_id_clinical_service,
                                                                                          i_id_dep_clin_serv_all,
                                                                                          l_c_analysis,
                                                                                          o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                            END IF;
                        
                        END LOOP;
                        g_error := 'CLOSE C_DEP_CLIN CURSOR';
                        CLOSE c_dep_clin;
                    END LOOP;
                
                END IF; --<< end if my alerts
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_ANALYSIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_ANALYSIS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_analysis;
    /********************************************************************************************
    * Set CLINICAL_SERVICE Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_clinical_service
    (
        i_lang              IN language.id_language%TYPE,
        o_clinical_services OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        --> Universos
        g_error := 'SET DEFAULT CLINICAL SERVICES';
        IF NOT pk_default_content.set_def_clinical_services(i_lang, o_clinical_services, l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_CLINICAL_SERVICE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_CLINICAL_SERVICE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_clinical_service;
    /********************************************************************************************
    * Set HEALTH_PLAN Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_health_plan
    (
        i_lang                 IN language.id_language%TYPE,
        o_health_plan_entities OUT table_number,
        o_health_plans         OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        --> Universos
        g_error := 'SET DEFAULT HEALTH PLANS';
        IF NOT pk_default_content.set_def_health_plans(i_lang, o_health_plan_entities, o_health_plans, l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HEALTH_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HEALTH_PLAN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_health_plan;
    /********************************************************************************************
    * Set HABITS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_habits
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_habits           OUT table_number,
        o_habits_char      OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        -->Pesq
        l_c_inst_habits    pk_types.cursor_type;
        l_a_habit_rel      table_number := table_number();
        l_a_habit_char_rel table_number := table_number();
    
    BEGIN
        g_func_name := upper('');
        --> Universos
        IF i_content_universe = 'Y'
        THEN
            g_error := 'SET DEFAULT HABITS';
            IF NOT pk_default_content.set_def_habits(i_lang, o_habits, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET DEFAULT HABITS CHARACTERIZATION';
            IF NOT pk_default_content.set_def_habits_charact(i_lang, o_habits_char, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        --> Pesquisáveis
        FOR i IN 1 .. i_version.count
        LOOP
            FOR j IN 1 .. i_market.count
            LOOP
                IF i_pesquisaveis = 'Y'
                THEN
                    g_error := 'SET INSTITUTION HABITS';
                    IF NOT pk_backoffice_default.set_inst_habits(i_lang,
                                                                 table_number(i_market(j)),
                                                                 table_varchar(i_version(i)),
                                                                 i_id_institution,
                                                                 l_c_inst_habits,
                                                                 l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                    g_error := 'SET INSTITUTION HABITS CHAR RELATION';
                    IF NOT pk_backoffice_default.set_inst_habit_char_rel(i_lang,
                                                                         i_market(j),
                                                                         i_version(i),
                                                                         l_a_habit_char_rel,
                                                                         l_a_habit_rel,
                                                                         l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HABITS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HABITS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_habits;
    /********************************************************************************************
    * Set SUPPLIES Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_supplies
    (
        i_lang     IN language.id_language%TYPE,
        o_supplies OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        --> Universos
        g_error := 'SET DEFAULT SUPPLIES';
        IF NOT pk_default_content.set_def_supplies(i_lang, o_supplies, l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_SUPPLIES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_SUPPLIES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_supplies;
    /********************************************************************************************
    * Set PROTOCOLS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_protocols
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_c_protocol pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                g_error := 'SET INSTITUTION PROTOCOLS';
                IF NOT pk_backoffice_default.set_inst_protocol(i_lang,
                                                               table_number(i_market(j)),
                                                               table_varchar(i_version(i)),
                                                               i_id_institution,
                                                               i_software,
                                                               l_c_protocol,
                                                               l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        
        END LOOP;
        pk_backoffice_default.orders_double_check(i_lang, i_id_institution, l_error_out);
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_PROTOCOLS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_PROTOCOLS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_protocols;
    /********************************************************************************************
    * Set GUIDELINES Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_guidelines
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_c_guideline pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                g_error := 'SET INSTITUTION GUIDELINES';
                IF NOT pk_backoffice_default.set_inst_guideline(i_lang,
                                                                table_number(i_market(j)),
                                                                table_varchar(i_version(i)),
                                                                i_id_institution,
                                                                i_software,
                                                                l_c_guideline,
                                                                l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        
        END LOOP;
        pk_backoffice_default.orders_double_check(i_lang, i_id_institution, l_error_out);
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_GUIDELINES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_GUIDELINES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_guidelines;
    /********************************************************************************************
    * Set ORDER_SETS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/28
    ********************************************************************************************/
    FUNCTION set_iso_order_sets
    (
        i_lang           IN language.id_language%TYPE,
        i_market         IN table_number,
        i_version        IN table_varchar,
        i_id_institution IN institution.id_institution%TYPE,
        i_software       IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_c_inst_order_set          pk_types.cursor_type;
        l_c_order_set_link          pk_types.cursor_type;
        l_c_order_set_task          pk_types.cursor_type;
        l_c_inst_order_set_frequent pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                g_error := 'SET_INST_ORDER_SET INSTITUTION';
                IF NOT pk_backoffice_default.set_inst_order_set(i_lang,
                                                                table_number(i_market(j)),
                                                                table_varchar(i_version(i)),
                                                                i_id_institution,
                                                                i_software,
                                                                l_c_inst_order_set,
                                                                l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'SET_INST_ORDER_SET_LINK INSTITUTION';
                IF NOT pk_backoffice_default.set_inst_order_set_link(i_lang,
                                                                     table_number(i_market(j)),
                                                                     table_varchar(i_version(i)),
                                                                     i_id_institution,
                                                                     i_software,
                                                                     l_c_order_set_link,
                                                                     l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'SET_INST_ORDER_SET_TASK INSTITUTION';
                IF NOT pk_backoffice_default.set_inst_order_set_task(i_lang,
                                                                     table_number(i_market(j)),
                                                                     table_varchar(i_version(i)),
                                                                     i_id_institution,
                                                                     i_software,
                                                                     l_c_order_set_task,
                                                                     l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'SET_INST_ORDER_SET_FREQUENT INSTITUTION';
                IF NOT pk_backoffice_default.set_inst_order_set_frequent(i_lang,
                                                                         table_number(i_market(j)),
                                                                         table_varchar(i_version(i)),
                                                                         i_id_institution,
                                                                         i_software,
                                                                         l_c_inst_order_set_frequent,
                                                                         l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        
        END LOOP;
        pk_backoffice_default.orders_double_check(i_lang, i_id_institution, l_error_out);
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_ORDER_SETS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_ORDER_SETS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_order_sets;

    /********************************************************************************************
    * Set Checklists Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/08
    ********************************************************************************************/
    FUNCTION set_iso_checklist
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_checklist        OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_inst_checklist pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT CHECKLIST';
            IF NOT pk_default_content.set_def_checklist(i_lang, o_checklist, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    g_error := 'SET INSTITUTION EXAMS';
                    IF NOT pk_backoffice_default.set_inst_checklist_inst(i_lang,
                                                                         table_number(i_market(j)),
                                                                         table_varchar(i_version(i)),
                                                                         i_id_institution,
                                                                         l_c_inst_checklist,
                                                                         l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_CHECKLIST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_CHECKLIST',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_checklist;
    /********************************************************************************************
    * Set External Medication Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/26
    ********************************************************************************************/
    FUNCTION set_iso_ext_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_inst_ext_med pk_types.cursor_type;
    
        -->Freqs
        l_c_ext_med pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'SET INSTITUTION EXTERNAL MEDICATION';
                        IF NOT pk_backoffice_default.set_inst_ext_med(i_lang,
                                                                      table_number(i_market(j)),
                                                                      table_varchar(i_version(i)),
                                                                      i_id_institution,
                                                                      table_number(i_software(k)),
                                                                      l_c_inst_ext_med,
                                                                      l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END LOOP;
                END IF;
            
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                            g_error := 'SET MOST FREQUENT EXT_MEDICATION';
                            IF NOT pk_default_inst_preferences.set_inst_ext_med_freq(i_lang,
                                                                                     i_market(j),
                                                                                     i_version(i),
                                                                                     i_id_institution,
                                                                                     i_software(k),
                                                                                     l_id_clinical_service,
                                                                                     i_id_dep_clin_serv,
                                                                                     l_c_ext_med,
                                                                                     o_error)
                            
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    --> MyPreferences by all Clinical Services
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                                g_error := 'SET MOST FREQUENT EXT_MEDICATION';
                                IF NOT pk_default_inst_preferences.set_inst_ext_med_freq(i_lang,
                                                                                         i_market(j),
                                                                                         i_version(i),
                                                                                         i_id_institution,
                                                                                         i_software(k),
                                                                                         l_id_clinical_service,
                                                                                         i_id_dep_clin_serv_all,
                                                                                         l_c_ext_med,
                                                                                         o_error)
                                
                                THEN
                                    RAISE l_exception;
                                END IF;
                            END IF;
                        END LOOP;
                        g_error := 'CLOSE C_DEP_CLIN CURSOR';
                        CLOSE c_dep_clin;
                    END LOOP;
                
                END IF; --<< end if my alerts
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_EXT_MEDICATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_EXT_MEDICATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_ext_medication;
    /********************************************************************************************
    * Set Hidrics Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/13
    ********************************************************************************************/
    FUNCTION set_iso_hidrics
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_hidrics          OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --> universes
        l_c_hidrics_device pk_types.cursor_type;
        l_c_hidrics_o_tp   pk_types.cursor_type;
        -->Pesq
        l_c_inst_hidrics               pk_types.cursor_type;
        l_c_inst_hidrics_device_rel    pk_types.cursor_type;
        l_c_inst_hidrics_occurs_tp_rel pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT HIDRICS';
            IF NOT pk_default_content.set_def_hidrics(i_lang, o_hidrics, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET HIDRICS DEVICE CONTENT';
            IF NOT pk_default_content.set_def_hidrics_device(i_lang, l_c_hidrics_device, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET HIDRICS OCCURS TYPE CONTENT';
            IF NOT pk_default_content.set_def_hidrics_occurs_type(i_lang, l_c_hidrics_o_tp, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'SET INSTITUTION HIDRICS';
                        IF NOT pk_backoffice_default.set_inst_hidrics(i_lang,
                                                                      table_number(i_market(j)),
                                                                      table_varchar(i_version(i)),
                                                                      i_id_institution,
                                                                      table_number(i_software(k)),
                                                                      l_c_inst_hidrics,
                                                                      l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        g_error := 'SET SET_INST_HIDRICS_DEVICE_REL INSTITUTION';
                        IF NOT pk_backoffice_default.set_inst_hidrics_device_rel(i_lang,
                                                                                 table_number(i_market(j)),
                                                                                 table_varchar(i_version(i)),
                                                                                 i_id_institution,
                                                                                 l_c_inst_hidrics_device_rel,
                                                                                 o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        g_error := 'SET SET_INST_HIDRICS_OCCURS_TYPE_REL INSTITUTION';
                        IF NOT pk_backoffice_default.set_inst_hidrics_occurs_tp_rel(i_lang,
                                                                                    table_number(i_market(j)),
                                                                                    table_varchar(i_version(i)),
                                                                                    i_id_institution,
                                                                                    l_c_inst_hidrics_occurs_tp_rel,
                                                                                    o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END LOOP;
                END IF;
            
            END LOOP;
        
        END LOOP;
        g_error := 'CHECK PROGRESS NOTES AND CPOE RELATIONS WITH I/O';
        pk_def_cpoe_out.set_cpoe_hidric_references();
        pk_def_prog_notes_out.update_button_hidrics_ref();
        pk_task_type.set_tt_hidric_references();
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HIDRICS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_HIDRICS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_hidrics;
    /********************************************************************************************
    * Set new MFR Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.3.3
    * @since                       2010/09/27
    ********************************************************************************************/
    FUNCTION set_iso_rehabilitation
    (
        i_lang               IN language.id_language%TYPE,
        i_content_universe   IN VARCHAR2 DEFAULT 'N',
        i_market             IN table_number,
        i_version            IN table_varchar,
        i_id_institution     IN institution.id_institution%TYPE,
        i_software           IN table_number,
        i_pesquisaveis       IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1  IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all  IN VARCHAR2 DEFAULT 'N',
        o_rehab_area         OUT table_number,
        o_rehab_session_type OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_rehab_area_interv pk_types.cursor_type;
        l_c_rehab_inst_soft   pk_types.cursor_type;
        l_c_rdcs              pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_id_institution institution.id_institution%TYPE;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT REHAB_AREA';
            IF NOT pk_default_content.set_def_rehab_area(i_lang, o_rehab_area, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT REHAB_SESSION_TYPE';
            IF NOT pk_default_content.set_def_rehab_session_type(i_lang, o_rehab_session_type, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        IF i_software(k) != 0
                        THEN
                            SELECT nvl((SELECT si.id_software_institution
                                         FROM software_institution si
                                        WHERE si.id_institution = i_id_institution
                                          AND si.id_software = i_software(k)
                                          AND rownum = 1),
                                       0)
                              INTO l_id_institution
                              FROM dual;
                        ELSE
                            l_id_institution := i_id_institution;
                        END IF;
                    
                        IF l_id_institution != 0
                        THEN
                        
                            g_error := 'SET SET_INST_REHAB_AREA_INTERV';
                            IF NOT pk_backoffice_default.set_inst_rehab_area_interv(i_lang,
                                                                                    table_number(i_market(j)),
                                                                                    table_varchar(i_version(i)),
                                                                                    i_id_institution,
                                                                                    l_c_rehab_area_interv,
                                                                                    o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            g_error := 'SET SET_INST_REHAB_INST_SOFT';
                            IF NOT pk_backoffice_default.set_inst_rehab_inst_soft(i_lang,
                                                                                  table_number(i_market(j)),
                                                                                  table_varchar(i_version(i)),
                                                                                  i_id_institution,
                                                                                  table_number(i_software(k)),
                                                                                  l_c_rehab_inst_soft,
                                                                                  o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                        ELSE
                            g_error := 'MISSING SOFTWARE_INSTITUTION CONFIGURATION';
                        END IF;
                    
                    END LOOP;
                END IF;
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                        
                            g_error := 'SET MOST FREQUENT';
                            IF NOT pk_default_inst_preferences.set_inst_rehab_st_freq(i_lang,
                                                                                      i_market(j),
                                                                                      i_version(i),
                                                                                      i_id_institution,
                                                                                      i_software(k),
                                                                                      l_id_clinical_service,
                                                                                      i_id_dep_clin_serv,
                                                                                      l_c_rdcs,
                                                                                      o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                        END IF;
                    
                    END LOOP;
                
                    --> MyPreferences by all Clinical Services
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                    
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                                g_error := 'SET MOST FREQUENT';
                                IF NOT pk_default_inst_preferences.set_inst_rehab_st_freq(i_lang,
                                                                                          i_market(j),
                                                                                          i_version(i),
                                                                                          i_id_institution,
                                                                                          i_software(k),
                                                                                          l_id_clinical_service,
                                                                                          i_id_dep_clin_serv_all,
                                                                                          l_c_rdcs,
                                                                                          o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            
                            END IF;
                        
                        END LOOP;
                        g_error := 'CLOSE C_DEP_CLIN CURSOR';
                        CLOSE c_dep_clin;
                    END LOOP;
                
                END IF;
            
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_REHABILITATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_REHABILITATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_rehabilitation;
    /********************************************************************************************
    * Set new BODY_STRUCTURE Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/10/08
    ********************************************************************************************/
    FUNCTION set_iso_body_structure
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_body_structure    OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_exam_body_structure pk_types.cursor_type;
        o_body_structure_freq   pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_id_institution institution.id_institution%TYPE;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT BODY_STRUCTURE';
            IF NOT pk_default_content.set_def_body_structure(i_lang, o_body_structure, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                
                    g_error := 'SET SET_INST_EXAM_BODY_STRUCTURE';
                    IF NOT pk_backoffice_default.set_inst_exam_body_structure(i_lang,
                                                                              table_number(i_market(j)),
                                                                              table_varchar(i_version(i)),
                                                                              l_c_exam_body_structure,
                                                                              o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
                --> MyPreferences by 1 Clinical Service
                IF i_mypreferences_by1 = 'Y'
                   AND i_id_dep_clin_serv IS NOT NULL
                   AND i_mypreferences_all = 'N'
                THEN
                
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                        SELECT nvl((SELECT acs.id_clinical_service
                                     FROM dep_clin_serv dcs
                                     JOIN department d
                                       ON d.id_department = dcs.id_department
                                      AND d.id_institution = i_id_institution
                                     JOIN clinical_service cs
                                       ON cs.id_clinical_service = dcs.id_clinical_service
                                     JOIN alert_default.clinical_service acs
                                       ON acs.id_content = cs.id_content
                                    WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                                      AND rownum = 1),
                                   0)
                          INTO l_id_clinical_service
                          FROM dual;
                    
                        IF l_id_clinical_service != 0
                        THEN
                        
                            g_error := 'SET SET_INST_BODY_STRUCTURE_FREQ';
                            IF NOT pk_default_inst_preferences.set_inst_body_structure_freq(i_lang,
                                                                                            i_market(j),
                                                                                            i_version(i),
                                                                                            i_id_institution,
                                                                                            i_software(k),
                                                                                            l_id_clinical_service,
                                                                                            i_id_dep_clin_serv,
                                                                                            o_body_structure_freq,
                                                                                            o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        END IF;
                    
                    END LOOP;
                ELSIF i_mypreferences_by1 = 'N'
                      AND i_id_dep_clin_serv IS NULL
                      AND i_mypreferences_all = 'Y'
                THEN
                    FOR k IN 1 .. i_software.count
                    LOOP
                        g_error := 'OPEN C_DEP_CLIN CURSOR';
                    
                        OPEN c_dep_clin(i_id_institution, i_software(k));
                        LOOP
                            FETCH c_dep_clin
                                INTO i_id_dep_clin_serv_all;
                            EXIT WHEN c_dep_clin%NOTFOUND;
                        
                            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                            SELECT nvl((SELECT acs.id_clinical_service
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON d.id_department = dcs.id_department
                                          AND d.id_institution = i_id_institution
                                         JOIN clinical_service cs
                                           ON cs.id_clinical_service = dcs.id_clinical_service
                                         JOIN alert_default.clinical_service acs
                                           ON acs.id_content = cs.id_content
                                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                          AND rownum = 1),
                                       0)
                              INTO l_id_clinical_service
                              FROM dual;
                        
                            IF l_id_clinical_service != 0
                            THEN
                            
                                g_error := 'SET SET_INST_BODY_STRUCTURE_FREQ';
                                IF NOT pk_default_inst_preferences.set_inst_body_structure_freq(i_lang,
                                                                                                i_market(j),
                                                                                                i_version(i),
                                                                                                i_id_institution,
                                                                                                i_software(k),
                                                                                                l_id_clinical_service,
                                                                                                i_id_dep_clin_serv_all,
                                                                                                o_body_structure_freq,
                                                                                                o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            END IF;
                        END LOOP;
                        CLOSE c_dep_clin;
                    END LOOP;
                END IF;
            
            END LOOP;
        
        END LOOP;
    
        g_error := 'SET BODY STRUCTURE RELATION + SYS_CONFIG';
        IF NOT pk_exam_utils.create_body_struct_rel(i_lang               => i_lang,
                                                    i_prof               => profissional(0, i_id_institution, 0),
                                                    i_mcs_concept        => NULL,
                                                    i_mcs_concept_parent => NULL,
                                                    o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_BODY_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_BODY_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_body_structure;
    /******************************************************
    * Merges a record into clinical_service table         *
    *                                                     *
    * @param l_id_clinical_service_par    parent_id       *
    * @param l_cs_id_content              id_content      *
    *                                                     *
    ******************************************************/
    PROCEDURE insert_into_clinical_service
    (
        l_id_clinical_service_par IN clinical_service.id_clinical_service_parent%TYPE DEFAULT NULL,
        l_cs_id_content           IN clinical_service.id_content%TYPE,
        i_lang                    IN language.id_language%TYPE DEFAULT NULL,
        i_descr                   IN translation.desc_lang_1%TYPE DEFAULT NULL,
        only_this                 IN VARCHAR2 DEFAULT 'Y'
    ) IS
    
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_count               NUMBER := 0;
    
        l_c_appointments pk_types.cursor_type;
        l_error          t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        g_error     := 'COUNT EXISTING CLINICAL SERVICE IDs';
        SELECT COUNT(cs.id_clinical_service)
          INTO l_count
          FROM clinical_service cs
         WHERE cs.id_content = l_cs_id_content
           AND cs.id_content IS NOT NULL
           AND cs.flg_available = g_flg_available;
    
        IF l_count = 0
        THEN
            g_error := 'GET SEQ_CLINICAL_SERVICE.NEXTVAL';
            SELECT seq_clinical_service.nextval
              INTO l_id_clinical_service
              FROM dual;
        
            g_error := 'INSERT INTO CLINICAL_SERVICE';
            INSERT INTO clinical_service
                (id_clinical_service,
                 id_clinical_service_parent,
                 code_clinical_service,
                 image_name,
                 rank,
                 flg_available,
                 id_content)
            VALUES
                (l_id_clinical_service,
                 decode(l_id_clinical_service_par, 0, NULL, l_id_clinical_service_par),
                 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_id_clinical_service,
                 NULL,
                 10,
                 g_flg_available,
                 l_cs_id_content);
        
            --> Traduções
            IF i_lang IS NOT NULL
               AND i_descr IS NOT NULL
            THEN
                g_error := 'INSERT_INTO_TRANSLATION CLINICAL_SERVICE';
                pk_translation.insert_into_translation(i_lang,
                                                       'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                       l_id_clinical_service,
                                                       i_descr);
            END IF;
        ELSE
            g_error := 'GET ALERT CLINICAL SERVICE ID';
            SELECT nvl((SELECT cs.id_clinical_service
                         FROM clinical_service cs
                        WHERE cs.id_content = l_cs_id_content
                          AND cs.id_content IS NOT NULL
                          AND cs.flg_available = g_flg_available
                          AND rownum = 1),
                       0)
              INTO l_id_clinical_service
              FROM dual;
        
            IF i_lang IS NOT NULL
               AND i_descr IS NOT NULL
            THEN
                IF pk_backoffice_default.check_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           l_id_clinical_service) = 0
                THEN
                    g_error := 'INSERT_INTO_TRANSLATION CLINICAL_SERVICE';
                    pk_translation.insert_into_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           l_id_clinical_service,
                                                           i_descr);
                END IF;
            END IF;
        END IF;
    
        -->check_appointment
        IF only_this = 'Y'
        THEN
            g_error := 'CHECK_APPOINTMENT - ONLY=Y';
            IF NOT pk_default_content.set_appointments(i_lang                => i_lang,
                                                       i_id_clinical_service => l_id_clinical_service,
                                                       o_appointments        => l_c_appointments,
                                                       o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --<
    END;
    /******************************************************
    * Merges a record into appointment table              *
    *                                                     *
    * @param l_id_clinical_service  clinical_service_id   *
    * @param l_id_sch_event         sch_event_id          *
    *                                                     *
    ******************************************************/
    PROCEDURE insert_into_appointment
    (
        l_id_clinical_service IN appointment.id_clinical_service%TYPE,
        l_id_sch_event        IN appointment.id_sch_event%TYPE
    ) IS
    
        l_id_appointment   appointment.id_appointment%TYPE;
        l_code_appointment appointment.code_appointment%TYPE;
    
        TYPE ref_cursor1 IS REF CURSOR;
        transl_cursor1 ref_cursor1;
    
        TYPE ref_cursor2 IS REF CURSOR;
        transl_cursor2 ref_cursor2;
    
        l_desc_translation_cs  pk_translation.t_desc_translation;
        l_desc_translation_sch pk_translation.t_desc_translation;
    
        CURSOR c_langs IS
            SELECT t.id_language
              FROM LANGUAGE t;
    
    BEGIN
        g_func_name        := upper('');
        l_id_appointment   := 'APP.' || to_char(l_id_sch_event) || '.' || to_char(l_id_clinical_service);
        l_code_appointment := 'APPOINTMENT.CODE_APPOINTMENT.' || to_char(l_id_appointment);
    
        g_error := 'INSERT INTO APPOINTMENT';
        INSERT INTO appointment
            (id_appointment, id_clinical_service, id_sch_event, flg_available, code_appointment)
        VALUES
            (l_id_appointment, l_id_clinical_service, l_id_sch_event, g_flg_available, l_code_appointment);
    
        FOR i_lang IN c_langs
        LOOP
            OPEN transl_cursor1 FOR '
            SELECT t.desc_lang_' || i_lang.id_language || '
              FROM translation t
             WHERE t.code_translation = ''CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_id_clinical_service || chr(39) || ' and t.desc_lang_' || i_lang.id_language || ' is not null';
        
            LOOP
                g_error := 'FETCH TRANSL_CURSOR RESULTS';
                FETCH transl_cursor1
                    INTO l_desc_translation_cs;
                EXIT WHEN transl_cursor1%NOTFOUND;
            
                OPEN transl_cursor2 FOR '
                  SELECT t.desc_lang_' || i_lang.id_language || '
                    FROM translation t
                   WHERE t.code_translation = ''SCH_EVENT.CODE_SCH_EVENT.' || l_id_sch_event || chr(39) || ' and t.desc_lang_' || i_lang.id_language || ' is not null';
            
                LOOP
                    g_error := 'FETCH TRANSL_CURSOR RESULTS';
                    FETCH transl_cursor2
                        INTO l_desc_translation_sch;
                    EXIT WHEN transl_cursor2%NOTFOUND;
                
                    IF pk_backoffice_default.check_translation(i_lang.id_language, l_code_appointment) = 0
                    THEN
                        g_error := 'INSERT_INTO_TRANSLATION APPOINTMENT';
                        pk_translation.insert_into_translation(i_lang.id_language,
                                                               l_code_appointment,
                                                               l_desc_translation_sch || ': ' || l_desc_translation_cs);
                    END IF;
                
                END LOOP;
                g_error := 'CLOSE TRANSL_CURSOR2 CURSOR';
                CLOSE transl_cursor2;
            
            END LOOP;
            g_error := 'CLOSE TRANSL_CURSOR1 CURSOR';
            CLOSE transl_cursor1;
        
        END LOOP;
    END;
    /********************************************************************************************
    * Set Default Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION create_def_institutions
    (
        i_lang             IN language.id_language%TYPE,
        i_market           IN table_number,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_default_param    IN VARCHAR2 DEFAULT 'N',
        i_mypreferences    IN VARCHAR2 DEFAULT 'N',
        i_version          IN table_varchar,
        i_software         IN table_number,
        o_institution      OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->INSTITUTION_GROUP
        l_c_institution_grp table_number := table_number();
    
        -->INSTITUTION
        l_inst_type          institution.flg_type%TYPE;
        l_id_institution_def institution.id_institution%TYPE;
        l_id_institution     institution.id_institution%TYPE;
    
        l_c_sw_instit table_number := table_number();
        l_c_dept      table_number := table_number();
        l_c_lab_rooms table_number := table_number();
        l_c_buildings table_number := table_number();
    
        -->Structure
        l_c_floors table_number := table_number();
    
        -->Rooms pos-default
        l_c_exam_rooms     table_number := table_number();
        l_c_epis_type      table_number := table_number();
        l_c_analysis_quest table_number := table_number();
        l_c_room_quest     table_number := table_number();
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_count  NUMBER;
        l_count1 NUMBER;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv, dcs.id_clinical_service
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        --> Universos
        IF i_content_universe = 'Y'
        THEN
            g_error := 'SET DEFAULT CONTENT';
            IF NOT pk_api_backoffice_default.set_default_content(i_lang, i_content_universe, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        --> Instituição
        FOR k IN 1 .. i_software.count
        LOOP
            IF i_software(k) = 12
            THEN
                l_inst_type := 'P';
            ELSIF i_software(k) = 3
            THEN
                l_inst_type := 'C';
            ELSE
                l_inst_type := 'H';
            END IF;
        
            FOR j IN 1 .. i_market.count
            LOOP
            
                g_error := 'COUNT FOR EXISTING INSTITUTIONS FOR INDICATED MARKET';
                SELECT COUNT(i.id_institution)
                  INTO l_count1
                  FROM alert_default.institution i
                  JOIN alert_default.software_institution si
                    ON si.id_institution = i.id_institution
                   AND si.id_software = i_software(k)
                 WHERE i.id_market = i_market(j)
                   AND i.flg_type = l_inst_type;
            
                IF l_count1 != 0
                THEN
                    g_error := 'SET DEFAULT INSTITUITION by MARKET';
                    IF NOT set_def_institution(i_lang, l_inst_type, i_market(j), o_institution, l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'GET INSTITUTION ID and DEFAULT ID';
                    SELECT t.id_alert, t.id_default
                      INTO l_id_institution, l_id_institution_def
                      FROM alert_default.map_content t
                      JOIN institution i
                        ON i.id_institution = t.id_alert
                       AND i.id_market = i_market(j)
                     WHERE t.table_name = 'INSTITUTION'
                       AND rownum = 1;
                
                    -->First Verify if that institution has this software
                    g_error := 'COUNT FOR EXISTING SOFTWARE MATCH ON DEFAULT';
                    SELECT COUNT(si.id_software_institution)
                      INTO l_count
                      FROM alert_default.software_institution si
                     WHERE si.id_institution = l_id_institution_def
                       AND si.id_software = i_software(k);
                
                    IF l_count != 0
                    THEN
                        g_error := 'SET SOFTWARE_INSTITUTION by INSTITUITION';
                        IF NOT pk_api_backoffice_default.get_software_institution(i_lang,
                                                                                  l_id_institution_def,
                                                                                  i_software(k),
                                                                                  l_c_sw_instit,
                                                                                  l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        g_error := 'SET DEPTS and DEPARTMENTS by INSTITUITION';
                        IF NOT pk_api_backoffice_default.get_dept(i_lang,
                                                                  l_id_institution_def,
                                                                  i_software(k),
                                                                  l_c_dept,
                                                                  l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        --> Administrator USERS
                        g_error := 'SET BACKOFFICE ADMINISTRATORS by INSTITUITION';
                        IF NOT pk_api_backoffice_default.create_backoffice_adm(i_lang,
                                                                               i_market(j),
                                                                               l_id_institution,
                                                                               l_error_out)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                        FOR i IN 1 .. i_version.count
                        LOOP
                            --> Pesquisáveis
                            IF i_default_param = 'Y'
                            THEN
                                g_error := 'SET DEFAULT CONTENT FOR INSTITUTION';
                                IF NOT pk_backoffice_default.set_inst_default_param(i_lang,
                                                                                    table_number(i_market(j)),
                                                                                    table_varchar(i_version(i)),
                                                                                    l_id_institution,
                                                                                    table_number(i_software(k)),
                                                                                    table_varchar(),
                                                                                    l_error_out)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            END IF;
                        
                            --> My-ALerts
                            IF i_mypreferences = 'Y'
                            THEN
                            
                                OPEN c_dep_clin(l_id_institution, i_software(k));
                                LOOP
                                    FETCH c_dep_clin
                                        INTO i_id_dep_clin_serv_all, l_id_clinical_service;
                                    EXIT WHEN c_dep_clin%NOTFOUND;
                                
                                    g_error := 'SET FREQUENT DEFAULT CONTENT FOR INSTITUTION';
                                    IF NOT pk_default_inst_preferences.set_inst_default_param_freq(i_lang,
                                                                                                   i_market(j),
                                                                                                   i_version(i),
                                                                                                   i_software(k),
                                                                                                   l_id_clinical_service,
                                                                                                   i_id_dep_clin_serv_all,
                                                                                                   l_error_out)
                                    THEN
                                        RAISE l_exception;
                                    END IF;
                                
                                END LOOP;
                                g_error := 'CLOSE C_DEP_CLIN CURSOR';
                                CLOSE c_dep_clin;
                            END IF;
                        END LOOP;
                    END IF;
                    /* g_error := 'COUNT FOR EXISTING PREVIOUS SOFTWARE PARAMETRIZATION';
                    SELECT COUNT(si.id_software_institution)
                      INTO l_count1
                      FROM software_institution si
                     WHERE si.id_institution = l_id_institution;
                    
                    IF l_count1 = 0
                    THEN
                        pk_utils.undo_changes;
                        pk_alert_exceptions.reset_error_state;
                    
                        RETURN FALSE;
                    END IF;*/
                
                    g_error := 'SET DEFAULT INSTITUITION_GROUP';
                    IF NOT set_def_institution_group(i_lang, l_c_institution_grp, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET FISICAL STRUCTURE FOR DEF INSTITUITION ';
                    IF NOT pk_api_backoffice_default.get_fisical_structure(i_lang,
                                                                           l_id_institution,
                                                                           l_id_institution_def,
                                                                           l_c_floors,
                                                                           l_c_buildings,
                                                                           l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            END LOOP;
        END LOOP;
    
        --> Configurações Pós-DEFAULT
        g_error := 'SET ROOMS by INSTITUITION POS-DEFAULT';
        IF NOT pk_api_backoffice_default.set_rooms_pos_default(i_lang,
                                                               l_id_institution_def,
                                                               l_c_lab_rooms,
                                                               l_c_exam_rooms,
                                                               l_c_epis_type,
                                                               l_c_analysis_quest,
                                                               l_c_room_quest,
                                                               l_error_out)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DEF_INSTITUTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            pk_api_backoffice_default.process_error(g_package_name, 'CREATE_DEF_INSTITUTIONS');
        
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DEF_INSTITUTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            pk_api_backoffice_default.process_error(g_package_name, 'CREATE_DEF_INSTITUTIONS');
        
            RETURN FALSE;
        
    END create_def_institutions;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION get_software_institution
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution_def IN software_institution.id_institution%TYPE,
        i_id_software        IN software_institution.id_software%TYPE,
        o_sw_instit          OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index NUMBER := 1;
        l_count NUMBER := 0;
    
        --SOFTWARE_INSTITUTION
        l_id_software    software_institution.id_software%TYPE;
        l_id_institution institution.id_institution%TYPE;
        l_si_id          software_institution.id_software_institution%TYPE;
    
        CURSOR c_sw_instit
        (
            c_id_institution software_institution.id_institution%TYPE,
            c_id_software    software_institution.id_software%TYPE
        ) IS
            SELECT si.id_software
              FROM alert_default.software_institution si
             WHERE si.id_institution = c_id_institution
               AND si.id_software IN (c_id_software, 26, 51);
    
    BEGIN
        g_func_name := upper('');
        o_sw_instit := table_number();
    
        g_error := 'OPEN C_SW_INSTIT CURSOR';
        OPEN c_sw_instit(i_id_institution_def, i_id_software);
        LOOP
            FETCH c_sw_instit
                INTO l_id_software;
            EXIT WHEN c_sw_instit%NOTFOUND;
        
            g_error := 'GET INSTITUTION ID';
            SELECT nvl((SELECT t.id_alert
                         FROM alert_default.map_content t
                        WHERE t.id_default = i_id_institution_def
                          AND t.table_name = 'INSTITUTION'
                          AND rownum = 1),
                       0)
              INTO l_id_institution
              FROM dual;
        
            IF l_id_institution != 0
            THEN
            
                g_error := 'COUNT SOFTWARE_INSTITUTION EXISTING RESULTS';
                SELECT COUNT(si.id_software_institution)
                  INTO l_count
                  FROM software_institution si
                 WHERE si.id_institution = l_id_institution
                   AND si.id_software = l_id_software;
            
                IF l_count = 0
                THEN
                
                    g_error := 'INSERT INTO SOFTWARE_INSTITUTION';
                    pk_api_ab_tables.upd_ins_into_ab_software_inst(i_id_ab_software_institution => NULL,
                                                                   i_import_code                => NULL,
                                                                   i_record_status              => 'A',
                                                                   i_id_ab_institution          => l_id_institution,
                                                                   i_id_ab_software             => l_id_software,
                                                                   o_id_ab_software_institution => l_si_id);
                
                    o_sw_instit.extend;
                
                    o_sw_instit(l_index) := l_id_software;
                
                    l_index := l_index + 1;
                
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'CLOSE C_SW_INSTIT CURSOR';
        CLOSE c_sw_instit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SOFTWARE_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_software_institution;
    /********************************************************************************************
    * Set Default Fisical Structure Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID
    * @param i_lang                Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/10/25
    ********************************************************************************************/
    FUNCTION get_fisical_structure
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_institution_def IN institution.id_institution%TYPE,
        o_id_floors          OUT table_number,
        o_id_building        OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index1         NUMBER := 1;
        l_index2         NUMBER := 1;
        l_count          NUMBER := 0;
        l_count_building NUMBER := 0;
        l_count_trl      NUMBER := 0;
    
        --FLOORS_INSTITUTION
        l_id_floors_def        floors_institution.id_floors%TYPE;
        l_id_building_def1     floors_institution.id_building%TYPE;
        l_id_floors_instit_def floors_institution.id_floors_institution%TYPE;
        l_id_floors_instit     floors_institution.id_floors_institution%TYPE;
        --FLOORS
        l_id_floors         floors.id_floors%TYPE;
        l_floor_image_plant floors.image_plant%TYPE;
        l_floor_rank        floors.rank%TYPE;
        --TRANSLATION
        dml_errors EXCEPTION;
        --BUILDING
        l_id_building building.id_building%TYPE;
    
        l_market                  institution.id_market%TYPE;
        i_language                language.id_language%TYPE;
        i_country                 country_market.id_country%TYPE;
        i_id_institution_language institution_language.id_institution_language%TYPE;
    
        CURSOR c_floors_instit(c_id_institution floors_institution.id_institution%TYPE) IS
            SELECT fi.id_floors, fi.id_building, fi.id_floors_institution
              FROM alert_default.floors_institution fi
             WHERE fi.id_institution = c_id_institution
               AND fi.flg_available = g_flg_available;
    
        CURSOR c_floors(c_id_floors floors.id_floors%TYPE) IS
            SELECT f.image_plant, f.rank
              FROM alert_default.floors f
             WHERE f.id_floors = c_id_floors
               AND f.flg_available = g_flg_available;
    
    BEGIN
        g_func_name   := upper('');
        o_id_floors   := table_number();
        o_id_building := table_number();
    
        g_error := 'OPEN C_FLOORS_INSTIT CURSOR';
        OPEN c_floors_instit(i_id_institution_def);
        LOOP
            FETCH c_floors_instit
                INTO l_id_floors_def, l_id_building_def1, l_id_floors_instit_def;
            EXIT WHEN c_floors_instit%NOTFOUND;
            --> Floors
            g_error := 'OPEN C_FLOORS CURSOR';
            OPEN c_floors(l_id_floors_def);
            LOOP
                FETCH c_floors
                    INTO l_floor_image_plant, l_floor_rank;
                EXIT WHEN c_floors%NOTFOUND;
            
                SELECT seq_floors.nextval
                  INTO l_id_floors
                  FROM dual;
            
                g_error := 'INSERT INTO FLOORS';
                INSERT INTO floors
                    (id_floors, code_floors, image_plant, rank, flg_available, adw_last_update)
                VALUES
                    (l_id_floors,
                     'FLOORS.CODE_FLOORS.' || l_id_floors,
                     l_floor_image_plant,
                     l_floor_rank,
                     g_flg_available,
                     SYSDATE);
            
                --> Mapping
                g_table_name := 'FLOORS';
                pk_api_default.insert_into_map_content(g_table_name, l_id_floors_def, l_id_floors);
                -- 15/03/2011 - RMGM : changed way how translations are loaded
                g_error := 'SET DEF TRANSLATIONS';
                IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                THEN
                    RAISE dml_errors;
                END IF;
            
                o_id_floors.extend;
            
                o_id_floors(l_index1) := l_id_floors;
            
                l_index1 := l_index1 + 1;
            
            END LOOP;
            g_error := 'CLOSE C_FLOORS CURSOR';
            CLOSE c_floors;
        
            --> Buildings
            SELECT COUNT(mc.id_alert)
              INTO l_count_building
              FROM alert_default.map_content mc
             WHERE mc.table_name = 'BUILDING'
               AND mc.id_default = l_id_building_def1;
        
            IF l_count_building = 0
            THEN
                g_error := 'GET MAX ID_BUILDING';
                SELECT nvl(MAX(t.id_building) + 1, 0)
                  INTO l_id_building
                  FROM building t;
            
                g_error := 'INSERT INTO BUILDING';
                INSERT INTO building
                    (id_building, code_building, flg_available, adw_last_update)
                VALUES
                    (l_id_building, 'BUILDING.CODE_BUILDING.' || l_id_building, g_flg_available, SYSDATE);
            
                --> Mapping
                g_table_name := 'BUILDING';
                pk_api_default.insert_into_map_content(g_table_name, l_id_building_def1, l_id_building);
            
                -- 15/03/2011 - RMGM : changed way how translations are loaded;
                g_error := 'SET DEF TRANSLATIONS';
                IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                THEN
                    RAISE dml_errors;
                END IF;
            
                o_id_building.extend;
            
                o_id_building(l_index2) := l_id_building;
            
                l_index2 := l_index2 + 1;
            
            END IF;
        
            --> Floors Institution
            g_error := 'COUNT FLOORS_INSTITUTION';
            SELECT COUNT(fi.id_floors_institution)
              INTO l_count
              FROM floors_institution fi
             WHERE fi.id_institution = i_id_institution
               AND fi.id_floors = l_id_floors
               AND fi.id_building = l_id_building;
        
            IF l_count = 0
            THEN
                SELECT seq_floors_institution.nextval
                  INTO l_id_floors_instit
                  FROM dual;
                g_error := 'INSERT INTO FLOORS_INSTITUTION';
                INSERT INTO floors_institution
                    (id_floors_institution, id_floors, id_institution, flg_available, adw_last_update, id_building)
                VALUES
                    (l_id_floors_instit, l_id_floors, i_id_institution, g_flg_available, SYSDATE, l_id_building);
            
                --> Mapping
                pk_api_default.insert_into_map_content('FLOORS_INSTITUTION',
                                                       l_id_floors_instit_def,
                                                       l_id_floors_instit);
            END IF;
        END LOOP;
        g_error := 'CLOSE C_FLOORS_INSTIT CURSOR';
        CLOSE c_floors_instit;
    
        g_error := 'GET ID_MARKET FROM INSTITUTION';
        SELECT t.id_market
          INTO l_market
          FROM institution t
         WHERE t.id_institution = i_id_institution;
    
        -->
        CASE
            WHEN l_market = 1 THEN
                i_language := 1;
            WHEN l_market = 2 THEN
                i_language := 2;
            WHEN l_market = 3 THEN
                i_language := 11;
            WHEN l_market = 4 THEN
                i_language := 5;
            WHEN l_market = 5 THEN
                i_language := 4;
            WHEN l_market = 6 THEN
                i_language := 3;
            WHEN l_market = 7 THEN
                i_language := 10;
            WHEN l_market = 8 THEN
                i_language := 7;
            WHEN l_market = 9 THEN
                i_language := 6;
        END CASE;
    
        g_error := 'COUNT INSTITUTION_LANGUAGE';
        SELECT COUNT(t.id_institution_language)
          INTO l_count
          FROM institution_language t
         WHERE t.id_institution = i_id_institution;
    
        IF l_count = 0
        THEN
            SELECT seq_institution_language.nextval
              INTO i_id_institution_language
              FROM dual;
            g_error := 'INSERT INTO INSTITUTION_LANGUAGE';
            INSERT INTO institution_language
                (id_institution_language, id_language, id_institution, flg_available, adw_last_update)
            VALUES
                (i_id_institution_language, i_language, i_id_institution, g_flg_available, SYSDATE);
        END IF;
    
        g_error := 'GET COUNTRY_ID';
        SELECT t.id_country
          INTO i_country
          FROM country_market t
         WHERE t.id_market = l_market;
    
        g_error := 'COUNT INSTITUTION_ATTRIBUTES';
        SELECT COUNT(t.id_inst_attributes)
          INTO l_count
          FROM inst_attributes t
         WHERE t.id_institution = i_id_institution;
    
        IF l_count = 0
        THEN
            g_error := 'INSERT INTO INST_ATTRIBUTES';
            INSERT INTO inst_attributes
                (id_country,
                 id_city,
                 id_geo_location,
                 id_institution,
                 id_inst_attributes,
                 social_security_number,
                 adw_last_update,
                 geo_location_desc,
                 city_desc,
                 id_currency,
                 email,
                 license_model,
                 flg_available,
                 payment_schedule,
                 id_institution_language,
                 payment_options,
                 registration_details_pdf,
                 id_location_tax)
            VALUES
                (i_country,
                 NULL,
                 NULL,
                 i_id_institution,
                 seq_inst_attributes.nextval,
                 '',
                 SYSDATE,
                 '',
                 '',
                 NULL,
                 '',
                 '',
                 g_flg_available,
                 '',
                 i_id_institution_language,
                 '',
                 '',
                 NULL);
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
                                              'GET_FISICAL_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_fisical_structure;
    /********************************************************************************************
    * Set Default Backoffice Administrator Users Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID
    * @param i_lang                Institution ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION create_backoffice_adm
    (
        i_lang   IN language.id_language%TYPE,
        i_market IN institution.id_market%TYPE,
        i_instit IN institution.id_institution%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_count       NUMBER(24) := 0;
        l_count_users NUMBER;
    
        --> Professional Data
        i_prof             professional.id_professional%TYPE;
        i_pass             VARCHAR2(255);
        i_language         language.id_language%TYPE;
        l_market           institution.id_market%TYPE;
        i_profile_template profile_template.id_profile_template%TYPE;
        i_sw_backoffice    profile_template.id_software%TYPE := 26;
        i_category         profile_template.id_category%TYPE;
        --> new core data vars
        l_soft_inst_pk     ab_soft_inst_user_info.id_ab_software_institution%TYPE := NULL;
        l_role_sw_inst_pk  ab_soft_inst_user_info.id_ab_software_inst_role%TYPE := NULL;
        l_role_id          ab_soft_inst_user_info.id_ab_role%TYPE := NULL;
        l_comp_id         /*ab_soft_inst_user_info.id_ab_component%type*/
        VARCHAR2(200) := '';
        l_prof_institution prof_institution.id_prof_institution%TYPE := 0;
        l_si_user_info     NUMBER := 0;
    
    BEGIN
        g_func_name := upper('');
        l_market    := i_market;
    
        g_error := 'GET ID_MARKET FROM INSTITUTION';
        SELECT t.id_market
          INTO l_market
          FROM institution t
         WHERE t.id_institution = i_instit;
    
        CASE
            WHEN l_market = 1 THEN
                i_language := 1;
            WHEN l_market = 2 THEN
                i_language := 2;
            WHEN l_market = 3 THEN
                i_language := 11;
            WHEN l_market = 4 THEN
                i_language := 5;
            WHEN l_market = 5 THEN
                i_language := 4;
            WHEN l_market = 6 THEN
                i_language := 3;
            WHEN l_market = 7 THEN
                i_language := 10;
            WHEN l_market = 8 THEN
                i_language := 7;
            WHEN l_market = 9 THEN
                i_language := 6;
            WHEN l_market = 16 THEN
                i_language := 17;
            WHEN l_market = 12 THEN
                i_language := 16;
            WHEN l_market = 17 THEN
                i_language := 6;
        END CASE;
    
        CASE
            WHEN l_market != 4 THEN
                SELECT t.id_profile_template, t.id_category
                  INTO i_profile_template, i_category
                  FROM profile_template t
                 WHERE t.id_software = i_sw_backoffice
                   AND t.intern_name_templ = 'Administrador sistema ALERT';
            
            WHEN l_market = 4 THEN
                SELECT t.id_profile_template, t.id_category
                  INTO i_profile_template, i_category
                  FROM profile_template t
                 WHERE t.id_software = i_sw_backoffice
                   AND t.intern_name_templ = 'Administrador de Sistemas NL';
        END CASE;
        --> SSO Security --> Está a ser inserido via app (java)
        i_pass  := upper('ADM' || i_instit);
        g_error := 'INSERT INTO AB_USER_INFO';
        pk_api_ab_tables.upd_ins_into_ab_user_info(i_id_ab_user_info    => NULL,
                                                   i_login              => i_pass,
                                                   i_password           => i_pass,
                                                   i_import_code        => NULL,
                                                   i_record_status      => 'A',
                                                   i_institution_key    => i_instit,
                                                   i_flg_is_enable      => NULL,
                                                   i_first_name         => 'Default',
                                                   i_last_name          => 'Backoffice Administrator',
                                                   i_full_name          => pk_backoffice.create_name_formated(i_lang,
                                                                                                              i_instit,
                                                                                                              'Default',
                                                                                                              NULL,
                                                                                                              NULL,
                                                                                                              'Backoffice Administrator'),
                                                   i_external_system    => NULL,
                                                   i_external_system_id => NULL,
                                                   i_secret_quest       => 'CL',
                                                   i_secret_answ        => i_pass,
                                                   i_id_language        => i_lang,
                                                   i_flg_temporary      => NULL,
                                                   i_date_creation_tstz => current_timestamp,
                                                   o_id_ab_user_info    => i_prof);
    
        SELECT COUNT(*)
          INTO l_count
          FROM professional p
         WHERE p.id_professional = i_prof;
    
        IF l_count = 0
        THEN
            g_error := 'INSERT INTO PROFESSIONAL';
            INSERT INTO professional
                (id_professional,
                 name,
                 nick_name,
                 dt_birth,
                 address,
                 district,
                 city,
                 zip_code,
                 num_contact,
                 marital_status,
                 gender,
                 flg_state,
                 num_order,
                 id_scholarship,
                 id_speciality,
                 id_country,
                 adw_last_update,
                 barcode,
                 initials,
                 title,
                 short_name,
                 first_name,
                 last_name)
            VALUES
                (i_prof,
                 pk_backoffice.create_name_formated(i_lang, i_instit, 'Default', NULL, NULL, 'Backoffice Administrator'),
                 'ADM',
                 to_date('01-01-1980', 'DD-MM-YYYY'),
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 'M',
                 'A',
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 SYSDATE,
                 NULL,
                 'SM',
                 NULL,
                 '-',
                 'Default',
                 'Backoffice Administrator');
        
            g_error := 'INSERT INTO PROFESSIONAL HISTORY';
            pk_backoffice.ins_professional_hist(i_id_professional => i_prof,
                                                i_operation_type  => pk_backoffice.g_prof_hist_oper_c);
        
            g_error := 'INSERT INTO PROF_INSTITUTION';
            pk_api_ab_tables.upd_ins_into_prof_institution(i_id_prof_institution => NULL,
                                                           i_id_professional     => i_prof,
                                                           i_id_institution      => i_instit,
                                                           i_flg_state           => 'A',
                                                           i_dt_end_tstz         => current_timestamp,
                                                           i_flg_external        => 'N',
                                                           i_dn_flg_status       => 'V',
                                                           o_id_prof_institution => l_prof_institution);
        
            g_error := 'INSERT INTO PROF_CAT';
            INSERT INTO prof_cat
                (id_prof_cat, id_professional, id_category, id_institution, id_category_sub)
            VALUES
                (seq_prof_cat.nextval, i_prof, i_category, i_instit, NULL);
        
            SELECT nvl((SELECT si.id_software_institution
                         FROM software_institution si
                        WHERE si.id_software = i_sw_backoffice
                          AND si.id_institution = i_instit),
                       0)
              INTO l_soft_inst_pk
              FROM dual;
            g_error := 'GET DEFAULT COMPONENT ID';
            pk_api_ab_tables.get_component_from_si(profissional(0, i_instit, i_sw_backoffice), l_comp_id);
        
            g_error := 'INSERT INTO PROF_SOFT_INST';
            pk_api_ab_tables.upd_ins_into_ab_sw_ins_usr_inf(i_prof                       => profissional(i_prof,
                                                                                                         i_instit,
                                                                                                         i_sw_backoffice),
                                                            i_id_ab_soft_inst_user_info  => NULL,
                                                            i_import_code                => NULL,
                                                            i_record_status              => 'A',
                                                            i_id_ab_software_institution => l_soft_inst_pk,
                                                            i_id_ab_software_inst_role   => l_role_sw_inst_pk,
                                                            i_id_ab_institution          => i_instit,
                                                            i_id_ab_software             => i_sw_backoffice,
                                                            i_id_ab_user_info            => i_prof,
                                                            i_id_ab_role                 => l_role_id,
                                                            i_id_ab_component            => to_number(l_comp_id),
                                                            i_id_ab_language             => i_language,
                                                            i_flg_log                    => NULL,
                                                            i_id_department              => NULL,
                                                            i_dt_log_tstz                => NULL,
                                                            i_timeout                    => NULL,
                                                            i_first_screen               => NULL,
                                                            o_id_ab_soft_inst_user_info  => l_si_user_info);
        
            g_error := 'INSERT INTO PROF_PROFILE_TEMPLATE';
            INSERT INTO prof_profile_template
                (id_prof_profile_template, id_profile_template, id_professional, id_software, id_institution)
            VALUES
                (seq_prof_profile_template.nextval, i_profile_template, i_prof, i_sw_backoffice, i_instit);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_BACKOFFICE_ADM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_BACKOFFICE_ADM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END create_backoffice_adm;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_dept
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN software_institution.id_institution%TYPE,
        i_id_software    IN software_institution.id_software%TYPE,
        o_id_dept        OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index     NUMBER := 1;
        l_count     NUMBER := 0;
        l_count_trl NUMBER := 0;
    
        --DEPT
        l_dp_id_dept_def       dept.id_dept%TYPE;
        l_dp_id_dept           dept.id_dept%TYPE;
        l_dp_rank              dept.rank%TYPE;
        l_dp_abbreviation      dept.abbreviation%TYPE;
        l_dp_flg_priority      dept.flg_priority%TYPE;
        l_dp_flg_collection_by dept.flg_collection_by%TYPE;
        --TRANSLATION
        dml_errors EXCEPTION;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_c_department   table_number := table_number();
        l_id_institution institution.id_institution%TYPE;
    
        CURSOR c_dept
        (
            c_id_institution institution.id_institution%TYPE,
            c_id_software    department.id_software%TYPE
        ) IS
            SELECT d.id_dept, d.rank, d.abbreviation, d.flg_priority, d.flg_collection_by
              FROM alert_default.dept d
              JOIN alert_default.department dp
                ON dp.id_dept = d.id_dept
               AND dp.id_institution = d.id_institution
               AND dp.id_software = c_id_software
             WHERE d.flg_available = g_flg_available
               AND d.id_institution = c_id_institution;
    
        CURSOR c_soft_dept
        (
            c_id_dept     department.id_dept%TYPE,
            c_id_software department.id_software%TYPE
        ) IS
            SELECT DISTINCT (t.id_software)
              FROM department t
             WHERE t.id_dept = c_id_dept
               AND t.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        --> DEPT
        o_id_dept := table_number();
    
        g_error := 'GET INSTITUTION ID';
        SELECT nvl((SELECT t.id_alert
                     FROM alert_default.map_content t
                    WHERE t.id_default = i_id_institution
                      AND t.table_name = 'INSTITUTION'
                      AND rownum = 1),
                   0)
          INTO l_id_institution
          FROM dual;
    
        IF l_id_institution != 0
        THEN
        
            g_error := 'OPEN C_DEPT CURSOR';
            OPEN c_dept(i_id_institution, i_id_software);
            LOOP
                FETCH c_dept
                    INTO l_dp_id_dept_def, l_dp_rank, l_dp_abbreviation, l_dp_flg_priority, l_dp_flg_collection_by;
                EXIT WHEN c_dept%NOTFOUND;
            
                l_dp_id_dept := l_id_institution || 00 || l_dp_id_dept_def;
                g_error      := 'COUNT DEPT EXISTING RESULTS';
                SELECT COUNT(d.id_dept)
                  INTO l_count
                  FROM dept d
                 WHERE d.id_institution = l_id_institution
                   AND d.id_dept = l_dp_id_dept;
            
                IF l_count = 0
                THEN
                    g_error := 'INSERT INTO DEPT';
                    INSERT INTO dept
                        (id_dept,
                         code_dept,
                         rank,
                         id_institution,
                         abbreviation,
                         flg_available,
                         flg_priority,
                         flg_collection_by)
                    VALUES
                        (l_dp_id_dept,
                         'DEPT.CODE_DEPT.' || l_dp_id_dept,
                         l_dp_rank,
                         l_id_institution,
                         l_dp_abbreviation,
                         g_flg_available,
                         l_dp_flg_priority,
                         l_dp_flg_collection_by);
                
                    --> Mapping
                    g_table_name := 'DEPT';
                    pk_api_default.insert_into_map_content(g_table_name, l_dp_id_dept_def, l_dp_id_dept);
                    -- 15/03/2011 - RMGM : changed way how translations are loaded
                    g_error      := 'SET DEF TRANSLATIONS';
                    g_table_name := 'DEPT';
                    IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                    THEN
                        RAISE dml_errors;
                    END IF;
                
                    o_id_dept.extend;
                    o_id_dept(l_index) := l_dp_id_dept;
                    l_index := l_index + 1;
                
                    --> DEPARTMENT
                    g_error := 'GET DEPARTMENTS by DEPT';
                    IF NOT pk_api_backoffice_default.get_department(i_lang,
                                                                    l_id_institution,
                                                                    i_id_software,
                                                                    l_dp_id_dept_def,
                                                                    l_dp_id_dept,
                                                                    l_c_department,
                                                                    l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                ELSE
                
                    o_id_dept.extend;
                    o_id_dept(l_index) := l_dp_id_dept;
                    l_index := l_index + 1;
                
                    --> DEPARTMENT
                    g_error := 'GET DEPARTMENTS by DEPT';
                    IF NOT pk_api_backoffice_default.get_department(i_lang,
                                                                    l_id_institution,
                                                                    i_id_software,
                                                                    l_dp_id_dept_def,
                                                                    l_dp_id_dept,
                                                                    l_c_department,
                                                                    l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
                --> SOFTWARE_DEPT
                FOR soft_dept IN c_soft_dept(l_dp_id_dept, i_id_software)
                LOOP
                    SELECT COUNT(sd.id_software_dept)
                      INTO l_count
                      FROM software_dept sd
                     WHERE sd.id_dept = l_dp_id_dept
                       AND sd.id_software = soft_dept.id_software;
                
                    IF l_count = 0
                    THEN
                        INSERT INTO software_dept
                            (id_software_dept, id_software, id_dept)
                        VALUES
                            (seq_software_dept.nextval, soft_dept.id_software, l_dp_id_dept);
                    END IF;
                END LOOP;
            
            END LOOP;
        END IF;
        g_error := 'CLOSE C_DEPT CURSOR';
        CLOSE c_dept;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_dept;
    /********************************************************************************************
    * Get Default Software_Institution Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_department
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software_institution.id_software%TYPE,
        i_id_dept_def    IN department.id_dept%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        o_id_department  OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index     NUMBER := 1;
        l_count     NUMBER := 0;
        l_count_trl NUMBER := 0;
    
        --DEPARTMENT
        l_id_department_def department.id_department%TYPE;
        l_id_department     department.id_department%TYPE;
        l_rank              dept.rank%TYPE;
        l_abbreviation      dept.abbreviation%TYPE;
        l_flg_type          department.flg_type%TYPE;
        l_id_software       department.id_software%TYPE;
        l_flg_default       department.flg_default%TYPE;
        l_flg_unidose       department.flg_unidose%TYPE;
        l_id_admission_type department.id_admission_type%TYPE;
        l_flg_priority      dept.flg_priority%TYPE;
        l_flg_collection_by dept.flg_collection_by%TYPE;
        l_adm_age_min       department.adm_age_min%TYPE;
        l_adm_age_max       department.adm_age_max%TYPE;
        l_admission_time    department.admission_time%TYPE;
        --TRANSLATION
        dml_errors EXCEPTION;
        -- CALL DCS
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_c_dcs table_number := table_number();
        -- CALL ROOMS
        l_c_rooms table_number := table_number();
        --FLOORS_DEPARTMENT
        l_id_floors_dept       floors_department.id_floors_department%TYPE;
        i_concat               NUMBER := 1001;
        l_id_floors_instit     floors_institution.id_floors_institution%TYPE;
        l_id_floors_department floors_department.id_department%TYPE;
        l_id_floors_depart_def floors_department.id_department%TYPE;
        l_flg_dep_default      floors_department.flg_dep_default%TYPE;
        l_id_floors_instit_def floors_department.id_floors_institution%TYPE;
        l_id_institution_def   institution.id_institution%TYPE;
    
        --DEPT_TEMPLATE
        l_id_dept_template dept_template.id_dept_template%TYPE;
        l_id_doc_template  dept_template.id_doc_template%TYPE := 58; --> Todas as especialidades
    
        CURSOR c_department
        (
            c_id_dept     department.id_dept%TYPE,
            c_id_software department.id_software%TYPE
        ) IS
            SELECT dp.id_department,
                   dp.rank,
                   dp.abbreviation,
                   dp.flg_type,
                   dp.id_software,
                   dp.flg_default,
                   dp.flg_unidose,
                   dp.id_admission_type,
                   dp.flg_priority,
                   dp.flg_collection_by,
                   dp.adm_age_min,
                   dp.adm_age_max,
                   dp.admission_time
              FROM alert_default.department dp
             WHERE dp.flg_available = g_flg_available
               AND dp.id_dept = c_id_dept
               AND dp.id_software = c_id_software;
    
        CURSOR c_floors_department(c_id_institution_def institution.id_institution%TYPE) IS
            SELECT t.id_department, t.flg_dep_default, t.id_floors_institution
              FROM alert_default.floors_department t
              JOIN alert_default.floors_institution fi
                ON fi.id_floors_institution = t.id_floors_institution
               AND fi.id_institution = c_id_institution_def
             WHERE t.flg_available = g_flg_available;
    
    BEGIN
        g_func_name := upper('');
        --> DEPARTMENT
        o_id_department := table_number();
    
        g_error := 'OPEN C_DEPARTMENT CURSOR';
        OPEN c_department(i_id_dept_def, i_id_software);
        LOOP
            FETCH c_department
                INTO l_id_department_def,
                     l_rank,
                     l_abbreviation,
                     l_flg_type,
                     l_id_software,
                     l_flg_default,
                     l_flg_unidose,
                     l_flg_priority,
                     l_id_admission_type,
                     l_flg_collection_by,
                     l_adm_age_min,
                     l_adm_age_max,
                     l_admission_time;
            EXIT WHEN c_department%NOTFOUND;
        
            l_id_department := i_id_institution || 00 || l_id_department_def;
        
            g_error := 'COUNT DEPARTMENT EXISTING RESULTS';
            SELECT COUNT(dp.id_department)
              INTO l_count
              FROM department dp
             WHERE dp.id_institution = i_id_institution
               AND dp.id_dept = i_id_dept
               AND dp.id_department = l_id_department;
        
            IF l_count = 0
            THEN
                g_error := 'INSERT INTO DEPARTMENT';
                INSERT INTO department
                    (id_department,
                     id_institution,
                     code_department,
                     rank,
                     abbreviation,
                     flg_type,
                     id_dept,
                     id_software,
                     flg_default,
                     flg_available,
                     flg_unidose,
                     id_admission_type,
                     flg_priority,
                     flg_collection_by,
                     adm_age_min,
                     adm_age_max,
                     admission_time)
                VALUES
                    (l_id_department,
                     i_id_institution,
                     'DEPARTMENT.CODE_DEPARTMENT.' || l_id_department,
                     l_rank,
                     l_abbreviation,
                     l_flg_type,
                     i_id_dept,
                     l_id_software,
                     l_flg_default,
                     g_flg_available,
                     l_flg_unidose,
                     l_id_admission_type,
                     l_flg_priority,
                     l_flg_collection_by,
                     l_adm_age_min,
                     l_adm_age_max,
                     l_admission_time);
            
                g_table_name := 'DEPARTMENT';
                pk_api_default.insert_into_map_content(g_table_name, l_id_department_def, l_id_department);
                -- 15/03/2011 - RMGM : changed way how translations are loaded
                g_error      := 'SET DEF TRANSLATIONS';
                g_table_name := 'DEPARTMENT';
                IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                THEN
                    RAISE dml_errors;
                END IF;
            
                o_id_department.extend;
                o_id_department(l_index) := l_id_department;
                l_index := l_index + 1;
            
            ELSE
            
                o_id_department.extend;
                o_id_department(l_index) := l_id_department;
                l_index := l_index + 1;
            
            END IF;
        
            --> DEP_CLIN_SERV
            g_error := 'GET DEP_CLIN_SERVS by DEPARTMENT';
            IF NOT pk_api_backoffice_default.get_dep_clin_serv(i_lang,
                                                               l_id_department_def,
                                                               l_id_department,
                                                               l_c_dcs,
                                                               l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            --> ROOMS
            g_error := 'GET ROOMS by DEPARTMENT';
            IF NOT pk_api_backoffice_default.get_rooms(i_lang,
                                                       l_id_department_def,
                                                       l_id_department,
                                                       l_id_floors_dept,
                                                       l_c_rooms,
                                                       l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            --> DEPT_TEMPLATE
            l_id_dept_template := l_id_department || i_concat;
            g_error            := 'COUNT DEPT_TEMPLATE';
            SELECT COUNT(dt.id_dept_template)
              INTO l_count
              FROM dept_template dt
             WHERE dt.id_department = l_id_department
               AND dt.id_dept_template = l_id_dept_template;
        
            IF l_count = 0
            THEN
                g_error := 'INSERT INTO DEPT_TEMPLATE';
                INSERT INTO dept_template
                    (id_dept_template,
                     id_doc_template,
                     id_department,
                     adw_last_update,
                     flg_available,
                     flg_gender,
                     age_max,
                     age_min)
                VALUES
                    (l_id_dept_template,
                     l_id_doc_template,
                     l_id_department,
                     SYSDATE,
                     g_flg_available,
                     NULL,
                     NULL,
                     NULL);
            END IF;
        END LOOP;
        g_error := 'CLOSE C_DEPARTMENT CURSOR';
        CLOSE c_department;
    
        --> FLOORS_DEPARTMENT
        g_error := 'GET ALERT_DEFAULT.INSTITUTION ID';
        SELECT nvl((SELECT t.id_default
                     FROM alert_default.map_content t
                    WHERE t.id_alert = i_id_institution
                      AND t.table_name = 'INSTITUTION'
                      AND rownum = 1),
                   0)
          INTO l_id_institution_def
          FROM dual;
    
        IF l_id_institution_def != 0
        THEN
            g_error := 'OPEN C_FLOORS_DEPARTMENT CURSOR';
            OPEN c_floors_department(l_id_institution_def);
            LOOP
                FETCH c_floors_department
                    INTO l_id_floors_depart_def, l_flg_dep_default, l_id_floors_instit_def;
                EXIT WHEN c_floors_department%NOTFOUND;
            
                g_error := 'GET DEPARTMENT ID';
                SELECT nvl((SELECT mc.id_alert
                             FROM alert_default.map_content mc
                            WHERE mc.table_name = 'DEPARTMENT'
                              AND mc.id_default = l_id_floors_depart_def
                              AND rownum = 1),
                           0)
                  INTO l_id_floors_department
                  FROM dual;
            
                g_error := 'GET FLOORS_INSTITUTION ID';
                SELECT nvl((SELECT mc.id_alert
                             FROM alert_default.map_content mc
                            WHERE mc.table_name = 'FLOORS_INSTITUTION'
                              AND mc.id_default = l_id_floors_instit_def
                              AND rownum = 1),
                           0)
                  INTO l_id_floors_instit
                  FROM dual;
            
                IF l_id_floors_instit != 0
                   AND l_id_floors_department != 0
                THEN
                    g_error := 'COUNT FLOORS_DEPARTMENT';
                    SELECT COUNT(fd.id_floors_department)
                      INTO l_count
                      FROM floors_department fd
                     WHERE fd.id_department = l_id_floors_department
                       AND fd.id_floors_institution = l_id_floors_instit;
                
                    IF l_count = 0
                    THEN
                        g_error := 'INSERT INTO FLOORS_DEPARTMENT';
                        INSERT INTO floors_department
                            (id_floors_department,
                             id_department,
                             flg_available,
                             adw_last_update,
                             flg_dep_default,
                             id_floors_institution)
                        VALUES
                            (seq_floors_department.nextval,
                             l_id_floors_department,
                             g_flg_available,
                             SYSDATE,
                             l_flg_dep_default,
                             l_id_floors_instit);
                    END IF;
                END IF;
            END LOOP;
            g_error := 'CLOSE C_FLOORS_DEPARTMENT CURSOR';
            CLOSE c_floors_department;
        END IF;
        --<
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEPARTMENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_department;
    /********************************************************************************************
    * Get Default DEP_CLIN_SERVS Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/10
    ********************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang              IN language.id_language%TYPE,
        i_id_department_def IN department.id_department%TYPE,
        i_id_department     IN department.id_department%TYPE,
        o_id_dcs            OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index NUMBER := 1;
        l_count NUMBER := 0;
    
        --DEP_CLIN_SERV
        l_id_dcs_def              dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_dcs                  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service_def dep_clin_serv.id_clinical_service%TYPE;
        l_id_clinical_service     dep_clin_serv.id_clinical_service%TYPE;
        l_rank                    dep_clin_serv.rank%TYPE;
        l_flg_nurse_pre           dep_clin_serv.flg_nurse_pre%TYPE;
        l_flg_default             dep_clin_serv.flg_default%TYPE;
        l_flg_type                dep_clin_serv.flg_type%TYPE;
        l_adm_age_min             dep_clin_serv.adm_age_min%TYPE;
        l_adm_age_max             dep_clin_serv.adm_age_max%TYPE;
        l_flg_coding              dep_clin_serv.flg_coding%TYPE;
        l_flg_just_post_presc     dep_clin_serv.flg_just_post_presc%TYPE;
        l_post_presc_num_hours    dep_clin_serv.post_presc_num_hours%TYPE;
    
        CURSOR c_dcs(c_id_department department.id_department%TYPE) IS
            SELECT dcs.id_dep_clin_serv,
                   dcs.id_clinical_service,
                   dcs.rank,
                   dcs.flg_nurse_pre,
                   dcs.flg_default,
                   dcs.flg_type,
                   dcs.adm_age_min,
                   dcs.adm_age_max,
                   dcs.flg_coding,
                   dcs.flg_just_post_presc,
                   dcs.post_presc_num_hours
              FROM alert_default.dep_clin_serv dcs
             WHERE dcs.flg_available = g_flg_available
               AND dcs.id_department = c_id_department;
    
    BEGIN
        g_func_name := upper('');
        --> DEPARTMENT
        o_id_dcs := table_number();
    
        g_error := 'OPEN D_DCS CURSOR';
        OPEN c_dcs(i_id_department_def);
        LOOP
            FETCH c_dcs
                INTO l_id_dcs_def,
                     l_id_clinical_service_def,
                     l_rank,
                     l_flg_nurse_pre,
                     l_flg_default,
                     l_flg_type,
                     l_adm_age_min,
                     l_adm_age_max,
                     l_flg_coding,
                     l_flg_just_post_presc,
                     l_post_presc_num_hours;
            EXIT WHEN c_dcs%NOTFOUND;
        
            g_error := 'GET CLINICAL_SERVICE ID';
            SELECT nvl((SELECT cs.id_clinical_service
                         FROM clinical_service cs
                        WHERE cs.id_content =
                              (SELECT cs2.id_content
                                 FROM alert_default.clinical_service cs2
                                WHERE cs2.id_clinical_service = l_id_clinical_service_def)
                          AND cs.id_content IS NOT NULL
                          AND cs.flg_available = g_flg_available
                          AND rownum = 1),
                       0)
              INTO l_id_clinical_service
              FROM dual;
        
            IF l_id_clinical_service != 0
            THEN
            
                g_error := 'COUNT DEP_CLIN_SERV EXISTING RESULTS';
                SELECT COUNT(dcs.id_dep_clin_serv)
                  INTO l_count
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_department = i_id_department
                   AND dcs.id_clinical_service = l_id_clinical_service;
            
                IF l_count = 0
                THEN
                    --> Generate ID_DCS
                    l_id_dcs := i_id_department || 00 || l_id_dcs_def;
                
                    g_error := 'INSERT INTO DEP_CLIN_SERV';
                    INSERT INTO dep_clin_serv
                        (id_dep_clin_serv,
                         id_clinical_service,
                         id_department,
                         rank,
                         flg_nurse_pre,
                         flg_default,
                         flg_available,
                         flg_type,
                         adm_age_min,
                         adm_age_max,
                         flg_coding,
                         flg_just_post_presc,
                         post_presc_num_hours)
                    VALUES
                        (l_id_dcs,
                         l_id_clinical_service,
                         i_id_department,
                         l_rank,
                         l_flg_nurse_pre,
                         l_flg_default,
                         g_flg_available,
                         l_flg_type,
                         l_adm_age_min,
                         l_adm_age_max,
                         l_flg_coding,
                         l_flg_just_post_presc,
                         l_post_presc_num_hours);
                
                    o_id_dcs.extend;
                    o_id_dcs(l_index) := l_id_dcs;
                    l_index := l_index + 1;
                
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'CLOSE D_DCS CURSOR';
        CLOSE c_dcs;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DEP_CLIN_SERV',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_dep_clin_serv;
    /********************************************************************************************
    * Get Default Rooms by DEPARTMENT Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang              IN language.id_language%TYPE,
        i_id_department_def IN department.id_department%TYPE,
        i_id_department     IN department.id_department%TYPE,
        i_floor_dept        IN floors_department.id_floors_department%TYPE,
        o_id_room           OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index     NUMBER := 1;
        l_count     NUMBER := 0;
        l_count_sc  NUMBER := 0;
        l_count_trl NUMBER := 0;
    
        --ROOM
        l_id_room_def               room.id_room%TYPE;
        l_id_room                   room.id_room%TYPE;
        l_flg_prof                  room.flg_prof%TYPE;
        l_capacity                  room.capacity%TYPE;
        l_interval_time             room.interval_time%TYPE;
        l_flg_recovery              room.flg_recovery%TYPE;
        l_flg_lab                   room.flg_lab%TYPE;
        l_rank                      room.rank%TYPE;
        l_flg_wait                  room.flg_wait%TYPE;
        l_flg_wl                    room.flg_wl%TYPE;
        l_img_name                  room.img_name%TYPE;
        l_flg_transp                room.flg_transp%TYPE;
        l_id_room_type              room.id_room_type%TYPE;
        l_flg_schedulable           room.flg_schedulable%TYPE;
        l_flg_status                room.flg_status%TYPE;
        l_flg_parameterization_type room.flg_parameterization_type%TYPE;
        l_flg_selected_specialties  room.flg_selected_specialties%TYPE;
        l_desc_room                 room.desc_room%TYPE;
        l_desc_room_abbreviation    room.desc_room_abbreviation%TYPE;
        --TRANSLATION
        dml_errors EXCEPTION;
        -- CALL BEDS
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_c_beds table_number := table_number();
        -- SYS_CONFIG
        l_sys_config_lab  alert_default.room_mcdt_type.type%TYPE := 'LAB';
        l_sys_config_exam alert_default.room_mcdt_type.type%TYPE := 'EXAM';
    
        i_id_institution institution.id_institution%TYPE;
    
        CURSOR c_rooms(c_id_department department.id_department%TYPE) IS
            SELECT r.id_room,
                   r.flg_prof,
                   r.capacity,
                   r.interval_time,
                   r.flg_recovery,
                   r.flg_lab,
                   r.rank,
                   r.flg_wait,
                   r.flg_wl,
                   r.img_name,
                   r.flg_transp,
                   r.id_room_type,
                   r.flg_schedulable,
                   r.flg_status,
                   r.flg_parameterization_type,
                   r.flg_selected_specialties,
                   r.desc_room,
                   r.desc_room_abbreviation
              FROM alert_default.room r
             WHERE r.flg_available = g_flg_available
               AND r.id_department = c_id_department;
    
        CURSOR c_dcs(c_id_department department.id_department%TYPE) IS
            SELECT DISTINCT (t.id_dep_clin_serv)
              FROM dep_clin_serv t
             WHERE t.id_department = c_id_department
               AND t.flg_available = g_flg_available;
    
        CURSOR c_sys_config
        (
            c_sys_config  sys_config.id_sys_config%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT sc.desc_sys_config,
                   sc.id_software,
                   sc.fill_type,
                   sc.client_configuration,
                   sc.internal_configuration,
                   sc.global_configuration,
                   sc.id_market
              FROM alert_default.sys_config sc
             WHERE sc.id_sys_config = c_sys_config
               AND sc.id_software = c_id_software;
    
    BEGIN
        g_func_name := upper('');
        o_id_room   := table_number();
    
        g_error := 'GET ID_INSTITUTION';
        SELECT DISTINCT (d.id_institution)
          INTO i_id_institution
          FROM department d
         WHERE d.id_department = i_id_department;
    
        g_error := 'OPEN C_ROOMS CURSOR';
        OPEN c_rooms(i_id_department_def);
        LOOP
            FETCH c_rooms
                INTO l_id_room_def,
                     l_flg_prof,
                     l_capacity,
                     l_interval_time,
                     l_flg_recovery,
                     l_flg_lab,
                     l_rank,
                     l_flg_wait,
                     l_flg_wl,
                     l_img_name,
                     l_flg_transp,
                     l_id_room_type,
                     l_flg_schedulable,
                     l_flg_status,
                     l_flg_parameterization_type,
                     l_flg_selected_specialties,
                     l_desc_room,
                     l_desc_room_abbreviation;
        
            EXIT WHEN c_rooms%NOTFOUND;
        
            --> Generate ID_ROOM
            l_id_room := i_id_department || l_id_room_def;
        
            g_error := 'COUNT ROOM EXISTING RESULTS';
            SELECT COUNT(r.id_room)
              INTO l_count
              FROM room r
             WHERE r.id_department = i_id_department
               AND r.id_room = l_id_room;
        
            IF l_count = 0
            THEN
                g_error := 'INSERT INTO ROOM';
                INSERT INTO room
                    (id_room,
                     flg_prof,
                     id_department,
                     code_room,
                     capacity,
                     interval_time,
                     flg_recovery,
                     flg_lab,
                     rank,
                     adw_last_update,
                     flg_wait,
                     flg_wl,
                     img_name,
                     flg_transp,
                     code_abbreviation,
                     id_floors_department,
                     flg_available,
                     id_room_type,
                     flg_schedulable,
                     flg_status,
                     flg_parameterization_type,
                     id_professional,
                     dt_creation,
                     dt_last_update,
                     flg_selected_specialties,
                     desc_room,
                     desc_room_abbreviation)
                VALUES
                    (l_id_room,
                     l_flg_prof,
                     i_id_department,
                     'ROOM.CODE_ROOM.' || l_id_room,
                     l_capacity,
                     l_interval_time,
                     l_flg_recovery,
                     l_flg_lab,
                     l_rank,
                     SYSDATE,
                     l_flg_wait,
                     l_flg_wl,
                     l_img_name,
                     l_flg_transp,
                     'ROOM.CODE_ABBREVIATION.' || l_id_room,
                     i_floor_dept,
                     g_flg_available,
                     l_id_room_type,
                     l_flg_schedulable,
                     l_flg_status,
                     l_flg_parameterization_type,
                     NULL,
                     current_timestamp,
                     NULL,
                     l_flg_selected_specialties,
                     l_desc_room,
                     l_desc_room_abbreviation);
            
                --> Mapping
                g_table_name := 'ROOM';
                pk_api_default.insert_into_map_content(g_table_name, l_id_room_def, l_id_room);
                -- 15/03/2011 - RMGM : changed way how translations are loaded
                g_error      := 'SET DEF TRANSLATIONS';
                g_table_name := 'ROOM';
                IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                THEN
                    RAISE dml_errors;
                END IF;
            
                o_id_room.extend;
                o_id_room(l_index) := l_id_room;
                l_index := l_index + 1;
            
            ELSE
            
                o_id_room.extend;
                o_id_room(l_index) := l_id_room;
                l_index := l_index + 1;
            
            END IF;
        
            --> Insere na SYS_CONFIG as salas que serão por DEFAULT
            -->ANALYSIS_ROOM
            SELECT COUNT(t.id_room)
              INTO l_count
              FROM alert_default.room t
              JOIN alert_default.room_mcdt_type rm
                ON rm.id_room = t.id_room
               AND rm.type = l_sys_config_lab
             WHERE t.id_room = l_id_room_def;
        
            IF l_count != 0
            THEN
                SELECT COUNT(sc.id_sys_config)
                  INTO l_count_sc
                  FROM sys_config sc
                 WHERE sc.id_sys_config = l_sys_config_lab;
            
                IF l_count_sc = 0
                THEN
                
                    INSERT INTO sys_config
                        (id_sys_config,
                         VALUE,
                         desc_sys_config,
                         id_institution,
                         id_software,
                         fill_type,
                         client_configuration,
                         internal_configuration,
                         global_configuration,
                         flg_schema,
                         id_market)
                        SELECT l_sys_config_lab,
                               l_id_room,
                               sc.desc_sys_config,
                               i_id_institution,
                               sc.id_software,
                               sc.fill_type,
                               sc.client_configuration,
                               sc.internal_configuration,
                               sc.global_configuration,
                               'A',
                               sc.id_market
                          FROM alert_default.sys_config sc
                         WHERE sc.id_sys_config = l_sys_config_lab
                           AND sc.id_software = (SELECT t.id_software
                                                   FROM department t
                                                  WHERE t.id_department = i_id_department);
                
                END IF;
            END IF;
            -->EXAM_ROOM
            SELECT COUNT(t.id_room)
              INTO l_count
              FROM alert_default.room t
              JOIN alert_default.room_mcdt_type rm
                ON rm.id_room = t.id_room
               AND rm.type = l_sys_config_exam
             WHERE t.id_room = l_id_room_def;
        
            IF l_count != 0
            THEN
                SELECT COUNT(sc.id_sys_config)
                  INTO l_count_sc
                  FROM sys_config sc
                 WHERE sc.id_sys_config = l_sys_config_exam;
            
                IF l_count_sc = 0
                THEN
                
                    INSERT INTO sys_config
                        (id_sys_config,
                         VALUE,
                         desc_sys_config,
                         id_institution,
                         id_software,
                         fill_type,
                         client_configuration,
                         internal_configuration,
                         global_configuration,
                         flg_schema,
                         id_market)
                        SELECT l_sys_config_exam,
                               l_id_room,
                               sc.desc_sys_config,
                               i_id_institution,
                               sc.id_software,
                               sc.fill_type,
                               sc.client_configuration,
                               sc.internal_configuration,
                               sc.global_configuration,
                               'A',
                               sc.id_market
                          FROM alert_default.sys_config sc
                         WHERE sc.id_sys_config = l_sys_config_exam
                           AND sc.id_software = (SELECT t.id_software
                                                   FROM department t
                                                  WHERE t.id_department = i_id_department);
                
                END IF;
            END IF;
        
            --> ROOM_DEP_CLIN_SERV
            FOR dcs IN c_dcs(i_id_department)
            LOOP
            
                g_error := 'COUNT ROOM_DCS EXISTING RESULTS';
                SELECT COUNT(rdcs.id_room_dep_clin_serv)
                  INTO l_count
                  FROM room_dep_clin_serv rdcs
                 WHERE rdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND rdcs.id_room = l_id_room;
            
                IF l_count = 0
                THEN
                    INSERT INTO room_dep_clin_serv
                        (id_room_dep_clin_serv, id_room, id_dep_clin_serv)
                    VALUES
                        (seq_room_dep_clin_serv.nextval, l_id_room, dcs.id_dep_clin_serv);
                
                END IF;
            END LOOP;
        
            --> BEDS
            g_error := 'GET BEDS by ROOM';
            IF NOT pk_api_backoffice_default.get_beds(i_lang,
                                                      l_id_room_def,
                                                      l_id_room,
                                                      i_id_department,
                                                      l_c_beds,
                                                      l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        g_error := 'CLOSE C_ROOMS CURSOR';
        CLOSE c_rooms;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ROOMS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_rooms;
    /********************************************************************************************
    * Get Default Beds by ROOM Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION get_beds
    (
        i_lang          IN language.id_language%TYPE,
        i_id_room_def   IN room.id_room%TYPE,
        i_id_room       IN room.id_room%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_id_bed        OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index     NUMBER := 1;
        l_count     NUMBER := 0;
        l_count_trl NUMBER := 0;
    
        --BED
        l_id_bed_def                bed.id_bed%TYPE;
        l_id_bed                    bed.id_bed%TYPE;
        l_flg_type                  bed.flg_type%TYPE;
        l_flg_status                bed.flg_status%TYPE;
        l_desc_bed                  bed.desc_bed%TYPE;
        l_notes                     bed.notes%TYPE;
        l_rank                      bed.rank%TYPE;
        l_id_bed_type               bed.id_bed_type%TYPE;
        l_flg_schedulable           bed.flg_schedulable%TYPE;
        l_flg_bed_status            bed.flg_bed_status%TYPE;
        l_flg_parameterization_type bed.flg_parameterization_type%TYPE;
        l_flg_selected_specialties  bed.flg_selected_specialties%TYPE;
    
        --TRANSLATION
        dml_errors EXCEPTION;
    
        CURSOR c_beds(c_id_room room.id_room%TYPE) IS
            SELECT b.id_bed,
                   b.flg_type,
                   b.flg_status,
                   b.desc_bed,
                   b.notes,
                   b.rank,
                   b.id_bed_type,
                   b.flg_schedulable,
                   b.flg_bed_status,
                   b.flg_parameterization_type,
                   b.flg_selected_specialties
              FROM alert_default.bed b
             WHERE b.flg_available = g_flg_available
               AND b.id_room = c_id_room;
    
        CURSOR c_dcs(c_id_department department.id_department%TYPE) IS
            SELECT DISTINCT (t.id_dep_clin_serv)
              FROM dep_clin_serv t
             WHERE t.id_department = c_id_department
               AND t.flg_available = g_flg_available;
    
    BEGIN
        g_func_name := upper('');
        o_id_bed    := table_number();
    
        g_error := 'OPEN C_BEDS CURSOR';
        OPEN c_beds(i_id_room_def);
        LOOP
            FETCH c_beds
                INTO l_id_bed_def,
                     l_flg_type,
                     l_flg_status,
                     l_desc_bed,
                     l_notes,
                     l_rank,
                     l_id_bed_type,
                     l_flg_schedulable,
                     l_flg_bed_status,
                     l_flg_parameterization_type,
                     l_flg_selected_specialties;
            EXIT WHEN c_beds%NOTFOUND;
        
            --> Generate ID_BED
            l_id_bed := i_id_room || l_id_bed_def;
        
            g_error := 'COUNT BED EXISTING RESULTS';
            SELECT COUNT(b.id_bed)
              INTO l_count
              FROM bed b
             WHERE b.id_room = i_id_room
               AND b.id_bed = l_id_bed;
        
            IF l_count = 0
            THEN
                g_error := 'INSERT INTO BED';
                INSERT INTO bed
                    (id_bed,
                     code_bed,
                     id_room,
                     flg_type,
                     flg_status,
                     desc_bed,
                     notes,
                     rank,
                     flg_available,
                     id_bed_type,
                     dt_creation,
                     flg_schedulable,
                     flg_bed_status,
                     flg_parameterization_type,
                     id_professional,
                     dt_last_update,
                     flg_selected_specialties)
                VALUES
                    (l_id_bed,
                     'BED.CODE_BED.' || l_id_bed,
                     i_id_room,
                     l_flg_type,
                     l_flg_status,
                     l_desc_bed,
                     l_notes,
                     l_rank,
                     g_flg_available,
                     l_id_bed_type,
                     current_timestamp,
                     l_flg_schedulable,
                     l_flg_bed_status,
                     l_flg_parameterization_type,
                     NULL,
                     NULL,
                     l_flg_selected_specialties);
            
                o_id_bed.extend;
                o_id_bed(l_index) := l_id_bed;
                l_index := l_index + 1;
            
                --> Mapping
                g_table_name := 'BED';
                pk_api_default.insert_into_map_content(g_table_name, l_id_bed_def, l_id_bed);
                -- 15/03/2011 - RMGM : changed way how translations are loaded
                g_error      := 'SET DEF TRANSLATIONS';
                g_table_name := 'BED';
                IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
                THEN
                    RAISE dml_errors;
                END IF;
            
            END IF;
        
            --> ROOM_DEP_CLIN_SERV
            FOR dcs IN c_dcs(i_id_department)
            LOOP
            
                g_error := 'COUNT BED_DCS EXISTING RESULTS';
                SELECT COUNT(*)
                  INTO l_count
                  FROM bed_dep_clin_serv bdcs
                 WHERE bdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND bdcs.id_bed = l_id_bed;
            
                IF l_count = 0
                THEN
                    INSERT INTO bed_dep_clin_serv
                        (id_bed, id_dep_clin_serv, flg_available)
                    VALUES
                        (l_id_bed, dcs.id_dep_clin_serv, g_flg_available);
                END IF;
            END LOOP;
        
        END LOOP;
    
        g_error := 'CLOSE C_BEDS CURSOR';
        CLOSE c_beds;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BEDS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_beds;
    /********************************************************************************************
    * Set Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/11
    ********************************************************************************************/
    FUNCTION set_default_content
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        o_health_plan_entities   table_number := table_number();
        o_health_plans           table_number := table_number();
        o_clinical_services      pk_types.cursor_type;
        o_analysis_parameters    table_number := table_number();
        o_sample_types           table_number := table_number();
        o_sample_rec             table_number := table_number();
        o_exam_cat               table_number := table_number();
        o_analysis               table_number := table_number();
        o_analysis_res_calcs     table_number := table_number();
        o_analysis_res_par_calcs table_number := table_number();
        o_analysis_loinc         table_number := table_number();
        o_analysis_desc          table_number := table_number();
        o_exams                  table_number := table_number();
        o_interv                 table_number := table_number();
        o_interv_cat             table_number := table_number();
        o_supplies               table_number := table_number();
        o_habits                 table_number := table_number();
        o_hidrics                table_number := table_number();
        o_transp_entity          table_number := table_number();
        o_disch_reas             table_number := table_number();
        o_disch_dest             table_number := table_number();
        o_disch_instr_group      table_number := table_number();
        o_disch_instructions     table_number := table_number();
        o_icnp_compositions      pk_types.cursor_type;
        o_events                 pk_types.cursor_type;
        o_lens                   table_number := table_number();
        o_necessity              table_number := table_number();
        o_codification           table_number := table_number();
        o_codification_analysis  table_number := table_number();
        o_interv_codification    table_number := table_number();
        o_exam_codification      table_number := table_number();
        o_transfer_option        table_number := table_number();
        o_sr_intervention        table_number := table_number();
        o_sr_equip               table_number := table_number();
        o_sr_equip_kit           table_number := table_number();
        o_sr_equip_period        table_number := table_number();
        o_diet_parent            pk_types.cursor_type;
        o_diet                   pk_types.cursor_type;
        o_positioning            table_number := table_number();
        o_speciality             table_number := table_number();
        o_physiatry_area         table_number := table_number();
        o_interv_physiatry_area  table_number := table_number();
        o_comp_axe               table_number := table_number();
        o_complication           table_number := table_number();
        o_comp_axe_group         table_number := table_number();
        o_checklist              table_number := table_number();
        o_rehab_area             table_number := table_number();
        o_rehab_session_type     table_varchar := table_varchar();
        o_body_structure         table_number := table_number();
        o_habit_char             table_number := table_number();
        o_questionnaire          pk_types.cursor_type;
        o_response               pk_types.cursor_type;
        o_hidrics_device         pk_types.cursor_type;
        o_hidrics_occurs_type    pk_types.cursor_type;
        o_isencao                table_number := table_number();
        o_supply_type            pk_types.cursor_type;
        o_supply                 pk_types.cursor_type;
        o_resnt                  pk_types.cursor_type;
        o_labt_st                pk_types.cursor_type;
        o_labt_bs                pk_types.cursor_type;
        o_labt_compl             pk_types.cursor_type;
        o_mcdtisencao            table_number := table_number();
        o_mcdtnature             table_number := table_number();
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT CONTENT';
            IF NOT pk_default_content.set_def_content(i_lang                   => i_lang,
                                                      o_health_plan_entities   => o_health_plan_entities,
                                                      o_health_plans           => o_health_plans,
                                                      o_clinical_services      => o_clinical_services,
                                                      o_analysis_parameters    => o_analysis_parameters,
                                                      o_sample_types           => o_sample_types,
                                                      o_sample_rec             => o_sample_rec,
                                                      o_exam_cat               => o_exam_cat,
                                                      o_analysis               => o_analysis,
                                                      o_analysis_res_calcs     => o_analysis_res_calcs,
                                                      o_analysis_res_par_calcs => o_analysis_res_par_calcs,
                                                      o_analysis_loinc         => o_analysis_loinc,
                                                      o_analysis_desc          => o_analysis_desc,
                                                      o_exams                  => o_exams,
                                                      o_interv                 => o_interv,
                                                      o_interv_cat             => o_interv_cat,
                                                      o_supplies               => o_supplies,
                                                      o_habits                 => o_habits,
                                                      o_habit_char             => o_habit_char,
                                                      o_hidrics                => o_hidrics,
                                                      o_transp_entity          => o_transp_entity,
                                                      o_disch_reas             => o_disch_reas,
                                                      o_disch_dest             => o_disch_dest,
                                                      o_disch_instr_group      => o_disch_instr_group,
                                                      o_disch_instructions     => o_disch_instructions,
                                                      o_icnp_compositions      => o_icnp_compositions,
                                                      o_events                 => o_events,
                                                      o_lens                   => o_lens,
                                                      o_necessity              => o_necessity,
                                                      o_codification           => o_codification,
                                                      o_codification_analysis  => o_codification_analysis,
                                                      o_interv_codification    => o_interv_codification,
                                                      o_exam_codification      => o_exam_codification,
                                                      o_transfer_option        => o_transfer_option,
                                                      o_sr_intervention        => o_sr_intervention,
                                                      o_sr_equip               => o_sr_equip,
                                                      o_sr_equip_kit           => o_sr_equip_kit,
                                                      o_sr_equip_period        => o_sr_equip_period,
                                                      o_diet_parent            => o_diet_parent,
                                                      o_diet                   => o_diet,
                                                      o_positioning            => o_positioning,
                                                      o_speciality             => o_speciality,
                                                      o_physiatry_area         => o_physiatry_area,
                                                      o_interv_physiatry_area  => o_interv_physiatry_area,
                                                      o_comp_axe               => o_comp_axe,
                                                      o_complication           => o_complication,
                                                      o_comp_axe_group         => o_comp_axe_group,
                                                      o_checklist              => o_checklist,
                                                      o_rehab_area             => o_rehab_area,
                                                      o_rehab_session_type     => o_rehab_session_type,
                                                      o_body_structure         => o_body_structure,
                                                      o_questionnaire          => o_questionnaire,
                                                      o_response               => o_response,
                                                      o_hidrics_device         => o_hidrics_device,
                                                      o_hidrics_occurs_type    => o_hidrics_occurs_type,
                                                      o_isencao                => o_isencao,
                                                      o_supply_type            => o_supply_type,
                                                      o_supply                 => o_supply,
                                                      o_res_notes              => o_resnt,
                                                      o_labt_st                => o_labt_st,
                                                      o_labt_bs                => o_labt_bs,
                                                      o_labt_compl             => o_labt_compl,
                                                      o_mcdt_nature            => o_mcdtnature,
                                                      o_mcdt_nisencao          => o_mcdtisencao,
                                                      o_error                  => l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DEFAULT_CONTENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DEFAULT_CONTENT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_default_content;
    /********************************************************************************************
    * Set Default Analysis_Room, Exam_Room and Epis_Type_Room Pos-Default Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/08/17
    ********************************************************************************************/
    FUNCTION set_rooms_pos_default
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_institution_def     IN institution.id_institution%TYPE,
        o_id_analysis_room       OUT table_number,
        o_id_exam_room           OUT table_number,
        o_id_epis_type_room      OUT table_number,
        o_id_analysis_quest_room OUT table_number,
        o_id_room_questionnaire  OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index          NUMBER := 1;
        l_index_ar       NUMBER := 1;
        l_index_er       NUMBER := 1;
        l_index_etr      NUMBER := 1;
        l_index_aqr      NUMBER := 1;
        l_index_rq       NUMBER := 1;
        l_count          NUMBER := 0;
        l_count_epis     NUMBER := 0;
        l_id_institution institution.id_institution%TYPE;
        --ANALYSIS_ROOM
        l_id_analysis      analysis.id_analysis%TYPE;
        l_id_analysis_room analysis_room.id_analysis_room%TYPE;
        l_flg_type         analysis_room.flg_type%TYPE := 'T';
        --EXAM_ROOM
        l_id_exam      exam.id_exam%TYPE;
        l_id_exam_room exam_room.id_exam_room%TYPE;
        --EPIS_TYPE_ROOM
        l_id_epis_type      epis_type_room.id_epis_type%TYPE;
        l_id_epis_type_room epis_type_room.id_epis_type_room%TYPE;
        --ROOM_MCDT_TYPE
        l_room_type_epis       alert_default.room_mcdt_type.type%TYPE := 'EPIS_TYPE';
        l_room_type_lab        alert_default.room_mcdt_type.type%TYPE := 'LAB';
        l_room_type_exam       alert_default.room_mcdt_type.type%TYPE := 'EXAM';
        l_room_type_lab_quest  alert_default.room_mcdt_type.type%TYPE := 'LAB_QUEST';
        l_room_type_room_quest alert_default.room_mcdt_type.type%TYPE := 'ROOM_QUEST';
    
        l_id_room_def    room.id_room%TYPE;
        l_id_room        room.id_room%TYPE;
        l_type           alert_default.room_mcdt_type.type%TYPE;
        l_id_software    department.id_software%TYPE;
        l_id_sample_type sample_type.id_sample_type%TYPE;
    
        --QUESTIONNAIRE
        l_id_questionnaire_def questionnaire.id_questionnaire%TYPE;
        l_id_questionnaire     questionnaire.id_questionnaire%TYPE;
    
        --EXAM
        l_id_analysis_quest_def analysis.id_analysis%TYPE;
        l_id_analysis_quest     analysis.id_analysis%TYPE;
        --ANALYSIS_QUESTIONNAIRE
        l_flg_time_quest            analysis_questionnaire.flg_time%TYPE;
        l_rank_quest                analysis_questionnaire.rank%TYPE;
        l_id_analysis_questionnaire analysis_questionnaire.id_analysis_questionnaire%TYPE;
    
        l_id_stype_quest_def     analysis_questionnaire.id_sample_type%TYPE;
        l_id_stype_questionnaire analysis_questionnaire.id_sample_type%TYPE;
    
        --ROOM_QUESTIONNAIRE
        l_flg_type_room_quest   room_questionnaire.flg_type%TYPE;
        l_flg_mandatory_quest   room_questionnaire.flg_mandatory%TYPE;
        l_id_room_questionnaire room_questionnaire.id_room_questionnaire%TYPE;
    
        CURSOR c_rooms(c_id_institution institution.id_institution%TYPE) IS
            SELECT rm.id_room, mc.id_alert, rm.type, d.id_software
              FROM alert_default.room t
              JOIN alert_default.room_mcdt_type rm
                ON rm.id_room = t.id_room
              JOIN alert_default.department d
                ON d.id_department = t.id_department
               AND d.id_institution = c_id_institution
              JOIN alert_default.map_content mc
                ON mc.id_default = t.id_room
               AND mc.table_name = 'ROOM';
    
        CURSOR c_analysis
        (
            c_id_institution institution.id_institution%TYPE,
            c_id_software    software.id_software%TYPE
        ) IS
            SELECT ast.id_analysis, ast.id_sample_type
              FROM analysis_sample_type ast
             WHERE ast.flg_available = g_flg_available
               AND EXISTS (SELECT 0
                      FROM analysis_instit_soft ais
                     WHERE ais.id_analysis = ast.id_analysis
                       AND ais.id_sample_type = ast.id_sample_type
                       AND ais.id_software = c_id_software
                       AND ais.id_institution = c_id_institution
                       AND ais.flg_available = g_flg_available);
    
        CURSOR c_exams
        (
            c_id_institution institution.id_institution%TYPE,
            c_id_software    software.id_software%TYPE
        ) IS
            SELECT DISTINCT (e.id_exam)
              FROM exam e
              JOIN exam_dep_clin_serv edcs
                ON edcs.id_exam = e.id_exam
               AND edcs.id_institution = c_id_institution
               AND edcs.flg_type = pk_exam_constant.g_exam_can_req
               AND edcs.id_software = c_id_software
             WHERE e.flg_available = g_flg_available;
    
        CURSOR c_epis_type(c_id_software software.id_software%TYPE) IS
            SELECT t.id_epis_type
              FROM epis_type_soft_inst t
             WHERE t.id_institution = 0
               AND t.id_software = c_id_software;
    
        CURSOR c_epis_type_instit
        (
            c_id_institution institution.id_institution%TYPE,
            c_id_software    software.id_software%TYPE
        ) IS
            SELECT t.id_epis_type
              FROM epis_type_soft_inst t
             WHERE t.id_institution = c_id_institution
               AND t.id_software = c_id_software;
    
        CURSOR c_room_quest(c_id_room room.id_room%TYPE) IS -->MRK and VRS not validation necessary
            SELECT rq.id_questionnaire, rq.flg_type, rq.flg_mandatory
              FROM alert_default.room_questionnaire rq
              JOIN alert_default.questionnaire q
                ON q.id_questionnaire = rq.id_questionnaire
               AND q.flg_available = g_flg_available
             WHERE rq.id_room = c_id_room;
    
    BEGIN
        g_func_name              := upper('');
        o_id_analysis_room       := table_number();
        o_id_exam_room           := table_number();
        o_id_epis_type_room      := table_number();
        o_id_analysis_quest_room := table_number();
        o_id_room_questionnaire  := table_number();
    
        g_error := 'GET INSTITUTION ID';
        SELECT nvl((SELECT t.id_alert
                     FROM alert_default.map_content t
                    WHERE t.id_default = i_id_institution_def
                      AND t.table_name = 'INSTITUTION'
                      AND rownum = 1),
                   0)
          INTO l_id_institution
          FROM dual;
    
        IF l_id_institution != 0
        THEN
        
            g_error := 'OPEN C_ROOMS CURSOR';
            OPEN c_rooms(i_id_institution_def);
            LOOP
                FETCH c_rooms
                    INTO l_id_room_def, l_id_room, l_type, l_id_software;
                EXIT WHEN c_rooms%NOTFOUND;
            
                --> ANALYSIS_ROOM
                IF l_type = l_room_type_lab
                THEN
                    g_error := 'OPEN C_ANALYSIS CURSOR';
                    OPEN c_analysis(l_id_institution, l_id_software);
                    LOOP
                        FETCH c_analysis
                            INTO l_id_analysis, l_id_sample_type;
                        EXIT WHEN c_analysis%NOTFOUND;
                    
                        g_error := 'COUNT ANALYSIS_ROOM EXISTING RESULTS';
                        SELECT COUNT(t.id_analysis_room)
                          INTO l_count
                          FROM analysis_room t
                         WHERE t.id_analysis = l_id_analysis
                           AND t.id_institution = l_id_institution
                           AND t.flg_type = l_flg_type
                           AND t.flg_available = g_flg_available
                           AND t.id_room = l_id_room;
                    
                        IF l_count = 0
                        THEN
                            g_error := 'GET ANALYSIS_ROOM NETXVAL';
                            SELECT seq_analysis_room.nextval
                              INTO l_id_analysis_room
                              FROM dual;
                        
                            g_error := 'INSERT INTO ANALYSIS_ROOM';
                            INSERT INTO analysis_room
                                (id_analysis_room,
                                 id_analysis,
                                 id_room,
                                 rank,
                                 adw_last_update,
                                 flg_type,
                                 flg_available,
                                 desc_exec_destination,
                                 flg_default,
                                 id_institution,
                                 id_sample_type)
                            VALUES
                                (l_id_analysis_room,
                                 l_id_analysis,
                                 l_id_room,
                                 0,
                                 SYSDATE,
                                 l_flg_type,
                                 g_flg_available,
                                 NULL,
                                 g_flg_available,
                                 l_id_institution,
                                 l_id_sample_type);
                        
                            o_id_analysis_room.extend;
                            o_id_analysis_room(l_index_ar) := l_id_analysis_room;
                            l_index_ar := l_index_ar + 1;
                        END IF;
                    END LOOP;
                
                    g_error := 'CLOSE C_ANALYSIS CURSOR';
                    CLOSE c_analysis;
                
                END IF;
                --> EXAM_ROOM
                IF l_type = l_room_type_exam
                THEN
                
                    g_error := 'OPEN C_EXAMS CURSOR';
                    OPEN c_exams(l_id_institution, l_id_software);
                    LOOP
                        FETCH c_exams
                            INTO l_id_exam;
                        EXIT WHEN c_exams%NOTFOUND;
                    
                        g_error := 'COUNT EXAM_ROOM EXISTING RESULTS';
                        SELECT COUNT(t.id_exam_room)
                          INTO l_count
                          FROM exam_room t
                         WHERE t.id_exam = l_id_exam
                           AND t.flg_available = g_flg_available
                           AND t.id_room = l_id_room;
                    
                        IF l_count = 0
                        THEN
                            g_error := 'GET EXAM_ROOM NETXVAL';
                            SELECT seq_exam_room.nextval
                              INTO l_id_exam_room
                              FROM dual;
                        
                            g_error := 'INSERT INTO EXAM_ROOM';
                            INSERT INTO exam_room
                                (id_exam_room, id_exam, id_room, rank, adw_last_update, flg_available)
                            VALUES
                                (l_id_exam_room, l_id_exam, l_id_room, 0, SYSDATE, g_flg_available);
                        
                            o_id_exam_room.extend;
                            o_id_exam_room(l_index_er) := l_id_exam_room;
                            l_index_er := l_index_er + 1;
                        END IF;
                    END LOOP;
                
                    g_error := 'CLOSE C_EXAMS CURSOR';
                    CLOSE c_exams;
                END IF;
            
                --> EPIS_TYPE_ROOM
                IF l_type = l_room_type_epis
                THEN
                    g_error := 'COUNT EPIS_TYPE FOR INSTITUTION EXISTING RESULTS';
                    SELECT COUNT(t.id_epis_type)
                      INTO l_count
                      FROM epis_type_soft_inst t
                     WHERE t.id_institution = l_id_institution
                       AND t.id_software = l_id_software;
                
                    IF l_count != 0
                    THEN
                        g_error := 'OPEN C_EPIS_TYPE_INSTIT CURSOR';
                        OPEN c_epis_type_instit(l_id_institution, l_id_software);
                        LOOP
                            FETCH c_epis_type_instit
                                INTO l_id_epis_type;
                            EXIT WHEN c_epis_type_instit%NOTFOUND;
                        
                            g_error := 'COUNT EPIS_TYPE_ROOM EXISTING RESULTS WHEN EPIS EXISTS';
                            SELECT COUNT(e.id_epis_type_room)
                              INTO l_count_epis
                              FROM epis_type_room e
                              JOIN epis_type_soft_inst t
                                ON t.id_epis_type = e.id_epis_type
                               AND t.id_institution = e.id_institution
                               AND t.id_software = l_id_software
                             WHERE e.id_institution = l_id_institution
                               AND e.id_room = l_id_room
                               AND e.id_dep_clin_serv IS NULL
                               AND e.id_epis_type = l_id_epis_type;
                        
                            IF l_count_epis = 0
                            THEN
                                g_error := 'GET NEXTVAL - EPIS_TYPE_ROOM';
                                SELECT nvl(MAX(t.id_epis_type_room), 0) + 1
                                  INTO l_id_epis_type_room
                                  FROM epis_type_room t;
                            
                                g_error := 'INSERT INTO EPIS_TYPE_ROOM';
                                INSERT INTO epis_type_room
                                    (id_epis_type_room, id_room, id_epis_type, id_institution, id_dep_clin_serv)
                                VALUES
                                    (l_id_epis_type_room, l_id_room, l_id_epis_type, l_id_institution, NULL);
                            
                                o_id_epis_type_room.extend;
                                o_id_epis_type_room(l_index_etr) := l_id_epis_type_room;
                                l_index_etr := l_index_etr + 1;
                            END IF;
                        END LOOP;
                    
                        g_error := 'CLOSE C_EPIS_TYPE_INSTIT CURSOR';
                        CLOSE c_epis_type_instit;
                    ELSE
                        g_error := 'OPEN C_EPIS_TYPE CURSOR';
                        OPEN c_epis_type(l_id_software);
                        LOOP
                            FETCH c_epis_type
                                INTO l_id_epis_type;
                            EXIT WHEN c_epis_type%NOTFOUND;
                        
                            g_error := 'INSERT INTO EPIS_TYPE_SOFT_INST';
                            INSERT INTO epis_type_soft_inst
                                (id_epis_type, id_software, id_institution)
                            VALUES
                                (l_id_epis_type, l_id_software, l_id_institution);
                        
                            g_error := 'COUNT EPIS_TYPE_ROOM EXISTING RESULTS WHEN EPIS NOT EXISTS';
                            SELECT COUNT(e.id_epis_type_room)
                              INTO l_count_epis
                              FROM epis_type_room e
                              JOIN epis_type_soft_inst t
                                ON t.id_epis_type = e.id_epis_type
                               AND t.id_institution = e.id_institution
                               AND t.id_software = l_id_software
                             WHERE e.id_institution = l_id_institution
                               AND e.id_room = l_id_room
                               AND e.id_dep_clin_serv IS NULL
                               AND e.id_epis_type = l_id_epis_type;
                        
                            IF l_count_epis = 0
                            THEN
                                g_error := 'GET NEXTVAL - EPIS_TYPE_ROOM';
                                SELECT nvl(MAX(t.id_epis_type_room), 0) + 1
                                  INTO l_id_epis_type_room
                                  FROM epis_type_room t;
                            
                                g_error := 'INSERT INTO EPIS_TYPE_ROOM';
                                INSERT INTO epis_type_room
                                    (id_epis_type_room, id_room, id_epis_type, id_institution, id_dep_clin_serv)
                                VALUES
                                    (l_id_epis_type_room, l_id_room, l_id_epis_type, l_id_institution, NULL);
                            
                                o_id_epis_type_room.extend;
                                o_id_epis_type_room(l_index_etr) := l_id_epis_type_room;
                                l_index_etr := l_index_etr + 1;
                            END IF;
                        END LOOP;
                    
                        g_error := 'CLOSE C_EPIS_TYPE CURSOR';
                        CLOSE c_epis_type;
                    
                    END IF;
                
                END IF;
            
                --> ANALYSIS_QUESTIONNAIRE
                --> ROOM_QUESTIONNAIRE
                IF l_type = l_room_type_room_quest
                THEN
                    g_error := 'OPEN C_ROOM_QUEST CURSOR';
                    OPEN c_room_quest(l_id_room_def);
                    LOOP
                        FETCH c_room_quest
                            INTO l_id_questionnaire_def, l_flg_type_room_quest, l_flg_mandatory_quest;
                        EXIT WHEN c_room_quest%NOTFOUND;
                    
                        --QUESTIONNARIE
                        g_error := 'GET QUESTIONNARIE ID';
                        SELECT nvl((SELECT q1.id_questionnaire
                                     FROM questionnaire q1
                                    WHERE q1.id_content =
                                          (SELECT q2.id_content
                                             FROM alert_default.questionnaire q2
                                            WHERE q2.id_questionnaire = l_id_questionnaire_def)
                                      AND q1.id_content IS NOT NULL
                                      AND q1.flg_available = g_flg_available
                                      AND rownum = 1),
                                   0)
                          INTO l_id_questionnaire
                          FROM dual;
                    
                        IF l_id_questionnaire != 0
                        THEN
                            g_error := 'COUNT ROOM_QUESTIONNAIRE EXISTING RESULTS';
                            SELECT COUNT(rq.id_room_questionnaire)
                              INTO l_count
                              FROM room_questionnaire rq
                             WHERE rq.id_questionnaire = l_id_questionnaire
                               AND rq.id_room = l_id_room;
                        
                            IF l_count = 0
                            THEN
                                g_error := 'GET SEQ_ROOM_QUESTIONNAIRE.NEXTVAL';
                                SELECT seq_room_questionnaire.nextval
                                  INTO l_id_room_questionnaire
                                  FROM dual;
                            
                                g_error := 'INSERT INTO ROOM_QUESTIONNAIRE';
                                INSERT INTO room_questionnaire
                                    (id_room_questionnaire,
                                     id_questionnaire,
                                     id_room,
                                     flg_type,
                                     flg_mandatory,
                                     flg_available)
                                VALUES
                                    (l_id_room_questionnaire,
                                     l_id_questionnaire,
                                     l_id_room,
                                     l_flg_type_room_quest,
                                     l_flg_mandatory_quest,
                                     g_flg_available);
                            
                                o_id_room_questionnaire.extend;
                                o_id_room_questionnaire(l_index_rq) := l_id_room_questionnaire;
                                l_index_rq := l_index_rq + 1;
                            END IF;
                        END IF;
                    
                    END LOOP;
                    g_error := 'CLOSE C_ROOM_QUEST CURSOR';
                    CLOSE c_room_quest;
                
                END IF;
            END LOOP;
        
            g_error := 'CLOSE C_ROOMS CURSOR';
            CLOSE c_rooms;
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
                                              'SET_ROOMS_POS_DEFAULT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_rooms_pos_default;
    /******************************************************
    *  DELETE DEFAULT Structure in ALERT SIDE             *
    *                                                     *
    * @param i_id_institution       Alert Institution ID  *
    *                                                     *
    ******************************************************/
    PROCEDURE delete_1def_structure
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_del_content    IN VARCHAR2 DEFAULT 'N',
        o_error          OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
        g_error     VARCHAR2(2000);
    
        CURSOR c_instits(c_id_institution institution.id_institution%TYPE) IS
            SELECT t.id_institution
              FROM institution t
              JOIN alert_default.map_content mc
                ON mc.id_alert = t.id_institution
               AND mc.table_name = 'INSTITUTION'
             WHERE t.id_institution = c_id_institution;
    
        CURSOR c_dcs(c_id_institution institution.id_institution%TYPE) IS
            SELECT t.id_dep_clin_serv
              FROM dep_clin_serv t
             WHERE t.id_department IN (SELECT d.id_department
                                         FROM department d
                                        WHERE d.id_institution = c_id_institution);
    
        CURSOR c_department(c_id_institution institution.id_institution%TYPE) IS
            SELECT d.id_department
              FROM department d
             WHERE d.id_institution = c_id_institution;
    
        CURSOR c_floors(c_id_institution institution.id_institution%TYPE) IS
            SELECT DISTINCT mc.id_alert, mc.id_default
              FROM alert_default.map_content d
              JOIN alert_default.floors_institution fi
                ON fi.id_institution = d.id_default
              JOIN alert_default.floors b
                ON b.id_floors = fi.id_floors
              JOIN alert_default.map_content mc
                ON mc.id_default = b.id_floors
               AND mc.table_name = 'FLOORS'
             WHERE d.id_alert = c_id_institution
               AND d.table_name = 'INSTITUTION';
    
        CURSOR c_building(c_id_institution institution.id_institution%TYPE) IS
            SELECT DISTINCT mc.id_alert, mc.id_default
              FROM alert_default.map_content d
              JOIN alert_default.floors_institution fi
                ON fi.id_institution = d.id_default
              JOIN alert_default.building b
                ON b.id_building = fi.id_building
              JOIN alert_default.map_content mc
                ON mc.id_default = b.id_building
               AND mc.table_name = 'BUILDING'
             WHERE d.id_alert = c_id_institution
               AND d.table_name = 'INSTITUTION';
    
    BEGIN
        g_func_name := upper('');
        g_error     := 'DELETE LOGS';
        DELETE FROM alert_default.logs;
    
        FOR i IN c_instits(i_id_institution)
        LOOP
            FOR x IN c_dcs(i.id_institution)
            LOOP
                g_error := 'DELETE BED_DEP_CLIN_SERV';
                DELETE FROM bed_dep_clin_serv t
                 WHERE t.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ROOM_DEP_CLIN_SERV';
                DELETE FROM room_dep_clin_serv t
                 WHERE t.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EXAM_DEP_CLIN_SERV FREQUENT';
                DELETE FROM exam_dep_clin_serv p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ANALYSIS_DEP_CLIN_SERV FREQUENT';
                DELETE FROM analysis_dep_clin_serv p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EXAM_CAT_DCS';
                DELETE FROM exam_cat_dcs p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ICNP_COMPO_DCS';
                DELETE FROM icnp_compo_dcs icd
                 WHERE icd.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ICNP_AXIS_DCS';
                DELETE FROM icnp_axis_dcs iad
                 WHERE iad.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DIAGNOSIS_DCS';
                DELETE FROM diagnosis_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DOC_TEMPLATE_CONTEXT';
                DELETE FROM doc_template_context dtc
                 WHERE dtc.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DRUG_DCS';
                DELETE FROM drug_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EMB_DCS';
                DELETE FROM emb_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE INTERV_DCS';
                DELETE FROM interv_dep_clin_serv idcs
                 WHERE idcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE SR_INTERV_DCS';
                DELETE FROM interv_dep_clin_serv sidcs
                 WHERE sidcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE SAMPLE_TEXT_FREQ';
                DELETE FROM sample_text_freq stf
                 WHERE stf.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE REHAB_DCS';
                DELETE FROM rehab_dep_clin_serv rdcs
                 WHERE rdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE PML_DCS';
                DELETE FROM pml_dep_clin_serv pdcs
                 WHERE pdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ETR';
                DELETE FROM epis_type_room etr
                 WHERE etr.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DIAG_LAY_DCS';
                DELETE FROM diag_lay_dep_clin_serv dldcs
                 WHERE dldcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ADM_IND_DCS';
                DELETE FROM adm_ind_dep_clin_serv aidcs
                 WHERE aidcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE BODY_STRUCTURE_DCS';
                DELETE FROM body_structure_dcs bsdcs
                 WHERE bsdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
            END LOOP;
        
            FOR x IN c_department(i.id_institution)
            LOOP
                g_error := 'DELETE ANALYSIS_ROOM';
                DELETE FROM analysis_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE ANALYSIS_QUESTIONNAIRE';
                DELETE FROM analysis_questionnaire t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE ROOM_QUESTIONNAIRE';
                DELETE FROM room_questionnaire t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE EXAM_ROOM';
                DELETE FROM exam_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE BED';
                DELETE FROM bed t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE EPIS_TYPE_ROOM';
                DELETE FROM epis_type_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE DEF MAPPING ROOMS';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_alert IN (SELECT t.id_room
                                        FROM room t
                                       WHERE t.id_department = x.id_department)
                   AND d.table_name = 'ROOM';
            
                g_error := 'DELETE ROOM';
                DELETE FROM room t
                 WHERE t.id_department = x.id_department;
            
                g_error := 'DELETE DEP_CLIN_SERV';
                DELETE FROM dep_clin_serv dcs
                 WHERE dcs.id_department = x.id_department;
            
                g_error := 'DELETE FLOORS_DEP_POSITION';
                DELETE FROM floors_dep_position fdp
                 WHERE fdp.id_floors_department IN
                       (SELECT f.id_floors_department
                          FROM floors_department f
                         WHERE f.id_department = x.id_department);
            
                g_error := 'DELETE FLOORS_DEPARTMENT';
                DELETE FROM floors_department f
                 WHERE f.id_department = x.id_department;
            
                g_error := 'DELETE DEPT_TEMPLATE';
                DELETE FROM dept_template f
                 WHERE f.id_department = x.id_department;
            END LOOP;
        
            g_error := 'DELETE DEF MAPPING FLOORS_INSTITUTION';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert IN (SELECT t.id_floors_institution
                                    FROM floors_institution t
                                   WHERE t.id_institution = i.id_institution)
               AND d.table_name = 'FLOORS_INSTITUTION';
        
            g_error := 'DELETE FLOORS_INSTITUTION';
            DELETE FROM floors_institution t
             WHERE t.id_institution = i.id_institution;
        
            FOR k IN c_floors(i.id_institution)
            LOOP
                g_error := 'DELETE DEF MAPPING FLOORS';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_default = k.id_default
                   AND d.table_name = 'FLOORS';
            
                g_error := 'DELETE FLOORS';
                DELETE FROM floors t
                 WHERE t.id_floors = k.id_alert;
            
            END LOOP;
        
            FOR k IN c_building(i.id_institution)
            LOOP
            
                g_error := 'DELETE DEF MAPPING BUILDING';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_default = k.id_default
                   AND d.table_name = 'BUILDING';
            
                g_error := 'DELETE BUILDING';
                DELETE FROM building b
                 WHERE b.id_building = k.id_alert;
            
            END LOOP;
        
            g_error := 'DELETE EXAM_DEP_CLIN_SERV SEARCHABLE';
            DELETE FROM exam_dep_clin_serv p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE EXAM_TYPE_GROUP';
            DELETE FROM exam_type_group p
             WHERE p.id_institution = i.id_institution;
        
            -->Analysis
            g_error := 'DELETE ANALYSIS_PARAM_FUNCTIONALITY';
            DELETE FROM analysis_param_funcionality t
             WHERE t.id_analysis_param IN (SELECT t.id_analysis_param
                                             FROM analysis_param t
                                            WHERE t.id_institution = i.id_institution);
        
            g_error := 'DELETE ANALYSIS_INSTIT_RECIPIENT';
            DELETE FROM analysis_instit_recipient t
             WHERE t.id_analysis_instit_soft IN
                   (SELECT t.id_analysis_instit_soft
                      FROM analysis_instit_soft t
                     WHERE t.id_institution = i.id_institution);
        
            g_error := 'DELETE ANALYSIS_INSTIT_SOFT SEARCHABLE';
            DELETE FROM analysis_instit_soft t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_UNIT_MEASURE';
            DELETE FROM analysis_unit_measure t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE UNIT_MEA_SOFT_INST';
            DELETE FROM unit_mea_soft_inst t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_LOINC';
            DELETE FROM analysis_loinc t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_PARAM';
            DELETE FROM analysis_param t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE DEF MAPPING DEPARTMENT';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert IN (SELECT t.id_department
                                    FROM department t
                                   WHERE t.id_institution = i.id_institution)
               AND d.table_name = 'DEPARTMENT';
        
            g_error := 'DELETE DEPARTMENT';
            DELETE FROM department t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE SOFTWARE_DEPT';
            DELETE FROM software_dept p
             WHERE p.id_dept IN (SELECT d.id_dept
                                   FROM dept d
                                  WHERE d.id_institution = i.id_institution);
        
            g_error := 'DELETE DEPT';
            DELETE FROM dept d
             WHERE d.id_institution = i.id_institution;
        
            g_error := 'DELETE INST_ATTRIBUTES';
            DELETE FROM inst_attributes p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SYS_CONFIG';
            DELETE FROM sys_config sc
             WHERE sc.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_IN_OUT';
            DELETE FROM prof_in_out t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_PREFERENCES';
            DELETE FROM prof_preferences p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_CAT';
            DELETE FROM prof_cat p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_PROFILE_TEMPLATE';
            DELETE FROM prof_profile_template p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_INSTITUTION';
            DELETE FROM prof_institution p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_SOFT_INST';
            DELETE FROM prof_soft_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SOFTWARE_INSTITUTION';
            DELETE FROM software_institution p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE INSTITUTION_LANGUAGE';
            DELETE FROM institution_language p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE INSTITUTION_LOGO';
            DELETE FROM institution_logo p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SYS_REQUEST';
            DELETE FROM sys_request t
             WHERE t.id_sys_session IN
                   (SELECT t.id_sys_session
                      FROM sys_session t
                     WHERE t.id_professional LIKE '' || i.id_institution || '%');
        
            g_error := 'DELETE SYS_SESSION';
            DELETE FROM sys_session t
             WHERE t.id_professional LIKE '' || i.id_institution || '%';
        
            g_error := 'DELETE PROFESSIONAL';
            DELETE FROM professional p
             WHERE p.id_professional LIKE '' || i.id_institution || '%';
        
            g_error := 'DELETE EPIS_TYPE_SOFT_INST';
            DELETE FROM epis_type_soft_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SAMPLE_TEXT_TYPE_CAT';
            DELETE FROM sample_text_type_cat p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE DOC_AREA_INST_SOFT';
            DELETE FROM doc_area_inst_soft p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROFILE_DISCH_REASON';
            DELETE FROM profile_disch_reason p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE NOTES_PROFILE_INST';
            DELETE FROM notes_profile_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE CHECKLIST_INST';
            DELETE FROM checklist_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE HIDRICS_CONFIGURATIONS';
            DELETE FROM hidrics_configurations p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE HIDRICS_LOCATION_REL';
            DELETE FROM hidrics_location_rel p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE icnp_axis_dcs';
            DELETE FROM icnp_axis_dcs iad
             WHERE iad.id_institution = i.id_institution;
        
            g_error := 'DELETE DIAGNOSIS_DCS';
            DELETE FROM diagnosis_dep_clin_serv ddcs
             WHERE ddcs.id_institution = i.id_institution;
        
            g_error := 'DELETE DRUG_DCS';
            DELETE FROM drug_dep_clin_serv ddcs
             WHERE ddcs.id_institution = i.id_institution;
        
            g_error := 'DELETE EMB_DCS';
            DELETE FROM emb_dep_clin_serv edcs
             WHERE edcs.id_institution = i.id_institution;
        
            g_error := 'DELETE INTERV_DCS';
            DELETE FROM interv_dep_clin_serv idcs
             WHERE idcs.id_institution = i.id_institution;
        
            g_error := 'DELETE SR_INTERV_DCS';
            DELETE FROM interv_dep_clin_serv sidcs
             WHERE sidcs.id_institution = i.id_institution;
        
            g_error := 'DELETE SAMPLE_TEXT_TYPE_CAT';
            DELETE FROM sample_text_type_cat sttc
             WHERE sttc.id_institution = i.id_institution;
        
            g_error := 'DELETE DISCH_INST_RELATION';
            DELETE FROM disch_instr_relation dir
             WHERE dir.id_institution = i.id_institution;
        
            g_error := 'DELETE DISCH_REAS_DEST';
            DELETE FROM disch_reas_dest drd
             WHERE drd.id_instit_param = i.id_institution;
        
            g_error := 'DELETE DOC_TEMPLATE';
            DELETE FROM doc_template_context dtc
             WHERE dtc.id_institution = i.id_institution;
            -- Guideline
            g_error := 'DELETE GUIDELINE';
            DELETE FROM guideline_process_task_det gptd
             WHERE gptd.id_guideline_process_task IN
                   (SELECT gpt.id_guideline_process_task
                      FROM guideline_process_task gpt
                     WHERE gpt.id_guideline_process IN
                           (SELECT gp.id_guideline_process
                              FROM guideline_process gp
                             WHERE gp.id_guideline IN (SELECT g.id_guideline
                                                         FROM guideline g
                                                        WHERE g.id_institution = i.id_institution)));
        
            DELETE FROM guideline_adv_input_value gaiv
             WHERE gaiv.id_adv_input_link IN
                   (SELECT gtl.id_guideline_task_link
                      FROM guideline_task_link gtl
                     WHERE gtl.id_guideline IN (SELECT g.id_guideline
                                                  FROM guideline g
                                                 WHERE g.id_institution = i.id_institution));
        
            DELETE FROM guideline_task_link gtl
             WHERE gtl.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_link gl
             WHERE gl.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_frequent gf
             WHERE gf.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_criteria_link gcl
             WHERE gcl.id_guideline_criteria IN
                   (SELECT gc.id_guideline_criteria
                      FROM guideline_criteria gc
                     WHERE gc.id_guideline IN (SELECT g.id_guideline
                                                 FROM guideline g
                                                WHERE g.id_institution = i.id_institution));
        
            DELETE FROM guideline_criteria gc
             WHERE gc.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_context_image gci
             WHERE gci.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_context_author gca
             WHERE gca.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline g
             WHERE g.id_institution = i.id_institution;
        
            -- protocol
            g_error := 'DELETE PROTOCOL';
            DELETE FROM protocol_frequent pf
             WHERE pf.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_relation pr
             WHERE pr.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_context_image pci
             WHERE pci.id_protocol IN (SELECT p.id_protocol
                                         FROM protocol p
                                        WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_context_author pca
             WHERE pca.id_protocol IN (SELECT p.id_protocol
                                         FROM protocol p
                                        WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_adv_input_value paiv
             WHERE paiv.id_adv_input_link IN
                   (SELECT pc.id_protocol_criteria
                      FROM protocol_criteria pc
                     WHERE pc.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_criteria_link pcl
             WHERE pcl.id_protocol_criteria IN
                   (SELECT pc.id_protocol_criteria
                      FROM protocol_criteria pc
                     WHERE pc.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_criteria pc
             WHERE pc.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_task pt
             WHERE pt.id_group_task IN
                   (SELECT pe.id_element
                      FROM protocol_element pe
                     WHERE pe.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_element pe
             WHERE pe.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_link pl
             WHERE pl.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol p
             WHERE p.id_institution = i.id_institution;
            -- Order SEt
            g_error := 'DELETE ORDER SET';
            DELETE FROM order_set_task_detail ostd
             WHERE ostd.id_order_set_task IN
                   (SELECT ost.id_order_set_task
                      FROM order_set_task ost
                     INNER JOIN order_set os
                        ON (os.id_order_set = ost.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE order_set_task_link ostl
             WHERE ostl.id_order_set_task IN
                   (SELECT ost.id_order_set_task
                      FROM order_set_task ost
                     INNER JOIN order_set os
                        ON (os.id_order_set = ost.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_task_dependency ostd
             WHERE ostd.id_order_set IN (SELECT os.id_order_set
                                           FROM order_set os
                                          WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_task ost
             WHERE ost.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_frequent osf
             WHERE osf.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE order_set_link osl
             WHERE osl.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_process_task_link osptl
             WHERE osptl.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     INNER JOIN order_set_process osp
                        ON (osp.id_order_set_process = ospt.id_order_set_process)
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task_det osptd
             WHERE osptd.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     INNER JOIN order_set_process osp
                        ON (osp.id_order_set_process = ospt.id_order_set_process)
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task_depend osptd
             WHERE osptd.id_order_set_process IN
                   (SELECT osp.id_order_set_process
                      FROM order_set_process osp
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task ospt
             WHERE ospt.id_order_set_process IN
                   (SELECT osp.id_order_set_process
                      FROM order_set_process osp
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process osp
             WHERE osp.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            g_error := 'DELETE HEALTH_PROGRAM_SI';
            DELETE FROM health_program_soft_inst hpsi
             WHERE hpsi.id_institution = i.id_institution;
        
            g_error := 'DELETE INTERV_DRUG';
            DELETE FROM interv_drug id
             WHERE id.id_institution = i.id_institution;
        
            g_error := 'DELETE DEF MAPPING INSTITUTION';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert = i.id_institution
               AND d.table_name = 'INSTITUTION';
        
            g_error := 'DELETE INSTITUTION';
            DELETE FROM institution d
             WHERE d.id_institution = i.id_institution;
        
        END LOOP;
    
        /*IF i_del_content = 'Y'
        THEN
            --DELETE FROM analysis;
            --execute immediate 'truncate table analysis;';
            --DELETE FROM exam;
            --execute immediate 'truncate table exam;';
        END IF;*/
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DEF_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            ROLLBACK;
            pk_api_backoffice_default.process_error('PK_API_BACKOFFICE_DEFAULT.DELETE_ALL_DEF_STRUCTURE', g_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DEF_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            ROLLBACK;
            pk_api_backoffice_default.process_error('PK_API_BACKOFFICE_DEFAULT.DELETE_ALL_DEF_STRUCTURE', g_error);
    END;
    /******************************************************
    *  DELETE DEFAULT Structure in ALERT SIDE             *
    *                                                     *
    * @param i_id_institution       Alert Institution ID  *
    *                                                     *
    ******************************************************/
    PROCEDURE delete_all_def_structure(o_error OUT t_error_out) IS
    
        l_exception EXCEPTION;
        l_error_out t_error_out;
        g_error     VARCHAR2(2000);
    
        CURSOR c_instits IS
            SELECT t.id_institution
              FROM institution t
              JOIN alert_default.map_content mc
                ON mc.id_alert = t.id_institution
               AND mc.table_name = 'INSTITUTION';
    
        CURSOR c_dcs(c_id_institution institution.id_institution%TYPE) IS
            SELECT t.id_dep_clin_serv
              FROM dep_clin_serv t
             WHERE t.id_department IN (SELECT d.id_department
                                         FROM department d
                                        WHERE d.id_institution = c_id_institution);
    
        CURSOR c_department(c_id_institution institution.id_institution%TYPE) IS
            SELECT d.id_department
              FROM department d
             WHERE d.id_institution = c_id_institution;
    
        CURSOR c_floors(c_id_institution institution.id_institution%TYPE) IS
            SELECT DISTINCT mc.id_alert, mc.id_default
              FROM alert_default.map_content d
              JOIN alert_default.floors_institution fi
                ON fi.id_institution = d.id_default
              JOIN alert_default.floors b
                ON b.id_floors = fi.id_floors
              JOIN alert_default.map_content mc
                ON mc.id_default = b.id_floors
               AND mc.table_name = 'FLOORS'
             WHERE d.id_alert = c_id_institution
               AND d.table_name = 'INSTITUTION';
    
        CURSOR c_building(c_id_institution institution.id_institution%TYPE) IS
            SELECT DISTINCT mc.id_alert, mc.id_default
              FROM alert_default.map_content d
              JOIN alert_default.floors_institution fi
                ON fi.id_institution = d.id_default
              JOIN alert_default.building b
                ON b.id_building = fi.id_building
              JOIN alert_default.map_content mc
                ON mc.id_default = b.id_building
               AND mc.table_name = 'BUILDING'
             WHERE d.id_alert = c_id_institution
               AND d.table_name = 'INSTITUTION';
    
    BEGIN
        g_func_name := upper('');
        g_error     := 'DELETE LOGS';
        DELETE FROM alert_default.logs;
    
        FOR i IN c_instits
        LOOP
            FOR x IN c_dcs(i.id_institution)
            LOOP
                g_error := 'DELETE BED_DEP_CLIN_SERV';
                DELETE FROM bed_dep_clin_serv t
                 WHERE t.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ROOM_DEP_CLIN_SERV';
                DELETE FROM room_dep_clin_serv t
                 WHERE t.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EXAM_DEP_CLIN_SERV FREQUENT';
                DELETE FROM exam_dep_clin_serv p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ANALYSIS_DEP_CLIN_SERV FREQUENT';
                DELETE FROM analysis_dep_clin_serv p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EXAM_CAT_DCS';
                DELETE FROM exam_cat_dcs p
                 WHERE p.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ICNP_COMPO_DCS';
                DELETE FROM icnp_compo_dcs icd
                 WHERE icd.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ICNP_AXIS_DCS';
                DELETE FROM icnp_axis_dcs iad
                 WHERE iad.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DIAGNOSIS_DCS';
                DELETE FROM diagnosis_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DOC_TEMPLATE_CONTEXT';
                DELETE FROM doc_template_context dtc
                 WHERE dtc.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DRUG_DCS';
                DELETE FROM drug_dep_clin_serv ddcs
                 WHERE ddcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE EMB_DCS';
                DELETE FROM emb_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE INTERV_DCS';
                DELETE FROM interv_dep_clin_serv idcs
                 WHERE idcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE SR_INTERV_DCS';
                DELETE FROM interv_dep_clin_serv sidcs
                 WHERE sidcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE SAMPLE_TEXT_FREQ';
                DELETE FROM sample_text_freq stf
                 WHERE stf.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE REHAB_DCS';
                DELETE FROM rehab_dep_clin_serv rdcs
                 WHERE rdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE PML_DCS';
                DELETE FROM pml_dep_clin_serv pdcs
                 WHERE pdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ETR';
                DELETE FROM epis_type_room etr
                 WHERE etr.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE DIAG_LAY_DCS';
                DELETE FROM diag_lay_dep_clin_serv dldcs
                 WHERE dldcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE ADM_IND_DCS';
                DELETE FROM adm_ind_dep_clin_serv aidcs
                 WHERE aidcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
                g_error := 'DELETE BODY_STRUCTURE_DCS';
                DELETE FROM body_structure_dcs bsdcs
                 WHERE bsdcs.id_dep_clin_serv = x.id_dep_clin_serv;
            
            END LOOP;
        
            FOR x IN c_department(i.id_institution)
            LOOP
                g_error := 'DELETE ANALYSIS_ROOM';
                DELETE FROM analysis_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE ANALYSIS_QUESTIONNAIRE';
                DELETE FROM analysis_questionnaire t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE ROOM_QUESTIONNAIRE';
                DELETE FROM room_questionnaire t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE EXAM_ROOM';
                DELETE FROM exam_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE BED';
                DELETE FROM bed t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE EPIS_TYPE_ROOM';
                DELETE FROM epis_type_room t
                 WHERE t.id_room IN (SELECT r.id_room
                                       FROM room r
                                      WHERE r.id_department = x.id_department);
            
                g_error := 'DELETE DEF MAPPING ROOMS';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_alert IN (SELECT t.id_room
                                        FROM room t
                                       WHERE t.id_department = x.id_department)
                   AND d.table_name = 'ROOM';
            
                g_error := 'DELETE ROOM';
                DELETE FROM room t
                 WHERE t.id_department = x.id_department;
            
                g_error := 'DELETE DEP_CLIN_SERV';
                DELETE FROM dep_clin_serv dcs
                 WHERE dcs.id_department = x.id_department;
            
                g_error := 'DELETE FLOORS_DEP_POSITION';
                DELETE FROM floors_dep_position fdp
                 WHERE fdp.id_floors_department IN
                       (SELECT f.id_floors_department
                          FROM floors_department f
                         WHERE f.id_department = x.id_department);
            
                g_error := 'DELETE FLOORS_DEPARTMENT';
                DELETE FROM floors_department f
                 WHERE f.id_department = x.id_department;
            
                g_error := 'DELETE DEPT_TEMPLATE';
                DELETE FROM dept_template f
                 WHERE f.id_department = x.id_department;
            END LOOP;
        
            g_error := 'DELETE DEF MAPPING FLOORS_INSTITUTION';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert IN (SELECT t.id_floors_institution
                                    FROM floors_institution t
                                   WHERE t.id_institution = i.id_institution)
               AND d.table_name = 'FLOORS_INSTITUTION';
        
            g_error := 'DELETE FLOORS_INSTITUTION';
            DELETE FROM floors_institution t
             WHERE t.id_institution = i.id_institution;
        
            FOR k IN c_floors(i.id_institution)
            LOOP
                g_error := 'DELETE DEF MAPPING FLOORS';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_default = k.id_default
                   AND d.table_name = 'FLOORS';
            
                g_error := 'DELETE FLOORS';
                DELETE FROM floors t
                 WHERE t.id_floors = k.id_alert;
            
            END LOOP;
        
            FOR k IN c_building(i.id_institution)
            LOOP
            
                g_error := 'DELETE DEF MAPPING BUILDING';
                DELETE FROM alert_default.map_content d
                 WHERE d.id_default = k.id_default
                   AND d.table_name = 'BUILDING';
            
                g_error := 'DELETE BUILDING';
                DELETE FROM building b
                 WHERE b.id_building = k.id_alert;
            
            END LOOP;
        
            g_error := 'DELETE EXAM_DEP_CLIN_SERV SEARCHABLE';
            DELETE FROM exam_dep_clin_serv p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE EXAM_TYPE_GROUP';
            DELETE FROM exam_type_group p
             WHERE p.id_institution = i.id_institution;
        
            -->Analysis
            g_error := 'DELETE ANALYSIS_PARAM_FUNCTIONALITY';
            DELETE FROM analysis_param_funcionality t
             WHERE t.id_analysis_param IN (SELECT t.id_analysis_param
                                             FROM analysis_param t
                                            WHERE t.id_institution = i.id_institution);
        
            g_error := 'DELETE ANALYSIS_INSTIT_RECIPIENT';
            DELETE FROM analysis_instit_recipient t
             WHERE t.id_analysis_instit_soft IN
                   (SELECT t.id_analysis_instit_soft
                      FROM analysis_instit_soft t
                     WHERE t.id_institution = i.id_institution);
        
            g_error := 'DELETE ANALYSIS_INSTIT_SOFT SEARCHABLE';
            DELETE FROM analysis_instit_soft t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_UNIT_MEASURE';
            DELETE FROM analysis_unit_measure t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE UNIT_MEA_SOFT_INST';
            DELETE FROM unit_mea_soft_inst t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_LOINC';
            DELETE FROM analysis_loinc t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE ANALYSIS_PARAM';
            DELETE FROM analysis_param t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE DEF MAPPING DEPARTMENT';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert IN (SELECT t.id_department
                                    FROM department t
                                   WHERE t.id_institution = i.id_institution)
               AND d.table_name = 'DEPARTMENT';
        
            g_error := 'DELETE DEPARTMENT';
            DELETE FROM department t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE SOFTWARE_DEPT';
            DELETE FROM software_dept p
             WHERE p.id_dept IN (SELECT d.id_dept
                                   FROM dept d
                                  WHERE d.id_institution = i.id_institution);
        
            g_error := 'DELETE DEPT';
            DELETE FROM dept d
             WHERE d.id_institution = i.id_institution;
        
            g_error := 'DELETE INST_ATTRIBUTES';
            DELETE FROM inst_attributes p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SYS_CONFIG';
            DELETE FROM sys_config sc
             WHERE sc.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_IN_OUT';
            DELETE FROM prof_in_out t
             WHERE t.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_PREFERENCES';
            DELETE FROM prof_preferences p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_CAT';
            DELETE FROM prof_cat p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_PROFILE_TEMPLATE';
            DELETE FROM prof_profile_template p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_INSTITUTION';
            DELETE FROM prof_institution p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROF_SOFT_INST';
            DELETE FROM prof_soft_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SOFTWARE_INSTITUTION';
            DELETE FROM software_institution p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE INSTITUTION_LANGUAGE';
            DELETE FROM institution_language p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE INSTITUTION_LOGO';
            DELETE FROM institution_logo p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SYS_REQUEST';
            DELETE FROM sys_request t
             WHERE t.id_sys_session IN
                   (SELECT t.id_sys_session
                      FROM sys_session t
                     WHERE t.id_professional LIKE '' || i.id_institution || '%');
        
            g_error := 'DELETE SYS_SESSION';
            DELETE FROM sys_session t
             WHERE t.id_professional LIKE '' || i.id_institution || '%';
        
            g_error := 'DELETE PROFESSIONAL';
            DELETE FROM professional p
             WHERE p.id_professional LIKE '' || i.id_institution || '%';
        
            g_error := 'DELETE EPIS_TYPE_SOFT_INST';
            DELETE FROM epis_type_soft_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE SAMPLE_TEXT_TYPE_CAT';
            DELETE FROM sample_text_type_cat p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE DOC_AREA_INST_SOFT';
            DELETE FROM doc_area_inst_soft p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE PROFILE_DISCH_REASON';
            DELETE FROM profile_disch_reason p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE NOTES_PROFILE_INST';
            DELETE FROM notes_profile_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE CHECKLIST_INST';
            DELETE FROM checklist_inst p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE HIDRICS_CONFIGURATIONS';
            DELETE FROM hidrics_configurations p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE HIDRICS_LOCATION_REL';
            DELETE FROM hidrics_location_rel p
             WHERE p.id_institution = i.id_institution;
        
            g_error := 'DELETE icnp_axis_dcs';
            DELETE FROM icnp_axis_dcs iad
             WHERE iad.id_institution = i.id_institution;
        
            g_error := 'DELETE DIAGNOSIS_DCS';
            DELETE FROM diagnosis_dep_clin_serv ddcs
             WHERE ddcs.id_institution = i.id_institution;
        
            g_error := 'DELETE DRUG_DCS';
            DELETE FROM drug_dep_clin_serv ddcs
             WHERE ddcs.id_institution = i.id_institution;
        
            g_error := 'DELETE EMB_DCS';
            DELETE FROM emb_dep_clin_serv edcs
             WHERE edcs.id_institution = i.id_institution;
        
            g_error := 'DELETE INTERV_DCS';
            DELETE FROM interv_dep_clin_serv idcs
             WHERE idcs.id_institution = i.id_institution;
        
            g_error := 'DELETE SR_INTERV_DCS';
            DELETE FROM interv_dep_clin_serv sidcs
             WHERE sidcs.id_institution = i.id_institution;
        
            g_error := 'DELETE SAMPLE_TEXT_TYPE_CAT';
            DELETE FROM sample_text_type_cat sttc
             WHERE sttc.id_institution = i.id_institution;
        
            g_error := 'DELETE DISCH_INST_RELATION';
            DELETE FROM disch_instr_relation dir
             WHERE dir.id_institution = i.id_institution;
        
            g_error := 'DELETE DISCH_REAS_DEST';
            DELETE FROM disch_reas_dest drd
             WHERE drd.id_instit_param = i.id_institution;
        
            g_error := 'DELETE DISCH_REAS_DEST';
            DELETE FROM doc_template_context dtc
             WHERE dtc.id_institution = i.id_institution;
        
            -- Guideline
            g_error := 'DELETE GUIDELINE';
            DELETE FROM guideline_process_task_det gptd
             WHERE gptd.id_guideline_process_task IN
                   (SELECT gpt.id_guideline_process_task
                      FROM guideline_process_task gpt
                     WHERE gpt.id_guideline_process IN
                           (SELECT gp.id_guideline_process
                              FROM guideline_process gp
                             WHERE gp.id_guideline IN (SELECT g.id_guideline
                                                         FROM guideline g
                                                        WHERE g.id_institution = i.id_institution)));
        
            DELETE FROM guideline_adv_input_value gaiv
             WHERE gaiv.id_adv_input_link IN
                   (SELECT gtl.id_guideline_task_link
                      FROM guideline_task_link gtl
                     WHERE gtl.id_guideline IN (SELECT g.id_guideline
                                                  FROM guideline g
                                                 WHERE g.id_institution = i.id_institution));
        
            DELETE FROM guideline_task_link gtl
             WHERE gtl.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_link gl
             WHERE gl.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_frequent gf
             WHERE gf.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_criteria_link gcl
             WHERE gcl.id_guideline_criteria IN
                   (SELECT gc.id_guideline_criteria
                      FROM guideline_criteria gc
                     WHERE gc.id_guideline IN (SELECT g.id_guideline
                                                 FROM guideline g
                                                WHERE g.id_institution = i.id_institution));
        
            DELETE FROM guideline_criteria gc
             WHERE gc.id_guideline IN (SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_context_image gci
             WHERE gci.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline_context_author gca
             WHERE gca.id_guideline IN (SELECT g.id_guideline
                                          FROM guideline g
                                         WHERE g.id_institution = i.id_institution);
        
            DELETE FROM guideline g
             WHERE g.id_institution = i.id_institution;
        
            -- protocol
            g_error := 'DELETE PROTOCOL';
            DELETE FROM protocol_frequent pf
             WHERE pf.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_relation pr
             WHERE pr.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_context_image pci
             WHERE pci.id_protocol IN (SELECT p.id_protocol
                                         FROM protocol p
                                        WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_context_author pca
             WHERE pca.id_protocol IN (SELECT p.id_protocol
                                         FROM protocol p
                                        WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_adv_input_value paiv
             WHERE paiv.id_adv_input_link IN
                   (SELECT pc.id_protocol_criteria
                      FROM protocol_criteria pc
                     WHERE pc.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_criteria_link pcl
             WHERE pcl.id_protocol_criteria IN
                   (SELECT pc.id_protocol_criteria
                      FROM protocol_criteria pc
                     WHERE pc.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_criteria pc
             WHERE pc.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_task pt
             WHERE pt.id_group_task IN
                   (SELECT pe.id_element
                      FROM protocol_element pe
                     WHERE pe.id_protocol IN (SELECT p.id_protocol
                                                FROM protocol p
                                               WHERE p.id_institution = i.id_institution));
        
            DELETE FROM protocol_element pe
             WHERE pe.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol_link pl
             WHERE pl.id_protocol IN (SELECT p.id_protocol
                                        FROM protocol p
                                       WHERE p.id_institution = i.id_institution);
        
            DELETE FROM protocol p
             WHERE p.id_institution = i.id_institution;
            -- Order SEt
            g_error := 'DELETE ORDER SET';
            DELETE FROM order_set_task_detail ostd
             WHERE ostd.id_order_set_task IN
                   (SELECT ost.id_order_set_task
                      FROM order_set_task ost
                     INNER JOIN order_set os
                        ON (os.id_order_set = ost.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE order_set_task_link ostl
             WHERE ostl.id_order_set_task IN
                   (SELECT ost.id_order_set_task
                      FROM order_set_task ost
                     INNER JOIN order_set os
                        ON (os.id_order_set = ost.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_task_dependency ostd
             WHERE ostd.id_order_set IN (SELECT os.id_order_set
                                           FROM order_set os
                                          WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_task ost
             WHERE ost.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_frequent osf
             WHERE osf.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE order_set_link osl
             WHERE osl.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            DELETE FROM order_set_process_task_link osptl
             WHERE osptl.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     INNER JOIN order_set_process osp
                        ON (osp.id_order_set_process = ospt.id_order_set_process)
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task_det osptd
             WHERE osptd.id_order_set_process_task IN
                   (SELECT ospt.id_order_set_process_task
                      FROM order_set_process_task ospt
                     INNER JOIN order_set_process osp
                        ON (osp.id_order_set_process = ospt.id_order_set_process)
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task_depend osptd
             WHERE osptd.id_order_set_process IN
                   (SELECT osp.id_order_set_process
                      FROM order_set_process osp
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process_task ospt
             WHERE ospt.id_order_set_process IN
                   (SELECT osp.id_order_set_process
                      FROM order_set_process osp
                     INNER JOIN order_set os
                        ON (os.id_order_set = osp.id_order_set AND os.id_institution = i.id_institution));
        
            DELETE FROM order_set_process osp
             WHERE osp.id_order_set IN (SELECT os.id_order_set
                                          FROM order_set os
                                         WHERE os.id_institution = i.id_institution);
        
            g_error := 'DELETE HEALTH_PROGRAM_SI';
            DELETE FROM health_program_soft_inst hpsi
             WHERE hpsi.id_institution = i.id_institution;
        
            g_error := 'DELETE INTERV_DRUG';
            DELETE FROM interv_drug id
             WHERE id.id_institution = i.id_institution;
        
            g_error := 'DELETE DEF MAPPING INSTITUTION';
            DELETE FROM alert_default.map_content d
             WHERE d.id_alert = i.id_institution
               AND d.table_name = 'INSTITUTION';
        
            g_error := 'DELETE INSTITUTION';
            DELETE FROM institution d
             WHERE d.id_institution = i.id_institution;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DEF_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            ROLLBACK;
            pk_api_backoffice_default.process_error('PK_API_BACKOFFICE_DEFAULT.DELETE_ALL_DEF_STRUCTURE', g_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_ALL_DEF_STRUCTURE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            ROLLBACK;
            pk_api_backoffice_default.process_error('PK_API_BACKOFFICE_DEFAULT.DELETE_ALL_DEF_STRUCTURE', g_error);
    END;
    /******************************************************
    * Update Queue of Lucene Indexes used by Translations *
    *                                                     *
    ******************************************************/
    PROCEDURE luceneindex_sync IS
    
    BEGIN
        FOR i IN 1 .. 17
        LOOP
            lucenedomainindex.sync('DESC_LANG_' || i || '_LIDX');
            COMMIT;
        END LOOP;
    END;
    /********************************************************************************************
    * Set Questionnaire/Response Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/12/15
    ********************************************************************************************/
    FUNCTION set_iso_question_response
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_id_questionnaire OUT pk_types.cursor_type,
        o_id_response      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->Pesq
        l_c_quest_response     pk_types.cursor_type;
        l_c_exam_questionnaire pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        IF i_content_universe = 'Y'
        THEN
            --> Universos
            g_error := 'SET DEFAULT QUESTIONNAIRE';
            IF NOT pk_default_content.set_def_questionnaire(i_lang, o_id_questionnaire, o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT RESPONSE';
            IF NOT pk_default_content.set_def_response(i_lang, o_id_response, o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR i IN 1 .. i_version.count
        LOOP
        
            FOR j IN 1 .. i_market.count
            LOOP
                --> Pesquisáveis
                IF i_pesquisaveis = 'Y'
                THEN
                    g_error := 'SET INST QUESTIONNAIRE_RESPONSE';
                    IF NOT pk_backoffice_default.set_inst_quest_response(i_lang,
                                                                         table_number(i_market(j)),
                                                                         table_varchar(i_version(i)),
                                                                         l_c_quest_response,
                                                                         l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INST EXAM_QUESTIONNAIRE';
                    IF NOT pk_backoffice_default.set_inst_exam_questionnaire(i_lang,
                                                                             table_number(i_market(j)),
                                                                             table_varchar(i_version(i)),
                                                                             l_c_exam_questionnaire,
                                                                             l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END LOOP;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_QUESTION_RESPONSE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_QUESTION_RESPONSE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_question_response;
    /********************************************************************************************
    * SET_ISO_ICNP
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.5.1.1 HF
    * @since                       2010/12/21
    ********************************************************************************************/
    FUNCTION set_iso_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -->OUTPUT
        o_icnp_compo      pk_types.cursor_type;
        o_inst_icnp_compo pk_types.cursor_type;
        o_icnp_axis       pk_types.cursor_type;
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_result NUMBER;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
        l_c_inst_icnp_axis_cs  pk_types.cursor_type;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    
    BEGIN
        /*IF i_content_universe = 'Y'
        THEN
        
        END IF;*/
        --> Pesquisáveis
        IF i_pesquisaveis = 'Y'
        THEN
        
            IF NOT pk_backoffice_default.set_inst_icnp_composition(i_lang,
                                                                   i_market,
                                                                   i_version,
                                                                   i_id_institution,
                                                                   i_software,
                                                                   l_result,
                                                                   o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT pk_backoffice_default.set_inst_icnp_composition_hist(i_lang,
                                                                        i_market,
                                                                        i_version,
                                                                        i_id_institution,
                                                                        i_software,
                                                                        l_result,
                                                                        o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            IF NOT pk_backoffice_default.set_inst_icnp_composition_term(i_lang,
                                                                        i_market,
                                                                        i_version,
                                                                        i_id_institution,
                                                                        i_software,
                                                                        l_result,
                                                                        o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET INSTITUTION ICNP_PREDIFINED_ACTION';
            IF NOT pk_backoffice_default.set_inst_icnp_compo(i_lang            => i_lang,
                                                             i_market          => i_market,
                                                             i_version         => i_version,
                                                             i_id_institution  => i_id_institution,
                                                             i_software        => i_software,
                                                             o_inst_icnp_compo => o_inst_icnp_compo,
                                                             o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ICNP TASK COMPOSITION';
            IF NOT pk_icnp_prm.load_icnp_task_comp_def(i_lang,
                                                       i_id_institution,
                                                       i_market,
                                                       i_version,
                                                       i_software,
                                                       l_result,
                                                       o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT ICNP TASK COMPOSITION BY SOFTWARE AND INSTITUTION';
            IF NOT pk_backoffice_default.set_inst_task_comp_search(i_lang,
                                                                   i_market,
                                                                   i_version,
                                                                   i_id_institution,
                                                                   i_software,
                                                                   l_result,
                                                                   o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        --> MyPreferences by 1 Clinical Service
        IF i_mypreferences_by1 = 'Y'
           AND i_id_dep_clin_serv IS NOT NULL
           AND i_mypreferences_all = 'N'
        THEN
            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
            SELECT nvl((SELECT acs.id_clinical_service
                         FROM dep_clin_serv dcs
                         JOIN department d
                           ON d.id_department = dcs.id_department
                          AND d.id_institution = i_id_institution
                         JOIN clinical_service cs
                           ON cs.id_clinical_service = dcs.id_clinical_service
                         JOIN alert_default.clinical_service acs
                           ON acs.id_content = cs.id_content
                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                          AND rownum = 1),
                       0)
              INTO l_id_clinical_service
              FROM dual;
        
            IF l_id_clinical_service != 0
            THEN
                FOR k IN 1 .. i_software.count
                LOOP
                    g_error := 'SET INSTITUTION ICNP AXIS DCS';
                    IF NOT pk_default_inst_preferences.set_inst_icnp_axis_cs(i_lang,
                                                                             i_id_institution,
                                                                             i_software(k),
                                                                             i_id_dep_clin_serv,
                                                                             l_c_inst_icnp_axis_cs,
                                                                             o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END LOOP;
            END IF;
        
            --> MyPreferences by all Clinical Services
        ELSIF i_mypreferences_by1 = 'N'
              AND i_id_dep_clin_serv IS NULL
              AND i_mypreferences_all = 'Y'
        THEN
            FOR k IN 1 .. i_software.count
            LOOP
            
                OPEN c_dep_clin(i_id_institution, i_software(k));
                LOOP
                    FETCH c_dep_clin
                        INTO i_id_dep_clin_serv_all;
                    EXIT WHEN c_dep_clin%NOTFOUND;
                
                    g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                    SELECT nvl((SELECT acs.id_clinical_service
                                 FROM dep_clin_serv dcs
                                 JOIN department d
                                   ON d.id_department = dcs.id_department
                                  AND d.id_institution = i_id_institution
                                 JOIN clinical_service cs
                                   ON cs.id_clinical_service = dcs.id_clinical_service
                                 JOIN alert_default.clinical_service acs
                                   ON acs.id_content = cs.id_content
                                WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                  AND rownum = 1),
                               0)
                      INTO l_id_clinical_service
                      FROM dual;
                
                    IF l_id_clinical_service != 0
                    THEN
                        g_error := 'SET INSTITUTION ICNP AXIS DCS';
                        IF NOT pk_default_inst_preferences.set_inst_icnp_axis_cs(i_lang,
                                                                                 i_id_institution,
                                                                                 i_software(k),
                                                                                 i_id_dep_clin_serv_all,
                                                                                 l_c_inst_icnp_axis_cs,
                                                                                 o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END IF;
                
                END LOOP;
                g_error := 'CLOSE C_DEP_CLIN CURSOR';
                CLOSE c_dep_clin;
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              'ALERT',
                                              'PK_API_BACKOFFICE_DEFAULT',
                                              'SET_ISO_ICNP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_BACKOFFICE_DEFAULT',
                                              'SET_ISO_ICNP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_icnp;
    /********************************************************************************************
    * Synch Lb_translation with translation info
    *
    * @param i_lang                Prefered language ID
    * @param i_code_translation    Code to process by default 'ALL' will be processed
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.1
    * @since                       2011/05/25
    ********************************************************************************************/
    FUNCTION synch_ncd_translation
    (
        i_lang             IN language.id_language%TYPE,
        i_code_translation IN translation.code_translation%TYPE DEFAULT 'ALL',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_user  VARCHAR2(300 CHAR) := 'ALERT_DEFAULT';
        i       PLS_INTEGER;
        g_error VARCHAR2(4000);
        TYPE tv IS TABLE OF VARCHAR2(200);
        now TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        -- code definition tv must be like <TABLE_NAME>.<COLUMN_NAME>.' 
        codes tv := tv('DEPARTMENT.CODE_DEPARTMENT.',
                       'ORIGIN.CODE_ORIGIN.',
                       'HEALTH_PLAN.CODE_HEALTH_PLAN.',
                       'APPOINTMENT.CODE_APPOINTMENT.',
                       'BED.CODE_BED.',
                       'BED_TYPE.CODE_BED_TYPE.',
                       'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.',
                       'COUNTRY.CODE_COUNTRY.',
                       'COUNTRY.CODE_NATIONALITY.',
                       'DEPT.CODE_DEPT.',
                       'DIAGNOSIS.CODE_DIAGNOSIS.',
                       'EXAM.CODE_EXAM.',
                       'EXAM_ALIAS.CODE_EXAM_ALIAS.',
                       'EXAM_CAT.CODE_EXAM_CAT.',
                       'AB_INSTITUTION.CODE_INSTITUTION.',
                       'ROOM.CODE_ROOM.',
                       'ROOM_TYPE.CODE_ROOM_TYPE.',
                       'SCH_CANCEL_REASON.CODE_CANCEL_REASON.',
                       'SCH_EVENT.CODE_SCH_EVENT.',
                       'SCH_DEP_TYPE.CODE_DEP_TYPE.',
                       'HEALTH_PLAN_ENTITY.CODE_HEALTH_PLAN_ENTITY.',
                       'REHAB_SESSION_TYPE.CODE_REHAB_SESSION_TYPE.',
                       'SCH_RESCHED_REASON.CODE_RESCHED_REASON.',
                       'SCH_EVENT_ALIAS.CODE_SCH_EVENT_ALIAS');
    BEGIN
        g_func_name := upper('');
        -- get current user to log
        l_user := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), USER);
        -- check if specific code will be loaded or all Alert translation are synch
        IF (i_code_translation = 'ALL' OR i_code_translation IS NULL)
        THEN
            FOR i IN codes.first .. codes.last
            LOOP
                g_error := 'importing ' || codes(i) || ' translations... ';
            
                BEGIN
                    MERGE INTO alert_basecomp.lb_translation g
                    USING (SELECT t.code_translation,
                                  t.desc_lang_1,
                                  t.desc_lang_2,
                                  t.desc_lang_3,
                                  t.desc_lang_4,
                                  t.desc_lang_5,
                                  t.desc_lang_6,
                                  t.desc_lang_7,
                                  t.desc_lang_8,
                                  t.desc_lang_9,
                                  t.desc_lang_10,
                                  t.desc_lang_11,
                                  t.desc_lang_12,
                                  t.desc_lang_13,
                                  t.desc_lang_14,
                                  t.desc_lang_15,
                                  t.desc_lang_16,
                                  t.desc_lang_17,
                                  t.desc_lang_18,
                                  t.desc_lang_19,
                                  t.desc_lang_20,
                                  t.desc_lang_21,
                                  t.desc_lang_22
                             FROM translation t
                            WHERE t.code_translation LIKE codes(i) || '%') d
                    ON (g.code = d.code_translation)
                    WHEN NOT MATCHED THEN
                        INSERT
                            (id_lb_translation,
                             code,
                             software_key,
                             module_code,
                             img_name,
                             import_code,
                             record_status,
                             create_time,
                             create_user,
                             create_institution,
                             update_time,
                             update_user,
                             update_institution,
                             desc_lang_1,
                             desc_lang_2,
                             desc_lang_3,
                             desc_lang_4,
                             desc_lang_5,
                             desc_lang_6,
                             desc_lang_7,
                             desc_lang_8,
                             desc_lang_9,
                             desc_lang_10,
                             desc_lang_11,
                             desc_lang_12,
                             desc_lang_13,
                             desc_lang_14,
                             desc_lang_15,
                             desc_lang_16,
                             desc_lang_17,
                             desc_lang_18,
                             desc_lang_19,
                             desc_lang_20,
                             desc_lang_21,
                             desc_lang_22)
                        VALUES
                            (alert_basecomp.seq_lb_translation.nextval,
                             d.code_translation,
                             NULL, -- software_key
                             'SCH-CORE', --module_code
                             NULL, -- img_name
                             NULL, -- import_code
                             'A', -- record_status
                             now, -- create_time
                             l_user, -- create_user
                             NULL, --create_institution
                             NULL, -- update
                             NULL, -- update
                             NULL, -- update
                             d.desc_lang_1,
                             d.desc_lang_2,
                             d.desc_lang_3,
                             d.desc_lang_4,
                             d.desc_lang_5,
                             d.desc_lang_6,
                             d.desc_lang_7,
                             d.desc_lang_8,
                             d.desc_lang_9,
                             d.desc_lang_10,
                             d.desc_lang_11,
                             d.desc_lang_12,
                             d.desc_lang_13,
                             d.desc_lang_14,
                             d.desc_lang_15,
                             d.desc_lang_16,
                             d.desc_lang_17,
                             d.desc_lang_18,
                             d.desc_lang_19,
                             d.desc_lang_20,
                             d.desc_lang_21,
                             d.desc_lang_22)
                    WHEN MATCHED THEN
                        UPDATE
                           SET desc_lang_1        = d.desc_lang_1,
                               desc_lang_2        = d.desc_lang_2,
                               desc_lang_3        = d.desc_lang_3,
                               desc_lang_4        = d.desc_lang_4,
                               desc_lang_5        = d.desc_lang_5,
                               desc_lang_6        = d.desc_lang_6,
                               desc_lang_7        = d.desc_lang_7,
                               desc_lang_8        = d.desc_lang_8,
                               desc_lang_9        = d.desc_lang_9,
                               desc_lang_10       = d.desc_lang_10,
                               desc_lang_11       = d.desc_lang_11,
                               desc_lang_12       = d.desc_lang_12,
                               desc_lang_13       = d.desc_lang_13,
                               desc_lang_14       = d.desc_lang_14,
                               desc_lang_15       = d.desc_lang_15,
                               desc_lang_16       = d.desc_lang_16,
                               desc_lang_17       = d.desc_lang_17,
                               desc_lang_18       = d.desc_lang_18,
                               desc_lang_19       = d.desc_lang_19,
                               desc_lang_20       = d.desc_lang_20,
                               desc_lang_21       = d.desc_lang_21,
                               desc_lang_22       = d.desc_lang_22,
                               import_code        = NULL,
                               update_user        = l_user,
                               update_time        = now,
                               update_institution = NULL;
                
                END;
            END LOOP;
        ELSE
            -- particular case
            BEGIN
                MERGE INTO alert_basecomp.lb_translation g
                USING (SELECT t.code_translation,
                              t.desc_lang_1,
                              t.desc_lang_2,
                              t.desc_lang_3,
                              t.desc_lang_4,
                              t.desc_lang_5,
                              t.desc_lang_6,
                              t.desc_lang_7,
                              t.desc_lang_8,
                              t.desc_lang_9,
                              t.desc_lang_10,
                              t.desc_lang_11,
                              t.desc_lang_12,
                              t.desc_lang_13,
                              t.desc_lang_14,
                              t.desc_lang_15,
                              t.desc_lang_16,
                              t.desc_lang_17,
                              t.desc_lang_18,
                              t.desc_lang_19,
                              t.desc_lang_20,
                              t.desc_lang_21,
                              t.desc_lang_22
                         FROM translation t
                        WHERE t.code_translation LIKE i_code_translation || '%') d
                ON (g.code = d.code_translation)
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_lb_translation,
                         code,
                         software_key,
                         module_code,
                         img_name,
                         import_code,
                         record_status,
                         create_time,
                         create_user,
                         create_institution,
                         update_time,
                         update_user,
                         update_institution,
                         desc_lang_1,
                         desc_lang_2,
                         desc_lang_3,
                         desc_lang_4,
                         desc_lang_5,
                         desc_lang_6,
                         desc_lang_7,
                         desc_lang_8,
                         desc_lang_9,
                         desc_lang_10,
                         desc_lang_11,
                         desc_lang_12,
                         desc_lang_13,
                         desc_lang_14,
                         desc_lang_15,
                         desc_lang_16,
                         desc_lang_17,
                         desc_lang_18,
                         desc_lang_19,
                         desc_lang_20,
                         desc_lang_21,
                         desc_lang_22)
                    VALUES
                        (alert_basecomp.seq_lb_translation.nextval,
                         d.code_translation,
                         NULL, -- software_key
                         'SCH-CORE', --module_code
                         NULL, -- img_name
                         NULL, -- import_code
                         'A', -- record_status
                         now, -- create_time
                         l_user, -- create_user
                         NULL, --create_institution
                         NULL, -- update
                         NULL, -- update
                         NULL, -- update
                         d.desc_lang_1,
                         d.desc_lang_2,
                         d.desc_lang_3,
                         d.desc_lang_4,
                         d.desc_lang_5,
                         d.desc_lang_6,
                         d.desc_lang_7,
                         d.desc_lang_8,
                         d.desc_lang_9,
                         d.desc_lang_10,
                         d.desc_lang_11,
                         d.desc_lang_12,
                         d.desc_lang_13,
                         d.desc_lang_14,
                         d.desc_lang_15,
                         d.desc_lang_16,
                         d.desc_lang_17,
                         d.desc_lang_18,
                         d.desc_lang_19,
                         d.desc_lang_20,
                         d.desc_lang_21,
                         d.desc_lang_22)
                WHEN MATCHED THEN
                    UPDATE
                       SET desc_lang_1        = d.desc_lang_1,
                           desc_lang_2        = d.desc_lang_2,
                           desc_lang_3        = d.desc_lang_3,
                           desc_lang_4        = d.desc_lang_4,
                           desc_lang_5        = d.desc_lang_5,
                           desc_lang_6        = d.desc_lang_6,
                           desc_lang_7        = d.desc_lang_7,
                           desc_lang_8        = d.desc_lang_8,
                           desc_lang_9        = d.desc_lang_9,
                           desc_lang_10       = d.desc_lang_10,
                           desc_lang_11       = d.desc_lang_11,
                           desc_lang_12       = d.desc_lang_12,
                           desc_lang_13       = d.desc_lang_13,
                           desc_lang_14       = d.desc_lang_14,
                           desc_lang_15       = d.desc_lang_15,
                           desc_lang_16       = d.desc_lang_16,
                           desc_lang_17       = d.desc_lang_17,
                           desc_lang_18       = d.desc_lang_18,
                           desc_lang_19       = d.desc_lang_19,
                           desc_lang_20       = d.desc_lang_20,
                           desc_lang_21       = d.desc_lang_21,
                           desc_lang_22       = d.desc_lang_22,
                           import_code        = NULL,
                           update_user        = l_user,
                           update_time        = now,
                           update_institution = NULL;
            
            END;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              l_user,
                                              g_package_name,
                                              'SYNCH_NCD_TRANSLATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END synch_ncd_translation;
    /********************************************************************************************
    * Set isolated Content and Parametrization
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_supply              cursor with supply inserted
    * @param o_error               cursor with supply configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_iso_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_supply           OUT pk_types.cursor_type,
        o_inst_supply      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        -->Universos
        l_c_supply_type pk_types.cursor_type;
        -->Pesq
        l_c_supply_area     pk_types.cursor_type;
        l_c_supply_location pk_types.cursor_type;
        l_c_supply_context  pk_types.cursor_type;
        l_c_supply_reason   pk_types.cursor_type;
        l_c_supply_relation pk_types.cursor_type;
        -->Freqs
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('');
        ------------------------------------------
        --  Universos
        ------------------------------------------
        IF i_content_universe = 'Y'
        THEN
        
            g_error := 'SET DEFAULT SUPPLY_TYPE';
            IF NOT pk_default_content.set_supply_type(i_lang, l_c_supply_type, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET DEFAULT SUPPLY';
            IF NOT pk_default_content.set_supply(i_lang, o_supply, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        ------------------------------------------
        --  Pesquisáveis
        ------------------------------------------
        IF i_pesquisaveis = 'Y'
        THEN
            FOR mkt IN 1 .. i_market.count
            LOOP
                FOR vrs IN 1 .. i_version.count
                LOOP
                    g_error := 'SET INSTITUTION SUPPLY';
                    IF NOT pk_backoffice_default.set_supply_soft_inst(i_lang,
                                                                      i_market(mkt),
                                                                      i_version(vrs),
                                                                      i_id_institution,
                                                                      i_software,
                                                                      o_inst_supply,
                                                                      l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION SUPPLY RELATION';
                    IF NOT pk_backoffice_default.set_supply_relation(i_lang,
                                                                     i_market(mkt),
                                                                     i_version(vrs),
                                                                     l_c_supply_relation,
                                                                     l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION SUPPLY AREA';
                    IF NOT pk_backoffice_default.set_supply_sup_area(i_lang,
                                                                     i_market(mkt),
                                                                     i_version(vrs),
                                                                     i_id_institution,
                                                                     i_software,
                                                                     l_c_supply_area,
                                                                     l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION SUPPLY_LOCATION';
                    IF NOT pk_backoffice_default.set_supply_loc_default(i_lang,
                                                                        i_market(mkt),
                                                                        i_version(vrs),
                                                                        i_id_institution,
                                                                        i_software,
                                                                        l_c_supply_location,
                                                                        l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION SUPPLY_CONTEXT';
                    IF NOT pk_backoffice_default.set_supply_context(i_lang,
                                                                    i_market(mkt),
                                                                    i_version(vrs),
                                                                    i_id_institution,
                                                                    i_software,
                                                                    l_c_supply_context,
                                                                    l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'SET INSTITUTION SUPPLY_REASON';
                    IF NOT pk_backoffice_default.set_supply_reason(i_lang,
                                                                   i_market(mkt),
                                                                   i_version(vrs),
                                                                   l_c_supply_reason,
                                                                   l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                END LOOP;
            END LOOP;
        END IF; -- Pesquisaveis
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_SUPPLY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_SUPPLY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_supply;
    /********************************************************************************************
    * Set isolated Content and Configurations
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_resnt               cursor with result notes inserted
    * @param o_inst_resnt          cursor with result notes instit configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.8
    * @since                           18-APR-2012
    ********************************************************************************************/
    FUNCTION set_iso_result_notes
    (
        i_lang             IN language.id_language%TYPE,
        i_content_universe IN VARCHAR2 DEFAULT 'N',
        i_market           IN table_number,
        i_version          IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE,
        i_software         IN table_number,
        i_pesquisaveis     IN VARCHAR2 DEFAULT 'N',
        o_resnt            OUT pk_types.cursor_type,
        o_inst_resnt       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --> error handling
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_func_name := upper('set_iso_result_notes');
        ------------------------------------------
        --  Universos
        ------------------------------------------
        IF i_content_universe = 'Y'
        THEN
        
            g_error := 'SET RESULT NOTES CONTENT';
            IF NOT pk_default_content.set_def_result_notes(i_lang, o_resnt, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        ------------------------------------------
        --  Pesquisáveis
        ------------------------------------------
        IF i_pesquisaveis = 'Y'
        THEN
        
            g_error := 'SET INSTITUTION|SOFTWARE CONFIGURATIONS';
            IF NOT pk_backoffice_default.set_inst_result_notes(i_lang,
                                                               i_market,
                                                               i_version,
                                                               i_id_institution,
                                                               i_software,
                                                               o_inst_resnt,
                                                               l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF; -- Pesquisaveis
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_result_notes;
    /********************************************************************************************
    * SET_ISO_PERIODIC_OBSERVATIONS
    *
    * @param i_lang                Prefered language ID
    * @param i_content_universe    Load Content Y/N
    * @param i_market              market to configure
    * @param i_version             Version of Content to configure
    * @param i_id_institution      Institution to configure
    * @param i_software            Software list to configure
    * @param i_pesquisaveis        Institution Parametrization Y/N
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8.X HF
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION set_iso_periodic_obs
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_content table_varchar := table_varchar();
    
        -->OUTPUT
        -- events
        l_c_universe_cursor_ev pk_types.cursor_type;
        l_c_universe_cursor_lt pk_types.cursor_type;
        l_c_universe_cursor_ex pk_types.cursor_type;
        l_c_universe_cursor_hb pk_types.cursor_type;
        -- event group
        l_c_inst_cursor_egsi pk_types.cursor_type;
        -- periodic obs param
        l_c_universe_cursor_pop pk_types.cursor_type;
        l_c_inst_cursor_pop     pk_types.cursor_type;
        l_c_pref_cursor_pop     pk_types.cursor_type;
        -- periodic obs desc
        l_c_inst_cursor_pod pk_types.cursor_type;
        l_c_inst_pod        pk_types.cursor_type;
        --
        l_error_out t_error_out;
        l_exception EXCEPTION;
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
        l_results              NUMBER := 0;
        l_def_cs_list          table_number := table_number();
        l_cs_out_id            clinical_service.id_clinical_service%TYPE;
        CURSOR c_dep_clin IS
            SELECT DISTINCT dcs.id_dep_clin_serv, dcs.id_clinical_service
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = i_id_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) p);
    BEGIN
        g_func_name := upper('set_iso_periodic_obs');
        --> Universos
        IF i_content_universe = 'Y'
        THEN
            g_error := 'SET DEFAULT UNIVERSES PO PARAM';
            IF NOT pk_periodicobservation_prm.set_def_poparam(i_lang, l_results, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET DEFAULT UNIVERSES PO PARAM MULTICHOICES';
            IF NOT pk_periodicobservation_prm.set_def_poparam_mc(i_lang, l_results, l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            --> load new apis translations (not internal <> process)
        
        END IF;
        --> Pesquisáveis
        IF i_pesquisaveis = 'Y'
        THEN
            g_error := 'SET SEARCHEABLE PO PARAM HEALTH PROGRAMS';
            IF NOT pk_periodicobservation_prm.set_pop_hpg_search(i_lang,
                                                                 i_id_institution,
                                                                 i_market,
                                                                 i_version,
                                                                 i_software,
                                                                 l_results,
                                                                 l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET SEARCHEABLE PO PARAM UNIT MEASURES';
            IF NOT pk_periodicobservation_prm.set_pop_um_search(i_lang,
                                                                i_id_institution,
                                                                i_market,
                                                                i_version,
                                                                i_software,
                                                                l_results,
                                                                l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET SEARCHEABLE PO PARAM RANKS';
            IF NOT pk_periodicobservation_prm.set_pop_rk_search(i_lang,
                                                                i_id_institution,
                                                                i_market,
                                                                i_version,
                                                                i_software,
                                                                l_results,
                                                                l_error_out)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET SEARCHEABLE PO PARAM WH';
            IF NOT pk_periodicobservation_prm.set_poparamwh_search(i_lang,
                                                                   i_id_institution,
                                                                   i_market,
                                                                   i_version,
                                                                   i_software,
                                                                   l_id_content,
                                                                   l_results,
                                                                   l_error_out)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
        --> MyPreferences by 1 Clinical Service
    
        IF i_mypreferences_by1 = 'Y'
           AND i_id_dep_clin_serv IS NOT NULL
           AND i_mypreferences_all = 'N'
        THEN
        
            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
            SELECT nvl((SELECT acs.id_clinical_service
                         FROM dep_clin_serv dcs
                         JOIN department d
                           ON d.id_department = dcs.id_department
                          AND d.id_institution = i_id_institution
                         JOIN clinical_service cs
                           ON cs.id_clinical_service = dcs.id_clinical_service
                         JOIN alert_default.clinical_service acs
                           ON acs.id_content = cs.id_content
                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                          AND rownum = 1),
                       0)
              INTO l_id_clinical_service
              FROM dual;
        
            IF l_id_clinical_service != 0
            THEN
                g_error := 'GET DCS CLINICAL_SERVICE ID ' || i_id_dep_clin_serv;
                SELECT dcs.id_clinical_service
                  INTO l_cs_out_id
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
                g_error := 'GET DEFAULT CLINICAL_SERVICE LIST OF IDS ' || l_cs_out_id;
                IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                          l_id_clinical_service,
                                                                          l_def_cs_list,
                                                                          l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
                g_error := 'SET PREFERENCES FOR ' || l_id_clinical_service;
                IF NOT pk_periodicobservation_prm.set_po_param_cs_freq(i_lang,
                                                                       i_id_institution,
                                                                       i_market,
                                                                       i_version,
                                                                       i_software,
                                                                       l_id_content,
                                                                       l_def_cs_list,
                                                                       l_cs_out_id,
                                                                       i_id_dep_clin_serv,
                                                                       l_results,
                                                                       l_error_out)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
            --> MyPreferences by all Clinical Services
        ELSIF i_mypreferences_by1 = 'N'
              AND i_id_dep_clin_serv IS NULL
              AND i_mypreferences_all = 'Y'
        THEN
        
            OPEN c_dep_clin;
            LOOP
                FETCH c_dep_clin
                    INTO i_id_dep_clin_serv_all, l_cs_out_id;
                EXIT WHEN c_dep_clin%NOTFOUND;
            
                g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                SELECT nvl((SELECT acs.id_clinical_service
                             FROM dep_clin_serv dcs
                             JOIN department d
                               ON d.id_department = dcs.id_department
                              AND d.id_institution = i_id_institution
                             JOIN clinical_service cs
                               ON cs.id_clinical_service = dcs.id_clinical_service
                             JOIN alert_default.clinical_service acs
                               ON acs.id_content = cs.id_content
                            WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                              AND rownum = 1),
                           0)
                  INTO l_id_clinical_service
                  FROM dual;
            
                IF l_id_clinical_service != 0
                THEN
                    g_error := 'GET DEFAULT CLINICAL_SERVICE LIST OF IDS ' || l_cs_out_id;
                    IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                              l_id_clinical_service,
                                                                              l_def_cs_list,
                                                                              l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                    g_error := 'SET PREFERENCES FOR ' || l_id_clinical_service;
                    IF NOT pk_periodicobservation_prm.set_po_param_cs_freq(i_lang,
                                                                           i_id_institution,
                                                                           i_market,
                                                                           i_version,
                                                                           i_software,
                                                                           l_id_content,
                                                                           l_def_cs_list,
                                                                           l_cs_out_id,
                                                                           i_id_dep_clin_serv_all,
                                                                           l_results,
                                                                           l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            END LOOP;
            g_error := 'CLOSE C_DEP_CLIN CURSOR';
            CLOSE c_dep_clin;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || l_error_out.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_iso_periodic_obs;
    /********************************************************************************************
    * Set EXAMS Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/06/25
    ********************************************************************************************/
    FUNCTION set_iso_social_worker_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_pesquisaveis      IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_by1 IN VARCHAR2 DEFAULT 'N',
        i_id_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_id_clinical_service  clinical_service.id_clinical_service%TYPE;
        i_id_dep_clin_serv_all dep_clin_serv.id_dep_clin_serv%TYPE;
    
        l_result NUMBER := 0;
    
        CURSOR c_dep_clin
        (
            c_institution institution.id_institution%TYPE,
            c_id_software software.id_software%TYPE
        ) IS
            SELECT DISTINCT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, department d, dept dp, software_dept sd, clinical_service cs
             WHERE dcs.id_department = d.id_department
               AND dcs.id_clinical_service = cs.id_clinical_service
               AND d.id_dept = dp.id_dept
               AND dp.id_dept = sd.id_dept
               AND dcs.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND dp.flg_available = g_flg_available
               AND cs.flg_available = g_flg_available
               AND d.id_institution = c_institution
               AND d.id_institution = dp.id_institution
               AND sd.id_software = c_id_software;
    BEGIN
        g_func_name := upper('set_iso_social_worker_interv');
        IF i_content_universe = 'Y'
        THEN
            IF NOT pk_default_content.set_intervplan_def(i_lang, l_result, o_error)
            THEN
                RAISE l_exception;
            END IF;
            IF NOT pk_default_content.set_taksgoal_def(i_lang, l_result, o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --> Pesquisáveis
        IF i_pesquisaveis = 'Y'
        THEN
            IF NOT pk_backoffice_default.set_taskgoaltask_search(i_lang,
                                                                 i_id_institution,
                                                                 i_market,
                                                                 i_version,
                                                                 i_software,
                                                                 l_result,
                                                                 o_error)
            THEN
                RAISE l_exception;
            END IF;
            IF NOT pk_backoffice_default.set_intervplan_search(i_lang,
                                                               i_id_institution,
                                                               i_market,
                                                               i_version,
                                                               i_software,
                                                               l_result,
                                                               o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        --> MyPreferences by 1 Clinical Service
        IF i_mypreferences_by1 = 'Y'
           AND i_id_dep_clin_serv IS NOT NULL
           AND i_mypreferences_all = 'N'
        THEN
            g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
            SELECT nvl((SELECT acs.id_clinical_service
                         FROM dep_clin_serv dcs
                         JOIN department d
                           ON d.id_department = dcs.id_department
                          AND d.id_institution = i_id_institution
                         JOIN clinical_service cs
                           ON cs.id_clinical_service = dcs.id_clinical_service
                         JOIN alert_default.clinical_service acs
                           ON acs.id_content = cs.id_content
                        WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                          AND rownum = 1),
                       0)
              INTO l_id_clinical_service
              FROM dual;
            IF l_id_clinical_service != 0
            THEN
                IF NOT pk_default_inst_preferences.set_intervplan_freq(i_lang,
                                                                       i_id_institution,
                                                                       i_market,
                                                                       i_version,
                                                                       i_software,
                                                                       table_number(l_id_clinical_service),
                                                                       NULL,
                                                                       i_id_dep_clin_serv,
                                                                       l_result,
                                                                       o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
            --> MyPreferences by all Clinical Services
        ELSIF i_mypreferences_by1 = 'N'
              AND i_id_dep_clin_serv IS NULL
              AND i_mypreferences_all = 'Y'
        THEN
            FOR k IN 1 .. i_software.count
            LOOP
                g_error := 'OPEN C_DEP_CLIN CURSOR';
                OPEN c_dep_clin(i_id_institution, i_software(k));
                LOOP
                    FETCH c_dep_clin
                        INTO i_id_dep_clin_serv_all;
                    EXIT WHEN c_dep_clin%NOTFOUND;
                
                    g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
                    SELECT nvl((SELECT acs.id_clinical_service
                                 FROM dep_clin_serv dcs
                                 JOIN department d
                                   ON d.id_department = dcs.id_department
                                  AND d.id_institution = i_id_institution
                                 JOIN clinical_service cs
                                   ON cs.id_clinical_service = dcs.id_clinical_service
                                 JOIN alert_default.clinical_service acs
                                   ON acs.id_content = cs.id_content
                                WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv_all
                                  AND rownum = 1),
                               0)
                      INTO l_id_clinical_service
                      FROM dual;
                
                    IF l_id_clinical_service != 0
                    THEN
                        IF NOT pk_default_inst_preferences.set_intervplan_freq(i_lang,
                                                                               i_id_institution,
                                                                               i_market,
                                                                               i_version,
                                                                               i_software,
                                                                               table_number(l_id_clinical_service),
                                                                               NULL,
                                                                               i_id_dep_clin_serv_all,
                                                                               l_result,
                                                                               o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END IF;
                END LOOP;
                CLOSE c_dep_clin;
            END LOOP;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_iso_social_worker_interv;
    /********************************************************************************************
    * Set Default Institutions
    *
    * @param i_lang                Prefered language ID
    * @param o_institutions        Institutions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION set_def_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_flg_type     IN institution.flg_type%TYPE,
        i_market       IN institution.id_market%TYPE,
        o_institutions OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count_trl          NUMBER := 0;
        l_index              NUMBER := 1;
        l_instits_validation NUMBER;
        x_flg_type           alert_default.institution.instit_default%TYPE := 'Y';
    
        --INSTITUTION
        l_id_institution_def institution.id_institution%TYPE;
        l_id_institution     institution.id_institution%TYPE;
        l_flg_type           institution.flg_type%TYPE;
        l_rank               institution.rank%TYPE;
        l_barcode            institution.barcode%TYPE;
        l_abbreviation       institution.abbreviation%TYPE;
        l_location           institution.location%TYPE;
        l_ine_location       institution.ine_location%TYPE;
        l_id_parent          institution.id_parent%TYPE;
        l_phone_number       institution.phone_number%TYPE;
        l_ext_code           institution.ext_code%TYPE;
        l_address            institution.address%TYPE;
        l_zip_code           institution.zip_code%TYPE;
        l_fax_number         institution.fax_number%TYPE;
        l_district           institution.district %TYPE;
        l_id_timezone_reg    institution.id_timezone_region%TYPE;
        l_id_market          institution.id_market%TYPE;
        l_flg_external       institution.flg_external%TYPE;
        l_dn_flg_status      institution.dn_flg_status%TYPE;
    
        --TRANSLATION
        dml_errors EXCEPTION;
    
        CURSOR c_institutions
        (
            c_flg_type institution.flg_type%TYPE,
            c_market   institution.id_market%TYPE
        ) IS
            SELECT i.id_institution,
                   i.flg_type,
                   i.rank,
                   i.barcode,
                   i.abbreviation,
                   i.location,
                   i.ine_location,
                   i.id_parent,
                   i.phone_number,
                   i.ext_code,
                   i.address,
                   i.zip_code,
                   i.fax_number,
                   i.district,
                   i.id_timezone_region,
                   i.id_market,
                   i.flg_external,
                   i.dn_flg_status
              FROM alert_default.institution i
             WHERE i.flg_available = g_flg_available
               AND i.instit_default = x_flg_type
               AND i.id_market = c_market
               AND i.flg_type = c_flg_type;
    
    BEGIN
        g_func_name    := upper('');
        o_institutions := table_number();
        g_table_name   := 'INSTITUTION';
    
        g_error := 'OPEN C_INSTITUTIONS CURSOR';
        OPEN c_institutions(i_flg_type, i_market);
        LOOP
            g_error := 'GET INSTITUTION INFO';
            FETCH c_institutions
                INTO l_id_institution_def,
                     l_flg_type,
                     l_rank,
                     l_barcode,
                     l_abbreviation,
                     l_location,
                     l_ine_location,
                     l_id_parent,
                     l_phone_number,
                     l_ext_code,
                     l_address,
                     l_zip_code,
                     l_fax_number,
                     l_district,
                     l_id_timezone_reg,
                     l_id_market,
                     l_flg_external,
                     l_dn_flg_status;
            EXIT WHEN c_institutions%NOTFOUND;
        
            SELECT COUNT(mi.id_alert)
              INTO l_instits_validation
              FROM alert_default.map_content mi
             WHERE mi.id_default = l_id_institution_def
               AND mi.table_name = 'INSTITUTION';
        
            IF l_instits_validation = 0
            THEN
                g_error := 'INSERT INTO INSTITUTION (' || l_id_institution || ');';
                pk_api_ab_tables.upd_ins_into_ab_institution(i_id_ab_institution          => NULL,
                                                             i_import_code                => NULL,
                                                             i_record_status              => 'A',
                                                             i_id_ab_market               => l_id_market,
                                                             i_code                       => NULL,
                                                             i_description                => NULL,
                                                             i_alt_description            => NULL,
                                                             i_shortname                  => l_abbreviation,
                                                             i_vat_registration           => NULL,
                                                             i_timezone_region_code       => NULL,
                                                             i_rb_country_key             => NULL, --id_country
                                                             i_rb_regional_classifier_key => NULL,
                                                             i_id_ab_institution_parent   => l_id_parent,
                                                             i_flg_type                   => l_flg_type,
                                                             i_address1                   => l_address,
                                                             i_address2                   => NULL,
                                                             i_address3                   => NULL,
                                                             i_zip_code                   => NULL,
                                                             i_zip_code_description       => l_zip_code,
                                                             i_fax_number                 => l_fax_number,
                                                             i_phone_number               => l_phone_number,
                                                             i_email                      => NULL,
                                                             i_logo                       => NULL,
                                                             i_web_site                   => NULL,
                                                             i_geo_location_key           => NULL /*l_district*/,
                                                             i_flg_external               => l_flg_external,
                                                             i_code_institution           => NULL,
                                                             i_flg_available              => g_flg_available,
                                                             i_rank                       => l_rank,
                                                             i_barcode                    => NULL,
                                                             i_ine_location               => l_ine_location,
                                                             i_id_timezone_region         => l_id_timezone_reg,
                                                             i_ext_code                   => l_ext_code,
                                                             i_dn_flg_status              => l_dn_flg_status,
                                                             i_adress_type                => NULL,
                                                             i_contact_det                => NULL,
                                                             o_id_ab_institution          => l_id_institution);
            
                --> Mapping
                pk_api_default.insert_into_map_content(g_table_name, l_id_institution_def, l_id_institution);
            
                o_institutions.extend;
            
                o_institutions(l_index) := l_id_institution;
            
                l_index := l_index + 1;
            
                /* ELSE
                pk_api_backoffice_default.process_error('PK_BACKOFFICE_DEFAULT', 'INSTITUTION ALREADY EXISTS');*/
            END IF;
        
        END LOOP;
    
        CLOSE c_institutions;
    
        -- 15/03/2011 - RMGM : changed way how translations are loaded
        g_error      := 'SET DEF TRANSLATIONS';
        g_table_name := 'AB_INSTITUTION';
        IF NOT pk_default_content.set_def_translations(i_lang, g_table_name, l_count_trl, o_error)
        THEN
            RAISE dml_errors;
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
                                              'SET_DEF_INSTITUTION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_def_institution;

    /********************************************************************************************
    * Set Default Institutions_Group
    *
    * @param i_lang                Prefered language ID
    * @param o_institutions_grp    Institutions Group
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/09
    ********************************************************************************************/
    FUNCTION set_def_institution_group
    (
        i_lang             IN language.id_language%TYPE,
        o_institutions_grp OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index  NUMBER := 1;
        l_count1 NUMBER := 0;
    
        --INSTITUTION_GROUP
        l_id_institution_def institution_group.id_institution%TYPE;
        l_id_institution     institution_group.id_institution%TYPE;
        l_flg_relation       institution_group.flg_relation%TYPE;
        l_id_group           institution_group.id_group%TYPE;
    
        CURSOR c_institutions_group IS
            SELECT t.id_group, t.id_institution, t.flg_relation
              FROM alert_default.institution_group t
             ORDER BY 1;
    
    BEGIN
        g_func_name        := upper('');
        o_institutions_grp := table_number();
    
        g_error := 'OPEN C_INSTITUTIONS_GROUP CURSOR';
        OPEN c_institutions_group;
        LOOP
            g_error := 'GET INSTITUTION_GROUP INFO';
            FETCH c_institutions_group
                INTO l_id_group, l_id_institution_def, l_flg_relation;
            EXIT WHEN c_institutions_group%NOTFOUND;
        
            g_error := 'GET INSTITUTION ID';
            SELECT nvl((SELECT t.id_alert
                         FROM alert_default.map_content t
                        WHERE t.id_default = l_id_institution_def
                          AND t.table_name = 'INSTITUTION'
                          AND rownum = 1),
                       0)
              INTO l_id_institution
              FROM dual;
        
            IF l_id_institution != 0
            THEN
                g_error := 'GET ID_GROUP';
            
                SELECT COUNT(*)
                  INTO l_count1
                  FROM institution_group ig
                 WHERE ig.id_institution = l_id_institution
                   AND ig.flg_relation = l_flg_relation;
            
                IF l_count1 = 0
                THEN
                
                    g_error := 'INSERT INTO INSTITUTION_GROUP (' || l_id_institution || ', ' || l_flg_relation || ', ' ||
                               l_id_group || ');';
                
                    INSERT INTO institution_group
                        (id_institution, flg_relation, id_group)
                    VALUES
                        (l_id_institution, l_flg_relation, l_id_group);
                
                    o_institutions_grp.extend;
                
                    o_institutions_grp(l_index) := l_id_group;
                
                    l_index := l_index + 1;
                
                END IF;
            END IF;
        END LOOP;
    
        CLOSE c_institutions_group;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DEF_INSTITUTION_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_def_institution_group;
    -- collect all configured and valid dep_clin_serv, clinical_service and software list to proccess
    -- pk_api_backoffice_default?
    FUNCTION get_valid_dcs_all
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT dcs_list.id_dep_clin_serv, dcs_list.id_clinical_service, dcs_list.alert_cs, dcs_list.id_software
          BULK COLLECT
          INTO o_dcs, o_def_cs, o_cs, o_software_dcs
          FROM (SELECT dcs.id_dep_clin_serv,
                       nvl((SELECT def_cs.id_clinical_service
                             FROM alert_default.clinical_service def_cs
                            WHERE def_cs.id_content = cs.id_content
                              AND def_cs.flg_available = g_flg_available),
                           0) id_clinical_service,
                       sd.id_software,
                       cs.id_clinical_service alert_cs
                  FROM dep_clin_serv dcs
                 INNER JOIN department d
                    ON (d.id_department = dcs.id_department)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = dcs.id_clinical_service)
                 INNER JOIN dept dp
                    ON (dp.id_dept = d.id_dept)
                 INNER JOIN software_dept sd
                    ON (sd.id_dept = dp.id_dept)
                 WHERE dcs.flg_available = g_flg_available
                   AND d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND cs.flg_available = g_flg_available
                   AND d.id_institution = i_id_institution
                   AND d.id_institution = dp.id_institution
                   AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                           column_value
                                            FROM TABLE(CAST(i_id_software AS table_number)) sw_list)) dcs_list
         WHERE dcs_list.id_clinical_service != 0;
        IF o_dcs.count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END get_valid_dcs_all;

    PROCEDURE get_valid_dcs_for_softwares
    (
        i_lang        IN VARCHAR2,
        i_institution IN NUMBER,
        i_soft        IN table_number,
        i_dcs         IN table_number,
        o_dcs         OUT table_number
    ) IS
    BEGIN
    
        SELECT DISTINCT dcs_list_valid.id_dcs
          BULK COLLECT
          INTO o_dcs
          FROM (SELECT dcs_id_list.id_dcs
                  FROM (SELECT column_value id_dcs
                          FROM TABLE(CAST(i_dcs AS table_number))) dcs_id_list
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = dcs_id_list.id_dcs AND dcs.flg_available = g_flg_available)
                 INNER JOIN department d
                    ON (d.id_department = dcs.id_department)
                 INNER JOIN dept dp
                    ON (dp.id_dept = d.id_dept)
                 INNER JOIN software_dept sd
                    ON (sd.id_dept = dp.id_dept)
                 WHERE d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND d.id_institution = i_institution
                   AND d.id_institution = dp.id_institution
                   AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                           column_value
                                            FROM TABLE(CAST(i_soft AS table_number)) sw_list)) dcs_list_valid;
    
    END get_valid_dcs_for_softwares;
    /********************************************************************************************
    * Returns true or false and list of valid DCS expanded by software
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_software           Software identifier list
    * @param i_dcs                   Dep_clin_serv identifier list
    * @param i_cs                    Clinical_service identifier list
    * @param o_dcs                   Dep_clin_serv identifier list
    * @param o_def_cs                Default Clinical_service identifier list
    * @param o_software_dcs          Software identifier list
    * @param o_cs                    Clinical_service identifier list
    * @param o_error                 Error ID
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2013/03/06
    * @version                       2.6.3.x
    ********************************************************************************************/
    FUNCTION get_valid_dcs_from_input
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        i_dcs            IN table_number,
        i_cs             IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DCS AND VALIDATED SOFTWARE AND CLINICAL SERVICES LIST';
        SELECT dcs_list_valid.id_dcs,
               dcs_list_valid.id_cs,
               dcs_list_valid.id_software,
               dcs_list_valid.id_clinical_service
          BULK COLLECT
          INTO o_dcs, o_cs, o_software_dcs, o_def_cs
          FROM (SELECT dcs_id_list.id_dcs,
                       cs_id_list.id_cs,
                       sd.id_software,
                       nvl((SELECT def_cs.id_clinical_service
                             FROM alert_default.clinical_service def_cs
                            WHERE def_cs.id_content = cs.id_content
                              AND def_cs.flg_available = g_flg_available),
                           0) id_clinical_service
                  FROM (SELECT rownum idx, column_value id_dcs
                          FROM TABLE(CAST(i_dcs AS table_number))) dcs_id_list
                 INNER JOIN (SELECT rownum idx, column_value id_cs
                              FROM TABLE(CAST(i_cs AS table_number))) cs_id_list
                    ON (cs_id_list.idx = dcs_id_list.idx)
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = dcs_id_list.id_dcs AND dcs.flg_available = g_flg_available)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = cs_id_list.id_cs)
                 INNER JOIN department d
                    ON (d.id_department = dcs.id_department)
                 INNER JOIN dept dp
                    ON (dp.id_dept = d.id_dept)
                 INNER JOIN software_dept sd
                    ON (sd.id_dept = dp.id_dept)
                 WHERE d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND d.id_institution = i_id_institution
                   AND d.id_institution = dp.id_institution
                   AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                           column_value
                                            FROM TABLE(CAST(i_id_software AS table_number)) sw_list)) dcs_list_valid
         WHERE dcs_list_valid.id_clinical_service != 0
         ORDER BY dcs_list_valid.id_software, dcs_list_valid.id_dcs;
    
        IF o_dcs.count > 0
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'INVALID LISTS (SOFTWARE, DEP_CLIN_SERV, CLINICAL_SERVICE)';
            RETURN FALSE;
        END IF;
    END get_valid_dcs_from_input;

    /********************************************************************************************
    * Returns true or false and list of valid cs/dcs combinations taken from dcs given.
    * Results are expanded expanded by software
    *
    * @param i_lang                  Language id
    * @param i_id_institution        Institution identifier
    * @param i_id_software           Software identifier list
    * @param i_dcs                   Dep_clin_serv identifier list
    * @param o_dcs                   Dep_clin_serv identifier list
    * @param o_def_cs                Default Clinical_service identifier list
    * @param o_software_dcs          Software identifier list
    * @param o_cs                    Clinical_service identifier list
    * @param o_error                 Error ID
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        LCRS
    * @since                         2013/11/28
    * @version                       2.6.3.x
    ********************************************************************************************/
    FUNCTION get_valid_cs_from_dcs_input
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN table_number,
        i_dcs            IN table_number,
        o_dcs            OUT table_number,
        o_def_cs         OUT table_number,
        o_cs             OUT table_number,
        o_software_dcs   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DCS AND VALIDATED SOFTWARE AND CLINICAL SERVICES LIST';
        SELECT dcs_list_valid.id_dcs,
               dcs_list_valid.id_clinical_service,
               dcs_list_valid.id_software,
               dcs_list_valid.id_clinical_service_def
          BULK COLLECT
          INTO o_dcs, o_cs, o_software_dcs, o_def_cs
          FROM (SELECT dcs_id_list.id_dcs,
                       cs.id_clinical_service,
                       sd.id_software,
                       nvl((SELECT def_cs.id_clinical_service
                             FROM alert_default.clinical_service def_cs
                            WHERE def_cs.id_content = cs.id_content
                              AND def_cs.flg_available = g_flg_available),
                           0) id_clinical_service_def
                  FROM (SELECT rownum idx, column_value id_dcs
                          FROM TABLE(CAST(i_dcs AS table_number))) dcs_id_list
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = dcs_id_list.id_dcs AND dcs.flg_available = g_flg_available)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = dcs.id_clinical_service)
                 INNER JOIN department d
                    ON (d.id_department = dcs.id_department)
                 INNER JOIN dept dp
                    ON (dp.id_dept = d.id_dept)
                 INNER JOIN software_dept sd
                    ON (sd.id_dept = dp.id_dept)
                 WHERE d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND d.id_institution = i_id_institution
                   AND d.id_institution = dp.id_institution
                   AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                           column_value
                                            FROM TABLE(CAST(i_id_software AS table_number)) sw_list)) dcs_list_valid
         WHERE dcs_list_valid.id_clinical_service_def > 0
         ORDER BY dcs_list_valid.id_software, dcs_list_valid.id_dcs;
    
        IF o_dcs.count > 0
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'INVALID LISTS (SOFTWARE, DEP_CLIN_SERV, CLINICAL_SERVICE)';
            RETURN FALSE;
        END IF;
    END get_valid_cs_from_dcs_input;
    -- get alert_default clinical_service ids based on id_content
    FUNCTION get_default_cs_id
    (
        i_lang    IN language.id_language%TYPE,
        i_cs_list IN table_number,
        o_cs_list OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_def_cs_id clinical_service.id_clinical_service%TYPE;
    BEGIN
        o_cs_list := table_number();
        FOR i IN 1 .. i_cs_list.count
        LOOP
            SELECT nvl((SELECT def_cs.id_clinical_service
                         FROM alert_default.clinical_service def_cs
                        INNER JOIN clinical_service ext_cs
                           ON (ext_cs.id_content = def_cs.id_content)
                        WHERE ext_cs.id_clinical_service = i_cs_list(i)
                          AND rownum = 1),
                       0)
              INTO l_def_cs_id
              FROM dual;
        
            IF l_def_cs_id != 0
            THEN
                o_cs_list.extend;
                o_cs_list(i) := l_def_cs_id;
            ELSE
                RETURN FALSE;
            END IF;
        
        END LOOP;
        RETURN TRUE;
    END get_default_cs_id;

    /********************************************************************************************
    * get list of software modules by area and institution
    *
    * @param i_lang                Language id
    * @param i_id_tool_area         Default area id
    * @param i_id_institution      institution id
    * @param o_id_sw               list of final softwares to configure by area
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/15
    ********************************************************************************************/
    /* FUNCTION check_softwares
    (
        i_lang           IN language.id_language%TYPE,
        i_id_tool_area   IN tool_area.id_tool_area%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_id_sw          OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        aux NUMBER;
    BEGIN
    
        g_func_name := upper('check_softwares');
        o_id_sw     := table_number();
    
        SELECT COUNT(*)
          INTO aux
          FROM tool_soft_area_dep dpsad
         WHERE dpsad.id_tool_area = i_id_tool_area
           AND dpsad.flg_status = g_flg_checked
           AND dpsad.id_institution IN (i_id_institution, 0);
    
        IF aux = 0
        THEN
    
            SELECT sw.id_software BULK COLLECT
              INTO o_id_sw
              FROM software sw
             WHERE sw.flg_viewer = g_flg_unavailable
               AND EXISTS (SELECT 1
                      FROM software_institution si
                     WHERE si.id_institution = i_id_institution
                       AND si.id_software = sw.id_software);
    
        ELSE
            SELECT dpsad.id_software BULK COLLECT
              INTO o_id_sw
              FROM tool_soft_area_dep dpsad
             WHERE dpsad.id_tool_area = i_id_tool_area
               AND dpsad.flg_status = g_flg_checked
               AND dpsad.id_institution IN (i_id_institution, 0)
               AND EXISTS (SELECT 1
                      FROM software_institution si
                     WHERE si.id_institution = i_id_institution
                       AND si.id_software = dpsad.id_software);
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
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_softwares;*/
    /********************************************************************************************
    * get all valid software modules
    *
    * @param i_lang                 Language id
    * @param i_institution          Institution id
    * @param i_param_sw_list        Parameter Software id list
    * @param o_sw_list              Output valid software list
    * @param o_error                Error output
    *
    * @author                       RMGM
    * @version                      2.6.2
    * @since                        2012/07/30
    ********************************************************************************************/
    FUNCTION check_software_instit
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_param_sw_list IN table_number,
        o_sw_list       OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('check_software_instit');
        IF i_param_sw_list.count > 0
        THEN
            SELECT si.id_software
              BULK COLLECT
              INTO o_sw_list
              FROM software_institution si
             WHERE si.id_institution = i_institution
               AND si.id_software IN (SELECT /*+ opt_estimate(soft_list rows = 10)*/
                                       column_value
                                        FROM TABLE(CAST(i_param_sw_list AS table_number)) sw_list);
            IF o_sw_list.count < 1
            THEN
                RETURN FALSE;
            ELSE
                RETURN TRUE;
            END IF;
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
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_software_instit;
    /********************************************************************************************
    * get list of complaint relations
    *
    * @param i_lang                Language id
    * @param i_id_complaint        Complaint initial id
    * @param o_id_comp             list of complaint upper leaf ids
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/30
    ********************************************************************************************/
    FUNCTION check_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_id_complaint IN complaint.id_complaint%TYPE,
        o_id_comp      OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('check_complaint');
        o_id_comp   := table_number();
    
        SELECT def_data.id_complaint
          BULK COLLECT
          INTO o_id_comp
          FROM (SELECT cr.rowid,
                       cr.id_complaint,
                       rank() over(PARTITION BY cr.id_complaint ORDER BY cr.rowid) records_count
                  FROM complaint_rel cr
                 WHERE cr.flg_available = g_flg_available
                 START WITH cr.id_complaint = i_id_complaint
                CONNECT BY PRIOR cr.id_comp_parent = cr.id_complaint) def_data
         WHERE def_data.records_count = 1;
    
        IF o_id_comp.count < 1
        THEN
            o_id_comp.extend;
            o_id_comp(1) := i_id_complaint;
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
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_complaint;
    /********************************************************************************************
    * Get list of Profiles to configure by category, software, market and institution filtering
    *
    * @param i_lang                Language id
    * @param i_id_category         Professional category id
    * @param i_id_market           Configuration Market id
    * @param i_id_software         Software module id
    * @param o_id_cat              list of profile templata ids to configure
    * @param o_error               error output
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.2
    * @since                       2012/07/30
    ********************************************************************************************/
    FUNCTION check_category
    (
        i_lang        IN language.id_language%TYPE,
        i_id_category IN category.id_category%TYPE,
        i_id_market   IN market.id_market%TYPE,
        i_id_software IN software.id_software%TYPE,
        o_id_cat      OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('check_category');
    
        SELECT pt.id_profile_template
          BULK COLLECT
          INTO o_id_cat
          FROM profile_template pt
         WHERE pt.flg_available = g_flg_available
           AND pt.id_software IN (0, i_id_software)
           AND EXISTS (SELECT 1
                  FROM profile_template_market ptm
                 INNER JOIN profile_template_category ptc
                    ON ptc.id_profile_template = ptm.id_profile_template
                 WHERE ptm.id_profile_template = pt.id_profile_template
                   AND ptm.id_market IN (0, i_id_market)
                   AND ptc.id_category = i_id_category);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_category;
    /********************************************************************************************
    * Set default labtests migration base table
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.3.1
    * @since                       2012/11/29
    ********************************************************************************************/
    FUNCTION load_labtest_migration_base
    (
        i_lang  IN language.id_language%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_labtest_migration_base');
        g_error     := 'LOADING LABTESTS MIGRATION BASE TABLE';
        INSERT INTO analysis_sample_type_mig
            (id_analysis, id_sample_type, id_analysis_legacy)
            SELECT double_check.id_analysis, double_check.id_sample_type, double_check.id_legacy
              FROM (SELECT checked_content.id_analysis, checked_content.id_sample_type, a.id_analysis id_legacy
                      FROM (SELECT ast.id_analysis, ast.id_sample_type, mig_base.id_content_client
                              FROM alert_default.analysis_sample_type_mig mig_base
                             INNER JOIN analysis_sample_type ast
                                ON (ast.id_content = mig_base.id_content_analysis_st)) checked_content
                     INNER JOIN analysis a
                        ON (a.id_content = checked_content.id_content_client)) double_check;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END load_labtest_migration_base;
    /* procedure that execute maintenance apis (xmap, EA rebuild, orders check)*/
    PROCEDURE post_default_maintenance
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_softw_list            IN table_number,
        i_flg_exam_bs_xmap      IN BOOLEAN DEFAULT FALSE,
        i_flg_orders_review     IN BOOLEAN DEFAULT FALSE,
        i_flgintakeoutp_ref     IN BOOLEAN DEFAULT FALSE,
        i_flg_diagnosis_rebuild IN BOOLEAN DEFAULT FALSE
    ) IS
        l_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
    
        IF i_flg_exam_bs_xmap
        THEN
            g_error := 'SET BODY STRUCTURE RELATION + SYS_CONFIG';
            IF NOT pk_exam_utils.create_body_struct_rel(i_lang               => i_lang,
                                                        i_prof               => profissional(0, i_id_institution, 0),
                                                        i_mcs_concept        => NULL,
                                                        i_mcs_concept_parent => NULL,
                                                        o_error              => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
        IF i_flg_orders_review
        THEN
            g_error := 'REMOVE ORDERS WITHOUT TASKS';
            pk_backoffice_default.orders_double_check(i_lang, i_id_institution, l_error);
        END IF;
        IF i_flgintakeoutp_ref
        THEN
            g_error := 'CHECK PROGRESS NOTES AND CPOE RELATIONS WITH I/O';
            pk_def_cpoe_out.set_cpoe_hidric_references();
            pk_def_prog_notes_out.update_button_hidrics_ref();
            pk_task_type.set_tt_hidric_references();
        END IF;
        IF i_flg_diagnosis_rebuild
        THEN
            g_error := 'EA GENERATION OVER TERM_SERVER CONFIGURATIONS';
            pk_ea_logic_diagnosis.rebuild_diagnosis_ea(i_id_institution, i_softw_list, FALSE);
            pk_ea_logic_not_order_reason.populate_ea(i_id_institution);
            pk_coding_terminology.populate_ea(i_id_institution);
            pk_coding_terminology.populate_ea_levels(i_id_institution);
        END IF;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              l_error);
    END post_default_maintenance;
    /*
    Method that Register and schedulle job to execute maintenance post default
    */
    FUNCTION post_def_job
    (
        i_lang  IN language.id_language%TYPE,
        l_sql   IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_job_name   VARCHAR2(200);
        l_start_time TIMESTAMP(6) WITH LOCAL TIME ZONE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        g_error      := 'CREATE JOB NAME WITH PREFIX';
        l_job_name   := dbms_scheduler.generate_job_name('POSTDEFMNT');
        l_start_time := SYSDATE + 1 / 1440;
        -- possibility of more jobs be created in a single operation;
        g_error := 'CREATE JOB ' || l_job_name;
        dbms_scheduler.create_job(job_name   => l_job_name,
                                  job_type   => 'PLSQL_BLOCK',
                                  job_action => l_sql,
                                  start_date => l_start_time,
                                  comments   => 'Post default maintenance routine ',
                                  enabled    => TRUE,
                                  auto_drop  => TRUE);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_func_name := upper('post_def_job');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
    END post_def_job;

    /**
    * Set complete default configuration (content, search, frequent and translations) using new engine
    *
    * @param i_lang                        Prefered language ID
    * @param i_id_market               Market ID
    * @param i_version                    ALERT version
    * @param i_software                  Software ID's    
    * @param i_id_content               ID's Content
    * @param i_id_clinical_service   Clinical Service ID
    * @param i_id_clinical_service   Clinical Service ID
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)
    * @param o_error                      Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                 RMGM
    * @version                                0.1
    * @since                                   2013/05/17
    */

    FUNCTION set_full_default_config
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_market              IN table_number,
        i_version             IN table_varchar,
        i_id_software         IN table_number,
        i_id_content          IN table_varchar,
        i_id_clinical_service IN table_number,
        i_id_dep_clin_serv    IN table_number,
        i_flg_dcs_all         IN VARCHAR2 DEFAULT 'Y',
        i_commit_at_end       IN VARCHAR2,
        o_results             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_d_institution institution.id_institution%TYPE := NULL;
        i_process_type  table_varchar := table_varchar('CORE');
        i_areas         table_varchar := table_varchar();
        i_tables        table_varchar := table_varchar();
        l_all_sw        table_number := table_number();
        i_dependencies  VARCHAR2(1) := 'N';
        o_execution_id  NUMBER := 0;
        l_exception EXCEPTION;
    BEGIN
        IF i_id_software.count = 0
        THEN
            SELECT si.id_software
              BULK COLLECT
              INTO l_all_sw
              FROM software_institution si
             WHERE si.id_institution = i_id_institution;
        ELSE
            l_all_sw := i_id_software;
        END IF;
        g_error := 'SET DEFAULT INSTITUTION CONFIGURATIONS';
        alert_core_func.pk_tool_engine.set_default_configuration(i_lang                => i_lang,
                                                                 i_market              => i_market,
                                                                 i_version             => i_version,
                                                                 i_institution         => i_id_institution,
                                                                 i_d_institution       => i_d_institution,
                                                                 i_software            => l_all_sw,
                                                                 i_id_content          => i_id_content,
                                                                 i_flg_dcs_all         => i_flg_dcs_all,
                                                                 i_id_clinical_service => i_id_clinical_service,
                                                                 i_dep_clin_serv       => i_id_dep_clin_serv,
                                                                 i_dependencies        => i_dependencies,
                                                                 i_process_type        => i_process_type,
                                                                 i_areas               => i_areas,
                                                                 i_tables              => i_tables,
                                                                 o_execution_id        => o_execution_id,
                                                                 o_error               => o_error);
    
        OPEN o_results FOR
            SELECT ex_det.id_execution_det,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_area), ex_det.tool_area_name) area_name,
                   ex_det.tool_table_name table_name,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_process_type), ex_det.internal_name) process_name,
                   ex_det.rec_inserted,
                   ex_det.execution_status,
                   ex_det.execution_length
              FROM alert_core_data.v_exec_hist_details ex_det
             WHERE ex_det.id_execution = o_execution_id;
    
        IF i_commit_at_end = g_flg_available
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_FULL_DEFAULT_CONFIG',
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
                                              'SET_FULL_DEFAULT_CONFIG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_full_default_config;

    /**
    * Set complete default configuration BY AREA (content, search, frequent and translations) using new engine
    *
    * @param i_lang                         Prefered language ID
    * @param i_id_market                Market ID
    * @param i_version                     ALERT version
    * @param i_software                   Software ID's
    * @param i_software                   ID's Content
    * @param i_id_clinical_service    Clinical Service ID
    * @param i_id_clinical_service    Clinical Service ID
    * @param i_commit_at_end         Commit automatic in transaction (Y, N)
    * @param o_error                        Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/27
    */

    FUNCTION set_iso_area
    (
        i_lang              IN language.id_language%TYPE,
        i_area_to_config    IN VARCHAR2,
        i_area_dependecies  IN VARCHAR2 DEFAULT 'N',
        i_content_universe  IN VARCHAR2 DEFAULT 'N',
        i_search_cfg        IN VARCHAR2 DEFAULT 'N',
        i_mypreferences_all IN VARCHAR2 DEFAULT 'N',
        i_commit_at_end     IN VARCHAR2 DEFAULT 'N',
        i_market            IN table_number,
        i_version           IN table_varchar,
        i_id_institution    IN institution.id_institution%TYPE,
        i_software          IN table_number,
        i_id_content        IN table_varchar,
        i_id_dep_clin_serv  IN table_number,
        o_results           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        i_d_institution       institution.id_institution%TYPE := NULL;
        i_id_clinical_service table_number := table_number();
        i_process_type        table_varchar := table_varchar();
        i_areas               table_varchar := table_varchar(i_area_to_config);
        i_tables              table_varchar := table_varchar();
        l_procs               NUMBER := 1;
    
        o_execution_id NUMBER := 0;
        l_exception EXCEPTION;
    BEGIN
        IF (i_content_universe = 'N' AND i_search_cfg = 'N' AND
           ((i_mypreferences_all = 'N' AND i_id_dep_clin_serv.count = 0) OR
           (i_mypreferences_all = 'Y' AND i_id_dep_clin_serv.count > 0)))
        THEN
            g_error := 'PARAMETERS NOT VALID, NEED AT LEAST ONE CONFIGURATION MODE';
            RAISE l_exception;
        END IF;
    
        IF i_content_universe = g_flg_available
        THEN
            i_process_type.extend;
            i_process_type(l_procs) := 'CONTENT';
            l_procs := l_procs + 1;
        END IF;
        IF i_search_cfg = g_flg_available
        THEN
            i_process_type.extend;
            i_process_type(l_procs) := 'SEARCH';
            l_procs := l_procs + 1;
        END IF;
        IF (i_mypreferences_all = g_flg_available OR i_id_dep_clin_serv.count > 0)
        THEN
            i_process_type.extend;
            i_process_type(l_procs) := 'FREQUENT';
            l_procs := l_procs + 1;
        END IF;
    
        IF i_process_type.count > 0
        THEN
            i_process_type.extend;
            i_process_type(l_procs) := 'TRANSLATION';
        
            g_error := 'SET DEFAULT INSTITUTION CONFIGURATIONS';
            alert_core_func.pk_tool_engine.set_default_configuration(i_lang                => i_lang,
                                                                     i_market              => i_market,
                                                                     i_version             => i_version,
                                                                     i_institution         => i_id_institution,
                                                                     i_d_institution       => i_d_institution,
                                                                     i_software            => i_software,
                                                                     i_id_content          => i_id_content,
                                                                     i_flg_dcs_all         => i_mypreferences_all,
                                                                     i_id_clinical_service => i_id_clinical_service,
                                                                     i_dep_clin_serv       => i_id_dep_clin_serv,
                                                                     i_dependencies        => i_area_dependecies,
                                                                     i_process_type        => i_process_type,
                                                                     i_areas               => i_areas,
                                                                     i_tables              => i_tables,
                                                                     o_execution_id        => o_execution_id,
                                                                     o_error               => o_error);
        END IF;
    
        IF i_commit_at_end = g_flg_available
        THEN
            COMMIT;
        END IF;
        OPEN o_results FOR
            SELECT ex_det.id_execution_det,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_area), ex_det.tool_area_name) area_name,
                   ex_det.tool_table_name table_name,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_process_type), ex_det.internal_name) process_name,
                   ex_det.rec_inserted,
                   ex_det.execution_status,
                   ex_det.execution_length
              FROM alert_core_data.v_exec_hist_details ex_det
             WHERE ex_det.id_execution = o_execution_id;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_ISO_AREA',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_iso_area;

BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);
    -- var definition
    g_flg_available := pk_alert_constant.g_available;
    g_yes           := pk_alert_constant.g_yes;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_api_backoffice_default;
/
