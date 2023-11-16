/*-- Last Change Revision: $Rev: 1982177 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-03-09 15:31:36 +0000 (ter, 09 mar 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_default_inst_preferences IS
    -- Package info
    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_DEFAULT_INST_PREFERENCES';
    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/03/01
    ********************************************************************************************/
    PROCEDURE set_default_param_freq
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_job_name IN VARCHAR2
    ) IS
        l_exception EXCEPTION;
        l_error       t_error_out;
        l_alert_ok    sys_alert.id_sys_alert%TYPE := 209;
        l_alert_nok   sys_alert.id_sys_alert%TYPE := 208;
        l_default_val episode.id_episode%TYPE := -1;
        l_control_var NUMBER := 0;
    
        l_param_def_vers_array table_varchar := table_varchar();
    BEGIN
        g_func_name := upper('set_default_param_freq');
        -- convert version strings into a table of content versions
        SELECT pk_utils.str_split_c(i_version,
                                    '|')
        INTO   l_param_def_vers_array
        FROM   dual;
    
        FOR vrs IN 1 .. l_param_def_vers_array.count
        LOOP
            pk_alertlog.log_info(i_job_name || ' in ' || i_id_dep_clin_serv || ', (version) ' ||
                                 l_param_def_vers_array(vrs));
            g_error := 'GET ALERT INSTITUTION ID';
            IF NOT set_inst_default_param_freq(i_lang,
                                               i_id_market,
                                               l_param_def_vers_array(vrs),
                                               i_id_software,
                                               i_id_clinical_service,
                                               i_id_dep_clin_serv,
                                               l_error)
            THEN
                pk_alertlog.log_info(i_id_dep_clin_serv || ' configuration error ' || l_error.log_id);
                l_control_var := 0;
            ELSE
                pk_alertlog.log_info('Defaul Param Freq ok ' || i_id_dep_clin_serv);
                l_control_var := 1;
            END IF;
        END LOOP;
        IF l_control_var = 1
        THEN
            g_error := 'SET INFO ALERT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => l_alert_ok,
                                                    i_id_episode          => l_default_val,
                                                    i_id_record           => i_id_dep_clin_serv,
                                                    i_dt_record           => current_timestamp,
                                                    i_id_room             => l_default_val,
                                                    i_id_clinical_service => l_default_val,
                                                    i_replace1            => '',
                                                    i_flg_type_dest       => '',
                                                    i_replace2            => '',
                                                    i_id_professional     => NULL,
                                                    o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error := 'SET ERROR ALERT';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => l_alert_nok,
                                                    i_id_episode          => l_default_val,
                                                    i_id_record           => i_id_dep_clin_serv,
                                                    i_dt_record           => current_timestamp,
                                                    i_id_room             => l_default_val,
                                                    i_id_clinical_service => l_default_val,
                                                    i_replace1            => '',
                                                    i_flg_type_dest       => '',
                                                    i_replace2            => '',
                                                    i_id_professional     => NULL,
                                                    o_error               => l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_default_param_freq',
                                              l_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
    END set_default_param_freq;
    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_default_param_freq
    (
        i_lang                IN language.id_language%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_version             IN VARCHAR2,
        i_id_software         IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_out t_error_out;
        l_exception EXCEPTION;
    
        l_id_inst             institution.id_institution%TYPE;
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
    
        l_c_analysis         pk_types.cursor_type;
        l_c_exams            pk_types.cursor_type;
        l_c_exam_cat         pk_types.cursor_type;
        l_c_interv           pk_types.cursor_type;
        l_c_text             pk_types.cursor_type;
        l_c_int_med          pk_types.cursor_type;
        l_c_serum            pk_types.cursor_type;
        l_c_ext_med          pk_types.cursor_type;
        l_c_diag_layout      pk_types.cursor_type;
        l_c_cipe             pk_types.cursor_type;
        l_c_dietary          pk_types.cursor_type;
        l_c_discharge_reason pk_types.cursor_type;
        l_c_templates        pk_types.cursor_type;
        l_c_transfer_option  pk_types.cursor_type;
        l_c_sr_interv        pk_types.cursor_type;
        l_c_pml_med          pk_types.cursor_type;
        -- ALERT-211849
        l_c_inst_icnp_axis_cs pk_types.cursor_type;
        l_c_bsdcs_config      pk_types.cursor_type;
        -- ALERT-216086
        l_c_inst_csad pk_types.cursor_type;
        l_c_inst_pop  pk_types.cursor_type;
        l_c_inst_rdcs pk_types.cursor_type;
        l_c_inst_vssa pk_types.cursor_type;
        l_c_inst_ccfg pk_types.cursor_type;
    
        l_c_inst_pod  pk_types.cursor_type;
        l_result      NUMBER;
        l_def_cs_list table_number := table_number();
        l_id_content  table_varchar := table_varchar();
    BEGIN
    
        g_error := 'GET ALERT INSTITUTION ID';
        SELECT s.id_institution
        INTO   l_id_inst
        FROM   dep_clin_serv dcs
        INNER  JOIN department s
        ON     (s.id_department = dcs.id_department)
        WHERE  dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        g_error := 'GET ALERT_DEFAULT CLINICAL SERVICE ID';
        SELECT nvl((SELECT cs.id_clinical_service
                   FROM   alert_default.clinical_service cs
                   WHERE  cs.id_content = (SELECT cs2.id_content
                                           FROM   clinical_service cs2
                                           WHERE  cs2.id_clinical_service = i_id_clinical_service)
                          AND rownum = 1),
                   0)
        INTO   l_id_clinical_service
        FROM   dual;
        pk_alertlog.log_info('Starting ' || l_id_clinical_service || ', ' || i_version || ', ' || i_id_market || ', ' ||
                             i_id_software);
        IF l_id_clinical_service != 0
        THEN
        
            g_error := ' MOST FREQUENT ANALYSIS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_analysis_freq(i_lang,
                                          i_id_market,
                                          i_version,
                                          l_id_inst,
                                          i_id_software,
                                          l_id_clinical_service,
                                          i_id_dep_clin_serv,
                                          l_c_analysis,
                                          o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT EXAMS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_exams_freq(i_lang,
                                       i_id_market,
                                       i_version,
                                       l_id_inst,
                                       i_id_software,
                                       l_id_clinical_service,
                                       i_id_dep_clin_serv,
                                       l_c_exams,
                                       o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT EXAM CATEGORIES';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_exam_cat_freq(i_lang,
                                          i_id_market,
                                          i_version,
                                          l_id_clinical_service,
                                          i_id_dep_clin_serv,
                                          l_c_exam_cat,
                                          o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT INTERVENTIONS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_interv_freq(i_lang,
                                        i_id_market,
                                        i_version,
                                        l_id_inst,
                                        i_id_software,
                                        l_id_clinical_service,
                                        i_id_dep_clin_serv,
                                        l_c_interv,
                                        o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT SAMPLE TEXTS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_sample_text_freq(i_lang,
                                             i_id_market,
                                             i_version,
                                             l_id_clinical_service,
                                             i_id_dep_clin_serv,
                                             l_c_text,
                                             o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT INTERNAL DRUGS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_int_med_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         l_id_inst,
                                         i_id_software,
                                         l_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         l_c_int_med,
                                         o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT SERUM';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_serum_const_freq(i_lang,
                                             i_id_market,
                                             i_version,
                                             l_id_inst,
                                             i_id_software,
                                             l_id_clinical_service,
                                             i_id_dep_clin_serv,
                                             l_c_serum,
                                             o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT EXTERNAL DRUGS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_ext_med_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         l_id_inst,
                                         i_id_software,
                                         l_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         l_c_ext_med,
                                         o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT BODY DIAGRAM LAYOUTS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_diag_layout_freq(i_lang,
                                             i_id_market,
                                             i_version,
                                             l_id_inst,
                                             i_id_software,
                                             l_id_clinical_service,
                                             i_id_dep_clin_serv,
                                             l_c_diag_layout,
                                             o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT ICNP COMPOSITIONS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_icnp_comp_freq(i_lang,
                                           i_id_market,
                                           i_version,
                                           l_id_inst,
                                           i_id_software,
                                           l_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           l_c_cipe,
                                           o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT DIAGNOSIS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_diagnosis_freq(i_lang,
                                           i_id_market,
                                           i_version,
                                           l_id_inst,
                                           i_id_software,
                                           l_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT DIETARY';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_dietary_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         i_id_software,
                                         l_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         l_c_dietary,
                                         o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT DISCHARGES';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_discharge_freq(i_lang,
                                           i_id_market,
                                           i_version,
                                           l_id_inst,
                                           i_id_software,
                                           l_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           l_c_discharge_reason,
                                           o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT TEMPLATES';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_templates_freq(i_lang,
                                           i_id_market,
                                           l_id_inst,
                                           i_version,
                                           i_id_software,
                                           l_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           l_c_templates,
                                           o_error)
            THEN
                RAISE l_exception;
            
            END IF;
        
            g_error := ' MOST FREQUENT TRANSFER_OPTION';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_transfer_option_freq(i_lang,
                                                 i_id_market,
                                                 i_version,
                                                 l_id_clinical_service,
                                                 i_id_dep_clin_serv,
                                                 l_c_transfer_option,
                                                 o_error)
            THEN
                RAISE l_exception;
            END IF;
            g_error := ' MOST FREQUENT SURGICAL PROCEDURES';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_sr_interv_freq(i_lang,
                                           i_id_market,
                                           i_version,
                                           l_id_inst,
                                           i_id_software,
                                           l_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           l_c_sr_interv,
                                           o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT REPORTED MEDICATION';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_pml_dcs_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         l_id_inst,
                                         i_id_software,
                                         l_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         l_c_pml_med,
                                         o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION ICNP AXIS DCS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_icnp_axis_cs(i_lang,
                                         l_id_inst,
                                         i_id_software,
                                         i_id_dep_clin_serv,
                                         l_c_inst_icnp_axis_cs,
                                         o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' MOST FREQUENT BODY_STRUCTURES';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_body_structure_freq(i_lang,
                                                i_id_market,
                                                i_version,
                                                l_id_inst,
                                                i_id_software,
                                                l_id_clinical_service,
                                                i_id_dep_clin_serv,
                                                l_c_bsdcs_config,
                                                o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION PERIODIC OBSERVATIONS DCS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_periodic_obs_param_freq(i_lang,
                                               i_id_market,
                                               i_version,
                                               l_id_inst,
                                               i_id_software,
                                               l_id_clinical_service,
                                               i_id_dep_clin_serv,
                                               l_c_inst_pop,
                                               o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION PERIODIC OBSERVATIONS DCS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_periodic_obs_desc_freq(i_lang,
                                              i_id_market,
                                              i_version,
                                              l_id_inst,
                                              i_id_software,
                                              l_id_clinical_service,
                                              i_id_dep_clin_serv,
                                              l_c_inst_pod,
                                              o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION PAST HISTORY DCS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_past_history_freq(i_lang,
                                              i_id_market,
                                              i_version,
                                              l_id_inst,
                                              i_id_software,
                                              l_id_clinical_service,
                                              l_c_inst_csad,
                                              o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION REHAB TYPE DCS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_rehab_st_freq(i_lang,
                                          i_id_market,
                                          i_version,
                                          l_id_inst,
                                          i_id_software,
                                          l_id_clinical_service,
                                          i_id_dep_clin_serv,
                                          l_c_inst_rdcs,
                                          o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION COMPLICATION CS';
            pk_alertlog.log_info('Processing' || g_error);
            IF NOT set_inst_comp_config_freq(i_lang,
                                             i_id_market,
                                             i_version,
                                             l_id_inst,
                                             i_id_software,
                                             l_id_clinical_service,
                                             l_c_inst_ccfg,
                                             o_error)
            THEN
                RAISE l_exception;
            END IF;
            g_error := ' INSTITUTION INTERVENTION BY CATEGORY';
            IF NOT set_int_dcs_mf_except_all(i_lang,
                                             l_id_inst,
                                             table_number(i_id_market),
                                             table_varchar(i_version),
                                             table_number(i_id_software),
                                             NULL,
                                             NULL,
                                             i_id_dep_clin_serv,
                                             l_result,
                                             o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := ' INSTITUTION INTERV_PLAN FREQUENT';
            IF NOT set_intervplan_freq(i_lang,
                                       l_id_inst,
                                       table_number(i_id_market),
                                       table_varchar(i_version),
                                       table_number(i_id_software),
                                       table_number(l_id_clinical_service),
                                       NULL,
                                       i_id_dep_clin_serv,
                                       l_result,
                                       o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'GET DEFAULT CLINICAL_SERVICE LIST OF IDS ' || l_id_clinical_service;
            IF NOT
                pk_default_inst_preferences.check_clinical_service(i_lang, l_id_clinical_service, l_def_cs_list, o_error)
            THEN
                RAISE l_exception;
            END IF;
            g_error := 'SET PREFERENCES FOR ' || l_id_clinical_service;
            IF NOT pk_periodicobservation_prm.set_po_param_cs_freq(i_lang,
                                                                   l_id_inst,
                                                                   table_number(i_id_market),
                                                                   table_varchar(i_version),
                                                                   table_number(i_id_software),
                                                                   l_id_content,
                                                                   l_def_cs_list,
                                                                   l_id_clinical_service,
                                                                   i_id_dep_clin_serv,
                                                                   l_result,
                                                                   o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            COMMIT;
        
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
                                              'SET_INST_DEFAULT_PARAM_FREQ',
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
                                              'SET_INST_DEFAULT_PARAM_FREQ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_inst_default_param_freq;
    /********************************************************************************************
    * Check if clinical service is content source or if need to get parent clinical_services ids
    *
    * @param i_lang                Language ID
    * @param i_clinical_service    Primary clinical service ID
    * @param i_id_software         Software ID
    * @param i_table_name          Table to process       
    * @param o_id_cs               Cursor of final source clinical services
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.4
    * @since                       2011/10/20
    ********************************************************************************************/
    FUNCTION check_clinical_service
    (
        i_lang IN language.id_language%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_id_cs OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(500) := upper('check_clinical_service');
    BEGIN
        o_id_cs := table_number();
    
        SELECT def_data.id_clinical_service
        BULK   COLLECT
        INTO   o_id_cs
        FROM   (SELECT csr.rowid,
                       csr.id_clinical_service,
                       rank() over(PARTITION BY csr.id_clinical_service ORDER BY csr.rowid) records_count
                FROM   alert_default.clinical_serv_rel csr
                WHERE  csr.flg_available = g_flg_available
                START  WITH csr.id_clinical_service = i_clinical_service
                            AND csr.flg_available = g_flg_available
                CONNECT BY PRIOR csr.id_cs_parent = csr.id_clinical_service) def_data
        WHERE  def_data.records_count = 1;
    
        IF o_id_cs.count < 1
        THEN
            o_id_cs.extend;
            o_id_cs(1) := i_clinical_service;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_clinical_service;
    /********************************************************************************************
    * Get Most frequent Analysis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_analysis            Most frequent Analysis Configuration
    * @param o_analysis_group      Most frequent Analysis Groups Configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_analysis_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_analysis_config OUT pk_types.cursor_type,
        o_analysis_group_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_analysis_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_analysis_config FOR
            SELECT def_data.id_analysis,
                   def_data.l_rank,
                   def_data.id_sample_type
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_analysis,
                           temp_data.l_rank,
                           temp_data.id_sample_type,
                           row_number() over(PARTITION BY temp_data.id_analysis, temp_data.id_sample_type ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT acs.rowid l_row,
                                   nvl((SELECT alert_a.id_analysis
                                       FROM   analysis alert_a
                                       INNER  JOIN alert_default.analysis a
                                       ON     (a.id_content = alert_a.id_content AND a.flg_available = g_flg_available)
                                       WHERE  a.id_analysis = acs.id_analysis
                                              AND alert_a.flg_available = g_flg_available),
                                       0) id_analysis,
                                   nvl(acs.rank,
                                       0) l_rank,
                                   decode(acs.id_sample_type,
                                          NULL,
                                          NULL,
                                          nvl((SELECT stp.id_sample_type
                                              FROM   sample_type stp
                                              WHERE  stp.id_content =
                                                     (SELECT def_st.id_content
                                                      FROM   alert_default.sample_type def_st
                                                      WHERE  def_st.id_sample_type = acs.id_sample_type
                                                             AND def_st.flg_available = g_flg_available)
                                                     AND stp.flg_available = g_flg_available
                                                     AND rownum = 1),
                                              0)) id_sample_type
                            FROM   alert_default.analysis_clin_serv acs
                            INNER  JOIN alert_default.analysis_sample_type ast
                            ON     (ast.id_analysis = acs.id_analysis AND ast.id_sample_type = acs.id_sample_type)
                            INNER  JOIN alert_default.ast_mkt_vrs amv
                            ON     (amv.id_content = ast.id_content AND amv.id_market = i_id_market AND
                                   amv.version = i_version)
                            WHERE  acs.id_analysis_group IS NULL
                                   AND acs.flg_available = g_flg_available
                                   AND acs.id_software = i_id_software
                                   AND acs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_analysis != 0
                           AND temp_data.id_sample_type != 0) def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   analysis_instit_soft ais
                    WHERE  ais.id_analysis = def_data.id_analysis
                           AND ais.flg_type = 'P'
                           AND ais.id_institution = i_id_institution
                           AND ais.id_sample_type = def_data.id_sample_type
                           AND ais.id_software = i_id_software
                           AND ais.flg_available = g_flg_available)
                   AND EXISTS (SELECT 0
                    FROM   analysis_sample_type aast
                    WHERE  aast.id_analysis = def_data.id_analysis
                           AND aast.id_sample_type = def_data.id_sample_type)
                   AND NOT EXISTS (SELECT 0
                    FROM   analysis_dep_clin_serv adcs
                    WHERE  adcs.id_analysis = def_data.id_analysis
                           AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND adcs.id_software = i_id_software
                           AND adcs.id_sample_type = def_data.id_sample_type);
    
        OPEN o_analysis_group_config FOR
            SELECT def_data.id_analysis_group,
                   def_data.l_rank
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_analysis_group,
                           temp_data.l_rank,
                           rank() over(PARTITION BY temp_data.id_analysis_group ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT acs.rowid l_row,
                                   nvl((SELECT alert_ag.id_analysis_group
                                       FROM   analysis_group alert_ag
                                       WHERE  alert_ag.id_content = ag.id_content
                                              AND alert_ag.flg_available = g_flg_available),
                                       0) id_analysis_group,
                                   nvl(acs.rank,
                                       0) l_rank
                            FROM   alert_default.analysis_clin_serv acs
                            INNER  JOIN alert_default.analysis_group ag
                            ON     (ag.id_analysis_group = acs.id_analysis_group)
                            INNER  JOIN alert_default.analysis_group_mrk_vrs agmv
                            ON     (agmv.id_analysis_group = ag.id_analysis_group AND agmv.id_market = i_id_market AND
                                   agmv.version = i_version)
                            WHERE  acs.id_analysis IS NULL
                                   AND acs.flg_available = g_flg_available
                                   AND acs.id_software = i_id_software
                                   AND acs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_analysis_group != 0) def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   analysis_instit_soft ais
                    WHERE  ais.id_analysis_group = def_data.id_analysis_group
                           AND ais.flg_type = 'P'
                           AND ais.id_institution = i_id_institution
                           AND ais.id_software = i_id_software
                           AND ais.flg_available = g_flg_available)
                   AND NOT EXISTS (SELECT 0
                    FROM   analysis_dep_clin_serv adcs
                    WHERE  adcs.id_analysis_group = def_data.id_analysis_group
                           AND adcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND adcs.id_software = i_id_software);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              g_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_analysis_config);
            pk_types.open_my_cursor(o_analysis_group_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_analysis_freq;
    /********************************************************************************************
    * Set Most frequent Analysis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_adcs_config         Most frequent Analysis and Groups Configuration Id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_analysis_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_adcs_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- labs
        l_labid_array     table_number := table_number();
        l_rank_array      table_number := table_number();
        l_sptype_id_array table_number := table_number();
        -- groups
        l_labgid_array table_number := table_number();
        l_rankg_array  table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal  pk_types.cursor_type;
        c_input_internal2 pk_types.cursor_type;
        l_aux1            table_number := table_number();
        l_aux2            table_number := table_number();
        l_auxf            table_number := table_number();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_analysis_freq(i_lang,
                                      i_id_market,
                                      i_version,
                                      i_id_institution,
                                      i_id_software,
                                      i_id_clinical_service,
                                      i_id_dep_clin_serv,
                                      c_input_internal,
                                      c_input_internal2,
                                      o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_analysis_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_labid_array,
                     l_rank_array,
                     l_sptype_id_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_labid_array.count SAVE EXCEPTIONS
                INSERT INTO analysis_dep_clin_serv
                    (id_analysis_dep_clin_serv,
                     id_analysis,
                     id_dep_clin_serv,
                     rank,
                     adw_last_update,
                     id_software,
                     flg_available,
                     id_sample_type)
                VALUES
                    (seq_analysis_dep_clin_serv.nextval,
                     l_labid_array(a),
                     i_id_dep_clin_serv,
                     l_rank_array(a),
                     SYSDATE,
                     i_id_software,
                     g_flg_available,
                     l_sptype_id_array(a))
                RETURNING id_analysis_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
            -- groups
            g_error := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal2 BULK COLLECT
                INTO l_labgid_array,
                     l_rankg_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_labgid_array.count SAVE EXCEPTIONS
                INSERT INTO analysis_dep_clin_serv
                    (id_analysis_dep_clin_serv,
                     id_dep_clin_serv,
                     rank,
                     adw_last_update,
                     id_software,
                     id_analysis_group,
                     flg_available)
                VALUES
                    (seq_analysis_dep_clin_serv.nextval,
                     i_id_dep_clin_serv,
                     l_rankg_array(a),
                     SYSDATE,
                     i_id_software,
                     l_labgid_array(a),
                     g_flg_available)
                RETURNING id_analysis_dep_clin_serv BULK COLLECT INTO l_aux2;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal2;
        
        END IF;
        l_auxf := l_aux1 MULTISET UNION l_aux2;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_adcs_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_analysis_freq;
    /********************************************************************************************
    * Get Most frequent Exams for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_exams_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exams_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_exams_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_exams_config FOR
            SELECT def_data.id_exam,
                   def_data.flg_type,
                   def_data.flg_first_result,
                   def_data.flg_mov_pat,
                   def_data.id_external_sys
            FROM   (SELECT temp_data.rowid,
                           temp_data.id_exam,
                           temp_data.flg_type,
                           temp_data.flg_first_result,
                           temp_data.flg_mov_pat,
                           temp_data.id_external_sys,
                           rank() over(PARTITION BY temp_data.id_exam, temp_data.flg_type ORDER BY temp_data.rowid) records_count
                    FROM   (SELECT ecs.rowid,
                                   nvl((SELECT alert_e.id_exam
                                       FROM   exam alert_e
                                       WHERE  alert_e.id_content = e.id_content
                                              AND alert_e.flg_available = g_flg_available),
                                       0) id_exam,
                                   ecs.flg_type,
                                   ecs.flg_first_result,
                                   ecs.flg_mov_pat,
                                   ecs.id_external_sys
                            FROM   alert_default.exam_clin_serv ecs
                            INNER  JOIN alert_default.exam e
                            ON     (e.id_exam = ecs.id_exam AND e.flg_available = g_flg_available)
                            INNER  JOIN alert_default.exam_mrk_vrs emv
                            ON     (emv.id_exam = ecs.id_exam AND emv.id_market = i_id_market AND emv.version = i_version)
                            WHERE  ecs.id_software = i_id_software
                                   AND ecs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_exam != 0) def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   exam_dep_clin_serv edcs
                    WHERE  edcs.id_exam = def_data.id_exam
                           AND edcs.flg_type = 'P'
                           AND edcs.id_institution = i_id_institution
                           AND edcs.id_software = i_id_software)
                   AND NOT EXISTS (SELECT 0
                    FROM   exam_dep_clin_serv edcs
                    WHERE  edcs.id_exam = def_data.id_exam
                           AND edcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND edcs.flg_type = def_data.flg_type
                           AND edcs.id_software = i_id_software);
    
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
            pk_types.open_my_cursor(o_exams_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_exams_freq;
    /********************************************************************************************
    * Set Most frequent Exams for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Configuration id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_exams_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exams_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_examid_array   table_number := table_number();
        l_flgtype_array  table_varchar := table_varchar();
        l_flgres_array   table_varchar := table_varchar();
        l_flgmov_array   table_varchar := table_varchar();
        l_extsysid_array table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_exams_freq(i_lang,
                                   i_id_market,
                                   i_version,
                                   i_id_institution,
                                   i_id_software,
                                   i_id_clinical_service,
                                   i_id_dep_clin_serv,
                                   c_input_internal,
                                   o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_exams_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_examid_array,
                     l_flgtype_array,
                     l_flgres_array,
                     l_flgmov_array,
                     l_extsysid_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_examid_array.count SAVE EXCEPTIONS
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv,
                     id_exam,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     adw_last_update,
                     id_software,
                     flg_first_result,
                     flg_mov_pat,
                     id_external_sys)
                VALUES
                    (seq_exam_dep_clin_serv.nextval,
                     l_examid_array(a),
                     i_id_dep_clin_serv,
                     l_flgtype_array(a),
                     0,
                     SYSDATE,
                     i_id_software,
                     l_flgres_array(a),
                     l_flgmov_array(a),
                     l_extsysid_array(a))
                RETURNING id_exam_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_exams_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_exams_freq;
    /********************************************************************************************
    * Get Most frequent Exam Cat. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams configutation
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_exam_cat_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exam_cat OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_diagnosis_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_exam_cat FOR
            SELECT def_data.id_exam_cat
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_exam_cat,
                           rank() over(PARTITION BY temp_data.id_exam_cat ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ecc.rowid l_row,
                                   nvl((SELECT alert_ec.id_exam_cat
                                       FROM   exam_cat alert_ec
                                       WHERE  alert_ec.id_content = ec.id_content
                                              AND alert_ec.flg_available = g_flg_available),
                                       0) id_exam_cat
                            FROM   alert_default.exam_cat_cs ecc
                            INNER  JOIN alert_default.exam_cat ec
                            ON     (ec.id_exam_cat = ecc.id_exam_cat AND ec.flg_available = g_flg_available)
                            WHERE  ecc.version = i_version
                                   AND ecc.id_market = i_id_market
                                   AND ecc.id_clin_serv IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_exam_cat != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   exam_cat_dcs ecdcs
                    WHERE  ecdcs.id_exam_cat = def_data.id_exam_cat
                           AND ecdcs.id_dep_clin_serv = i_id_dep_clin_serv);
    
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
            pk_types.open_my_cursor(o_exam_cat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_exam_cat_freq;
    /********************************************************************************************
    * Set Most frequent Exam Cat. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_exams               Most frequent Exams Default configutation records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_exam_cat_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_exam_cat_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_excatid_array table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_exam_cat_freq(i_lang,
                                      i_id_market,
                                      i_version,
                                      i_id_clinical_service,
                                      i_id_dep_clin_serv,
                                      c_input_internal,
                                      o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_exam_cat_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_excatid_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_excatid_array.count SAVE EXCEPTIONS
                INSERT INTO exam_cat_dcs
                    (id_exam_cat_dcs,
                     id_exam_cat,
                     id_dep_clin_serv)
                VALUES
                    (seq_exam_cat_dcs.nextval,
                     l_excatid_array(a),
                     i_id_dep_clin_serv)
                RETURNING id_exam_cat_dcs BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_exam_cat_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_exam_cat_freq;
    /********************************************************************************************
    * Get Most frequent Interventions for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Deparment/Clinical Service ID
    * @param o_interv              Most frequent Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_interv_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_interv_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_diagnosis_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_interv_config FOR
            SELECT def_data.id_intervention,
                   def_data.flg_type,
                   def_data.flg_bandaid,
                   def_data.flg_chargeable
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_intervention,
                           temp_data.flg_type,
                           temp_data.flg_bandaid,
                           temp_data.flg_chargeable,
                           rank() over(PARTITION BY temp_data.id_intervention, temp_data.flg_type ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ics.rowid l_row,
                                   nvl((SELECT alert_i.id_intervention
                                       FROM   intervention alert_i
                                       WHERE  alert_i.id_content = i.id_content
                                              AND alert_i.flg_status = g_active),
                                       0) id_intervention,
                                   ics.flg_type,
                                   ics.flg_bandaid,
                                   ics.flg_chargeable
                            FROM   alert_default.interv_clin_serv ics
                            INNER  JOIN alert_default.intervention i
                            ON     (i.id_intervention = ics.id_intervention AND i.flg_status = g_active)
                            INNER  JOIN alert_default.interv_mrk_vrs imv
                            ON     (imv.id_intervention = i.id_intervention AND imv.id_market = i_id_market AND
                                   imv.version = i_version)
                            WHERE  ics.id_software = i_id_software
                                   AND ics.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_intervention != 0) def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   interv_dep_clin_serv idcs
                    WHERE  idcs.id_intervention = def_data.id_intervention
                           AND idcs.id_dep_clin_serv IS NULL
                           AND idcs.flg_type = 'P'
                           AND idcs.id_institution = i_id_institution
                           AND idcs.id_software = i_id_software)
                   AND NOT EXISTS (SELECT 0
                    FROM   interv_dep_clin_serv idcs
                    WHERE  idcs.id_intervention = def_data.id_intervention
                           AND idcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND idcs.flg_type = def_data.flg_type
                           AND idcs.id_software = i_id_software);
    
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
            pk_types.open_my_cursor(o_interv_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_interv_freq;
    /********************************************************************************************
    * set Most frequent Interventions for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Deparment/Clinical Service ID
    * @param o_interv              Most frequent Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_interv_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_interv_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_intervid_array table_number := table_number();
        l_flgtype_array  table_varchar := table_varchar();
        l_flgban_array   table_varchar := table_varchar();
        l_flgcharg_array table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_interv_freq(i_lang,
                                    i_id_market,
                                    i_version,
                                    i_id_institution,
                                    i_id_software,
                                    i_id_clinical_service,
                                    i_id_dep_clin_serv,
                                    c_input_internal,
                                    o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_interv_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_intervid_array,
                     l_flgtype_array,
                     l_flgban_array,
                     l_flgcharg_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_intervid_array.count SAVE EXCEPTIONS
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     adw_last_update,
                     id_software,
                     flg_bandaid,
                     flg_chargeable)
                VALUES
                    (seq_interv_dep_clin_serv.nextval,
                     l_intervid_array(a),
                     i_id_dep_clin_serv,
                     l_flgtype_array(a),
                     0,
                     SYSDATE,
                     i_id_software,
                     l_flgban_array(a),
                     l_flgcharg_array(a))
                RETURNING id_interv_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_interv_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_interv_freq;
    /********************************************************************************************
    * Get Most frequent Texts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_text_config         Most frequent Texts configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_sample_text_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_text_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_sample_text_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_text_config FOR
            SELECT def_data.id_sample_text
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_sample_text,
                           rank() over(PARTITION BY temp_data.id_sample_text ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT stf.rowid l_row,
                                   nvl((SELECT st.id_sample_text
                                       FROM   sample_text st
                                       WHERE  st.id_sample_text = stf.id_sample_text
                                              AND st.flg_available = g_flg_available),
                                       0) id_sample_text
                            FROM   alert_default.sample_text_freq stf
                            WHERE  stf.version = i_version
                                   AND stf.id_market = i_id_market
                                   AND stf.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_sample_text != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   sample_text_freq stf
                    WHERE  stf.id_sample_text = def_data.id_sample_text
                           AND stf.id_dep_clin_serv = i_id_dep_clin_serv);
    
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
            pk_types.open_my_cursor(o_text_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_sample_text_freq;
    /********************************************************************************************
    * Get Most frequent Texts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_text_config         Most frequent Texts configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_sample_text_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_text_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_textid_array table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_sample_text_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         i_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         c_input_internal,
                                         o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_sample_text_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_textid_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_textid_array.count SAVE EXCEPTIONS
                INSERT INTO sample_text_freq
                    (id_freq_sample_text,
                     id_sample_text,
                     id_dep_clin_serv)
                VALUES
                    (seq_sample_text_freq.nextval,
                     l_textid_array(a),
                     i_id_dep_clin_serv)
                RETURNING id_freq_sample_text BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_text_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_sample_text_freq;
    /********************************************************************************************
    * Get Most frequent Internal Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_int_med             Most frequent internal medication configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_int_med_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_int_med_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
        g_func_name := upper('get_inst_serum_const_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_int_med_config FOR
            SELECT def_data.id_drug,
                   def_data.vers
            FROM   (SELECT dcs.rowid,
                           dcs.id_drug,
                           mm.vers,
                           rank() over(PARTITION BY dcs.id_drug, mm.vers ORDER BY dcs.rowid) records_count
                    FROM   alert_default.drug_clin_serv dcs
                    INNER  JOIN mi_med mm
                    ON     (mm.id_drug = dcs.id_drug AND mm.flg_available = g_flg_available)
                    WHERE  dcs.version = i_version
                           AND dcs.id_market = i_id_market
                           AND dcs.id_software = i_id_software
                           AND dcs.flg_type = 'M'
                           AND dcs.id_clinical_service IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                 column_value
                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)) def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   drug_dep_clin_serv ddcs
                    WHERE  ddcs.id_drug = def_data.id_drug
                           AND ddcs.id_dep_clin_serv IS NULL
                           AND ddcs.flg_type = 'P'
                           AND ddcs.id_institution = i_id_institution
                           AND ddcs.id_software = i_id_software
                           AND ddcs.vers = def_data.vers)
                   AND NOT EXISTS (SELECT 0
                    FROM   drug_dep_clin_serv ddcs
                    WHERE  ddcs.id_drug = def_data.id_drug
                           AND ddcs.vers = def_data.vers
                           AND ddcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND ddcs.flg_type = 'M'
                           AND ddcs.id_software = i_id_software);
    
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
            pk_types.open_my_cursor(o_int_med_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_int_med_freq;
    /********************************************************************************************
    * Set Most frequent Internal Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_int_med             Most frequent internal medication configured id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_int_med_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_int_med_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drugid_array table_varchar := table_varchar();
        l_vers_array   table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_int_med_freq(i_lang,
                                     i_id_market,
                                     i_version,
                                     i_id_institution,
                                     i_id_software,
                                     i_id_clinical_service,
                                     i_id_dep_clin_serv,
                                     c_input_internal,
                                     o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_int_med_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_drugid_array,
                     l_vers_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_drugid_array.count SAVE EXCEPTIONS
                INSERT INTO drug_dep_clin_serv
                    (id_drug_dep_clin_serv,
                     id_drug,
                     id_dep_clin_serv,
                     rank,
                     adw_last_update,
                     flg_type,
                     id_software,
                     vers)
                VALUES
                    (seq_drug_dep_clin_serv.nextval,
                     l_drugid_array(a),
                     i_id_dep_clin_serv,
                     0,
                     SYSDATE,
                     'M',
                     i_id_software,
                     l_vers_array(a))
                RETURNING id_drug_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_int_med_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_int_med_freq;
    /********************************************************************************************
    * Get Most frequent Serum for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_serum_config       Most frequent serum configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION get_inst_serum_const_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_serum_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_serum_const_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_serum_config FOR
            SELECT def_data.id_drug,
                   def_data.vers
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_drug,
                           temp_data.vers,
                           rank() over(PARTITION BY temp_data.id_drug, temp_data.vers ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT dcs.rowid l_row,
                                   dcs.id_drug,
                                   mm.vers
                            FROM   alert_default.drug_clin_serv dcs
                            INNER  JOIN mi_med mm
                            ON     (mm.id_drug = dcs.id_drug AND mm.flg_available = g_flg_available AND
                                   mm.flg_mix_fluid = g_flg_available AND mm.route_abrv = 'IV')
                            WHERE  dcs.version = i_version
                                   AND dcs.id_market = i_id_market
                                   AND dcs.id_software = i_id_software
                                   AND dcs.flg_type = 'F'
                                   AND dcs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_drug != '0') def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   drug_dep_clin_serv ddcs
                    WHERE  ddcs.id_drug = def_data.id_drug
                           AND ddcs.id_dep_clin_serv IS NULL
                           AND ddcs.flg_type = 'P'
                           AND ddcs.id_institution = i_id_institution
                           AND ddcs.id_software = i_id_software
                           AND ddcs.vers = def_data.vers)
                   AND NOT EXISTS (SELECT 0
                    FROM   drug_dep_clin_serv ddcs
                    WHERE  ddcs.id_drug = def_data.id_drug
                           AND ddcs.vers = def_data.vers
                           AND ddcs.flg_type = 'F'
                           AND ddcs.id_software = i_id_software
                           AND ddcs.id_dep_clin_serv = i_id_dep_clin_serv);
    
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
            pk_types.open_my_cursor(o_serum_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_serum_const_freq;
    /********************************************************************************************
    * Set Most frequent Serum for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_serum_config        Most frequent serum configured id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/21
    ********************************************************************************************/
    FUNCTION set_inst_serum_const_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_serum_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drugid_array table_varchar := table_varchar();
        l_vers_array   table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_serum_const_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         i_id_institution,
                                         i_id_software,
                                         i_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         c_input_internal,
                                         o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_serum_const_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_drugid_array,
                     l_vers_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_drugid_array.count SAVE EXCEPTIONS
                INSERT INTO drug_dep_clin_serv
                    (id_drug_dep_clin_serv,
                     id_drug,
                     id_dep_clin_serv,
                     rank,
                     adw_last_update,
                     flg_type,
                     id_software,
                     vers)
                VALUES
                    (seq_drug_dep_clin_serv.nextval,
                     l_drugid_array(a),
                     i_id_dep_clin_serv,
                     0,
                     SYSDATE,
                     'F',
                     i_id_software,
                     l_vers_array(a))
                RETURNING id_drug_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_serum_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_serum_const_freq;
    /********************************************************************************************
    * Get Most frequent External Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_ext_med_config      Most frequent External medication configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION get_inst_ext_med_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_ext_med_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_diagnosis_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_ext_med_config FOR
            SELECT def_data.emb_id,
                   def_data.vers
            FROM   (SELECT temp_data.rowid,
                           temp_data.emb_id,
                           temp_data.vers,
                           rank() over(PARTITION BY temp_data.emb_id, temp_data.vers ORDER BY temp_data.rowid) records_count
                    FROM   (SELECT ecs.rowid,
                                   nvl((SELECT mm.emb_id
                                       FROM   me_med mm
                                       WHERE  mm.emb_id = ecs.emb_id
                                              AND mm.vers = ecs.vers
                                              AND mm.flg_available = g_flg_available),
                                       0) emb_id,
                                   ecs.vers
                            FROM   alert_default.emb_clin_serv ecs
                            WHERE  ecs.version = i_version
                                   AND ecs.id_software = i_id_software
                                   AND ecs.id_market = i_id_market
                                   AND ecs.flg_type = 'M'
                                   AND ecs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.emb_id != '0') def_data
            WHERE  def_data.records_count = 1
                   AND EXISTS (SELECT 0
                    FROM   emb_dep_clin_serv edcs
                    WHERE  edcs.emb_id = def_data.emb_id
                           AND edcs.id_dep_clin_serv IS NULL
                           AND edcs.id_institution = i_id_institution
                           AND edcs.id_software = i_id_software
                           AND edcs.flg_type = 'P'
                           AND edcs.vers = def_data.vers)
                   AND NOT EXISTS (SELECT 0
                    FROM   emb_dep_clin_serv edcs
                    WHERE  edcs.emb_id = def_data.emb_id
                           AND edcs.id_dietary_drug IS NULL
                           AND edcs.id_manipulated IS NULL
                           AND edcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND edcs.id_software = i_id_software
                           AND edcs.flg_type = 'M'
                           AND edcs.vers = def_data.vers);
    
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
            pk_types.open_my_cursor(o_ext_med_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_ext_med_freq;
    /********************************************************************************************
    * Set Most frequent External Medication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_ext_med_config      Most frequent External medication configurated id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/22
    ********************************************************************************************/
    FUNCTION set_inst_ext_med_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_ext_med_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- collection arrays
        l_embid_array table_varchar := table_varchar();
        l_vers_array  table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_ext_med_freq(i_lang,
                                     i_id_market,
                                     i_version,
                                     i_id_institution,
                                     i_id_software,
                                     i_id_clinical_service,
                                     i_id_dep_clin_serv,
                                     c_input_internal,
                                     o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_ext_med_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_embid_array,
                     l_vers_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_embid_array.count SAVE EXCEPTIONS
                INSERT INTO emb_dep_clin_serv
                    (id_emb_dep_clin_serv,
                     emb_id,
                     id_dep_clin_serv,
                     id_software,
                     flg_type,
                     rank,
                     vers)
                VALUES
                    (seq_emb_dep_clin_serv.nextval,
                     l_embid_array(a),
                     i_id_dep_clin_serv,
                     i_id_software,
                     'M',
                     0,
                     l_vers_array(a))
                RETURNING id_emb_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_ext_med_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
    
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_ext_med_freq;
    /********************************************************************************************
    * Get Most frequent Body Diagrams Layouts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_diaglay_config      Configuration cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMG
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_diag_layout_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_diaglay_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
        g_func_name := upper('get_inst_diag_layout_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_diaglay_config FOR
            SELECT def_data.id_diagram_layout,
                   def_data.flg_type
            FROM   (SELECT def_dlcs.rowid,
                           def_dlcs.id_diagram_layout,
                           def_dlcs.flg_type,
                           rank() over(PARTITION BY def_dlcs.id_diagram_layout, def_dlcs.flg_type ORDER BY def_dlcs.rowid) records_count
                    FROM   alert_default.diag_lay_clin_serv def_dlcs
                    WHERE  def_dlcs.id_software IN (i_id_software,
                                                    g_generic)
                           AND def_dlcs.id_market IN (i_id_market,
                                                      g_generic)
                           AND def_dlcs.version = i_version
                           AND def_dlcs.id_clinical_service IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                 column_value
                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   diag_lay_dep_clin_serv dldcs
                    WHERE  dldcs.id_diagram_layout = def_data.id_diagram_layout
                           AND dldcs.id_software = i_id_software
                           AND dldcs.flg_type = def_data.flg_type
                           AND dldcs.id_dep_clin_serv = i_id_dep_clin_serv);
    
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
            pk_types.open_my_cursor(o_diaglay_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_diag_layout_freq;
    /********************************************************************************************
    * Get Most frequent Body Diagrams Layouts for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_diaglay_config      Configuration cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMG
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_diag_layout_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_diaglay_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- def_data.id_diagnosis, def_data.id_alert_diagnosis, def_data.flg_type
        l_diaglayid_array table_number := table_number();
        l_flgtype_array   table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_diag_layout_freq(i_lang,
                                         i_id_market,
                                         i_version,
                                         i_id_software,
                                         i_id_clinical_service,
                                         i_id_dep_clin_serv,
                                         c_input_internal,
                                         o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_diag_layout_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_diaglayid_array,
                     l_flgtype_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_diaglayid_array.count SAVE EXCEPTIONS
                INSERT INTO diag_lay_dep_clin_serv
                    (id_diag_lay_dep_clin_serv,
                     id_diagram_layout,
                     id_institution,
                     id_software,
                     flg_type,
                     rank,
                     adw_last_update,
                     id_dep_clin_serv)
                VALUES
                    (seq_diag_lay_dep_clin_serv.nextval,
                     l_diaglayid_array(a),
                     i_id_institution,
                     i_id_software,
                     l_flgtype_array(a),
                     0,
                     SYSDATE,
                     i_id_dep_clin_serv)
                RETURNING id_diag_lay_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_diaglay_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_diag_layout_freq;
    /********************************************************************************************
    * Get Most frequent ICNP Compo. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cipe                Most frequent ICNP Compo.
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_icnp_comp_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cipe_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
        g_func_name := upper('get_inst_icnp_comp_freq');
    
        g_error := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_cipe_config FOR
            SELECT def_data.id_composition
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.id_composition,
                           rank() over(PARTITION BY temp_data.id_composition ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT icc.rowid my_rowid,
                                   nvl((SELECT ic1.id_composition
                                       FROM   icnp_composition ic1
                                       WHERE  ic1.id_content = ic.id_content
                                              AND ic1.flg_available = g_flg_available
                                              AND ic1.id_institution = i_id_institution
                                              AND ic1.id_software = i_id_software
                                              AND rownum = 1),
                                       0) id_composition
                            FROM   alert_default.icnp_compo_cs icc
                            INNER  JOIN alert_default.icnp_composition ic
                            ON     (ic.id_composition = icc.id_composition AND ic.id_software = icc.id_software AND
                                   ic.flg_available = g_flg_available)
                            WHERE  icc.id_software = i_id_software
                                   AND icc.id_market = i_id_market
                                   AND icc.version = i_version
                                   AND icc.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_composition != 0) def_data
            WHERE  def_data.frecords_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_compo_dcs icdcs
                    WHERE  icdcs.id_composition = def_data.id_composition
                           AND icdcs.id_dep_clin_serv = i_id_dep_clin_serv);
    
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
            pk_types.open_my_cursor(o_cipe_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_icnp_comp_freq;
    /********************************************************************************************
    * Set Most frequent ICNP Compo. for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cipe                Most frequent ICNP Compo.
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_icnp_comp_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cipe_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- collection arrays
        l_icnpid_array table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_icnp_comp_freq(i_lang,
                                       i_id_market,
                                       i_version,
                                       i_id_institution,
                                       i_id_software,
                                       i_id_clinical_service,
                                       i_id_dep_clin_serv,
                                       c_input_internal,
                                       o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_icnp_comp_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_icnpid_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_icnpid_array.count SAVE EXCEPTIONS
                INSERT INTO icnp_compo_dcs
                    (id_icnp_compo_dcs,
                     id_composition,
                     id_dep_clin_serv)
                VALUES
                    (seq_icnp_comp_dcs.nextval,
                     l_icnpid_array(a),
                     i_id_dep_clin_serv)
                RETURNING id_icnp_compo_dcs BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_cipe_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_icnp_comp_freq;

    /********************************************************************************************
    * Set Most frequent Diagnosis for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_diagnosis_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_diagnosis_freq';
        e_function_call_excep EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
        g_error := 'Invoking CHECK_CLINICAL_SERVICE to retrieve parent''s clinical services of i_id_clinical_service = ' ||
                   to_char(i_id_clinical_service);
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => k_function_name);
    
        IF NOT check_clinical_service(i_lang             => i_lang,
                                      i_clinical_service => i_id_clinical_service,
                                      o_id_cs            => l_cs_array,
                                      o_error            => o_error)
        THEN
            g_error := 'The call to function CHECK_CLINICAL_SERVICE returned an error ';
            alertlog.pk_alertlog.log_error(text            => g_error,
                                           object_name     => g_package_name,
                                           sub_object_name => k_function_name);
            RAISE e_function_call_excep;
        END IF;
    
        g_error := 'Invoking PK_DIAGNOSIS_DEF.SET_INST_DIAGNOSIS_FREQ to insert most-frequent diagnoses';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => k_function_name);
    
        pk_diagnosis_def.set_inst_diagnosis_freq(i_lang          => i_lang,
                                                 i_market        => i_id_market,
                                                 i_version       => i_version,
                                                 i_institution   => i_id_institution,
                                                 i_software      => i_id_software,
                                                 i_lst_clin_serv => l_cs_array,
                                                 i_dep_clin_serv => i_id_dep_clin_serv);
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_diagnosis_def.e_missing_cfg_term_version THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'e_missing_cfg_term_version',
                                              'Verify the setup required in order be able to run the default process for Diagnosis functionality.',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN e_function_call_excep THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 'e_function_call_excep',
                                              i_sqlerrm  => 'A call to a function returned an unexpected error.',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_inst_diagnosis_freq;
    /********************************************************************************************
    * Get Most frequent Dietaries for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_dietary             Most frequent Dietaries configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/16
    ********************************************************************************************/
    FUNCTION get_inst_dietary_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dietary_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_dietary_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
        g_error := 'OPEN DIETARY CONFIGURATION CURSOR';
        OPEN o_dietary_config FOR
            SELECT def_data.qty,
                   def_data.dosage,
                   def_data.id_dietary_drug,
                   def_data.vers
            FROM   (SELECT ROWID,
                           ecs.qty,
                           ecs.dosage,
                           ecs.id_dietary_drug,
                           ecs.flg_type,
                           ecs.vers,
                           ecs.id_software,
                           rank() over(PARTITION BY ecs.id_dietary_drug, ecs.vers, ecs.flg_type ORDER BY ROWID) records_count
                    FROM   alert_default.emb_clin_serv ecs
                    WHERE  ecs.id_clinical_service IN
                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                             column_value
                            FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                           AND ecs.id_dietary_drug IS NOT NULL
                           AND ecs.version = i_version
                           AND ecs.id_market = i_id_market
                           AND ecs.id_software = i_id_software
                           AND EXISTS (SELECT 0
                            FROM   me_dietary md
                            WHERE  md.id_dietary_drug = ecs.id_dietary_drug
                                   AND md.vers = ecs.vers)) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   emb_dep_clin_serv edcs
                    WHERE  edcs.id_dietary_drug = def_data.id_dietary_drug
                           AND edcs.vers = def_data.vers
                           AND edcs.flg_type = 'M'
                           AND edcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND edcs.id_software = i_id_software);
    
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
            pk_types.open_my_cursor(o_dietary_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_dietary_freq;
    /********************************************************************************************
    * Get Most frequent Dietaries for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    DepartmentClinical Service ID
    * @param o_dietary             Most frequent Dietaries configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/16
    ********************************************************************************************/
    FUNCTION set_inst_dietary_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dietary_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- colection arrays internal med
        -- def_data.qty, def_data.dosage, def_data.id_dietary_drug, def_data.flg_type, def_data.vers
        l_qty_array  table_number := table_number();
        l_dosg_array table_number := table_number();
        l_ddid_array table_varchar := table_varchar();
        l_vers_array table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_dietary_freq(i_lang,
                                     i_id_market,
                                     i_version,
                                     i_id_software,
                                     i_id_clinical_service,
                                     i_id_dep_clin_serv,
                                     c_input_internal,
                                     o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_dietary_freq');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_qty_array,
                     l_dosg_array,
                     l_ddid_array,
                     l_vers_array;
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_ddid_array.count SAVE EXCEPTIONS
                INSERT INTO emb_dep_clin_serv
                    (id_emb_dep_clin_serv,
                     qty,
                     dosage,
                     id_dep_clin_serv,
                     rank,
                     id_software,
                     id_dietary_drug,
                     flg_type,
                     vers)
                VALUES
                    (seq_emb_dep_clin_serv.nextval,
                     l_qty_array(a),
                     l_dosg_array(a),
                     i_id_dep_clin_serv,
                     0,
                     i_id_software,
                     l_ddid_array(a),
                     'M',
                     l_vers_array(a))
                RETURNING id_emb_dep_clin_serv BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_dietary_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_dietary_freq;
    /********************************************************************************************
    * Get Most frequent discharges for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_drd_config          Most frequent discharge reason
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/02/15
    ********************************************************************************************/
    FUNCTION get_inst_discharge_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_drd_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_templates_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
        g_error := 'OPEN TEMPLATES CONFIGURATION CURSOR';
        --DISCH_REAS_DEST    
        OPEN o_drd_config FOR
            SELECT def_data.alert_discharge_reason,
                   def_data.alert_discharge_dest,
                   def_data.flg_diag,
                   def_data.report_name,
                   def_data.id_epis_type,
                   def_data.type_screen,
                   def_data.id_reports,
                   def_data.flg_mcdt,
                   def_data.flg_care_stage,
                   def_data.flg_default,
                   def_data.rank,
                   def_data.flg_specify_dest,
                   def_data.flg_rep_notes,
                   def_data.flg_def_disch_status,
                   def_data.id_def_disch_status,
                   def_data.flg_needs_overall_resp
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.alert_discharge_reason,
                           temp_data.alert_discharge_dest,
                           temp_data.flg_diag,
                           temp_data.report_name,
                           temp_data.id_epis_type,
                           temp_data.type_screen,
                           temp_data.id_reports,
                           temp_data.flg_mcdt,
                           temp_data.flg_care_stage,
                           temp_data.flg_default,
                           temp_data.rank,
                           temp_data.flg_specify_dest,
                           temp_data.flg_rep_notes,
                           temp_data.flg_def_disch_status,
                           temp_data.id_def_disch_status,
                           temp_data.flg_needs_overall_resp,
                           row_number() over(PARTITION BY temp_data.id_discharge_reason, temp_data.id_discharge_dest, temp_data.id_software_param ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT drs.rowid my_rowid,
                                   drs.id_discharge_reason,
                                   nvl((SELECT dr.id_discharge_reason
                                       FROM   discharge_reason dr
                                       INNER  JOIN alert_default.discharge_reason dr2
                                       ON     (dr2.id_content = dr.id_content AND dr2.flg_available = g_flg_available)
                                       WHERE  dr2.id_discharge_reason = drs.id_discharge_reason
                                              AND dr.id_content IS NOT NULL
                                              AND dr.flg_available = g_flg_available
                                              AND rownum = 1),
                                       0) alert_discharge_reason,
                                   drs.id_discharge_dest,
                                   decode(drs.id_discharge_dest,
                                          NULL,
                                          NULL,
                                          nvl((SELECT dd.id_discharge_dest
                                              FROM   discharge_dest dd
                                              INNER  JOIN alert_default.discharge_dest dd2
                                              ON     (dd2.id_content = dd.id_content AND
                                                     dd2.flg_available = g_flg_available)
                                              WHERE  dd2.id_discharge_dest = drs.id_discharge_dest
                                                     AND dd.id_content IS NOT NULL
                                                     AND dd.flg_available = g_flg_available
                                                     AND rownum = 1),
                                              0)) alert_discharge_dest,
                                   drs.flg_diag,
                                   drs.id_software_param,
                                   drs.report_name,
                                   drs.id_epis_type,
                                   drs.type_screen,
                                   drs.id_reports,
                                   drs.flg_mcdt,
                                   drs.flg_care_stage,
                                   drs.flg_default,
                                   drs.rank,
                                   drs.flg_specify_dest,
                                   drs.flg_rep_notes,
                                   drs.flg_def_disch_status,
                                   drs.id_def_disch_status,
                                   drs.flg_needs_overall_resp
                            
                            FROM   alert_default.disch_reas_dest drs
                            INNER  JOIN alert_default.discharge_reason_mrk_vrs drmv
                            ON     (drmv.id_discharge_reason = drs.id_discharge_reason AND drmv.id_market = drs.id_market AND
                                   drmv.version = drs.version)
                            INNER  JOIN alert_default.discharge_dest_mrk_vrs ddmv
                            ON     (ddmv.id_discharge_dest = drs.id_discharge_dest AND ddmv.id_market = drs.id_market AND
                                   ddmv.version = drs.version)
                            WHERE  drs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                    FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                   AND drs.id_software_param = i_id_software
                                   AND drs.id_market = i_id_market
                                   AND drs.version = i_version
                                   AND drs.flg_active = 'A') temp_data
                    WHERE  temp_data.alert_discharge_reason != 0
                           AND (temp_data.alert_discharge_dest != 0 OR temp_data.alert_discharge_dest IS NULL)) def_data
            WHERE  def_data.frecords_count = 1
                   AND NOT EXISTS
             (SELECT 0
                    FROM   disch_reas_dest drd
                    WHERE  drd.id_discharge_reason = def_data.alert_discharge_reason
                           AND (drd.id_discharge_dest = def_data.alert_discharge_dest OR
                           (drd.id_discharge_dest IS NULL AND def_data.alert_discharge_dest IS NULL))
                           AND drd.id_dep_clin_serv = i_id_dep_clin_serv
                           AND drd.id_software_param = i_id_software
                           AND drd.id_instit_param = i_id_institution
                           AND drd.flg_active = 'A');
    
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
            pk_types.open_my_cursor(o_drd_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_discharge_freq;
    /********************************************************************************************
    * Get Most frequent discharges for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_drd_config          Most frequent discharge reason
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/02/15
    ********************************************************************************************/
    FUNCTION set_inst_discharge_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_drd_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- colection arrays internal med
        l_id_dischrea_array      table_number := table_number();
        l_id_dischdest_array     table_number := table_number();
        l_id_fdiag_array         table_varchar := table_varchar();
        l_report_name_array      table_varchar := table_varchar();
        l_epis_type_array        table_number := table_number();
        l_type_scr_array         table_varchar := table_varchar();
        l_reports_array          table_number := table_number();
        l_flg_mcdt_array         table_varchar := table_varchar();
        l_care_stage_array       table_varchar := table_varchar();
        l_default_array          table_varchar := table_varchar();
        l_rank_array             table_number := table_number();
        l_spec_dest_array        table_varchar := table_varchar();
        l_rep_notes_array        table_varchar := table_varchar();
        l_flg_disch_status_array table_varchar := table_varchar();
        l_id_disch_status_array  table_number := table_number();
        l_flg_over_resp_array    table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN DISCHARGE CONFIGURATION CURSOR';
        IF NOT get_inst_discharge_freq(i_lang,
                                       i_id_market,
                                       i_version,
                                       i_id_institution,
                                       i_id_software,
                                       i_id_clinical_service,
                                       i_id_dep_clin_serv,
                                       c_input_internal,
                                       o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_discharge_freq');
            g_error     := 'FETCH DISCHARGE CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_id_dischrea_array,
                     l_id_dischdest_array,
                     l_id_fdiag_array,
                     l_report_name_array,
                     l_epis_type_array,
                     l_type_scr_array,
                     l_reports_array,
                     l_flg_mcdt_array,
                     l_care_stage_array,
                     l_default_array,
                     l_rank_array,
                     l_spec_dest_array,
                     l_rep_notes_array,
                     l_flg_disch_status_array,
                     l_id_disch_status_array,
                     l_flg_over_resp_array;
            g_error := 'LOAD DISCHARGE CONFIGURATION';
            FORALL a IN 1 .. l_id_dischrea_array.count SAVE EXCEPTIONS
                INSERT INTO disch_reas_dest
                    (id_disch_reas_dest,
                     id_discharge_reason,
                     id_discharge_dest,
                     id_dep_clin_serv,
                     flg_active,
                     flg_diag,
                     id_institution,
                     id_instit_param,
                     id_software_param,
                     report_name,
                     id_epis_type,
                     type_screen,
                     id_department,
                     id_reports,
                     flg_mcdt,
                     rank,
                     flg_specify_dest,
                     flg_care_stage,
                     flg_default,
                     flg_rep_notes,
                     flg_def_disch_status,
                     id_def_disch_status,
                     flg_needs_overall_resp)
                VALUES
                    (seq_disch_reas_dest.nextval,
                     l_id_dischrea_array(a),
                     l_id_dischdest_array(a),
                     i_id_dep_clin_serv,
                     'A',
                     l_id_fdiag_array(a),
                     NULL,
                     i_id_institution,
                     i_id_software,
                     l_report_name_array(a),
                     l_epis_type_array(a),
                     l_type_scr_array(a),
                     NULL,
                     l_reports_array(a),
                     l_flg_mcdt_array(a),
                     l_rank_array(a),
                     l_spec_dest_array(a),
                     l_care_stage_array(a),
                     l_default_array(a),
                     l_rep_notes_array(a),
                     l_flg_disch_status_array(a),
                     l_id_disch_status_array(a),
                     l_flg_over_resp_array(a))
                RETURNING id_disch_reas_dest BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE DISCHARGE CONFIGURATION CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_drd_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_discharge_freq;
    /********************************************************************************************
    * Get Most frequent templates for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_id_institution      Institution ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_templates           Cursor of templates
    * @param o_profiles            Cursor of profiles
    * @param o_context             Cursor of contexts
    * @param o_flg_types           Cursor of templates flag types
    * @param o_id_sch_event        Cursor of scheduler events
    * @param o_context_2           Cursor of additional contexts
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION get_inst_templates_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_templates_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_templates_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
        g_error := 'OPEN TEMPLATES CONFIGURATION CURSOR';
        OPEN o_templates_config FOR
            SELECT f_data.id_doc_template,
                   f_data.id_profile_template,
                   f_data.id_context,
                   f_data.flg_type,
                   f_data.id_sch_event,
                   f_data.id_context_2
            FROM   (SELECT def_data.x_row,
                           def_data.id_doc_template,
                           def_data.id_profile_template,
                           def_data.id_context,
                           def_data.flg_type,
                           def_data.id_sch_event,
                           def_data.id_context_2,
                           rank() over(PARTITION BY def_data.id_doc_template, def_data.id_profile_template, def_data.id_context, def_data.flg_type, def_data.id_sch_event, def_data.id_context_2 ORDER BY def_data.x_row) frecords_count
                    FROM   (SELECT temp_data.rowid x_row,
                                   temp_data.id_doc_template,
                                   temp_data.id_profile_template,
                                   temp_data.id_context,
                                   temp_data.flg_type,
                                   temp_data.id_sch_event,
                                   temp_data.id_context_2
                            FROM   (SELECT dtc.rowid,
                                           dtc.id_doc_template,
                                           dtc.id_profile_template,
                                           dtc.id_software,
                                           nvl((SELECT cs.id_clinical_service
                                               FROM   clinical_service cs
                                               WHERE  cs.id_content =
                                                      (SELECT cs2.id_content
                                                       FROM   alert_default.clinical_service cs2
                                                       WHERE  cs2.id_clinical_service = i_id_clinical_service)
                                                      AND cs.id_content IS NOT NULL
                                                      AND cs.flg_available = 'Y'
                                                      AND rownum = 1),
                                               0) id_context,
                                           dtc.flg_type,
                                           dtc.id_sch_event,
                                           dtc.id_context_2,
                                           rank() over(PARTITION BY dtc.id_doc_template, dtc.id_profile_template, dtc.id_context, dtc.flg_type, dtc.id_sch_event, dtc.id_context_2 ORDER BY dtc.rowid) records_count
                                    FROM   alert_default.doc_template_context dtc
                                    WHERE  dtc.id_software = i_id_software
                                           AND dtc.id_clinical_service IN
                                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                 column_value
                                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                           AND dtc.id_market = i_id_market
                                           AND dtc.version = i_version
                                           AND dtc.flg_type IN ('A',
                                                                'S')) temp_data
                            WHERE  temp_data.id_context != 0
                                   AND temp_data.records_count = 1
                                   AND NOT EXISTS
                             (SELECT 0
                                    FROM   doc_template_context alert_dtc
                                    WHERE  alert_dtc.id_doc_template = temp_data.id_doc_template
                                           AND alert_dtc.id_institution = i_id_institution
                                           AND alert_dtc.id_software = temp_data.id_software
                                           AND alert_dtc.id_context = temp_data.id_context
                                           AND alert_dtc.flg_type = temp_data.flg_type
                                           AND (alert_dtc.id_context_2 = temp_data.id_context_2 OR
                                           (alert_dtc.id_context_2 IS NULL AND temp_data.id_context_2 IS NULL))
                                           AND (alert_dtc.id_profile_template = temp_data.id_profile_template OR
                                           (alert_dtc.id_profile_template IS NULL AND
                                           temp_data.id_profile_template IS NULL))
                                           AND (alert_dtc.id_sch_event = temp_data.id_sch_event OR
                                           (alert_dtc.id_sch_event IS NULL AND temp_data.id_sch_event IS NULL)))
                            UNION ALL
                            -- DA, DS
                            SELECT temp_data.rowid,
                                   temp_data.id_doc_template,
                                   temp_data.id_profile_template,
                                   temp_data.id_context,
                                   temp_data.flg_type,
                                   temp_data.id_sch_event,
                                   temp_data.id_context_2
                            FROM   (SELECT dtc.rowid,
                                           dtc.id_doc_template,
                                           dtc.id_profile_template,
                                           dtc.id_software,
                                           dtc.id_context,
                                           dtc.flg_type,
                                           dtc.id_sch_event,
                                           nvl((SELECT cs.id_clinical_service
                                               FROM   clinical_service cs
                                               WHERE  cs.id_content =
                                                      (SELECT cs2.id_content
                                                       FROM   alert_default.clinical_service cs2
                                                       WHERE  cs2.id_clinical_service = i_id_clinical_service)
                                                      AND cs.id_content IS NOT NULL
                                                      AND cs.flg_available = 'Y'
                                                      AND rownum = 1),
                                               0) id_context_2,
                                           rank() over(PARTITION BY dtc.id_doc_template, dtc.id_profile_template, dtc.id_context, dtc.flg_type, dtc.id_sch_event, dtc.id_context_2 ORDER BY dtc.rowid) records_count
                                    FROM   alert_default.doc_template_context dtc
                                    WHERE  dtc.id_software = i_id_software
                                           AND dtc.id_clinical_service IN
                                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                 column_value
                                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                           AND dtc.id_market = i_id_market
                                           AND dtc.version = i_version
                                           AND dtc.flg_type IN ('DA',
                                                                'DS')) temp_data
                            WHERE  temp_data.id_context_2 != 0
                                   AND temp_data.records_count = 1
                                   AND NOT EXISTS
                             (SELECT 0
                                    FROM   doc_template_context alert_dtc
                                    WHERE  alert_dtc.id_doc_template = temp_data.id_doc_template
                                           AND alert_dtc.id_institution = i_id_institution
                                           AND alert_dtc.id_software = temp_data.id_software
                                           AND alert_dtc.id_context = temp_data.id_context
                                           AND alert_dtc.flg_type = temp_data.flg_type
                                           AND (alert_dtc.id_context_2 = temp_data.id_context_2 OR
                                           (alert_dtc.id_context_2 IS NULL AND temp_data.id_context_2 IS NULL))
                                           AND (alert_dtc.id_profile_template = temp_data.id_profile_template OR
                                           (alert_dtc.id_profile_template IS NULL AND
                                           temp_data.id_profile_template IS NULL))
                                           AND (alert_dtc.id_sch_event = temp_data.id_sch_event OR
                                           (alert_dtc.id_sch_event IS NULL AND temp_data.id_sch_event IS NULL)))
                            UNION ALL
                            -- SD
                            SELECT temp_data.rowid,
                                   temp_data.id_doc_template,
                                   temp_data.id_profile_template,
                                   temp_data.id_context,
                                   temp_data.flg_type,
                                   temp_data.id_sch_event,
                                   temp_data.id_context_2
                            FROM   (SELECT dtc.rowid,
                                           dtc.id_doc_template,
                                           dtc.id_profile_template,
                                           dtc.id_software,
                                           NULL id_context,
                                           dtc.flg_type,
                                           dtc.id_sch_event,
                                           dtc.id_context_2,
                                           rank() over(PARTITION BY dtc.id_doc_template, dtc.id_profile_template, dtc.id_context, dtc.flg_type, dtc.id_sch_event, dtc.id_context_2 ORDER BY dtc.rowid) records_count
                                    FROM   alert_default.doc_template_context dtc
                                    WHERE  dtc.id_software = i_id_software
                                           AND dtc.id_clinical_service IN
                                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                 column_value
                                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                           AND dtc.id_market = i_id_market
                                           AND dtc.version = i_version
                                           AND dtc.flg_type = 'SD') temp_data
                            WHERE  temp_data.records_count = 1
                                   AND NOT EXISTS
                             (SELECT 0
                                    FROM   doc_template_context alert_dtc
                                    WHERE  alert_dtc.id_doc_template = temp_data.id_doc_template
                                           AND alert_dtc.id_institution = i_id_institution
                                           AND alert_dtc.id_software = temp_data.id_software
                                           AND (alert_dtc.id_context = temp_data.id_context OR
                                           (alert_dtc.id_context IS NULL AND temp_data.id_context IS NULL))
                                           AND alert_dtc.flg_type = temp_data.flg_type
                                           AND alert_dtc.id_dep_clin_serv = i_id_dep_clin_serv
                                           AND (alert_dtc.id_context_2 = temp_data.id_context_2 OR
                                           (alert_dtc.id_context_2 IS NULL AND temp_data.id_context_2 IS NULL))
                                           AND (alert_dtc.id_profile_template = temp_data.id_profile_template OR
                                           (alert_dtc.id_profile_template IS NULL AND
                                           temp_data.id_profile_template IS NULL))
                                           AND (alert_dtc.id_sch_event = temp_data.id_sch_event OR
                                           (alert_dtc.id_sch_event IS NULL AND temp_data.id_sch_event IS NULL)))
                            UNION ALL
                            -- CT
                            SELECT temp_data.rowid,
                                   temp_data.id_doc_template,
                                   temp_data.id_profile_template,
                                   temp_data.id_context,
                                   temp_data.flg_type,
                                   temp_data.id_sch_event,
                                   temp_data.id_context_2
                            FROM   (SELECT dtc.rowid,
                                           dtc.id_doc_template,
                                           dtc.id_profile_template,
                                           dtc.id_software,
                                           dtc.id_context,
                                           dtc.flg_type,
                                           dtc.id_sch_event,
                                           dtc.id_context_2,
                                           rank() over(PARTITION BY dtc.id_doc_template, dtc.id_profile_template, dtc.id_context, dtc.flg_type, dtc.id_sch_event, dtc.id_context_2 ORDER BY dtc.rowid) records_count
                                    FROM   alert_default.doc_template_context dtc
                                    WHERE  dtc.id_software = i_id_software
                                           AND dtc.id_clinical_service IN
                                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                 column_value
                                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                           AND dtc.id_market = i_id_market
                                           AND dtc.version = i_version
                                           AND dtc.flg_type = 'CT') temp_data
                            WHERE  temp_data.records_count = 1
                                   AND NOT EXISTS
                             (SELECT 0
                                    FROM   doc_template_context dtc
                                    WHERE  dtc.id_doc_template = temp_data.id_doc_template
                                           AND dtc.id_institution = i_id_institution
                                           AND dtc.id_software = temp_data.id_software
                                           AND dtc.id_context = temp_data.id_context
                                           AND dtc.flg_type = temp_data.flg_type
                                           AND dtc.id_dep_clin_serv = i_id_dep_clin_serv
                                           AND (dtc.id_context_2 = temp_data.id_context_2 OR
                                           (dtc.id_context_2 IS NULL AND temp_data.id_context_2 IS NULL))
                                           AND
                                           (dtc.id_profile_template = temp_data.id_profile_template OR
                                           (dtc.id_profile_template IS NULL AND temp_data.id_profile_template IS NULL))
                                           AND (dtc.id_sch_event = temp_data.id_sch_event OR
                                           (dtc.id_sch_event IS NULL AND temp_data.id_sch_event IS NULL)))) def_data) f_data
            WHERE  f_data.frecords_count = 1;
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
            pk_types.open_my_cursor(o_templates_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_templates_freq;
    /********************************************************************************************
    * Get Most frequent templates for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_id_institution      Institution ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_templates           Cursor of templates
    * @param o_profiles            Cursor of profiles
    * @param o_context             Cursor of contexts
    * @param o_flg_types           Cursor of templates flag types
    * @param o_id_sch_event        Cursor of scheduler events
    * @param o_context_2           Cursor of additional contexts
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_templates_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_templates_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- colection arrays internal med
        l_id_doctempl_array  table_varchar := table_varchar();
        l_id_proftempl_array table_number := table_number();
        l_id_context_array   table_number := table_number();
        l_id_ftype_array     table_varchar := table_varchar();
        l_id_sche_array      table_number := table_number();
        l_id_context2_array  table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'GET DEFAULT CONFIGURATION';
        IF NOT get_inst_templates_freq(i_lang,
                                       i_id_market,
                                       i_id_institution,
                                       i_version,
                                       i_id_software,
                                       i_id_clinical_service,
                                       i_id_dep_clin_serv,
                                       c_input_internal,
                                       o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_templates_freq');
            g_error     := 'FETCH DEFAULT CONFIGURATION';
            FETCH c_input_internal BULK COLLECT
                INTO l_id_doctempl_array,
                     l_id_proftempl_array,
                     l_id_context_array,
                     l_id_ftype_array,
                     l_id_sche_array,
                     l_id_context2_array;
            g_error := 'LOAD DEFAULT CONFIGURATION';
            FORALL a IN 1 .. l_id_doctempl_array.count SAVE EXCEPTIONS
                INSERT INTO doc_template_context
                    (id_doc_template_context,
                     id_doc_template,
                     id_institution,
                     id_software,
                     id_profile_template,
                     id_dep_clin_serv,
                     adw_last_update,
                     id_context,
                     flg_type,
                     id_sch_event,
                     id_context_2)
                VALUES
                    (seq_doc_template_context.nextval,
                     l_id_doctempl_array(a),
                     i_id_institution,
                     i_id_software,
                     l_id_proftempl_array(a),
                     i_id_dep_clin_serv,
                     SYSDATE,
                     l_id_context_array(a),
                     l_id_ftype_array(a),
                     l_id_sche_array(a),
                     l_id_context2_array(a))
                RETURNING id_doc_template_context BULK COLLECT INTO l_aux1;
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN TRANSFER OPTION DEFAULT IDS CONFIGURED';
        OPEN o_templates_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_templates_freq;
    /********************************************************************************************
    * Get Most frequent transfer option for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_transfer_option     list of content and properties to be configured in Alert tables
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/13
    ********************************************************************************************/
    FUNCTION get_inst_transfer_option_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        o_transfer_option OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
        g_func_name := upper('get_inst_transfer_option_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
        g_error := 'OPEN TRANSFER OPTION DEFAULT CONFIGURATION';
        OPEN o_transfer_option FOR
            SELECT def_data.alert_topt
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.alert_topt,
                           rank() over(PARTITION BY temp_data.alert_topt ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT tocs.rowid my_rowid,
                                   nvl((SELECT topt1.id_transfer_option
                                       FROM   transfer_option topt1
                                       WHERE  topt1.id_content = topt.id_content
                                              AND topt1.id_content IS NOT NULL
                                              AND rownum = 1),
                                       0) alert_topt
                            FROM   alert_default.transfer_opt_clin_serv tocs
                            INNER  JOIN alert_default.transfer_option topt
                            ON     (topt.id_transfer_option = tocs.id_transfer_option)
                            INNER  JOIN alert_default.transfer_option_mrk_vrs tomv
                            ON     (tomv.id_transfer_option = tocs.id_transfer_option AND tomv.id_market = i_id_market AND
                                   tomv.version = i_version)
                            WHERE  tocs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                    FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                   AND topt.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.alert_topt != 0) def_data
            WHERE  def_data.frecords_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   transfer_opt_dcs tod
                    WHERE  tod.id_dep_clin_serv = i_id_dep_clin_serv
                           AND tod.id_transfer_option = def_data.alert_topt);
    
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
            pk_types.open_my_cursor(o_transfer_option);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_transfer_option_freq;
    /********************************************************************************************
    *  Set Most frequent transfer option for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_transfer_option_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- colection arrays internal med
        l_alert_id_array table_number := table_number();
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'GET TRANSFER OPTION DEFAULT CONFIGURATION';
        IF NOT get_inst_transfer_option_freq(i_lang,
                                             i_id_market,
                                             i_version,
                                             i_id_clinical_service,
                                             i_id_dep_clin_serv,
                                             c_input_internal,
                                             o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_transfer_option_freq');
            g_error     := 'FETCH TRANSFER OPTION DEFAULT CONFIGURATION';
            FETCH c_input_internal BULK COLLECT
                INTO l_alert_id_array;
            g_error := 'LOAD TRANSFER OPTION DEFAULT CONFIGURATION INTO ALERT';
            FORALL a IN 1 .. l_alert_id_array.count SAVE EXCEPTIONS
                INSERT INTO transfer_opt_dcs
                    (id_transfer_option,
                     id_dep_clin_serv)
                VALUES
                    (l_alert_id_array(a),
                     i_id_dep_clin_serv)
                RETURNING id_transfer_option BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE TRANSFER OPTION DEFAULT CONFIGURATION';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN TRANSFER OPTION DEFAULT IDS CONFIGURED';
        OPEN o_sr_interv FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_transfer_option_freq;
    /********************************************************************************************
    * Get Most frequent sr_interv for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION get_inst_sr_interv_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_sr_interv_freq');
        g_error     := 'GET CS STRUCTURE ';
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE ';
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN c_sr_interv_id_content';
        OPEN o_sr_interv FOR
            SELECT def_data.flg_type,
                   def_data.rank,
                   def_data.alert_id
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.flg_type,
                           temp_data.rank,
                           temp_data.alert_id,
                           rank() over(PARTITION BY temp_data.alert_id, temp_data.flg_type ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT srcs.rowid my_rowid,
                                   srcs.flg_type,
                                   NULL rank,
                                   nvl((SELECT a_sri.id_intervention
                                       FROM   intervention a_sri
                                       WHERE  a_sri.id_content = sri.id_content
                                              AND a_sri.id_content IS NOT NULL
                                              AND a_sri.flg_status = 'A'
                                              AND rownum = 1),
                                       0) AS alert_id
                            FROM   alert_default.interv_clin_serv srcs
                            INNER  JOIN alert_default.intervention sri
                            ON     (sri.id_intervention = srcs.id_intervention)
                            INNER  JOIN alert_default.interv_mrk_vrs srimv
                            ON     (srimv.id_intervention = sri.id_intervention AND srimv.id_market = i_id_market AND
                                   srimv.version = i_version)
                            WHERE  srcs.id_software = i_id_software
                                   AND srcs.flg_type = 'M'
                                   AND srcs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.alert_id != 0) def_data
            WHERE  def_data.frecords_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   interv_dep_clin_serv sridcs
                    WHERE  sridcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND sridcs.id_intervention = def_data.alert_id
                           AND sridcs.flg_type = 'M'
                           AND sridcs.id_software = i_id_software);
    
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
            pk_types.open_my_cursor(o_sr_interv);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_sr_interv_freq;
    /********************************************************************************************
    *  Most frequent sr_interv for a specific Dep_clin_serv configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Default Clinical Service ID
    * @param i_id_dep_clin_serv    Alert Department/Clinical Service ID
    * @param o_sr_interv           Cursor with Default Configuration records
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_sr_interv_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sr_interv OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- colection arrays internal med
        l_flg_type_array table_varchar := table_varchar();
        l_rank_array     table_number := table_number();
        l_alert_id_array table_number := table_number();
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'GET DEFAULT CONFIGURATIONS';
        IF NOT get_inst_sr_interv_freq(i_lang,
                                       i_id_market,
                                       i_version,
                                       i_id_software,
                                       i_id_clinical_service,
                                       i_id_dep_clin_serv,
                                       c_input_internal,
                                       o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_sr_interv_freq');
            g_error     := 'FETCH DEFAULT CONFIGURATIONS';
            FETCH c_input_internal BULK COLLECT
                INTO l_flg_type_array,
                     l_rank_array,
                     l_alert_id_array;
            g_error := 'LOAD DEFAULT CONFIGURATIONS';
            FORALL a IN 1 .. l_alert_id_array.count SAVE EXCEPTIONS
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_institution,
                     id_dep_clin_serv,
                     id_intervention,
                     flg_type,
                     id_software,
                     rank,
                     adw_last_update)
                VALUES
                    (seq_interv_dep_clin_serv.nextval,
                     i_id_institution,
                     i_id_dep_clin_serv,
                     l_alert_id_array(a),
                     l_flg_type_array(a),
                     i_id_software,
                     l_rank_array(a),
                     SYSDATE)
                RETURNING id_interv_dep_clin_serv BULK COLLECT INTO l_aux1;
        
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        OPEN o_sr_interv FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_sr_interv_freq;
    /********************************************************************************************
    * Get Frequent Reported Medication for markets, versions and softwares
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Default id Clinical Service
    * @param i_id_dep_clin_serv    Destination id_dep_clin_Serv
    * @param o_internal_config     Cursor of internal medication records
    * @param o_external_config     Cursor of external medication records
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION get_inst_pml_dcs_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_internal_config OUT pk_types.cursor_type,
        o_external_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_pml_dcs_freq');
        g_error     := 'GET CS STRUCTURE ';
        IF NOT check_clinical_service(i_lang,
                                      i_id_clinical_service,
                                      l_cs_array,
                                      o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE ';
            RAISE l_exception;
        END IF;
    
        g_error := 'I -COLECTING CONFIGURATIONS ' || i_id_institution || ', ' || i_id_software || ', ' ||
                   i_id_clinical_service;
        OPEN o_internal_config FOR
            SELECT def_data.vers,
                   def_data.flg_med_type,
                   def_data.flg_type,
                   def_data.alert_drug_id
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.vers,
                           temp_data.flg_med_type,
                           temp_data.flg_type,
                           temp_data.alert_drug_id,
                           rank() over(PARTITION BY temp_data.vers, temp_data.alert_drug_id, temp_data.flg_type, temp_data.flg_med_type ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT pdcs.rowid my_rowid,
                                   pdcs.vers,
                                   pdcs.flg_med_type,
                                   pdcs.flg_type,
                                   nvl((SELECT mm.id_drug
                                       FROM   mi_med mm
                                       WHERE  mm.id_drug = pdcs.med_id
                                              AND mm.flg_available = g_flg_available
                                              AND mm.vers = pdcs.vers),
                                       '0') alert_drug_id
                            FROM   alert_default.pml_clin_serv pdcs
                            WHERE  pdcs.flg_type = 'M'
                                   AND pdcs.flg_med_type = 'I'
                                   AND pdcs.id_software = i_id_software
                                   AND pdcs.id_market = i_market
                                   AND pdcs.version = i_version
                                   AND pdcs.id_clin_serv IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.alert_drug_id != '0') def_data
            WHERE  def_data.frecords_count = 1
                   AND EXISTS (SELECT 0
                    FROM   drug_dep_clin_serv ddcs
                    WHERE  ddcs.id_drug = def_data.alert_drug_id
                           AND ddcs.id_dep_clin_serv IS NULL
                           AND ddcs.flg_type = 'P'
                           AND ddcs.id_institution = i_id_institution
                           AND ddcs.id_software = i_id_software
                           AND ddcs.vers = def_data.vers)
                   AND NOT EXISTS (SELECT 0
                    FROM   pml_dep_clin_serv pdcs
                    WHERE  pdcs.med_id = def_data.alert_drug_id
                           AND pdcs.vers = def_data.vers
                           AND pdcs.flg_type = def_data.flg_type
                           AND pdcs.flg_med_type = def_data.flg_med_type
                           AND pdcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND pdcs.id_institution = i_id_institution);
        g_error := 'E - COLECTING CONFIGURATIONS ' || i_id_institution || ', ' || i_id_software || ', ' ||
                   i_id_clinical_service;
        OPEN o_external_config FOR
            SELECT def_data.vers,
                   def_data.flg_med_type,
                   def_data.flg_type,
                   def_data.alert_drug_id
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.vers,
                           temp_data.flg_med_type,
                           temp_data.flg_type,
                           temp_data.alert_drug_id,
                           rank() over(PARTITION BY temp_data.vers, temp_data.alert_drug_id, temp_data.flg_type, temp_data.flg_med_type ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT pdcs.rowid        my_rowid,
                                   pdcs.vers,
                                   pdcs.flg_med_type,
                                   pdcs.flg_type,
                                   pdcs.med_id       alert_drug_id
                            FROM   alert_default.pml_clin_serv pdcs
                            WHERE  pdcs.flg_type = 'M'
                                   AND pdcs.flg_med_type = 'E'
                                   AND pdcs.id_software = i_id_software
                                   AND pdcs.id_clin_serv = i_id_clinical_service
                                   AND pdcs.id_market = i_market
                                   AND pdcs.version = i_version
                                   AND pdcs.id_clin_serv IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                   AND EXISTS (SELECT 0
                                    FROM   me_med mm
                                    WHERE  mm.med_id = pdcs.med_id
                                           AND mm.vers = pdcs.vers
                                           AND mm.flg_available = g_flg_available)) temp_data
                    WHERE  temp_data.alert_drug_id != '0') def_data
            WHERE  def_data.frecords_count = 1
                   AND EXISTS
             (SELECT 0
                    FROM   emb_dep_clin_serv edcs
                    JOIN   me_med med
                    ON     (med.emb_id = edcs.emb_id AND med.vers = edcs.vers AND med.flg_available = g_flg_available)
                    WHERE  edcs.id_dep_clin_serv IS NULL
                           AND edcs.flg_type = 'P'
                           AND edcs.id_institution = i_id_institution
                           AND edcs.id_software = i_id_software
                           AND edcs.vers = def_data.vers
                           AND med.med_id = def_data.alert_drug_id)
                   AND NOT EXISTS (SELECT 0
                    FROM   pml_dep_clin_serv pdcs
                    WHERE  pdcs.med_id = def_data.alert_drug_id
                           AND pdcs.vers = def_data.vers
                           AND pdcs.flg_type = def_data.flg_type
                           AND pdcs.flg_med_type = def_data.flg_med_type
                           AND pdcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND pdcs.id_institution = i_id_institution);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'AAA',
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
                                              'AAA',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_inst_pml_dcs_freq;
    /********************************************************************************************
    * Set Frequent Reported Medication for Dep_clin_serv in Institution
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Default id Clinical Service
    * @param i_id_dep_clin_serv    Destination id_dep_clin_Serv
    * @param o_results_pml         Cursor of configurations ids made
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2012/02/08
    ********************************************************************************************/
    FUNCTION set_inst_pml_dcs_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_results_pml OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- colection arrays internal med
        l_med_id_array           table_varchar := table_varchar();
        l_vers_array             table_varchar := table_varchar();
        l_pml_flg_med_type_array table_varchar := table_varchar();
        l_pml_flg_type_array     table_varchar := table_varchar();
        -- colection arrays external med
        l_med_id_array_ext           table_varchar := table_varchar();
        l_vers_array_ext             table_varchar := table_varchar();
        l_pml_flg_med_type_array_ext table_varchar := table_varchar();
        l_pml_flg_type_array_ext     table_varchar := table_varchar();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        c_input_external pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        l_aux2           table_varchar := table_varchar();
        l_auxf           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
    BEGIN
        g_table_name := upper('pml_dep_clin_serv');
    
        g_error := 'GET CONFIGURATION FROM REPOSITORY';
        IF NOT get_inst_pml_dcs_freq(i_lang,
                                     i_market,
                                     i_version,
                                     i_id_institution,
                                     i_id_software,
                                     i_id_clinical_service,
                                     i_id_dep_clin_serv,
                                     c_input_internal,
                                     c_input_external,
                                     o_error)
        THEN
            g_error := 'ERROR GETTING CONFIGURATION FROM REPOSITORY';
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_pml_dcs_freq');
            -- internal medication configuration
            g_error := 'LOAD ARRAYS INTERNAL MEDS';
            FETCH c_input_internal BULK COLLECT
                INTO l_vers_array,
                     l_pml_flg_med_type_array,
                     l_pml_flg_type_array,
                     l_med_id_array;
        
            g_error := 'INSERT ' || g_table_name || ' WITH FORALL';
            FORALL a IN 1 .. l_med_id_array.count SAVE EXCEPTIONS
                INSERT INTO pml_dep_clin_serv
                    (id_dep_clin_serv,
                     id_software,
                     id_institution,
                     med_id,
                     vers,
                     flg_med_type,
                     flg_type)
                VALUES
                    (i_id_dep_clin_serv,
                     i_id_software,
                     i_id_institution,
                     l_med_id_array(a),
                     l_vers_array(a),
                     l_pml_flg_med_type_array(a),
                     l_pml_flg_type_array(a))
                RETURNING med_id BULK COLLECT INTO l_aux1;
            g_error := 'CLOSE INTERNAL CURSOR';
            CLOSE c_input_internal;
            -- external medication configuration
            g_error := 'LOAD ARRAYS EXTERNAL MEDS';
            FETCH c_input_external BULK COLLECT
                INTO l_vers_array_ext,
                     l_pml_flg_med_type_array_ext,
                     l_pml_flg_type_array_ext,
                     l_med_id_array_ext;
        
            g_error := 'INSERT ' || g_table_name || ' WITH FORALL';
            FORALL a IN 1 .. l_med_id_array_ext.count SAVE EXCEPTIONS
                INSERT INTO pml_dep_clin_serv
                    (id_dep_clin_serv,
                     id_software,
                     id_institution,
                     med_id,
                     vers,
                     flg_med_type,
                     flg_type)
                VALUES
                    (i_id_dep_clin_serv,
                     i_id_software,
                     i_id_institution,
                     l_med_id_array_ext(a),
                     l_vers_array_ext(a),
                     l_pml_flg_med_type_array_ext(a),
                     l_pml_flg_type_array_ext(a))
                RETURNING med_id BULK COLLECT INTO l_aux2;
            g_error := 'CLOSE INTERNAL CURSOR';
            CLOSE c_input_external;
        
        END IF;
    
        l_auxf := l_aux1 MULTISET UNION l_aux2;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        OPEN o_results_pml FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_pml_dcs_freq;

    /********************************************************************************************
    * GET_INST_ICNP_AXIS_CS by ICNP_COMPOSITION previously inserted
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_icnp_axis           outpup configuration
    * @param o_error               error identifier
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION get_inst_icnp_axis_cs
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_icnp_axis OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        --ICNP_VERSION
        l_icnp_version   sys_config.id_sys_config%TYPE := 'ICNP_VERSION';
        l_active_version sys_config.value%TYPE;
    
    BEGIN
        g_func_name      := upper('get_inst_icnp_axis_cs');
        l_active_version := pk_sysconfig.get_config(l_icnp_version,
                                                    i_id_institution,
                                                    i_id_software);
        g_error          := 'OPEN CONFIGURATION CURSOR';
        OPEN o_icnp_axis FOR
            SELECT def_data.id_axis,
                   def_data.id_term
            FROM   (SELECT it.rowid,
                           it.id_axis,
                           it.id_term,
                           rank() over(PARTITION BY it.id_axis, it.id_term ORDER BY it.rowid) records_count
                    FROM   icnp_term it
                    INNER  JOIN icnp_axis ia
                    ON     (ia.id_axis = it.id_axis AND ia.id_icnp_version = l_active_version)
                    WHERE  it.flg_available = g_flg_available) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_axis_dcs iad
                    WHERE  iad.id_term = def_data.id_term
                           AND iad.id_dep_clin_serv = i_id_dep_clin_serv
                           AND iad.id_software = i_id_software
                           AND iad.id_institution = i_id_institution
                           AND iad.id_axis = def_data.id_axis);
    
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
            pk_types.open_my_cursor(o_icnp_axis);
            pk_alert_exceptions.reset_error_state;
    END get_inst_icnp_axis_cs;
    /********************************************************************************************
    * SET_INST_ICNP_AXIS_CS by ICNP_COMPOSITION previously inserted
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/02/20
    ********************************************************************************************/
    FUNCTION set_inst_icnp_axis_cs
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_icnp_axis OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- support arrays
        l_data_id_axis table_number := table_number();
        l_data_id_term table_number := table_number();
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_varchar := table_varchar();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_icnp_axis_cs(i_lang,
                                     i_id_institution,
                                     i_id_software,
                                     i_id_dep_clin_serv,
                                     c_input_internal,
                                     o_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_icnp_axis_cs');
            g_error     := 'FETCH CONFIGURATION CURSOR';
            FETCH c_input_internal BULK COLLECT
                INTO l_data_id_axis,
                     l_data_id_term;
        
            g_error := 'LOAD CONFIGURATIONS';
            FORALL a IN 1 .. l_data_id_axis.count SAVE EXCEPTIONS
                INSERT INTO icnp_axis_dcs
                    (id_icnp_axis_dcs,
                     id_axis,
                     id_term,
                     id_composition,
                     id_dep_clin_serv,
                     id_software,
                     id_institution)
                VALUES
                    (seq_icnp_axis_dcs.nextval,
                     l_data_id_axis(a),
                     l_data_id_term(a),
                     NULL,
                     i_id_dep_clin_serv,
                     i_id_software,
                     i_id_institution)
                RETURNING id_icnp_axis_dcs BULK COLLECT INTO l_aux1;
        
            g_error := 'CLOSE CURSOR';
            CLOSE c_input_internal;
        END IF;
        pk_alertlog.log_info(l_aux1.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_icnp_axis FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_varchar));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        
    END set_inst_icnp_axis_cs;
    /********************************************************************************************
    * Get Most frequent Body Structures for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Body Structures Configuration Details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/05/22
    ********************************************************************************************/
    FUNCTION get_inst_body_structure_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_bsdcs_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_body_structure_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
    
        OPEN o_bsdcs_config FOR
            SELECT def_data.id_body_structure,
                   def_data.flg_default
            FROM   (SELECT temp_data.l_row,
                           temp_data.id_body_structure,
                           temp_data.flg_default,
                           rank() over(PARTITION BY temp_data.id_body_structure, temp_data.flg_default ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT bsc.rowid l_row,
                                   nvl((SELECT alert_bs.id_body_structure
                                       FROM   body_structure alert_bs
                                       WHERE  alert_bs.flg_available = g_flg_available
                                              AND alert_bs.id_content = bs.id_content),
                                       0) id_body_structure,
                                   bsc.flg_default
                            FROM   alert_default.body_structure_cs bsc
                            JOIN   alert_default.body_structure bs
                            ON     (bs.id_body_structure = bsc.id_body_structure AND bs.flg_available = g_flg_available)
                            JOIN   alert_default.body_structure_mrk_vrs bsmv
                            ON     (bsmv.id_body_structure = bs.id_body_structure AND bsmv.id_market = i_id_market AND
                                   bsmv.version = i_version)
                            JOIN   alert_default.clinical_service cs
                            ON     (cs.id_clinical_service = bsc.id_clinical_service AND
                                   cs.flg_available = g_flg_available)
                            WHERE  bsc.flg_available = g_flg_available
                                   AND bsc.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_body_structure != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   body_structure_dcs bsdcs
                    WHERE  bsdcs.id_body_structure = def_data.id_body_structure
                           AND bsdcs.id_dep_clin_serv = i_id_dep_clin_serv
                           AND bsdcs.id_institution = i_id_institution
                           AND bsdcs.flg_available = g_flg_available
                           AND bsdcs.flg_default = def_data.flg_default);
    
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
            pk_types.open_my_cursor(o_bsdcs_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_body_structure_freq;
    /********************************************************************************************
    * Set Most frequent Body Structures for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Body Structures Configuration Id's
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/05/22
    ********************************************************************************************/
    FUNCTION set_inst_body_structure_freq
    (
        i_lang IN language.id_language%TYPE,
        i_id_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_bsdcs_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- labs
        l_bsid_array   table_number := table_number();
        l_flgdef_array table_varchar := table_varchar();
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_number := table_number();
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    BEGIN
        g_error := 'OPEN CONFIGURATION CURSOR';
        IF NOT get_inst_body_structure_freq(i_lang,
                                            i_id_market,
                                            i_version,
                                            i_id_institution,
                                            i_id_software,
                                            i_id_clinical_service,
                                            i_id_dep_clin_serv,
                                            c_input_internal,
                                            o_error)
        THEN
            RAISE l_exception;
        ELSE
            LOOP
                g_func_name := upper('set_inst_body_structure_freq');
                g_error     := 'FETCH CONFIGURATION CURSOR';
                FETCH c_input_internal BULK COLLECT
                    INTO l_bsid_array,
                         l_flgdef_array LIMIT g_array_size1;
                g_error := 'LOAD CONFIGURATIONS';
                FORALL a IN 1 .. l_bsid_array.count SAVE EXCEPTIONS
                    INSERT INTO body_structure_dcs
                        (id_body_structure_dcs,
                         id_body_structure,
                         id_dep_clin_serv,
                         id_institution,
                         flg_default,
                         flg_available)
                    VALUES
                        (seq_body_structure_dcs.nextval,
                         l_bsid_array(a),
                         i_id_dep_clin_serv,
                         i_id_institution,
                         l_flgdef_array(a),
                         g_flg_available)
                    RETURNING id_body_structure_dcs BULK COLLECT INTO l_aux1;
                pk_alertlog.log_info(l_aux1.count || ' rows inserted');
                EXIT WHEN c_input_internal%NOTFOUND;
                g_error := 'CLOSE CONFIGURATION CURSOR';
                CLOSE c_input_internal;
            END LOOP;
        END IF;
    
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_bsdcs_config FOR
            SELECT column_value
            FROM   TABLE(CAST(l_aux1 AS table_number));
        RETURN TRUE;
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
    END set_inst_body_structure_freq;
    /********************************************************************************************
    * Get Most frequent Periodic Observations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_pop_config          Most frequent Configurations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION get_periodic_obs_param_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_pop_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_periodic_obs_param_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_pop_config FOR
            SELECT def_data.id_software,
                   def_data.id_content,
                   def_data.id_event,
                   def_data.id_clinical_service,
                   def_data.periodic_observation_type,
                   def_data.id_time_event_group,
                   def_data.flg_fill_type,
                   def_data.format_num,
                   def_data.id_unit_measure,
                   def_data.id_context,
                   def_data.flg_type
            FROM   (SELECT temp_data.id_software,
                           temp_data.id_content,
                           temp_data.id_event,
                           temp_data.id_clinical_service,
                           temp_data.periodic_observation_type,
                           temp_data.id_time_event_group,
                           temp_data.flg_fill_type,
                           temp_data.format_num,
                           temp_data.id_unit_measure,
                           temp_data.id_context,
                           temp_data.flg_type,
                           row_number() over(PARTITION BY temp_data.id_software, temp_data.id_content, temp_data.id_event, temp_data.id_clinical_service ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT pop.rowid l_row,
                                   pop.id_content,
                                   --pop.id_event   id_event_def,
                                   decode(pop.id_event,
                                          NULL,
                                          NULL,
                                          pk_default_content.get_alert_event_id(i_lang,
                                                                                pop.id_event)) id_event,
                                   pop.periodic_observation_type,
                                   (SELECT cs.id_clinical_service
                                    FROM   clinical_service cs
                                    INNER  JOIN alert_default.clinical_service acs
                                    ON     (acs.id_content = cs.id_content)
                                    WHERE  cs.flg_available = g_flg_available
                                           AND acs.id_clinical_service = i_id_clinical_service) id_clinical_service,
                                   pop.id_time_event_group,
                                   pop.flg_fill_type,
                                   pop.format_num,
                                   pop.id_unit_measure,
                                   pop.id_context,
                                   pop.flg_type,
                                   pop.id_software
                            FROM   alert_default.periodic_observation_param pop
                            WHERE  pop.id_software = i_id_software
                                   AND pop.id_market = i_market
                                   AND pop.version = i_version
                                   AND pop.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                   AND pop.flg_available = g_flg_available
                                   AND pop.id_clinical_service IS NOT NULL) temp_data
                    WHERE  (temp_data.id_event != 0 OR temp_data.id_event IS NULL)) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT pop.id_periodic_observation_param
                    FROM   periodic_observation_param pop
                    WHERE  pop.id_content = def_data.id_content
                           AND pop.id_clinical_service = def_data.id_clinical_service
                           AND (pop.id_event = def_data.id_event OR
                           (pop.id_event IS NULL AND def_data.id_event IS NULL))
                           AND pop.id_institution = i_id_institution
                           AND pop.id_software = def_data.id_software
                           AND pop.flg_available = g_flg_available);
    
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
            pk_types.open_my_cursor(o_pop_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_periodic_obs_param_freq;
    /********************************************************************************************
    * Set Most frequent Periodic Observations for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_software            Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_pop_config          Most frequent Configurations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION set_periodic_obs_param_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_periodic_obs_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays   
        l_data_pop_id_software table_number;
        l_data_pop_id_content  table_varchar;
        l_data_pop_id_event    table_number;
        l_data_pop_po_type     table_varchar;
        l_data_pop_id_cs       table_number;
        l_data_pop_id_teg      table_number;
        l_data_pop_fill_type   table_varchar;
        l_data_pop_format_num  table_varchar;
        l_data_pop_id_unit_mea table_number;
        l_data_pop_id_context  table_number;
        l_data_pop_flg_type    table_varchar;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal  pk_types.cursor_type;
        c_input_internal2 pk_types.cursor_type;
        l_aux1            table_number := table_number();
        l_auxf            table_number := table_number();
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        -- temporary translation
        o_trl_table t_tab_translation;
        o_trl_rec   t_rec_translation;
    
        l_error t_error_out;
    
    BEGIN
    
        --PERIODIC_OBSERVATION_PARAM
        IF NOT get_periodic_obs_param_freq(i_lang,
                                           i_market,
                                           i_version,
                                           i_id_institution,
                                           i_id_software,
                                           i_id_clinical_service,
                                           i_id_dep_clin_serv,
                                           c_input_internal,
                                           l_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_periodic_obs_param_freq');
            LOOP
                g_error := 'FETCH CONFIGURATION CURSOR ' || i_id_clinical_service;
                FETCH c_input_internal BULK COLLECT
                    INTO l_data_pop_id_software,
                         l_data_pop_id_content,
                         l_data_pop_id_event,
                         l_data_pop_id_cs,
                         l_data_pop_po_type,
                         l_data_pop_id_teg,
                         l_data_pop_fill_type,
                         l_data_pop_format_num,
                         l_data_pop_id_unit_mea,
                         l_data_pop_id_context,
                         l_data_pop_flg_type LIMIT g_array_size;
                g_error := 'LOAD CONFIGURATIONS ' || i_id_clinical_service;
                FORALL j IN 1 .. l_data_pop_id_content.count SAVE EXCEPTIONS
                    INSERT INTO periodic_observation_param
                        (id_periodic_observation_param,
                         code_periodic_observation,
                         id_event,
                         periodic_observation_type,
                         id_clinical_service,
                         id_time_event_group,
                         flg_available,
                         flg_fill_type,
                         rank,
                         format_num,
                         id_unit_measure,
                         id_institution,
                         id_software,
                         id_context,
                         flg_type,
                         id_content)
                    VALUES
                        (seq_periodic_observation_param.nextval,
                         'PERIODIC_OBSERVATION_PARAM.CODE_PERIODIC_OBSERVATION.' ||
                         seq_periodic_observation_param.currval,
                         l_data_pop_id_event(j),
                         l_data_pop_po_type(j),
                         l_data_pop_id_cs(j),
                         l_data_pop_id_teg(j),
                         g_flg_available,
                         l_data_pop_fill_type(j),
                         0,
                         l_data_pop_format_num(j),
                         l_data_pop_id_unit_mea(j),
                         i_id_institution,
                         l_data_pop_id_software(j),
                         l_data_pop_id_context(j),
                         l_data_pop_flg_type(j),
                         l_data_pop_id_content(j))
                    RETURNING id_periodic_observation_param BULK COLLECT INTO l_aux1;
                l_auxf := l_auxf MULTISET UNION l_aux1;
                EXIT WHEN c_input_internal%NOTFOUND;
            END LOOP;
        
            CLOSE c_input_internal;
        
        END IF;
    
        --- RMGM : Load Translations
        /*l_table_name := upper('periodic_observation_param');
        g_error      := 'LOAD TRANSLATIONS ' || l_table_name;
        IF NOT pk_default_content.set_def_translations(i_lang, l_table_name, o_error)
        THEN
            RAISE dml_errors;
        END IF;*/
    
        SELECT t_rec_translation(def_data.code_translation,
                                 'ALERT',
                                 'ALERT.' || def_data.code_translation,
                                 'PERIODIC_OBSERVATION_PARAM',
                                 'PFH',
                                 def_data.desc_lang_1,
                                 def_data.desc_lang_2,
                                 def_data.desc_lang_3,
                                 def_data.desc_lang_4,
                                 def_data.desc_lang_5,
                                 def_data.desc_lang_6,
                                 def_data.desc_lang_7,
                                 def_data.desc_lang_8,
                                 def_data.desc_lang_9,
                                 def_data.desc_lang_10,
                                 def_data.desc_lang_11,
                                 def_data.desc_lang_12,
                                 def_data.desc_lang_13,
                                 def_data.desc_lang_14,
                                 def_data.desc_lang_15,
                                 def_data.desc_lang_16,
                                 def_data.desc_lang_17,
                                 def_data.desc_lang_18,
                                 def_data.desc_lang_19,
                                 def_data.desc_lang_20,
                                 def_data.desc_lang_21,
                                 def_data.desc_lang_22,
                                 NULL)
        BULK   COLLECT
        INTO   o_trl_table
        FROM   (SELECT temp_data.code_translation,
                       def_t.desc_lang_1,
                       def_t.desc_lang_2,
                       def_t.desc_lang_3,
                       def_t.desc_lang_4,
                       def_t.desc_lang_5,
                       def_t.desc_lang_6,
                       def_t.desc_lang_7,
                       def_t.desc_lang_8,
                       def_t.desc_lang_9,
                       def_t.desc_lang_10,
                       def_t.desc_lang_11,
                       def_t.desc_lang_12,
                       def_t.desc_lang_13,
                       def_t.desc_lang_14,
                       def_t.desc_lang_15,
                       def_t.desc_lang_16,
                       def_t.desc_lang_17,
                       def_t.desc_lang_18,
                       def_t.desc_lang_19,
                       def_t.desc_lang_20,
                       def_t.desc_lang_21,
                       def_t.desc_lang_22
                FROM   (SELECT r_data.code_translation,
                               (SELECT def_pop.code_periodic_observation
                                FROM   alert_default.periodic_observation_param def_pop
                                WHERE  def_pop.id_periodic_observation_param = r_data.def_pop) def_code
                        FROM   (SELECT pk_default_content.get_def_periodic_obs_id(1,
                                                                                  ext_pop.id_content,
                                                                                  ext_pop.id_clinical_service,
                                                                                  ext_pop.id_software,
                                                                                  ext_pop.id_event,
                                                                                  ext_pop.id_institution) def_pop,
                                       ext_pop.code_periodic_observation code_translation
                                FROM   periodic_observation_param ext_pop
                                WHERE  ext_pop.id_periodic_observation_param IN
                                       (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                        FROM   TABLE(CAST(l_auxf AS table_number)) p)
                                       AND ext_pop.flg_available = 'Y') r_data
                        WHERE  r_data.def_pop != 0) temp_data
                INNER  JOIN alert_default.translation def_t
                ON     (def_t.code_translation = temp_data.def_code)) def_data
        WHERE  NOT EXISTS (SELECT 0
                FROM   TABLE(pk_translation.get_table_code_translation(1,
                                                                       'PERIODIC_OBSERVATION_PARAM')) trl
                WHERE  trl.code_translation = def_data.code_translation);
    
        pk_translation.ins_bulk_translation(o_trl_table,
                                            g_flg_available);
        pk_alertlog.log_info('Translations: ' || SQL%ROWCOUNT || ' Inserted');
    
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED ' || i_id_clinical_service;
        OPEN o_inst_periodic_obs_param FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        WHEN dml_errors THEN
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
        
    END set_periodic_obs_param_freq;
    /********************************************************************************************
      * Get Periodic observation param desc for a set of markets, versions and sotwares
      *
      * @param i_lang                Prefered language ID
      * @param i_market              Market ID's
      * @param i_version             ALERT version's
      * @param i_id_institution      Institution ID
      * @param i_id_software         Software ID
    * @param i_id_clinical_service  default clinical id
    * @param i_id_dep_clin_serv  alert dep_clin_serv id
      * @param o_cursor_config       Cursor of periodic observation param desc identifiers
      * @param o_error               Error
      *
      *
      * @return                      true or false on success or error
      *
      * @author                      RMGM
      * @version                     0.1
      * @since                       2012/08/29
      ********************************************************************************************/
    FUNCTION get_periodic_obs_desc_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cursor_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_periodic_obs_desc_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_cursor_config FOR
            SELECT def_data.id_periodic_observation_param,
                   def_data.pod_id_content,
                   def_data.value,
                   def_data.icon
            FROM   (SELECT norm_data.id_periodic_observation_param,
                           norm_data.value,
                           norm_data.icon,
                           norm_data.pod_id_content,
                           rank() over(PARTITION BY norm_data.id_periodic_observation_param, norm_data.pod_id_content ORDER BY norm_data.l_row) records_count
                    FROM   (SELECT temp_data.l_row,
                                   pk_default_content.get_alert_periodic_obs_id(i_lang,
                                                                                temp_data.pop_id_content,
                                                                                temp_data.id_clinical_service,
                                                                                temp_data.id_software,
                                                                                temp_data.id_event,
                                                                                temp_data.id_market) id_periodic_observation_param,
                                   temp_data.pod_id_content,
                                   temp_data.value,
                                   temp_data.icon
                            FROM   (SELECT def_pod.rowid               l_row,
                                           def_pop.id_clinical_service,
                                           def_pop.id_event,
                                           def_pop.id_software,
                                           def_pop.id_content          pop_id_content,
                                           def_pod.id_content          pod_id_content,
                                           def_pod.value,
                                           def_pod.icon,
                                           def_pod.id_market
                                    FROM   alert_default.periodic_observation_desc def_pod
                                    INNER  JOIN alert_default.periodic_observation_param def_pop
                                    ON     (def_pop.id_periodic_observation_param = def_pod.id_periodic_observation_param AND
                                           def_pop.flg_available = g_flg_available AND
                                           def_pop.id_market = def_pod.id_market AND def_pop.version = def_pod.version)
                                    WHERE  def_pod.flg_available = g_flg_available
                                           AND def_pop.id_clinical_service IN
                                           (SELECT /*+ dynamic_sampling(p 2) */
                                                 column_value
                                                FROM   TABLE(CAST(l_cs_array AS table_number)) p)
                                           AND def_pod.id_market = i_market
                                           AND def_pod.version = i_version) temp_data
                            WHERE  (temp_data.id_clinical_service != 0)
                                   AND (temp_data.id_event IS NULL OR temp_data.id_event != 0)) norm_data
                    WHERE  norm_data.id_periodic_observation_param != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS
             (SELECT 0
                    FROM   periodic_observation_desc alert_pod
                    WHERE  alert_pod.id_periodic_observation_param = def_data.id_periodic_observation_param
                           AND alert_pod.flg_available = g_flg_available
                           AND alert_pod.id_content = def_data.pod_id_content);
    
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
            pk_types.open_my_cursor(o_cursor_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_periodic_obs_desc_freq;
    /********************************************************************************************
    * Set Periodic observations desc. for a specific institution
    *
    * @param i_lang                     Prefered language ID
    * @param i_market                   Market ID's
    * @param i_version                  ALERT version's
    * @param i_id_institution           Institution ID
    * @param i_software                 Software ID's
    * @param o_inst_periodic_obs_desc   Cursor of Instituition Periodic Observations Desc.
    * @param o_error                    Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_periodic_obs_desc_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_pod OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays   
        l_data_pop_id         table_number;
        l_data_pod_id_content table_varchar;
        l_data_pod_value      table_varchar;
        l_data_pod_icon       table_varchar;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal  pk_types.cursor_type;
        c_input_internal2 pk_types.cursor_type;
        l_aux1            table_number := table_number();
        l_auxf            table_number := table_number();
    
        o_trl_table t_tab_translation;
        o_trl_rec   t_rec_translation;
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        l_error t_error_out;
    
    BEGIN
        IF NOT get_periodic_obs_desc_freq(i_lang,
                                          i_market,
                                          i_version,
                                          i_id_institution,
                                          i_id_software,
                                          i_id_clinical_service,
                                          i_id_dep_clin_serv,
                                          c_input_internal,
                                          l_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_periodic_obs_desc_freq');
            LOOP
            
                g_error := 'FETCH CONFIGURATION CURSOR';
                FETCH c_input_internal BULK COLLECT
                    INTO l_data_pop_id,
                         l_data_pod_id_content,
                         l_data_pod_value,
                         l_data_pod_icon LIMIT g_array_size;
                g_error := 'LOAD CONFIGURATIONS';
                FORALL j IN 1 .. l_data_pod_id_content.count SAVE EXCEPTIONS
                    INSERT INTO periodic_observation_desc
                        (id_periodic_observation_desc,
                         code_periodic_observation_desc,
                         id_periodic_observation_param,
                         flg_available,
                         rank,
                         VALUE,
                         adw_last_update,
                         icon,
                         id_content)
                    VALUES
                        (seq_periodic_observation_desc.nextval,
                         'PERIODIC_OBSERVATION_DESC.CODE_PERIODIC_OBSERVATION_DESC.' ||
                         seq_periodic_observation_desc.currval,
                         l_data_pop_id(j),
                         g_flg_available,
                         0,
                         l_data_pod_value(j),
                         SYSDATE,
                         l_data_pod_icon(j),
                         l_data_pod_id_content(j))
                    RETURNING id_periodic_observation_desc BULK COLLECT INTO l_aux1;
                l_auxf := l_auxf MULTISET UNION l_aux1;
                EXIT WHEN c_input_internal%NOTFOUND;
            END LOOP;
        
            CLOSE c_input_internal;
        
        END IF;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_inst_pod FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
    
        -- 15/03/2011 - RMGM : changed way how translations are loaded
        /*l_table_name := upper('periodic_observation_desc');
        g_error      := 'SET DEF TRANSLATIONS';
        IF NOT pk_default_content.set_def_translations(i_lang, l_table_name, o_error)
        THEN
            RAISE dml_errors;
        END IF;*/
        SELECT t_rec_translation(def_data.code_translation,
                                 'ALERT',
                                 'ALERT.' || def_data.code_translation,
                                 'PERIODIC_OBSERVATION_DESC',
                                 'PFH',
                                 def_data.desc_lang_1,
                                 def_data.desc_lang_2,
                                 def_data.desc_lang_3,
                                 def_data.desc_lang_4,
                                 def_data.desc_lang_5,
                                 def_data.desc_lang_6,
                                 def_data.desc_lang_7,
                                 def_data.desc_lang_8,
                                 def_data.desc_lang_9,
                                 def_data.desc_lang_10,
                                 def_data.desc_lang_11,
                                 def_data.desc_lang_12,
                                 def_data.desc_lang_13,
                                 def_data.desc_lang_14,
                                 def_data.desc_lang_15,
                                 def_data.desc_lang_16,
                                 def_data.desc_lang_17,
                                 def_data.desc_lang_18,
                                 def_data.desc_lang_19,
                                 def_data.desc_lang_20,
                                 def_data.desc_lang_21,
                                 def_data.desc_lang_22,
                                 NULL)
        BULK   COLLECT
        INTO   o_trl_table
        FROM   (SELECT temp_data.code_translation,
                       def_t.desc_lang_1,
                       def_t.desc_lang_2,
                       def_t.desc_lang_3,
                       def_t.desc_lang_4,
                       def_t.desc_lang_5,
                       def_t.desc_lang_6,
                       def_t.desc_lang_7,
                       def_t.desc_lang_8,
                       def_t.desc_lang_9,
                       def_t.desc_lang_10,
                       def_t.desc_lang_11,
                       def_t.desc_lang_12,
                       def_t.desc_lang_13,
                       def_t.desc_lang_14,
                       def_t.desc_lang_15,
                       def_t.desc_lang_16,
                       def_t.desc_lang_17,
                       def_t.desc_lang_18,
                       def_t.desc_lang_19,
                       def_t.desc_lang_20,
                       def_t.desc_lang_21,
                       def_t.desc_lang_22
                FROM   (SELECT r_data.code_translation,
                               nvl((SELECT def_pod.code_periodic_observation_desc
                                   FROM   alert_default.periodic_observation_desc def_pod
                                   WHERE  def_pod.id_content = r_data.id_content
                                          AND def_pod.id_periodic_observation_param = r_data.id_pop
                                          AND def_pod.flg_available = 'Y'),
                                   NULL) code_translation_def
                        FROM   (SELECT pod.code_periodic_observation_desc code_translation,
                                       pk_default_content.get_def_periodic_obs_id(i_lang,
                                                                                  pop.id_content,
                                                                                  pop.id_clinical_service,
                                                                                  pop.id_software,
                                                                                  pop.id_event,
                                                                                  pop.id_institution) id_pop,
                                       pod.id_content
                                FROM   periodic_observation_desc pod
                                INNER  JOIN periodic_observation_param pop
                                ON     (pop.id_periodic_observation_param = pod.id_periodic_observation_param)
                                WHERE  pod.flg_available = 'Y'
                                       AND pod.id_periodic_observation_desc IN
                                       (SELECT /*+ dynamic_sampling(p 2) */
                                             column_value
                                            FROM   TABLE(CAST(l_auxf AS table_number)) p)
                                       AND rownum > 0) r_data
                        WHERE  r_data.id_pop != 0) temp_data
                INNER  JOIN alert_default.translation def_t
                ON     (def_t.code_translation = temp_data.code_translation_def)
                WHERE  temp_data.code_translation_def IS NOT NULL) def_data
        WHERE  NOT EXISTS (SELECT 0
                FROM   TABLE(pk_translation.get_table_code_translation(i_lang,
                                                                       'PERIODIC_OBSERVATION_DESC')) trl
                WHERE  trl.code_translation = def_data.code_translation);
    
        pk_translation.ins_bulk_translation(o_trl_table,
                                            g_flg_available);
        pk_alertlog.log_info('Translations: ' || SQL%ROWCOUNT || ' Inserted');
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        WHEN dml_errors THEN
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
        
    END set_periodic_obs_desc_freq;
    /********************************************************************************************
    * Get Most frequent Past History for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/18
    ********************************************************************************************/
    FUNCTION get_inst_past_history_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_past_history_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_cursor_config FOR
            SELECT def_data.id_alert_diagnosis,
                   def_data.id_clinical_service,
                   def_data.id_software,
                   def_data.id_profile_template
            FROM   (SELECT temp_data.id_alert_diagnosis,
                           temp_data.id_clinical_service,
                           temp_data.id_software,
                           temp_data.id_profile_template,
                           rank() over(PARTITION BY temp_data.id_alert_diagnosis, temp_data.id_clinical_service, temp_data.id_software, temp_data.id_profile_template ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT csad.rowid l_row,
                                   nvl((SELECT alert_ad.id_alert_diagnosis
                                       FROM   alert_diagnosis alert_ad
                                       WHERE  alert_ad.id_alert_diagnosis = csad.id_alert_diagnosis
                                              AND alert_ad.flg_available = g_flg_available),
                                       -100) id_alert_diagnosis,
                                   nvl((SELECT alert_cs.id_clinical_service
                                       FROM   clinical_service alert_cs
                                       INNER  JOIN alert_default.clinical_service def_cs
                                       ON     (def_cs.id_content = alert_cs.id_content)
                                       WHERE  def_cs.id_clinical_service = i_id_clinical_service
                                              AND alert_cs.flg_available = g_flg_available),
                                       -100) id_clinical_service,
                                   decode(csad.id_profile_template,
                                          NULL,
                                          NULL,
                                          0,
                                          0,
                                          nvl((SELECT alert_pt.id_profile_template
                                              FROM   profile_template alert_pt
                                              WHERE  alert_pt.id_profile_template = csad.id_profile_template
                                                     AND alert_pt.flg_available = g_flg_available),
                                              -100)) id_profile_template,
                                   csad.id_software
                            FROM   alert_default.clin_serv_alert_diagnosis csad
                            INNER  JOIN alert_default.alert_diagnosis_mrk_vrs admv
                            ON     (admv.id_alert_diagnosis = csad.id_alert_diagnosis AND admv.id_market = i_market AND
                                   admv.version = i_version)
                            WHERE  csad.id_software = i_id_software
                                   AND csad.flg_available = g_flg_available
                                   AND csad.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_profile_template != -100
                           AND temp_data.id_clinical_service != -100
                           AND temp_data.id_alert_diagnosis != -100) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS
             (SELECT 0
                    FROM   clin_serv_alert_diagnosis alert_csad
                    WHERE  alert_csad.id_alert_diagnosis = def_data.id_alert_diagnosis
                           AND alert_csad.id_clinical_service = def_data.id_clinical_service
                           AND alert_csad.flg_available = g_flg_available
                           AND alert_csad.id_software = def_data.id_software
                           AND alert_csad.id_profile_template = def_data.id_profile_template);
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
            pk_types.open_my_cursor(o_cursor_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_past_history_freq;
    /********************************************************************************************
    * Set Most frequent Past History for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_inst_csad           Most frequent ids configured
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/18
    ********************************************************************************************/
    FUNCTION set_inst_past_history_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_csad OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays   
        l_data_csad_id_software table_number;
        l_data_csad_id_ad       table_number;
        l_data_csad_id_cs       table_number;
        l_data_csad_id_ptemp    table_number;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal  pk_types.cursor_type;
        c_input_internal2 pk_types.cursor_type;
        l_aux1            table_number := table_number();
        l_auxf            table_number := table_number();
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        l_error t_error_out;
    
    BEGIN
        IF NOT get_inst_past_history_freq(i_lang,
                                          i_market,
                                          i_version,
                                          i_id_institution,
                                          i_id_software,
                                          i_id_clinical_service,
                                          c_input_internal,
                                          l_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_past_history_freq');
            LOOP
            
                g_error := 'FETCH CONFIGURATION CURSOR';
                FETCH c_input_internal BULK COLLECT
                    INTO l_data_csad_id_ad,
                         l_data_csad_id_cs,
                         l_data_csad_id_software,
                         l_data_csad_id_ptemp LIMIT g_array_size;
                g_error := 'LOAD CONFIGURATIONS';
                FORALL j IN 1 .. l_data_csad_id_ad.count SAVE EXCEPTIONS
                    INSERT INTO clin_serv_alert_diagnosis
                        (id_clin_serv_alert_diagnosis,
                         id_clinical_service,
                         id_alert_diagnosis,
                         flg_available,
                         adw_last_update,
                         id_software,
                         id_profile_template,
                         id_institution)
                    VALUES
                        (seq_clin_serv_alert_diagnosis.nextval,
                         l_data_csad_id_cs(j),
                         l_data_csad_id_ad(j),
                         g_flg_available,
                         SYSDATE,
                         l_data_csad_id_software(j),
                         l_data_csad_id_ptemp(j),
                         i_id_institution)
                    RETURNING id_clin_serv_alert_diagnosis BULK COLLECT INTO l_aux1;
                l_auxf := l_auxf MULTISET UNION l_aux1;
                EXIT WHEN c_input_internal%NOTFOUND;
            END LOOP;
        
            CLOSE c_input_internal;
        
        END IF;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_inst_csad FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        
    END set_inst_past_history_freq;
    /********************************************************************************************
    * Set Most frequent Rehab types for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_cursor_config       Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION get_inst_rehab_st_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_cursor_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    
    BEGIN
    
        g_func_name := upper('get_inst_rehab_st_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_cursor_config FOR
            SELECT def_data.id_dep_clin_serv,
                   def_data.id_rehab_session_type
            FROM   (SELECT temp_data.id_dep_clin_serv,
                           temp_data.id_rehab_session_type,
                           rank() over(PARTITION BY temp_data.id_dep_clin_serv, temp_data.id_rehab_session_type ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT rcs.rowid l_row,
                                   i_id_dep_clin_serv id_dep_clin_serv,
                                   nvl((SELECT alert_rst.id_rehab_session_type
                                       FROM   rehab_session_type alert_rst
                                       WHERE  alert_rst.id_content = rst.id_content
                                              AND rownum = 1),
                                       '-100') id_rehab_session_type
                            FROM   alert_default.rehab_clin_serv rcs
                            INNER  JOIN alert_default.rehab_session_type rst
                            ON     (rst.id_rehab_session_type = rcs.id_rehab_session_type AND
                                   rst.flg_available = g_flg_available)
                            INNER  JOIN alert_default.rehab_session_type_mrk_vrs rstmv
                            ON     (rstmv.id_rehab_session_type = rst.id_rehab_session_type AND
                                   rstmv.id_market = i_market AND rstmv.version = i_version)
                            WHERE  rcs.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                    FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_rehab_session_type != '-100') def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS
             (SELECT 0
                    FROM   rehab_dep_clin_serv ext_tbl
                    WHERE  ext_tbl.id_dep_clin_serv = def_data.id_dep_clin_serv
                           AND ext_tbl.id_rehab_session_type = def_data.id_rehab_session_type);
    
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
            pk_types.open_my_cursor(o_cursor_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_rehab_st_freq;
    /********************************************************************************************
    * Set Most frequent Rehab Types for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_dep_clin_serv    Department/Clinical Service ID
    * @param o_bsdcs_config        Most frequent Configuration Id's generated
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION set_inst_rehab_st_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_inst_rdcs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays       
        l_data_rcs_id_rst table_varchar;
        l_data_rcs_id_dcs table_number;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_number := table_number();
        l_auxf           table_number := table_number();
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        l_error t_error_out;
    BEGIN
        IF NOT get_inst_rehab_st_freq(i_lang,
                                      i_market,
                                      i_version,
                                      i_id_institution,
                                      i_id_software,
                                      i_id_clinical_service,
                                      i_id_dep_clin_serv,
                                      c_input_internal,
                                      l_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_rehab_st_freq');
            LOOP
                g_error := 'FETCH CONFIGURATION CURSOR';
                FETCH c_input_internal BULK COLLECT
                    INTO l_data_rcs_id_dcs,
                         l_data_rcs_id_rst LIMIT g_array_size;
                g_error := 'LOAD CONFIGURATIONS';
                FORALL j IN 1 .. l_data_rcs_id_rst.count SAVE EXCEPTIONS
                    INSERT INTO rehab_dep_clin_serv
                        (id_dep_clin_serv,
                         id_rehab_session_type)
                    VALUES
                        (l_data_rcs_id_dcs(j),
                         l_data_rcs_id_rst(j))
                    RETURNING id_dep_clin_serv BULK COLLECT INTO l_aux1;
                l_auxf := l_auxf MULTISET UNION l_aux1;
                EXIT WHEN c_input_internal%NOTFOUND;
            END LOOP;
        
            CLOSE c_input_internal;
        
        END IF;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_inst_rdcs FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        
    END set_inst_rehab_st_freq;
    /********************************************************************************************
    * Get Most frequent VS Scales for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION get_inst_vssa_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_vssa_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
    
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
            pk_types.open_my_cursor(o_cursor_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_vssa_freq;
    /********************************************************************************************
    * Set Most frequent VS Scales for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Clinical Service ID
    * @param o_inst_vssa           Most frequent Configuration details
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/19
    ********************************************************************************************/
    FUNCTION set_inst_vssa_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_vssa OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays   
        l_data_vssa_id_cs  table_number;
        l_data_vssa_id_vss table_number;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal pk_types.cursor_type;
        l_aux1           table_number := table_number();
        l_auxf           table_number := table_number();
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        l_error t_error_out;
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        
    END set_inst_vssa_freq;
    /********************************************************************************************
    * Get Most frequent Complication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/20
    ********************************************************************************************/
    FUNCTION get_inst_comp_config_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_cursor_config OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_func_name := upper('get_inst_comp_config_freq');
        g_error     := 'GET CS STRUCTURE' || i_id_clinical_service;
        IF NOT pk_default_inst_preferences.check_clinical_service(i_lang,
                                                                  i_id_clinical_service,
                                                                  l_cs_array,
                                                                  o_error)
        THEN
            g_error := 'ERROR GET CS STRUCTURE' || i_id_clinical_service;
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN CONFIGURATION CURSOR';
        OPEN o_cursor_config FOR
            SELECT def_data.id_complication,
                   def_data.id_comp_axe,
                   def_data.id_clinical_service,
                   def_data.flg_configuration,
                   def_data.id_sys_list,
                   def_data.rank,
                   def_data.flg_default
            FROM   (SELECT temp_data.id_complication,
                           temp_data.id_comp_axe,
                           temp_data.id_clinical_service,
                           temp_data.flg_configuration,
                           temp_data.id_sys_list,
                           temp_data.rank,
                           temp_data.flg_default,
                           rank() over(PARTITION BY temp_data.id_complication, temp_data.id_comp_axe, temp_data.id_clinical_service, temp_data.id_sys_list ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT cc.rowid l_row,
                                   decode(cc.id_complication,
                                          NULL,
                                          NULL,
                                          nvl((SELECT c.id_complication
                                              FROM   complication c
                                              INNER  JOIN alert_default.complication c2
                                              ON     (c2.id_content = c.id_content)
                                              INNER  JOIN alert_default.comp_mrk_vrs cmv
                                              ON     (cmv.id_complication = c2.id_complication AND
                                                     cmv.id_market = i_market AND cmv.version = i_version)
                                              WHERE  c2.id_complication = cc.id_complication
                                                     AND c.flg_available = g_flg_available),
                                              -100)) id_complication,
                                   decode(cc.id_comp_axe,
                                          NULL,
                                          NULL,
                                          nvl((SELECT ca.id_comp_axe
                                              FROM   comp_axe ca
                                              INNER  JOIN alert_default.comp_axe def_ca
                                              ON     (def_ca.id_content = ca.id_content)
                                              INNER  JOIN alert_default.comp_axe_mrk_vrs camv
                                              ON     (camv.id_comp_axe = def_ca.id_comp_axe AND camv.id_market = i_market AND
                                                     camv.version = i_version)
                                              WHERE  def_ca.id_comp_axe = cc.id_comp_axe
                                                     AND ca.flg_available = g_flg_available),
                                              -100)) id_comp_axe,
                                   nvl((SELECT alert_cs.id_clinical_service
                                       FROM   clinical_service alert_cs
                                       INNER  JOIN alert_default.clinical_service def_cs
                                       ON     (def_cs.id_content = alert_cs.id_content)
                                       WHERE  def_cs.id_clinical_service = i_id_clinical_service
                                              AND alert_cs.flg_available = g_flg_available),
                                       -100) id_clinical_service,
                                   cc.flg_configuration,
                                   cc.id_sys_list,
                                   cc.rank,
                                   cc.flg_default
                            FROM   alert_default.comp_config cc
                            WHERE  cc.id_software = i_id_software
                                   AND cc.id_clinical_service IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_clinical_service != -100
                           AND (temp_data.id_comp_axe IS NULL OR temp_data.id_comp_axe != -100)
                           AND (temp_data.id_complication IS NULL OR temp_data.id_complication != -100)) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   comp_config cc
                    WHERE  cc.id_complication = def_data.id_complication
                           AND cc.id_comp_axe = def_data.id_comp_axe
                           AND cc.id_clinical_service = def_data.id_clinical_service
                           AND cc.id_institution = i_id_institution
                           AND cc.id_sys_list = def_data.id_sys_list
                           AND cc.id_software = i_id_software);
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
            pk_types.open_my_cursor(o_cursor_config);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_inst_comp_config_freq;
    /********************************************************************************************
    * Set Most frequent Complication for a specific clinical_service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_id_clinical_service Clinical Service ID
    * @param o_cursor_config       Most frequent configuration
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/20
    ********************************************************************************************/
    FUNCTION set_inst_comp_config_freq
    (
        i_lang IN language.id_language%TYPE,
        i_market IN market.id_market%TYPE,
        i_version IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_inst_cc OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- detail arrays   
        l_data_cc_id_complication table_number;
        l_data_cc_id_compaxe      table_number;
        l_data_cc_id_cs           table_number;
        l_data_cc_flg_config      table_varchar;
        l_data_cc_id_syslist      table_number;
        l_data_cc_rank            table_number;
        l_data_cc_flg_def         table_varchar;
    
        --TRANSLATION
        dml_errors EXCEPTION;
        l_table_name user_tables.table_name%TYPE;
    
        -- auxiliar outputs
        c_input_internal  pk_types.cursor_type;
        c_input_internal2 pk_types.cursor_type;
        l_aux1            table_number := table_number();
        l_auxf            table_number := table_number();
    
        --error handling
        l_exception EXCEPTION;
        bulk_errors EXCEPTION;
        PRAGMA EXCEPTION_INIT(bulk_errors,
                              -24381);
        error_num NUMBER;
        error_msg VARCHAR2(2000);
    
        l_error t_error_out;
    
    BEGIN
        IF NOT get_inst_comp_config_freq(i_lang,
                                         i_market,
                                         i_version,
                                         i_id_institution,
                                         i_id_software,
                                         i_id_clinical_service,
                                         c_input_internal,
                                         l_error)
        THEN
            RAISE l_exception;
        ELSE
            g_func_name := upper('set_inst_comp_config_freq');
            LOOP
            
                g_error := 'FETCH CONFIGURATION CURSOR';
                FETCH c_input_internal BULK COLLECT
                    INTO l_data_cc_id_complication,
                         l_data_cc_id_compaxe,
                         l_data_cc_id_cs,
                         l_data_cc_flg_config,
                         l_data_cc_id_syslist,
                         l_data_cc_rank,
                         l_data_cc_flg_def LIMIT g_array_size;
                g_error := 'LOAD CONFIGURATIONS';
                FORALL j IN 1 .. l_data_cc_id_complication.count SAVE EXCEPTIONS
                    INSERT INTO comp_config
                        (id_comp_config,
                         id_complication,
                         id_comp_axe,
                         id_clinical_service,
                         id_institution,
                         id_software,
                         flg_configuration,
                         id_sys_list,
                         rank,
                         flg_default)
                    VALUES
                        (seq_comp_config.nextval,
                         l_data_cc_id_complication(j),
                         l_data_cc_id_compaxe(j),
                         l_data_cc_id_cs(j),
                         i_id_institution,
                         i_id_software,
                         l_data_cc_flg_config(j),
                         l_data_cc_id_syslist(j),
                         l_data_cc_rank(j),
                         l_data_cc_flg_def(j))
                    RETURNING id_comp_config BULK COLLECT INTO l_aux1;
                l_auxf := l_auxf MULTISET UNION l_aux1;
                EXIT WHEN c_input_internal%NOTFOUND;
            END LOOP;
        
            CLOSE c_input_internal;
        
        END IF;
        pk_alertlog.log_info(l_auxf.count || ' rows inserted');
        g_error := 'RETURN DEFAULT IDS CONFIGURED';
        OPEN o_inst_cc FOR
            SELECT column_value
            FROM   TABLE(CAST(l_auxf AS table_number));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN bulk_errors THEN
            FOR idx IN 1 .. SQL%bulk_exceptions.count
            LOOP
                error_msg := SQLERRM(-sql%BULK_EXCEPTIONS(idx).error_code);
                error_num := SQL%BULK_EXCEPTIONS(idx).error_index;
                g_error   := g_error || ' ( index ) ' || error_num;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQL%BULK_EXCEPTIONS(idx).error_code,
                                                  error_msg,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  g_func_name,
                                                  o_error);
            
            END LOOP;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN l_exception THEN
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
        
    END set_inst_comp_config_freq;
    /********************************************************************************************
    * Set Most frequent Default Parametrizations for a specific clinical_service using new engine
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             ALERT version
    * @param i_software            Software ID's
    * @param i_id_clinical_service Clinical Service ID
    * @param i_id_clinical_service Clinical Service ID    
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)    
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/17
    ********************************************************************************************/
    FUNCTION set_inst_param_freq_new
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_id_software IN table_number,
        i_id_clinical_service IN table_number,
        i_id_dep_clin_serv IN table_number,
        i_flg_dcs_all IN VARCHAR2,
        i_commit_at_end IN VARCHAR2,
        o_results OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_d_institution institution.id_institution%TYPE := NULL;
        i_process_type  table_varchar := table_varchar('FREQUENT',
                                                       'TRANSLATION');
        i_areas         table_varchar := table_varchar();
        i_tables        table_varchar := table_varchar();
        i_id_content    table_varchar := table_varchar();
        i_dependencies  VARCHAR2(1) := 'N';
        o_execution_id  NUMBER := 0;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'SET DEFAULT INSTITUTION CLINICAL SERVICE PREFERENCES CONFIGURATIONS';
        alert_core_func.pk_tool_engine.set_default_configuration(i_lang                => i_lang,
                                                                 i_market              => i_market,
                                                                 i_version             => i_version,
                                                                 i_institution         => i_id_institution,
                                                                 i_d_institution       => i_d_institution,
                                                                 i_software            => i_id_software,
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
        IF i_commit_at_end = g_flg_available
        THEN
            COMMIT;
        END IF;
        OPEN o_results FOR
            SELECT ex_det.id_execution_det,
                   nvl(pk_translation.get_translation(i_lang,
                                                      ex_det.code_tool_area),
                       ex_det.tool_area_name) area_name,
                   ex_det.tool_table_name table_name,
                   nvl(pk_translation.get_translation(i_lang,
                                                      ex_det.code_tool_process_type),
                       ex_det.internal_name) process_name,
                   ex_det.rec_inserted,
                   ex_det.execution_status,
                   ex_det.execution_length
            FROM   alert_core_data.v_exec_hist_details ex_det
            WHERE  ex_det.id_execution = o_execution_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error || ' / ' || o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_INST_DEFAULT_PARAM_FREQ_NEW',
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
                                              'SET_INST_DEFAULT_PARAM_FREQ_NEW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_inst_param_freq_new;
    /********************************************************************************************
    * Set interv_dcs_most_freq_except configuration
    *
    * @param i_lang                  Language ID
    * @param i_institution           Institution ID
    * @param i_mkt                   Market Search List
    * @param i_vers                  Content Version Search List
    * @param i_software              Software Search List
    * @param i_clin_serv_in          Default Clinical Service Seach list
    * @param i_clin_serv_out         Configuration target (id_clinical_service)
    * @param i_dep_clin_serv_out     Configuration target (Dep_clin_serv_id)
    * @param o_result                Number of records inserted
    * @param o_error                 Error message    
    *
    * @return                        True or False
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/
    FUNCTION set_int_dcs_mf_except_all
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        i_clin_serv_in IN table_number,
        i_clin_serv_out IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET INTERVENTION BY PROFESSIONAL CATEGORY, MARKET AND VERSION';
        INSERT INTO interv_dcs_most_freq_except
            (id_interv_dcs_most_freq_except,
             id_interv_dep_clin_serv,
             flg_cat_prof,
             flg_available,
             adw_last_update,
             flg_status)
            SELECT seq_interv_dcs_most_f_e.nextval,
                   def_data.id_interv_dep_clin_serv,
                   def_data.flg_cat_prof,
                   g_flg_available,
                   SYSDATE,
                   def_data.flg_status
            FROM   (SELECT temp_data.id_interv_dep_clin_serv,
                           temp_data.flg_cat_prof,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.id_interv_dep_clin_serv, temp_data.flg_cat_prof ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ix.rowid l_row,
                                   decode(ics.id_clinical_service,
                                          NULL,
                                          pk_default_inst_preferences.get_idcs_dest_id(ix.id_interv_clin_serv,
                                                                                       i_institution,
                                                                                       NULL),
                                          pk_default_inst_preferences.get_idcs_dest_id(ix.id_interv_clin_serv,
                                                                                       NULL,
                                                                                       i_dep_clin_serv_out)) id_interv_dep_clin_serv,
                                   ix.flg_cat_prof,
                                   ix.flg_status
                            FROM   alert_default.interv_dcs_most_freq_except ix
                            INNER  JOIN alert_default.interv_clin_serv ics
                            ON     (ics.id_interv_clin_serv = ix.id_interv_clin_serv)
                            WHERE  ix.flg_available = 'Y'
                                   AND ix.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ix.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                    WHERE  temp_data.id_interv_dep_clin_serv > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   interv_dcs_most_freq_except dest_tbl
                    WHERE  dest_tbl.id_interv_dep_clin_serv = def_data.id_interv_dep_clin_serv
                           AND dest_tbl.flg_cat_prof = def_data.flg_cat_prof);
        o_result := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_int_dcs_mf_except_all',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_int_dcs_mf_except_all;
    /********************************************************************************************
    * Set Default Task Goal Task configuration Social Worker
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                content version tag list
    * @param i_software            softwar ID list                
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_freq
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        i_clin_serv_in IN table_number,
        i_clin_serv_out IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- error handling external methods
        l_exception EXCEPTION;
        -- auxiliary array to store final clinical_service list
        l_cs_array table_number := table_number();
    BEGIN
        g_error := 'GET CS STRUCTURE' || i_clin_serv_in(1);
        IF NOT check_clinical_service(i_lang,
                                      i_clin_serv_in(1),
                                      l_cs_array,
                                      o_error)
        THEN
            RAISE l_exception;
        END IF;
        g_func_name := upper('set_intervplan_freq');
        g_error     := 'SET INTERV PLAN SEARCH CONFIGURATION';
        INSERT INTO interv_plan_dep_clin_serv
            (id_interv_plan,
             id_software,
             id_dep_clin_serv,
             flg_available,
             flg_type,
             id_interv_plan_dep_clin_serv)
            SELECT def_data.id_interv_plan,
                   def_data.id_software,
                   i_dep_clin_serv_out,
                   g_flg_available,
                   def_data.flg_type,
                   seq_interv_plan_dep_clin_serv.nextval
            FROM   (SELECT temp_data.id_software,
                           temp_data.id_interv_plan,
                           temp_data.flg_type,
                           row_number() over(PARTITION BY temp_data.id_software, temp_data.id_interv_plan, temp_data.flg_type ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT def_tbl.rowid l_row,
                                   def_tbl.id_software,
                                   nvl((SELECT ext_ip.id_interv_plan
                                       FROM   interv_plan ext_ip
                                       INNER  JOIN alert_default.interv_plan def_ip
                                       ON     (def_ip.id_content = ext_ip.id_content)
                                       WHERE  ext_ip.flg_available = g_flg_available
                                              AND def_ip.flg_available = g_flg_available
                                              AND def_ip.id_interv_plan = def_tbl.id_interv_plan),
                                       0) id_interv_plan,
                                   def_tbl.flg_type
                            FROM   alert_default.interv_plan_dep_clin_serv def_tbl
                            WHERE  def_tbl.flg_available = g_flg_available
                                   AND def_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                        FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND def_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   def_tbl.version IN (SELECT /*+ dynamic_sampling(2) */
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND def_tbl.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                        FROM   TABLE(CAST(l_cs_array AS table_number)) p)) temp_data
                    WHERE  temp_data.id_interv_plan > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   interv_plan_dep_clin_serv dest_tbl
                    WHERE  dest_tbl.id_interv_plan = def_data.id_interv_plan
                           AND dest_tbl.id_software = def_data.id_software
                           AND dest_tbl.id_dep_clin_serv = i_dep_clin_serv_out
                           AND dest_tbl.flg_type = def_data.flg_type);
        o_result := SQL%ROWCOUNT;
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
            RETURN FALSE;
    END set_intervplan_freq;
    /********************************************************************************************
    * Get destination table Id Interv_Dep_clin_serv
    *
    * @param i_interv_cs             Alert_default Interv_clin_serv_id
    * @param i_institution           Institution ID
    * @param i_dcs                   Dep_clin_serv_id
    *
    * @return                        Id Interv_Dep_clin_serv
    *
    * @author                        RMGM
    * @version                       0.1
    * @since                         2013/05/14
    ********************************************************************************************/
    FUNCTION get_idcs_dest_id
    (
        i_interv_cs IN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE IS
        l_res interv_dep_clin_serv.id_interv_dep_clin_serv%TYPE := 0;
    BEGIN
        SELECT nvl((SELECT idcs.id_interv_dep_clin_serv
                   FROM   (SELECT nvl((SELECT dest_i.id_intervention
                                      FROM   intervention dest_i
                                      WHERE  dest_i.id_content = i.id_content
                                             AND dest_i.flg_status = 'A'),
                                      0) id_intervention,
                                  ics.flg_type,
                                  ics.id_software
                           FROM   alert_default.interv_clin_serv ics
                           INNER  JOIN alert_default.intervention i
                           ON     (i.id_intervention = ics.id_intervention AND i.flg_status = 'A')
                           WHERE  ics.id_interv_clin_serv = i_interv_cs) def_interv
                   INNER  JOIN interv_dep_clin_serv idcs
                   ON     (idcs.id_intervention = def_interv.id_intervention)
                   WHERE  idcs.flg_type = def_interv.flg_type
                          AND idcs.id_software = def_interv.id_software
                          AND (idcs.id_institution = i_institution OR
                          (idcs.id_institution IS NULL AND i_institution IS NULL))
                          AND (idcs.id_dep_clin_serv = i_dcs OR (idcs.id_dep_clin_serv IS NULL AND i_dcs IS NULL))),
                   0)
        INTO   l_res
        FROM   dual;
    
        RETURN l_res;
    END get_idcs_dest_id;

BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner,
                         NAME  => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_yes           := pk_alert_constant.g_yes;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
    g_generic     := 0;
END pk_default_inst_preferences;
/
