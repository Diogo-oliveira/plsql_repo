/*-- Last Change Revision: $Rev: 2055295 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-16 11:19:18 +0000 (qui, 16 fev 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_woman_health IS

    e_call_error EXCEPTION;

    /**######################################################
      Private Functions
    ######################################################**/

    /**
    * Gets the configuration variables: institution and software
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diag_type                 Diagnosis type
    * @param   i_conf_type                 Diagnosis configuration area: G - pregnancy area
    * @param   o_inst                      institution id
    * @param   o_soft                      software id
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Jos� Silva
    * @version v2.6.1
    * @since   13-02-2012
    */
    FUNCTION get_cfg_vars
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_inst     OUT institution.id_institution%TYPE,
        o_soft     OUT software.id_software%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_CFG_VARS';
        --
    
    BEGIN
    
        BEGIN
            g_error := 'GET VITAL_SIGN CFG_VARS';
            pk_alertlog.log_debug(g_error);
            SELECT id_institution, id_software
              INTO o_inst, o_soft
              FROM (SELECT vsi.id_institution,
                           vsi.id_software,
                           row_number() over(ORDER BY decode(vsi.id_institution, i_prof.institution, 1, 2), decode(vsi.id_software, i_prof.software, 1, 2)) line_number
                      FROM vs_soft_inst vsi
                     INNER JOIN vital_sign vs
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                     WHERE vsi.id_software IN (i_prof.software, 0)
                       AND vsi.id_institution IN (i_prof.institution, 0)
                       AND vsi.flg_view = i_flg_view)
             WHERE line_number = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_inst := i_prof.institution;
                o_soft := i_prof.software;
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_cfg_vars;

    /************************************************************************************************************
    * Returns information specif for vaccines, like status, administration and doses.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    *
    * @param      o_vaccines_status    cursor with vaccines status
    * @param      o_vaccines_admin     cursor with vaccines administration information
    * @param      o_vaccines_dose      cursor with vaccines doses information
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/14
    ***********************************************************************************************************/

    FUNCTION get_vaccines_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN time_event_group.intern_name%TYPE,
        
        i_patient         IN patient.id_patient%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vaccines_status OUT pk_types.cursor_type,
        o_vaccines_admin  OUT pk_types.cursor_type,
        o_vaccines_dose   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_dose_other sys_domain.val%TYPE := 'O';
    
    BEGIN
    
        -----------------------------------------
        -- VACINAS INFO
        -----------------------------------------
    
        -- cursor so para estados
        g_error := 'GET CURSOR O_VACC_STATUS';
        OPEN o_vaccines_status FOR
            SELECT vs.flg_status,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_VACCINE_STATUS', vs.flg_status, i_lang) flg_status_desc,
                   vdt.medid,
                   vdesc.icon,
                   vdt.id_vaccine_det,
                   pk_translation.get_translation(i_lang, v.code_vaccine) name_vs
              FROM vaccine v, vaccine_det vdt, vaccine_status vs, vaccine_desc vdesc --, SYS_MESSAGE SM
             WHERE to_char(v.id_vaccine) = vdt.medid
               AND vdesc.id_vaccine = v.id_vaccine
               AND vdesc.value(+) = vs.flg_status
               AND vdt.id_patient = i_patient
               AND vdt.id_vaccine_det = vs.id_vaccine_det(+)
               AND vs.flg_active = 'A'
             ORDER BY name_vs;
    
        -- CURSOR SO PARA AS ADMINS
        g_error := 'GET CURSOR O_VACC_ADMINS';
        OPEN o_vaccines_admin FOR
            SELECT v.id_vaccine,
                   vd.n_dose,
                   pk_date_utils.date_send_tsz(i_lang, vda.dt_admin_tstz, i_prof) dt_admin,
                   pk_date_utils.date_chr_short_read(i_lang, vda.dt_admin_tstz, i_prof) dt_admin_chr,
                   vd.medid,
                   vd.n_dose ||
                   nvl(pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER', vd.n_dose, i_lang),
                       pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER', l_domain_dose_other, i_lang)) desc_dose,
                   vdt.id_vaccine_det
              FROM vaccine v, vaccine_dose vd, vaccine_dose_admin vda, vaccine_det vdt --, SYS_MESSAGE SM
             WHERE to_char(v.id_vaccine) = vd.medid
               AND vdt.medid = vd.medid
               AND vd.id_vaccine_dose = vda.id_vaccine_dose
               AND vdt.id_patient = i_patient
               AND vdt.id_vaccine_det(+) = vda.id_vaccine_det;
    
        -- CURSOR SO PARA AS DOSES
        g_error := 'GET CURSOR O_VACC_DOSE';
        OPEN o_vaccines_dose FOR
            SELECT v.id_vaccine,
                   vd.n_dose,
                   vd.medid,
                   nvl(pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER', vd.n_dose, i_lang),
                       pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER', l_domain_dose_other, i_lang)) desc_dose
              FROM vaccine v, vaccine_dose vd
             WHERE to_char(v.id_vaccine) = vd.medid;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VACCINES_INFO',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vaccines_status);
            pk_types.open_my_cursor(o_vaccines_admin);
            pk_types.open_my_cursor(o_vaccines_dose);
            RETURN FALSE;
    END get_vaccines_info;

    /************************************************************************************************************
    * Gets a formatted value to be used in the periodic observation grid
    *
    * @param      i_lang     language
    * @param      i_prof     profisisonal
    * @param      i_value    value to be formatted
    *
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Jos� Silva
    * @version    0.1
    * @since      2010/09/10
    ***********************************************************************************************************/
    FUNCTION get_formatted_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_decimal_symb sys_config.value%TYPE;
        l_format_value VARCHAR2(100);
    BEGIN
        l_decimal_symb := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
    
        l_format_value := REPLACE(REPLACE(i_value, '.', l_decimal_symb), ',', l_decimal_symb);
    
        IF substr(l_format_value, 1, 1) = l_decimal_symb
        THEN
            l_format_value := '0' || l_format_value;
        END IF;
    
        RETURN l_format_value;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_formatted_value;

    /************************************************************************************************************
    * Get the usual values for the specified parameter (analysis, vaccines) or for all parameters when
    * i_id_event is null
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    * @param      i_id_event           parameter's id
    *
    * @param      o_usual_val          cursor with usual values for all parameters
    * @param      o_usual_val_str      usual value as a String, for the specified i_id_event parameter
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/20
    ***********************************************************************************************************/
    FUNCTION get_usual_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_intern_name    IN time_event_group.intern_name%TYPE,
        i_patient        IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy  IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_event       IN event.id_group%TYPE,
        o_usual_val      OUT pk_types.cursor_type,
        o_usual_val_str  OUT VARCHAR2,
        o_usual_icon_str OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_usual_value_str VARCHAR2(100) := NULL;
        l_usual_icon_str  VARCHAR2(100) := NULL;
    
    BEGIN
    
        IF i_id_event IS NULL
        THEN
            -----------------------------------------
            -- VALORES HABITUAIS INFO
            -----------------------------------------
            g_error := 'GET CURSOR O_VAL_HABIT';
            OPEN o_usual_val FOR
            
                SELECT DISTINCT emf.id_group id_vital_sign,
                                emf.flg_group,
                                e.flg_most_freq,
                                decode(nvl(e.flg_most_freq, 'N'),
                                       'N',
                                       sm.desc_message,
                                       get_formatted_value(i_lang, i_prof, emf.value)) VALUE,
                                decode(emf.value, NULL, NULL, adesc.icon) icon,
                                adesc.value flg_value
                  FROM event_most_freq  emf,
                       event            e,
                       event_group      eg,
                       time_event_group teg,
                       sys_message      sm,
                       analysis_desc    adesc
                 WHERE emf.id_pat_pregnancy = i_pat_pregnancy
                   AND emf.id_patient = i_patient
                   AND e.id_group = emf.id_group
                   AND e.flg_group = emf.flg_group
                   AND e.id_event_group = eg.id_event_group
                   AND teg.id_event_group = eg.id_event_group
                   AND teg.intern_name = i_intern_name
                   AND sm.code_message = 'COMMON_M018'
                   AND sm.id_language = i_lang
                   AND (adesc.id_analysis = e.id_group OR adesc.id_analysis IS NULL)
                   AND e.flg_group = 'A'
                   AND pk_translation.get_translation(i_lang, adesc.code_analysis_desc(+)) = emf.value
                
                UNION
                
                SELECT emf.id_group id_vital_sign,
                       emf.flg_group,
                       e.flg_most_freq,
                       decode(nvl(e.flg_most_freq, 'N'),
                              'N',
                              sm.desc_message,
                              get_formatted_value(i_lang, i_prof, emf.value)) VALUE,
                       NULL icon,
                       NULL flg_value
                  FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
                
                 WHERE emf.id_pat_pregnancy = i_pat_pregnancy
                   AND emf.id_patient = i_patient
                   AND e.id_group = emf.id_group
                   AND e.flg_group = emf.flg_group
                   AND e.id_event_group = eg.id_event_group
                   AND teg.id_event_group = eg.id_event_group
                   AND teg.intern_name = i_intern_name
                   AND sm.code_message = 'COMMON_M018'
                   AND sm.id_language = i_lang
                   AND e.flg_group = 'VS';
        ELSE
            -----------------------------------------
            -- VALORES HABITUAIS INFO
            -----------------------------------------
            g_error := 'GET CURSOR O_VAL_HABIT';
            OPEN o_usual_val FOR
                SELECT DISTINCT decode(nvl(e.flg_most_freq, 'N'),
                                       'N',
                                       sm.desc_message,
                                       get_formatted_value(i_lang, i_prof, emf.value)) usual_value,
                                decode(emf.value, NULL, NULL, adesc.icon) icon
                  FROM event_most_freq emf,
                       event e,
                       event_group eg,
                       time_event_group teg,
                       sys_message sm,
                       (SELECT ad.id_analysis,
                               pk_translation.get_translation(i_lang, ad.code_analysis_desc) desc_value,
                               ad.icon
                          FROM analysis_desc ad
                         WHERE ad.id_analysis = i_id_event) adesc
                 WHERE emf.id_group = i_id_event
                   AND emf.id_pat_pregnancy = i_pat_pregnancy
                   AND emf.id_patient = i_patient
                   AND e.id_group = emf.id_group
                   AND e.flg_group = emf.flg_group
                   AND e.id_event_group = eg.id_event_group
                   AND teg.id_event_group = eg.id_event_group
                   AND teg.intern_name = i_intern_name
                   AND sm.code_message = 'COMMON_M018'
                   AND sm.id_language = i_lang
                   AND e.flg_group = 'A'
                   AND (adesc.id_analysis = e.id_group OR adesc.id_analysis IS NULL)
                   AND adesc.desc_value(+) = emf.value
                
                UNION
                
                SELECT decode(nvl(e.flg_most_freq, 'N'),
                              'N',
                              sm.desc_message,
                              get_formatted_value(i_lang, i_prof, emf.value)) usual_value,
                       NULL icon
                  FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
                 WHERE emf.id_group = i_id_event
                   AND emf.id_pat_pregnancy = i_pat_pregnancy
                   AND emf.id_patient = i_patient
                   AND e.id_group = emf.id_group
                   AND e.flg_group = emf.flg_group
                   AND e.id_event_group = eg.id_event_group
                   AND teg.id_event_group = eg.id_event_group
                   AND teg.intern_name = i_intern_name
                   AND sm.code_message = 'COMMON_M018'
                   AND sm.id_language = i_lang
                   AND e.flg_group = 'VS';
        
            --S� temos um valor habitual por cada parametro
            FETCH o_usual_val
                INTO l_usual_value_str, l_usual_icon_str;
        
            -- ! Pode ser null
            o_usual_val_str  := l_usual_value_str;
            o_usual_icon_str := l_usual_icon_str;
        
            --close do cursor porque n�o vai ser mais necess�rio
            CLOSE o_usual_val;
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
                                              'GET_USUAL_VALUES',
                                              o_error);
            pk_types.open_my_cursor(o_usual_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_usual_values;

    /************************************************************************************************************
    * Get the usual values for the specified parameter (analysis, vaccines) as a string
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    * @param      i_id_event           parameter's id
    *
    * @param      o_error              error message
    *
    * @return     the usual value for the specified i_id_event parameter
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/20
    ***********************************************************************************************************/
    FUNCTION get_usual_values_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_event      IN event.id_group%TYPE,
        i_is_icon       IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_usual_value_str VARCHAR2(100) := NULL;
        l_usual_icon_str  VARCHAR2(100) := NULL;
        --error message
    
        l_usual_val   pk_types.cursor_type;
        l_error_strut t_error_out;
    
    BEGIN
    
        IF NOT get_usual_values(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_intern_name    => i_intern_name,
                                i_patient        => i_patient,
                                i_pat_pregnancy  => i_pat_pregnancy,
                                i_id_event       => i_id_event,
                                o_usual_val      => l_usual_val,
                                o_usual_val_str  => l_usual_value_str,
                                o_usual_icon_str => l_usual_icon_str,
                                o_error          => l_error_strut)
        THEN
            RETURN NULL;
        END IF;
    
        IF i_is_icon = 'Y'
        THEN
            RETURN l_usual_icon_str;
        ELSE
            RETURN l_usual_value_str;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                       'PK_WOMAN_HEALTH.GET_USUAL_VALUES_STR / ' || g_error || ' / ' || SQLERRM;
            RETURN NULL;
    END get_usual_values_str;

    /**######################################################
      End of Private Functions
    ######################################################**/

    FUNCTION get_time_event_axis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_flg_screen    IN VARCHAR2,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter todos os events activos registados para a gr�vida e respectivas datas de registo
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PATIENT - ID do paciente
                                 I_PROF - ID do profissional
                                 I_FLG_SCREEN - (S) Summary, (G) Graph ou (D) Detail;
                                        Para os valores que n�o D, mostra s� os ativos e n�o os cancelados
                                 I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP (ex: WOMAN_HEALTH_DET)
                                 I_PAT_PREGNANCY - ID da gravidez
                        Saida: O_TIME - Listar todas as datas onde se registaram os sinais vitais
                                 O_SIGN_V - Listar todos os events registados no tempo de gravidez
                                 O_VAL_HABIT - Valores habituais dos events
                                 O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/17
          NOTA:
        *********************************************************************************/
    
        l_flg_view VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
        l_age         vital_sign_unit_measure.age_min%TYPE;
    BEGIN
        g_error := 'GET CFG_VARS';
        IF NOT (get_cfg_vars(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_flg_view => l_flg_view,
                             o_inst     => l_institution,
                             o_soft     => l_software,
                             o_error    => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_sysdate_tstz := current_timestamp;
        ----------------------------------------------------------
        -- Intervalo de tempo parametrizados
        ----------------------------------------------------------
        g_error := 'OPEN CURSOR O_TIME';
        OPEN o_time FOR
            SELECT pk_translation.get_translation(i_lang, code_time) desc_time
              FROM TIME t, time_group tg, time_event_group teg
             WHERE teg.intern_name = i_intern_name
               AND teg.id_time_group = tg.id_time_group
               AND tg.id_time_group = t.id_time_group
             ORDER BY rank;
    
        ----------------------------------------------------------
        -- EVENTOS
        ----------------------------------------------------------
        g_error := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
        ------------------------------------------------------
        -- EVENTOS - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            e.flg_most_freq
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(i_flg_screen, 'D') = 'D')
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
                  
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            e.flg_most_freq
            
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = emf.id_group
               AND emf.flg_group = e.flg_group
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
               AND e.id_group = emf.id_group
               AND e.id_group = vs.id_vital_sign
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
                  
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_pat_pregnancy = pp.id_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- EVENTS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT vsre.id_vital_sign_parent,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            e.flg_most_freq
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg,
                   pat_pregnancy       pp
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active OR nvl(i_flg_screen, 'D') = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- EVENTS - An�lises
            ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', vs.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            (SELECT e.flg_most_freq
                               FROM event e, event_group eg, time_event_group teg
                              WHERE teg.intern_name = i_intern_name
                                AND teg.id_event_group = eg.id_event_group
                                AND eg.id_event_group = e.id_event_group
                                AND e.flg_group = 'A'
                                AND e.id_group = vs.id_analysis) flg_most_freq
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND vsi.flg_type = 'M'
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT vs.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', vs.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            (SELECT e.flg_most_freq
                               FROM event e, event_group eg, time_event_group teg
                              WHERE teg.intern_name = i_intern_name
                                AND teg.id_event_group = eg.id_event_group
                                AND eg.id_event_group = e.id_event_group
                                AND e.flg_group = 'A'
                                AND e.id_group = vs.id_analysis) flg_most_freq
            
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.flg_type = 'M'
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_pat_pregnancy = pp.id_pat_pregnancy
            UNION
            ------------------------------------------------------
            -- EVENTS - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vaccine,
                            pk_translation.get_translation(i_lang, vs.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            vs.rank,
                            1 val_min,
                            2 val_max,
                            '0xFFFFFF' color_grafh,
                            '0xCCCCCC' color_text,
                            'N.A.' desc_unit_measure,
                            e.flg_group,
                            e.flg_most_freq
              FROM vaccine          vs,
                   vaccine_dose     ar,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY rank, flg_group ASC;
    
        ----------------------------------------------------------
        -- Valores Habituais
        -- TODO: Valores habituais poderiam vir no O_TIME
        ----------------------------------------------------------
    
        OPEN o_val_habit FOR
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, vdesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   vaccine_desc     vdesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
                  
               AND (vdesc.id_vaccine(+) = e.id_group AND e.flg_group = 'V' AND
                   (vdesc.id_vaccine_desc IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, adesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   analysis_desc    adesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
                  
               AND (adesc.id_analysis(+) = e.id_group AND e.flg_group = 'A' AND
                   (adesc.id_analysis IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, adesc.code_analysis_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   NULL icon
              FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
                  
               AND e.flg_group = 'VS';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_AXIS',
                                              o_error);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_time_event_axis;

    FUNCTION get_time_event_all
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_flg_screen    IN VARCHAR2,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Retorna para cada data de registo / event do epis�dio, os valores,
                      sendo estes visualizados numa grelha
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                    I_PATIENT - ID do epis�dio
                                    I_PROF - Trinomio do profissional
                                    I_FLG_SCREEN - (S) Summary, (G) Graph ou (D) Detail;
                                        Para os valores que n�o D, mostra s� os ativos e n�o os cancelados
                                    I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP
                                    I_PAT_PREGNANCY - ID da gravidez
                        Saida: O_VAL_VS - Array para cada event / tempo de leitura, os respectivos valores
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2006/12/12
        
          NOTA:
        *********************************************************************************/
    
        --
        i NUMBER := 0;
    
        l_value     VARCHAR2(20);
        l_sinal     VARCHAR2(20) := 'FALSE';
        l_array_val VARCHAR2(4000) := NULL;
        l_sep       VARCHAR2(1) := ';';
    
        l_time  VARCHAR2(200);
        l_time2 VARCHAR2(200);
    
        l_cont     NUMBER;
        l_reg_cont NUMBER;
    
        l_temp       VARCHAR2(2000);
        l_temp2      VARCHAR2(2000);
        l_glasgow    NUMBER;
        l_rel_domain vital_sign_relation.relation_domain%TYPE;
    
        l_flg_view VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
        ----------------------------------------------------------
        -- Tempos parametrizados
        ----------------------------------------------------------
        CURSOR c_time IS
            SELECT pk_translation.get_translation(i_lang, t.code_time) desc_time, val_max, val_min
              FROM TIME t, time_group tg, time_event_group teg
             WHERE teg.intern_name = i_intern_name
               AND teg.id_time_group = tg.id_time_group
               AND tg.id_time_group = t.id_time_group
             ORDER BY rank;
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
    
        ----------------------------------------------------------
        -- EVENTOS
        ----------------------------------------------------------
        CURSOR c_vital IS
        ------------------------------------------------------
        -- EVENTOS - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign, vsi.rank, e.flg_group
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR i_flg_screen = 'D')
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
                  -- Jos� Brito 19/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                  --
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND trunc(vsr.dt_vital_sign_read_tstz) BETWEEN l_dt_aux AND l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            -- vs mais frequentes
            SELECT DISTINCT vs.id_vital_sign, vsi.rank, e.flg_group
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = e.id_group
               AND e.id_group = emf.id_group
               AND emf.flg_group = e.flg_group
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND emf.id_pat_pregnancy = i_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- EVENTOS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT vsre.id_vital_sign_parent, vsi.rank, e.flg_group
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active OR i_flg_screen = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND trunc(vsr.dt_vital_sign_read_tstz) BETWEEN l_dt_aux AND l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- EVENTOS - An�lises
            ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis, NULL rank, e.flg_group --VSI.RANK
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND vsr.desc_analysis_result IS NOT NULL
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.flg_type = 'M'
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND trunc(vsr.dt_analysis_result_par_tstz) BETWEEN l_dt_aux AND l_dt_aux + g_weeks_gest * g_days_in_week
            UNION
            -- analises mais frequentes
            SELECT DISTINCT vs.id_analysis, NULL rank, e.flg_group
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND emf.id_pat_pregnancy = i_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- EVENTOS - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vaccine, vs.rank, e.flg_group
              FROM vaccine vs, vaccine_det vd, vaccine_status vst, event e, event_group eg, time_event_group teg
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
                  -- todo: valida�ao se e cancelado!!!
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
                  
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND trunc(vst.dt_vaccine_status_tstz) BETWEEN l_dt_aux AND l_dt_aux + g_weeks_gest * g_days_in_week
            
             ORDER BY rank, flg_group ASC;
    
        ----------------------------------------------------------
        -- VALORES: SINAIS VITAIS
        ----------------------------------------------------------
        CURSOR c_values_vs
        (
            i_vital_sign    NUMBER,
            i_data_read     CHAR,
            i_data_read_min CHAR
        ) IS
        
            SELECT *
              FROM ( ------------------------------------------------------
                    -- VALORES - Sinais Vitais Simples
                    ------------------------------------------------------
                    SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt,
                            decode(vsr.id_unit_measure,
                                    vsi.id_unit_measure,
                                    decode(vsr.value,
                                           NULL,
                                           pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                           -- converter n�meros decimais entre -1 e 1
                                           CASE
                                               WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                                decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                               ELSE
                                                to_char(vsr.value)
                                           END),
                                    nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                                        vsr.id_unit_measure,
                                                                                        vsi.id_unit_measure)),
                                        decode(vsr.value,
                                               NULL,
                                               pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                               -- converter n�meros decimais entre -1 e 1
                                               CASE
                                                   WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                                    decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                                   ELSE
                                                    to_char(vsr.value)
                                               END))) VALUE,
                            vsr.id_vital_sign_read,
                            '' relation_domain,
                            trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - l_dt_aux) / g_days_in_week) || '|' ||
                            decode(trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - l_dt_aux) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || nvl(vdesc.icon, 'X') header_desc,
                            e.flg_group,
                            decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg
                      FROM vital_sign_read  vsr,
                            vital_sign       vs,
                            vs_soft_inst     vsi,
                            vital_sign_desc  vdesc,
                            event            e,
                            event_group      eg,
                            time_event_group teg
                     WHERE vs.id_vital_sign = vsr.id_vital_sign
                       AND vs.flg_available = g_vs_avail
                       AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                                      FROM vital_sign_relation vr
                                                     WHERE vr.relation_domain = g_vs_rel_sum)
                       AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                           OR nvl(i_flg_screen, 'D') = 'D')
                       AND vsr.id_vital_sign = i_vital_sign
                       AND vsi.id_vital_sign = vs.id_vital_sign
                       AND vsi.id_software = l_software
                       AND vsi.id_institution = l_institution
                       AND vsi.flg_view = l_flg_view
                          -- Jos� Brito 19/12/2008 ALERT-9992
                          -- Support for vital signs selected in multichoice
                       AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                       AND vdesc.flg_available(+) = 'Y'
                       AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                          --
                       AND vsr.id_patient = i_patient
                       AND e.flg_group = 'VS'
                       AND teg.intern_name = i_intern_name
                       AND teg.id_event_group = eg.id_event_group
                       AND eg.id_event_group = e.id_event_group
                       AND e.id_group = vsr.id_vital_sign
                       AND vsr.value IS NOT NULL
                          -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
                       AND trunc(vsr.dt_vital_sign_read_tstz) BETWEEN l_dt_aux + i_data_read_min AND
                           least(l_dt_aux + g_weeks_gest * g_days_in_week, l_dt_aux + i_data_read)
                    UNION ALL
                    ------------------------------------------------------
                    -- VALORES - Sinais Vitais Compostos
                    ------------------------------------------------------
                    SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt,
                            (SELECT vs2.value
                               FROM vital_sign_read vs2, vital_sign_relation vsr2
                              WHERE vs2.id_patient = i_patient
                                AND vsr2.id_vital_sign_parent = vr.id_vital_sign_parent
                                AND vsr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                AND vs2.dt_vital_sign_read_tstz = vsr.dt_vital_sign_read_tstz
                                AND vs2.id_vital_sign = vsr2.id_vital_sign_detail
                                AND vs2.id_vital_sign = (SELECT id_vital_sign_detail
                                                           FROM vital_sign_relation
                                                          WHERE id_vital_sign_parent = vsr2.id_vital_sign_parent
                                                            AND relation_domain != pk_alert_constant.g_vs_rel_percentile
                                                            AND rank = 1)) || '/' ||
                            (SELECT vs2.value
                               FROM vital_sign_read vs2, vital_sign_relation vsr2
                              WHERE vs2.id_patient = i_patient
                                AND vsr2.id_vital_sign_parent = vr.id_vital_sign_parent
                                AND vsr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                AND vs2.dt_vital_sign_read_tstz = vsr.dt_vital_sign_read_tstz
                                AND vs2.id_vital_sign = vsr2.id_vital_sign_detail
                                AND vs2.id_vital_sign = (SELECT id_vital_sign_detail
                                                           FROM vital_sign_relation
                                                          WHERE id_vital_sign_parent = vsr2.id_vital_sign_parent
                                                            AND relation_domain != pk_alert_constant.g_vs_rel_percentile
                                                            AND rank = 2)) VALUE,
                            vsr.id_vital_sign_read,
                            vr.relation_domain,
                            trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - l_dt_aux) / g_days_in_week) || '|' ||
                            decode(trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - l_dt_aux) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|X' header_desc,
                            e.flg_group,
                            decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg
                      FROM vital_sign_relation vr, vital_sign_read vsr, event e, event_group eg, time_event_group teg
                     WHERE (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                           OR nvl(i_flg_screen, 'D') = 'D')
                       AND vr.id_vital_sign_detail = vsr.id_vital_sign
                       AND vr.id_vital_sign_parent = i_vital_sign
                       AND vr.relation_domain = g_vs_rel_conc
                       AND vsr.id_patient = i_patient
                       AND e.flg_group = 'VS'
                       AND teg.intern_name = i_intern_name
                       AND teg.id_event_group = eg.id_event_group
                       AND eg.id_event_group = e.id_event_group
                       AND e.id_group = vr.id_vital_sign_parent
                       AND vsr.value IS NOT NULL
                          -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
                       AND trunc(vsr.dt_vital_sign_read_tstz) BETWEEN l_dt_aux + i_data_read_min AND
                           least(l_dt_aux + g_weeks_gest * g_days_in_week, l_dt_aux + i_data_read)
                     ORDER BY dt DESC)
             WHERE rownum = 1;
    
        ----------------------------------------------------------
        -- VALORES: AN�LISES
        ----------------------------------------------------------
        CURSOR c_values_a
        (
            i_vital_sign    NUMBER,
            i_data_read     CHAR,
            i_data_read_min CHAR
        ) IS
        
            SELECT *
              FROM ( ------------------------------------------------------
                    -- VALORES - An�lises
                    ------------------------------------------------------
                    SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) dt,
                            vsr.desc_analysis_result VALUE,
                            vsr.id_analysis_result_par id_vital_sign_read,
                            '' relation_domain,
                            trunc((CAST(vsr.dt_analysis_result_par_tstz AS DATE) - l_dt_aux) / g_days_in_week) || '|' ||
                            decode(trunc((CAST(vsr.dt_analysis_result_par_tstz AS DATE) - l_dt_aux) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || nvl(adesc.icon, 'X') header_desc,
                            e.flg_group,
                            'A' reg,
                            (SELECT a.value
                               FROM abnormality a
                              WHERE a.id_abnormality = vsr.id_abnormality) abnorm
                      FROM analysis_result_par         vsr,
                            analysis                    vs,
                            analysis_result             ar,
                            analysis_desc               adesc,
                            analysis_param              apar,
                            analysis_param_funcionality vsi,
                            event                       e,
                            event_group                 eg,
                            time_event_group            teg
                     WHERE vs.flg_available = g_vs_avail
                       AND apar.id_analysis = i_vital_sign
                       AND vsi.id_analysis_param = apar.id_analysis_param
                       AND apar.flg_available = g_vs_avail
                       AND vsi.flg_type = 'M'
                       AND apar.id_analysis = vs.id_analysis
                       AND apar.id_software = i_prof.software
                       AND apar.id_institution = i_prof.institution
                          -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
                       AND adesc.id_analysis(+) = vs.id_analysis
                       AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                           to_char(vsr.desc_analysis_result))
                          -- para incidir sobre os parametros de analise
                       AND apar.id_analysis = vs.id_analysis
                       AND vsr.id_analysis_parameter = apar.id_analysis_parameter
                       AND ar.id_patient = i_patient
                       AND e.flg_group = 'A'
                       AND teg.intern_name = i_intern_name
                       AND teg.id_event_group = eg.id_event_group
                       AND eg.id_event_group = e.id_event_group
                       AND e.id_group = vs.id_analysis
                       AND ar.id_analysis_result = vsr.id_analysis_result
                          -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
                       AND trunc(vsr.dt_analysis_result_par_tstz) BETWEEN l_dt_aux + i_data_read_min AND
                           least(l_dt_aux + g_weeks_gest * g_days_in_week, l_dt_aux + i_data_read)
                     ORDER BY dt DESC)
             WHERE rownum = 1;
    
        ----------------------------------------------------------
        -- VALORES: VACINAS
        ----------------------------------------------------------
        CURSOR c_values_v
        (
            i_vital_sign    NUMBER,
            i_data_read     CHAR,
            i_data_read_min CHAR
        ) IS
        
            SELECT *
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt,
                           pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) VALUE,
                           vst.id_vaccine_status id_vital_sign_read,
                           '' relation_domain,
                           trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - l_dt_aux) / g_days_in_week) || '|' ||
                           decode(trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - l_dt_aux) / 7),
                                  1,
                                  pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                  pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || vdesc.icon header_desc,
                           e.flg_group,
                           vst.flg_active reg
                      FROM vaccine          vs,
                           vaccine_det      vd,
                           vaccine_status   vst,
                           vaccine_desc     vdesc,
                           event            e,
                           event_group      eg,
                           time_event_group teg
                     WHERE vs.flg_available = g_vs_avail
                       AND to_char(vs.id_vaccine) = vd.medid
                          -- todo: nao filtra por cancelados!!!!
                       AND vs.id_vaccine = i_vital_sign
                       AND vd.id_patient = i_patient
                       AND vd.id_vaccine_det = vst.id_vaccine_det
                       AND vdesc.id_vaccine = vs.id_vaccine
                       AND vdesc.value = vst.flg_status
                       AND e.flg_group = 'V'
                       AND teg.intern_name = i_intern_name
                       AND teg.id_event_group = eg.id_event_group
                       AND eg.id_event_group = e.id_event_group
                       AND e.id_group = vs.id_vaccine
                          -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
                       AND trunc(vst.dt_vaccine_status_tstz) BETWEEN l_dt_aux + i_data_read_min AND
                           least(l_dt_aux + g_weeks_gest * g_days_in_week, l_dt_aux + i_data_read)
                     ORDER BY dt DESC)
             WHERE rownum = 1;
    
        l_aux_dt                 VARCHAR2(50);
        l_aux_value              VARCHAR2(50);
        l_aux_id_vital_sign_read NUMBER;
        l_aux_relation_domain    VARCHAR2(50);
        l_aux_header_desc        VARCHAR2(50);
        l_aux_flg_group          VARCHAR2(50);
        l_aux_reg                VARCHAR2(50);
        l_aux_abnormality        VARCHAR2(50);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'INICIALIZA��O';
        o_val_vs       := table_varchar(); -- inicializa��o do vector
        g_error        := 'GET CURSOR C_VITAL';
        pk_alertlog.log_debug('DATE ' || to_char(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
    
        g_error := 'GET CFG_VARS';
        IF NOT (get_cfg_vars(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_flg_view => l_flg_view,
                             o_inst     => l_institution,
                             o_soft     => l_software,
                             o_error    => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'OPEN C_PAT_PREGN';
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        FOR r_vital IN c_vital
        LOOP
        
            IF l_sinal = 'TRUE'
            THEN
            
                -- nova linha para o ARRAY
            
                o_val_vs(i) := l_array_val || l_sep;
            
            END IF;
        
            i := i + 1;
        
            o_val_vs.extend; -- o array O_VAL_VS tem mais uma linha
            l_array_val := NULL;
        
            IF l_array_val IS NULL
            THEN
            
                l_array_val := r_vital.id_vital_sign || l_sep;
            
            END IF;
        
            g_error := 'GET CURSOR C_TIME';
        
            FOR r_time IN c_time
            LOOP
            
                l_time  := r_time.val_max;
                l_time2 := r_time.val_min;
            
                l_value := 'FALSE';
                g_error := 'GET CURSOR C_REG';
            
                l_cont     := 0;
                l_reg_cont := 0;
            
                -- ALERT-282398 - RESET VARS
                l_aux_dt                 := NULL;
                l_aux_value              := NULL;
                l_aux_id_vital_sign_read := NULL;
                l_aux_relation_domain    := NULL;
                l_aux_header_desc        := NULL;
                l_aux_flg_group          := NULL;
                l_aux_reg                := NULL;
                l_aux_abnormality        := NULL;
            
                g_error := 'GET CURSOR C_VALUES' || r_vital.id_vital_sign || '-' || l_time;
            
                IF r_vital.flg_group = 'VS'
                THEN
                
                    g_error := 'OPEN c_values_VS';
                    OPEN c_values_vs(r_vital.id_vital_sign, l_time, l_time2);
                    FETCH c_values_vs
                        INTO l_aux_dt,
                             l_aux_value,
                             l_aux_id_vital_sign_read,
                             l_aux_relation_domain,
                             l_aux_header_desc,
                             l_aux_flg_group,
                             l_aux_reg;
                    CLOSE c_values_vs;
                
                ELSIF r_vital.flg_group = 'A'
                THEN
                
                    g_error := 'OPEN c_values_A';
                    OPEN c_values_a(r_vital.id_vital_sign, l_time, l_time2);
                    FETCH c_values_a
                        INTO l_aux_dt,
                             l_aux_value,
                             l_aux_id_vital_sign_read,
                             l_aux_relation_domain,
                             l_aux_header_desc,
                             l_aux_flg_group,
                             l_aux_reg,
                             l_aux_abnormality;
                    CLOSE c_values_a;
                
                ELSIF r_vital.flg_group = 'V'
                THEN
                
                    g_error := 'OPEN c_values_V';
                    OPEN c_values_v(r_vital.id_vital_sign, l_time, l_time2);
                    FETCH c_values_v
                        INTO l_aux_dt,
                             l_aux_value,
                             l_aux_id_vital_sign_read,
                             l_aux_relation_domain,
                             l_aux_header_desc,
                             l_aux_flg_group,
                             l_aux_reg;
                    CLOSE c_values_v;
                
                END IF;
            
                g_error := 'GET CURSOR C_VALUES LOOP';
            
                l_rel_domain := l_aux_relation_domain;
            
                IF l_cont = 0
                THEN
                
                    l_temp  := l_aux_value;
                    l_temp2 := l_aux_id_vital_sign_read;
                
                    IF l_aux_relation_domain = g_vs_rel_sum
                    THEN
                        l_array_val := l_array_val || l_aux_id_vital_sign_read || '|' || l_aux_reg || '|';
                        l_glasgow   := nvl(l_glasgow, 0) + l_aux_value;
                    ELSE
                        l_array_val := l_array_val || l_aux_id_vital_sign_read || '|' || l_aux_reg || '|' ||
                                       l_aux_value || '|' || l_aux_header_desc || '|' || l_aux_abnormality;
                    END IF;
                
                    l_value := 'TRUE';
                
                ELSIF l_cont = 1
                      AND l_aux_relation_domain = g_vs_rel_conc
                THEN
                
                    l_array_val := l_array_val || '/' || l_aux_value; -- || L_SEP;
                
                ELSIF l_cont = 1
                      AND l_aux_relation_domain = g_vs_rel_sum
                THEN
                
                    l_glasgow := nvl(l_glasgow, 0) + l_aux_value;
                
                ELSIF l_cont = 2
                THEN
                
                    IF l_temp2 != l_aux_id_vital_sign_read
                    THEN
                    
                        l_glasgow := nvl(l_glasgow, 0) + l_aux_value;
                    
                    END IF;
                
                END IF;
            
                l_cont := l_cont + 1;
            
                g_error := 'L_CONT IF';
            
                IF l_cont IN (1, 2, 3)
                THEN
                    IF l_rel_domain = g_vs_rel_sum
                    THEN
                        l_array_val := l_array_val || to_char(l_glasgow);
                    END IF;
                
                    l_array_val := l_array_val || l_sep; --TESTE
                END IF;
            
                IF l_value = 'FALSE'
                THEN
                
                    l_array_val := l_array_val || l_sep; --teste
                
                END IF;
            END LOOP;
        
            l_sinal := 'TRUE';
        
        END LOOP;
    
        IF l_sinal = 'TRUE'
        THEN
        
            -- nova linha para o ARRAY
            o_val_vs(i) := l_array_val || l_sep;
        
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_ALL',
                                              o_error);
            o_val_vs := table_varchar();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    FUNCTION get_pat_pregnancy_type
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os tipos de gravidezes poss�veis
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTA:
        *********************************************************************************/
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT sd.desc_val, sd.val, sd.img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                  i_prof,
                                                                  'PAT_PREGN_FETUS.FLG_CHILDBIRTH_TYPE',
                                                                  NULL)) sd;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREGNANCY_TYPE',
                                              o_error);
        
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_pregnancy_time
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os tipos de gravidezes (em curso ou anterior)
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTA:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT desc_val, val
              FROM sys_domain
             WHERE code_domain = 'WOMAN_HEALTH.FLG_CURRENT'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND flg_available = 'Y'
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREGNANCY_TIME',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_pregnancy_abbort
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os tipos de gravidezes (em curso ou anterior)
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTA:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT sd.desc_val, sd.val
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'PAT_PREGNANCY.FLG_STATUS', NULL)) sd;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREGNANCY_ABBORT',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_patient              patient.id_patient%TYPE,
        i_pat_pregnancy        pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_last_menstruation pat_pregnancy.dt_last_menstruation%TYPE,
        i_dt_childbirth        DATE,
        i_n_pregnancy          pat_pregnancy.n_pregnancy%TYPE,
        i_flg_childbirth_type  VARCHAR2, --pat_pregnancy.flg_childbirth_type%TYPE,
        i_n_children           pat_pregnancy.n_children%TYPE,
        i_flg_abbort           VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_active           IN VARCHAR2,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_cdr_call             IN cdr_event.id_cdr_call%TYPE, --ALERT-175003
        o_msg                  OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_flg_show             OUT VARCHAR2,
        o_button               OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Criar nova gravidez ou actualizar gravidez existente
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do paciente
                                I_DT_LAST_MENSTRUATION - Data da �ltima menstrua��o
                                I_DT_CHILDBIRTH - Data do Parto
                                I_N_PREGNANCY - N�mero da gravidez
                                I_FLG_CHILDBIRTH_TYPE - Tipo da gravidez (ectoccica ou cesariana)
                                I_N_CHILDREN - N� de nados-vivos
                                I_FLG_ABBORT - Se � aborto ou gravidez ect�pica
                                I_FLG_ACTIVE - Se � gravidez anterior ou em curso
                                I_PROF - Profissional
                                I_ID_EPISODE - ID do epis�dio
                        Saida:  O_MSG - Mensagem a apresentar
                                O_MSG_TITLE - T�tulo da ensagem a apresentar
                                O_FLG_SHOW - Mostrar ou n�o ao utilizador
                                O_BUTTON - Tipo de bot�o a apresentar
                                O_ERROR - erro
        
          CRIA��O: RdSN 2007/01/30
          NOTAS:
        *********************************************************************************/
    
        l_childbirth_type    table_varchar := table_varchar();
        l_child_status       table_varchar := table_varchar();
        l_child_gender       table_varchar := table_varchar();
        l_child_weight       table_number := table_number();
        l_present_health     table_varchar := table_varchar();
        l_flg_present_health table_varchar := table_varchar();
        l_um_weight          table_number := table_number();
    
        l_dt_last_menstruation VARCHAR2(50);
        l_dt_childbirth        VARCHAR2(50);
    
        l_n_children pat_pregnancy.n_children%TYPE;
        l_gest_week_unk_config CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('UNKNOWN_GESTATION_AVAILABLE',
                                                                                         i_prof);
        l_flg_gest_week VARCHAR2(1 CHAR);
    BEGIN
    
        l_dt_last_menstruation := to_char(i_dt_last_menstruation, 'YYYYMMDDhh24miss');
        l_dt_childbirth        := to_char(i_dt_childbirth, 'YYYYMMDDhh24miss');
    
        IF i_n_children IS NULL
           AND i_flg_childbirth_type IS NOT NULL
        THEN
            l_n_children := 1;
        ELSE
            l_n_children := i_n_children;
        END IF;
    
        FOR i IN 1 .. nvl(l_n_children, 0)
        LOOP
            l_childbirth_type.extend;
            l_childbirth_type(i) := i_flg_childbirth_type;
        
            l_child_status.extend;
        
            IF i_flg_childbirth_type IS NOT NULL
            THEN
                l_child_status(i) := pk_pregnancy_core.g_pregn_fetus_unk;
            END IF;
        
            IF i_pat_pregnancy IS NULL
            THEN
                l_child_gender.extend;
                l_child_weight.extend;
                l_present_health.extend;
                l_flg_present_health.extend;
                l_um_weight.extend;
            END IF;
        END LOOP;
    
        IF l_dt_last_menstruation IS NULL
           AND l_gest_week_unk_config = pk_alert_constant.g_yes
        THEN
            l_flg_gest_week := 'U';
        END IF;
    
        IF NOT pk_pregnancy.set_pat_pregnancy(i_lang                 => i_lang,
                                              i_patient              => i_patient,
                                              i_pat_pregnancy        => i_pat_pregnancy,
                                              i_dt_last_menstruation => l_dt_last_menstruation,
                                              i_dt_intervention      => l_dt_childbirth,
                                              i_flg_type             => 'C',
                                              i_num_weeks            => NULL,
                                              i_num_days             => NULL,
                                              i_n_children           => l_n_children,
                                              i_flg_childbirth_type  => l_childbirth_type,
                                              i_flg_child_status     => l_child_status,
                                              i_flg_child_gender     => l_child_gender,
                                              i_flg_child_weight     => l_child_weight,
                                              i_present_health       => l_present_health,
                                              i_flg_present_health   => l_flg_present_health,
                                              i_um_weight            => l_um_weight,
                                              i_flg_complication     => '',
                                              i_notes_complication   => '',
                                              i_flg_desc_interv      => '',
                                              i_desc_intervention    => '',
                                              i_id_inst_interv       => NULL,
                                              i_notes                => '',
                                              i_flg_abortion_type    => i_flg_abbort,
                                              i_prof                 => i_prof,
                                              i_id_episode           => i_id_episode,
                                              i_flg_menses           => NULL,
                                              i_cycle_duration       => NULL,
                                              i_flg_use_constracep   => NULL,
                                              i_dt_contrac_meth_end  => NULL,
                                              i_flg_contra_precision => NULL,
                                              i_dt_pdel_lmp          => NULL,
                                              i_num_weeks_exam       => NULL,
                                              i_num_days_exam        => NULL,
                                              i_num_weeks_us         => NULL,
                                              i_num_days_us          => NULL,
                                              i_dt_pdel_correct      => NULL,
                                              i_dt_us_performed      => NULL,
                                              i_flg_del_onset        => NULL,
                                              i_del_duration         => NULL,
                                              i_flg_interv_precision => NULL,
                                              i_id_alert_diagnosis   => table_number(),
                                              i_code_state           => NULL,
                                              i_code_year            => NULL,
                                              i_code_number          => NULL,
                                              i_flg_contrac_type     => table_number(),
                                              i_notes_contrac        => NULL,
                                              i_cdr_call             => i_cdr_call,
                                              i_flg_gest_weeks       => l_flg_gest_week,
                                              o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
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
                                              'SET_PAT_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION check_current_preg
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verifica se existe alguma gravidez activa
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTA:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT sm.desc_message
              FROM pat_pregnancy pp, sys_message sm
             WHERE flg_status = 'A'
               AND sm.code_message = 'WOMAN_HEALTH_T012'
               AND sm.id_language = i_lang
               AND id_patient = i_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CURRENT_PREGNANCY',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_new_family_member
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os tipos de novos membros da familia
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTAS: Se for homem, n�o tem a op��o de Novo Rec�m-nascido
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT desc_val, val, rank
              FROM sys_domain sd, patient pat
             WHERE code_domain = 'WOMAN_HEALTH.NEW_FAMILY_MEMBER'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND pat.id_patient = i_patient
               AND pat.gender = 'F'
            
            UNION
            
            SELECT desc_val, val, rank
              FROM sys_domain sd, patient pat
             WHERE code_domain = 'WOMAN_HEALTH.NEW_FAMILY_MEMBER'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND pat.id_patient = i_patient
               AND pat.gender = 'M'
               AND sd.val <> 'B'
            
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_package_owner,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_NEW_FAMILY_MEMBER',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_newborn_fam_data
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os dados da fam�lia para o feto/recem-nascido
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/30
          NOTAS: !!!!! N�O � USADA (PARA JA!) !!!!!
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT 'I' gender,
                   0 pat_age,
                   3 id_family_relationship,
                   pk_translation.get_translation(i_lang, 'FAMILY_RELATIONSHIP.CODE_FAMILY_RELATIONSHIP.3') family_relationship,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T022') name
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEWBORN_FAM_DATA',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_newborn_fam_data;

    FUNCTION set_pat_family
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_new_patient IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar dados do paciente no que diz respeito a pertence � fam�lia da m�e
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_NEW_PATIENT - ID do novo Paciente naquela familia
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/31
          NOTAS:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'UPDATE PATIENT';
        UPDATE patient
           SET id_pat_family =
               (SELECT id_pat_family
                  FROM patient
                 WHERE id_patient = i_patient)
         WHERE id_patient = i_new_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_FAMILY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION set_pat_pregnancy_rh
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_blood_type_mother  IN VARCHAR2,
        i_blood_type_father  IN VARCHAR2,
        i_flg_antigl_aft_chb IN pat_pregnancy.flg_antigl_aft_chb%TYPE,
        i_flg_antigl_aft_abb IN pat_pregnancy.flg_antigl_aft_abb%TYPE,
        i_flg_antigl_need    IN pat_pregnancy.flg_antigl_need%TYPE,
        i_flg_confirm        IN VARCHAR2,
        i_prof               IN profissional,
        o_msg                OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Altera��o dos dados da gravidez no deepnav de RH
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_PAT_PREGNANCY - ID da gravidez
                            I_BLOOD_TYPE_MOTHER - Sangue da m�e (Rhesus + Type)
                            I_BLOOD_TYPE_FATHER - Sangue da m�e (Rhesus + Type)
                            I_FLG_ANTIGL_AFT_CHB - Antiglobulina ap�s os partos RH+
                            I_FLG_ANTIGL_AFT_ABB - Antiglobulina ap�s os abortos
                            I_FLG_ANTIGL_NEED - Antiglobulina
                            I_PROF - ID do profissional
                        Saida: O_MSG - Mensagem a mostrar
                            O_MSG_TITLE - T�tulo da mensagem a mostrar
                            O_FLG_SHOW - Y se tem mensagem a mostrar
                            O_BUTTON - Retorno para fun��o de controle do flash
                            O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/03
          NOTAS: Pode alterar o tipo de sangue da m�e, pelo que deve lan�ar uma msg de aviso
        *********************************************************************************/
    
        l_blood_mother_rh VARCHAR2(2);
        l_blood_mother_gr VARCHAR2(2);
        l_blood_rh        VARCHAR2(2);
        l_blood_gr        VARCHAR2(2);
        l_blood_father_rh VARCHAR2(2);
        l_blood_father_gr VARCHAR2(2);
    
        l_blood_prev sys_message.desc_message%TYPE;
    
        CURSOR c1 IS
            SELECT flg_blood_group, flg_blood_rhesus
              FROM pat_blood_group
             WHERE id_patient = i_patient
               AND flg_status = 'A';
    
        l_blood_group_father  pat_pregnancy.blood_group_father%TYPE;
        l_blood_rhesus_father pat_pregnancy.blood_rhesus_father%TYPE;
        l_rowids_1            table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'INSERT/UPDATE PATIENT';
    
        IF i_blood_type_father IS NOT NULL
        THEN
            -- TRANSFORMACAO DO BLOOD DO PAI (VEM COMO EX: +A OU -O)
            IF substr(i_blood_type_father, 0, 1) = '+'
            THEN
                l_blood_father_rh := 'P';
            ELSE
                l_blood_father_rh := 'N';
            END IF;
        
        END IF;
    
        g_error           := 'REPLACE';
        l_blood_father_gr := REPLACE(i_blood_type_father, substr(i_blood_type_father, 0, 1));
    
        g_error := 'UPDATE PAT_PREGNANCY';
        -- *********************************
        -- PT 03/10/2008 2.4.3.d
        l_blood_group_father  := CASE l_blood_father_gr
                                     WHEN NULL THEN
                                      ''
                                     ELSE
                                      l_blood_father_gr
                                 END;
        l_blood_rhesus_father := CASE l_blood_father_rh
                                     WHEN NULL THEN
                                      ''
                                     ELSE
                                      l_blood_father_rh
                                 END;
    
        ts_pat_pregnancy.upd(id_pat_pregnancy_in    => i_pat_pregnancy,
                             blood_group_father_in  => l_blood_group_father,
                             blood_rhesus_father_in => l_blood_rhesus_father,
                             flg_antigl_aft_chb_in  => i_flg_antigl_aft_chb,
                             flg_antigl_aft_abb_in  => i_flg_antigl_aft_abb,
                             flg_antigl_need_in     => i_flg_antigl_need,
                             rows_out               => l_rowids_1);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PREGNANCY',
                                      i_rowids     => l_rowids_1,
                                      o_error      => o_error);
        -- *********************************
    
        /*UPDATE pat_pregnancy
           SET blood_group_father  = nvl(l_blood_father_gr, ''),
               blood_rhesus_father = nvl(l_blood_father_rh, ''),
               flg_antigl_aft_chb  = i_flg_antigl_aft_chb,
               flg_antigl_aft_abb  = i_flg_antigl_aft_abb,
               flg_antigl_need     = i_flg_antigl_need
        
         WHERE id_pat_pregnancy = i_pat_pregnancy;
        
        COMMIT;*/
    
        -- ACTUALIZA O TIPO DE SANGUE, DEPOIS DE CONFIRMACAO POR PARTE DO USER
    
        IF i_blood_type_mother IS NOT NULL
        THEN
        
            IF substr(i_blood_type_mother, 0, 1) = '+'
            THEN
                l_blood_mother_rh := 'P';
            ELSE
                l_blood_mother_rh := 'N';
            END IF;
        
        END IF;
    
        l_blood_mother_gr := REPLACE(i_blood_type_mother, substr(i_blood_type_mother, 0, 1));
    
        g_error := 'SELECT ON BLOOD';
    
        OPEN c1;
        FETCH c1
            INTO l_blood_gr, l_blood_rh;
        CLOSE c1;
    
        IF ((l_blood_mother_gr <> nvl(l_blood_gr, 'X')) OR (l_blood_mother_rh <> nvl(l_blood_rh, 'X')))
        THEN
        
            IF i_flg_confirm = 'Y'
            THEN
                g_error := 'CALL TO PK_PATIENT.SET_PAT_BLOOD';
            
                IF NOT pk_patient.set_pat_blood(i_lang,
                                                NULL,
                                                i_patient,
                                                l_blood_mother_gr,
                                                l_blood_mother_rh,
                                                NULL,
                                                i_prof,
                                                'D',
                                                o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            
                o_msg       := NULL;
                o_msg_title := NULL;
                o_flg_show  := 'N';
                o_button    := NULL;
            
                COMMIT;
            
            ELSE
            
                IF l_blood_mother_rh IS NOT NULL
                THEN
                    IF l_blood_mother_rh = 'P'
                    THEN
                        l_blood_mother_rh := '+';
                    ELSE
                        l_blood_mother_rh := '-';
                    END IF;
                END IF;
            
                IF l_blood_rh IS NOT NULL
                THEN
                    IF l_blood_rh = 'P'
                    THEN
                        l_blood_rh := '+';
                    ELSE
                        l_blood_rh := '-';
                    END IF;
                END IF;
            
                IF l_blood_gr IS NULL
                   OR l_blood_rh IS NULL
                THEN
                    -- todo: n�o est� a funcionar. Nunca apresenta 'Nenhum'
                    l_blood_prev := pk_message.get_message(i_lang, 'COMMON_M002'); -- NESTE CASO, COLOCA A VAR A 'NENHUM'
                ELSE
                    l_blood_prev := l_blood_gr || l_blood_rh;
                END IF;
            
                o_msg       := REPLACE(REPLACE(pk_message.get_message(i_lang, 'WOMAN_HEALTH_T050'),
                                               '@1',
                                               l_blood_mother_gr || l_blood_mother_rh),
                                       '@2',
                                       l_blood_prev);
                o_msg_title := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T018');
                o_flg_show  := 'Y';
                o_button    := 'C';
            
            END IF;
        
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
                                              'SET_PAT_PREGNANCY_DET_RH',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION get_pat_pregnancy_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        o_preg          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter dados da gravidez para o ecr� de detalhe
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PAT_PREGNANCY - ID da gravidez
                                I_PROF - ID do profissional
                        Saida:  O_PREG - Cursor com info da gr�vida
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/03
          NOTAS:
        *********************************************************************************/
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET PREGNANCY DATA';
    
        OPEN o_preg FOR
            SELECT dt_last_menstruation,
                   pk_date_utils.dt_chr(i_lang, dt_last_menstruation, i_prof) dt_last_menstruation_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T027') dt_last_menstruation_desc,
                   nvl(flg_urine_preg_test, 'N') flg_urine_preg_test,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_URINE_PREG_TEST', nvl(flg_urine_preg_test, 'N'), i_lang) flg_urine_preg_test_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T031') flg_urine_preg_test_desc,
                   dt_urine_preg_test,
                   pk_date_utils.dt_chr(i_lang, dt_urine_preg_test, i_prof) dt_urine_preg_test_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T032') dt_urine_preg_test_desc,
                   nvl(flg_hemat_preg_test, 'N') flg_hemat_preg_test,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_HEMAT_PREG_TEST', nvl(flg_hemat_preg_test, 'N'), i_lang) flg_hemat_preg_test_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T033') flg_hemat_preg_test_desc,
                   dt_hemat_preg_test,
                   pk_date_utils.dt_chr(i_lang, dt_hemat_preg_test, i_prof) dt_hemat_preg_test_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T034') dt_hemat_preg_test_desc,
                   decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') || pbg.flg_blood_group blood_type_mother_val,
                   pbg.flg_blood_group || decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') blood_type_mother_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T035') blood_type_mother_desc,
                   decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') || pp.blood_group_father blood_type_father_val,
                   pp.blood_group_father || decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') blood_type_father_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T036') blood_type_father_desc,
                   flg_antigl_aft_chb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T037') flg_antigl_atf_chb_desc,
                   flg_antigl_aft_abb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T038') flg_antigl_atf_abb_desc,
                   contrac_method,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.CONTRAC_METHOD', contrac_method, i_lang) contrac_method_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T039') contrac_method_desc,
                   contrac_method_last,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.CONTRAC_METHOD', contrac_method_last, i_lang) contrac_method_last_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T040') contrac_method_last_desc,
                   dt_contrac_meth_begin,
                   pk_date_utils.dt_chr(i_lang, dt_contrac_meth_begin, i_prof) dt_contrac_meth_begin_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T041') dt_contrac_meth_begin_desc,
                   dt_contrac_meth_end,
                   pk_date_utils.dt_chr(i_lang, dt_contrac_meth_end, i_prof) dt_contrac_meth_end_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T042') dt_contrac_meth_end_desc,
                   father_name,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T043') father_name_desc,
                   dt_father_birth,
                   pk_date_utils.dt_chr(i_lang, dt_father_birth, i_prof) dt_father_birth_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T044') dt_father_birth_desc,
                   father_age,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T045') father_age_desc,
                   pk_translation.get_translation(i_lang, oc.code_occupation) father_job_desc_val,
                   id_occupation_father,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T046') father_job_desc,
                   trunc((nvl(CAST(pp.dt_intervention AS DATE), SYSDATE) - pp.dt_init_pregnancy + 6) / g_days_in_week) || ' ' ||
                   decode(trunc((nvl(CAST(pp.dt_intervention AS DATE), SYSDATE) - pp.dt_init_pregnancy + 6) / 7),
                          1,
                          pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                          pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) time_gest,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T028') time_gest_desc,
                   dt_pdel_correct,
                   pk_date_utils.dt_chr(i_lang, dt_pdel_correct, i_prof) dt_pdel_correct_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T029') dt_pdel_correct_desc,
                   pp.dt_init_pregnancy + g_weeks_gest_normal * g_days_in_week dt_chb_sched,
                   pk_date_utils.dt_chr(i_lang, pp.dt_init_pregnancy + g_weeks_gest_normal * g_days_in_week, i_prof) dt_chb_sched_chr,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T030') dt_chb_sched_desc,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T061') age_unit
            
              FROM pat_pregnancy pp, pat_blood_group pbg, patient pat, occupation oc
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND pat.id_patient = i_patient
               AND pat.id_patient = pbg.id_patient(+)
               AND pat.id_patient = pp.id_patient
               AND pbg.flg_status(+) = 'A'
               AND oc.id_occupation(+) = pp.id_occupation_father;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREGNANCY_DET',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pregnancy_timeframe
    (
        i_lang          IN language.id_language%TYPE,
        i_dt_last_menst IN pat_pregnancy.dt_last_menstruation%TYPE,
        i_dt_correct    IN pat_pregnancy.dt_pdel_correct%TYPE,
        i_prof          IN profissional,
        o_preg          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter tempo de gesta��o
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_DT_LAST_MENST - Data da �ltima menstrua��o
                                I_DT_CORRECT - Data corrigida de concep��o
                                I_PROF - ID do profissional
                        Saida:  O_PREG - Cursor com info da gr�vida
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/04
          NOTAS:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET PREGNANCY DATA';
    
        OPEN o_preg FOR
            SELECT trunc((SYSDATE - nvl(i_dt_correct, i_dt_last_menst)) / g_days_in_week) || ' ' ||
                   decode(trunc((SYSDATE - nvl(i_dt_correct, i_dt_last_menst)) / 7),
                          1,
                          pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                          pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) time_gest,
                   nvl(i_dt_correct, i_dt_last_menst) + g_weeks_gest_normal * g_days_in_week dt_chb_sched
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREGNANCY_TIMEFRAME',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_vs_header
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_sign_v        OUT pk_types.cursor_type,
        o_preg          OUT pk_types.cursor_type,
        o_vacc_status   OUT pk_types.cursor_type,
        o_vacc_admin    OUT pk_types.cursor_type,
        o_vacc_dose     OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter os eventos parametrizados e forma de inser��o no UI
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PROF - ID do profissional
                                 I_INTERN_NAME - Intern name do TIME_EVENT_GROUP
                                 I_PATIENT - ID do paciente
                                 I_PAT_PREGNANCY - ID da gravidez
                        Saida:   O_SIGN_V - Detalhe dos eventos
                                 O_PREG - Dados necess�rios da gravidez (para o deepnav de RH)
                                 O_VACC - Dados de eventos vacinas (com doses e administra��o)
                                 O_VAL_HABIT - Valores habituais das an�lises e sinais vitais
                                 O_ERROR - erro
        
           CRIA��O: RdSN 2007/02/03
        
           NOTAS: FLG_FILL_TYPE: N - sinal vital cujo preenchimento � num�rico (keypad)
                           V - sinal vital cujo preenchimento � alfanum�rico (multi-choice)
                         B - sinal vital cujo preenchimento � feito atrav�s de keypad c/ barra
                         P - r�gua da dor
                         X - n�o � preenchido e � tem detalhe (total de Glasgow)
                FLG_SUM: N - n�o � parcela do total de Glasgow
                       Y - � parcela do total de Glasgow
                RELATION_TYPE: S - soma (Glasgow)
                           C - concatena��o (PA)
                       Similar to PK_VITAL_SIGN.GET_VS_HEADER
        
        *********************************************************************************/
    
        l_flg_view VARCHAR2(2) := 'P';
    
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CFG_VARS';
        IF NOT (get_cfg_vars(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_flg_view => l_flg_view,
                             o_inst     => l_institution,
                             o_soft     => l_software,
                             o_error    => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        -----------------------------------------
        -- EVENTS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
            SELECT /*+opt_estimate(table vs_confs rows=10)*/
            DISTINCT vs_confs.id_vital_sign,
                     val_min,
                     val_max,
                     nvl(vs_confs.rank, 0) rank,
                     0 rank_conc,
                     NULL id_vital_sign_parent,
                     g_vs_rel_sum relation_type,
                     format_num,
                     flg_fill_type,
                     flg_sum,
                     name_vs,
                     desc_unit_measure,
                     id_unit_measure,
                     dt_server,
                     e.flg_most_freq,
                     NULL VALUE,
                     e.flg_group,
                     NULL sample_type_desc,
                     decode(vr.id_vital_sign_parent, NULL, 'N', 'Y') id_vital_sign_detail,
                     NULL n_dose
              FROM time_event_group teg
              JOIN event e
                ON e.id_event_group = teg.id_event_group
              JOIN TABLE(pk_vital_sign.tf_get_vs_header(i_lang, i_prof, l_flg_view, l_institution, l_software, NULL, i_patient)) vs_confs
                ON vs_confs.id_vital_sign = e.id_group
              LEFT JOIN vital_sign_relation vr
                ON vr.id_vital_sign_parent = vs_confs.id_vital_sign
               AND vr.relation_domain = g_vs_rel_conc
             WHERE teg.intern_name = i_intern_name
               AND e.flg_group = 'VS'
            
            UNION ALL
            
            SELECT /*+opt_estimate(table vs_confs rows=10)*/
            DISTINCT v.id_vital_sign,
                     vs_confs.val_min,
                     vs_confs.val_max,
                     nvl(vs_confs.rank, 0) rank,
                     vr.rank rank_conc,
                     vr.id_vital_sign_parent,
                     vr.relation_domain relation_type,
                     vs_confs.format_num,
                     vs_confs.flg_fill_type,
                     pk_alert_constant.g_no flg_sum,
                     pk_translation.get_translation(i_lang, v.code_vital_sign) name_vs,
                     vs_confs.desc_unit_measure,
                     vs_confs.id_unit_measure,
                     vs_confs.dt_server,
                     e.flg_most_freq,
                     NULL VALUE,
                     e.flg_group,
                     NULL sample_type_desc,
                     decode(vr.id_vital_sign_parent, NULL, 'N', 'Y') id_vital_sign_detail,
                     NULL n_dose
              FROM time_event_group teg
              JOIN event e
                ON e.id_event_group = teg.id_event_group
              JOIN TABLE(pk_vital_sign.tf_get_vs_header(i_lang, i_prof, l_flg_view, l_institution, l_software, NULL, i_patient)) vs_confs
                ON vs_confs.id_vital_sign = e.id_group
              JOIN vital_sign_relation vr
                ON vr.id_vital_sign_parent = vs_confs.id_vital_sign
               AND vr.relation_domain = g_vs_rel_conc
              JOIN vital_sign v
                ON v.id_vital_sign = vr.id_vital_sign_detail
               AND v.flg_available = pk_alert_constant.g_available
             WHERE teg.intern_name = i_intern_name
               AND e.flg_group = 'VS'
             ORDER BY rank, sample_type_desc DESC, name_vs;
    
        -----------------------------------------
        -- GRAVIDEZ INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') || pbg.flg_blood_group blood_type_mother_val,
                   pbg.flg_blood_group || decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') blood_type_mother_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T035') blood_type_mother_desc,
                   decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') || pp.blood_group_father blood_type_father_val,
                   pp.blood_group_father || decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') blood_type_father_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T036') blood_type_father_desc,
                   flg_antigl_aft_chb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T053') flg_antigl_atf_chb_desc,
                   flg_antigl_aft_abb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T054') flg_antigl_atf_abb_desc,
                   -- antiglobulina
                   flg_antigl_need,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_NEED', flg_antigl_need, i_lang) flg_antigl_need_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T052') flg_antigl_need_desc
            
              FROM pat_pregnancy pp, pat_blood_group pbg, patient pat
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND pat.id_patient = i_patient
               AND pat.id_patient = pbg.id_patient(+)
               AND pat.id_patient = pp.id_patient(+)
               AND pbg.flg_status(+) = 'A';
    
        --chamada � fun��o da informa��o das vacinas
        IF NOT get_vaccines_info(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_intern_name     => i_intern_name,
                                 i_patient         => i_patient,
                                 i_pat_pregnancy   => i_pat_pregnancy,
                                 o_vaccines_status => o_vacc_status,
                                 o_vaccines_admin  => o_vacc_admin,
                                 o_vaccines_dose   => o_vacc_dose,
                                 o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -----------------------------------------
        -- VALORES HABITUAIS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_VAL_HABIT';
        OPEN o_val_habit FOR
        
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, vdesc.icon) icon,
                   vdesc.value flg_value
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   vaccine_desc     vdesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
                  
               AND (vdesc.id_vaccine(+) = e.id_group AND e.flg_group = 'V' AND
                   (vdesc.id_vaccine_desc IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, adesc.icon) icon,
                   adesc.value flg_value
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   analysis_desc    adesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
                  
               AND (adesc.id_analysis(+) = e.id_group AND e.flg_group = 'A' AND
                   (adesc.id_analysis IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, adesc.code_analysis_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   NULL icon,
                   NULL flg_value
              FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
                  
               AND e.flg_group = 'VS';
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VS_HEADER',
                                              o_error);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_preg);
            pk_types.open_my_cursor(o_vacc_status);
            pk_types.open_my_cursor(o_vacc_admin);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    FUNCTION get_pregnancy_data_domain
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        i_intern_name IN VARCHAR2,
        o_preg        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter os valores para v�rios multichoices
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do Paciente
                                I_PROF - ID do profissional
                        Saida: O_PREG - Listagem das gravidezes
                                O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/06
          NOTA:
        *********************************************************************************/
    
        l_code_domain VARCHAR2(200) := 'WOMAN_HEALTH.';
    
    BEGIN
    
        l_code_domain := l_code_domain || i_intern_name;
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT desc_val, val, img_name, rank
              FROM sys_domain
             WHERE code_domain = l_code_domain
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND flg_available = pk_alert_constant.g_yes
            
            UNION ALL
            
            SELECT pk_message.get_message(i_lang, 'COMMON_M002') desc_val, 'X' val, NULL img_name, -1 rank
              FROM dual
            
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREGNANCY_DATA_DOMAIN',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION set_analysis_most_freq
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_analysis_req_par   IN table_number,
        i_parameter_analysis IN table_number,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Altera��o dos dados da gravidez
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_ANALYSIS_RES_MOST_FREQ - ID dos ANALYSIS_RESULT's mais frequentes
                                 I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/08
          NOTAS: !!!!! NAO USADA !!!!!
        *********************************************************************************/
    
    BEGIN
    
        FOR i IN 1 .. i_analysis_req_par.count
        LOOP
        
            g_error := 'UPDATE ANALYSIS_RESULT_PAR ' || i;
        
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
                                              'SET_ANALYSIS_MOST_FREQ',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION set_vaccine_dose_admin
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_vaccine     IN table_varchar,
        i_vaccine_det IN table_varchar,
        i_n_dose      IN table_number,
        i_dt_admin    IN table_varchar,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grava��o de administra��o de vacinas
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_VACCINE - array de vacinas
                            I_VACCINE_DET - array de ID de detalhe
                            I_N_DOSE - array de n� de doses
                            I_DT_ADMIN - array de datas de administra��o
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/10
          NOTAS:
        *********************************************************************************/
    
        l_vaccine      VARCHAR2(20);
        l_vaccine_det  NUMBER;
        l_vaccine_dose NUMBER;
        l_vda          vaccine_dose_admin.id_vaccine_dose_admin%TYPE;
        l_vdet         vaccine_det.id_vaccine_det%TYPE;
        l_vdose        vaccine_dose.id_vaccine_dose%TYPE;
        l_n_dose       vaccine_dose.n_dose%TYPE;
    
        l_rowids     table_varchar := table_varchar();
        l_rowids_aux table_varchar;
    
        CURSOR c1 IS
            SELECT id_vaccine_dose_admin
              FROM vaccine_dose_admin
             WHERE medid = l_vaccine
               AND id_vaccine_dose = l_vaccine_dose
               AND id_vaccine_det = l_vaccine_det;
    
        CURSOR c2 IS
            SELECT id_vaccine_det
              FROM vaccine_det
             WHERE medid = l_vaccine
               AND id_patient = i_patient;
    
        CURSOR c3 IS
            SELECT id_vaccine_dose
              FROM vaccine_dose
             WHERE medid = l_vaccine
               AND n_dose = l_n_dose;
    
    BEGIN
    
        g_error := 'LOOP';
    
        FOR i IN 1 .. i_dt_admin.count
        LOOP
        
            g_error := 'VACCINE_DET CHECK';
        
            l_vaccine := i_vaccine(i);
        
            IF i_vaccine_det(i) IS NULL
            THEN
            
                g_error := 'FETCH CURSOR C2';
                OPEN c2;
                FETCH c2
                    INTO l_vdet;
                g_found := c2%NOTFOUND;
                CLOSE c2;
            
                IF l_vdet IS NULL
                THEN
                
                    g_error       := 'GET SEQ';
                    l_vaccine_det := ts_vaccine_det.next_key();
                
                    g_error := 'INSERT VACCINE_DET';
                    ts_vaccine_det.ins(id_vaccine_det_in => l_vaccine_det,
                                       medid_in          => l_vaccine,
                                       flg_type_in       => 'V',
                                       id_patient_in     => i_patient,
                                       id_episode_in     => i_episode,
                                       rows_out          => l_rowids_aux);
                    l_rowids := l_rowids MULTISET UNION DISTINCT l_rowids_aux;
                ELSE
                
                    l_vaccine_det := l_vdet;
                
                END IF;
            
            ELSE
            
                l_vaccine_det := i_vaccine_det(i);
            
            END IF;
        
            -- todo: CODIGO PODERIA SER OPTIMIZADO
            l_n_dose := i_n_dose(i);
        
            g_error := 'FETCH CURSOR C3';
            OPEN c3;
            FETCH c3
                INTO l_vdose;
            g_found := c3%NOTFOUND;
            CLOSE c3;
        
            l_vaccine_dose := l_vdose;
        
            g_error := 'FETCH CURSOR C1';
            OPEN c1;
            FETCH c1
                INTO l_vda;
            g_found := c1%NOTFOUND;
            CLOSE c1;
        
            IF g_found
            THEN
            
                g_error := 'INSERT VACCINE_DOSE_ADMIN ' || l_vaccine || '-' || l_vaccine_dose || '-' || l_vaccine_det || '-' ||
                           l_n_dose;
            
                INSERT INTO vaccine_dose_admin
                    (id_vaccine_dose_admin, medid, id_vaccine_dose, dt_admin_tstz, id_vaccine_det, n_dose)
                VALUES
                    (seq_vaccine_dose_admin.nextval,
                     l_vaccine,
                     l_vaccine_dose,
                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_admin(i), NULL),
                     l_vaccine_det,
                     l_n_dose);
            
            ELSE
            
                g_error := 'UPDATE VACCINE_DOSE_ADMIN';
            
                UPDATE vaccine_dose_admin
                   SET dt_admin_tstz = pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_admin(i), NULL)
                 WHERE medid = l_vaccine
                   AND id_vaccine_dose = l_vaccine_dose
                   AND id_vaccine_det = l_vaccine_det;
            
            END IF;
        
        END LOOP;
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'vaccine_det',
                                      i_rowids     => SET(l_rowids),
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_VACCINE_DOSE_ADMIN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION set_vaccine_status
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_status  IN table_varchar,
        i_vaccine     IN table_varchar,
        i_vaccine_det IN table_varchar,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grava��o da altera��o do estado das vacinas
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_FLG_STATUS - array de FLG_STATUS da vacina
                            I_VACCINE - array de vacinas
                            I_VACCINE_DET - array de ID de detalhe
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/03/05
          NOTAS:
        *********************************************************************************/
    
        l_vaccine_det NUMBER;
        l_vdet        vaccine_det.id_vaccine_det%TYPE;
        l_vaccine     VARCHAR2(20);
    
        l_rowids     table_varchar := table_varchar();
        l_rowids_aux table_varchar;
    
        CURSOR c2 IS
            SELECT id_vaccine_det
              FROM vaccine_det
             WHERE medid = l_vaccine
               AND id_patient = i_patient;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'LOOP';
    
        FOR i IN 1 .. i_flg_status.count
        LOOP
        
            l_vaccine := i_vaccine(i);
        
            g_error := 'CHECK VACCINE_DET';
        
            IF i_vaccine_det(i) IS NULL
            THEN
            
                g_error := 'FETCH CURSOR C2';
                OPEN c2;
                FETCH c2
                    INTO l_vdet;
                g_found := c2%NOTFOUND;
                CLOSE c2;
            
                IF l_vdet IS NULL
                THEN
                
                    g_error       := 'GET SEQ';
                    l_vaccine_det := ts_vaccine_det.next_key();
                
                    g_error := 'INSERT VACCINE_DET';
                    ts_vaccine_det.ins(id_vaccine_det_in => l_vaccine_det,
                                       medid_in          => i_vaccine(i),
                                       flg_type_in       => 'V',
                                       id_patient_in     => i_patient,
                                       id_episode_in     => i_episode,
                                       rows_out          => l_rowids_aux);
                    l_rowids := l_rowids MULTISET UNION DISTINCT l_rowids_aux;
                
                ELSE
                
                    l_vaccine_det := l_vdet;
                
                END IF;
            
            ELSE
            
                l_vaccine_det := i_vaccine_det(i);
            
            END IF;
        
            g_error := 'INSERT VACCINE_STATUS';
        
            -- actualiza os anteriores status para anteriores
            UPDATE vaccine_status
               SET flg_active = 'P'
             WHERE id_vaccine_det = l_vaccine_det;
        
            -- cria��o de estados intermedios para vacinas
            INSERT INTO vaccine_status
                (id_vaccine_status, id_vaccine_det, flg_status, flg_active, dt_vaccine_status_tstz, id_professional)
            VALUES
                (seq_vaccine_status.nextval, l_vaccine_det, i_flg_status(i), 'A', g_sysdate_tstz, i_prof.id);
        
        END LOOP;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'vaccine_det',
                                      i_rowids     => SET(l_rowids),
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_VACCINE_STATUS',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION create_epis_pregnancy
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cria��o de intecorr�ncia (epis�dio da gr�vida)
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_EPISODE - ID do Epis�dio
                            I_PAT_PREGNANCY - ID da gravidez
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/11
          NOTAS:
        *********************************************************************************/
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        INSERT INTO epis_pregnancy
            (id_epis_pregnancy, id_episode, id_pat_pregnancy, dt_begin_tstz, id_professional)
        VALUES
            (seq_epis_pregnancy.nextval, i_episode, i_pat_pregnancy, g_sysdate_tstz, i_prof.id);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION set_event_most_freq
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_id_group      IN table_number,
        i_flg_group     IN table_varchar,
        i_value         IN table_varchar,
        i_id_unit_meas  IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualiza os registos habituais
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_ID_GROUP - Array com ID_VITAL_SIGN / ID_ANALYSIS
                            I_VALUE - Array com os valores
                            I_ID_UNIT_MEAS - Array com as unidades de medida
                            I_PAT_PREGNANCY - ID da gravidez
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/14
          NOTAS:
        *********************************************************************************/
    
        l_id_group               VARCHAR2(20);
        l_flg_group              VARCHAR2(20);
        l_event_most_freq_exists VARCHAR2(1);
        --valor
        l_id_event_most_freq event_most_freq.id_event_most_freq%TYPE;
        l_value_m_freq       VARCHAR2(100);
    
        l_rowids     table_varchar := table_varchar();
        l_rowids_aux table_varchar;
    
        CURSOR event_most_freq_exists IS
            SELECT 0
              FROM event_most_freq
             WHERE id_group = l_id_group
               AND flg_group = l_flg_group
               AND id_patient = i_patient
               AND id_pat_pregnancy = i_pat_pregnancy;
    
    BEGIN
    
        g_error := 'SET MOST FREQ';
        FOR i IN 1 .. i_id_group.count
        LOOP
        
            IF i_value IS NOT NULL
            THEN
            
                l_id_group  := i_id_group(i);
                l_flg_group := i_flg_group(i);
            
                -- verifica se existe um evento habitual j� criado
                g_error := 'OPEN EVENT_MOST_FREQ_EXISTS';
                OPEN event_most_freq_exists;
                FETCH event_most_freq_exists
                    INTO l_event_most_freq_exists;
                g_found := event_most_freq_exists%NOTFOUND;
                CLOSE event_most_freq_exists;
            
                IF g_found
                THEN
                    --Apenas cria um novo registo se o valor nao for NULL
                    l_value_m_freq := i_value(i);
                    IF l_value_m_freq IS NOT NULL
                    THEN
                        g_error              := 'GET EVENT_MOST_FREQ KEY';
                        l_id_event_most_freq := ts_event_most_freq.next_key();
                    
                        g_error := 'INSERT EVENT_MOST_FREQ';
                        ts_event_most_freq.ins(id_event_most_freq_in      => l_id_event_most_freq,
                                               id_group_in                => l_id_group,
                                               flg_group_in               => l_flg_group,
                                               id_patient_in              => i_patient,
                                               value_in                   => l_value_m_freq,
                                               id_unit_measure_in         => i_id_unit_meas(i),
                                               id_pat_pregnancy_in        => i_pat_pregnancy,
                                               id_prof_read_in            => i_prof.id,
                                               id_institution_read_in     => i_prof.institution,
                                               id_software_read_in        => i_prof.software,
                                               dt_event_most_freq_tstz_in => current_timestamp,
                                               id_episode_in              => i_episode,
                                               handle_error_in            => TRUE,
                                               rows_out                   => l_rowids_aux);
                    
                        l_rowids := l_rowids MULTISET UNION DISTINCT l_rowids_aux;
                    
                    END IF;
                
                ELSE
                    g_error := 'UPDATE EVENT_MOST_FREQ';
                    UPDATE event_most_freq
                       SET VALUE = i_value(i), id_unit_measure = i_id_unit_meas(i)
                     WHERE id_group = l_id_group
                       AND flg_group = l_flg_group
                       AND id_patient = i_patient
                       AND id_pat_pregnancy = i_pat_pregnancy;
                
                END IF;
            
            END IF;
        
        END LOOP;
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'event_most_freq',
                                      i_rowids     => SET(l_rowids),
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EVENT_MOST_FREQ',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_event_most_freq;

    FUNCTION set_event_most_freq
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_id_group        IN table_number,
        i_flg_group       IN table_varchar,
        i_value           IN table_varchar,
        i_id_unit_meas    IN table_number,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_pat_pregn_fetus IN pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualiza os registos habituais
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_PATIENT - ID do Paciente
                            I_ID_GROUP - Array com ID_VITAL_SIGN / ID_ANALYSIS
                            I_VALUE - Array com os valores
                            I_ID_UNIT_MEAS - Array com as unidades de medida
                            I_PAT_PREGNANCY - ID da gravidez
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/14
          NOTAS:
        *********************************************************************************/
    
        l_id_group  VARCHAR2(20);
        l_flg_group VARCHAR2(20);
        --valor
        l_id_event_most_freq event_most_freq.id_event_most_freq%TYPE;
        l_value_m_freq       VARCHAR2(100);
    
        l_rowids table_varchar;
    
    BEGIN
    
        g_error := 'SET MOST FREQ';
        FOR i IN 1 .. i_id_group.count
        LOOP
        
            IF i_value IS NOT NULL
            THEN
            
                l_id_group  := i_id_group(i);
                l_flg_group := i_flg_group(i);
            
                -- verifica se existe um evento habitual j� criado
                g_error := 'get id_event_most_freq';
                BEGIN
                    SELECT emf.id_event_most_freq
                      INTO l_id_event_most_freq
                      FROM event_most_freq emf
                     WHERE emf.id_group = l_id_group
                       AND emf.flg_group = l_flg_group
                       AND emf.id_patient = i_patient
                       AND nvl(emf.id_pat_pregnancy, -9999) = nvl(i_pat_pregnancy, -9999)
                       AND nvl(emf.id_pat_pregn_fetus, -9999) = nvl(i_pat_pregn_fetus, -9999)
                       AND nvl(emf.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_event_most_freq := NULL;
                END;
            
                IF l_id_event_most_freq IS NULL
                THEN
                    --Apenas cria um novo registo se o valor nao for NULL
                    l_value_m_freq := i_value(i);
                    IF l_value_m_freq IS NOT NULL
                    THEN
                        g_error              := 'GET EVENT_MOST_FREQ KEY';
                        l_id_event_most_freq := ts_event_most_freq.next_key();
                    
                        g_error := 'INSERT EVENT_MOST_FREQ';
                        ts_event_most_freq.ins(id_event_most_freq_in      => l_id_event_most_freq,
                                               id_group_in                => l_id_group,
                                               flg_group_in               => l_flg_group,
                                               id_patient_in              => i_patient,
                                               value_in                   => l_value_m_freq,
                                               id_unit_measure_in         => i_id_unit_meas(i),
                                               id_pat_pregnancy_in        => i_pat_pregnancy,
                                               id_prof_read_in            => i_prof.id,
                                               id_institution_read_in     => i_prof.institution,
                                               id_software_read_in        => i_prof.software,
                                               dt_event_most_freq_tstz_in => current_timestamp,
                                               id_episode_in              => i_episode,
                                               handle_error_in            => TRUE,
                                               id_pat_pregn_fetus_in      => i_pat_pregn_fetus,
                                               flg_status_in              => pk_alert_constant.g_active,
                                               rows_out                   => l_rowids);
                    
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'EVENT_MOST_FREQ',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                    END IF;
                
                ELSE
                    g_error := 'UPDATE EVENT_MOST_FREQ';
                
                    ts_event_most_freq.upd(id_event_most_freq_in      => l_id_event_most_freq,
                                           value_in                   => i_value(i),
                                           id_unit_measure_in         => i_id_unit_meas(i),
                                           dt_event_most_freq_tstz_in => current_timestamp,
                                           id_episode_in              => i_episode,
                                           id_prof_read_in            => i_prof.id,
                                           id_institution_read_in     => i_prof.institution,
                                           id_software_read_in        => i_prof.software,
                                           flg_status_in              => pk_alert_constant.g_active,
                                           rows_out                   => l_rowids);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EVENT_MOST_FREQ',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                END IF;
            
            END IF;
        
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
                                              'SET_EVENT_MOST_FREQ',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END set_event_most_freq;

    FUNCTION cancel_pat_pregnancy
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       patient.id_patient%TYPE,
        i_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE,
        i_prof          IN profissional,
        i_flg_confirm   IN VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar gravidez existente
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                I_PATIENT - ID do paciente
                                I_PAT_PREGNANCY - ID da gravidez
                                I_PROF - Profissional
                                I_FLG_CONFIRM - Flag de confirma��o do cancelamento da gravidez
                        Saida:  O_MSG - Mensagem a mostrar ao utilizador
                                O_MSG_TITLE - Titulo da mensagem a mostrar ao utilizador
                                O_FLG_SHOW - Flg a assinalar se dever� ser mostrada a msg
                                O_BUTTON - Tipo de bot�o a apresentar ao utilizador
                                O_ERROR - erro
        
          CRIA��O: RdSN 2007/02/15
          NOTAS:
        *********************************************************************************/
    
        l_rowids_1 table_varchar;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'CANCEL PAT_PREGNANCY';
    
        IF i_flg_confirm = 'Y'
        THEN
        
            o_msg       := NULL;
            o_msg_title := NULL;
            o_flg_show  := 'N';
            o_button    := NULL;
        
            g_error := 'SET PREGNANCY HISTORY';
            IF NOT pk_pregnancy_api.set_pat_pregnancy_hist(i_lang, i_pat_pregnancy, o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
            g_error := 'UPDATE PAT PREGNANCY';
            -- *********************************
            -- PT 03/10/2008 2.4.3.d
            ts_pat_pregnancy.upd(id_pat_pregnancy_in      => i_pat_pregnancy,
                                 flg_status_in            => 'C',
                                 id_professional_in       => i_prof.id,
                                 dt_pat_pregnancy_tstz_in => current_timestamp,
                                 rows_out                 => l_rowids_1);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PREGNANCY',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
        
            g_error := 'UPDATE N_PREGNANCY';
            IF NOT pk_pregnancy_core.set_n_pregnancy(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_error   => o_error)
            THEN
                RAISE l_exception;
            END IF;
            -- *********************************
        
            /*UPDATE pat_pregnancy p
              SET p.flg_status = 'C', p.id_professional = i_prof.id, p.dt_pat_pregnancy_tstz = current_timestamp
            WHERE id_pat_pregnancy = i_pat_pregnancy
              AND id_patient = i_patient;
            
            COMMIT;*/
        
        ELSE
        
            o_msg       := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T066');
            o_msg_title := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T018');
            o_flg_show  := 'Y';
            o_button    := 'C';
        
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
                                              'CANCEL_PAT_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END;

    FUNCTION get_father_age
    (
        i_lang     IN language.id_language%TYPE,
        i_dt_birth IN patient.dt_birth%TYPE,
        i_prof     IN profissional,
        o_age      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Fun��o para c�lculo da idade do pai a partir da sua data de nascimento
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                            I_DT_BIRTH - Data de nascimento
                            I_PROF - ID do profissional
                        Saida: O_ERROR - Erro
        
          CRIA��O: RdSN 2007/02/23
          NOTAS:
        *********************************************************************************/
    BEGIN
    
        OPEN o_age FOR
            SELECT trunc(months_between(SYSDATE, i_dt_birth) / 12, 0) father_age
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FATHER_AGE',
                                              o_error);
            pk_types.open_my_cursor(o_age);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_analysis_desc_list
    (
        i_lang           IN language.id_language%TYPE,
        i_analysis       IN analysis_desc.id_analysis%TYPE,
        i_analysis_param IN analysis_desc.id_analysis_parameter%TYPE DEFAULT NULL,
        o_analysis       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de descritivos de uma an�lise cuja leitura n�o � num�rica
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_ANALYSIS - ID da An�lise cujos descritivos se pretende
                                 I_ANALYSIS_PARAM - ID do Parametro da An�lise cujos descritivos se pretende
                        Saida:   O_ANALYSIS - descritivos
                                 O_ERROR - erro
        
          CRIA��O: RdSN 2007/02/26
        *********************************************************************************/
    
        l_desc_vs_avail      VARCHAR2(1) := 'Y';
        l_sample_type        analysis_param.id_sample_type%TYPE;
        l_analysis_parameter analysis_param.id_analysis_parameter%TYPE;
    
    BEGIN
    
        SELECT ap.id_sample_type, ap.id_analysis_parameter
          INTO l_sample_type, l_analysis_parameter
          FROM analysis_param ap
         WHERE ap.id_analysis_param = i_analysis_param;
    
        g_error := 'GET CURSOR';
        OPEN o_analysis FOR 'SELECT DISTINCT id_analysis_desc, rank, VALUE, pk_translation.get_translation(' || i_lang || ', code_analysis_desc) an_desc, icon ' || --
         '  FROM analysis_desc ' || --
         ' WHERE id_analysis = ' || i_analysis || --
         '   AND id_sample_type = ' || l_sample_type || --
         '   and id_analysis_parameter = ' || l_analysis_parameter || --
         '   AND flg_available = ''' || l_desc_vs_avail || '''' || --
         'UNION ALL ' || --
         'SELECT -1 id_analysis_desc, -1 rank, ''X'' VALUE, pk_message.get_message(' || i_lang || ', ''COMMON_M002'') an_desc, NULL icon ' || --
         '  FROM dual ' || --
         ' ORDER BY rank ';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_DESC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_vaccine_desc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_vaccine IN analysis_desc.id_analysis%TYPE,
        o_vaccine OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de descritivos de uma vacina cuja leitura n�o � num�rica
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                    I_VACCINE - ID da Vacina cujos descritivos se pretende
                        Saida:   O_VACCINE - descritivos
                                 O_ERROR - erro
        
          CRIA��O: RdSN 2007/02/26
        *********************************************************************************/
    
        l_desc_vs_avail VARCHAR2(1) := 'Y';
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_vaccine FOR 'SELECT ID_VACCINE_DESC, RANK, VALUE, ' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CODE_VACCINE_DESC) VACCINE_DESC, ICON ' || 'FROM VACCINE_DESC ' || 'WHERE ID_VACCINE = ' || i_vaccine || ' AND FLG_AVAILABLE = ''' || l_desc_vs_avail || '''' || ' UNION ALL ' || 'SELECT -1 ID_VACCINE_DESC, -1 RANK, ''X'' VALUE, PK_MESSAGE.GET_MESSAGE(' || i_lang || ', ''COMMON_M002'') VACCINE_DESC, NULL ICON ' || 'FROM DUAL ' || ' ORDER BY RANK';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VACCINE_DESC_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_vaccine);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_preg_avail
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        o_avail            OUT VARCHAR2,
        o_dt_min           OUT VARCHAR2,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_preg_init     OUT VARCHAR2,
        o_dt_preg_end      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Verifica se pode criar gravidezes para aquele paciente ( se n�o for homem e menor de 8 anos )
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                       I_PATIENT - ID do paciente
                  Saida:   O_AVAIL - permiss�o para criar gravidezes
                     O_ERROR - erro
        
          CRIA��O: RdSN 2007/03/14
          NOTAS:
        *********************************************************************************/
    
        l_age    NUMBER;
        l_avail  VARCHAR2(2);
        l_dt_min DATE;
    
        l_code_min_preg_age CONSTANT sys_config.id_sys_config%TYPE := 'WOMAN_HEALTH.MIN_PREGN_AGE';
        l_code_max_preg_age CONSTANT sys_config.id_sys_config%TYPE := 'WOMAN_HEALTH.MAX_PREGN_AGE';
    
        l_min_preg_age     NUMBER;
        l_max_preg_age     NUMBER;
        l_count            NUMBER(3);
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_dt_init_pat_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_preg_init     VARCHAR2(500);
        l_dt_preg_end      VARCHAR2(500);
        l_dt_end           VARCHAR2(500);
        l_exception EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET AVAIL';
        SELECT decode(gender, 'F', pk_alert_constant.g_yes, pk_alert_constant.g_no),
               nvl(age, trunc(SYSDATE - dt_birth) / 365.25) age,
               add_months(decode(dt_birth, NULL, trunc(SYSDATE - age * 365.25), dt_birth), 12 * 8) dt_min
          INTO l_avail, l_age, l_dt_min
          FROM patient
         WHERE id_patient = i_patient;
        g_error        := 'GET MAX AND MIN PREGNANCY WEEKS';
        l_min_preg_age := to_number(pk_sysconfig.get_config(i_code_cf => l_code_min_preg_age, i_prof => i_prof));
        l_max_preg_age := to_number(pk_sysconfig.get_config(i_code_cf => l_code_max_preg_age, i_prof => i_prof));
    
        IF (l_avail = pk_alert_constant.g_yes)
        THEN
            IF l_age BETWEEN l_min_preg_age AND l_max_preg_age
            THEN
                l_avail := pk_alert_constant.g_yes;
            ELSIF l_age > l_max_preg_age
            THEN
                l_avail := pk_pregnancy_core.g_pat_pregn_type_r;
            ELSE
                l_avail := pk_alert_constant.g_no;
            END IF;
        
            BEGIN
                SELECT pp.flg_status, pp.id_pat_pregnancy, pp.dt_init_pregnancy
                  INTO l_avail, l_id_pat_pregnancy, l_dt_init_pat_preg
                  FROM pat_pregnancy pp
                 WHERE pp.id_patient = i_patient
                   AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close
                   AND i_prof.software NOT IN (pk_alert_constant.g_soft_nutritionist,
                                               pk_alert_constant.g_soft_psychologist,
                                               pk_alert_constant.g_soft_rehab,
                                               pk_alert_constant.g_soft_resptherap,
                                               pk_alert_constant.g_soft_social,
                                               pk_alert_constant.g_soft_case_manager)
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_pat_pregnancy := NULL;
            END;
        
            IF l_avail IS NOT NULL
            THEN
                g_error := 'GET PREGNANCY DATE END BY INIT DATE';
                IF NOT pk_pregnancy.get_dt_pregnancy_end(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_num_weeks   => NULL,
                                                         i_num_days    => NULL,
                                                         i_dt_init     => pk_date_utils.date_send(i_lang,
                                                                                                  l_dt_init_pat_preg,
                                                                                                  i_prof),
                                                         o_dt_end      => l_dt_preg_end,
                                                         o_dt_init_chr => l_dt_preg_init,
                                                         o_dt_end_chr  => l_dt_end,
                                                         o_error       => o_error)
                THEN
                    l_dt_preg_init := NULL;
                    l_dt_preg_end  := NULL;
                END IF;
            
                IF l_dt_preg_end IS NULL
                THEN
                    l_dt_preg_end := pk_date_utils.date_send(i_lang, g_sysdate_tstz, i_prof);
                END IF;
            
            END IF;
        
        END IF;
    
        o_avail            := l_avail;
        o_dt_min           := pk_date_utils.date_send(i_lang, l_dt_min, i_prof);
        o_id_pat_pregnancy := l_id_pat_pregnancy;
        o_dt_preg_init     := l_dt_preg_init;
        o_dt_preg_end      := l_dt_preg_end;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREG_AVAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_preg_converted_time
    (
        i_lang           IN language.id_language%TYPE,
        i_weeks          IN NUMBER,
        i_dt_preg        IN DATE,
        i_dt_reg         IN DATE,
        o_weeks          OUT NUMBER,
        o_trimester      OUT NUMBER,
        o_desc_trimester OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Converte datas da gravidez para n� de semanas e trimestre
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_WEEKS - n�mero de semanas
                                 I_DT_PREG - data da �ltima menstrua��o
                                 I_DT_REG - data do registo (por exemplo, em que data foi registada a ecografia). Se vier a NULL consideramos a data actual
                        Saida:   O_AVAIL - permiss�o para criar gravidezes
                                 O_WEEKS - n�mero de semanas
                                 O_TRIMESTER - trimestre
                                 O_ERROR - erro
        
          CRIA��O: JSILVA 30/05/2007
          NOTAS:
        *********************************************************************************/
    
        l_dt_reg    DATE;
        l_weeks     NUMBER;
        l_trimester NUMBER;
    
    BEGIN
    
        IF i_weeks IS NOT NULL
        THEN
        
            g_error := 'GET PREGNANCY TRIMESTER 1';
        
            IF i_weeks BETWEEN 0 AND 12
            THEN
                o_desc_trimester := pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER', '1', i_lang);
                o_trimester      := 1;
            ELSIF i_weeks BETWEEN 12 AND 24
            THEN
                o_desc_trimester := pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER', '2', i_lang);
                o_trimester      := 2;
            ELSIF i_weeks BETWEEN 24 AND 36
            THEN
                o_desc_trimester := pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER', '3', i_lang);
                o_trimester      := 3;
            ELSE
                o_desc_trimester := pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER', '4', i_lang);
                o_trimester      := 3;
            END IF;
        
            o_weeks := i_weeks;
        
        ELSIF i_dt_preg IS NOT NULL
        THEN
            g_error := 'GET PREGNANCY WEEKS';
            SELECT nvl(i_dt_reg, SYSDATE)
              INTO l_dt_reg
              FROM dual;
        
            SELECT trunc((trunc(l_dt_reg) - trunc(i_dt_preg)) / 7)
              INTO l_weeks
              FROM dual;
        
            g_error          := 'GET PREGNANCY TRIMESTER 2';
            o_weeks          := l_weeks;
            l_trimester      := conv_weeks_to_trimester(l_weeks);
            o_desc_trimester := pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER', l_trimester, i_lang);
            o_trimester      := l_trimester;
            IF l_trimester > 3
            THEN
                o_trimester := 3;
            END IF;
        
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
                                              'GET_PREG_CONVERTED_TIME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_preg_converted_time;

    /******************************************************************************
    OBJECTIVO: Gravar uma biometria para determinado feto.
    PARAMETROS:  ENTRADA:
                    I_LANG                    - L�ngua registada como prefer�ncia do profissional
                    I_PROF                    - ID do profissional, software e institui��o
                    I_ID_PAT_PREGN_FETUS      - ID do feto para a gravidez corrente
                    I_ID_VITAL_SIGN           - ID do sinal vital a gravar
                    I_VS_VALUE                - valor do sinal vital
    
             SAIDA:
                    O_ID_PAT_PREGN_FETUS_BIOM - id da biometria inserida
                    O_ERROR - erro
    
    CRIA��O: cmf 30/05/2007
    *********************************************************************************/
    FUNCTION set_new_fetus_biom
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat_pregn_fetus      IN pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        i_id_vital_sign           IN vital_sign.id_vital_sign%TYPE,
        i_vs_value                IN pat_pregn_fetus_biom.value%TYPE,
        o_id_pat_pregn_fetus_biom OUT pat_pregn_fetus_biom.id_pat_pregn_fetus_biom%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next NUMBER;
    
    BEGIN
    
        SELECT seq_pat_pregn_fetus_biom.nextval
          INTO l_next
          FROM dual;
    
        g_error := 'INSERT RECORD';
        INSERT INTO pat_pregn_fetus_biom
            (id_pat_pregn_fetus_biom,
             dt_pat_pregn_fetus_biom_tstz,
             id_pat_pregn_fetus,
             id_professional,
             id_vital_sign,
             VALUE)
        VALUES
            (l_next, current_timestamp, i_id_pat_pregn_fetus, i_prof.id, i_id_vital_sign, i_vs_value);
    
        o_id_pat_pregn_fetus_biom := l_next;
    
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
                                              'SET_NEW_FETUS_BIOM',
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_new_fetus_biom;

    FUNCTION conv_weeks_to_trimester(i_weeks IN NUMBER) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
    
        IF i_weeks BETWEEN 0 AND 12
        THEN
            l_return := 1;
        ELSIF i_weeks BETWEEN 13 AND 24
        THEN
            l_return := 2;
        ELSIF i_weeks BETWEEN 25 AND 36
        THEN
            l_return := 3;
        ELSE
            l_return := 4;
        END IF;
    
        RETURN l_return;
    
    END conv_weeks_to_trimester;

    FUNCTION set_pregnancy_register
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_desc_register    IN pregnancy_register.desc_register%TYPE,
        i_flg_type         IN pregnancy_register.flg_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Insere um novo registo associado a uma gravidez
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PROF - profissional
                                 I_PAT_PREGNANCY - ID da gravidez
                                 I_DESC_REGISTER - Informa��o inserida no registo
                                 I_FLG_TYPE - Tipo de registo
                        Saida:   O_ERROR - erro
        
          CRIA��O: JSILVA 18-06-2007
        *********************************************************************************/
    
        l_next NUMBER;
    
    BEGIN
    
        g_error := 'GET SEQ NEXT VAL';
        SELECT seq_pregnancy_register.nextval
          INTO l_next
          FROM dual;
    
        g_error := 'INSERT PREGNANCY REGISTER';
        INSERT INTO pregnancy_register
            (id_pregnancy_register,
             dt_pregn_register_tstz,
             desc_register,
             id_pat_pregnancy,
             id_professional,
             flg_type,
             id_institution,
             id_software)
        VALUES
            (l_next,
             current_timestamp,
             i_desc_register,
             i_id_pat_pregnancy,
             i_prof.id,
             'C',
             i_prof.institution,
             i_prof.software);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PREGNANCY_REGISTER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END set_pregnancy_register;

    FUNCTION get_pregnancy_register
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type         IN pregnancy_register.flg_type%TYPE,
        o_pregn_register   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Devolve os registos de um determinado tipo, associados a uma gravidez
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PROF - profissional
                                 I_PAT_PREGNANCY - ID da gravidez
                                 I_DESC_REGISTER - Informa��o inserida no registo
                                 I_FLG_TYPE - Tipo de registo
                        Saida:   O_ERROR - erro
        
          CRIA��O: JSILVA 18-06-2007
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET PREGNANCY REGISTER';
    
        OPEN o_pregn_register FOR
            SELECT pr.id_pregnancy_register,
                   pk_date_utils.date_send_tsz(i_lang, pr.dt_pregn_register_tstz, i_prof) dt_pregn_register,
                   -- Lu�s Maia 02-06-2008 (retorno da hora e minuto do registo
                   --pk_date_utils.dt_chr_tsz(i_lang, pr.dt_pregn_register_tstz, i_prof) dt_pregn_register_f,
                   pk_date_utils.date_char_tsz(i_lang, pr.dt_pregn_register_tstz, i_prof.institution, i_prof.software) dt_pregn_register_f,
                   -- ASANTOS 25-05-2009
                   -- Changes to include get_name_signature
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) desc_prof,
                   --LMAIA 11-03-2009
                   -- Changes to include get_spec_signature function
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    prof.id_professional,
                                                    pr.dt_pregn_register_tstz,
                                                    pp.id_episode) desc_speciality,
                   --pk_translation.get_translation(i_lang, spec.code_speciality) desc_speciality,
                   --
                   pr.desc_register
              FROM pregnancy_register pr, professional prof, pat_pregnancy pp --, speciality spec
             WHERE pr.id_pat_pregnancy = i_id_pat_pregnancy
               AND pr.flg_type = i_flg_type
               AND prof.id_professional = pr.id_professional
               AND pr.id_pat_pregnancy = pp.id_pat_pregnancy
            --AND spec.id_speciality(+) = prof.id_speciality
             ORDER BY pr.dt_pregn_register_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREGNANCY_REGISTER',
                                              o_error);
            pk_types.open_my_cursor(o_pregn_register);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pregnancy_register;

    FUNCTION get_time_event_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_reg   IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_val_det  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Devolve o detalhe de uma leitura/registo de um sinal vital ou an�lise
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PROF - profissional
                                 I_ID_REG - ID do registo
                                 I_FLG_TYPE - Tipo de registo S - sinal vital simples
                                                              C - sinal vital composto
                                                              A - an�lise
                                                              V - v�cinas
                        Saida:   O_ERROR - erro
        
          CRIA��O: JSILVA 21-06-2007
        *********************************************************************************/
    
        l_reg_vs_s VARCHAR2(0050);
        l_reg_vs_c VARCHAR2(0050);
        l_reg_a    VARCHAR2(0050);
        l_reg_drug VARCHAR2(0050);
        l_reg_vacc VARCHAR2(0050);
    
        l_vs_view_preg  VARCHAR2(0050);
        l_flg_view      VARCHAR2(0050);
        l_view_delivery VARCHAR2(0050);
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_reg_vs_s     := 'S';
        l_reg_vs_c     := 'C';
        l_reg_a        := 'A';
        l_reg_drug     := 'D';
        l_reg_vacc     := 'V';
    
        l_vs_view_preg  := 'P';
        l_flg_view      := 'PT';
        l_view_delivery := 'PG';
    
        g_error := 'GET REG DET';
    
        IF i_flg_type = l_reg_vs_s
        THEN
        
            OPEN o_val_det FOR
                SELECT *
                  FROM (
                        -- sinais vitais simples
                        SELECT nvl(decode(vsr.id_unit_measure,
                                            nvl(um.id_unit_measure, vsi.id_unit_measure),
                                            decode(vsr.value,
                                                   NULL,
                                                   pk_vital_sign.get_vs_alias(i_lang,
                                                                              vsr.id_patient,
                                                                              vdesc.code_vital_sign_desc),
                                                   -- converter n�meros decimais entre -1 e 1
                                                   CASE
                                                       WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                                        decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                                       ELSE
                                                        pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                                                        i_prof                => i_prof,
                                                                                        i_id_patient          => vsr.id_patient,
                                                                                        i_id_episode          => vsr.id_episode,
                                                                                        i_id_vital_sign       => nvl(vr.id_vital_sign_parent,
                                                                                                                     vsr.id_vital_sign),
                                                                                        i_id_vital_sign_desc  => vsr.id_vital_sign_desc,
                                                                                        i_dt_vital_sign_read  => vsr.dt_vital_sign_read_tstz,
                                                                                        i_id_unit_measure_vsr => vsr.id_unit_measure,
                                                                                        i_id_unit_measure_vsi => vsr.id_unit_measure,
                                                                                        i_value               => vsr.value,
                                                                                        i_decimal_symbol      => l_decimal_symbol,
                                                                                        i_relation_domain     => vr.relation_domain,
                                                                                        i_dt_registry         => vsr.dt_registry)
                                                   END || ' ' || pk_translation.get_translation(i_lang, um.code_unit_measure)),
                                            nvl(to_char(pk_unit_measure.get_unit_mea_conversion(nvl(vsr.value,
                                                                                                    pk_vital_sign.get_vs_alias(i_lang,
                                                                                                                               vsr.id_patient,
                                                                                                                               vdesc.code_vital_sign_desc)),
                                                                                                vsr.id_unit_measure,
                                                                                                nvl(um.id_unit_measure,
                                                                                                    vsi.id_unit_measure))),
                                                decode(vsr.value,
                                                       NULL,
                                                       pk_vital_sign.get_vs_alias(i_lang,
                                                                                  vsr.id_patient,
                                                                                  vdesc.code_vital_sign_desc),
                                                       -- converter n�meros decimais entre -1 e 1
                                                       CASE
                                                           WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                                            decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                                           ELSE
                                                            pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                                                            i_prof                => i_prof,
                                                                                            i_id_patient          => vsr.id_patient,
                                                                                            i_id_episode          => vsr.id_episode,
                                                                                            i_id_vital_sign       => nvl(vr.id_vital_sign_parent,
                                                                                                                         vsr.id_vital_sign),
                                                                                            i_id_vital_sign_desc  => vsr.id_vital_sign_desc,
                                                                                            i_dt_vital_sign_read  => vsr.dt_vital_sign_read_tstz,
                                                                                            i_id_unit_measure_vsr => vsr.id_unit_measure,
                                                                                            i_id_unit_measure_vsi => vsr.id_unit_measure,
                                                                                            i_value               => vsr.value,
                                                                                            i_decimal_symbol      => l_decimal_symbol,
                                                                                            i_relation_domain     => vr.relation_domain,
                                                                                            i_dt_registry         => vsr.dt_registry)
                                                       END)) || ' ' ||
                                            pk_translation.get_translation(i_lang, um.code_unit_measure)),
                                     pk_message.get_message(i_lang, 'COMMON_M002')) VALUE,
                                pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_reg,
                                -- Lu�s Maia 02-06-2008 (retorno da hora e minuto do registo
                                pk_date_utils.date_char_tsz(i_lang,
                                                            vsr.dt_vital_sign_read_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) dt_reg_f,
                                pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_reg,
                                -- ASANTOS 20-05-2009
                                -- Changes to include get_name_signature
                                pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_read,
                                -- LMAIA 11-03-2009
                                -- Changes to include get_spec_signature function
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 prof.id_professional,
                                                                 vsr.dt_vital_sign_read_tstz,
                                                                 vsr.id_episode) desc_speciality,
                                --pk_translation.get_translation(i_lang, spec.code_speciality) desc_speciality,
                                pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) flg_status
                          FROM vital_sign vs
                          JOIN vital_sign_read vsr
                            ON vsr.id_vital_sign = vs.id_vital_sign
                          JOIN professional prof
                            ON prof.id_professional = vsr.id_prof_read
                          JOIN vs_soft_inst vsi
                            ON vsi.id_vital_sign = vsr.id_vital_sign
                          LEFT JOIN unit_measure um
                            ON vsi.id_unit_measure = um.id_unit_measure
                          LEFT JOIN vital_sign_desc vdesc
                            ON vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc
                           AND vdesc.flg_available = pk_alert_constant.g_yes
                           AND vsr.id_vital_sign = vdesc.id_vital_sign
                          LEFT JOIN vital_sign_relation vr
                            ON vsr.id_vital_sign = vr.id_vital_sign_detail
                           AND vr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                           AND vr.flg_available = pk_alert_constant.g_yes
                         WHERE vsr.id_vital_sign_read = i_id_reg
                           AND vsi.id_software IN (i_prof.software, 0)
                           AND vsi.id_institution IN (i_prof.institution, 0)
                         ORDER BY vdesc.flg_available DESC)
                 WHERE rownum < 2;
        
        ELSIF i_flg_type = l_reg_vs_c
        THEN
        
            OPEN o_val_det FOR
            --sinais vitais compostos
                SELECT pk_utils.concatenate_list(CURSOR
                                                 (SELECT -- converter n�meros decimais entre -1 e 1
                                                   CASE
                                                       WHEN vsr2.value BETWEEN - 1 AND 1 THEN
                                                        decode(vsr2.value, 0, '0', '0' || to_char(vsr2.value))
                                                       ELSE
                                                        to_char(vsr2.value)
                                                   END
                                                    FROM vital_sign_read vsr2, vital_sign_relation vr
                                                   WHERE vsr2.id_vital_sign = vr.id_vital_sign_detail
                                                     AND vr.relation_domain = l_reg_vs_c
                                                     AND vsr2.id_patient = vsr.id_patient
                                                     AND vsr2.dt_vital_sign_read_tstz = vsr.dt_vital_sign_read_tstz
                                                     AND vr.id_vital_sign_parent =
                                                         (SELECT vr2.id_vital_sign_parent
                                                            FROM vital_sign_relation vr2
                                                           WHERE vr2.id_vital_sign_detail = vsr.id_vital_sign
                                                             AND vr2.relation_domain !=
                                                                 pk_alert_constant.g_vs_rel_percentile)
                                                   ORDER BY vr.rank),
                                                 '/') || ' ' ||
                       pk_translation.get_translation(i_lang, um.code_unit_measure) VALUE,
                       pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_reg,
                       -- Lu�s Maia 02-06-2008 (retorno da hora e minuto do registo
                       pk_date_utils.date_char_tsz(i_lang,
                                                   vsr.dt_vital_sign_read_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_reg_f,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_reg,
                       -- ASANTOS 20-05-2009
                       -- Changes to include get_name_signature
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_read,
                       -- LMAIA 11-03-2009
                       -- Changes to include get_spec_signature function
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        prof.id_professional,
                                                        vsr.dt_vital_sign_read_tstz,
                                                        vsr.id_episode) desc_speciality,
                       --pk_translation.get_translation(i_lang, spec.code_speciality) desc_speciality,
                       pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) flg_status
                  FROM vital_sign vs, unit_measure um, vital_sign_read vsr, professional prof
                --, speciality              spec
                 WHERE vsr.id_vital_sign_read = i_id_reg
                   AND vsr.id_vital_sign = vs.id_vital_sign
                   AND prof.id_professional = vsr.id_prof_read
                   AND vsr.id_unit_measure = um.id_unit_measure(+);
        
        ELSIF i_flg_type = l_reg_a
        THEN
        
            OPEN o_val_det FOR
            --resultados de an�lises
                SELECT decode(nvl(to_char(arp.desc_analysis_result), arp.analysis_result_value),
                               NULL,
                               pk_message.get_message(i_lang, 'COMMON_M002'),
                               nvl2(arp.analysis_result_value,
                                    CASE
                                        WHEN arp.analysis_result_value BETWEEN - 1 AND 1 THEN
                                         decode(arp.analysis_result_value, 0, '0', '0' || to_char(arp.analysis_result_value))
                                        ELSE
                                         to_char(arp.analysis_result_value)
                                    END,
                                    arp.desc_analysis_result) || ' ' ||
                               pk_translation.get_translation(i_lang, arp.code_unit_measure)) VALUE,
                       pk_date_utils.date_send_tsz(i_lang,
                                                   decode(ar.dt_sample, NULL, ar.dt_analysis_result_tstz, ar.dt_sample),
                                                   i_prof) dt_reg,
                       -- Lu�s Maia 02-06-2008 (retorno da hora e minuto do registo
                       pk_date_utils.date_char_tsz(i_lang,
                                                   decode(ar.dt_sample, NULL, ar.dt_analysis_result_tstz, ar.dt_sample),
                                                   i_prof.institution,
                                                   i_prof.software) dt_reg_f,
                       --RS 20071011 Reformulacao analises
                       -- Jos� Brito 19/02/2010 ALERT-75569
                       nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                     i_prof,
                                                                     'P',
                                                                     arp.code_analysis_parameter,
                                                                     NULL),
                           pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) desc_reg,
                       --
                       -- ASANTOS 20-05-2009
                       -- Changes to include get_name_signature
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_read,
                       -- LMAIA 11-03-2009
                       -- Changes to include get_spec_signature function
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        prof.id_professional,
                                                        ar.dt_analysis_result_tstz,
                                                        ar.id_episode) desc_speciality,
                       --pk_translation.get_translation(i_lang, spec.code_speciality) desc_speciality,
                       NULL flg_status,
                       --s�rgio s(If this field has a value then the result IS NOT normal) 2008-03-10
                       (SELECT abn.value
                          FROM abnormality abn
                         WHERE abn.id_abnormality = arp.id_abnormality) abnorm
                -- Jos� Brito 25/08/2008 Reestruturada a query para n�o devolver resultados repetidos,
                -- quando a institui��o usa duas (ou mais) unidades de medida nas an�lises
                  FROM analysis a,
                       analysis_result ar,
                       (SELECT arp1.id_analysis_result_par,
                               arp1.id_unit_measure,
                               aum.id_analysis,
                               arp1.id_analysis_result,
                               um.code_unit_measure,
                               arp1.analysis_result_value,
                               arp1.desc_analysis_result,
                               arp1.id_abnormality,
                               apmr.code_analysis_parameter
                          FROM analysis_result_par   arp1,
                               analysis_unit_measure aum,
                               unit_measure          um,
                               analysis_param        apm,
                               analysis_result       ar1,
                               analysis_parameter    apmr
                         WHERE arp1.id_analysis_result_par = i_id_reg
                           AND arp1.id_unit_measure = aum.id_unit_measure(+)
                           AND aum.id_unit_measure = um.id_unit_measure(+)
                           AND aum.id_software(+) = i_prof.software
                           AND aum.id_institution(+) = i_prof.institution
                           AND aum.flg_default(+) = pk_alert_constant.g_yes
                              -- Jos� Brito 19/02/2010 ALERT-75569
                           AND ar1.id_analysis = nvl(aum.id_analysis, ar1.id_analysis)
                           AND ar1.id_analysis_result = arp1.id_analysis_result
                           AND ar1.id_analysis = apm.id_analysis
                           AND apm.id_analysis_parameter = arp1.id_analysis_parameter
                           AND apm.id_analysis_parameter = nvl(aum.id_analysis_parameter, apm.id_analysis_parameter)
                           AND apmr.id_analysis_parameter = apm.id_analysis_parameter
                           AND apm.id_institution = i_prof.institution
                           AND apm.id_software = i_prof.software) arp,
                       professional prof
                 WHERE ar.id_analysis_result = arp.id_analysis_result
                   AND ar.id_analysis = a.id_analysis
                   AND ar.id_analysis = nvl(arp.id_analysis, ar.id_analysis)
                   AND ar.id_professional = prof.id_professional;
        
        ELSIF i_flg_type = l_reg_drug
        THEN
        
            IF NOT pk_api_pfh_clindoc_in.get_delivery_drug_det(i_lang    => i_lang,
                                                               i_prof    => i_prof,
                                                               i_id_reg  => i_id_reg,
                                                               o_val_det => o_val_det,
                                                               o_error   => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
        ELSIF i_flg_type = l_reg_vacc
        THEN
            OPEN o_val_det FOR
            -- vacinas
                SELECT pk_utils.concatenate_list(CURSOR
                                                 (SELECT vd.n_dose || ' ' ||
                                                         nvl(pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER',
                                                                                     vd.n_dose,
                                                                                     i_lang),
                                                             pk_sysdomain.get_domain('VACCINE.DOSE_NUMBER', 'O', i_lang)) || ': ' ||
                                                         pk_date_utils.dt_chr_tsz(i_lang, vda.dt_admin_tstz, i_prof)
                                                    FROM vaccine v2, vaccine_dose vd, vaccine_dose_admin vda
                                                   WHERE v2.id_vaccine = v.id_vaccine
                                                     AND to_char(v2.id_vaccine) = vd.medid
                                                     AND vda.id_vaccine_dose = vd.id_vaccine_dose
                                                     AND vda.id_vaccine_det = vdt.id_vaccine_det
                                                   ORDER BY vd.n_dose),
                                                 ', ') VALUE,
                       pk_date_utils.date_send_tsz(i_lang, vs.dt_vaccine_status_tstz, i_prof) dt_reg,
                       -- Lu�s Maia 02-06-2008 (retorno da hora e minuto do registo
                       pk_date_utils.date_char_tsz(i_lang,
                                                   vs.dt_vaccine_status_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_reg_f,
                       
                       pk_translation.get_translation(i_lang, v.code_vaccine) desc_reg,
                       -- ASANTOS 20-05-2009
                       -- Changes to include get_name_signature
                       pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) prof_read,
                       -- LMAIA 11-03-2009
                       -- Changes to include get_spec_signature function
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        prof.id_professional,
                                                        vs.dt_vaccine_status_tstz,
                                                        vdt.id_episode) desc_speciality,
                       --(SELECT pk_translation.get_translation(i_lang, spec.code_speciality)
                       --     FROM speciality spec
                       --    WHERE spec.id_speciality = prof.id_speciality) desc_speciality,
                       pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) flg_status
                  FROM vaccine v, vaccine_det vdt, vaccine_status vs, vaccine_desc vdesc, professional prof
                 WHERE to_char(v.id_vaccine) = vdt.medid
                   AND vdesc.id_vaccine = v.id_vaccine
                   AND vdesc.value = vs.flg_status
                   AND vs.id_vaccine_status = i_id_reg
                   AND vdt.id_vaccine_det = vs.id_vaccine_det
                   AND vs.id_professional = prof.id_professional(+);
        
        ELSE
            pk_types.open_my_cursor(o_val_det);
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
                                              'GET_TIME_EVENT_DET',
                                              o_error);
            pk_types.open_my_cursor(o_val_det);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_time_event_det;

    FUNCTION get_woman_health_non_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_doc_area     IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_values          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Devolve os elementos de um template com atributos n�o dispon�veis na documentation
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PROF - profissional
                                 I_ID_DOC_AREA - area da documenta��o
                                 I_ID_DOC_TEMPLATE - template associado
                        Saida:   O_VALUES - textos que v�o estar associados a elementos no momento da cria��o de um registo da documentation
                                 O_TYPE - tipo dos elementos
                                 O_ERROR - erro
        
          CRIA��O: JSILVA 23-08-2007
        *********************************************************************************/
    
        l_limit NUMBER; -- limite de registos a mostrar
        l_count NUMBER;
    
        l_flag BOOLEAN;
    
        l_aux_val VARCHAR2(4000);
    
        CURSOR c_vs_read IS
            SELECT vsr.id_vital_sign_read,
                   pk_date_utils.to_char_insttimezone(i_prof,
                                                      vsr.dt_vital_sign_read_tstz,
                                                      pk_sysconfig.get_config('DATE_HOUR_FORMAT_FLASH', i_prof)) dt_read,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_vital_sign,
                   to_char(vsr.value) desc_value
              FROM vital_sign_read vsr, vital_sign vs, pat_pregnancy pp, documentation_ext dext
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND vs.id_vital_sign = dext.value
               AND vs.id_vital_sign = vsr.id_vital_sign
               AND vsr.id_patient = pp.id_patient
               AND vsr.flg_state = g_vs_read_active
               AND dext.internal_name = 'VITAL_SIGN_WEIGHT'
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY vsr.dt_vital_sign_read_tstz DESC;
    
    BEGIN
    
        l_count   := 1;
        l_limit   := 3;
        l_aux_val := '';
    
        l_flag := FALSE;
    
        g_error := 'LOOP VS VALUES';
        FOR r_vs_read IN c_vs_read
        LOOP
        
            EXIT WHEN l_count = l_limit;
        
            IF l_flag
            THEN
                l_aux_val := l_aux_val || chr(10);
            END IF;
        
            l_aux_val := l_aux_val || r_vs_read.dt_read || ' ; ' || r_vs_read.desc_vital_sign || ' ' ||
                         r_vs_read.desc_value;
        
            l_flag  := TRUE;
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'OPEN CURSOR O_VALUES';
        OPEN o_values FOR
            SELECT de.id_doc_element, de.id_documentation, l_aux_val desc_val, '' val, dext.flg_mode
              FROM doc_element de, documentation_ext dext
             WHERE de.id_doc_element = dext.id_doc_element
               AND dext.internal_name = 'VITAL_SIGN_WEIGHT'
            UNION ALL
            SELECT de.id_doc_element, de.id_documentation, NULL desc_val, '' val, dext.flg_mode
              FROM doc_element de, documentation_ext dext
             WHERE de.id_doc_element = dext.id_doc_element
               AND dext.internal_name = 'DATE_DELIVERY_START'
            UNION ALL
            SELECT de.id_doc_element, de.id_documentation, NULL desc_val, '' val, dext.flg_mode
              FROM doc_element de, documentation_ext dext
             WHERE de.id_doc_element = dext.id_doc_element
               AND dext.internal_name = 'DATE_BIRTH'
             ORDER BY id_doc_element;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_NON_DOC',
                                              o_error);
            pk_types.open_my_cursor(o_values);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_woman_health_non_doc;

    /************************************************************************************************************
    * This function returns all patient's pregnancies
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient�s ID
    * @param      i_prof                        professional's ID
    * @param      o_preg                        pregnancies list
    * @param      o_error                       error message
    *
    * @return     a list with all pregnancies for the specified patient, if any
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/08/28
    ***********************************************************************************************************/
    FUNCTION get_pat_pregnancy_new
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_preg    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PREG';
        OPEN o_preg FOR
            SELECT id_pat_pregnancy,
                   n_pregnancy,
                   dt_last_menstruation,
                   pk_date_utils.dt_chr(i_lang, dt_last_menstruation, i_prof) dt_last_menstruation_desc,
                   CAST(dt_intervention AS DATE) dt_childbirth,
                   pk_date_utils.dt_chr(i_lang, CAST(dt_intervention AS DATE), i_prof) dt_childbirth_desc,
                   NULL flg_childbirth_type_desc,
                   --pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_CHILDBIRTH_TYPE', flg_childbirth_type, i_lang) flg_childbirth_type_desc,
                   NULL flg_childbirth_type,
                   -- jsilva 06-11-2007 n�mero de nados vivos com base no que � registado no partograma
                   nvl(pp.n_children, 1) n_children,
                   decode(trunc((SYSDATE - CAST(dt_intervention AS DATE)) / 365.25),
                          NULL,
                          'N/A',
                          1,
                          1 || ' ' || pk_message.get_message(i_lang, 'WOMAN_HEALTH_T073'),
                          trunc((SYSDATE - CAST(dt_intervention AS DATE)) / 365.25) || ' ' ||
                          pk_message.get_message(i_lang, 'WOMAN_HEALTH_T074')) current_age,
                   -- Todo: Anos est� hardcoded
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name active_icon,
                   get_flg_abort_ectopic_str(i_lang,
                                             NULL, --flg_abbort,
                                             NULL, --flg_abortion_type,
                                             num_gest_weeks,
                                             --flg_ectopic_pregnancy
                                             NULL) flg_abbort_desc,
                   NULL flg_abbort,
                   flg_status,
                   NULL flg_abortion_type,
                   CAST(dt_intervention AS DATE) dt_abortion,
                   num_gest_weeks gestation_time,
                   NULL flg_ectopic_pregnancy,
                   flg_status,
                   decode(flg_status, 'C', 'Y', 'N') flg_cancel,
                   pk_sysdomain.get_rank(i_lang, 'WOMAN_HEALTH.FLG_STATUS', flg_status) rank
            
              FROM pat_pregnancy pp, sys_domain sd
             WHERE sd.val = pp.flg_status
               AND sd.code_domain = 'WOMAN_HEALTH.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND id_patient = i_patient
               AND sd.id_language = i_lang
             ORDER BY rank ASC, n_pregnancy DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_PREGNANCY_NEW',
                                              o_error);
            pk_types.open_my_cursor(o_preg);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pat_pregnancy_new;

    /************************************************************************************************************
    * This function returns either the Abortion or Ectopic type description.
    *
    * @param      i_lang                        default language
    
    * @param      i_flg_abbort                  flag that indicates if it is an Abortion or an ecptopic pregnancy (depracated)
    * @param      i_flg_abortion_type           flag that indicates the abortion type
    * @param      i_gestation_time              time (in weeks) when the Abortion occurs
    * @param      i_flg_ectopic_pregnancy       flag that indicates if it is an ecptopic pregnancy or not
    * @param      o_error                       error message
    *
    * @return     VARCHAR with the label to be displayed
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/08/28
    ***********************************************************************************************************/
    FUNCTION get_flg_abort_ectopic_str
    (
        i_lang                  IN language.id_language%TYPE,
        i_flg_abbort            IN VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_abortion_type     IN VARCHAR2, --pat_pregnancy.flg_abortion_type%TYPE,
        i_gestation_time        IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_ectopic_pregnancy IN VARCHAR2 --pat_pregnancy.flg_ectopic_pregnancy%TYPE
        --o_error                 OUT VARCHAR2
    ) RETURN VARCHAR2 IS
    
        --label a ser retornada para apresenta��o no ecr�
        l_desc_abortion_label VARCHAR2(50) := NULL;
    
    BEGIN
    
        --identifica��o do tipo de Aborto/Gravidez Ect�pica
        SELECT decode(i_flg_abbort,
                      'A',
                      pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ABBORT', i_flg_abbort, i_lang),
                      'E',
                      pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ABBORT', i_flg_abbort, i_lang),
                      'N',
                      pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ABBORT', i_flg_abbort, i_lang),
                      decode(i_flg_ectopic_pregnancy,
                             'Y',
                             pk_message.get_message(i_lang, 'PAT_PREGNANCY_M003'),
                             decode(i_flg_abortion_type,
                                    'P',
                                    pk_message.get_message(i_lang, 'PAT_PREGNANCY_M002'),
                                    'E',
                                    pk_message.get_message(i_lang, 'PAT_PREGNANCY_M001'),
                                    pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_ABORTION_TYPE', i_flg_abortion_type, i_lang)))) ||
               decode(i_gestation_time,
                      NULL,
                      '',
                      ' (' || i_gestation_time || ' ' || pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001') || ')')
          INTO l_desc_abortion_label
          FROM dual;
    
        RETURN l_desc_abortion_label;
    EXCEPTION
        WHEN OTHERS THEN
            /*o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
            'PK_WOMAN_HEALTH.GET_FLG_ABORT_ECTOPIC_LABEL / ' || g_error || ' / ' || SQLERRM;*/
            RETURN NULL;
    END get_flg_abort_ectopic_str;

    /************************************************************************************************************
    * This function returns either the Abortion or Ectopic type description.
    *
    * @param      i_lang                        default language
    
    * @param      i_flg_abbort                  flag that indicates if it is an Abortion or an ecptopic pregnancy (depracated)
    * @param      i_flg_abortion_type           flag that indicates the abortion type
    * @param      i_gestation_time              time (in weeks) when the Abortion occurs
    * @param      i_flg_ectopic_pregnancy       flag that indicates if it is an ecptopic pregnancy or not
    * @param      o_error                       error message
    *
    * @return     VARCHAR with the label to be displayed
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/08/28
    ***********************************************************************************************************/
    FUNCTION get_flg_abort_ectopic_label
    (
        i_lang                  IN language.id_language%TYPE,
        i_flg_abbort            IN VARCHAR2, --pat_pregnancy.flg_abbort%TYPE,
        i_flg_abortion_type     IN VARCHAR2, --pat_pregnancy.flg_abortion_type%TYPE,
        i_gestation_time        IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_ectopic_pregnancy IN VARCHAR2, --pat_pregnancy.flg_ectopic_pregnancy%TYPE,
        o_l_flg_abbort_desc     OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_l_flg_abbort_desc := get_flg_abort_ectopic_str(i_lang,
                                                         i_flg_abbort,
                                                         i_flg_abortion_type,
                                                         i_gestation_time,
                                                         i_flg_ectopic_pregnancy);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FLG_ABORT_ECTOPIC_LABEL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_flg_abort_ectopic_label;

    /********************************************************************************************
    * Devolver o n�mero de semanas da gravidez activa
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_lines                  Static lines
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Carlos Ferreira
    * @since                          07-09-2007
    **********************************************************************************************/
    FUNCTION get_pregnancy_weeks
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_pat   IN NUMBER,
        o_age   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_weeks NUMBER;
        l_days  NUMBER;
        l_age   VARCHAR2(50);
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_max_weeks    NUMBER(6);
        l_flg_status   pat_pregnancy.flg_status%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy, pp.flg_status
              INTO l_dt_init_preg, l_flg_status
              FROM pat_pregnancy pp
             WHERE id_patient = i_pat
               AND flg_status IN (pk_pregnancy_core.g_pat_pregn_active, pk_pregnancy_core.g_pat_pregn_auto_close)
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN TRUE;
        END;
    
        g_error := 'GET PREGNANCY WEEKS';
        l_weeks := pk_pregnancy_api.get_pregnancy_weeks(i_prof, l_dt_init_preg, NULL, NULL);
        l_days  := pk_pregnancy_api.get_pregnancy_days(i_prof, l_dt_init_preg, NULL, NULL);
    
        l_max_weeks := to_number(pk_sysconfig.get_config('PREGNANCY_MAX_NUMBER_OF_WEEKS',
                                                         i_prof.institution,
                                                         i_prof.software));
    
        IF (l_weeks >= l_max_weeks AND l_flg_status = pk_pregnancy_core.g_pat_pregn_auto_close)
           OR (l_weeks IS NULL AND l_days IS NULL AND l_flg_status = pk_pregnancy_core.g_pat_pregn_active)
        THEN
            l_age := pk_message.get_message(i_lang, i_prof, 'PAT_PREGNANCY_M007');
        ELSE
        
            IF l_days > 0
            THEN
                l_age := ' ' || l_days || pk_message.get_message(i_lang, i_prof, 'DAY_SIGN');
            END IF;
        
            l_age := l_weeks || pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T063') || l_age;
        
        END IF;
    
        o_age := l_age;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PREGNANCY_WEEKS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_pregnancy_weeks;

    /************************************************************************************************************
    * Returns the parameters associated with a specified analysis
    *
    * @param      i_lang                language
    * @param      i_prof                profisisonal
    * @param      i_analysis            analysis' identifier
    *
    * @param      o_analysis_parameters cursor with the list of parameters
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/19
    ***********************************************************************************************************/

    FUNCTION get_analysis_parameters
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_analysis            IN analysis.id_analysis%TYPE,
        o_analysis_parameters OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_analysis_parameters FOR
            SELECT DISTINCT apm.id_analysis_parameter
              FROM analysis_param apm, analysis_parameter pa
             WHERE apm.id_analysis = i_analysis
               AND apm.flg_available = g_available
               AND apm.id_institution = i_prof.institution
               AND apm.id_software = i_prof.software
               AND pa.id_analysis_parameter = apm.id_analysis_parameter;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_PARAMETERS',
                                              o_error);
            pk_types.open_my_cursor(o_analysis_parameters);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_analysis_parameters;

    FUNCTION get_time_event_axis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_sign_v        OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Preencher ecr� com datas em que se registaram events da gr�vida,
                    os pr�prios events parametrizados e valores habituais para esses eventos
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                 I_PATIENT - ID do paciente
                                 I_PROF - ID do profissional
                                 I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
                                 I_PAT_PREGNANCY - ID da gravidez
                        Saida: O_TIME - Datas onde se registaram os eventos
                                 O_SIGN_V - Listar todos os sinais vitais registados no epis�dio
                                 O_VAL_HABIT - Cursor com valores habituais
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2007/01/17
          NOTA: Limita��o de datas de registos entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
        *********************************************************************************/
    
        l_flg_screen VARCHAR2(2) := 'D'; -- This is always a Detail call
        l_flg_view   VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
        l_age         vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        ----------------------------------------------------------
        -- Tempos de registo
        ----------------------------------------------------------
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        g_error := 'GET CFG_VARS';
        IF NOT (get_cfg_vars(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_flg_view => l_flg_view,
                             o_inst     => l_institution,
                             o_soft     => l_software,
                             o_error    => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'OPEN CURSOR O_TIME';
        OPEN o_time FOR
        
        ------------------------------------------------------
        -- Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vsr.dt_vital_sign_read_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vs_read_tstz,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            -- TODO: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
                            pk_date_utils.dt_chr_year_short_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) || '|' ||
                            trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' header_desc
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   sys_message      sm,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active OR nvl(l_flg_screen, 'D') = 'D')
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- Sinais Vitais Compostos (ex: Press�o Arterial)
            ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vsr.dt_vital_sign_read_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vs_read_tstz,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            pk_date_utils.dt_chr_year_short_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) || '|' ||
                            trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(vsr.dt_vital_sign_read_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vital_sign_relation vsre,
                   vs_soft_inst        vsi,
                   sys_message         sm,
                   event               e,
                   event_group         eg,
                   time_event_group    teg,
                   pat_pregnancy       pp
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active OR nvl(l_flg_screen, 'D') = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- An�lises
            ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               decode(ar.dt_sample,
                                                                                      NULL,
                                                                                      vsr.dt_analysis_result_par_tstz,
                                                                                      ar.dt_sample),
                                                                               g_dt_format),
                                            g_dt_format) dt_vs_read_tstz,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               vsr.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) dt_vital_sign_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                  decode(ar.dt_sample,
                                                                         NULL,
                                                                         vsr.dt_analysis_result_par_tstz,
                                                                         ar.dt_sample),
                                                                  i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             decode(ar.dt_sample,
                                                                    NULL,
                                                                    vsr.dt_analysis_result_par_tstz,
                                                                    ar.dt_sample),
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               vsr.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) short_dt_read,
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          decode(ar.dt_sample,
                                                                                 NULL,
                                                                                 vsr.dt_analysis_result_par_tstz,
                                                                                 ar.dt_sample),
                                                                          i_prof),
                                    '-') ||
                            decode(ar.dt_sample, NULL, ' ' || pk_message.get_message(i_lang, 'COMMON_M052'), '') || '|' ||
                            trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                  pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                         pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' || '|' ||
                            decode(ar.dt_sample, NULL, 'Y', 'N') header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = vsr.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   pp.dt_init_pregnancy AND pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- Vacinas
            ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vst.dt_vaccine_status_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vs_read_tstz,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof),
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vst.dt_vaccine_status_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) short_dt_read,
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof),
                                    '-') || '|' ||
                            trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM vaccine          vs,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   sys_message      sm,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY dt_vs_read_tstz ASC;
    
        ----------------------------------------------------------
        -- Eventos parametrizados
        ----------------------------------------------------------
        g_error := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
        ------------------------------------------------------
        -- Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
            
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
                  
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
            
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = emf.id_group
               AND emf.flg_group = e.flg_group
               AND e.id_group = emf.id_group
               AND e.id_group = vs.id_vital_sign
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
                  
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- Sinais Vitais Compostos (ex: Press�o Arterial)
            ------------------------------------------------------
            SELECT DISTINCT vsre.id_vital_sign_parent,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
            
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg,
                   pat_pregnancy       pp
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- An�lises
            ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'P',
                                                                      pa.code_analysis_parameter,
                                                                      NULL) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            vsi.flg_fill_type
            
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            UNION
            SELECT DISTINCT vs.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'P',
                                                                      pa.code_analysis_parameter,
                                                                      NULL) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            vsi.flg_fill_type
            
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- Vacinas
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vaccine,
                            pk_translation.get_translation(i_lang, vs.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            vs.rank,
                            1 val_min,
                            2 val_max,
                            '0xFFFFFF' color_grafh,
                            '0xCCCCCC' color_text,
                            'N.A.' desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            NULL flg_fill_type
            
              FROM vaccine          vs,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        ----------------------------------------------------------
        -- Valores Habituais
        -- TODO: Valores habituais poderiam vir no O_TIME
        ----------------------------------------------------------
    
        OPEN o_val_habit FOR
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, vdesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   vaccine_desc     vdesc
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
               AND (vdesc.id_vaccine(+) = e.id_group AND e.flg_group = 'V' AND
                   (vdesc.id_vaccine_desc IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) = emf.value))
            UNION
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, adesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   analysis_desc    adesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
               AND (adesc.id_analysis(+) = e.id_group AND e.flg_group = 'A' AND
                   (adesc.id_analysis IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, adesc.code_analysis_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   NULL icon
              FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
                  
               AND e.flg_group = 'VS';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_AXIS_DET',
                                              o_error);
            pk_types.open_my_cursor(o_sign_v);
            pk_types.open_my_cursor(o_time);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_time_event_all_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_vs        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Retorna para cada data de registo / event da gr�vida, os valores,
                      sendo estes visualizados numa grelha
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                                    I_PATIENT - ID Pacient
                                 I_PROF - ID do profissional
                                 I_INTERN_NAME - Intern Name do TIME_EVENT_GROUP
                                 I_PAT_PREGNANCY - ID da gravidez
                        Saida: O_VAL_VS - Array para cada event / tempo de leitura, os respectivos valores
                         O_ERROR - Erro
        
          CRIA��O: RdSN 2006/12/12
          NOTA: Os sinais vitais apresentados s�o tanto os ACTIVOS como os CANCELADOS
        *********************************************************************************/
    
        --
        i NUMBER := 0;
    
        l_value     VARCHAR2(20);
        l_sinal     VARCHAR2(20) := 'FALSE';
        l_array_val VARCHAR2(4000) := NULL;
        l_sep       VARCHAR2(1) := ';';
    
        l_time     VARCHAR2(200);
        l_cont     NUMBER;
        l_reg_cont NUMBER;
    
        l_temp       VARCHAR2(4000);
        l_temp2      VARCHAR2(4000);
        l_glasgow    NUMBER;
        l_rel_domain vital_sign_relation.relation_domain%TYPE;
    
        l_flg_screen VARCHAR2(2) := 'D'; -- This is always a Detail call
        l_flg_view   VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
        ----------------------------------------------------------
        -- TEMPOS de registo
        ----------------------------------------------------------
        CURSOR c_time IS
        ------------------------------------------------------
        -- TEMPOS - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vsr.dt_vital_sign_read_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM vital_sign_read vsr, vital_sign vs, vs_soft_inst vsi, event e, event_group eg, time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            UNION
            ------------------------------------------------------
            -- TEMPOS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vsr.dt_vital_sign_read_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vital_sign_relation vsre,
                   vs_soft_inst        vsi,
                   event               e,
                   event_group         eg,
                   time_event_group    teg
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            UNION
            ------------------------------------------------------
            -- TEMPOS - An�lises
            ------------------------------------------------------
            
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vsr.dt_analysis_result_par_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_analysis_result_par_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_analysis_result = vsr.id_analysis_result(+)
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            UNION
            ------------------------------------------------------
            -- TEMPOS - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT to_timestamp_tz(pk_date_utils.to_char_insttimezone(i_prof,
                                                                               vst.dt_vaccine_status_tstz,
                                                                               g_dt_format),
                                            g_dt_format) dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vst.dt_vaccine_status_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM vaccine vs, vaccine_det vd, vaccine_status vst, event e, event_group eg, time_event_group teg
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
             ORDER BY dt_vital_sign_read ASC;
    
        ----------------------------------------------------------
        -- EVENTS
        ----------------------------------------------------------
        CURSOR c_vital IS
        ------------------------------------------------------
        -- EVENTS - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign, vsi.rank, e.flg_group, NULL sample_type_desc
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
                  -- Jos� Brito 19/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                  --
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            UNION
            -- vs mais frequentes
            SELECT DISTINCT vs.id_vital_sign, vsi.rank, e.flg_group, NULL sample_type_desc
            
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = emf.id_group
               AND emf.flg_group = e.flg_group
                  
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND emf.id_pat_pregnancy = i_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- EVENTS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT vsre.id_vital_sign_parent, vsi.rank, e.flg_group, NULL sample_type_desc
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- EVENTS - An�lises
            ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis,
                            NULL rank,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND vsr.desc_analysis_result IS NOT NULL
                  --               AND vsi.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            -- analises mais frequentes
            SELECT DISTINCT vs.id_analysis,
                            NULL rank,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc
            
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND emf.id_pat_pregnancy = i_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- EVENTS - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vaccine, vs.rank, e.flg_group, NULL sample_type_desc --VSI.RANK
              FROM vaccine vs, vaccine_det vd, vaccine_status vst, event e, event_group eg, time_event_group teg
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        ----------------------------------------------------------
        -- VALORES
        ----------------------------------------------------------
        CURSOR c_values_vs
        (
            i_vital_sign NUMBER,
            i_data_read  CHAR
        ) IS
        ------------------------------------------------------
        -- VALORES - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT decode(vsr.id_unit_measure,
                           vsi.id_unit_measure,
                           decode(vsr.value,
                                  NULL,
                                  pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                  -- converter n�meros decimais entre -1 e 1
                                  CASE
                                      WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                       decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                      ELSE
                                       to_char(vsr.value)
                                  END),
                           nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                               vsr.id_unit_measure,
                                                                               vsi.id_unit_measure)),
                               decode(vsr.value,
                                      NULL,
                                      pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                      -- converter n�meros decimais entre -1 e 1
                                      CASE
                                          WHEN vsr.value BETWEEN - 1 AND 1 THEN
                                           decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                                          ELSE
                                           to_char(vsr.value)
                                      END))) || '|' || nvl(vdesc.icon, 'X') ||
                    decode(vdesc.value, NULL, NULL, '|' || vdesc.value) VALUE,
                   vsr.id_vital_sign_read,
                   '' relation_domain,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'S' flg_reg,
                   vs.rank
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- Jos� Brito 19/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                  --
               AND vsr.id_vital_sign = i_vital_sign
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software = l_software
               AND vsi.id_institution = l_institution
               AND vsi.flg_view = l_flg_view
               AND pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYY/MM/DD HH24:MI:SS') =
                   i_data_read
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION ALL
            ------------------------------------------------------
            -- VALORES - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT -- converter n�meros decimais entre -1 e 1
             CASE
                 WHEN vsr.value BETWEEN - 1 AND 1 THEN
                  decode(vsr.value, 0, '0', '0' || to_char(vsr.value))
                 ELSE
                  to_char(vsr.value)
             END VALUE,
             vsr.id_vital_sign_read,
             vr.relation_domain,
             decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
             'C' flg_reg,
             vr.rank
              FROM vital_sign_relation vr, vital_sign_read vsr, event e, event_group eg, time_event_group teg
             WHERE (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vr.id_vital_sign_detail = vsr.id_vital_sign
               AND vr.id_vital_sign_parent = i_vital_sign
               AND vr.relation_domain = g_vs_rel_conc
               AND pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_vital_sign_read_tstz, 'YYYY/MM/DD HH24:MI:SS') =
                   i_data_read
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = i_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
             ORDER BY rank;
    
        CURSOR c_values_a
        (
            i_vital_sign NUMBER,
            i_data_read  CHAR
        ) IS
        ------------------------------------------------------
        -- VALORES - An�lises
        ------------------------------------------------------
            SELECT vsr.desc_analysis_result || '|' || nvl(adesc.icon, 'X') ||
                   decode(adesc.value, NULL, NULL, '|' || adesc.value) VALUE,
                   vsr.id_analysis_result_par id_vital_sign_read,
                   '' relation_domain,
                   'A' reg,
                   'A' flg_reg
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vs.id_analysis = i_vital_sign
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_analysis_result_par_tstz, 'YYYY/MM/DD HH24:MI:SS') =
                   i_data_read
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND adesc.id_analysis(+) = vs.id_analysis
               AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                   to_char(vsr.desc_analysis_result))
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
        CURSOR c_values_v
        (
            i_vital_sign NUMBER,
            i_data_read  CHAR
        ) IS
        ------------------------------------------------------
        -- VALORES - Vacinas
        ------------------------------------------------------
            SELECT pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) || '|' || vdesc.icon ||
                   decode(vdesc.value, NULL, NULL, '|' || vdesc.value) VALUE,
                   vst.id_vaccine_status id_vital_sign_read,
                   '' relation_domain,
                   vst.flg_active reg,
                   'V' flg_reg
              FROM vaccine          vs,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   vaccine_desc     vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.flg_available = g_vs_avail
               AND to_char(vs.id_vaccine) = vd.medid
               AND vs.id_vaccine = i_vital_sign
               AND vdesc.id_vaccine(+) = vs.id_vaccine
               AND vdesc.value = vst.flg_status
               AND pk_date_utils.to_char_insttimezone(i_prof, vst.dt_vaccine_status_tstz, 'YYYY/MM/DD HH24:MI:SS') =
                   i_data_read
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'INICIALIZA��O';
        o_val_vs       := table_varchar(); -- inicializa��o do vector
        g_error        := 'GET CURSOR C_VITAL';
        pk_alertlog.log_debug('DATE ' || to_char(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
    
        g_error := 'GET CFG_VARS';
        IF NOT (get_cfg_vars(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_flg_view => l_flg_view,
                             o_inst     => l_institution,
                             o_soft     => l_software,
                             o_error    => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'OPEN C_PAT_PREGN';
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        FOR r_vital IN c_vital
        LOOP
            IF r_vital.id_vital_sign = 18
            THEN
                pk_alertlog.log_debug('************R_VITAL.ID_VITAL_SIGN ' || r_vital.id_vital_sign);
                pk_alertlog.log_debug('DATE ' || to_char(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
            END IF;
            --
        
            IF l_sinal = 'TRUE'
            THEN
            
                -- nova linha para o ARRAY
            
                o_val_vs(i) := l_array_val || l_sep;
            
            END IF;
        
            i := i + 1;
        
            o_val_vs.extend; -- o array O_VAL_VS tem mais uma linha
            l_array_val := NULL;
        
            IF l_array_val IS NULL
            THEN
            
                l_array_val := r_vital.id_vital_sign || l_sep;
            
            END IF;
        
            g_error := 'GET CURSOR C_TIME';
            FOR r_time IN c_time
            LOOP
            
                l_time := pk_date_utils.to_char_insttimezone(i_prof, r_time.dt_vital_sign_read, 'YYYY/MM/DD HH24:MI:SS');
            
                l_value := 'FALSE';
                g_error := 'GET CURSOR C_REG';
            
                l_cont     := 0;
                l_reg_cont := 0;
            
                g_error := 'GET CURSOR C_VALUES' || r_vital.id_vital_sign || '-' || l_time;
            
                IF r_vital.flg_group = 'VS'
                THEN
                
                    FOR r_val IN c_values_vs(r_vital.id_vital_sign, l_time)
                    LOOP
                    
                        g_error      := 'GET CURSOR C_VALUES LOOP';
                        l_rel_domain := r_val.relation_domain;
                    
                        g_error := 'BEFORE IF - ' || l_cont || ' - ' || l_rel_domain || ' - ' || r_val.relation_domain;
                        IF l_cont = 0
                        THEN
                        
                            g_error := 'L_CONT = 0';
                            l_temp  := r_val.value;
                            g_error := 'L_TEMP';
                            l_temp2 := r_val.id_vital_sign_read;
                        
                            g_error := 'BEFORE IF 2';
                            IF r_val.relation_domain = g_vs_rel_sum
                            THEN
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|';
                                l_glasgow   := nvl(l_glasgow, 0) + r_val.value;
                            ELSE
                                g_error     := 'L_CONT != 0';
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|' || r_val.value;
                            END IF;
                        
                            l_value := 'TRUE';
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_conc
                        THEN
                        
                            l_array_val := l_array_val || '/' || r_val.value || '|X'; -- || L_SEP;
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_sum
                        THEN
                            l_glasgow := nvl(l_glasgow, 0) + r_val.value;
                        
                        ELSIF l_cont = 2
                        THEN
                        
                            g_error := 'L_CONT = 2';
                            IF l_temp2 != r_val.id_vital_sign_read
                               AND r_vital.flg_group = 'VS'
                            THEN
                                g_error   := 'INSIDE IF';
                                l_glasgow := nvl(l_glasgow, 0) + r_val.value;
                            END IF;
                        END IF;
                    
                        g_error := 'AFTER IF';
                        l_cont  := l_cont + 1;
                    END LOOP; -- C_VALUES
                
                ELSIF r_vital.flg_group = 'A'
                THEN
                
                    FOR r_val IN c_values_a(r_vital.id_vital_sign, l_time)
                    LOOP
                    
                        g_error      := 'GET CURSOR C_VALUES LOOP';
                        l_rel_domain := r_val.relation_domain;
                    
                        g_error := 'BEFORE IF - ' || l_cont || ' - ' || l_rel_domain || ' - ' || r_val.relation_domain;
                        IF l_cont = 0
                        THEN
                        
                            g_error := 'L_CONT = 0';
                            l_temp  := r_val.value;
                            g_error := 'L_TEMP';
                            l_temp2 := r_val.id_vital_sign_read;
                        
                            g_error := 'BEFORE IF 2';
                            IF r_val.relation_domain = g_vs_rel_sum
                            THEN
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|';
                                l_glasgow   := nvl(l_glasgow, 0) + to_char(r_val.value);
                            ELSE
                                g_error     := 'L_CONT != 0';
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|' || r_val.value;
                            END IF;
                        
                            l_value := 'TRUE';
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_conc
                        THEN
                        
                            l_array_val := l_array_val || '/' || r_val.value || '|X'; -- || L_SEP;
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_sum
                        THEN
                            l_glasgow := nvl(l_glasgow, 0) + to_char(r_val.value);
                        
                        ELSIF l_cont = 2
                        THEN
                        
                            g_error := 'L_CONT = 2';
                            IF l_temp2 != r_val.id_vital_sign_read
                               AND r_vital.flg_group = 'VS'
                            THEN
                                g_error   := 'INSIDE IF';
                                l_glasgow := nvl(l_glasgow, 0) + to_char(r_val.value);
                            END IF;
                        END IF;
                    
                        g_error := 'AFTER IF';
                        l_cont  := l_cont + 1;
                    END LOOP; -- C_VALUES
                
                ELSIF r_vital.flg_group = 'V'
                THEN
                
                    FOR r_val IN c_values_v(r_vital.id_vital_sign, l_time)
                    LOOP
                    
                        g_error      := 'GET CURSOR C_VALUES LOOP';
                        l_rel_domain := r_val.relation_domain;
                    
                        g_error := 'BEFORE IF - ' || l_cont || ' - ' || l_rel_domain || ' - ' || r_val.relation_domain;
                        IF l_cont = 0
                        THEN
                        
                            g_error := 'L_CONT = 0';
                            l_temp  := r_val.value;
                            g_error := 'L_TEMP';
                            l_temp2 := r_val.id_vital_sign_read;
                        
                            g_error := 'BEFORE IF 2';
                            IF r_val.relation_domain = g_vs_rel_sum
                            THEN
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|';
                                l_glasgow   := nvl(l_glasgow, 0) + r_val.value;
                            ELSE
                                g_error     := 'L_CONT != 0';
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|' || r_val.value;
                            END IF;
                        
                            l_value := 'TRUE';
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_conc
                        THEN
                        
                            l_array_val := l_array_val || '/' || r_val.value || '|X'; -- || L_SEP;
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_sum
                        THEN
                            l_glasgow := nvl(l_glasgow, 0) + r_val.value;
                        
                        ELSIF l_cont = 2
                        THEN
                        
                            g_error := 'L_CONT = 2';
                            IF l_temp2 != r_val.id_vital_sign_read
                               AND r_vital.flg_group = 'VS'
                            THEN
                                g_error   := 'INSIDE IF';
                                l_glasgow := nvl(l_glasgow, 0) + r_val.value;
                            END IF;
                        END IF;
                    
                        g_error := 'AFTER IF';
                        l_cont  := l_cont + 1;
                    END LOOP; -- C_VALUES
                END IF; ---IF R_VITAL.FLG_GROUP
            
                g_error := 'L_CONT IF 1';
            
                IF l_cont IN (1, 2, 3)
                THEN
                    g_error := 'L_CONT IF 2';
                
                    IF l_rel_domain = g_vs_rel_sum
                    THEN
                        g_error     := 'L_CONT IF 3';
                        l_array_val := l_array_val || to_char(l_glasgow);
                    
                    END IF;
                
                    g_error := 'L_CONT IF 4';
                END IF;
            
                g_error     := 'L_CONT IF 5';
                l_array_val := l_array_val || l_sep; -- novo
            END LOOP;
        
            l_sinal := 'TRUE';
        
        END LOOP;
    
        g_error := 'L_CONT IF 6 - ' || i;
        IF i > 0
        --AND o_val_vs.LIMIT >= i
        THEN
            o_val_vs(i) := l_array_val || l_sep;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_ALL_DET',
                                              o_error);
            o_val_vs := table_varchar();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --

    /************************************************************************************************************
    * Preencher ecr� com datas em que se registaram events da gr�vida,
    * os pr�prios events parametrizados e valores habituais para esses eventos
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    * @param      o_time                Datas onde se registaram os eventos
    * @param      o_analysis              Listar todos os sinais vitais registados no epis�dio
    * @param      o_val_habit           Cursor com valores habituais
    * @param      o_error               Erro
    *
    *  CRIA��O: RdSN 2007/01/17
    *  ALTERA��O : Orlando Antunes
    *  NOTA: Limita��o de datas de registos entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
    *  NOTA2: Esta fun��o resultou da simplifica��o da get_time_event_axis_det apenas para o caso das
    *         an�lises.
    ***********************************************************************************************************/
    FUNCTION get_analysis_time_ev_axis_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type,
        o_analysis      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        ----------------------------------------------------------
        -- Tempos de registo
        ----------------------------------------------------------
    
        g_error := 'OPEN CURSOR O_TIME';
        OPEN o_time FOR
        
        ------------------------------------------------------
        -- An�lises
        ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) dt_vital_sign_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_analysis_result_par_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_analysis_result_par_tstz, i_prof) short_dt_read,
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          vsr.dt_analysis_result_par_tstz,
                                                                          i_prof),
                                    '-') ||
                            decode(ar.dt_sample, NULL, ' ' || pk_message.get_message(i_lang, 'COMMON_M052'), '') || '|' ||
                            trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                  pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                         pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' || '|' ||
                            decode(ar.dt_sample, NULL, 'Y', 'N') header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = vsr.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   pp.dt_init_pregnancy AND pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY short_dt_read, hour_read ASC;
    
        ----------------------------------------------------------
        -- Eventos parametrizados
        ----------------------------------------------------------
        g_error := 'OPEN CURSOR o_analysis';
        OPEN o_analysis FOR
        ------------------------------------------------------
        -- An�lises
        ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'P',
                                                                      pa.code_analysis_parameter,
                                                                      NULL) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            vsi.flg_fill_type
            
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            UNION
            SELECT DISTINCT vs.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'P',
                                                                      pa.code_analysis_parameter,
                                                                      NULL) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = vsum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = vsum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            vsi.rank,
                            vsum.val_min,
                            vsum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = vsum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = vsum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            vsi.flg_fill_type
            
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(vsum.id_unit_measure, 0) = nvl(vsi.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        ----------------------------------------------------------
        -- Valores Habituais
        -- TODO: Valores habituais poderiam vir no O_TIME
        ----------------------------------------------------------
    
        OPEN o_val_habit FOR
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, vdesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   vaccine_desc     vdesc
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
               AND (vdesc.id_vaccine(+) = e.id_group AND e.flg_group = 'V' AND
                   (vdesc.id_vaccine_desc IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) = emf.value))
            UNION
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, adesc.icon) icon
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   analysis_desc    adesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
               AND (adesc.id_analysis(+) = e.id_group AND e.flg_group = 'A' AND
                   (adesc.id_analysis IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, adesc.code_analysis_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   NULL icon
              FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M036'
               AND sm.id_language = i_lang
                  
               AND e.flg_group = 'VS';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_AXIS_DET',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_time);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_analysis_time_ev_axis_det;

    /************************************************************************************************************
    * Retorna para cada data de registo / event da gr�vida, os valores,
    * sendo estes visualizados numa grelha.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    * @param      o_val_analysis              Datas Array para cada event / tempo de leitura, os respectivos valores
    * @param      o_error               Erro
    *
    *  CRIA��O: RdSN 2007/01/17
    *  ALTERA��O : Orlando Antunes
    *  NOTA: Os sinais vitais apresentados s�o tanto os ACTIVOS como os CANCELADOS
    *  NOTA2: Esta fun��o resultou da simplifica��o da get_time_event_all_det apenas para o caso das
    *         an�lises.
    ***********************************************************************************************************/
    FUNCTION get_analysis_time_ev_all_det
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_val_analysis  OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --
        i NUMBER := 0;
    
        l_value     VARCHAR2(20);
        l_sinal     VARCHAR2(20) := 'FALSE';
        l_array_val VARCHAR2(4000) := NULL;
        l_sep       VARCHAR2(1) := ';';
    
        l_time     VARCHAR2(200);
        l_cont     NUMBER;
        l_reg_cont NUMBER;
    
        l_temp       VARCHAR2(4000);
        l_temp2      VARCHAR2(4000);
        l_glasgow    NUMBER;
        l_rel_domain vital_sign_relation.relation_domain%TYPE;
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
        ----------------------------------------------------------
        -- TEMPOS de registo
        ----------------------------------------------------------
        CURSOR c_time IS
        ------------------------------------------------------
        -- TEMPOS - An�lises
        ------------------------------------------------------
        
            SELECT DISTINCT decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               vsr.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                  decode(ar.dt_sample,
                                                                         NULL,
                                                                         vsr.dt_analysis_result_par_tstz,
                                                                         ar.dt_sample),
                                                                  i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             decode(ar.dt_sample,
                                                                    NULL,
                                                                    vsr.dt_analysis_result_par_tstz,
                                                                    ar.dt_sample),
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          decode(ar.dt_sample,
                                                                                 NULL,
                                                                                 vsr.dt_analysis_result_par_tstz,
                                                                                 ar.dt_sample),
                                                                          i_prof),
                                    '-') ||
                            decode(ar.dt_sample, NULL, ' ' || pk_message.get_message(i_lang, 'COMMON_M052'), '') || '|' ||
                            trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                  pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                         pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' || '|' ||
                            decode(ar.dt_sample, NULL, 'Y', 'N') header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE vs.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = vsr.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(decode(ar.dt_sample, NULL, vsr.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   pp.dt_init_pregnancy AND pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
             ORDER BY short_dt_read, hour_read ASC;
        ----------------------------------------------------------
        -- EVENTS
        ----------------------------------------------------------
        CURSOR c_vital IS
        
        ------------------------------------------------------
        -- EVENTS - An�lises
        ------------------------------------------------------
            SELECT DISTINCT vs.id_analysis id_vital_sign,
                            NULL rank,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND vsr.desc_analysis_result IS NOT NULL
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            -- analises mais frequentes
            SELECT DISTINCT vs.id_analysis id_vital_sign,
                            NULL rank,
                            e.flg_group,
                            decode(vs.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(vs.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc
            
              FROM analysis                    vs,
                   analysis_param_funcionality vsi,
                   analysis_unit_measure       vsum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   event_most_freq             emf,
                   analysis_parameter          pa,
                   analysis_param              apar
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis(+) = vs.id_analysis
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND vsum.id_analysis(+) = vs.id_analysis
                  -- ALERT-51560
               AND nvl(vsum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
               AND vsum.id_institution(+) = i_prof.institution
               AND vsum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND emf.id_pat_pregnancy = i_pat_pregnancy
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        ----------------------------------------------------------
        -- VALORES
        ----------------------------------------------------------
    
        CURSOR c_values_a
        (
            i_vital_sign NUMBER,
            i_data_read  CHAR
        ) IS
        ------------------------------------------------------
        -- VALORES - An�lises
        ------------------------------------------------------
            SELECT vsr.desc_analysis_result || '|' || nvl(adesc.icon, 'X') ||
                   decode(adesc.value, NULL, NULL, '|' || adesc.value) VALUE,
                   vsr.id_analysis_result_par id_vital_sign_read,
                   '' relation_domain,
                   'A' reg,
                   'A' flg_reg
              FROM analysis_result_par         vsr,
                   analysis                    vs,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality vsi,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE vs.flg_available = g_vs_avail
               AND apar.id_analysis = i_vital_sign
               AND vsi.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND vsi.flg_type = 'M'
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pk_date_utils.to_char_insttimezone(i_prof, vsr.dt_analysis_result_par_tstz, 'YYYY/MM/DD HH24:MI:SS') =
                   i_data_read
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND adesc.id_analysis(+) = vs.id_analysis
               AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                   to_char(vsr.desc_analysis_result))
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = vs.id_analysis
               AND vsr.id_analysis_parameter = apar.id_analysis_parameter
                  
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = vsr.id_analysis_result
               AND e.id_group = vs.id_analysis
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'INICIALIZA��O';
        o_val_analysis := table_varchar(); -- inicializa��o do vector
        g_error        := 'GET CURSOR C_VITAL';
        pk_alertlog.log_debug('DATE ' || to_char(SYSDATE, 'YYYY/MM/DD HH24:MI:SS'));
    
        g_error := 'OPEN C_PAT_PREGN';
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        FOR r_vital IN c_vital
        LOOP
            --
        
            IF l_sinal = 'TRUE'
            THEN
            
                -- nova linha para o ARRAY
            
                o_val_analysis(i) := l_array_val || l_sep;
            
            END IF;
        
            i := i + 1;
        
            o_val_analysis.extend; -- o array o_val_analysis tem mais uma linha
            l_array_val := NULL;
        
            IF l_array_val IS NULL
            THEN
            
                l_array_val := r_vital.id_vital_sign || l_sep;
            
            END IF;
        
            g_error := 'GET CURSOR C_TIME';
            FOR r_time IN c_time
            LOOP
            
                l_time := pk_date_utils.to_char_insttimezone(i_prof, r_time.dt_vital_sign_read, 'YYYY/MM/DD HH24:MI:SS');
            
                l_value := 'FALSE';
                g_error := 'GET CURSOR C_REG';
            
                l_cont     := 0;
                l_reg_cont := 0;
            
                g_error := 'GET CURSOR C_VALUES' || r_vital.id_vital_sign || '-' || l_time;
            
                IF r_vital.flg_group = 'A'
                THEN
                
                    FOR r_val IN c_values_a(r_vital.id_vital_sign, l_time)
                    LOOP
                    
                        g_error      := 'GET CURSOR C_VALUES LOOP';
                        l_rel_domain := r_val.relation_domain;
                    
                        g_error := 'BEFORE IF - ' || l_cont || ' - ' || l_rel_domain || ' - ' || r_val.relation_domain;
                        IF l_cont = 0
                        THEN
                        
                            g_error := 'L_CONT = 0';
                            l_temp  := r_val.value;
                            g_error := 'L_TEMP';
                            l_temp2 := r_val.id_vital_sign_read;
                        
                            g_error := 'BEFORE IF 2';
                            IF r_val.relation_domain = g_vs_rel_sum
                            THEN
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|';
                                l_glasgow   := nvl(l_glasgow, 0) + to_char(r_val.value);
                            ELSE
                                g_error     := 'L_CONT != 0';
                                l_array_val := l_array_val || r_val.id_vital_sign_read || '|' || r_val.flg_reg || '|' ||
                                               r_val.reg || '|' || r_val.value;
                            END IF;
                        
                            l_value := 'TRUE';
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_conc
                        THEN
                        
                            l_array_val := l_array_val || '/' || r_val.value || '|X'; -- || L_SEP;
                        
                        ELSIF l_cont = 1
                              AND r_val.relation_domain = g_vs_rel_sum
                        THEN
                            l_glasgow := nvl(l_glasgow, 0) + to_char(r_val.value);
                        
                        ELSIF l_cont = 2
                        THEN
                        
                            g_error := 'L_CONT = 2';
                            IF l_temp2 != r_val.id_vital_sign_read
                               AND r_vital.flg_group = 'VS'
                            THEN
                                g_error   := 'INSIDE IF';
                                l_glasgow := nvl(l_glasgow, 0) + to_char(r_val.value);
                            END IF;
                        END IF;
                    
                        g_error := 'AFTER IF';
                        l_cont  := l_cont + 1;
                    END LOOP; -- C_VALUES
                
                END IF; ---IF R_VITAL.FLG_GROUP
            
                g_error := 'L_CONT IF 1';
            
                IF l_cont IN (1, 2, 3)
                THEN
                    g_error := 'L_CONT IF 2';
                
                    IF l_rel_domain = g_vs_rel_sum
                    THEN
                        g_error     := 'L_CONT IF 3';
                        l_array_val := l_array_val || to_char(l_glasgow);
                    
                    END IF;
                
                    g_error := 'L_CONT IF 4';
                END IF;
            
                g_error     := 'L_CONT IF 5';
                l_array_val := l_array_val || l_sep; -- novo
            END LOOP;
        
            l_sinal := 'TRUE';
        
        END LOOP;
    
        g_error := 'L_CONT IF 6 - ' || i;
        IF i > 0
        THEN
            o_val_analysis(i) := l_array_val || l_sep;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_EVENT_ALL_DET',
                                              o_error);
        
            o_val_analysis := table_varchar();
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_analysis_time_ev_all_det;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir a grelha das an�lises.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores das an�lises.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_analysis_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_analysis_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_analysis_val       Cursor com a informa��o dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/29
    ***********************************************************************************************************/
    FUNCTION get_woman_health_analysis
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis_time OUT pk_types.cursor_type,
        o_analysis_par  OUT pk_types.cursor_type,
        o_analysis_val  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - An�lises
        ----------------------------------------------------------
        g_error := 'OPEN O_ANALYSIS_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
        OPEN o_analysis_time FOR
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang,
                                                        nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz),
                                                        i_prof) time_var,
                            pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                  nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz),
                                                                  i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz),
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            trunc((CAST(nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz) AS DATE) -
                                  pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz) AS DATE) -
                                         pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            pk_date_utils.dt_chr_year_short_tsz(i_lang,
                                                                nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz),
                                                                i_prof) || '|' || 'X' || '|' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = arp.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
               AND CAST(nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz) AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY time_var, hour_read ASC;
    
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - An�lises
        ----------------------------------------------------------
        OPEN o_analysis_par FOR
            SELECT DISTINCT apar.id_analysis_param par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_event,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND nvl(aum.id_analysis_parameter, apar.id_analysis_parameter) = apar.id_analysis_parameter
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND aum.flg_default(+) = pk_alert_constant.g_yes
                  -- ALERT-51560
               AND nvl(aum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_analysis_result = arp.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
               AND CAST(nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz) AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            UNION
            SELECT DISTINCT apar.id_analysis_param par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          ap.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis                    a,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          ap,
                   analysis_param              apar
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND nvl(aum.id_analysis_parameter, apar.id_analysis_parameter) = apar.id_analysis_parameter
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND aum.flg_default(+) = pk_alert_constant.g_yes
                  -- ALERT-51560
               AND nvl(aum.id_analysis_parameter, ap.id_analysis_parameter) = ap.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND apar.id_analysis_parameter = ap.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        --Open the analysis cursor
        ----------------------------------------------------------
        -- VALORES - An�lises
        ----------------------------------------------------------
        OPEN o_analysis_val FOR
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang,
                                                        nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz),
                                                        i_prof) time_var,
                            apar.id_analysis_param par_var,
                            arp.id_analysis_result_par || '|' || --id_result
                             nvl(ar.flg_status, 'A') || '|' || --estado
                            -- Jos� Brito 25/08/2008 Mostrar unidade de medida das an�lises
                             nvl2(arp.analysis_result_value,
                                  CASE
                                      WHEN arp.analysis_result_value BETWEEN - 1 AND 1 THEN
                                       decode(arp.analysis_result_value, 0, '0', '0' || to_char(arp.analysis_result_value))
                                      ELSE
                                       to_char(arp.analysis_result_value)
                                  END,
                                  arp.desc_analysis_result) || ' ' ||
                             (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um
                               WHERE um.id_unit_measure = arp.id_unit_measure) || '|' || --result
                            --
                             NULL /*TODO - unidades*/
                             || '|' || nvl(adesc.icon, 'X') || '|' VALUE, --icon
                            arp.id_analysis_result_par id_analysis_res_par,
                            '' relation_domain,
                            'A' reg,
                            'A' flg_reg,
                            --s�rgio s(If this field has a value then the result IS NOT normal) 2008-03-10
                            (SELECT abn.value
                               FROM abnormality abn
                              WHERE abn.id_abnormality = arp.id_abnormality) abnorm
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND (adesc.id_analysis = a.id_analysis OR adesc.id_analysis IS NULL)
               AND (adesc.id_sample_type = ar.id_sample_type OR adesc.id_sample_type IS NULL)
               AND adesc.id_analysis_parameter(+) = apar.id_analysis_parameter
                  /*AND (pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                  to_char(arp.desc_analysis_result) OR arp.id_analysis_desc = adesc.id_analysis_desc OR
                  adesc.id_analysis_desc IS NULL)*/
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = arp.id_analysis_result
               AND e.id_group = a.id_analysis
               AND ais.flg_fill_type IS NOT NULL
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(nvl(ar.dt_sample, arp.dt_analysis_result_par_tstz) AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
             ORDER BY 2;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_ANALYSIS',
                                              o_error);
            pk_types.open_my_cursor(o_analysis_time);
            pk_types.open_my_cursor(o_analysis_par);
            pk_types.open_my_cursor(o_analysis_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_analysis;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir a grelha das vacinas.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores das vacinas.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_vaccines_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_vaccines_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_vaccines_val       Cursor com a informa��o dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/13
    ***********************************************************************************************************/
    FUNCTION get_woman_health_vaccines
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vaccines_time OUT pk_types.cursor_type,
        o_vaccines_par  OUT pk_types.cursor_type,
        o_vaccines_val  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - Vacicas
        ----------------------------------------------------------
        g_error := 'OPEN O_ANALYSIS_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
        OPEN o_vaccines_time FOR
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id do tempo
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_par_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vst.dt_vaccine_status_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) short_dt_read,
                            trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof),
                                    '-') || '|' || 'X' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   sys_message      sm,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY short_dt_read, hour_read ASC;
    
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - Vaccines
        ----------------------------------------------------------
        OPEN o_vaccines_par FOR
            SELECT DISTINCT vacc.id_vaccine par_var, --id do parametro
                            vacc.id_vaccine,
                            pk_translation.get_translation(i_lang, vacc.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            vacc.rank,
                            1 val_min,
                            2 val_max,
                            '0xFFFFFF' color_grafh,
                            '0xCCCCCC' color_text,
                            'N.A.' desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            NULL flg_fill_type
            
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
        ----------------------------------------------------------
        -- VALORES - Vaccines
        ----------------------------------------------------------
        --CURSOR c_values_vs(i_vital_sign NUMBER, i_data_read CHAR) IS
        OPEN o_vaccines_val FOR
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id time
                            vacc.id_vaccine par_var, -- id parametro
                            vst.id_vaccine_status || '|' || --id_result
                            'A' /*TODO - estado da vacina*/
                            || '|' || --estado
                            pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) || '|' || '|' ||
                            nvl(vdesc.icon, 'X') || '|' VALUE, --icon
                            vst.id_vaccine_status id_par_read,
                            '' relation_domain,
                            vst.flg_active reg,
                            'V' flg_reg
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   vaccine_desc     vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vdesc.id_vaccine(+) = vacc.id_vaccine
               AND vdesc.value = vst.flg_status
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_VACCINES',
                                              o_error);
            pk_types.open_my_cursor(o_vaccines_time);
            pk_types.open_my_cursor(o_vaccines_par);
            pk_types.open_my_cursor(o_vaccines_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_vaccines;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir a grelha dos sinais vitais.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores das sinais vitais.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_vital_signs_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_vital_signs_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_vital_signs_val       Cursor com a informa��o dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/13
    ***********************************************************************************************************/
    FUNCTION get_woman_health_vital_signs
    (
        i_lang             IN language.id_language%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_intern_name      IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vital_signs_time OUT pk_types.cursor_type,
        o_vital_signs_par  OUT pk_types.cursor_type,
        o_vital_signs_val  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_screen VARCHAR2(2) := 'D'; -- This is always a Detail call
        l_flg_view   VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
        l_age    vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - Vitais Simples
        ----------------------------------------------------------
        g_error := 'OPEN O_VITAL_SIGNS_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
        OPEN o_vital_signs_time FOR
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                            vsr.dt_vital_sign_read_tstz dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM vital_sign_read vsr, vital_sign vs, vs_soft_inst vsi, event e, event_group eg, time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- TEMPOS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                            vsr.dt_vital_sign_read_tstz dt_vital_sign_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vital_sign_relation vsre,
                   vs_soft_inst        vsi,
                   event               e,
                   event_group         eg,
                   time_event_group    teg
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - Vitais Simples
        ----------------------------------------------------------
        g_error := 'OPEN O_VITAL_SIGNS_PAR';
        OPEN o_vital_signs_par FOR
        ------------------------------------------------------
        -- Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                  -- Jos� Brito 19/12/2008 ALERT-9992
               AND vdesc.flg_available(+) = 'Y'
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = emf.id_group
               AND emf.flg_group = e.flg_group
               AND e.id_group = emf.id_group
               AND e.id_group = vs.id_vital_sign
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- Sinais Vitais Compostos (ex: Press�o Arterial)
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vsre.id_vital_sign_parent,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg,
                   pat_pregnancy       pp
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week;
    
        --Open the vital_signs cursor
        ----------------------------------------------------------
        -- VALORES - Vitais Simples
        ----------------------------------------------------------
        g_error := 'OPEN O_VITAL_SIGNS_VAL';
        OPEN o_vital_signs_val FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                   vs.id_vital_sign par_var, --id parametro
                   decode(vsr.id_unit_measure,
                          vsi.id_unit_measure,
                          decode(vsr.value,
                                 NULL,
                                 pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                 to_char(vsr.value)),
                          nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                              vsr.id_unit_measure,
                                                                              vsi.id_unit_measure)),
                              decode(vsr.value,
                                     NULL,
                                     pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                     to_char(vsr.value)))) || '|' || nvl(vdesc.icon, 'X') ||
                   decode(vdesc.value, NULL, NULL, '|' || vdesc.value) VALUE,
                   vsr.id_vital_sign_read,
                   '' relation_domain,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'S' flg_reg
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- Jos� Brito 19/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                  --
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION ALL
            ------------------------------------------------------
            -- VALORES - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var,
                   vsr.id_vital_sign par_var,
                   to_char(vsr.value) VALUE,
                   vsr.id_vital_sign_read,
                   vr.relation_domain,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'C' flg_reg
              FROM vital_sign_relation vr, vital_sign_read vsr, event e, event_group eg, time_event_group teg
             WHERE (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vr.id_vital_sign_detail = vsr.id_vital_sign
               AND vr.relation_domain = g_vs_rel_conc
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_VITAL_SIGNS',
                                              o_error);
            pk_types.open_my_cursor(o_vital_signs_time);
            pk_types.open_my_cursor(o_vital_signs_par);
            pk_types.open_my_cursor(o_vital_signs_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_vital_signs;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir a grelha dos sinais vitais.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores da Imonulogia
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_vital_signs_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_vital_signs_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_vital_signs_val       Cursor com a informa��o dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/13
    ***********************************************************************************************************/
    FUNCTION get_woman_health_immunology
    (
        i_lang            IN language.id_language%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_prof            IN profissional,
        i_intern_name     IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_immunology_time OUT pk_types.cursor_type,
        o_immunology_par  OUT pk_types.cursor_type,
        o_immunology_val  OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - Imonologia
        ----------------------------------------------------------
        g_error := 'OPEN O_immunology_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
    
        OPEN o_immunology_time FOR
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) dt_par_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             arp.dt_analysis_result_par_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               arp.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) short_dt_read,
                            
                            trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                   pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            
                             decode(trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                          pp.dt_init_pregnancy + 6) / 7),
                                    1,
                                    pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                    pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            
                             REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                           decode(ar.dt_sample,
                                                                                  NULL,
                                                                                  arp.dt_analysis_result_par_tstz,
                                                                                  ar.dt_sample),
                                                                           --arp.dt_analysis_result_par_tstz,
                                                                           i_prof),
                                     '-') ||
                            -- decode(ar.dt_sample, NULL, ' ' || pk_message.get_message(i_lang, 'COMMON_M052'), '') ||
                             '|' || 'X' || '|'
                            -- || decode(ar.dt_sample, NULL, 'Y', 'N')
                             header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
                  --AND ais.id_analysis(+) = a.id_analysis
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = arp.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
               AND CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   pp.dt_init_pregnancy AND pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id do tempo
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_par_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vst.dt_vaccine_status_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) short_dt_read,
                            trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7) || '|' ||
                            decode(trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy + 6) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof),
                                    '-') || '|' || 'X' || '|' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   sys_message      sm,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   vaccine_desc     vdesc
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND vdesc.id_vaccine = vacc.id_vaccine
               AND vdesc.value = vst.flg_status
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
             ORDER BY short_dt_read, hour_read ASC;
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - Imunologia
        ----------------------------------------------------------
        g_error := 'OPEN O_immunology_PAR';
        OPEN o_immunology_par FOR
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_event,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
               AND nvl(aum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_analysis_result = arp.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
               AND CAST(arp.dt_analysis_result_par_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            UNION
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          ap.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis                    a,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          ap,
                   analysis_param              apar
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND nvl(aum.id_analysis_parameter, ap.id_analysis_parameter) = ap.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND apar.id_analysis_parameter = ap.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
            
            UNION
            
            SELECT DISTINCT vacc.id_vaccine par_var, --id do parametro
                            vacc.id_vaccine,
                            pk_translation.get_translation(i_lang, vacc.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            vacc.rank,
                            1 val_min,
                            2 val_max,
                            '0xFFFFFF' color_grafh,
                            '0xCCCCCC' color_text,
                            'N.A.' desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            NULL flg_fill_type,
                            NULL habit_value,
                            NULL icon_habit_value,
                            NULL icon_flag_status,
                            NULL icon_color
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   vaccine_desc     vdesc
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND vdesc.id_vaccine = vacc.id_vaccine
               AND vdesc.value = vst.flg_status
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        --Open the immunology cursor
        ----------------------------------------------------------
        -- VALORES - Imonulogia
        ----------------------------------------------------------
        g_error := 'OPEN O_immunology_VAL';
        OPEN o_immunology_val FOR
        --CURSOR c_values_vs(i_vital_sign NUMBER, i_data_read CHAR) IS0
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            apar.id_analysis_parameter par_var,
                            arp.id_analysis_result_par || '|' || --id_result
                            'A' /*TODO - estado da an�lise*/
                            || '|' || --estado
                            nvl(to_char(arp.desc_analysis_result),
                                arp.analysis_result_value || ' ' ||
                                (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                   FROM unit_measure um
                                  WHERE um.id_unit_measure = arp.id_unit_measure)) || '|' || --result
                            NULL /*TODO - unidades*/
                            || '|' || nvl(adesc.icon, 'X') || '|' VALUE, --icon
                            arp.id_analysis_result_par id_par_read,
                            '' relation_domain,
                            'A' reg,
                            'A' flg_reg
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND adesc.id_analysis(+) = a.id_analysis
               AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                   to_char(arp.desc_analysis_result))
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = arp.id_analysis_result
               AND e.id_group = a.id_analysis
               AND ais.flg_fill_type IS NOT NULL
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(arp.dt_analysis_result_par_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id time
                            vacc.id_vaccine par_var, -- id parametro
                            
                            vst.id_vaccine_status || '|' || --id_result
                            'A' /*TODO - estado da vacina*/
                            || '|' || --estado
                            pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) || '|' || '|' ||
                            nvl(vdesc.icon, 'X') || '|' VALUE, --icon
                            vst.id_vaccine_status id_par_read,
                            '' relation_domain,
                            vst.flg_active reg,
                            'V' flg_reg
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   vaccine_desc     vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vdesc.id_vaccine(+) = vacc.id_vaccine
               AND vdesc.value = vst.flg_status
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
             ORDER BY 2;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_IMUNOLOGY',
                                              o_error);
            pk_types.open_my_cursor(o_immunology_time);
            pk_types.open_my_cursor(o_immunology_par);
            pk_types.open_my_cursor(o_immunology_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_immunology;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir a grelha do RH.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores para o RH.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_vital_signs_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_vital_signs_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_vital_signs_val       Cursor com a informa��o dos valores
    * @param      o_error                 Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/13
    ***********************************************************************************************************/
    FUNCTION get_woman_health_rh
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_rh_time       OUT pk_types.cursor_type,
        o_rh_par        OUT pk_types.cursor_type,
        o_rh_val        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - RH
        ----------------------------------------------------------
        g_error := 'OPEN O_rh_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
    
        OPEN o_rh_time FOR
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) dt_analysis_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             arp.dt_analysis_result_par_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               arp.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) short_dt_read,
                            abs(trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                      pp.dt_init_pregnancy) / 7))
                            
                            || '|' ||
                            decode(trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                         pp.dt_init_pregnancy) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          decode(ar.dt_sample,
                                                                                 NULL,
                                                                                 arp.dt_analysis_result_par_tstz,
                                                                                 ar.dt_sample),
                                                                          --arp.dt_analysis_result_par_tstz,
                                                                          i_prof),
                                    '-') || '|' || 'X' || '|' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = arp.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
             ORDER BY short_dt_read, hour_read ASC;
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - RH
        ----------------------------------------------------------
        g_error := 'OPEN O_rh_PAR';
        OPEN o_rh_par FOR
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_event,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND nvl(aum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_analysis_result = arp.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
            UNION
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          ap.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'N') habit_value,
                            get_usual_values_str(i_lang,
                                                 i_prof,
                                                 i_intern_name,
                                                 i_patient,
                                                 i_pat_pregnancy,
                                                 a.id_analysis,
                                                 'Y') icon_habit_value,
                            'A' icon_flag_status,
                            '0x787864' icon_color
              FROM analysis                    a,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          ap,
                   analysis_param              apar
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND nvl(aum.id_analysis_parameter, ap.id_analysis_parameter) = ap.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND apar.id_analysis_parameter = ap.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        --Open the rh cursor
        ----------------------------------------------------------
        -- VALORES - RH
        ----------------------------------------------------------
        g_error := 'OPEN O_rh_VAL';
        OPEN o_rh_val FOR
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            apar.id_analysis_parameter par_var,
                            arp.id_analysis_result_par || '|' || --id_result
                             'A' /*TODO - estado da an�lise*/
                             || '|' || --estado
                             nvl(arp.desc_analysis_result,
                                 arp.analysis_result_value || ' ' ||
                                 (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                    FROM unit_measure um
                                   WHERE um.id_unit_measure = arp.id_unit_measure)) || '|' || --result
                            /*decode(adesc.VALUE, NULL, NULL, adesc.VALUE) || '|' || --valor*/
                             NULL /*TODO - unidades*/
                             || '|' || nvl(adesc.icon, 'X') || '|' VALUE, --icon
                            arp.id_analysis_result_par id_analysis_res_par,
                            '' relation_domain,
                            'A' reg,
                            'A' flg_reg
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND adesc.id_analysis(+) = a.id_analysis
               AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                   to_char(arp.desc_analysis_result))
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = arp.id_analysis_result
               AND e.id_group = a.id_analysis
               AND ais.flg_fill_type IS NOT NULL
            -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
             ORDER BY 2;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_RH',
                                              o_error);
            pk_types.open_my_cursor(o_rh_time);
            pk_types.open_my_cursor(o_rh_par);
            pk_types.open_my_cursor(o_rh_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_rh;

    /************************************************************************************************************
    * Esta fun��o retorna toda a informa��o necess�ria para construir as v�rias grelhas de resumo da sa�de materna.
    * S�o retornados 3 cursores distintos com a informa��o respectivamente do tempo, dos par�metros
    * e dos valores da para os v�rios parametros.
    *
    * @param      i_lang                L�ngua registada como prefer�ncia do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_intern_name         Intern Name do TIME_EVENT_GROUP (ex: 'WOMAN_HEALTH_ANALYSIS')
    * @param      i_pat_pregnancy       ID da gravidez
    *
    * @param      o_summary_time      Cursor com a informa��o dos tempos (colunas)
    * @param      o_summary_par       Cursor com a informa��o dos par�metros (linhas)
    * @param      o_summary_val       Cursor com a informa��o dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/13
    ***********************************************************************************************************/
    FUNCTION get_woman_health_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_summary_time  OUT pk_types.cursor_type,
        o_summary_par   OUT pk_types.cursor_type,
        o_summary_val   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_screen VARCHAR2(2) := 'D'; -- This is always a Detail call
        l_flg_view   VARCHAR2(2) := 'P'; -- View 1 on the Vital Signs
    
        --
    
        --SS: 2007/09/10: performance
        CURSOR c_pat_pregn IS
            SELECT pp.dt_init_pregnancy dt_aux
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        l_dt_aux DATE;
        l_age    vital_sign_unit_measure.age_min%TYPE;
    
    BEGIN
    
        OPEN c_pat_pregn;
        FETCH c_pat_pregn
            INTO l_dt_aux;
        CLOSE c_pat_pregn;
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        --Open the time cursor
        ----------------------------------------------------------
        -- TEMPOS de registo - summary
        ----------------------------------------------------------
        g_error := 'OPEN O_summary_TIME';
        --o time_var � definido como a data em formato str porque existem registos para as mesmas datas com ids diferentes
    
        OPEN o_summary_time FOR
        ------------------------------------------------------
        -- TEMPOS - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_par_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            NULL header_desc
              FROM vital_sign_read vsr, vital_sign vs, vs_soft_inst vsi, event e, event_group eg, time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- TEMPOS - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_par_read,
                            pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vsr.dt_vital_sign_read_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) short_dt_read,
                            NULL header_desc
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vital_sign_relation vsre,
                   vs_soft_inst        vsi,
                   event               e,
                   event_group         eg,
                   time_event_group    teg
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR l_flg_screen = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- TEMPOS - Analysis
            ------------------------------------------------------
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) dt_par_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             arp.dt_analysis_result_par_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        decode(ar.dt_sample,
                                                               NULL,
                                                               arp.dt_analysis_result_par_tstz,
                                                               ar.dt_sample),
                                                        i_prof) short_dt_read,
                            trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                  pp.dt_init_pregnancy) / 7) || '|' ||
                            decode(trunc((CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) -
                                         pp.dt_init_pregnancy) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' ||
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                          decode(ar.dt_sample,
                                                                                 NULL,
                                                                                 arp.dt_analysis_result_par_tstz,
                                                                                 ar.dt_sample),
                                                                          i_prof),
                                    '-') || '|' || 'X' || '|' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   sys_message                 sm,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND sm.code_message = 'WOMAN_HEALTH_T003'
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_patient(+) = i_patient
               AND ar.id_analysis_result = arp.id_analysis_result(+)
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND ais.flg_fill_type IS NOT NULL
               AND CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   pp.dt_init_pregnancy AND pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- TEMPOS - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id do tempo
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_par_read,
                            pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) dt_read,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             vst.dt_vaccine_status_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_read,
                            pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) short_dt_read,
                            REPLACE(pk_date_utils.date_chr_short_read_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof),
                                    '-') || '|' ||
                            trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy) / 7) || '|' ||
                            decode(trunc((CAST(vst.dt_vaccine_status_tstz AS DATE) - pp.dt_init_pregnancy) / 7),
                                   1,
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T065'),
                                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001')) || '|' || 'X' header_desc -- RdSN: Neste momento s� Registadas com PHR mostram icone. Isto pode ser revisto, porque no servi�o de urgencia tb n � no contexto de uma consulta
            
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   sys_message      sm,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND sm.code_message = 'WOMAN_HEALTH_T003'
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
             ORDER BY short_dt_read, hour_read ASC;
        --Open the parameters cursor
        ----------------------------------------------------------
        -- EVENTS - summary
        ----------------------------------------------------------
        g_error := 'OPEN O_summary_PAR';
        OPEN o_summary_par FOR
        ----------------------------------------------------------
        -- EVENTS - Sinais Vitais Simples
        ----------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vs.id_vital_sign id_par,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
            
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND (vsr.value IS NOT NULL OR vsr.id_vital_sign_desc IS NOT NULL)
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
                  -- Jos� Brito 19/12/2008 ALERT-9992
               AND vdesc.flg_available(+) = 'Y'
                  --
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vs.id_vital_sign id_par,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vs.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
              FROM vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp,
                   event_most_freq  emf
             WHERE vs.flg_available = g_vs_avail
               AND vs.id_vital_sign = emf.id_group
               AND emf.flg_group = e.flg_group
               AND e.id_group = emf.id_group
               AND e.id_group = vs.id_vital_sign
                  -- para suportar VS preenchiveis atrav�s de multichoice
               AND emf.value IS NOT NULL
               AND emf.value = vdesc.value(+)
                  
               AND vsi.id_vital_sign(+) = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
                  
               AND emf.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
            
            UNION
            ------------------------------------------------------
            -- Sinais Vitais Compostos (ex: Press�o Arterial)
            ------------------------------------------------------
            SELECT DISTINCT vs.id_vital_sign par_var, --id parametro
                            vsre.id_vital_sign_parent id_par,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            vsi.rank,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsre.id_vital_sign_parent,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.color_grafh,
                            vsi.color_text,
                            (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                               FROM dual) desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            vs.flg_fill_type
              FROM vital_sign_read     vsr,
                   vital_sign          vs,
                   vs_soft_inst        vsi,
                   vital_sign_relation vsre,
                   event               e,
                   event_group         eg,
                   time_event_group    teg,
                   pat_pregnancy       pp
             WHERE vsre.id_vital_sign_parent = vs.id_vital_sign
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vsre.id_vital_sign_detail = vsr.id_vital_sign
               AND vsre.relation_domain = g_vs_rel_conc
               AND vsre.id_vital_sign_parent = vsi.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vs.id_vital_sign
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            ----------------------------------------------------------
            -- EVENTS - Analysis
            ----------------------------------------------------------
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis id_par,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          pa.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_event,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type
            
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_parameter          pa,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND nvl(aum.id_analysis_parameter, pa.id_analysis_parameter) = pa.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND apar.id_analysis_parameter = pa.id_analysis_parameter
               AND ar.id_patient(+) = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND ar.id_analysis_result = arp.id_analysis_result
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND CAST(arp.dt_analysis_result_par_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
            
            UNION
            
            SELECT DISTINCT apar.id_analysis_parameter par_var,
                            a.id_analysis id_par,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          ap.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') name_vs,
                            ais.rank,
                            aum.val_min,
                            aum.val_max,
                            NULL color_graph,
                            NULL color_text,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            e.flg_group,
                            decode(a.id_sample_type,
                                   pk_sysconfig.get_config('SAMPLE_TYPE_URINE', i_prof.institution, i_prof.software),
                                   'U',
                                   decode(a.id_sample_type,
                                          pk_sysconfig.get_config('SAMPLE_TYPE_BLOOD',
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                          'B',
                                          NULL)) sample_type_desc,
                            ais.flg_fill_type
            
              FROM analysis                    a,
                   analysis_param_funcionality ais,
                   analysis_unit_measure       aum,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg,
                   pat_pregnancy               pp,
                   event_most_freq             emf,
                   analysis_parameter          ap,
                   analysis_param              apar
             WHERE a.flg_available = g_vs_avail
                  --AND ais.id_analysis(+) = a.id_analysis
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND nvl(aum.id_analysis_parameter, ap.id_analysis_parameter) = ap.id_analysis_parameter
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
               AND emf.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = a.id_analysis
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND apar.id_analysis_parameter = ap.id_analysis_parameter
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
               AND pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_pat_pregnancy = emf.id_pat_pregnancy
            
            UNION
            
            ----------------------------------------------------------
            -- EVENTS - Vacinas
            ----------------------------------------------------------
            SELECT DISTINCT vacc.id_vaccine par_var, --id do parametro
                            vacc.id_vaccine id_par,
                            pk_translation.get_translation(i_lang, vacc.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            vacc.rank,
                            1 val_min,
                            2 val_max,
                            '0xFFFFFF' color_grafh,
                            '0xCCCCCC' color_text,
                            'N.A.' desc_unit_measure,
                            e.flg_group,
                            NULL sample_type_desc,
                            NULL flg_fill_type
            
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   pat_pregnancy    pp
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
               AND pp.id_pat_pregnancy = i_pat_pregnancy
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN pp.dt_init_pregnancy AND
                   pp.dt_init_pregnancy + g_weeks_gest * g_days_in_week
             ORDER BY rank, sample_type_desc DESC, flg_group ASC;
    
        --Open the summary cursor
        ----------------------------------------------------------
        -- VALORES - summary
        ----------------------------------------------------------
        g_error := 'OPEN O_SUMMARY_VAL';
        OPEN o_summary_val FOR
        
        ------------------------------------------------------
        -- VALORES - Sinais Vitais Simples
        ------------------------------------------------------
            SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                   vs.id_vital_sign par_var, --id parametro
                   decode(vsr.id_unit_measure,
                          vsi.id_unit_measure,
                          decode(vsr.value,
                                 NULL,
                                 pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                 to_char(vsr.value)),
                          nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vsr.value,
                                                                              vsr.id_unit_measure,
                                                                              vsi.id_unit_measure)),
                              decode(vsr.value,
                                     NULL,
                                     pk_vital_sign.get_vs_alias(i_lang, vsr.id_patient, vdesc.code_vital_sign_desc),
                                     to_char(vsr.value)))) || '|' || nvl(vdesc.icon, 'X') ||
                   decode(vdesc.value, NULL, NULL, '|' || vdesc.value) VALUE,
                   vsr.id_vital_sign_read,
                   '' relation_domain,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'S' flg_reg
              FROM vital_sign_read  vsr,
                   vital_sign       vs,
                   vs_soft_inst     vsi,
                   vital_sign_desc  vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vs.id_vital_sign = vsr.id_vital_sign
               AND vs.flg_available = g_vs_avail
               AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                              FROM vital_sign_relation vr
                                             WHERE vr.relation_domain = g_vs_rel_sum)
               AND (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
                  -- Jos� Brito 19/12/2008 ALERT-9992
                  -- Support for vital signs selected in multichoice
               AND vsr.id_vital_sign_desc = vdesc.id_vital_sign_desc(+)
               AND vdesc.flg_available(+) = 'Y'
               AND vsr.id_vital_sign = vdesc.id_vital_sign(+)
                  --
               AND vsi.id_vital_sign = vs.id_vital_sign
               AND vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = l_flg_view
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vsr.id_vital_sign
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION ALL
            ------------------------------------------------------
            -- VALORES - Sinais Vitais Compostos
            ------------------------------------------------------
            SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof) time_var, -- id tempo
                   vsr.id_vital_sign par_var, --id parametro
                   to_char(vsr.value) VALUE,
                   vsr.id_vital_sign_read,
                   vr.relation_domain,
                   decode(vsr.dt_cancel_tstz, '', 'A', 'C') reg,
                   'C' flg_reg
              FROM vital_sign_relation vr, vital_sign_read vsr, event e, event_group eg, time_event_group teg
             WHERE (vsr.flg_state = g_vs_read_active -------------- Sinais Vitais Activos    -- RdSN 2006/12/13
                   OR nvl(l_flg_screen, 'D') = 'D')
               AND vr.id_vital_sign_detail = vsr.id_vital_sign
               AND vr.relation_domain = g_vs_rel_conc
               AND vsr.id_patient = i_patient
               AND e.flg_group = 'VS'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vsr.dt_vital_sign_read_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- VALORES - Analysis
            ------------------------------------------------------
            SELECT DISTINCT decode(ar.dt_sample,
                                   NULL,
                                   pk_date_utils.date_send_tsz(i_lang, arp.dt_analysis_result_par_tstz, i_prof),
                                   pk_date_utils.date_send_tsz(i_lang, ar.dt_sample, i_prof)) time_var,
                            apar.id_analysis_parameter par_var,
                            arp.id_analysis_result_par || '|' || --id_result
                            'A' -- TODO - estado da an�lise
                            || '|' || --estado
                            nvl(to_char(arp.desc_analysis_result),
                                arp.analysis_result_value || ' ' ||
                                (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                   FROM unit_measure um
                                  WHERE um.id_unit_measure = arp.id_unit_measure)) || '|' || --result
                            NULL -- TODO - unidades
                            || '|' || nvl(adesc.icon, 'X') || '|' VALUE, --icon
                            arp.id_analysis_result_par id_par_read,
                            '' relation_domain,
                            'A' reg,
                            'A' flg_reg
              FROM analysis_result_par         arp,
                   analysis                    a,
                   analysis_result             ar,
                   analysis_param              apar,
                   analysis_param_funcionality ais,
                   analysis_desc               adesc,
                   event                       e,
                   event_group                 eg,
                   time_event_group            teg
             WHERE a.flg_available = g_vs_avail
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = apar.id_analysis_param
               AND apar.flg_available = g_vs_avail
               AND apar.id_software = i_prof.software
               AND apar.id_institution = i_prof.institution
                  -- TODO: melhorar este c�digo... grava a descri��o (ex: Positivo) quando deveria gravar o value ('P')...
               AND adesc.id_analysis(+) = a.id_analysis
               AND (adesc.id_analysis IS NULL OR pk_translation.get_translation(i_lang, adesc.code_analysis_desc) =
                   to_char(arp.desc_analysis_result))
                  -- para incidir sobre os parametros de analise
               AND apar.id_analysis = a.id_analysis
               AND arp.id_analysis_parameter = apar.id_analysis_parameter
               AND ar.id_patient = i_patient
               AND e.flg_group = 'A'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND ar.id_analysis_result = arp.id_analysis_result
               AND e.id_group = a.id_analysis
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(decode(ar.dt_sample, NULL, arp.dt_analysis_result_par_tstz, ar.dt_sample) AS DATE) BETWEEN
                   l_dt_aux AND l_dt_aux + g_weeks_gest * g_days_in_week
            
            UNION
            ------------------------------------------------------
            -- VALORES - Vacinas
            ------------------------------------------------------
            SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, vst.dt_vaccine_status_tstz, i_prof) time_var, --id time
                            vacc.id_vaccine par_var, -- id parametro
                            pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) || '|' || vdesc.icon ||
                            decode(vdesc.value, NULL, NULL, '|' || vdesc.value) VALUE,
                            vst.id_vaccine_status id_par_read,
                            '' relation_domain,
                            vst.flg_active reg,
                            'V' flg_reg
              FROM vaccine          vacc,
                   vaccine_det      vd,
                   vaccine_status   vst,
                   vaccine_desc     vdesc,
                   event            e,
                   event_group      eg,
                   time_event_group teg
             WHERE vacc.flg_available = g_vs_avail
               AND to_char(vacc.id_vaccine) = vd.medid
               AND vdesc.id_vaccine(+) = vacc.id_vaccine
               AND vdesc.value = vst.flg_status
               AND vd.id_patient = i_patient
               AND vd.id_vaccine_det = vst.id_vaccine_det
               AND e.flg_group = 'V'
               AND teg.intern_name = i_intern_name
               AND teg.id_event_group = eg.id_event_group
               AND eg.id_event_group = e.id_event_group
               AND e.id_group = vacc.id_vaccine
                  -- limita��o de datas entre a data da �ltima menstrua��o / data corrigida e as 44 semanas
               AND CAST(vst.dt_vaccine_status_tstz AS DATE) BETWEEN l_dt_aux AND
                   l_dt_aux + g_weeks_gest * g_days_in_week
             ORDER BY 2;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WOMAN_HEALTH_SUMMARY',
                                              o_error);
            pk_types.open_my_cursor(o_summary_time);
            pk_types.open_my_cursor(o_summary_par);
            pk_types.open_my_cursor(o_summary_val);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_woman_health_summary;

    /************************************************************************************************************
    * Returns the data needed to build the screen that allows the creation of analysis in the Woman Health.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    *
    * @param      o_analysis           cursor with the list of analysis
    * @param      o_val_habit          cursor with the usual values for each type of analysis
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/19
    ***********************************************************************************************************/

    FUNCTION get_analysis_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --valores habituais
        l_usual_value_str VARCHAR2(100) := NULL;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        -----------------------------------------
        -- EVENTS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_ANALYSIS';
        OPEN o_analysis FOR
        -----------------------------------------
        -- EVENTS An�lises
        -----------------------------------------
            SELECT DISTINCT a.id_analysis,
                            ap.id_analysis_param,
                            ap.id_analysis_parameter,
                            aum.val_min,
                            aum.val_max,
                            aum.format_num,
                            ais.flg_fill_type,
                            nvl(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                          i_prof,
                                                                          'P',
                                                                          aparam.code_analysis_parameter,
                                                                          NULL),
                                pk_lab_tests_api_db.get_alias_translation(i_lang, i_prof, 'A', a.code_analysis, NULL)) ||
                            decode((SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                     FROM unit_measure um, unit_mea_soft_inst umsi
                                    WHERE --RS 20071012 Reformula��o an�lises
                                   --um.id_unit_measure = vsi.id_unit_measure
                                    um.id_unit_measure = aum.id_unit_measure
                                   --RS 20071012 Reformula��o an�lises
                                AND um.id_unit_measure = umsi.id_unit_measure
                                AND umsi.id_institution =
                                    (SELECT MAX(umsi2.id_institution)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))
                                AND umsi.id_software =
                                    (SELECT MAX(umsi2.id_software)
                                       FROM unit_mea_soft_inst umsi2
                                      WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                        AND umsi2.id_institution IN (0, i_prof.institution)
                                        AND umsi2.id_software IN (0, i_prof.software))),
                                   NULL,
                                   '',
                                   ' (' || (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                              FROM unit_measure um, unit_mea_soft_inst umsi
                                             WHERE --RS 20071012 Reformula��o an�lises
                                            --um.id_unit_measure = vsi.id_unit_measure
                                             um.id_unit_measure = aum.id_unit_measure
                                            --RS 20071012 Reformula��o an�lises
                                         AND um.id_unit_measure = umsi.id_unit_measure
                                         AND umsi.id_institution =
                                             (SELECT MAX(umsi2.id_institution)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))
                                         AND umsi.id_software =
                                             (SELECT MAX(umsi2.id_software)
                                                FROM unit_mea_soft_inst umsi2
                                               WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                 AND umsi2.id_institution IN (0, i_prof.institution)
                                                 AND umsi2.id_software IN (0, i_prof.software))) || ')') desc_analysis,
                            (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                FROM unit_measure um, unit_mea_soft_inst umsi
                               WHERE --RS 20071012 Reformula��o an�lises
                              --um.id_unit_measure = vsi.id_unit_measure
                               um.id_unit_measure = aum.id_unit_measure
                              --RS 20071012 Reformula��o an�lises
                            AND um.id_unit_measure = umsi.id_unit_measure
                            AND umsi.id_institution =
                               (SELECT MAX(umsi2.id_institution)
                                  FROM unit_mea_soft_inst umsi2
                                 WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                   AND umsi2.id_institution IN (0, i_prof.institution)
                                   AND umsi2.id_software IN (0, i_prof.software))
                            AND umsi.id_software = (SELECT MAX(umsi2.id_software)
                                                     FROM unit_mea_soft_inst umsi2
                                                    WHERE umsi2.id_unit_measure = aum.id_unit_measure
                                                      AND umsi2.id_institution IN (0, i_prof.institution)
                                                      AND umsi2.id_software IN (0, i_prof.software))) desc_unit_measure,
                            aum.id_unit_measure,
                            g_sysdate_tstz dt_server,
                            e.flg_most_freq,
                            --NULL VALUE,
                            e.flg_group
              FROM analysis                    a,
                   analysis_param_funcionality ais,
                   --analysis_instit_soft        ais2,
                   analysis_unit_measure aum,
                   time_event_group      teg,
                   event_group           eg,
                   event                 e,
                   sys_message           sm,
                   analysis_result       ar,
                   analysis_param        ap,
                   analysis_parameter    aparam
             WHERE a.flg_available = g_vs_avail
               AND ap.id_analysis = a.id_analysis
               AND ais.flg_type = 'M'
               AND ais.id_analysis_param = ap.id_analysis_param
               AND ap.flg_available = g_vs_avail
                  
               AND ap.id_software = i_prof.software
               AND ap.id_institution = i_prof.institution
               AND aum.id_analysis(+) = a.id_analysis
               AND aum.flg_default(+) = pk_alert_constant.g_yes
               AND ais.id_analysis_param = ap.id_analysis_param -- tco
               AND nvl(aum.id_analysis_parameter, aparam.id_analysis_parameter) = aparam.id_analysis_parameter
                  --AND aum.id_analysis_parameter = ap.id_analysis_parameter -- tco
                  --RS 20071012 Reformula��o an�lises
                  --AND nvl(aum.id_unit_measure, 0) = nvl(ais.id_unit_measure, 0)
                  --RS 20071012 Reformula��o an�lises
               AND aum.id_institution(+) = i_prof.institution
               AND aum.id_software(+) = i_prof.software
                  
               AND teg.intern_name = i_intern_name
               AND eg.id_event_group = teg.id_event_group
               AND e.id_event_group = eg.id_event_group
               AND e.flg_group = 'A'
               AND e.id_group = a.id_analysis
               AND aum.flg_default(+) = 'Y'
               AND nvl(aum.id_analysis_parameter, aparam.id_analysis_parameter) = aparam.id_analysis_parameter
               AND ar.id_analysis(+) = a.id_analysis
               AND ar.id_patient(+) = i_patient
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
               AND a.id_analysis = ap.id_analysis
               AND ap.id_analysis_parameter = aparam.id_analysis_parameter
               AND ap.id_software = i_prof.software -- RdSN 2007/10/25
               AND ap.id_institution = i_prof.institution -- RdSN 2007/10/25
               AND ais.flg_fill_type IS NOT NULL
             ORDER BY desc_analysis;
    
        -----------------------------------------
        -- VALORES HABITUAIS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_VAL_HABIT';
    
        IF NOT get_usual_values(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_intern_name    => i_intern_name,
                                i_patient        => i_patient,
                                i_pat_pregnancy  => i_pat_pregnancy,
                                i_id_event       => NULL,
                                o_usual_val      => o_val_habit,
                                o_usual_val_str  => l_usual_value_str,
                                o_usual_icon_str => l_usual_value_str,
                                o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ANALYSIS_CREATE',
                                              o_error);
        
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_analysis_create;

    /************************************************************************************************************
    * Returns the data needed to build the screen that allows the creation of vaccines in the Woman Health.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    *
    * @param      o_vaccines           cursor with the list of vaccines
    * @param      o_val_habit          cursor with the usual values for each type of vaccine
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/14
    ***********************************************************************************************************/

    FUNCTION get_vaccines_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intern_name   IN time_event_group.intern_name%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_vaccines      OUT pk_types.cursor_type,
        o_val_habit     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        -----------------------------------------
        -- EVENTS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_ANALYSIS';
        OPEN o_vaccines FOR
        -----------------------------------------
        -- EVENTS Vacinas
        -----------------------------------------
            SELECT DISTINCT vs.id_vaccine,
                            0 val_min,
                            1 val_max,
                            vs.rank,
                            0 rank_conc,
                            NULL id_vital_sign_parent,
                            NULL relation_type,
                            'N',
                            'D' flg_fill_type, -- hardcoded como por Dose (vacina + multichoice)
                            'N' flg_sum,
                            pk_translation.get_translation(i_lang, vs.code_vaccine) || ' (' ||
                            pk_message.get_message(i_lang, 'WOMAN_HEALTH_T072') || ')' name_vs,
                            NULL desc_unit_measure,
                            1 id_unit_measure,
                            g_sysdate_tstz dt_server,
                            'N',
                            NULL VALUE,
                            e.flg_group,
                            NULL sample_type_desc,
                            'N' id_vital_sign_detail,
                            (SELECT COUNT(id_vaccine_dose)
                               FROM vaccine_dose vd
                              WHERE vd.medid = to_char(vs.id_vaccine)) n_dose
              FROM vaccine vs, time_event_group teg, event_group eg, event e
             WHERE teg.intern_name = i_intern_name
               AND eg.id_event_group = teg.id_event_group
               AND e.id_event_group = eg.id_event_group
               AND e.flg_group = 'V'
               AND e.id_group = vs.id_vaccine
            
             ORDER BY rank, sample_type_desc DESC, name_vs;
    
        -----------------------------------------
        -- VALORES HABITUAIS INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_VAL_HABIT';
        OPEN o_val_habit FOR
        
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   decode(emf.value, NULL, NULL, vdesc.icon) icon,
                   vdesc.value flg_value
              FROM event_most_freq  emf,
                   event            e,
                   event_group      eg,
                   time_event_group teg,
                   sys_message      sm,
                   vaccine_desc     vdesc
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
                  
               AND (vdesc.id_vaccine(+) = e.id_group AND e.flg_group = 'V' AND
                   (vdesc.id_vaccine_desc IS NULL OR emf.value IS NULL OR
                   pk_translation.get_translation(i_lang, vdesc.code_vaccine_desc) = emf.value))
            
            UNION
            
            SELECT emf.id_group id_vital_sign,
                   emf.flg_group,
                   e.flg_most_freq,
                   decode(nvl(e.flg_most_freq, 'N'), 'N', sm.desc_message, emf.value) VALUE,
                   NULL icon,
                   NULL flg_value
              FROM event_most_freq emf, event e, event_group eg, time_event_group teg, sys_message sm
            
             WHERE emf.id_pat_pregnancy = i_pat_pregnancy
               AND emf.id_patient = i_patient
               AND e.id_group = emf.id_group
               AND e.flg_group = emf.flg_group
               AND e.id_event_group = eg.id_event_group
               AND teg.id_event_group = eg.id_event_group
               AND teg.intern_name = i_intern_name
               AND sm.code_message = 'COMMON_M018'
               AND sm.id_language = i_lang
                  
               AND e.flg_group = 'VS';
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VACCINES_CREATE',
                                              o_error);
            pk_types.open_my_cursor(o_vaccines);
            pk_types.open_my_cursor(o_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vaccines_create;

    /************************************************************************************************************
    * Returns the data needed to build the screen that allows the creation of Immunology parameters
    * in the Woman Health.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    *
    * @param      o_analysis           cursor with the list of analysis
    * @param      o_val_habit          cursor with the usual values for each type of analysis
    * @param      o_vaccines           cursor with the list of vaccines
    * @param      o_val_habit          cursor with the usual values for each type of vaccine
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/14
    ***********************************************************************************************************/

    FUNCTION get_immunology_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_intern_name        IN time_event_group.intern_name%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_val_habit OUT pk_types.cursor_type,
        o_vaccines           OUT pk_types.cursor_type,
        o_vaccines_val_habit OUT pk_types.cursor_type,
        o_vaccines_status    OUT pk_types.cursor_type,
        o_vaccines_admin     OUT pk_types.cursor_type,
        o_vaccines_dose      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --chamada � fun��o das an�lises
        IF NOT get_analysis_create(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_intern_name   => i_intern_name,
                                   i_patient       => i_patient,
                                   i_pat_pregnancy => i_pat_pregnancy,
                                   o_analysis      => o_analysis,
                                   o_val_habit     => o_analysis_val_habit,
                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --chamada � fun��o das vacinas
        IF NOT get_vaccines_create(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_intern_name   => i_intern_name,
                                   i_patient       => i_patient,
                                   i_pat_pregnancy => i_pat_pregnancy,
                                   o_vaccines      => o_vaccines,
                                   o_val_habit     => o_vaccines_val_habit,
                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --chamada � fun��o da informa��o das vacinas
        IF NOT get_vaccines_info(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_intern_name     => i_intern_name,
                                 i_patient         => i_patient,
                                 i_pat_pregnancy   => i_pat_pregnancy,
                                 o_vaccines_status => o_vaccines_status,
                                 o_vaccines_admin  => o_vaccines_admin,
                                 o_vaccines_dose   => o_vaccines_dose,
                                 o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_IMMUNOLOGY_CREATE',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_analysis_val_habit);
            pk_types.open_my_cursor(o_vaccines);
            pk_types.open_my_cursor(o_vaccines_val_habit);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_immunology_create;

    /************************************************************************************************************
    * Returns the data needed to build the screen that allows the creation of RH parameters in the Woman Health.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_intern_name        intern name do TIME_EVENT_GROUP
    * @param      i_pat_pregnancy      pregnancy's identifier
    *
    * @param      o_analysis           cursor with the list of analysis
    * @param      o_analysis_val_habit cursor with the usual values for each type of analysis
    * @param      o_preg_info          cursor with information about the current pregnacy
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/14
    ***********************************************************************************************************/
    FUNCTION get_rh_create
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_intern_name        IN time_event_group.intern_name%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_analysis           OUT pk_types.cursor_type,
        o_analysis_val_habit OUT pk_types.cursor_type,
        o_preg_info          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --chamada � fun��o das an�lises
        IF NOT get_analysis_create(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_intern_name   => i_intern_name,
                                   i_patient       => i_patient,
                                   i_pat_pregnancy => i_pat_pregnancy,
                                   o_analysis      => o_analysis,
                                   o_val_habit     => o_analysis_val_habit,
                                   o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -----------------------------------------
        -- GRAVIDEZ INFO
        -----------------------------------------
        g_error := 'GET CURSOR O_PREG';
        OPEN o_preg_info FOR
            SELECT decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') || pbg.flg_blood_group blood_type_mother_val,
                   pbg.flg_blood_group || decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') blood_type_mother_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T035') blood_type_mother_desc,
                   decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') || pp.blood_group_father blood_type_father_val,
                   pp.blood_group_father || decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') blood_type_father_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T036') blood_type_father_desc,
                   flg_antigl_aft_chb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T053') flg_antigl_atf_chb_desc,
                   flg_antigl_aft_abb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T054') flg_antigl_atf_abb_desc,
                   -- antiglobulina
                   flg_antigl_need,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_NEED', flg_antigl_need, i_lang) flg_antigl_need_desc_val,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T052') flg_antigl_need_desc
            
              FROM pat_pregnancy pp, pat_blood_group pbg, patient pat
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND pat.id_patient = i_patient
               AND pat.id_patient = pbg.id_patient(+)
               AND pat.id_patient = pp.id_patient(+)
               AND pbg.flg_status(+) = 'A';
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RH_CREATE',
                                              o_error);
            pk_types.open_my_cursor(o_analysis);
            pk_types.open_my_cursor(o_analysis_val_habit);
            pk_types.open_my_cursor(o_preg_info);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_rh_create;

    /************************************************************************************************************
    * This function creates the analysis in the database.
    *
    * @param      i_lang               language
    * @param      i_prof               profisisonal
    * @param      i_patient            patient's identifier
    * @param      i_episode            episode's identifier
    * @param      i_par_analysis       bydimensional array with (analysisId|parameterId) pairs
    * @param      i_results            array with the results for each analysis parameter
    * @param      i_unit_measure       array with unit measures for each analysis parameter
    * @param      i_date_str           harvest date
    *
    * @param      o_error              error message
    *
    * @return     boolean type, "False" on error or "True" if success
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/14
    ***********************************************************************************************************/
    FUNCTION set_analysis_create
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_pat_pregnancy          IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_par_analysis           IN table_table_number, -- analysisId|resultId
        i_results                IN table_varchar,
        i_analysis_desc          IN table_number,
        i_results_habit          IN table_varchar,
        i_analysis_req_det_id    IN table_number,
        i_unit_measure           IN table_number,
        i_date_str               IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_analysis           analysis.id_analysis%TYPE;
        l_id_analysis_parameter analysis_parameter.id_analysis_parameter%TYPE;
        l_id_analysis_param     analysis_param.id_analysis_param%TYPE;
        l_id_sample_type        analysis_param.id_sample_type%TYPE;
        l_result_par_value      analysis_result_par.desc_analysis_result%TYPE;
        l_analysis_desc_value   analysis_desc.id_analysis_desc%TYPE;
        l_unit_measure_value    unit_measure.id_unit_measure%TYPE;
        l_analysis_req_det_id   analysis_req_det.id_analysis_req_det%TYPE;
    
        --Valores habituais
        l_usual_values_val event_most_freq.value%TYPE;
        l_usual_values_flg event_most_freq.flg_group%TYPE;
    
        l_id_analysis_param_array     table_number;
        l_id_analysis_parameter_array table_number;
        l_result_par_value_array      table_varchar;
        l_analysis_desc_array         table_number;
        l_desc_par_value_array        table_varchar;
        l_unit_measure_value_array    table_number;
        l_temp_array_chr              table_varchar;
        l_temp_array_num              table_number;
        --Valores habituais
        l_usual_values_val_array table_varchar;
        l_usual_values_flg_array table_varchar;
    
        l_date_tstz TIMESTAMP WITH TIME ZONE;
    
        --para adicionar os values v�lidos
        --l_add_value NUMBER := 1;
        o_result VARCHAR2(4000);
    
    BEGIN
    
        IF i_date_str IS NULL
        THEN
            l_date_tstz := current_timestamp;
        ELSE
            l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date_str, NULL);
        END IF;
    
        --insert na periodic_observation_reg o valores para as v�rias colunas!
    
        INSERT INTO periodic_observation_reg --
            (id_periodic_observation_reg,
             dt_periodic_observation_reg,
             dt_result,
             id_episode,
             id_patient,
             flg_type_reg,
             flg_mig,
             flg_ref,
             flg_status,
             flg_group,
             adw_last_update) --
        VALUES --
            (seq_periodic_observation_reg.nextval,
             l_date_tstz,
             current_timestamp,
             i_episode,
             i_patient,
             'W',
             'N',
             'N',
             'A',
             'A',
             SYSDATE);
    
        FOR i IN 1 .. i_par_analysis.count
        LOOP
        
            --o array vai ter sempre apenas duas posi��es
            --1 - id da an�lise
            l_id_analysis := i_par_analysis(i) (1);
            -- 2 - id do parametro
            l_id_analysis_parameter := i_par_analysis(i) (2);
            l_id_analysis_param     := i_par_analysis(i) (3);
        
            g_error := 'LACK OF CONFIGURATION IN ANALYSIS_PARAM';
            SELECT ap.id_sample_type
              INTO l_id_sample_type
              FROM analysis_param ap
             WHERE ap.id_analysis_param = l_id_analysis_param;
        
            l_id_analysis_param_array     := table_number(l_id_analysis_param);
            l_id_analysis_parameter_array := table_number(l_id_analysis_parameter);
        
            --o resultado est� sempre na mesma posi��o do par an�lise|parametro
            l_result_par_value       := i_results(i);
            l_result_par_value_array := table_varchar(l_result_par_value);
            l_analysis_desc_value := CASE
                                         WHEN i_analysis_desc(i) = -1 THEN
                                          NULL
                                         ELSE
                                          i_analysis_desc(i)
                                     END;
            l_analysis_desc_array    := table_number(l_analysis_desc_value);
            l_desc_par_value_array   := table_varchar(NULL);
        
            --a unidade de medida est� sempre na mesma posi��o do par an�lise|parametro
            l_unit_measure_value       := i_unit_measure(i);
            l_unit_measure_value_array := table_number(l_unit_measure_value);
        
            l_temp_array_chr := table_varchar(NULL);
            l_temp_array_num := table_number(NULL);
        
            --Apenas s�o registados os valores v�lidos, mas fazendo apenas uma chamada � fun��o de set
            IF i_results(i) IS NOT NULL
            THEN
                l_analysis_req_det_id := i_analysis_req_det_id(i);
            
                g_error := 'CALL TO SET_LAB_TEST_RESULT';
                IF NOT pk_lab_tests_api_db.set_lab_test_result(i_lang                       => i_lang,
                                                               i_prof                       => i_prof,
                                                               i_patient                    => i_patient,
                                                               i_episode                    => i_episode,
                                                               i_analysis                   => l_id_analysis,
                                                               i_sample_type                => l_id_sample_type,
                                                               i_analysis_parameter         => l_id_analysis_parameter_array,
                                                               i_analysis_param             => l_id_analysis_param_array,
                                                               i_analysis_req_det           => l_analysis_req_det_id,
                                                               i_analysis_req_par           => l_temp_array_num,
                                                               i_analysis_result_par        => l_temp_array_num,
                                                               i_analysis_result_par_parent => NULL,
                                                               i_flg_type                   => table_varchar('N'),
                                                               i_harvest                    => NULL,
                                                               i_dt_sample                  => i_date_str,
                                                               i_prof_req                   => NULL,
                                                               i_dt_analysis_result         => i_date_str,
                                                               i_result_notes               => NULL,
                                                               i_result_value_1             => l_result_par_value_array,
                                                               i_analysis_desc              => l_analysis_desc_array,
                                                               i_unit_measure               => l_unit_measure_value_array,
                                                               i_result_status              => l_temp_array_num,
                                                               i_ref_val_min                => l_temp_array_chr,
                                                               i_ref_val_max                => l_temp_array_chr,
                                                               i_parameter_notes            => l_temp_array_chr,
                                                               i_flg_result_origin          => NULL,
                                                               i_result_origin_notes        => NULL,
                                                               i_flg_orig_analysis          => g_type_woman_health,
                                                               i_clinical_decision_rule     => i_clinical_decision_rule,
                                                               o_result                     => o_result,
                                                               o_error                      => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            
            END IF;
        
            --caso sejam enviados valores habituais
            IF i_results_habit.exists(i)
            THEN
                g_error := 'SET USUAL VALUES';
                --Valores habituais
                l_usual_values_val       := i_results_habit(i);
                l_usual_values_val_array := table_varchar(l_usual_values_val);
            
                l_usual_values_flg       := 'A'; --Analises
                l_usual_values_flg_array := table_varchar(l_usual_values_flg);
                --cria��o dos valores habituais para todos os par�metros....
                --Nota: Os valores habituais est�o associados a an�lises e n�o aos par�metros das
                -- an�lises porque na tabela event apenas temos as an�lises parametrizadas.
                g_error := 'CALL TO SET_EVENT_MOST_FREQ ';
                IF NOT pk_woman_health.set_event_most_freq(i_lang,
                                                           i_patient,
                                                           table_number(l_id_analysis),
                                                           --l_analysis_parameter_array,
                                                           l_usual_values_flg_array,
                                                           l_usual_values_val_array,
                                                           table_number(l_unit_measure_value),
                                                           i_pat_pregnancy,
                                                           i_prof,
                                                           i_episode,
                                                           o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            END IF;
        END LOOP;
    
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
                                              'SET_ANALYSIS_CREATE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_analysis_create;

    /**********************************************************************************************
    * Gets the minimum date of service
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient ID
    * @param i_pat_pregnancy          pregnancy ID
    * @param o_dt_reg                 minimum date of service
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Jos� Silva
    * @version                        2.5
    * @since                          2010/10/15
    **********************************************************************************************/
    FUNCTION get_min_dt_reg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_reg        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_MIN_DT_REG';
        l_dt_birth patient.dt_birth%TYPE;
        l_sysdate  TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_pat IS
            SELECT nvl(p.dt_birth,
                       CAST(pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                             i_prof.software,
                                                             pk_date_utils.add_to_ltstz(l_sysdate, -p.age, 'YEAR')) AS DATE))
              FROM patient p
             WHERE p.id_patient = i_patient;
    
    BEGIN
        l_sysdate := current_timestamp;
    
        g_error := 'GET PATIENT AGE';
        OPEN c_pat;
        FETCH c_pat
            INTO l_dt_birth;
        CLOSE c_pat;
    
        o_dt_reg := pk_date_utils.date_send(i_lang, l_dt_birth, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_min_dt_reg;

    /**********************************************************************************************
    * Verifies if woman is pregnant
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient ID
    * @param o_flg_pregnant           'Y' is pregnant; otherwise 'N'
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.1.0.1
    * @since                          2011/05/10
    **********************************************************************************************/
    FUNCTION is_woman_pregnant
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_flg_pregnant OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'IS_WOMAN_PREGNANT';
        --
        l_count PLS_INTEGER;
    BEGIN
        g_error := 'GET ACTIVE PREGNANCY';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT COUNT(*)
          INTO l_count
          FROM pat_pregnancy pp
         WHERE flg_status = pk_alert_constant.g_active
           AND id_patient = i_patient;
    
        IF l_count = 0
        THEN
            o_flg_pregnant := pk_alert_constant.g_no;
        ELSE
            o_flg_pregnant := pk_alert_constant.g_yes;
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END is_woman_pregnant;
BEGIN

    g_vs_read_active := 'A';
    g_vs_read_cancel := 'C';
    g_vs_rel_sum     := 'S'; -- TOTAL GLASGOW
    g_vs_rel_conc    := 'C'; -- PRESS�O ARTERIAL
    g_vs_rel_man     := 'M'; -- MANCHESTER
    g_vs_bio         := 'PE';
    g_vs_avail       := 'Y';
    g_vs_show        := 'Y';
    g_vs_pain        := 11;
    g_vs_fill_char   := 'V';
    g_active         := 'A';
    --
    g_type_graph := 'G';
    g_type_table := 'T';
    --
    g_available := 'Y';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
