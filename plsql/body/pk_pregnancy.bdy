/*-- Last Change Revision: $Rev: 2048196 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-10-21 17:10:42 +0100 (sex, 21 out 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_pregnancy IS

    g_package_name VARCHAR2(32);
    /* Package owner */
    g_package_owner VARCHAR2(32);

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION error_handling_ext
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlcode        IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        i_flg_action     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
    BEGIN
    
        l_error_in.set_all(i_lang,
                           i_sqlcode,
                           i_sqlerror,
                           i_error,
                           'ALERT',
                           g_package_name,
                           i_func_proc_name,
                           NULL,
                           i_flg_action);
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling_ext;

    /************************************************************************************************************ 
    * This function saves the history related to RH records
    *
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_rh_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_blood_group  IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_blood_rhesus IN pat_blood_group.flg_blood_rhesus%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_pregnancy_rh_hist pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE;
    
    BEGIN
    
        SELECT seq_pat_pregnancy_rh_hist.nextval
          INTO l_id_pat_pregnancy_rh_hist
          FROM dual;
    
        g_error := 'INSERT INTO PAT_PREGNANCY';
        INSERT INTO pat_pregnancy_rh_hist
            (id_pat_pregnancy_rh_hist,
             id_pat_pregnancy,
             id_prof_rh,
             dt_reg_rh,
             blood_group_father,
             blood_rhesus_father,
             blood_group_mother,
             blood_rhesus_mother,
             flg_antigl_aft_chb,
             flg_antigl_aft_abb,
             flg_antigl_need,
             titration_value,
             flg_antibody,
             id_episode_rh)
            SELECT l_id_pat_pregnancy_rh_hist,
                   id_pat_pregnancy,
                   id_prof_rh,
                   dt_reg_rh,
                   blood_group_father,
                   blood_rhesus_father,
                   i_flg_blood_group,
                   i_flg_blood_rhesus,
                   flg_antigl_aft_chb,
                   flg_antigl_aft_abb,
                   flg_antigl_need,
                   titration_value,
                   flg_antibody,
                   id_episode_rh
              FROM pat_pregnancy p
             WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PAT_PREGNANCY_RH_HIST', g_error, SQLERRM, TRUE, o_error);
    END set_pat_pregnancy_rh_hist;

    /********************************************************************************************
    * Returns the pregnancy probable end date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks
    * @param i_dt_init                Pregnancy start date
    * @param o_dt_end                 Pregnancy end date (serialized)
    * @param o_dt_end_chr             Pregnancy end date (formatted)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error                      
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/04
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_end
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_num_weeks   IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days    IN NUMBER,
        i_dt_init     IN VARCHAR2,
        o_dt_end      OUT VARCHAR2,
        o_dt_init_chr OUT VARCHAR2,
        o_dt_end_chr  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_end              DATE;
        l_dt_init             pat_pregnancy.dt_init_pregnancy%TYPE;
        l_num_weeks           NUMBER;
        l_num_weeks_performed NUMBER;
        l_num_weeks_us        NUMBER;
    
        l_exception EXCEPTION;
    BEGIN
    
        l_dt_init := to_date(i_dt_init, pk_date_utils.g_dateformat);
        l_dt_end  := pk_pregnancy_core.get_dt_pregnancy_end(i_lang, i_prof, i_num_weeks, i_num_days, l_dt_init);
    
        IF l_dt_end IS NOT NULL
        THEN
            o_dt_end := pk_date_utils.date_send(i_lang, l_dt_end, i_prof);
        
            o_dt_end_chr := pk_date_utils.date_chr_short_read(i_lang, l_dt_end, i_prof);
        END IF;
    
        IF NOT pk_pregnancy_core.get_gestation_weeks(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_num_weeks      => i_num_weeks,
                                                     i_num_days       => i_num_days,
                                                     i_num_weeks_exam => NULL,
                                                     i_num_days_exam  => NULL,
                                                     i_num_weeks_us   => NULL,
                                                     i_num_days_us    => NULL,
                                                     o_num_weeks      => l_num_weeks,
                                                     o_num_weeks_exam => l_num_weeks_performed,
                                                     o_num_weeks_us   => l_num_weeks_us,
                                                     o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_dt_init IS NULL
        THEN
            l_dt_init := pk_pregnancy_core.get_dt_pregnancy_start(i_prof            => i_prof,
                                                                  i_num_weeks       => l_num_weeks,
                                                                  i_num_weeks_exam  => NULL,
                                                                  i_num_weeks_us    => NULL,
                                                                  i_dt_intervention => NULL,
                                                                  i_flg_precision   => NULL);
        END IF;
    
        o_dt_init_chr := pk_date_utils.date_send(i_lang, l_dt_init, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_SUMM_PAGE_DOC_AREA_PREGN',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
        
    END get_dt_pregnancy_end;

    /********************************************************************************************
    * Returns all the information related with the ultrasound, by pregnancy weeks and days.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_us_performed        Date when the US was performed
    * @param o_num_weeks_performed    Gestational weeks at which the US was made
    * @param o_dt_us_performed        Date when the US was performed
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.15
    * @since                          2014/04/08
    **********************************************************************************************/
    FUNCTION get_us_dt_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_num_weeks_preg_init IN NUMBER,
        i_num_days_preg_init  IN NUMBER,
        i_dt_us_performed     IN VARCHAR2,
        o_num_weeks_performed OUT NUMBER,
        o_num_days_performed  OUT NUMBER,
        o_dt_us_performed     OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_init_preg    pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_us_performed pat_pregnancy.dt_us_performed%TYPE;
    
        l_dt_us_return pat_pregnancy.dt_us_performed%TYPE;
    
        l_exception EXCEPTION;
        l_num_weeks_us NUMBER;
        l_num_days_us  NUMBER;
    
    BEGIN
    
        l_dt_us_performed := to_date(i_dt_us_performed, pk_date_utils.g_dateformat);
    
        IF NOT pk_pregnancy_core.get_us_dt_info(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_num_weeks_preg_init => i_num_weeks_preg_init,
                                                i_num_days_preg_init  => i_num_days_preg_init,
                                                i_dt_us_performed     => l_dt_us_performed,
                                                o_num_weeks_performed => o_num_weeks_performed,
                                                o_num_days_performed  => o_num_days_performed,
                                                o_dt_us_performed     => l_dt_us_return,
                                                o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_dt_us_performed := pk_date_utils.date_send(i_lang, l_dt_us_return, i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'GET_US_DT_INFO', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_us_dt_info;

    /********************************************************************************************
    * Gets the formatted number of weeks and days of the current pregnancy (used in the report header)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy weeks and days
    *
    * @author                         José Silva
    * @version                        2.6.1.1
    * @since                          2011/06/09
    **********************************************************************************************/
    FUNCTION get_pregnancy_weeks
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_age   VARCHAR2(50);
        l_error t_error_out;
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
        l_flg_status   pat_pregnancy.flg_status%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy, pp.flg_status
              INTO l_dt_init_preg, l_flg_status
              FROM pat_pregnancy pp
             WHERE id_patient = i_pat
               AND flg_status = pk_pregnancy_core.g_pat_pregn_active;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        l_age := pk_pregnancy_core.get_pregn_formatted_weeks(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_weeks      => NULL,
                                                             i_dt_preg    => l_dt_init_preg,
                                                             i_flg_status => l_flg_status,
                                                             i_dt_reg     => NULL);
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PREGNANCY_WEEKS',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_pregnancy_weeks;

    /********************************************************************************************
    * Gets the formatted number of days of the current pregnancy
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy  days
    *
    * @author                         Gisela Couto
    * @version                        2.6.4.1.1
    * @since                          2014/08/27
    **********************************************************************************************/
    FUNCTION get_pregnancy_num_days
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_age   NUMBER;
        l_error t_error_out;
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy
              INTO l_dt_init_preg
              FROM pat_pregnancy pp
             WHERE id_patient = i_pat
               AND flg_status = pk_pregnancy_core.g_pat_pregn_active;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        l_age := pk_pregnancy_core.get_pregnancy_days(i_prof    => i_prof,
                                                      i_dt_preg => l_dt_init_preg,
                                                      i_dt_reg  => NULL,
                                                      i_weeks   => NULL);
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PREGNANCY_NUM_DAYS',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_pregnancy_num_days;

    /********************************************************************************************
    * Gets the formatted number of weeks and days of the current pregnancy (CDS API)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    *
    * @return                         Pregnancy weeks and days
    *
    * @author                         José Silva
    * @version                        2.6.1.2
    * @since                          2011/09/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_num_weeks
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_pat  IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_age   NUMBER;
        l_error t_error_out;
    
        l_dt_init_preg pat_pregnancy.dt_init_pregnancy%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy
              INTO l_dt_init_preg
              FROM pat_pregnancy pp
             WHERE id_patient = i_pat
               AND flg_status = pk_pregnancy_core.g_pat_pregn_active;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        l_age := pk_pregnancy_core.get_pregnancy_weeks(i_prof    => i_prof,
                                                       i_dt_preg => l_dt_init_preg,
                                                       i_dt_reg  => NULL,
                                                       i_weeks   => NULL);
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PREGNANCY_NUM_WEEKS',
                                              l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_pregnancy_num_weeks;

    /********************************************************************************************
    * Gets the weeks and days based in the input weeks or dates
    *
    * @param i_lagn                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_weeks                  Input weeks
    * @param i_days                   Input days
    * @param i_dt_preg                Pregnancy start date (only if i_weeks and i_days is null)
    * @param i_dt_reg                 Pregnancy end date (if any)
    * @param o_weeks                  Output weeks
    * @param o_days                   Output days
    * @param o_weeks_chr              Formatted weeks and days
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/07
    **********************************************************************************************/
    FUNCTION get_preg_weeks_and_days
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_weeks     IN pat_pregnancy.num_gest_weeks%TYPE,
        i_days      IN NUMBER,
        i_dt_preg   IN VARCHAR2,
        i_dt_reg    IN VARCHAR2,
        o_weeks     OUT NUMBER,
        o_days      OUT NUMBER,
        o_weeks_chr OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_weeks pat_pregnancy.num_gest_weeks%TYPE;
        l_days  NUMBER;
    
        l_num_weeks      pat_pregnancy.num_gest_weeks%TYPE;
        l_num_weeks_exam pat_pregnancy.num_gest_weeks_exam%TYPE;
        l_num_weeks_us   pat_pregnancy.num_gest_weeks_us%TYPE;
    
        l_exception EXCEPTION;
    
        l_dt_preg DATE;
        l_dt_reg  DATE;
    
        l_max_weeks NUMBER;
    
    BEGIN
    
        g_error   := 'GET DATES';
        l_dt_preg := to_date(i_dt_preg, pk_date_utils.g_dateformat);
        l_dt_reg  := to_date(i_dt_reg, pk_date_utils.g_dateformat);
    
        l_max_weeks := nvl(pk_sysconfig.get_config(g_gestation_weeks, i_prof), 42);
    
        g_error := 'GET WEEKS AND DAYS';
        IF i_weeks IS NOT NULL
        THEN
            l_weeks := i_weeks;
            l_days  := i_days;
        ELSIF l_dt_preg IS NOT NULL
        THEN
            l_weeks := pk_pregnancy_core.get_pregnancy_weeks(i_prof, l_dt_preg, l_dt_reg, NULL);
            l_days  := pk_pregnancy_core.get_pregnancy_days(i_prof, l_dt_preg, l_dt_reg, NULL);
        END IF;
    
        IF l_weeks <= l_max_weeks
        THEN
            g_error := 'GET GESTATION WEEKS';
            IF NOT pk_pregnancy_core.get_gestation_weeks(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_num_weeks      => l_weeks,
                                                         i_num_days       => l_days,
                                                         i_num_weeks_exam => NULL,
                                                         i_num_days_exam  => NULL,
                                                         i_num_weeks_us   => NULL,
                                                         i_num_days_us    => NULL,
                                                         o_num_weeks      => l_num_weeks,
                                                         o_num_weeks_exam => l_num_weeks_exam,
                                                         o_num_weeks_us   => l_num_weeks_us,
                                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error     := 'RETURN WEEKS';
            o_weeks     := l_weeks;
            o_days      := l_days;
            o_weeks_chr := pk_pregnancy_core.get_pregn_formatted_weeks(i_lang, i_prof, l_num_weeks, NULL, NULL);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_PREG_WEEKS_AND_DAYS',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_preg_weeks_and_days;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/23
    * @Reviewed by                    Gisela Couto
    * @Date                           2014/03/17
    **********************************************************************************************/
    FUNCTION get_summ_page_doc_area_pregn
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_doc_area_register  t_doc_area_register;
        l_doc_area_val       t_doc_area_val;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
        l_count              NUMBER;
    BEGIN
    
        IF i_doc_area IN (pk_pregnancy_core.g_doc_area_obs_adv,
                          pk_pregnancy_core.g_doc_area_curr_pregn,
                          pk_pregnancy_core.g_doc_area_obs_hist,
                          pk_pregnancy_core.g_doc_area_obs_idx)
        THEN
        
            IF NOT get_sum_page_doc_area_preg_int(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_pat               => i_pat,
                                                  i_doc_area          => i_doc_area,
                                                  o_doc_area_register => l_doc_area_register,
                                                  o_doc_area_val      => l_doc_area_val,
                                                  o_error             => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        
            OPEN o_doc_area_register FOR
                SELECT *
                  FROM TABLE(l_doc_area_register);
        
            OPEN o_doc_area_val FOR
                SELECT *
                  FROM TABLE(l_doc_area_val);
        
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_past_hist
        THEN
        
            IF NOT get_sum_page_doc_ar_past_preg(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_episode           => i_episode,
                                                 i_pat               => i_pat,
                                                 i_doc_area          => i_doc_area,
                                                 o_doc_area_register => o_doc_area_register,
                                                 o_doc_area_val      => o_doc_area_val,
                                                 o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_obs_idx_tmpl
        THEN
        
            IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => i_doc_area,
                                                      i_current_episode    => i_episode,
                                                      i_scope              => i_pat,
                                                      i_scope_type         => 'P',
                                                      o_doc_area_register  => o_doc_area_register,
                                                      o_doc_area_val       => o_doc_area_val,
                                                      o_template_layouts   => l_template_layouts,
                                                      o_doc_area_component => l_doc_area_component,
                                                      o_record_count       => l_count,
                                                      o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
            /*                    OPEN o_doc_area_register FOR
                SELECT *
                  FROM TABLE(l_doc_area_register);
            
            OPEN o_doc_area_val FOR
                SELECT *
                  FROM TABLE(l_doc_area_val);*/
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN error_handling_ext(i_lang,
                                      'GET_SUMM_PAGE_DOC_AREA_PREGN',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
        
    END get_summ_page_doc_area_pregn;

    FUNCTION get_sum_page_doc_area_preg_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT t_doc_area_register,
        o_doc_area_val      OUT t_doc_area_val,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sep         CONSTANT VARCHAR2(1) := '.';
        l_upper_limit CONSTANT NUMBER := pk_sysconfig.get_config('ADVERSE_OBSTETRIC_UPPER', i_prof);
    
        l_desc           VARCHAR2(200);
        l_weight_measure VARCHAR2(200);
        l_weight_id      unit_measure.id_unit_measure%TYPE;
    
        l_config_val sys_config.value%TYPE := pk_sysconfig.get_config('NEWBORN_CURR_STATUS_MULTICHOICE', i_prof);
    
        l_domain_r              CONSTANT sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_TYPE',
                                                                                             pk_pregnancy_core.g_pat_pregn_type_r,
                                                                                             i_lang);
        l_gest_weeks_u          CONSTANT sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_GEST_WEEKS',
                                                                                             pk_pregnancy_core.g_gest_weeks_unknown,
                                                                                             i_lang);
        l_label_sisprenantal    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T126'); --            
        l_label_dt_menstruation CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T127'); --
        l_label_menses          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T128'); --
        l_label_cycle           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T129'); --
        l_label_contracep       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T130'); --
        l_label_contracep_type  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T166'); --
        l_label_dt_contracep    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T131'); --
        l_label_gest_age        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T132'); --
        l_label_gest_reported   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T092'); --
        l_label_edd_lmp         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T133'); --
        l_label_gest_exam       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T148'); --
        l_label_gest_us         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T136'); --
        l_label_edd_us          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T134'); --
        l_label_us_performed    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T164'); --
        l_label_us_at_gest_age  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T165'); --
        l_label_fetus_num       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T078');
        l_label_outcome         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T146'); --
        l_label_compl           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T140'); --
        l_label_interv          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T141'); --
        l_label_dt_birth        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T145'); --
        l_label_notes           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T100'); --
        l_label_extr            CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T177'); --
        l_label_num_birth       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T179'); --
        l_label_num_ab          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T180'); --
        l_label_num_gest        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T181'); --
    
        l_title_fetus           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T084'); -- newborn
        l_title_fetus_ab        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T183'); -- abortion - fetus
        l_label_fetus_status    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T095'); --
        l_label_fetus_ab_status CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T182'); -- label fetus status during abortion
        l_label_birth_type      CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T144'); --
        l_label_fetus_gender    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T096');
        l_label_weight          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T137'); --
        l_label_health          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T143'); --
    
        l_label_flg_health CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T174'); --
    
        l_label_fetus_weight CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T097'); --
    
        l_label_pregnancy CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T021');
        l_label_pregn_num CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T091');
        l_label_weeks     CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001');
        l_label_week      CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T120');
    
        l_label_weight_sup CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T115');
        l_label_fetus_dead CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T116');
        l_label_num_abort  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T121');
        l_label_pre_term   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T117');
        l_label_c_section  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T118');
    
        l_label_days       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T158');
        l_closed_by_system CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'COMMON_M141');
        l_outdated         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'PAT_PREGNANCY_M008');
    
        l_label_labour_onset CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              i_prof,
                                                                                              
                                                                                              'WOMAN_HEALTH_T147'); --
    
        l_label_labour_duration CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 i_prof,
                                                                                                 'WOMAN_HEALTH_T138'); --                                                                                   
        l_auto_close            CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 i_prof,
                                                                                                 'PAT_PREGNANCY_M009');
    BEGIN
    
        IF i_doc_area = pk_pregnancy_core.g_doc_area_curr_pregn
        THEN
            g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
            SELECT t_doc_area_register_line(id_epis_documentation    => id_epis_documentation,
                                            PARENT                   => PARENT,
                                            id_doc_template          => id_doc_template,
                                            dt_creation              => dt_creation,
                                            dt_register              => dt_register,
                                            dt_pat_pregnancy_tstz    => dt_pat_pregnancy_tstz,
                                            id_professional          => id_professional,
                                            nick_name                => nick_name,
                                            desc_speciality          => desc_speciality,
                                            id_doc_area              => id_doc_area,
                                            flg_status               => flg_status,
                                            flg_preg_status          => flg_preg_status,
                                            desc_status              => desc_status,
                                            notes                    => notes,
                                            dt_last_update           => dt_last_update,
                                            flg_type_register        => flg_type_register,
                                            flg_type                 => flg_type,
                                            n_pregnancy              => n_pregnancy,
                                            pregnancy_number         => pregnancy_number,
                                            dt_last_menstruation     => dt_last_menstruation,
                                            weeks_number             => weeks_number,
                                            days_number              => days_number,
                                            weeks_measure            => weeks_measure,
                                            weight_measure           => weight_measure,
                                            n_children               => n_children,
                                            flg_abortion_type        => flg_abortion_type,
                                            flg_childbirth_type      => flg_childbirth_type,
                                            flg_child_status         => flg_child_status,
                                            flg_gender               => flg_gender,
                                            weight                   => weight,
                                            weight_um                => weight_um,
                                            present_health           => present_health,
                                            flg_present_health       => flg_present_health,
                                            flg_complication         => flg_complication,
                                            notes_complications      => notes_complications,
                                            id_inst_intervention     => id_inst_intervention,
                                            flg_desc_intervention    => flg_desc_intervention,
                                            desc_intervention        => desc_intervention,
                                            dt_intervention          => dt_intervention,
                                            dt_intervention_tstz     => dt_intervention_tstz,
                                            dt_init_pregnancy        => dt_init_pregnancy,
                                            flg_dt_interv_precision  => flg_dt_interv_precision,
                                            dt_intervention_chr      => dt_intervention_chr,
                                            pregnancy_notes          => pregnancy_notes,
                                            flg_menses               => flg_menses,
                                            cycle_duration           => cycle_duration,
                                            flg_use_constraceptives  => flg_use_constraceptives,
                                            type_description         => type_description,
                                            type_description_field   => type_description_field,
                                            type_ids                 => type_ids,
                                            type_free_text           => type_free_text,
                                            dt_contrac_meth_end      => dt_contrac_meth_end,
                                            flg_dt_contrac_precision => flg_dt_contrac_precision,
                                            dt_pdel_lmp              => dt_pdel_lmp,
                                            code_state               => code_state,
                                            code_year                => code_year,
                                            code_number              => code_number,
                                            weeks_number_exam        => weeks_number_exam,
                                            days_number_exam         => days_number_exam,
                                            weeks_number_us          => weeks_number_us,
                                            days_number_us           => days_number_us,
                                            dt_pdel_correct          => dt_pdel_correct,
                                            dt_us_performed          => dt_us_performed,
                                            num_weeks_at_us          => num_weeks_at_us,
                                            num_days_at_us           => num_days_at_us,
                                            flg_del_onset            => flg_del_onset,
                                            del_duration             => del_duration,
                                            flg_extraction           => flg_extraction,
                                            extraction_desc          => extraction_desc,
                                            flg_preg_out_type        => flg_preg_out_type,
                                            preg_out_type_desc       => preg_out_type_desc,
                                            num_births               => num_births,
                                            num_abortions            => num_abortions,
                                            num_gestations           => num_gestations,
                                            flg_gest_weeks           => flg_gest_weeks,
                                            flg_gest_weeks_exam      => flg_gest_weeks_exam,
                                            flg_gest_weeks_us        => flg_gest_weeks_us,
                                            viewer_category          => viewer_category,
                                            viewer_category_desc     => viewer_category_desc,
                                            viewer_id_prof           => viewer_id_prof,
                                            viewer_id_epis           => viewer_id_epis,
                                            viewer_date              => viewer_date,
                                            rank                     => rank)
              BULK COLLECT
              INTO o_doc_area_register
              FROM (SELECT pp.id_pat_pregnancy id_epis_documentation,
                           NULL PARENT,
                           NULL id_doc_template,
                           pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_creation,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       pp.dt_pat_pregnancy_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) dt_register,
                           pp.dt_pat_pregnancy_tstz dt_pat_pregnancy_tstz,
                           pp.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional) nick_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pp.id_professional,
                                                            pp.dt_pat_pregnancy_tstz,
                                                            pp.id_episode) desc_speciality,
                           i_doc_area id_doc_area,
                           decode(pp.flg_status,
                                  pk_pregnancy_core.g_pat_pregn_cancel,
                                  pk_pregnancy_core.g_pat_pregn_cancel,
                                  pk_pregnancy_core.g_pat_pregn_active) flg_status,
                           pp.flg_status flg_preg_status,
                           pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pp.flg_status, i_lang) desc_status,
                           NULL notes,
                           pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                           pk_pregnancy_core.g_free_text flg_type_register,
                           pk_pregnancy_core.g_pat_pregn_type_c flg_type,
                           l_label_pregn_num || ' ' || pp.n_pregnancy n_pregnancy,
                           -- INFO needed in the creation/edition screen
                           pp.n_pregnancy pregnancy_number,
                           pk_date_utils.date_send(i_lang, dt_last_menstruation, i_prof) dt_last_menstruation,
                           pk_pregnancy_core.get_pregnancy_weeks(i_prof, pp.dt_init_preg_lmp, NULL, NULL) weeks_number,
                           pk_pregnancy_core.get_pregnancy_days(i_prof, pp.dt_init_preg_lmp, NULL, NULL) days_number,
                           l_label_weeks weeks_measure,
                           pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                        i_prof,
                                                                        (SELECT ppf.id_unit_measure
                                                                           FROM pat_pregn_fetus ppf
                                                                          WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                                                            AND ppf.id_unit_measure IS NOT NULL
                                                                            AND rownum = 1)) weight_measure,
                           pp.n_children,
                           pk_pregnancy_core.get_abortion_type(pp.flg_status) flg_abortion_type,
                           CAST(MULTISET (SELECT ppf.flg_childbirth_type
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_varchar) flg_childbirth_type,
                           CAST(MULTISET
                                (SELECT decode(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_unk, NULL, ppf.flg_status) flg_status
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_varchar) flg_child_status,
                           CAST(MULTISET (SELECT ppf.flg_gender
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_varchar) flg_gender,
                           CAST(MULTISET (SELECT ppf.weight
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_number) weight,
                           CAST(MULTISET (SELECT ppf.id_unit_measure
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_number) weight_um,
                           CAST(MULTISET (SELECT ppf.present_health
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                        instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                        ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                  ORDER BY ppf.fetus_number) AS table_varchar) present_health,
                           CAST(MULTISET (SELECT ppf.flg_present_health
                                   FROM pat_pregn_fetus ppf
                                  WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                    AND ppf.flg_present_health = pk_alert_constant.g_yes
                                  ORDER BY ppf.fetus_number) AS table_varchar) flg_present_health,
                           pk_pregnancy_core.get_serialized_compl(i_lang,
                                                                  i_prof,
                                                                  pp.flg_complication,
                                                                  pp.id_pat_pregnancy) flg_complication,
                           pp.notes_complications,
                           pp.id_inst_intervention,
                           pp.flg_desc_intervention,
                           pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                   pp.id_inst_intervention,
                                                                   pp.flg_desc_intervention,
                                                                   pp.desc_intervention,
                                                                   'N') desc_intervention,
                           pk_date_utils.date_send_tsz(i_lang, pp.dt_intervention, i_prof) dt_intervention,
                           pp.dt_intervention dt_intervention_tstz,
                           pp.dt_init_pregnancy dt_init_pregnancy,
                           pp.flg_dt_interv_precision,
                           pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                 i_prof,
                                                                 pp.dt_intervention,
                                                                 pp.flg_dt_interv_precision) dt_intervention_chr,
                           pp.notes pregnancy_notes,
                           --
                           pp.flg_menses,
                           pp.cycle_duration,
                           pp.flg_use_constraceptives,
                           
                           pk_pregnancy_core.get_contraception_type(i_lang,
                                                                    i_prof,
                                                                    pp.id_pat_pregnancy,
                                                                    NULL,
                                                                    pk_alert_constant.g_no) type_description,
                           pk_pregnancy_core.get_contraception_type(i_lang, i_prof, pp.id_pat_pregnancy, NULL) type_description_field,
                           pk_pregnancy_core.get_contraception_type_id(i_lang, i_prof, pp.id_pat_pregnancy) type_ids,
                           (SELECT pct.other_contraception_type
                              FROM pat_preg_cont_type pct
                             WHERE pct.id_pat_pregnancy = pp.id_pat_pregnancy
                               AND pct.id_contrac_type = pk_pregnancy_core.g_desc_contract_type_other) type_free_text,
                           pk_date_utils.date_send(i_lang, pp.dt_contrac_meth_end, i_prof) dt_contrac_meth_end,
                           pp.flg_dt_contrac_precision,
                           pk_date_utils.date_send(i_lang, pp.dt_pdel_lmp, i_prof) dt_pdel_lmp,
                           -- SISPRENATAL
                           nvl(pc.code_state, pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state)) code_state,
                           pc.code_year,
                           pc.code_number,
                           --
                           pk_pregnancy_core.get_pregnancy_weeks(i_prof, pp.dt_init_preg_exam, NULL, NULL) weeks_number_exam,
                           pk_pregnancy_core.get_pregnancy_days(i_prof, pp.dt_init_preg_exam, NULL, NULL) days_number_exam,
                           --
                           nvl2(pp.num_gest_weeks_us,
                                pk_pregnancy_core.get_pregnancy_weeks(i_prof, pp.dt_init_pregnancy, NULL, NULL),
                                NULL) weeks_number_us,
                           nvl2(pp.num_gest_weeks_us,
                                pk_pregnancy_core.get_pregnancy_days(i_prof, pp.dt_init_pregnancy, NULL, NULL),
                                NULL) days_number_us,
                           --
                           nvl(pk_date_utils.date_send(i_lang, pp.dt_pdel_correct, i_prof),
                               nvl2(pp.num_gest_weeks_us,
                                    pk_date_utils.date_send(i_lang,
                                                            pk_pregnancy_core.get_dt_pregnancy_end(i_lang,
                                                                                                   i_prof,
                                                                                                   pp.num_gest_weeks_us,
                                                                                                   NULL,
                                                                                                   pp.dt_init_pregnancy),
                                                            i_prof),
                                    NULL)) dt_pdel_correct,
                           pk_date_utils.date_send(i_lang, pp.dt_us_performed, i_prof) dt_us_performed,
                           nvl2(pp.dt_us_performed,
                                pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                      pp.dt_init_pregnancy,
                                                                      pp.dt_us_performed,
                                                                      NULL),
                                NULL) num_weeks_at_us,
                           nvl2(pp.dt_us_performed,
                                pk_pregnancy_core.get_pregnancy_days(i_prof,
                                                                     pp.dt_init_pregnancy,
                                                                     pp.dt_us_performed,
                                                                     NULL),
                                NULL) num_days_at_us,
                           NULL flg_del_onset,
                           NULL del_duration,
                           pp.flg_extraction,
                           pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION', pp.flg_extraction, i_lang) extraction_desc,
                           pp.flg_preg_out_type,
                           pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE', pp.flg_preg_out_type, i_lang) preg_out_type_desc,
                           pp.num_births,
                           pp.num_abortions,
                           pp.num_gestations,
                           pp.flg_gest_weeks,
                           pp.flg_gest_weeks_exam,
                           pp.flg_gest_weeks_us,
                           NULL viewer_category,
                           NULL viewer_category_desc,
                           NULL viewer_id_prof,
                           NULL viewer_id_epis,
                           NULL viewer_date,
                           NULL rank
                      FROM pat_pregnancy pp
                      LEFT JOIN pat_pregnancy_code pc
                        ON pp.id_pat_pregnancy = pc.id_pat_pregnancy
                     WHERE pp.id_patient = i_pat
                       AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_active
                     ORDER BY pp.n_pregnancy DESC);
        
            g_error := 'GET CURSOR O_DOC_AREA_VAL';
        
            SELECT t_doc_area_val_line(id_epis_documentation     => id_epis_documentation,
                                       PARENT                    => PARENT,
                                       id_documentation          => id_documentation,
                                       id_doc_component          => id_doc_component,
                                       id_doc_element_crit       => id_doc_element_crit,
                                       dt_reg                    => dt_reg,
                                       desc_doc_component        => desc_doc_component,
                                       desc_element              => desc_element,
                                       VALUE                     => VALUE,
                                       id_doc_area               => id_doc_area,
                                       rank_component            => rank_component,
                                       rank_element              => rank_element,
                                       desc_qualification        => desc_qualification,
                                       flg_current_episode       => flg_current_episode,
                                       id_epis_documentation_det => id_epis_documentation_det)
              BULK COLLECT
              INTO o_doc_area_val
              FROM (SELECT id_pat_pregnancy id_epis_documentation,
                           NULL PARENT,
                           0 id_documentation,
                           0 id_doc_component,
                           NULL id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                           -- first title
                           pk_utils.to_bold(first_title) desc_doc_component,
                           -- remove the last characters since flash already shows them
                           substr(pregnancy_info, 1, length(pregnancy_info) - 2) desc_element,
                           NULL VALUE,
                           i_doc_area id_doc_area,
                           1 rank_component,
                           1 rank_element,
                           NULL desc_qualification,
                           NULL flg_current_episode,
                           NULL id_epis_documentation_det
                      FROM (SELECT pp.id_pat_pregnancy,
                                   pp.dt_pat_pregnancy_tstz,
                                   pp.first_title,
                                   -- SISPRENATAL
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_sisprenantal,
                                                                         pk_pregnancy_core.get_pat_pregnancy_code(i_lang,
                                                                                                                  i_prof,
                                                                                                                  pp.id_pat_pregnancy,
                                                                                                                  NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- LMP
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_dt_menstruation,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              dt_last_menstruation,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Menses
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_menses,
                                                                         pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MENSES',
                                                                                                 pp.flg_menses,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Cycle duration
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_cycle,
                                                                         nvl2(pp.cycle_duration,
                                                                              pp.cycle_duration || ' ' || l_label_days,
                                                                              NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Contraceptive use
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_contracep,
                                                                         pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_USE_CONSTRACEPTIVES',
                                                                                                 pp.flg_use_constraceptives,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   
                                   -- Contraceptive type
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_contracep_type,
                                                                         pk_pregnancy_core.get_contraception_type(i_lang,
                                                                                                                  i_prof,
                                                                                                                  pp.id_pat_pregnancy,
                                                                                                                  NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Last use of contraceptive
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_dt_contracep,
                                                                         pk_pregnancy_core.get_dt_contrac_end(i_lang,
                                                                                                              i_prof,
                                                                                                              pp.dt_contrac_meth_end,
                                                                                                              pp.flg_dt_contrac_precision),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Gestational age by LMP
                                    decode(pp.flg_gest_weeks,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_gest_age,
                                                                                l_gest_weeks_u,
                                                                                l_sep,
                                                                                pp.first_title),
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_gest_age,
                                                                                pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                            i_prof,
                                                                                                                            pp.num_gest_weeks,
                                                                                                                            dt_init_preg_lmp,
                                                                                                                            pp.dt_intervention,
                                                                                                                            pp.flg_status),
                                                                                l_sep,
                                                                                pp.first_title)) ||
                                   -- EDD by LMP
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_edd_lmp,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_pdel_lmp,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- Gestational age by examination
                                    decode(pp.flg_gest_weeks_exam,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_exam,
                                                                                      l_gest_weeks_u,
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_exam),
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_exam,
                                                                                      nvl2(pp.num_gest_weeks_exam,
                                                                                           pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                       i_prof,
                                                                                                                                       pp.num_gest_weeks_exam,
                                                                                                                                       pp.dt_init_preg_exam,
                                                                                                                                       pp.dt_intervention,
                                                                                                                                       pp.flg_status),
                                                                                           NULL),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_exam)) ||
                                   -- Gestational age by US
                                    decode(pp.flg_gest_weeks_us,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_us,
                                                                                      l_gest_weeks_u,
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_us),
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_us,
                                                                                      nvl2(pp.num_gest_weeks_us,
                                                                                           pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                       i_prof,
                                                                                                                                       pp.num_gest_weeks_us,
                                                                                                                                       pp.dt_init_pregnancy,
                                                                                                                                       pp.dt_intervention,
                                                                                                                                       pp.flg_status),
                                                                                           NULL),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_us)) ||
                                   -- EDD by US
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_edd_us,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_pdel_correct,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- US performed in
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_us_performed,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_us_performed,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- US performed at gestational age
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_us_at_gest_age,
                                                                         nvl2(pp.dt_us_performed,
                                                                              pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                          i_prof,
                                                                                                                          NULL,
                                                                                                                          pp.dt_init_pregnancy,
                                                                                                                          pp.dt_us_performed,
                                                                                                                          pp.flg_status),
                                                                              NULL),
                                                                         l_sep,
                                                                         '') ||
                                   -- número de fetos
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_fetus_num,
                                                                         pp.n_children,
                                                                         l_sep,
                                                                         '') ||
                                   -- complicações
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_compl,
                                                                               pk_pregnancy_core.get_preg_complications(i_lang,
                                                                                                                        i_prof,
                                                                                                                        pp.flg_complication,
                                                                                                                        pp.notes_complications,
                                                                                                                        pp.id_pat_pregnancy,
                                                                                                                        NULL),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_compl) ||
                                   
                                   -- Expulsion
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_extr,
                                                                               pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION',
                                                                                                       pp.flg_extraction,
                                                                                                       i_lang),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                   -- pregnancy outcome
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_c,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_outcome,
                                                                                      pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                               pp.flg_status,
                                                                                                                               pp.id_pat_pregnancy,
                                                                                                                               NULL,
                                                                                                                               pk_pregnancy_core.g_type_summ),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_out)) ||
                                   --pregnacy outcome type (when expulsion)
                                    decode(pp.flg_extraction,
                                           pk_pregnancy_core.g_pat_pregn_extract_y,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_outcome,
                                                                                      pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE',
                                                                                                              pp.flg_preg_out_type,
                                                                                                              i_lang),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_out)) ||
                                   -- Intervention date
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_c,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_dt_birth,
                                                                                pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                                      i_prof,
                                                                                                                      pp.dt_intervention,
                                                                                                                      pp.flg_dt_interv_precision),
                                                                                l_sep,
                                                                                pp.first_title)) ||
                                   -- pregnancy summary    
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_birth,
                                                                               pp.num_births,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_ab,
                                                                               pp.num_abortions,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_gest,
                                                                               pp.num_gestations,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                   -- notas
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_notes,
                                                                               pp.notes,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_notes) pregnancy_info
                              FROM (SELECT id_pat_pregnancy,
                                           flg_type,
                                           num_gest_weeks,
                                           dt_pat_pregnancy_tstz,
                                           dt_last_menstruation,
                                           flg_menses,
                                           cycle_duration,
                                           flg_use_constraceptives,
                                           dt_contrac_meth_end,
                                           flg_dt_contrac_precision,
                                           dt_intervention,
                                           flg_dt_interv_precision,
                                           dt_pdel_lmp,
                                           num_gest_weeks_exam,
                                           dt_init_preg_exam,
                                           dt_init_preg_lmp,
                                           num_gest_weeks_us,
                                           dt_init_pregnancy,
                                           dt_pdel_correct,
                                           dt_us_performed,
                                           n_children,
                                           flg_complication,
                                           notes_complications,
                                           notes,
                                           pregn.flg_extraction,
                                           pregn.flg_preg_out_type,
                                           pregn.num_births,
                                           pregn.num_abortions,
                                           pregn.num_gestations,
                                           pregn.flg_gest_weeks,
                                           pregn.flg_gest_weeks_exam,
                                           pregn.flg_gest_weeks_us,
                                           pk_pregnancy_core.get_summ_page_first_title(i_lang,
                                                                                       i_prof,
                                                                                       id_pat_pregnancy,
                                                                                       NULL,
                                                                                       flg_type) first_title,
                                           pk_pregnancy_core.check_break_summ_pg_exam(i_lang,
                                                                                      i_prof,
                                                                                      flg_type,
                                                                                      num_gest_weeks_exam) break_exam,
                                           pk_pregnancy_core.check_break_summ_pg_us(i_lang,
                                                                                    i_prof,
                                                                                    flg_type,
                                                                                    num_gest_weeks_us,
                                                                                    dt_pdel_correct,
                                                                                    dt_us_performed,
                                                                                    n_children) break_us,
                                           pk_pregnancy_core.check_break_summ_pg_compl(i_lang,
                                                                                       i_prof,
                                                                                       flg_type,
                                                                                       id_pat_pregnancy,
                                                                                       NULL,
                                                                                       flg_complication,
                                                                                       notes_complications) break_compl,
                                           pk_pregnancy_core.check_break_summ_pg_out(i_lang,
                                                                                     i_prof,
                                                                                     flg_type,
                                                                                     id_pat_pregnancy,
                                                                                     flg_status,
                                                                                     dt_intervention,
                                                                                     id_inst_intervention,
                                                                                     flg_desc_intervention,
                                                                                     desc_intervention) break_out,
                                           pk_pregnancy_core.check_break_summ_pg_notes(i_lang, i_prof, flg_type, notes) break_notes,
                                           pregn.flg_status
                                      FROM pat_pregnancy pregn
                                     WHERE id_patient = i_pat
                                       AND flg_status = pk_pregnancy_core.g_pat_pregn_active) pp)
                    UNION ALL
                    SELECT id_pat_pregnancy id_epis_documentation,
                           NULL PARENT,
                           id_pat_pregn_fetus id_documentation,
                           id_pat_pregn_fetus id_doc_component,
                           NULL id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                           -- TITULO
                           '<br>' || pk_utils.to_bold(l_title_fetus) || ' ' || fetus_number desc_doc_component,
                           -- remove the last characters since flash already shows them
                           substr(fetus_info, 1, length(fetus_info) - 2) desc_element,
                           NULL VALUE,
                           i_doc_area id_doc_area,
                           1 rank_component,
                           1 rank_element,
                           NULL desc_qualification,
                           NULL flg_current_episode,
                           NULL id_epis_documentation_det
                      FROM (SELECT pp.id_pat_pregnancy,
                                   ppf.id_pat_pregn_fetus,
                                   pp.dt_pat_pregnancy_tstz,
                                   ppf.fetus_number,
                                   '<br>' ||
                                   -- estado
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_fetus_status,
                                                                         pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_STATUS',
                                                                                                 ppf.flg_status,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         '') ||
                                   --tipo de parto
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_birth_type,
                                                                         pk_sysdomain.get_domain_no_avail('PAT_PREGN_FETUS.FLG_CHILDBIRTH_TYPE',
                                                                                                          ppf.flg_childbirth_type,
                                                                                                          i_lang),
                                                                         l_sep,
                                                                         '') ||
                                   -- sexo
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_fetus_gender,
                                                                         pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_GENDER',
                                                                                                 ppf.flg_gender,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         '') ||
                                   -- peso
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_weight,
                                                                         decode(ppf.weight,
                                                                                NULL,
                                                                                NULL,
                                                                                ppf.weight || ' ' ||
                                                                                pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                                                                             i_prof,
                                                                                                                             ppf.id_unit_measure)),
                                                                         l_sep,
                                                                         '') ||
                                   -- present health 
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_health,
                                                                         ppf.present_health,
                                                                         l_sep,
                                                                         '') fetus_info
                              FROM pat_pregnancy pp, pat_pregn_fetus ppf
                             WHERE pp.id_patient = i_pat
                               AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_active
                               AND ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                               AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                   instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                   ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk))
                     ORDER BY id_epis_documentation, id_doc_component);
        
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_obs_hist
        THEN
            g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        
            SELECT t_doc_area_register_line(id_epis_documentation    => id_epis_documentation,
                                            PARENT                   => PARENT,
                                            id_doc_template          => id_doc_template,
                                            dt_creation              => dt_creation,
                                            dt_register              => dt_register,
                                            dt_pat_pregnancy_tstz    => dt_pat_pregnancy_tstz,
                                            id_professional          => id_professional,
                                            nick_name                => nick_name,
                                            desc_speciality          => desc_speciality,
                                            id_doc_area              => id_doc_area,
                                            flg_status               => flg_status,
                                            flg_preg_status          => flg_preg_status,
                                            desc_status              => desc_status,
                                            notes                    => notes,
                                            dt_last_update           => dt_last_update,
                                            flg_type_register        => flg_type_register,
                                            flg_type                 => flg_type,
                                            n_pregnancy              => n_pregnancy,
                                            pregnancy_number         => pregnancy_number,
                                            dt_last_menstruation     => dt_last_menstruation,
                                            weeks_number             => weeks_number,
                                            days_number              => days_number,
                                            weeks_measure            => weeks_measure,
                                            weight_measure           => weight_measure,
                                            n_children               => n_children,
                                            flg_abortion_type        => flg_abortion_type,
                                            flg_childbirth_type      => flg_childbirth_type,
                                            flg_child_status         => flg_child_status,
                                            flg_gender               => flg_gender,
                                            weight                   => weight,
                                            weight_um                => weight_um,
                                            present_health           => present_health,
                                            flg_present_health       => flg_present_health,
                                            flg_complication         => flg_complication,
                                            notes_complications      => notes_complications,
                                            id_inst_intervention     => id_inst_intervention,
                                            flg_desc_intervention    => flg_desc_intervention,
                                            desc_intervention        => desc_intervention,
                                            dt_intervention          => dt_intervention,
                                            dt_intervention_tstz     => dt_intervention_tstz,
                                            dt_init_pregnancy        => dt_init_pregnancy,
                                            flg_dt_interv_precision  => flg_dt_interv_precision,
                                            dt_intervention_chr      => dt_intervention_chr,
                                            pregnancy_notes          => pregnancy_notes,
                                            flg_menses               => flg_menses,
                                            cycle_duration           => cycle_duration,
                                            flg_use_constraceptives  => flg_use_constraceptives,
                                            type_description         => type_description,
                                            type_description_field   => type_description_field,
                                            type_ids                 => type_ids,
                                            type_free_text           => type_free_text,
                                            dt_contrac_meth_end      => dt_contrac_meth_end,
                                            flg_dt_contrac_precision => flg_dt_contrac_precision,
                                            dt_pdel_lmp              => dt_pdel_lmp,
                                            code_state               => code_state,
                                            code_year                => code_year,
                                            code_number              => code_number,
                                            weeks_number_exam        => weeks_number_exam,
                                            days_number_exam         => days_number_exam,
                                            weeks_number_us          => weeks_number_us,
                                            days_number_us           => days_number_us,
                                            dt_pdel_correct          => dt_pdel_correct,
                                            dt_us_performed          => dt_us_performed,
                                            num_weeks_at_us          => num_weeks_at_us,
                                            num_days_at_us           => num_days_at_us,
                                            flg_del_onset            => flg_del_onset,
                                            del_duration             => del_duration,
                                            flg_extraction           => flg_extraction,
                                            extraction_desc          => extraction_desc,
                                            flg_preg_out_type        => flg_preg_out_type,
                                            preg_out_type_desc       => preg_out_type_desc,
                                            num_births               => num_births,
                                            num_abortions            => num_abortions,
                                            num_gestations           => num_gestations,
                                            flg_gest_weeks           => flg_gest_weeks,
                                            flg_gest_weeks_exam      => flg_gest_weeks_exam,
                                            flg_gest_weeks_us        => flg_gest_weeks_us,
                                            viewer_category          => viewer_category,
                                            viewer_category_desc     => viewer_category_desc,
                                            viewer_id_prof           => viewer_id_prof,
                                            viewer_id_epis           => viewer_id_epis,
                                            viewer_date              => viewer_date,
                                            rank                     => rank)
              BULK COLLECT
              INTO o_doc_area_register
              FROM (
                    
                    SELECT pp.id_pat_pregnancy id_epis_documentation,
                            NULL PARENT,
                            NULL id_doc_template,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_creation, -- 
                            pk_date_utils.date_char_tsz(i_lang,
                                                        pp.dt_pat_pregnancy_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_register,
                            
                            pp.dt_pat_pregnancy_tstz dt_pat_pregnancy_tstz,
                            pp.id_professional,
                            CASE
                                 WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                                  l_closed_by_system
                                 ELSE
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional)
                             END nick_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             pp.id_professional,
                                                             pp.dt_pat_pregnancy_tstz,
                                                             pp.id_episode) desc_speciality,
                            i_doc_area id_doc_area,
                            decode(pp.flg_status,
                                   pk_pregnancy_core.g_pat_pregn_cancel,
                                   pk_pregnancy_core.g_pat_pregn_cancel,
                                   pk_pregnancy_core.g_pat_pregn_auto_close,
                                   pk_pregnancy_core.g_pat_pregn_auto_close,
                                   pk_pregnancy_core.g_pat_pregn_active) flg_status,
                            pp.flg_status flg_preg_status,
                            CASE
                                 WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                                  l_outdated
                                 ELSE
                                  pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pp.flg_status, i_lang)
                             END desc_status,
                            NULL notes,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                            pk_pregnancy_core.g_free_text flg_type_register,
                            CASE
                                 WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                                  pk_pregnancy_core.g_pat_pregn_type_r
                                 ELSE
                                  decode(pp.flg_type,
                                         pk_pregnancy_core.g_pat_pregn_type_r,
                                         pk_pregnancy_core.g_pat_pregn_type_r,
                                         pk_pregnancy_core.g_pat_pregn_type_cr)
                             END flg_type,
                            l_label_pregn_num || ' ' || pp.n_pregnancy ||
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_r,
                                   chr(10) || '(' || l_domain_r || ')',
                                   NULL) n_pregnancy,
                            pp.n_pregnancy pregnancy_number,
                            pk_date_utils.date_send(i_lang, pp.dt_last_menstruation, i_prof) dt_last_menstruation,
                            pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                  pp.dt_init_preg_lmp,
                                                                  pp.dt_intervention,
                                                                  pp.num_gest_weeks) weeks_number,
                            pk_pregnancy_core.get_pregnancy_days(i_prof,
                                                                 pp.dt_init_preg_lmp,
                                                                 pp.dt_intervention,
                                                                 pp.num_gest_weeks) days_number,
                            l_label_weeks weeks_measure,
                            pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                         i_prof,
                                                                         (SELECT ppf.id_unit_measure
                                                                            FROM pat_pregn_fetus ppf
                                                                           WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                                                             AND ppf.id_unit_measure IS NOT NULL
                                                                             AND rownum = 1)) weight_measure,
                            nvl(pp.n_children, 1) n_children,
                            pk_pregnancy_core.get_abortion_type(pp.flg_status) flg_abortion_type,
                            CAST(MULTISET (SELECT ppf.flg_childbirth_type
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_varchar) flg_childbirth_type,
                            CAST(MULTISET
                                 (SELECT decode(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_unk, NULL, ppf.flg_status) flg_status
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_varchar) flg_child_status,
                            CAST(MULTISET (SELECT ppf.flg_gender
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_varchar) flg_gender,
                            CAST(MULTISET (SELECT ppf.weight
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_number) weight,
                            CAST(MULTISET (SELECT ppf.id_unit_measure
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_number) weight_um,
                            CAST(MULTISET (SELECT ppf.present_health
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_varchar) present_health,
                            CAST(MULTISET (SELECT ppf.flg_present_health
                                    FROM pat_pregn_fetus ppf
                                   WHERE ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                     AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                         instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                         ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                   ORDER BY ppf.fetus_number) AS table_varchar) flg_present_health,
                            pk_pregnancy_core.get_serialized_compl(i_lang,
                                                                   i_prof,
                                                                   pp.flg_complication,
                                                                   pp.id_pat_pregnancy) flg_complication,
                            pp.notes_complications,
                            pp.id_inst_intervention,
                            pp.flg_desc_intervention,
                            pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                    pp.id_inst_intervention,
                                                                    pp.flg_desc_intervention,
                                                                    pp.desc_intervention,
                                                                    'N') desc_intervention,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_intervention, i_prof) dt_intervention,
                            pp.dt_intervention dt_intervention_tstz,
                            pp.dt_init_pregnancy dt_init_pregnancy,
                            pp.flg_dt_interv_precision,
                            pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                  i_prof,
                                                                  pp.dt_intervention,
                                                                  pp.flg_dt_interv_precision) dt_intervention_chr,
                            pp.notes pregnancy_notes,
                            --
                            pp.flg_menses,
                            pp.cycle_duration,
                            pp.flg_use_constraceptives,
                            NULL type_description,
                            NULL type_description_field,
                            NULL type_ids,
                            NULL type_free_text,
                            pk_date_utils.date_send(i_lang, pp.dt_contrac_meth_end, i_prof) dt_contrac_meth_end,
                            pp.flg_dt_contrac_precision,
                            pk_date_utils.date_send(i_lang, pp.dt_pdel_lmp, i_prof) dt_pdel_lmp,
                            -- SISPRENATAL
                            nvl(pc.code_state, pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state)) code_state,
                            pc.code_year,
                            pc.code_number,
                            --
                            pk_pregnancy_core.get_pregnancy_weeks(i_prof, pp.dt_init_preg_exam, pp.dt_intervention, NULL) weeks_number_exam,
                            pk_pregnancy_core.get_pregnancy_days(i_prof, pp.dt_init_preg_exam, pp.dt_intervention, NULL) days_number_exam,
                            --
                            nvl2(pp.num_gest_weeks_us,
                                 pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                       pp.dt_init_pregnancy,
                                                                       pp.dt_intervention,
                                                                       NULL),
                                 NULL) weeks_number_us,
                            nvl2(pp.num_gest_weeks_us,
                                 pk_pregnancy_core.get_pregnancy_days(i_prof,
                                                                      pp.dt_init_pregnancy,
                                                                      pp.dt_intervention,
                                                                      NULL),
                                 NULL) days_number_us,
                            --
                            nvl(pk_date_utils.date_send(i_lang, pp.dt_pdel_correct, i_prof),
                                nvl2(pp.num_gest_weeks_us,
                                     pk_date_utils.date_send(i_lang,
                                                             pk_pregnancy_core.get_dt_pregnancy_end(i_lang,
                                                                                                    i_prof,
                                                                                                    pp.num_gest_weeks_us,
                                                                                                    NULL,
                                                                                                    pp.dt_init_pregnancy),
                                                             i_prof),
                                     NULL)) dt_pdel_correct,
                            pk_date_utils.date_send(i_lang, pp.dt_us_performed, i_prof) dt_us_performed,
                            nvl2(pp.dt_us_performed,
                                 pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                       pp.dt_init_pregnancy,
                                                                       pp.dt_us_performed,
                                                                       NULL),
                                 NULL) num_weeks_at_us,
                            nvl2(pp.dt_us_performed,
                                 pk_pregnancy_core.get_pregnancy_days(i_prof,
                                                                      pp.dt_init_pregnancy,
                                                                      pp.dt_us_performed,
                                                                      NULL),
                                 NULL) num_days_at_us,
                            --
                            pp.flg_del_onset,
                            pp.del_duration,
                            pp.flg_extraction,
                            pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION', pp.flg_extraction, i_lang) extraction_desc,
                            pp.flg_preg_out_type,
                            pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE', pp.flg_preg_out_type, i_lang) preg_out_type_desc,
                            pp.num_births,
                            pp.num_abortions,
                            pp.num_gestations,
                            pp.flg_gest_weeks,
                            pp.flg_gest_weeks_exam,
                            pp.flg_gest_weeks_us,
                            -- viewer fields
                            CASE
                                 WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                                  pp.id_pat_pregnancy
                                 ELSE
                                  pk_pregnancy_core.get_viewer_category(pp.id_pat_pregnancy)
                             END viewer_category,
                            CASE
                                 WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                                  l_label_pregn_num || ' ' || pp.n_pregnancy ||
                                  decode(pp.flg_type,
                                         pk_pregnancy_core.g_pat_pregn_type_r,
                                         chr(10) || '(' || l_domain_r || ')',
                                         NULL) || chr(13) || l_closed_by_system
                                 ELSE
                                  pk_sysdomain.get_domain(pk_pregnancy_core.g_domain_pregn_viewer,
                                                          pk_pregnancy_core.get_viewer_category(pp.id_pat_pregnancy),
                                                          i_lang)
                             END viewer_category_desc,
                            pp.id_professional viewer_id_prof,
                            pp.id_episode viewer_id_epis,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) viewer_date,
                            NULL rank
                    
                      FROM pat_pregnancy pp
                      LEFT JOIN pat_pregnancy_code pc
                        ON pp.id_pat_pregnancy = pc.id_pat_pregnancy
                     WHERE pp.id_patient = i_pat
                       AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_active
                     ORDER BY pp.n_pregnancy DESC);
        
            g_error := 'GET CURSOR O_DOC_AREA_VAL';
        
            SELECT t_doc_area_val_line(id_epis_documentation     => id_epis_documentation,
                                       PARENT                    => PARENT,
                                       id_documentation          => id_documentation,
                                       id_doc_component          => id_doc_component,
                                       id_doc_element_crit       => id_doc_element_crit,
                                       dt_reg                    => dt_reg,
                                       desc_doc_component        => desc_doc_component,
                                       desc_element              => desc_element,
                                       VALUE                     => VALUE,
                                       id_doc_area               => id_doc_area,
                                       rank_component            => rank_component,
                                       rank_element              => rank_element,
                                       desc_qualification        => desc_qualification,
                                       flg_current_episode       => flg_current_episode,
                                       id_epis_documentation_det => id_epis_documentation_det)
              BULK COLLECT
              INTO o_doc_area_val
              FROM (
                    
                    SELECT id_pat_pregnancy id_epis_documentation,
                            NULL PARENT,
                            0 id_documentation,
                            0 id_doc_component,
                            NULL id_doc_element_crit,
                            pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                            -- first title
                            pk_utils.to_bold(first_title) desc_doc_component,
                            -- remove the last characters since flash already shows them
                            substr(pregnancy_info, 1, length(pregnancy_info) - 2) desc_element,
                            NULL VALUE,
                            i_doc_area id_doc_area,
                            1 rank_component,
                            1 rank_element,
                            NULL desc_qualification,
                            NULL flg_current_episode,
                            NULL id_epis_documentation_det
                      FROM (SELECT pp.id_pat_pregnancy,
                                    pp.dt_pat_pregnancy_tstz,
                                    pp.first_title,
                                    -- Reported intervention date
                                    decode(pp.flg_type,
                                            pk_pregnancy_core.g_pat_pregn_type_r,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_dt_birth,
                                                                                 pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                                       i_prof,
                                                                                                                       pp.dt_intervention,
                                                                                                                       pp.flg_dt_interv_precision),
                                                                                 l_sep,
                                                                                 pp.first_title)) ||
                                    -- SISPRENATAL
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_sisprenantal,
                                                                          pk_pregnancy_core.get_pat_pregnancy_code(i_lang,
                                                                                                                   i_prof,
                                                                                                                   pp.id_pat_pregnancy,
                                                                                                                   NULL),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- LMP
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_dt_menstruation,
                                                                          pk_date_utils.dt_chr(i_lang,
                                                                                               dt_last_menstruation,
                                                                                               i_prof),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- Menses
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_menses,
                                                                          pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MENSES',
                                                                                                  pp.flg_menses,
                                                                                                  i_lang),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- Cycle duration
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_cycle,
                                                                          nvl2(pp.cycle_duration,
                                                                               pp.cycle_duration || ' ' || l_label_days,
                                                                               NULL),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- Contraceptive use
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_contracep,
                                                                          pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_USE_CONSTRACEPTIVES',
                                                                                                  pp.flg_use_constraceptives,
                                                                                                  i_lang),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    
                                    -- Contraceptive type
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_contracep_type,
                                                                          pk_pregnancy_core.get_contraception_type(i_lang,
                                                                                                                   i_prof,
                                                                                                                   pp.id_pat_pregnancy,
                                                                                                                   NULL),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- Last use of contraceptive
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_dt_contracep,
                                                                          pk_pregnancy_core.get_dt_contrac_end(i_lang,
                                                                                                               i_prof,
                                                                                                               pp.dt_contrac_meth_end,
                                                                                                               pp.flg_dt_contrac_precision),
                                                                          l_sep,
                                                                          pp.first_title) ||
                                    -- Gestational age by LMP / Gestational age
                                     decode(pp.flg_gest_weeks,
                                            pk_pregnancy_core.g_gest_weeks_unknown,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 decode(pp.flg_type,
                                                                                        pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                        l_label_gest_age,
                                                                                        l_label_gest_reported),
                                                                                 l_gest_weeks_u,
                                                                                 l_sep,
                                                                                 pp.first_title),
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 decode(pp.flg_type,
                                                                                        pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                        l_label_gest_age,
                                                                                        l_label_gest_reported),
                                                                                 pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                             i_prof,
                                                                                                                             pp.num_gest_weeks,
                                                                                                                             dt_init_preg_lmp,
                                                                                                                             pp.dt_intervention,
                                                                                                                             pp.flg_status),
                                                                                 l_sep,
                                                                                 pp.first_title)) ||
                                    -- EDD by LMP
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_edd_lmp,
                                                                          pk_date_utils.dt_chr(i_lang, pp.dt_pdel_lmp, i_prof),
                                                                          l_sep,
                                                                          '') ||
                                    -- Gestational age by examination
                                     decode(pp.flg_gest_weeks_exam,
                                            pk_pregnancy_core.g_gest_weeks_unknown,
                                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                       l_label_gest_exam,
                                                                                       l_gest_weeks_u,
                                                                                       l_sep,
                                                                                       pp.first_title,
                                                                                       break_exam),
                                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                       l_label_gest_exam,
                                                                                       nvl2(pp.num_gest_weeks_exam,
                                                                                            pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                        i_prof,
                                                                                                                                        pp.num_gest_weeks_exam,
                                                                                                                                        pp.dt_init_preg_exam,
                                                                                                                                        pp.dt_intervention,
                                                                                                                                        pp.flg_status),
                                                                                            NULL),
                                                                                       l_sep,
                                                                                       pp.first_title,
                                                                                       break_exam)) ||
                                    -- Gestational age by US
                                     decode(pp.flg_gest_weeks_us,
                                            pk_pregnancy_core.g_gest_weeks_unknown,
                                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                       l_label_gest_us,
                                                                                       l_gest_weeks_u,
                                                                                       l_sep,
                                                                                       pp.first_title,
                                                                                       break_us),
                                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                       l_label_gest_us,
                                                                                       nvl2(pp.num_gest_weeks_us,
                                                                                            pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                        i_prof,
                                                                                                                                        pp.num_gest_weeks_us,
                                                                                                                                        pp.dt_init_pregnancy,
                                                                                                                                        pp.dt_intervention,
                                                                                                                                        pp.flg_status),
                                                                                            NULL),
                                                                                       l_sep,
                                                                                       pp.first_title,
                                                                                       break_us)) ||
                                    -- EDD by US
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_edd_us,
                                                                          pk_date_utils.dt_chr(i_lang,
                                                                                               pp.dt_pdel_correct,
                                                                                               i_prof),
                                                                          l_sep,
                                                                          '') ||
                                    -- US performed in
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_us_performed,
                                                                          pk_date_utils.dt_chr(i_lang,
                                                                                               pp.dt_us_performed,
                                                                                               i_prof),
                                                                          l_sep,
                                                                          '') ||
                                    -- US performed at gestational age
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_us_at_gest_age,
                                                                          nvl2(pp.dt_us_performed,
                                                                               pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                           i_prof,
                                                                                                                           NULL,
                                                                                                                           pp.dt_init_pregnancy,
                                                                                                                           pp.dt_us_performed,
                                                                                                                           pp.flg_status),
                                                                               NULL),
                                                                          l_sep,
                                                                          '') ||
                                    -- Number of fetuses
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_fetus_num,
                                                                          pp.n_children,
                                                                          l_sep,
                                                                          '') ||
                                    -- Pregnancy outcome
                                     decode(pp.flg_type,
                                            pk_pregnancy_core.g_pat_pregn_type_r,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_outcome,
                                                                                 pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                          pp.flg_status,
                                                                                                                          pp.id_pat_pregnancy,
                                                                                                                          NULL,
                                                                                                                          pk_pregnancy_core.g_type_summ),
                                                                                 l_sep,
                                                                                 '')) ||
                                    -- Procedure place
                                     decode(pp.flg_type,
                                            pk_pregnancy_core.g_pat_pregn_type_r,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_interv,
                                                                                 pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                         pp.id_inst_intervention,
                                                                                                                         pp.flg_desc_intervention,
                                                                                                                         pp.desc_intervention),
                                                                                 l_sep,
                                                                                 '')) ||
                                    
                                    -- Labour onset
                                     pk_pregnancy_core.get_formatted_text(NULL,
                                                                          l_label_labour_onset,
                                                                          pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_DEL_ONSET',
                                                                                                  pp.flg_del_onset,
                                                                                                  i_lang),
                                                                          l_sep,
                                                                          '') ||
                                    
                                    -- Labour duration                                           
                                     pk_pregnancy_core.get_formatted_text(NULL,
                                                                          l_label_labour_duration,
                                                                          CASE
                                                                              WHEN regexp_like(pp.del_duration, '\w\w:\w\w') THEN
                                                                               pp.del_duration || 'h'
                                                                              WHEN regexp_like(pp.del_duration, '\w\w:\w') THEN
                                                                               regexp_replace(pp.del_duration, '\w\w:\w', pp.del_duration || '0h')
                                                                              WHEN regexp_like(pp.del_duration, '\w:\w\w') THEN
                                                                               regexp_replace(pp.del_duration, '\w:\w\w', '0' || pp.del_duration || 'h')
                                                                              WHEN regexp_like(pp.del_duration, '\w:\w') THEN
                                                                               regexp_replace(pp.del_duration, '\w:\w', '0' || pp.del_duration || '0h')
                                                                          END,
                                                                          l_sep,
                                                                          '') ||
                                    
                                    -- Complications
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_compl,
                                                                                pk_pregnancy_core.get_preg_complications(i_lang,
                                                                                                                         i_prof,
                                                                                                                         pp.flg_complication,
                                                                                                                         pp.notes_complications,
                                                                                                                         pp.id_pat_pregnancy,
                                                                                                                         NULL),
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                break_compl) ||
                                    --Extraction /expulsion
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_extr,
                                                                                pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION',
                                                                                                        pp.flg_extraction,
                                                                                                        i_lang),
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                '') ||
                                    -- Pregnancy outcome
                                     decode(pp.flg_extraction,
                                            pk_pregnancy_core.g_pat_pregn_extract_y,
                                            '',
                                            decode(pp.flg_type,
                                                   pk_pregnancy_core.g_pat_pregn_type_c,
                                                   pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                              l_label_outcome,
                                                                                              pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                                       pp.flg_status,
                                                                                                                                       pp.id_pat_pregnancy,
                                                                                                                                       NULL,
                                                                                                                                       pk_pregnancy_core.g_type_summ),
                                                                                              l_sep,
                                                                                              pp.first_title,
                                                                                              break_out))) ||
                                    --pregnacy outcome type (when expulsion)
                                     decode(pp.flg_extraction,
                                            pk_pregnancy_core.g_pat_pregn_extract_y,
                                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                       l_label_outcome,
                                                                                       pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE',
                                                                                                               pp.flg_preg_out_type,
                                                                                                               i_lang),
                                                                                       l_sep,
                                                                                       pp.first_title,
                                                                                       break_out)) ||
                                    -- Procedure place
                                     decode(pp.flg_type,
                                            pk_pregnancy_core.g_pat_pregn_type_c,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_interv,
                                                                                 pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                         pp.id_inst_intervention,
                                                                                                                         pp.flg_desc_intervention,
                                                                                                                         pp.desc_intervention),
                                                                                 l_sep,
                                                                                 '')) ||
                                    -- Intervention date
                                     decode(pp.flg_type,
                                            pk_pregnancy_core.g_pat_pregn_type_c,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_dt_birth,
                                                                                 pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                                       i_prof,
                                                                                                                       pp.dt_intervention,
                                                                                                                       pp.flg_dt_interv_precision),
                                                                                 l_sep,
                                                                                 pp.first_title)) ||
                                    
                                    -- pregnancy summary    
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_num_birth,
                                                                                pp.num_births,
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                '') ||
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_num_ab,
                                                                                pp.num_abortions,
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                '') ||
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_num_gest,
                                                                                pp.num_gestations,
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                '') ||
                                    -- Notes
                                     pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                l_label_notes,
                                                                                pp.notes,
                                                                                l_sep,
                                                                                pp.first_title,
                                                                                break_notes) pregnancy_info
                               FROM (SELECT id_pat_pregnancy,
                                            flg_type,
                                            flg_status,
                                            num_gest_weeks,
                                            dt_pat_pregnancy_tstz,
                                            dt_last_menstruation,
                                            flg_menses,
                                            cycle_duration,
                                            flg_use_constraceptives,
                                            dt_contrac_meth_end,
                                            flg_dt_contrac_precision,
                                            dt_intervention,
                                            dt_pdel_lmp,
                                            num_gest_weeks_exam,
                                            dt_init_preg_exam,
                                            dt_init_preg_lmp,
                                            num_gest_weeks_us,
                                            dt_init_pregnancy,
                                            dt_pdel_correct,
                                            dt_us_performed,
                                            pregn.flg_del_onset,
                                            pregn.del_duration,
                                            n_children,
                                            flg_complication,
                                            notes_complications,
                                            notes,
                                            flg_dt_interv_precision,
                                            id_inst_intervention,
                                            flg_desc_intervention,
                                            desc_intervention,
                                            pregn.flg_extraction,
                                            pregn.flg_preg_out_type,
                                            pregn.num_births,
                                            pregn.num_abortions,
                                            pregn.num_gestations,
                                            pregn.flg_gest_weeks,
                                            pregn.flg_gest_weeks_exam,
                                            pregn.flg_gest_weeks_us,
                                            pk_pregnancy_core.get_summ_page_first_title(i_lang,
                                                                                        i_prof,
                                                                                        id_pat_pregnancy,
                                                                                        NULL,
                                                                                        flg_type) first_title,
                                            pk_pregnancy_core.check_break_summ_pg_exam(i_lang,
                                                                                       i_prof,
                                                                                       flg_type,
                                                                                       num_gest_weeks_exam) break_exam,
                                            pk_pregnancy_core.check_break_summ_pg_us(i_lang,
                                                                                     i_prof,
                                                                                     flg_type,
                                                                                     num_gest_weeks_us,
                                                                                     dt_pdel_correct,
                                                                                     dt_us_performed,
                                                                                     n_children) break_us,
                                            pk_pregnancy_core.check_break_summ_pg_compl(i_lang,
                                                                                        i_prof,
                                                                                        flg_type,
                                                                                        id_pat_pregnancy,
                                                                                        NULL,
                                                                                        flg_complication,
                                                                                        notes_complications) break_compl,
                                            pk_pregnancy_core.check_break_summ_pg_out(i_lang,
                                                                                      i_prof,
                                                                                      flg_type,
                                                                                      id_pat_pregnancy,
                                                                                      flg_status,
                                                                                      dt_intervention,
                                                                                      id_inst_intervention,
                                                                                      flg_desc_intervention,
                                                                                      desc_intervention) break_out,
                                            pk_pregnancy_core.check_break_summ_pg_notes(i_lang, i_prof, flg_type, notes) break_notes
                                       FROM pat_pregnancy pregn
                                      WHERE id_patient = i_pat
                                        AND flg_status <> pk_pregnancy_core.g_pat_pregn_active) pp)
                    
                    UNION ALL
                    
                    SELECT id_pat_pregnancy id_epis_documentation,
                            NULL PARENT,
                            id_pat_pregn_fetus id_documentation,
                            id_pat_pregn_fetus id_doc_component,
                            NULL id_doc_element_crit,
                            pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                            -- TITULO
                            '<br>' || pk_utils.to_bold(decode(flg_preg_out_type,
                                                              pk_pregnancy_core.g_pat_pregn_type_ab,
                                                              l_title_fetus_ab,
                                                              l_title_fetus)) || ' ' || fetus_number desc_doc_component,
                            -- remove the last characters since flash already shows them
                            substr(fetus_info, 1, length(fetus_info) - 2) desc_element,
                            NULL VALUE,
                            i_doc_area id_doc_area,
                            1 rank_component,
                            1 rank_element,
                            NULL desc_qualification,
                            NULL flg_current_episode,
                            NULL id_epis_documentation_det
                      FROM (SELECT pp.id_pat_pregnancy,
                                    ppf.id_pat_pregn_fetus,
                                    pp.dt_pat_pregnancy_tstz,
                                    ppf.fetus_number,
                                    '<br>' ||
                                    -- estado
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          decode(flg_preg_out_type,
                                                                                 pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                                 l_label_fetus_ab_status,
                                                                                 l_label_fetus_status),
                                                                          pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_STATUS',
                                                                                                  ppf.flg_status,
                                                                                                  i_lang),
                                                                          l_sep,
                                                                          '') ||
                                    --tipo de parto
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_birth_type,
                                                                          pk_sysdomain.get_domain_no_avail('PAT_PREGN_FETUS.FLG_CHILDBIRTH_TYPE',
                                                                                                           ppf.flg_childbirth_type,
                                                                                                           i_lang),
                                                                          l_sep,
                                                                          '') ||
                                    -- sexo
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          l_label_fetus_gender,
                                                                          pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_GENDER',
                                                                                                  ppf.flg_gender,
                                                                                                  i_lang),
                                                                          l_sep,
                                                                          '') ||
                                    -- peso
                                     pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                          decode(flg_preg_out_type,
                                                                                 pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                                 l_label_fetus_weight,
                                                                                 l_label_weight),
                                                                          decode(ppf.weight,
                                                                                 NULL,
                                                                                 NULL,
                                                                                 ppf.weight || ' ' ||
                                                                                 pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                                                                              i_prof,
                                                                                                                              ppf.id_unit_measure)),
                                                                          l_sep,
                                                                          '') ||
                                    -- present health 
                                     decode(l_config_val,
                                            pk_alert_constant.g_no,
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_health,
                                                                                 ppf.present_health,
                                                                                 l_sep,
                                                                                 ''),
                                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                 l_label_flg_health,
                                                                                 pk_sysdomain.get_domain('PAT_PREGN_FETUS.CURRENT_STATUS',
                                                                                                         ppf.flg_present_health,
                                                                                                         i_lang),
                                                                                 l_sep,
                                                                                 '')) fetus_info,
                                    pp.flg_preg_out_type
                               FROM pat_pregnancy pp, pat_pregn_fetus ppf
                              WHERE pp.id_patient = i_pat
                                AND ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                    instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                                    ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                                AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_active)
                     ORDER BY id_epis_documentation, id_doc_component);
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_obs_adv
        THEN
            l_desc           := get_adv_obs_component(i_lang, i_prof, i_pat);
            l_weight_measure := pk_pregnancy_core.get_preg_summ_unit_measure(i_lang, i_prof, NULL);
            l_weight_id      := pk_pregnancy_core.get_preg_summ_unit_measure_id(i_lang, i_prof);
        
            g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        
            SELECT t_doc_area_register_line(id_epis_documentation    => id_epis_documentation,
                                            PARENT                   => PARENT,
                                            id_doc_template          => id_doc_template,
                                            dt_creation              => dt_creation,
                                            dt_register              => dt_register,
                                            dt_pat_pregnancy_tstz    => dt_pat_pregnancy_tstz,
                                            id_professional          => id_professional,
                                            nick_name                => nick_name,
                                            desc_speciality          => desc_speciality,
                                            id_doc_area              => id_doc_area,
                                            flg_status               => flg_status,
                                            flg_preg_status          => flg_preg_status,
                                            desc_status              => desc_status,
                                            notes                    => notes,
                                            dt_last_update           => dt_last_update,
                                            flg_type_register        => flg_type_register,
                                            flg_type                 => flg_type,
                                            n_pregnancy              => n_pregnancy,
                                            pregnancy_number         => pregnancy_number,
                                            dt_last_menstruation     => dt_last_menstruation,
                                            weeks_number             => weeks_number,
                                            days_number              => days_number,
                                            weeks_measure            => weeks_measure,
                                            weight_measure           => weight_measure,
                                            n_children               => n_children,
                                            flg_abortion_type        => flg_abortion_type,
                                            flg_childbirth_type      => flg_childbirth_type,
                                            flg_child_status         => flg_child_status,
                                            flg_gender               => flg_gender,
                                            weight                   => weight,
                                            weight_um                => weight_um,
                                            present_health           => present_health,
                                            flg_present_health       => flg_present_health,
                                            flg_complication         => flg_complication,
                                            notes_complications      => notes_complications,
                                            id_inst_intervention     => id_inst_intervention,
                                            flg_desc_intervention    => flg_desc_intervention,
                                            desc_intervention        => desc_intervention,
                                            dt_intervention          => dt_intervention,
                                            dt_intervention_tstz     => dt_intervention_tstz,
                                            dt_init_pregnancy        => dt_init_pregnancy,
                                            flg_dt_interv_precision  => flg_dt_interv_precision,
                                            dt_intervention_chr      => dt_intervention_chr,
                                            pregnancy_notes          => pregnancy_notes,
                                            flg_menses               => flg_menses,
                                            cycle_duration           => cycle_duration,
                                            flg_use_constraceptives  => flg_use_constraceptives,
                                            type_description         => type_description,
                                            type_description_field   => type_description_field,
                                            type_ids                 => type_ids,
                                            type_free_text           => type_free_text,
                                            dt_contrac_meth_end      => dt_contrac_meth_end,
                                            flg_dt_contrac_precision => flg_dt_contrac_precision,
                                            dt_pdel_lmp              => dt_pdel_lmp,
                                            code_state               => code_state,
                                            code_year                => code_year,
                                            code_number              => code_number,
                                            weeks_number_exam        => weeks_number_exam,
                                            days_number_exam         => days_number_exam,
                                            weeks_number_us          => weeks_number_us,
                                            days_number_us           => days_number_us,
                                            dt_pdel_correct          => dt_pdel_correct,
                                            dt_us_performed          => dt_us_performed,
                                            num_weeks_at_us          => num_weeks_at_us,
                                            num_days_at_us           => num_days_at_us,
                                            flg_del_onset            => flg_del_onset,
                                            del_duration             => del_duration,
                                            flg_extraction           => flg_extraction,
                                            extraction_desc          => extraction_desc,
                                            flg_preg_out_type        => flg_preg_out_type,
                                            preg_out_type_desc       => preg_out_type_desc,
                                            num_births               => num_births,
                                            num_abortions            => num_abortions,
                                            num_gestations           => num_gestations,
                                            flg_gest_weeks           => flg_gest_weeks,
                                            flg_gest_weeks_exam      => flg_gest_weeks_exam,
                                            flg_gest_weeks_us        => flg_gest_weeks_us,
                                            viewer_category          => viewer_category,
                                            viewer_category_desc     => viewer_category_desc,
                                            viewer_id_prof           => viewer_id_prof,
                                            viewer_id_epis           => viewer_id_epis,
                                            viewer_date              => viewer_date,
                                            rank                     => rank)
              BULK COLLECT
              INTO o_doc_area_register
              FROM (
                    
                    SELECT 0 id_epis_documentation,
                            NULL PARENT,
                            NULL id_doc_template,
                            NULL dt_creation,
                            NULL dt_register,
                            NULL dt_pat_pregnancy_tstz,
                            NULL id_professional,
                            NULL nick_name,
                            NULL desc_speciality,
                            i_doc_area id_doc_area,
                            pk_pregnancy_core.g_pat_pregn_active flg_status,
                            NULL flg_preg_status,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS',
                                                    pk_pregnancy_core.g_pat_pregn_active,
                                                    i_lang) desc_status,
                            NULL notes,
                            NULL dt_last_update,
                            pk_pregnancy_core.g_free_text flg_type_register,
                            NULL flg_type,
                            NULL n_pregnancy,
                            pk_pregnancy_core.g_max_pregn pregnancy_number,
                            NULL dt_last_menstruation,
                            NULL weeks_number,
                            NULL days_number,
                            NULL weeks_measure,
                            NULL weight_measure,
                            NULL n_children,
                            NULL flg_abortion_type,
                            NULL flg_childbirth_type,
                            NULL flg_child_status,
                            NULL flg_gender,
                            NULL weight,
                            NULL weight_um,
                            NULL present_health,
                            NULL flg_present_health,
                            NULL flg_complication,
                            NULL notes_complications,
                            NULL id_inst_intervention,
                            NULL flg_desc_intervention,
                            NULL desc_intervention,
                            NULL dt_intervention,
                            NULL dt_intervention_tstz,
                            NULL dt_init_pregnancy,
                            NULL flg_dt_interv_precision,
                            NULL dt_intervention_chr,
                            NULL pregnancy_notes,
                            NULL flg_menses,
                            NULL cycle_duration,
                            NULL flg_use_constraceptives,
                            NULL type_description,
                            NULL type_description_field,
                            NULL type_ids,
                            NULL type_free_text,
                            NULL dt_contrac_meth_end,
                            NULL flg_dt_contrac_precision,
                            NULL dt_pdel_lmp,
                            NULL code_state,
                            NULL code_year,
                            NULL code_number,
                            NULL weeks_number_exam,
                            NULL days_number_exam,
                            NULL weeks_number_us,
                            NULL days_number_us,
                            NULL dt_pdel_correct,
                            NULL dt_us_performed,
                            NULL num_weeks_at_us,
                            NULL num_days_at_us,
                            NULL flg_del_onset,
                            NULL del_duration,
                            NULL flg_extraction,
                            NULL extraction_desc,
                            NULL flg_preg_out_type,
                            NULL preg_out_type_desc,
                            NULL num_births,
                            NULL num_abortions,
                            NULL num_gestations,
                            NULL flg_gest_weeks,
                            NULL flg_gest_weeks_exam,
                            NULL flg_gest_weeks_us,
                            -- viewer fields
                            NULL viewer_category,
                            NULL viewer_category_desc,
                            NULL viewer_id_prof,
                            NULL viewer_id_epis,
                            NULL viewer_date,
                            NULL rank
                      FROM dual
                     WHERE g_flg_count IS NOT NULL
                    UNION ALL
                    SELECT pp.id_pat_pregnancy id_epis_documentation,
                            NULL PARENT,
                            NULL id_doc_template,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_creation,
                            pk_date_utils.date_char_tsz(i_lang,
                                                        pp.dt_pat_pregnancy_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) dt_register,
                            pp.dt_pat_pregnancy_tstz dt_pat_pregnancy_tstz,
                            pp.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional) nick_name,
                            pk_prof_utils.get_spec_signature(i_lang,
                                                             i_prof,
                                                             pp.id_professional,
                                                             pp.dt_pat_pregnancy_tstz,
                                                             pp.id_episode) desc_speciality,
                            i_doc_area id_doc_area,
                            pk_pregnancy_core.g_pat_pregn_active flg_status,
                            pp.flg_status flg_preg_status,
                            pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pp.flg_status, i_lang) desc_status,
                            NULL notes,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                            pk_pregnancy_core.g_free_text flg_type_register,
                            nvl(pp.flg_type, pk_pregnancy_core.g_pat_pregn_type_c) flg_type,
                            l_label_pregn_num || ' ' || pp.n_pregnancy n_pregnancy,
                            pp.n_pregnancy pregnancy_number,
                            NULL dt_last_menstruation,
                            NULL weeks_number,
                            NULL days_number,
                            NULL weeks_measure,
                            NULL weight_measure,
                            NULL n_children,
                            NULL flg_abortion_type,
                            NULL flg_childbirth_type,
                            NULL flg_child_status,
                            NULL flg_gender,
                            NULL weight,
                            NULL weight_um,
                            NULL present_health,
                            NULL flg_present_health,
                            NULL flg_complication,
                            NULL notes_complications,
                            NULL id_inst_intervention,
                            NULL flg_desc_intervention,
                            NULL desc_intervention,
                            NULL dt_intervention,
                            pp.dt_intervention dt_intervention_tstz,
                            pp.dt_init_pregnancy dt_init_pregnancy,
                            NULL flg_dt_interv_precision,
                            NULL dt_intervention_chr,
                            NULL pregnancy_notes,
                            NULL flg_menses,
                            NULL cycle_duration,
                            NULL flg_use_constraceptives,
                            NULL type_description,
                            NULL type_description_field,
                            NULL type_ids,
                            NULL type_free_text,
                            NULL dt_contrac_meth_end,
                            NULL flg_dt_contrac_precision,
                            NULL dt_pdel_lmp,
                            NULL code_state,
                            NULL code_year,
                            NULL code_number,
                            NULL weeks_number_exam,
                            NULL days_number_exam,
                            NULL weeks_number_us,
                            NULL days_number_us,
                            NULL dt_pdel_correct,
                            NULL dt_us_performed,
                            NULL num_weeks_at_us,
                            NULL num_days_at_us,
                            NULL flg_del_onset,
                            NULL del_duration,
                            NULL flg_extraction,
                            NULL extraction_desc,
                            NULL flg_preg_out_type,
                            NULL preg_out_type_desc,
                            NULL num_births,
                            NULL num_abortions,
                            NULL num_gestations,
                            NULL flg_gest_weeks,
                            NULL flg_gest_weeks_exam,
                            NULL flg_gest_weeks_us,
                            -- viewer fields
                            pk_pregnancy_core.get_viewer_category(pp.id_pat_pregnancy) viewer_category,
                            pk_sysdomain.get_domain(pk_pregnancy_core.g_domain_pregn_viewer,
                                                    pk_pregnancy_core.get_viewer_category(pp.id_pat_pregnancy),
                                                    i_lang) viewer_category_desc,
                            pp.id_professional viewer_id_prof,
                            pp.id_episode viewer_id_epis,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) viewer_date,
                            NULL rank
                      FROM pat_pregnancy pp
                     WHERE pp.id_patient = i_pat
                       AND (pp.flg_status NOT IN (pk_pregnancy_core.g_pat_pregn_active,
                                                  pk_pregnancy_core.g_pat_pregn_cancel,
                                                  pk_pregnancy_core.g_pat_pregn_past,
                                                  pk_pregnancy_core.g_pat_pregn_no,
                                                  pk_pregnancy_core.g_pat_pregn_auto_close) OR
                           ((nvl(pp.flg_complication, pk_pregnancy_core.g_flg_no_prob) <>
                           pk_pregnancy_core.g_flg_no_prob OR pp.notes_complications IS NOT NULL) AND
                           pp.flg_status = pk_pregnancy_core.g_pat_pregn_past))
                     ORDER BY pregnancy_number DESC);
        
            g_error := 'GET CURSOR O_DOC_AREA_VAL';
        
            SELECT t_doc_area_val_line(id_epis_documentation     => id_epis_documentation,
                                       PARENT                    => PARENT,
                                       id_documentation          => id_documentation,
                                       id_doc_component          => id_doc_component,
                                       id_doc_element_crit       => id_doc_element_crit,
                                       dt_reg                    => dt_reg,
                                       desc_doc_component        => desc_doc_component,
                                       desc_element              => desc_element,
                                       VALUE                     => VALUE,
                                       id_doc_area               => id_doc_area,
                                       rank_component            => rank_component,
                                       rank_element              => rank_element,
                                       desc_qualification        => desc_qualification,
                                       flg_current_episode       => flg_current_episode,
                                       id_epis_documentation_det => id_epis_documentation_det)
              BULK COLLECT
              INTO o_doc_area_val
              FROM (SELECT 0    id_epis_documentation,
                           NULL PARENT,
                           NULL id_documentation,
                           NULL id_doc_component,
                           NULL id_doc_element_crit,
                           NULL dt_reg,
                           -- peso > 2500
                           l_desc desc_doc_component,
                           -- remove the last characters since flash already shows them
                           substr(adverse_info, 1, length(adverse_info) - 2) desc_element,
                           NULL VALUE,
                           i_doc_area id_doc_area,
                           1 rank_component,
                           1 rank_element,
                           NULL desc_qualification,
                           NULL flg_current_episode,
                           NULL id_epis_documentation_det
                      FROM (SELECT decode(g_flg_count,
                                           pk_pregnancy_core.g_flg_weight_l,
                                           g_count_weight_l || l_sep || chr(10),
                                           pk_pregnancy_core.g_flg_weight_u,
                                           g_count_weight_u || l_sep || chr(10),
                                           pk_pregnancy_core.g_flg_dead_fetus,
                                           g_count_dead_fetus || l_sep || chr(10),
                                           pk_pregnancy_core.g_flg_abortion,
                                           g_count_abortion || l_sep || chr(10),
                                           pk_pregnancy_core.g_flg_pre_labor,
                                           g_count_pre_labor || l_sep || chr(10),
                                           pk_pregnancy_core.g_flg_cesarean,
                                           g_count_cesarean || l_sep || chr(10)) ||
                                   -- peso > 4000
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         (l_label_weight_sup || ' &gt; ' ||
                                                                         pk_unit_measure.get_unit_mea_conversion(l_upper_limit,
                                                                                                                  pk_pregnancy_core.g_adverse_weight_um_id,
                                                                                                                  l_weight_id) || ' ' ||
                                                                         l_weight_measure),
                                                                         decode(g_flg_count,
                                                                                pk_pregnancy_core.g_flg_weight_u,
                                                                                NULL,
                                                                                g_count_weight_u),
                                                                         l_sep,
                                                                         '') ||
                                   -- morte fetal ou neo natal
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_fetus_dead,
                                                                         decode(g_flg_count,
                                                                                pk_pregnancy_core.g_flg_dead_fetus,
                                                                                NULL,
                                                                                g_count_dead_fetus),
                                                                         l_sep,
                                                                         '') ||
                                   -- abortos
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_num_abort,
                                                                         decode(g_flg_count,
                                                                                pk_pregnancy_core.g_flg_abortion,
                                                                                NULL,
                                                                                g_count_abortion),
                                                                         l_sep,
                                                                         '') ||
                                   -- partos pré-termo
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_pre_term,
                                                                         decode(g_flg_count,
                                                                                pk_pregnancy_core.g_flg_pre_labor,
                                                                                NULL,
                                                                                g_count_pre_labor),
                                                                         l_sep,
                                                                         '') ||
                                   -- cesarianas
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_c_section,
                                                                         decode(g_flg_count,
                                                                                pk_pregnancy_core.g_flg_cesarean,
                                                                                NULL,
                                                                                g_count_cesarean),
                                                                         l_sep,
                                                                         '') adverse_info
                              FROM dual
                             WHERE g_flg_count IS NOT NULL)
                    UNION ALL
                    SELECT id_pat_pregnancy id_epis_documentation,
                           NULL PARENT,
                           0 id_documentation,
                           0 id_doc_component,
                           NULL id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                           -- first title
                           pk_utils.to_bold(first_title) desc_doc_component,
                           -- remove the last characters since flash already shows them
                           substr(pregnancy_info, 1, length(pregnancy_info) - 2) desc_element,
                           NULL VALUE,
                           i_doc_area id_doc_area,
                           1 rank_component,
                           1 rank_element,
                           NULL desc_qualification,
                           NULL flg_current_episode,
                           NULL id_epis_documentation_det
                      FROM (SELECT pp.id_pat_pregnancy,
                                   pp.dt_pat_pregnancy_tstz,
                                   pp.first_title,
                                   -- Reported intervention date
                                   decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_r,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_dt_birth,
                                                                                pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                                      i_prof,
                                                                                                                      pp.dt_intervention,
                                                                                                                      pp.flg_dt_interv_precision),
                                                                                l_sep,
                                                                                pp.first_title)) ||
                                   -- SISPRENATAL
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_sisprenantal,
                                                                         pk_pregnancy_core.get_pat_pregnancy_code(i_lang,
                                                                                                                  i_prof,
                                                                                                                  pp.id_pat_pregnancy,
                                                                                                                  NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- LMP
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_dt_menstruation,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              dt_last_menstruation,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Menses
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_menses,
                                                                         pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MENSES',
                                                                                                 pp.flg_menses,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Cycle duration
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_cycle,
                                                                         nvl2(pp.cycle_duration,
                                                                              pp.cycle_duration || ' ' || l_label_days,
                                                                              NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Contraceptive use
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_contracep,
                                                                         pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_USE_CONSTRACEPTIVES',
                                                                                                 pp.flg_use_constraceptives,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   
                                   -- Contraceptive type
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_contracep_type,
                                                                         pk_pregnancy_core.get_contraception_type(i_lang,
                                                                                                                  i_prof,
                                                                                                                  pp.id_pat_pregnancy,
                                                                                                                  NULL),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Last use of contraceptive
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_dt_contracep,
                                                                         pk_pregnancy_core.get_dt_contrac_end(i_lang,
                                                                                                              i_prof,
                                                                                                              pp.dt_contrac_meth_end,
                                                                                                              pp.flg_dt_contrac_precision),
                                                                         l_sep,
                                                                         pp.first_title) ||
                                   -- Gestational age by LMP / Gestational age
                                    decode(pp.flg_gest_weeks,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                decode(pp.flg_type,
                                                                                       pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                       l_label_gest_age,
                                                                                       l_label_gest_reported),
                                                                                l_gest_weeks_u,
                                                                                l_sep,
                                                                                pp.first_title),
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                decode(pp.flg_type,
                                                                                       pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                       l_label_gest_age,
                                                                                       l_label_gest_reported),
                                                                                pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                            i_prof,
                                                                                                                            pp.num_gest_weeks,
                                                                                                                            dt_init_preg_lmp,
                                                                                                                            pp.dt_intervention,
                                                                                                                            pp.flg_status),
                                                                                l_sep,
                                                                                pp.first_title)) ||
                                   -- EDD by LMP
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_edd_lmp,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_pdel_lmp,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- Gestational age by examination
                                    decode(pp.flg_gest_weeks_exam,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_exam,
                                                                                      l_gest_weeks_u,
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_exam),
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_exam,
                                                                                      nvl2(pp.num_gest_weeks_exam,
                                                                                           pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                       i_prof,
                                                                                                                                       pp.num_gest_weeks_exam,
                                                                                                                                       pp.dt_init_preg_exam,
                                                                                                                                       pp.dt_intervention,
                                                                                                                                       pp.flg_status),
                                                                                           NULL),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_exam)) ||
                                   -- Gestational age by US
                                    decode(pp.flg_gest_weeks_us,
                                           pk_pregnancy_core.g_gest_weeks_unknown,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_us,
                                                                                      l_gest_weeks_u,
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_us),
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_gest_us,
                                                                                      nvl2(pp.num_gest_weeks_us,
                                                                                           pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                       i_prof,
                                                                                                                                       pp.num_gest_weeks_us,
                                                                                                                                       pp.dt_init_pregnancy,
                                                                                                                                       pp.dt_intervention,
                                                                                                                                       pp.flg_status),
                                                                                           NULL),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_us)) ||
                                   -- EDD by US
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_edd_us,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_pdel_correct,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- US performed in
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_us_performed,
                                                                         pk_date_utils.dt_chr(i_lang,
                                                                                              pp.dt_us_performed,
                                                                                              i_prof),
                                                                         l_sep,
                                                                         '') ||
                                   -- US performed at gestational age
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_us_at_gest_age,
                                                                         nvl2(pp.dt_us_performed,
                                                                              pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                          i_prof,
                                                                                                                          NULL,
                                                                                                                          pp.dt_init_pregnancy,
                                                                                                                          pp.dt_us_performed,
                                                                                                                          pp.flg_status),
                                                                              NULL),
                                                                         l_sep,
                                                                         '') ||
                                   -- Number of fetuses
                                    pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                         l_label_fetus_num,
                                                                         pp.n_children,
                                                                         l_sep,
                                                                         '') ||
                                   -- Pregnancy outcome
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_r,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_outcome,
                                                                                pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                         pp.flg_status,
                                                                                                                         pp.id_pat_pregnancy,
                                                                                                                         NULL,
                                                                                                                         pk_pregnancy_core.g_type_summ),
                                                                                l_sep,
                                                                                '')) ||
                                   -- Procedure place
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_r,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_interv,
                                                                                pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                        pp.id_inst_intervention,
                                                                                                                        pp.flg_desc_intervention,
                                                                                                                        pp.desc_intervention),
                                                                                l_sep,
                                                                                '')) ||
                                   -- Complications
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_compl,
                                                                               pk_pregnancy_core.get_preg_complications(i_lang,
                                                                                                                        i_prof,
                                                                                                                        pp.flg_complication,
                                                                                                                        pp.notes_complications,
                                                                                                                        pp.id_pat_pregnancy,
                                                                                                                        NULL),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_compl) ||
                                   --Extraction /expulsion
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_extr,
                                                                               pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION',
                                                                                                       pp.flg_extraction,
                                                                                                       i_lang),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                   -- Pregnancy outcome
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_c,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_outcome,
                                                                                      pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                               pp.flg_status,
                                                                                                                               pp.id_pat_pregnancy,
                                                                                                                               NULL,
                                                                                                                               pk_pregnancy_core.g_type_summ),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_out)) ||
                                   --pregnacy outcome type (when expulsion)
                                    decode(pp.flg_extraction,
                                           pk_pregnancy_core.g_pat_pregn_extract_y,
                                           pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                                      l_label_outcome,
                                                                                      pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE',
                                                                                                              pp.flg_preg_out_type,
                                                                                                              i_lang),
                                                                                      l_sep,
                                                                                      pp.first_title,
                                                                                      break_out)) ||
                                   -- Procedure place
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_c,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_interv,
                                                                                pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                        pp.id_inst_intervention,
                                                                                                                        pp.flg_desc_intervention,
                                                                                                                        pp.desc_intervention),
                                                                                l_sep,
                                                                                '')) ||
                                   -- Intervention date
                                    decode(pp.flg_type,
                                           pk_pregnancy_core.g_pat_pregn_type_c,
                                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                                l_label_dt_birth,
                                                                                pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                                      i_prof,
                                                                                                                      pp.dt_intervention,
                                                                                                                      pp.flg_dt_interv_precision),
                                                                                l_sep,
                                                                                pp.first_title)) ||
                                   -- pregnancy summary    
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_birth,
                                                                               pp.num_births,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_ab,
                                                                               pp.num_abortions,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_num_gest,
                                                                               pp.num_gestations,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               '') ||
                                   -- Notes
                                    pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                               l_label_notes,
                                                                               pp.notes,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_notes) pregnancy_info
                              FROM (SELECT id_pat_pregnancy,
                                           flg_type,
                                           flg_status,
                                           num_gest_weeks,
                                           dt_pat_pregnancy_tstz,
                                           dt_last_menstruation,
                                           flg_menses,
                                           cycle_duration,
                                           flg_use_constraceptives,
                                           dt_contrac_meth_end,
                                           flg_dt_contrac_precision,
                                           dt_intervention,
                                           dt_pdel_lmp,
                                           num_gest_weeks_exam,
                                           dt_init_preg_exam,
                                           dt_init_preg_lmp,
                                           num_gest_weeks_us,
                                           dt_init_pregnancy,
                                           dt_pdel_correct,
                                           dt_us_performed,
                                           n_children,
                                           flg_complication,
                                           notes_complications,
                                           notes,
                                           flg_dt_interv_precision,
                                           id_inst_intervention,
                                           flg_desc_intervention,
                                           desc_intervention,
                                           flg_extraction,
                                           flg_preg_out_type,
                                           num_births,
                                           num_abortions,
                                           num_gestations,
                                           pp.flg_gest_weeks,
                                           pp.flg_gest_weeks_exam,
                                           pp.flg_gest_weeks_us,
                                           pk_pregnancy_core.get_summ_page_first_title(i_lang,
                                                                                       i_prof,
                                                                                       id_pat_pregnancy,
                                                                                       NULL,
                                                                                       flg_type) first_title,
                                           pk_pregnancy_core.check_break_summ_pg_exam(i_lang,
                                                                                      i_prof,
                                                                                      flg_type,
                                                                                      num_gest_weeks_exam) break_exam,
                                           pk_pregnancy_core.check_break_summ_pg_us(i_lang,
                                                                                    i_prof,
                                                                                    flg_type,
                                                                                    num_gest_weeks_us,
                                                                                    dt_pdel_correct,
                                                                                    dt_us_performed,
                                                                                    n_children) break_us,
                                           pk_pregnancy_core.check_break_summ_pg_compl(i_lang,
                                                                                       i_prof,
                                                                                       flg_type,
                                                                                       id_pat_pregnancy,
                                                                                       NULL,
                                                                                       flg_complication,
                                                                                       notes_complications) break_compl,
                                           pk_pregnancy_core.check_break_summ_pg_out(i_lang,
                                                                                     i_prof,
                                                                                     flg_type,
                                                                                     id_pat_pregnancy,
                                                                                     flg_status,
                                                                                     dt_intervention,
                                                                                     id_inst_intervention,
                                                                                     flg_desc_intervention,
                                                                                     desc_intervention) break_out,
                                           pk_pregnancy_core.check_break_summ_pg_notes(i_lang, i_prof, flg_type, notes) break_notes
                                      FROM pat_pregnancy pp
                                     WHERE pp.id_patient = i_pat
                                       AND (pp.flg_status NOT IN
                                           (pk_pregnancy_core.g_pat_pregn_active,
                                             pk_pregnancy_core.g_pat_pregn_cancel,
                                             pk_pregnancy_core.g_pat_pregn_past,
                                             pk_pregnancy_core.g_pat_pregn_no,
                                             pk_pregnancy_core.g_pat_pregn_auto_close) OR
                                           (pk_pregnancy_core.check_pregn_complications(i_lang,
                                                                                         i_prof,
                                                                                         pp.id_pat_pregnancy,
                                                                                         pp.flg_complication,
                                                                                         pp.notes_complications,
                                                                                         pp.flg_type) =
                                           pk_alert_constant.g_yes AND
                                           pp.flg_status = pk_pregnancy_core.g_pat_pregn_past))) pp)
                     ORDER BY id_epis_documentation, id_doc_component);
        ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_obs_idx
        THEN
        
            g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
            SELECT t_doc_area_register_line(id_epis_documentation    => id_epis_documentation,
                                            PARENT                   => PARENT,
                                            id_doc_template          => id_doc_template,
                                            dt_creation              => dt_creation,
                                            dt_register              => dt_register,
                                            dt_pat_pregnancy_tstz    => dt_pat_pregnancy_tstz,
                                            id_professional          => id_professional,
                                            nick_name                => nick_name,
                                            desc_speciality          => desc_speciality,
                                            id_doc_area              => id_doc_area,
                                            flg_status               => flg_status,
                                            flg_preg_status          => flg_preg_status,
                                            desc_status              => desc_status,
                                            notes                    => notes,
                                            dt_last_update           => dt_last_update,
                                            flg_type_register        => flg_type_register,
                                            flg_type                 => flg_type,
                                            n_pregnancy              => n_pregnancy,
                                            pregnancy_number         => pregnancy_number,
                                            dt_last_menstruation     => dt_last_menstruation,
                                            weeks_number             => weeks_number,
                                            days_number              => days_number,
                                            weeks_measure            => weeks_measure,
                                            weight_measure           => weight_measure,
                                            n_children               => n_children,
                                            flg_abortion_type        => flg_abortion_type,
                                            flg_childbirth_type      => flg_childbirth_type,
                                            flg_child_status         => flg_child_status,
                                            flg_gender               => flg_gender,
                                            weight                   => weight,
                                            weight_um                => weight_um,
                                            present_health           => present_health,
                                            flg_present_health       => flg_present_health,
                                            flg_complication         => flg_complication,
                                            notes_complications      => notes_complications,
                                            id_inst_intervention     => id_inst_intervention,
                                            flg_desc_intervention    => flg_desc_intervention,
                                            desc_intervention        => desc_intervention,
                                            dt_intervention          => dt_intervention,
                                            dt_intervention_tstz     => dt_intervention_tstz,
                                            dt_init_pregnancy        => dt_init_pregnancy,
                                            flg_dt_interv_precision  => flg_dt_interv_precision,
                                            dt_intervention_chr      => dt_intervention_chr,
                                            pregnancy_notes          => pregnancy_notes,
                                            flg_menses               => flg_menses,
                                            cycle_duration           => cycle_duration,
                                            flg_use_constraceptives  => flg_use_constraceptives,
                                            type_description         => type_description,
                                            type_description_field   => type_description_field,
                                            type_ids                 => type_ids,
                                            type_free_text           => type_free_text,
                                            dt_contrac_meth_end      => dt_contrac_meth_end,
                                            flg_dt_contrac_precision => flg_dt_contrac_precision,
                                            dt_pdel_lmp              => dt_pdel_lmp,
                                            code_state               => code_state,
                                            code_year                => code_year,
                                            code_number              => code_number,
                                            weeks_number_exam        => weeks_number_exam,
                                            days_number_exam         => days_number_exam,
                                            weeks_number_us          => weeks_number_us,
                                            days_number_us           => days_number_us,
                                            dt_pdel_correct          => dt_pdel_correct,
                                            dt_us_performed          => dt_us_performed,
                                            num_weeks_at_us          => num_weeks_at_us,
                                            num_days_at_us           => num_days_at_us,
                                            flg_del_onset            => flg_del_onset,
                                            del_duration             => del_duration,
                                            flg_extraction           => flg_extraction,
                                            extraction_desc          => extraction_desc,
                                            flg_preg_out_type        => flg_preg_out_type,
                                            preg_out_type_desc       => preg_out_type_desc,
                                            num_births               => num_births,
                                            num_abortions            => num_abortions,
                                            num_gestations           => num_gestations,
                                            flg_gest_weeks           => flg_gest_weeks,
                                            flg_gest_weeks_exam      => flg_gest_weeks_exam,
                                            flg_gest_weeks_us        => flg_gest_weeks_us,
                                            viewer_category          => viewer_category,
                                            viewer_category_desc     => viewer_category_desc,
                                            viewer_id_prof           => viewer_id_prof,
                                            viewer_id_epis           => viewer_id_epis,
                                            viewer_date              => viewer_date,
                                            rank                     => rank)
              BULK COLLECT
              INTO o_doc_area_register
              FROM (SELECT *
                      FROM (SELECT 0 id_epis_documentation,
                                   NULL PARENT,
                                   NULL id_doc_template,
                                   NULL dt_creation,
                                   NULL dt_register,
                                   NULL dt_pat_pregnancy_tstz,
                                   NULL id_professional,
                                   NULL nick_name,
                                   NULL desc_speciality,
                                   i_doc_area id_doc_area,
                                   pk_pregnancy_core.g_pat_pregn_active flg_status,
                                   NULL flg_preg_status,
                                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS',
                                                           pk_pregnancy_core.g_pat_pregn_active,
                                                           i_lang) desc_status,
                                   NULL notes,
                                   NULL dt_last_update,
                                   pk_pregnancy_core.g_free_text flg_type_register,
                                   NULL flg_type,
                                   NULL n_pregnancy,
                                   NULL pregnancy_number,
                                   NULL dt_last_menstruation,
                                   NULL weeks_number,
                                   NULL days_number,
                                   NULL weeks_measure,
                                   NULL weight_measure,
                                   NULL n_children,
                                   NULL flg_abortion_type,
                                   NULL flg_childbirth_type,
                                   NULL flg_child_status,
                                   NULL flg_gender,
                                   NULL weight,
                                   NULL weight_um,
                                   NULL present_health,
                                   NULL flg_present_health,
                                   NULL flg_complication,
                                   NULL notes_complications,
                                   NULL id_inst_intervention,
                                   NULL flg_desc_intervention,
                                   NULL desc_intervention,
                                   NULL dt_intervention,
                                   NULL dt_intervention_tstz,
                                   NULL dt_init_pregnancy,
                                   NULL flg_dt_interv_precision,
                                   NULL dt_intervention_chr,
                                   NULL pregnancy_notes,
                                   NULL flg_menses,
                                   NULL cycle_duration,
                                   NULL flg_use_constraceptives,
                                   NULL type_description,
                                   NULL type_description_field,
                                   NULL type_ids,
                                   NULL type_free_text,
                                   NULL dt_contrac_meth_end,
                                   NULL flg_dt_contrac_precision,
                                   NULL dt_pdel_lmp,
                                   NULL code_state,
                                   NULL code_year,
                                   NULL code_number,
                                   NULL weeks_number_exam,
                                   NULL days_number_exam,
                                   NULL weeks_number_us,
                                   NULL days_number_us,
                                   NULL dt_pdel_correct,
                                   NULL dt_us_performed,
                                   NULL num_weeks_at_us,
                                   NULL num_days_at_us,
                                   NULL flg_del_onset,
                                   NULL del_duration,
                                   NULL flg_extraction,
                                   NULL extraction_desc,
                                   NULL flg_preg_out_type,
                                   NULL preg_out_type_desc,
                                   NULL num_births,
                                   NULL num_abortions,
                                   NULL num_gestations,
                                   NULL flg_gest_weeks,
                                   NULL flg_gest_weeks_exam,
                                   NULL flg_gest_weeks_us,
                                   -- viewer fields
                                   NULL viewer_category,
                                   NULL viewer_category_desc,
                                   NULL viewer_id_prof,
                                   NULL viewer_id_epis,
                                   NULL viewer_date,
                                   2    rank
                              FROM dual
                             WHERE EXISTS (SELECT 0
                                      FROM pat_pregnancy pp
                                     WHERE pp.id_patient = i_pat
                                       AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel)
                            UNION ALL
                            SELECT pp_ac.id_pat_pregnancy id_epis_documentation,
                                   NULL PARENT,
                                   NULL id_doc_template,
                                   pk_date_utils.date_send_tsz(i_lang, pp_ac.dt_auto_closed, i_prof) dt_creation,
                                   NULL dt_register,
                                   NULL dt_pat_pregnancy_tstz,
                                   NULL id_professional,
                                   NULL nick_name,
                                   NULL desc_speciality,
                                   i_doc_area id_doc_area,
                                   pk_pregnancy_core.g_pat_pregn_auto_close flg_status,
                                   pp_ac.flg_status flg_preg_status,
                                   l_outdated desc_status,
                                   NULL notes,
                                   pk_date_utils.date_send_tsz(i_lang, pp_ac.dt_auto_closed, i_prof) dt_last_update,
                                   pk_pregnancy_core.g_free_text flg_type_register,
                                   pk_pregnancy_core.g_free_text flg_type,
                                   NULL n_pregnancy,
                                   NULL pregnancy_number,
                                   NULL dt_last_menstruation,
                                   NULL weeks_number,
                                   NULL days_number,
                                   NULL weeks_measure,
                                   NULL weight_measure,
                                   NULL n_children,
                                   NULL flg_abortion_type,
                                   NULL flg_childbirth_type,
                                   NULL flg_child_status,
                                   NULL flg_gender,
                                   NULL weight,
                                   NULL weight_um,
                                   NULL present_health,
                                   NULL flg_present_health,
                                   NULL flg_complication,
                                   NULL notes_complications,
                                   NULL id_inst_intervention,
                                   NULL flg_desc_intervention,
                                   NULL desc_intervention,
                                   NULL dt_intervention,
                                   NULL dt_intervention_tstz,
                                   NULL dt_init_pregnancy,
                                   NULL flg_dt_interv_precision,
                                   NULL dt_intervention_chr,
                                   NULL pregnancy_notes,
                                   NULL flg_menses,
                                   NULL cycle_duration,
                                   NULL flg_use_constraceptives,
                                   NULL type_description,
                                   NULL type_description_field,
                                   NULL type_ids,
                                   NULL type_free_text,
                                   NULL dt_contrac_meth_end,
                                   NULL flg_dt_contrac_precision,
                                   NULL dt_pdel_lmp,
                                   NULL code_state,
                                   NULL code_year,
                                   NULL code_number,
                                   NULL weeks_number_exam,
                                   NULL days_number_exam,
                                   NULL weeks_number_us,
                                   NULL days_number_us,
                                   NULL dt_pdel_correct,
                                   NULL dt_us_performed,
                                   NULL num_weeks_at_us,
                                   NULL num_days_at_us,
                                   NULL flg_del_onset,
                                   NULL del_duration,
                                   NULL flg_extraction,
                                   NULL extraction_desc,
                                   NULL flg_preg_out_type,
                                   NULL preg_out_type_desc,
                                   NULL num_births,
                                   NULL num_abortions,
                                   NULL num_gestations,
                                   NULL flg_gest_weeks,
                                   NULL flg_gest_weeks_exam,
                                   NULL flg_gest_weeks_us,
                                   -- viewer fields
                                   NULL viewer_category,
                                   NULL viewer_category_desc,
                                   NULL viewer_id_prof,
                                   NULL viewer_id_epis,
                                   NULL viewer_date,
                                   1    rank
                              FROM pat_pregnancy pp_ac
                             WHERE pp_ac.id_patient = i_pat
                               AND pp_ac.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close) t
                     ORDER BY t.rank ASC);
        
            g_error := 'GET CURSOR O_DOC_AREA_VAL';
        
            SELECT t_doc_area_val_line(id_epis_documentation     => id_epis_documentation,
                                       PARENT                    => PARENT,
                                       id_documentation          => id_documentation,
                                       id_doc_component          => id_doc_component,
                                       id_doc_element_crit       => id_doc_element_crit,
                                       dt_reg                    => dt_reg,
                                       desc_doc_component        => desc_doc_component,
                                       desc_element              => desc_element,
                                       VALUE                     => VALUE,
                                       id_doc_area               => id_doc_area,
                                       rank_component            => rank_component,
                                       rank_element              => rank_element,
                                       desc_qualification        => desc_qualification,
                                       flg_current_episode       => flg_current_episode,
                                       id_epis_documentation_det => id_epis_documentation_det)
              BULK COLLECT
              INTO o_doc_area_val
              FROM (
                    
                    SELECT t.id_epis_documentation,
                            t.parent,
                            t.id_documentation,
                            t.id_doc_component,
                            t.id_doc_element_crit,
                            t.dt_reg,
                            t.desc_doc_component,
                            t.desc_element,
                            t.value,
                            t.id_doc_area,
                            t.rank_component,
                            t.rank_element,
                            t.desc_qualification,
                            t.flg_current_episode,
                            t.id_epis_documentation_det
                      FROM (SELECT 0    id_epis_documentation,
                                    NULL PARENT,
                                    NULL id_documentation,
                                    NULL id_doc_component,
                                    NULL id_doc_element_crit,
                                    NULL dt_reg,
                                    -- obstetric index
                                    pk_pregnancy_core.get_obstetric_index(i_lang, i_prof, i_pat, 'T') desc_doc_component,
                                    pk_pregnancy_core.get_obstetric_index(i_lang, i_prof, i_pat, 'C') desc_element,
                                    NULL VALUE,
                                    i_doc_area id_doc_area,
                                    1 rank_component,
                                    1 rank_element,
                                    NULL desc_qualification,
                                    NULL flg_current_episode,
                                    NULL id_epis_documentation_det,
                                    0 rank
                               FROM dual
                              WHERE EXISTS (SELECT 0
                                       FROM pat_pregnancy pp
                                      WHERE pp.id_patient = i_pat
                                        AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel)
                             UNION ALL
                             SELECT pp_ac.id_pat_pregnancy id_epis_documentation,
                                    NULL PARENT,
                                    0 id_documentation,
                                    0 id_doc_component,
                                    NULL id_doc_element_crit,
                                    pk_date_utils.date_send_tsz(i_lang, pp_ac.dt_auto_closed, i_prof) dt_reg,
                                    -- obstetric index
                                    NULL desc_doc_component,
                                    l_label_pregn_num || ' ' || pp_ac.n_pregnancy || ' ' || l_auto_close || ' ' ||
                                    pk_date_utils.date_char_tsz(i_lang,
                                                                pp_ac.dt_auto_closed,
                                                                i_prof.institution,
                                                                i_prof.software) desc_element,
                                    NULL VALUE,
                                    i_doc_area id_doc_area,
                                    1 rank_component,
                                    1 rank_element,
                                    NULL desc_qualification,
                                    NULL flg_current_episode,
                                    NULL id_epis_documentation_det,
                                    1 rank
                               FROM pat_pregnancy pp_ac
                              WHERE pp_ac.id_patient = i_pat
                                AND pp_ac.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close) t
                     ORDER BY t.rank ASC);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_SUM_PAGE_DOC_AREA_PREG_INT', g_error, SQLERRM, FALSE, o_error);
    END get_sum_page_doc_area_preg_int;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page (REPORTS version)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/23
    **********************************************************************************************/

    FUNCTION get_summ_pg_doc_ar_preg_rep
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
    
        RETURN get_summ_page_doc_area_pregn(i_lang,
                                            i_prof,
                                            i_episode,
                                            i_pat,
                                            i_doc_area,
                                            o_doc_area_register,
                                            o_doc_area_val,
                                            o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN error_handling_ext(i_lang,
                                      'GET_SUMM_PAGE_DOC_AREA_PREGN',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_summ_pg_doc_ar_preg_rep;

    /********************************************************************************************
    * Gets all domains used in the pregnancy creation/edition screen
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_DOMAIN domain code
    * @param   O_DOMAINS the cursOr with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    *
    * @author  José Silva
    * @version 1.0 
    * @since   28-08-2008
    *********************************************************************************************/
    FUNCTION get_pregnancy_domain
    (
        i_lang    IN sys_domain.id_language%TYPE,
        i_prof    IN profissional,
        i_domain  IN sys_domain.code_domain%TYPE,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_abortion           CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.FLG_STATUS';
        l_code_preg_out_type      CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.FLG_PREG_OUT_TYPE';
        l_code_compl              CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.FLG_COMPLICATION';
        l_code_fetus_st           CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGN_FETUS.FLG_STATUS';
        l_config_abortion         CONSTANT sys_config.id_sys_config%TYPE := 'PREGNANCY_ABORTION_LIMIT';
        l_code_contrac_method     CONSTANT sys_domain.code_domain%TYPE := 'WOMAN_HEALTH.CONTRAC_METHOD';
        l_code_newborn_cur_status CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGN_FETUS.CURRENT_STATUS';
        l_config_cur_status       CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_CURR_STATUS_DEFAULT';
        l_cur_status_def sys_config.value%TYPE;
        l_abortion_limit NUMBER;
    
        l_flg_context_pregnancy CONSTANT VARCHAR2(1 CHAR) := 'P';
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
        l_show_diagnosis VARCHAR2(1 CHAR);
        l_fetus_alive    sys_domain.val%TYPE;
    
        l_tbl_diags t_coll_values_domain_mkt;
    BEGIN
    
        IF i_domain = l_code_compl
        THEN
            l_show_diagnosis := pk_alert_constant.g_yes;
        ELSE
            l_show_diagnosis := pk_alert_constant.g_no;
        END IF;
    
        IF i_domain = l_code_abortion
           OR i_domain = l_code_preg_out_type
        THEN
            l_abortion_limit := pk_sysconfig.get_config(l_config_abortion, i_prof);
        END IF;
    
        l_cur_status_def := pk_sysconfig.get_config(l_config_cur_status, i_prof);
    
        IF i_domain = l_code_fetus_st
        THEN
            l_fetus_alive := pk_alert_constant.g_yes;
        ELSE
            l_fetus_alive := pk_alert_constant.g_no;
        END IF;
    
        IF i_domain <> pk_pregnancy_core.g_code_domain
        THEN
            l_tbl_diags := pk_diagnosis_core.get_pregn_diag_diff_list(i_lang, i_prof, l_show_diagnosis);
        
            g_error := 'GET CURSOR';
            OPEN o_domains FOR
                SELECT sd.val data,
                       sd.desc_val label,
                       sd.rank,
                       NULL id_alert_diagnosis,
                       l_abortion_limit max_gestation_age,
                       decode(sd.val, pk_pregnancy_core.g_pregn_fetus_an, l_fetus_alive, pk_alert_constant.g_no) fetus_alive,
                       decode(i_domain,
                              l_code_newborn_cur_status,
                              decode(sd.val, l_cur_status_def, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                              pk_alert_constant.g_no) flg_default
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, i_domain, NULL)) sd
                UNION ALL
                SELECT sd.val      data,
                       sd.desc_val label,
                       sd.rank,
                       sd.val      id_alert_diagnosis,
                       NULL        max_gestation_age,
                       NULL        fetus_alive,
                       NULL
                  FROM TABLE(l_tbl_diags) sd
                 ORDER BY rank, label;
        
        ELSIF NOT get_inst_domain_template(i_lang,
                                           i_prof,
                                           pk_pregnancy_core.g_flg_type_r,
                                           l_flg_context_pregnancy,
                                           o_domains,
                                           l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_domains);
            RETURN error_handling(i_lang,
                                  'GET_PREGNANCY_DOMAIN',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  FALSE,
                                  o_error);
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_domains);
            RETURN error_handling(i_lang, 'GET_PREGNANCY_DOMAIN', g_error, SQLERRM, FALSE, o_error);
    END get_pregnancy_domain;

    /************************************************************************************************************ 
    * This function creates new pregnacies or updates existing ones for the specified patient
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_dt_last_menstruation        last menstruation date
    * @param      i_dt_intervention             childbirth/abortion dat
    * @param      i_flg_type                    Register type: C - regular pregnancy, R - reported pregnancy
    * @param      i_n_pregnancy                 pregnancy number
    * @param      i_n_children                  number of born childs
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_flg_child_weight            list of child weight (one per children)
    * @param      i_flg_complication            Complication type during pregnancy
    * @param      i_notes_complication          Complication notes (free text)
    * @param      i_flg_desc_interv             Type of register related to the intervention place: D - home; I - institution; O - free text
    * @param      i_desc_intervention           Description related to the place where the delivery/abortion occured
    * @param      i_id_inst_interv              Institution ID in which the labor/abortion took place
    * @param      i_notes                       Pregnancy notes
    * @param      i_flg_abortion_type           flag that indicates the abortion type
    * @param      i_prof                        Professional info
    * @param      i_id_episode                  Episode ID
    * @param      i_cdr_call                    Rule engine call identifier
    * @param      o_error                       error message
    *
    * @return     Saves the information for a specified pregnancy
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/24
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_patient              IN patient.id_patient%TYPE,
        i_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_last_menstruation IN VARCHAR2,
        i_dt_intervention      IN VARCHAR2,
        i_flg_type             IN VARCHAR2,
        i_num_weeks            IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days             IN NUMBER,
        i_n_children           IN pat_pregnancy.n_children%TYPE,
        i_flg_childbirth_type  IN table_varchar,
        i_flg_child_status     IN table_varchar,
        i_flg_child_gender     IN table_varchar,
        i_flg_child_weight     IN table_number,
        i_um_weight            IN table_number,
        --
        i_present_health     IN table_varchar,
        i_flg_present_health IN table_varchar,
        --
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE,
        i_flg_desc_interv    IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention  IN pat_pregnancy.desc_intervention%TYPE,
        i_id_inst_interv     IN pat_pregnancy.id_inst_intervention%TYPE,
        i_notes              IN pat_pregnancy.notes%TYPE,
        i_flg_abortion_type  IN pat_pregnancy.flg_status%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        --
        i_flg_menses           IN pat_pregnancy.flg_menses%TYPE,
        i_cycle_duration       IN pat_pregnancy.cycle_duration%TYPE,
        i_flg_use_constracep   IN pat_pregnancy.flg_use_constraceptives%TYPE,
        i_dt_contrac_meth_end  IN VARCHAR2,
        i_flg_contra_precision IN VARCHAR2,
        i_dt_pdel_lmp          IN VARCHAR2,
        i_num_weeks_exam       IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_days_exam        IN NUMBER,
        i_num_weeks_us         IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_num_days_us          IN NUMBER,
        i_dt_pdel_correct      IN VARCHAR2,
        i_dt_us_performed      IN VARCHAR2,
        i_flg_del_onset        IN pat_pregnancy.flg_del_onset%TYPE,
        i_del_duration         IN pat_pregnancy.del_duration%TYPE,
        i_flg_interv_precision IN pat_pregnancy.flg_dt_interv_precision%TYPE,
        i_id_alert_diagnosis   IN table_number,
        -- SISPRENATAL
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE,
        --Contraceptive Type
        i_flg_contrac_type IN table_number,
        i_notes_contrac    IN VARCHAR2,
        --
        i_cdr_call IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        --
        i_flg_extraction      IN pat_pregnancy.flg_extraction%TYPE DEFAULT NULL,
        i_flg_preg_out_type   IN pat_pregnancy.flg_preg_out_type%TYPE DEFAULT NULL,
        i_num_births          IN pat_pregnancy.num_births%TYPE DEFAULT NULL,
        i_num_abortions       IN pat_pregnancy.num_abortions%TYPE DEFAULT NULL,
        i_num_gestations      IN pat_pregnancy.num_gestations%TYPE DEFAULT NULL,
        i_flg_gest_weeks      IN pat_pregnancy.flg_gest_weeks%TYPE DEFAULT NULL,
        i_flg_gest_weeks_exam IN pat_pregnancy.flg_gest_weeks_exam%TYPE DEFAULT NULL,
        i_flg_gest_weeks_us   IN pat_pregnancy.flg_gest_weeks_us%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pregn_exception EXCEPTION;
        l_msg_pregn_exc sys_message.desc_message%TYPE;
        l_n_preg_exists NUMBER;
    
        l_sisprenatal_exception EXCEPTION;
        l_msg_sisprenatal_exc sys_message.desc_message%TYPE;
        l_sisprenatal_exists  VARCHAR2(1 CHAR);
    
        l_flg_status         pat_pregnancy.flg_status%TYPE;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_num_weeks          pat_pregnancy.num_gest_weeks%TYPE;
        l_num_weeks_exam     pat_pregnancy.num_gest_weeks_exam%TYPE;
        l_num_weeks_us       pat_pregnancy.num_gest_weeks_us%TYPE;
        l_dt_intervention    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_pregnancy_start pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_pregn_exam      pat_pregnancy.dt_init_preg_exam%TYPE;
        l_dt_pregn_lmp       pat_pregnancy.dt_init_preg_lmp%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
    
        l_weith_um    unit_measure.id_unit_measure%TYPE;
        l_t_weight_um table_varchar;
    
        l_num_weeks_lmp NUMBER;
        l_num_days_lmp  NUMBER;
    
        CURSOR c1 IS
            SELECT 1
              FROM pat_pregnancy p
             WHERE id_patient = i_patient
               AND flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
               AND nvl(p.flg_dt_interv_precision, pk_pregnancy_core.g_dt_flg_precision_h) <>
                   pk_pregnancy_core.g_dt_flg_precision_y
               AND (l_dt_intervention = p.dt_intervention OR
                   (l_dt_pregnancy_start BETWEEN
                   nvl(p.dt_init_pregnancy, p.dt_intervention - numtodsinterval(p.num_gest_weeks * 7, 'DAY')) AND
                   nvl(p.dt_intervention, current_timestamp) OR
                   l_dt_intervention BETWEEN
                   nvl(p.dt_init_pregnancy, p.dt_intervention - numtodsinterval(p.num_gest_weeks * 7, 'DAY')) AND
                   nvl(p.dt_intervention, current_timestamp)))
               AND (id_pat_pregnancy <> i_pat_pregnancy OR i_pat_pregnancy IS NULL);
    
        l_rowids_1 table_varchar;
        e_process_event EXCEPTION;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
        CURSOR c_exist_pregancy IS
            SELECT COUNT(1)
              FROM pat_pregnancy pp
             WHERE id_patient = i_patient
               AND flg_status IN (pk_pregnancy_core.g_pat_pregn_active)
               AND (pp.id_pat_pregnancy <> i_pat_pregnancy OR i_pat_pregnancy IS NULL);
    
        l_exist_pregancy NUMBER;
        l_curr_pregn     sys_message.desc_message%TYPE;
        l_exception_curr_pregn EXCEPTION;
    
        l_women_health_hpg_id   sys_config.value%TYPE;
        l_health_program        health_program.id_health_program%TYPE;
        l_insts                 table_number;
        l_id_pat_health_program pat_health_program.id_pat_health_program%TYPE;
        l_php_flg_status        pat_health_program.flg_status%TYPE;
        l_dt_begin_tstz         pat_health_program.dt_begin_tstz%TYPE;
    
        l_extraction_config    CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('EXTRACTION_EXPULSION_VISIBLE',
                                                                                         i_prof);
        l_gest_week_unk_config CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('UNKNOWN_GESTATION_AVAILABLE',
                                                                                         i_prof);
    BEGIN
    
        g_error               := 'GET ERROR MESSAGE';
        l_msg_pregn_exc       := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T122');
        l_msg_sisprenatal_exc := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M011');
        l_curr_pregn          := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T184');
    
        g_error := 'CHECK SISPRENATAL NUMBER';
        IF i_code_number IS NOT NULL
        THEN
            l_sisprenatal_exists := pk_pregnancy_core.check_pregnancy_code(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_pat_pregnancy => i_pat_pregnancy,
                                                                           i_code_state    => i_code_state,
                                                                           i_code_year     => i_code_year,
                                                                           i_code_number   => i_code_number,
                                                                           i_flg_type      => pk_pregnancy_core.g_pregn_code_s);
        
            IF l_sisprenatal_exists = pk_alert_constant.g_yes
            THEN
                RAISE l_sisprenatal_exception;
            END IF;
        END IF;
    
        g_error := 'GET FLG STATUS';
        IF i_flg_abortion_type IS NOT NULL
        THEN
            l_flg_status := i_flg_abortion_type;
        ELSE
            IF i_flg_type = pk_pregnancy_core.g_pat_pregn_type_c
               AND
               ((i_dt_intervention IS NULL AND l_extraction_config <> g_yes) OR
               (l_extraction_config = g_yes AND
               (i_flg_preg_out_type IS NULL OR
               (i_flg_preg_out_type IS NOT NULL AND i_flg_preg_out_type <> pk_pregnancy_core.g_pat_pregn_type_ab))))
            THEN
                l_flg_status := pk_pregnancy_core.g_pat_pregn_active;
            ELSIF i_flg_type = pk_pregnancy_core.g_pat_pregn_type_r
                  OR i_dt_intervention IS NOT NULL
                  OR i_flg_preg_out_type = pk_pregnancy_core.g_pat_pregn_type_ab
            THEN
                l_flg_status := pk_pregnancy_core.g_pat_pregn_past;
            END IF;
        END IF;
    
        IF l_flg_status = pk_pregnancy_core.g_pat_pregn_active
        THEN
            OPEN c_exist_pregancy;
            FETCH c_exist_pregancy
                INTO l_exist_pregancy;
            CLOSE c_exist_pregancy;
        
            IF l_exist_pregancy > 0
            THEN
                RAISE l_exception_curr_pregn;
            END IF;
        END IF;
    
        l_dt_intervention := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_intervention, NULL);
    
        g_error       := 'GET WEIGHT UNIT_MEASURE';
        l_t_weight_um := table_varchar();
        l_weith_um    := pk_pregnancy_core.get_preg_summ_unit_measure_id(i_lang, i_prof);
    
        FOR i IN 1 .. i_flg_child_weight.count
        LOOP
            l_t_weight_um.extend;
        
            IF i_um_weight.count > 0
            THEN
                l_t_weight_um(i) := i_um_weight(i);
            ELSIF i_flg_child_weight(i) IS NOT NULL
            THEN
                l_t_weight_um(i) := l_weith_um;
            ELSE
                l_t_weight_um(i) := NULL;
            END IF;
        END LOOP;
    
        -- this code is used when the pregnancy is created using the ultrasound request
        g_error := 'CHECK GESTATION WEEKS';
        pk_alertlog.log_debug('WEEKS:' || coalesce(i_num_weeks, i_num_weeks_exam, i_num_weeks_us));
        pk_alertlog.log_debug('DAYS:' || coalesce(i_num_days, i_num_days_exam, i_num_days_us));
        IF coalesce(i_num_weeks, i_num_weeks_exam, i_num_weeks_us) IS NULL
           AND coalesce(i_num_days, i_num_days_exam, i_num_days_us) IS NULL
        THEN
        
            l_num_weeks_lmp := pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                     to_date(i_dt_last_menstruation,
                                                                             pk_date_utils.g_dateformat),
                                                                     l_dt_intervention,
                                                                     NULL);
            l_num_days_lmp  := pk_pregnancy_core.get_pregnancy_days(i_prof,
                                                                    to_date(i_dt_last_menstruation,
                                                                            pk_date_utils.g_dateformat),
                                                                    l_dt_intervention,
                                                                    NULL);
        ELSE
            l_num_weeks_lmp := i_num_weeks;
            l_num_days_lmp  := i_num_days;
        END IF;
    
        g_error := 'GET GESTATION WEEKS';
        IF NOT pk_pregnancy_core.get_gestation_weeks(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_num_weeks      => l_num_weeks_lmp,
                                                     i_num_days       => l_num_days_lmp,
                                                     i_num_weeks_exam => i_num_weeks_exam,
                                                     i_num_days_exam  => i_num_days_exam,
                                                     i_num_weeks_us   => i_num_weeks_us,
                                                     i_num_days_us    => i_num_days_us,
                                                     o_num_weeks      => l_num_weeks,
                                                     o_num_weeks_exam => l_num_weeks_exam,
                                                     o_num_weeks_us   => l_num_weeks_us,
                                                     o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
        pk_alertlog.log_debug(' get_gestation_weeks l_num_weeks_lmp:' || l_num_weeks_lmp || 'l_num_days_lmp:' ||
                              l_num_days_lmp || ' l_num_weeks:' || l_num_weeks);
        g_error              := 'CHECK PREGNANCY START DATE';
        l_dt_pregnancy_start := pk_pregnancy_core.get_dt_pregnancy_start(i_prof            => i_prof,
                                                                         i_num_weeks       => l_num_weeks,
                                                                         i_num_weeks_exam  => l_num_weeks_exam,
                                                                         i_num_weeks_us    => l_num_weeks_us,
                                                                         i_dt_intervention => l_dt_intervention,
                                                                         i_flg_precision   => i_flg_interv_precision);
    
        g_error        := 'GET DT_LAST_MENSTRUATION';
        l_dt_pregn_lmp := pk_pregnancy_core.get_dt_pregnancy_start(i_prof,
                                                                   l_num_weeks,
                                                                   NULL,
                                                                   NULL,
                                                                   l_dt_intervention,
                                                                   i_flg_interv_precision);
    
        g_error         := 'GET DT_PREG_EXAM';
        l_dt_pregn_exam := pk_pregnancy_core.get_dt_pregnancy_start(i_prof            => i_prof,
                                                                    i_num_weeks       => NULL,
                                                                    i_num_weeks_exam  => l_num_weeks_exam,
                                                                    i_num_weeks_us    => NULL,
                                                                    i_dt_intervention => l_dt_intervention,
                                                                    i_flg_precision   => i_flg_interv_precision);
    
        IF i_flg_interv_precision <> pk_pregnancy_core.g_dt_flg_precision_y
        THEN
            OPEN c1;
            FETCH c1
                INTO l_n_preg_exists;
            g_found := c1%NOTFOUND;
            CLOSE c1;
        ELSE
            g_found := TRUE;
        END IF;
    
        IF g_found
        THEN
        
            g_error := 'INSERT';
            IF i_pat_pregnancy IS NULL
            THEN
                g_error            := 'GET PAT_PREGNANCY ID';
                l_id_pat_pregnancy := ts_pat_pregnancy.next_key();
            
                g_error := 'INSERT PAT_PREGNANCY';
                ts_pat_pregnancy.ins(id_pat_pregnancy_in      => l_id_pat_pregnancy,
                                     dt_pat_pregnancy_tstz_in => current_timestamp,
                                     id_professional_in       => i_prof.id,
                                     id_patient_in            => i_patient,
                                     dt_last_menstruation_in  => to_date(i_dt_last_menstruation,
                                                                         pk_date_utils.g_dateformat),
                                     num_gest_weeks_in        => l_num_weeks,
                                     num_gest_weeks_exam_in   => l_num_weeks_exam,
                                     num_gest_weeks_us_in     => l_num_weeks_us,
                                     dt_intervention_in       => l_dt_intervention,
                                     n_children_in            => i_n_children,
                                     flg_status_in            => l_flg_status,
                                     id_episode_in            => i_id_episode,
                                     flg_type_in              => i_flg_type,
                                     flg_complication_in      => i_flg_complication,
                                     notes_complications_in   => i_notes_complication,
                                     flg_desc_intervention_in => i_flg_desc_interv,
                                     desc_intervention_in     => i_desc_intervention,
                                     id_inst_intervention_in  => i_id_inst_interv,
                                     notes_in                 => i_notes,
                                     --
                                     flg_menses_in               => i_flg_menses,
                                     cycle_duration_in           => i_cycle_duration,
                                     flg_use_constraceptives_in  => i_flg_use_constracep,
                                     dt_contrac_meth_end_in      => to_date(i_dt_contrac_meth_end,
                                                                            pk_date_utils.g_dateformat),
                                     flg_dt_contrac_precision_in => i_flg_contra_precision,
                                     dt_pdel_lmp_in              => to_date(i_dt_pdel_lmp, pk_date_utils.g_dateformat),
                                     dt_pdel_correct_in          => to_date(i_dt_pdel_correct,
                                                                            pk_date_utils.g_dateformat),
                                     dt_us_performed_in          => to_date(i_dt_us_performed,
                                                                            pk_date_utils.g_dateformat),
                                     flg_del_onset_in            => i_flg_del_onset,
                                     del_duration_in             => i_del_duration,
                                     flg_dt_interv_precision_in  => i_flg_interv_precision,
                                     dt_init_pregnancy_in        => l_dt_pregnancy_start,
                                     dt_init_preg_exam_in        => l_dt_pregn_exam,
                                     dt_init_preg_lmp_in         => l_dt_pregn_lmp,
                                     --
                                     id_cdr_call_in         => i_cdr_call,
                                     flg_extraction_in      => i_flg_extraction,
                                     num_births_in          => i_num_births,
                                     num_abortions_in       => i_num_abortions,
                                     num_gestations_in      => i_num_gestations,
                                     flg_preg_out_type_in   => i_flg_preg_out_type,
                                     flg_gest_weeks_in      => i_flg_gest_weeks,
                                     flg_gest_weeks_exam_in => i_flg_gest_weeks_exam,
                                     flg_gest_weeks_us_in   => i_flg_gest_weeks_us,
                                     rows_out               => l_rowids_1);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PREGNANCY',
                                              i_rowids     => l_rowids_1,
                                              o_error      => l_error);
            
            ELSE
            
                l_id_pat_pregnancy := i_pat_pregnancy;
            
                g_error := 'SET PREGNANCY HISTORY';
                IF NOT pk_pregnancy_core.set_pat_pregnancy_hist(i_lang, i_pat_pregnancy, l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'UPDATE PAT PREGNANCY';
                ts_pat_pregnancy.upd(id_pat_pregnancy_in       => i_pat_pregnancy,
                                     id_professional_in        => i_prof.id,
                                     dt_pat_pregnancy_tstz_in  => current_timestamp,
                                     dt_last_menstruation_in   => to_date(i_dt_last_menstruation,
                                                                          pk_date_utils.g_dateformat),
                                     dt_last_menstruation_nin  => FALSE,
                                     num_gest_weeks_in         => l_num_weeks,
                                     num_gest_weeks_nin        => FALSE,
                                     num_gest_weeks_exam_in    => l_num_weeks_exam,
                                     num_gest_weeks_exam_nin   => FALSE,
                                     num_gest_weeks_us_in      => l_num_weeks_us,
                                     num_gest_weeks_us_nin     => FALSE,
                                     dt_intervention_in        => l_dt_intervention,
                                     dt_intervention_nin       => FALSE,
                                     n_children_in             => i_n_children,
                                     flg_status_in             => l_flg_status,
                                     flg_complication_in       => i_flg_complication,
                                     flg_complication_nin      => FALSE,
                                     notes_complications_in    => i_notes_complication,
                                     notes_complications_nin   => FALSE,
                                     flg_desc_intervention_in  => i_flg_desc_interv,
                                     flg_desc_intervention_nin => FALSE,
                                     desc_intervention_in      => i_desc_intervention,
                                     desc_intervention_nin     => FALSE,
                                     id_inst_intervention_in   => i_id_inst_interv,
                                     id_inst_intervention_nin  => FALSE,
                                     notes_in                  => i_notes,
                                     notes_nin                 => FALSE,
                                     id_episode_in             => i_id_episode,
                                     --
                                     flg_menses_in                => i_flg_menses,
                                     flg_menses_nin               => FALSE,
                                     cycle_duration_in            => i_cycle_duration,
                                     cycle_duration_nin           => FALSE,
                                     flg_use_constraceptives_in   => i_flg_use_constracep,
                                     flg_use_constraceptives_nin  => FALSE,
                                     dt_contrac_meth_end_in       => to_date(i_dt_contrac_meth_end,
                                                                             pk_date_utils.g_dateformat),
                                     dt_contrac_meth_end_nin      => FALSE,
                                     flg_dt_contrac_precision_in  => i_flg_contra_precision,
                                     flg_dt_contrac_precision_nin => FALSE,
                                     dt_pdel_lmp_in               => to_date(i_dt_pdel_lmp, pk_date_utils.g_dateformat),
                                     dt_pdel_lmp_nin              => FALSE,
                                     dt_pdel_correct_in           => to_date(i_dt_pdel_correct,
                                                                             pk_date_utils.g_dateformat),
                                     dt_pdel_correct_nin          => FALSE,
                                     dt_us_performed_in           => to_date(i_dt_us_performed,
                                                                             pk_date_utils.g_dateformat),
                                     dt_us_performed_nin          => FALSE,
                                     flg_del_onset_in             => i_flg_del_onset,
                                     flg_del_onset_nin            => FALSE,
                                     del_duration_in              => i_del_duration,
                                     del_duration_nin             => FALSE,
                                     flg_dt_interv_precision_in   => i_flg_interv_precision,
                                     flg_dt_interv_precision_nin  => FALSE,
                                     dt_init_pregnancy_in         => l_dt_pregnancy_start,
                                     dt_init_pregnancy_nin        => FALSE,
                                     dt_init_preg_exam_in         => l_dt_pregn_exam,
                                     dt_init_preg_exam_nin        => FALSE,
                                     dt_init_preg_lmp_in          => l_dt_pregn_lmp,
                                     dt_init_preg_lmp_nin         => FALSE,
                                     --
                                     id_cdr_call_in          => i_cdr_call,
                                     id_cdr_call_nin         => TRUE,
                                     flg_extraction_in       => i_flg_extraction,
                                     flg_extraction_nin      => FALSE,
                                     num_births_in           => i_num_births,
                                     num_births_nin          => FALSE,
                                     num_abortions_in        => i_num_abortions,
                                     num_abortions_nin       => FALSE,
                                     num_gestations_in       => i_num_gestations,
                                     num_gestations_nin      => FALSE,
                                     flg_preg_out_type_in    => i_flg_preg_out_type,
                                     flg_preg_out_type_nin   => FALSE,
                                     flg_gest_weeks_in       => i_flg_gest_weeks,
                                     flg_gest_weeks_nin      => FALSE,
                                     flg_gest_weeks_exam_in  => i_flg_gest_weeks_exam,
                                     flg_gest_weeks_exam_nin => FALSE,
                                     flg_gest_weeks_us_in    => i_flg_gest_weeks_us,
                                     flg_gest_weeks_us_nin   => FALSE,
                                     rows_out                => l_rowids_1);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PREGNANCY',
                                              i_rowids     => l_rowids_1,
                                              o_error      => l_error);
            END IF;
        
            g_error := 'SET FETUS INFO';
            IF NOT set_pat_pregn_fetus(i_lang,
                                       i_prof,
                                       l_id_pat_pregnancy,
                                       nvl(i_n_children, 0),
                                       NULL,
                                       i_flg_type,
                                       i_flg_child_gender,
                                       i_flg_childbirth_type,
                                       i_flg_child_status,
                                       i_flg_child_weight,
                                       l_t_weight_um,
                                       i_present_health,
                                       i_flg_present_health,
                                       l_id_pat_pregn_fetus,
                                       l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SET SISPRENATAL NUMBER';
            DELETE FROM pat_pregnancy_code
             WHERE id_pat_pregnancy = l_id_pat_pregnancy;
        
            IF i_code_number IS NOT NULL
            THEN
                IF NOT pk_pregnancy_core.set_pat_pregnancy_code(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_pat_pregnancy => l_id_pat_pregnancy,
                                                                i_code_state    => i_code_state,
                                                                i_code_year     => i_code_year,
                                                                i_code_number   => i_code_number,
                                                                i_flg_type      => pk_pregnancy_core.g_pregn_code_s,
                                                                o_error         => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            g_error := 'INSERT PAT_PREG_CONT_TYPE';
            DELETE FROM pat_preg_cont_type pd
             WHERE pd.id_pat_pregnancy = l_id_pat_pregnancy;
        
            IF i_flg_contrac_type.exists(1)
            THEN
                FOR i IN 1 .. i_flg_contrac_type.count
                LOOP
                    IF (i_flg_contrac_type(i) = pk_pregnancy_core.g_desc_contract_type_other)
                    THEN
                        INSERT INTO pat_preg_cont_type
                            (id_pat_pregnancy, id_contrac_type, other_contraception_type)
                        VALUES
                            (l_id_pat_pregnancy, i_flg_contrac_type(i), i_notes_contrac);
                    ELSE
                        INSERT INTO pat_preg_cont_type
                            (id_pat_pregnancy, id_contrac_type)
                        VALUES
                            (l_id_pat_pregnancy, i_flg_contrac_type(i));
                    END IF;
                END LOOP;
            END IF;
        
            g_error := 'INSERT PREGNANCY DIAGNOSIS';
            DELETE FROM pat_pregnancy_diagnosis pd
             WHERE pd.id_pat_pregnancy = l_id_pat_pregnancy;
        
            IF i_id_alert_diagnosis.exists(1)
            THEN
                FOR i IN 1 .. i_id_alert_diagnosis.count
                LOOP
                    INSERT INTO pat_pregnancy_diagnosis
                        (id_pat_pregnancy, id_alert_diagnosis)
                    VALUES
                        (l_id_pat_pregnancy, i_id_alert_diagnosis(i));
                END LOOP;
            END IF;
        
            g_error := 'UPDATE N_PREGNANCY';
            IF NOT pk_pregnancy_core.set_n_pregnancy(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_error   => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            --
            l_women_health_hpg_id := pk_sysconfig.get_config('WOMEN_HEALTH_HPG_ID', i_prof);
        
            BEGIN
                l_health_program := to_number(l_women_health_hpg_id);
            EXCEPTION
                WHEN value_error THEN
                    l_health_program := NULL;
            END;
        
            IF l_health_program IS NOT NULL
            THEN
            
                g_error := 'call pk_list.tf_get_all_inst_group';
                l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                         i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
            
                g_error := 'select * FROM pat_health_program php';
                BEGIN
                    SELECT php.id_pat_health_program, php.flg_status, php.dt_begin_tstz
                      INTO l_id_pat_health_program, l_php_flg_status, l_dt_begin_tstz
                      FROM pat_health_program php
                     WHERE php.id_patient = i_patient
                       AND php.id_health_program = l_health_program
                       AND php.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   t.column_value id_institution
                                                    FROM TABLE(CAST(l_insts AS table_number)) t)
                       AND php.flg_status NOT IN (pk_health_program.g_flg_status_cancelled)
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_pat_health_program := NULL;
                        l_php_flg_status        := NULL;
                END;
            
                IF l_flg_status <> pk_pregnancy_core.g_pat_pregn_active
                   AND l_id_pat_health_program IS NOT NULL
                THEN
                    g_error := 'call pk_health_program.set_pat_hpg';
                    IF NOT pk_health_program.set_pat_hpg(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_patient => i_patient,
                                                         --i_pat_hpg        => l_id_pat_health_program,
                                                         i_health_program => l_health_program,
                                                         i_monitor_loc    => g_flg_mon_inst,
                                                         i_dt_begin       => pk_date_utils.date_send_tsz(i_lang,
                                                                                                         l_dt_begin_tstz,
                                                                                                         i_prof),
                                                         i_dt_end         => nvl(i_dt_intervention,
                                                                                 pk_date_utils.date_send_tsz(i_lang,
                                                                                                             current_timestamp,
                                                                                                             i_prof)),
                                                         i_notes          => NULL,
                                                         i_action         => 'REMOVE',
                                                         i_origin         => pk_alert_constant.g_pregnancy,
                                                         o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                ELSIF (l_php_flg_status IS NULL OR l_php_flg_status = pk_health_program.g_flg_status_inactive)
                      AND l_flg_status = pk_pregnancy_core.g_pat_pregn_active
                
                THEN
                
                    g_error := 'call pk_health_program.set_pat_hpg';
                    IF NOT pk_health_program.set_pat_hpg(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    --i_pat_hpg        => l_id_pat_health_program,
                                                    i_health_program => l_health_program,
                                                    i_monitor_loc    => g_flg_mon_inst,
                                                    i_dt_begin       => pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof),
                                                    i_dt_end         => NULL,
                                                    i_notes          => NULL,
                                                    i_action         => CASE
                                                                            WHEN l_php_flg_status IS NULL THEN
                                                                             'NEW'
                                                                            ELSE
                                                                             'ADD'
                                                                        END,
                                                    i_origin         => pk_alert_constant.g_pregnancy,
                                                    o_error          => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            END IF;
        
            g_error := 'call pk_periodic_observation.set_preg_po_param';
            IF NOT pk_periodic_observation.set_preg_po_param(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_pat_pregnancy => l_id_pat_pregnancy,
                                                             o_error         => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            --
        ELSIF l_n_preg_exists = 1
        THEN
            RAISE l_pregn_exception;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_curr_pregn THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGNANCY',
                                      '',
                                      'WOMAN_HEALTH_M011',
                                      l_curr_pregn,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_pregn_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGNANCY',
                                      '',
                                      'WOMAN_HEALTH_T122',
                                      l_msg_pregn_exc,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_sisprenatal_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGNANCY',
                                      '',
                                      'WOMAN_HEALTH_M011',
                                      l_msg_sisprenatal_exc,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGNANCY',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_PAT_PREGNANCY', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END set_pat_pregnancy;

    /************************************************************************************************************ 
    * Gets the information to be placed on the detail screen
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_doc_area_register           Cursor with the pregnancy info register
    * @param      o_doc_area_val                Cursor containing the completed info for the current pregnancy
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    * @Reviewed by   Gisela Couto
    * @Date      2014/03/07
    ***********************************************************************************************************/
    FUNCTION get_pat_pregnancy_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config_val sys_config.value%TYPE := pk_sysconfig.get_config('NEWBORN_CURR_STATUS_MULTICHOICE', i_prof);
    
        l_sep CONSTANT VARCHAR2(1) := '.';
    
        l_domain_r     CONSTANT sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_TYPE',
                                                                                    pk_pregnancy_core.g_pat_pregn_type_r,
                                                                                    i_lang);
        l_gest_weeks_u CONSTANT sys_domain.desc_val%TYPE := pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_GEST_WEEKS',
                                                                                    pk_pregnancy_core.g_gest_weeks_unknown,
                                                                                    i_lang);
    
        l_label_sisprenantal    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T126'); -- 
        l_label_dt_menstruation CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T127'); --
        l_label_menses          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T128'); --
        l_label_cycle           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T129'); --
        l_label_contracep       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T130'); --
        l_label_contracep_type  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T166'); --
        l_label_dt_contracep    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T131'); --
        l_label_gest_age        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T132'); --
        l_label_gest_reported   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T092'); --
        l_label_edd_lmp         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T133'); --
        l_label_gest_exam       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T148'); --
        l_label_gest_us         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T136'); --
        l_label_edd_us          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T134'); --
        l_label_us_performed    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T164'); --
        l_label_us_at_gest_age  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T165'); --
        l_label_fetus_num       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T078');
        l_label_outcome         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T146'); --
        l_label_compl           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T140'); --
        l_label_interv          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T141'); --
        l_label_dt_birth        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T145'); --
        l_label_notes           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T100');
        l_label_extr            CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T177'); --
        l_label_num_birth       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T179'); --
        l_label_num_ab          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T180'); --
        l_label_num_gest        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T181'); --
    
        l_title_fetus           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T084'); --
        l_title_fetus_ab        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T183'); -- abortion - fetus
        l_label_fetus_status    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T095'); --
        l_label_fetus_ab_status CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T182'); -- label fetus status during abortion
    
        l_label_birth_type   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T144'); --
        l_label_fetus_gender CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T096'); --
        l_label_weight       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T137'); --
        l_label_health       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T143'); --
        l_label_flg_health   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T174');
        l_label_fetus_weight CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T097'); --
    
        l_label_pregnancy CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T021');
    
        l_label_pregn_num CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T091');
    
        l_label_days       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T158');
        l_closed_by_system CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                            i_prof,
                                                                                            'COMMON_M141');
    
        l_label_labour_onset CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              i_prof,
                                                                                              'WOMAN_HEALTH_T147'); --
    
        l_label_labour_duration CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 i_prof,
                                                                                                 'WOMAN_HEALTH_T138'); --                                                                                   
    
        l_outdated CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                    i_prof,
                                                                                    'PAT_PREGNANCY_M008');
    
    BEGIN
    
        g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        OPEN o_epis_doc_register FOR
            SELECT 0 id_epis_documentation,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                   pp.id_professional,
                   CASE
                        WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                         l_closed_by_system
                        ELSE
                         pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional)
                    END nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pp.id_professional,
                                                    pp.dt_pat_pregnancy_tstz,
                                                    pp.id_episode) desc_speciality,
                   NULL id_doc_area,
                   decode(pp.flg_status,
                          pk_pregnancy_core.g_pat_pregn_cancel,
                          pk_pregnancy_core.g_pat_pregn_cancel,
                          pk_pregnancy_core.g_pat_pregn_auto_close,
                          pk_pregnancy_core.g_pat_pregn_auto_close,
                          pk_pregnancy_core.g_pat_pregn_active) flg_status,
                   CASE
                        WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                         l_outdated
                        ELSE
                         pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pp.flg_status, i_lang)
                    END desc_status,
                   NULL notes,
                   l_label_pregn_num || ' ' || pp.n_pregnancy ||
                   decode(pp.flg_type, pk_pregnancy_core.g_pat_pregn_type_r, chr(10) || '(' || l_domain_r || ')', NULL) n_pregnancy
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
            UNION ALL
            SELECT pp.id_pat_pregnancy_hist id_epis_documentation,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                   pp.id_professional,
                   CASE
                       WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                        l_closed_by_system
                       ELSE
                        pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_professional)
                   END nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pp.id_professional,
                                                    pp.dt_pat_pregnancy_tstz,
                                                    pp.id_episode) desc_speciality,
                   NULL id_doc_area,
                   decode(pp.flg_status,
                          pk_pregnancy_core.g_pat_pregn_cancel,
                          pk_pregnancy_core.g_pat_pregn_cancel,
                          pk_pregnancy_core.g_pat_pregn_auto_close,
                          pk_pregnancy_core.g_pat_pregn_auto_close,
                          pk_pregnancy_core.g_pat_pregn_active) flg_status,
                   CASE
                       WHEN pp.flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                        l_outdated
                       ELSE
                        pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pp.flg_status, i_lang)
                   END desc_status,
                   NULL notes,
                   l_label_pregn_num || ' ' ||
                   (SELECT p.n_pregnancy
                      FROM pat_pregnancy p
                     WHERE p.id_pat_pregnancy = i_pat_pregnancy) ||
                   decode((SELECT p.flg_type
                            FROM pat_pregnancy p
                           WHERE p.id_pat_pregnancy = i_pat_pregnancy),
                          pk_pregnancy_core.g_pat_pregn_type_r,
                          chr(10) || '(' || l_domain_r || ')',
                          NULL) n_pregnancy
              FROM pat_pregnancy_hist pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
             ORDER BY dt_last_update DESC;
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        OPEN o_epis_document_val FOR
            SELECT nvl(id_pat_pregnancy_hist, 0) id_epis_documentation,
                   NULL PARENT,
                   0 id_documentation,
                   0 id_doc_component,
                   NULL id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_reg,
                   -- first title
                   pk_utils.to_bold(first_title) desc_doc_component,
                   -- remove the last characters since flash already shows them
                   pregnancy_info desc_element,
                   NULL           VALUE,
                   NULL           id_doc_area,
                   1              rank_component,
                   1              rank_element,
                   NULL           desc_qualification
              FROM (SELECT pp.id_pat_pregnancy,
                            pp.id_pat_pregnancy_hist,
                            pp.dt_pat_pregnancy_tstz,
                            pp.first_title,
                            -- Reported intervention date
                            decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_r,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_dt_birth,
                                                                         pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                               i_prof,
                                                                                                               pp.dt_intervention,
                                                                                                               pp.flg_dt_interv_precision),
                                                                         l_sep,
                                                                         pp.first_title)) ||
                            -- SISPRENATAL
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_sisprenantal,
                                                                  pk_pregnancy_core.get_pat_pregnancy_code(i_lang,
                                                                                                           i_prof,
                                                                                                           pp.id_pat_pregnancy,
                                                                                                           pp.id_pat_pregnancy_hist),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            -- LMP
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_dt_menstruation,
                                                                  pk_date_utils.dt_chr(i_lang, dt_last_menstruation, i_prof),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            -- Menses
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_menses,
                                                                  pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MENSES',
                                                                                          pp.flg_menses,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            -- Cycle duration
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_cycle,
                                                                  nvl2(pp.cycle_duration,
                                                                       pp.cycle_duration || ' ' || l_label_days,
                                                                       NULL),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            -- Contraceptive use
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_contracep,
                                                                  pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_USE_CONSTRACEPTIVES',
                                                                                          pp.flg_use_constraceptives,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            
                            -- Contraceptive type
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_contracep_type,
                                                                  pk_pregnancy_core.get_contraception_type(i_lang,
                                                                                                           i_prof,
                                                                                                           pp.id_pat_pregnancy,
                                                                                                           pp.id_pat_pregnancy_hist),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            
                            -- Last use of contraceptive
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_dt_contracep,
                                                                  pk_pregnancy_core.get_dt_contrac_end(i_lang,
                                                                                                       i_prof,
                                                                                                       pp.dt_contrac_meth_end,
                                                                                                       pp.flg_dt_contrac_precision),
                                                                  l_sep,
                                                                  pp.first_title) ||
                            -- Gestational age by LMP / Gestational age
                             decode(pp.flg_gest_weeks,
                                    pk_pregnancy_core.g_gest_weeks_unknown,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         decode(pp.flg_type,
                                                                                pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                l_label_gest_age,
                                                                                l_label_gest_reported),
                                                                         l_gest_weeks_u,
                                                                         l_sep,
                                                                         pp.first_title),
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         decode(pp.flg_type,
                                                                                pk_pregnancy_core.g_pat_pregn_type_c,
                                                                                l_label_gest_age,
                                                                                l_label_gest_reported),
                                                                         pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                     i_prof,
                                                                                                                     trunc(pp.num_gest_weeks),
                                                                                                                     dt_init_preg_lmp,
                                                                                                                     pp.dt_intervention,
                                                                                                                     pp.flg_status),
                                                                         l_sep,
                                                                         pp.first_title)) ||
                            -- EDD by LMP
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_edd_lmp,
                                                                  pk_date_utils.dt_chr(i_lang, pp.dt_pdel_lmp, i_prof),
                                                                  l_sep,
                                                                  '') ||
                            -- Gestational age by examination
                             decode(pp.flg_gest_weeks_exam,
                                    pk_pregnancy_core.g_gest_weeks_unknown,
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_gest_exam,
                                                                               l_gest_weeks_u,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_exam),
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_gest_exam,
                                                                               nvl2(pp.num_gest_weeks_exam,
                                                                                    pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                i_prof,
                                                                                                                                trunc(pp.num_gest_weeks_exam),
                                                                                                                                pp.dt_init_preg_exam,
                                                                                                                                pp.dt_intervention,
                                                                                                                                pp.flg_status),
                                                                                    NULL),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_exam)) ||
                            -- Gestational age by US
                             decode(pp.flg_gest_weeks_us,
                                    pk_pregnancy_core.g_gest_weeks_unknown,
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_gest_us,
                                                                               l_gest_weeks_u,
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_us),
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_gest_us,
                                                                               nvl2(pp.num_gest_weeks_us,
                                                                                    pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                                i_prof,
                                                                                                                                trunc(pp.num_gest_weeks_us),
                                                                                                                                pp.dt_init_pregnancy,
                                                                                                                                pp.dt_intervention,
                                                                                                                                pp.flg_status),
                                                                                    NULL),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_us)) ||
                            -- EDD by US
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_edd_us,
                                                                  pk_date_utils.dt_chr(i_lang, pp.dt_pdel_correct, i_prof),
                                                                  l_sep,
                                                                  '') ||
                            -- US performed in
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_us_performed,
                                                                  pk_date_utils.dt_chr(i_lang, pp.dt_us_performed, i_prof),
                                                                  l_sep,
                                                                  '') ||
                            -- US performed at gestational age
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_us_at_gest_age,
                                                                  nvl2(pp.dt_us_performed,
                                                                       pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                   i_prof,
                                                                                                                   NULL,
                                                                                                                   pp.dt_init_us_performed,
                                                                                                                   pp.dt_us_performed,
                                                                                                                   pp.flg_status),
                                                                       NULL),
                                                                  l_sep,
                                                                  '') ||
                            -- Number of fetuses
                             pk_pregnancy_core.get_formatted_text(NULL, l_label_fetus_num, pp.n_children, l_sep, '') ||
                            
                            -- Pregnancy outcome
                             decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_r,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_outcome,
                                                                         pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                  pp.flg_status,
                                                                                                                  pp.id_pat_pregnancy,
                                                                                                                  pp.id_pat_pregnancy_hist,
                                                                                                                  pk_pregnancy_core.g_type_summ),
                                                                         l_sep,
                                                                         '')) ||
                            
                            -- Procedure place
                             decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_r,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_interv,
                                                                         pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                 pp.id_inst_intervention,
                                                                                                                 pp.flg_desc_intervention,
                                                                                                                 pp.desc_intervention),
                                                                         l_sep,
                                                                         '')) ||
                            
                            -- Labour onset
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_labour_onset,
                                                                  pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_DEL_ONSET',
                                                                                          pp.flg_del_onset,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  '') ||
                            
                            -- Labour duration                                           
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_labour_duration,
                                                                  CASE
                                                                      WHEN regexp_like(pp.del_duration, '\w\w:\w\w') THEN
                                                                       pp.del_duration || 'h'
                                                                      WHEN regexp_like(pp.del_duration, '\w\w:\w') THEN
                                                                       regexp_replace(pp.del_duration, '\w\w:\w', pp.del_duration || '0h')
                                                                      WHEN regexp_like(pp.del_duration, '\w:\w\w') THEN
                                                                       regexp_replace(pp.del_duration, '\w:\w\w', '0' || pp.del_duration || 'h')
                                                                      WHEN regexp_like(pp.del_duration, '\w:\w') THEN
                                                                       regexp_replace(pp.del_duration, '\w:\w', '0' || pp.del_duration || '0h')
                                                                  END,
                                                                  l_sep,
                                                                  '') ||
                            
                            -- Complications
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_compl,
                                                                        pk_pregnancy_core.get_preg_complications(i_lang,
                                                                                                                 i_prof,
                                                                                                                 pp.flg_complication,
                                                                                                                 pp.notes_complications,
                                                                                                                 pp.id_pat_pregnancy,
                                                                                                                 pp.id_pat_pregnancy_hist),
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        break_compl) ||
                            -- Expulsion
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_extr,
                                                                        pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_EXTRACTION',
                                                                                                pp.flg_extraction,
                                                                                                i_lang),
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        '') ||
                            -- Pregnancy outcome
                             decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_c,
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_outcome,
                                                                               pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                        pp.flg_status,
                                                                                                                        pp.id_pat_pregnancy,
                                                                                                                        pp.id_pat_pregnancy_hist,
                                                                                                                        pk_pregnancy_core.g_type_summ),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_out)) ||
                            --pregnacy outcome type (when expulsion)
                             decode(pp.flg_extraction,
                                    pk_pregnancy_core.g_pat_pregn_extract_y,
                                    pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                               l_label_outcome,
                                                                               pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_PREG_OUT_TYPE',
                                                                                                       pp.flg_preg_out_type,
                                                                                                       i_lang),
                                                                               l_sep,
                                                                               pp.first_title,
                                                                               break_out)) ||
                            -- Procedure place
                             decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_c,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_interv,
                                                                         pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                 pp.id_inst_intervention,
                                                                                                                 pp.flg_desc_intervention,
                                                                                                                 pp.desc_intervention),
                                                                         l_sep,
                                                                         '')) ||
                            -- Intervention date
                             decode(pp.flg_type,
                                    pk_pregnancy_core.g_pat_pregn_type_c,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_dt_birth,
                                                                         pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                               i_prof,
                                                                                                               pp.dt_intervention,
                                                                                                               pp.flg_dt_interv_precision),
                                                                         l_sep,
                                                                         pp.first_title)) ||
                            -- pregnancy summary    
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_num_birth,
                                                                        pp.num_births,
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        '') ||
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_num_ab,
                                                                        pp.num_abortions,
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        '') ||
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_num_gest,
                                                                        pp.num_gestations,
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        '') ||
                            -- Notes
                             pk_pregnancy_core.get_formatted_text_break(NULL,
                                                                        l_label_notes,
                                                                        pp.notes,
                                                                        l_sep,
                                                                        pp.first_title,
                                                                        break_notes) pregnancy_info
                       FROM (SELECT id_pat_pregnancy,
                                     NULL id_pat_pregnancy_hist,
                                     flg_type,
                                     flg_status,
                                     num_gest_weeks,
                                     dt_pat_pregnancy_tstz,
                                     dt_last_menstruation,
                                     flg_menses,
                                     cycle_duration,
                                     flg_use_constraceptives,
                                     dt_contrac_meth_end,
                                     flg_dt_contrac_precision,
                                     dt_intervention,
                                     dt_pdel_lmp,
                                     num_gest_weeks_exam,
                                     dt_init_preg_exam,
                                     dt_init_preg_lmp,
                                     num_gest_weeks_us,
                                     dt_init_pregnancy,
                                     dt_init_pregnancy dt_init_us_performed,
                                     dt_pdel_correct,
                                     dt_us_performed,
                                     pregn.flg_del_onset,
                                     pregn.del_duration,
                                     n_children,
                                     flg_complication,
                                     notes_complications,
                                     notes,
                                     flg_dt_interv_precision,
                                     id_inst_intervention,
                                     flg_desc_intervention,
                                     desc_intervention,
                                     pregn.flg_extraction,
                                     pregn.flg_preg_out_type,
                                     pregn.num_births,
                                     pregn.num_abortions,
                                     pregn.num_gestations,
                                     pregn.flg_gest_weeks,
                                     pregn.flg_gest_weeks_exam,
                                     pregn.flg_gest_weeks_us,
                                     pk_pregnancy_core.get_summ_page_first_title(i_lang,
                                                                                 i_prof,
                                                                                 pregn.id_pat_pregnancy,
                                                                                 NULL,
                                                                                 pregn.flg_type) first_title,
                                     pk_pregnancy_core.check_break_summ_pg_exam(i_lang,
                                                                                i_prof,
                                                                                flg_type,
                                                                                num_gest_weeks_exam) break_exam,
                                     pk_pregnancy_core.check_break_summ_pg_us(i_lang,
                                                                              i_prof,
                                                                              flg_type,
                                                                              num_gest_weeks_us,
                                                                              dt_pdel_correct,
                                                                              dt_us_performed,
                                                                              n_children) break_us,
                                     pk_pregnancy_core.check_break_summ_pg_compl(i_lang,
                                                                                 i_prof,
                                                                                 flg_type,
                                                                                 id_pat_pregnancy,
                                                                                 NULL,
                                                                                 flg_complication,
                                                                                 notes_complications) break_compl,
                                     pk_pregnancy_core.check_break_summ_pg_out(i_lang,
                                                                               i_prof,
                                                                               flg_type,
                                                                               id_pat_pregnancy,
                                                                               flg_status,
                                                                               dt_intervention,
                                                                               id_inst_intervention,
                                                                               flg_desc_intervention,
                                                                               desc_intervention) break_out,
                                     pk_pregnancy_core.check_break_summ_pg_notes(i_lang, i_prof, flg_type, notes) break_notes
                                FROM pat_pregnancy pregn
                               WHERE id_pat_pregnancy = i_pat_pregnancy
                              UNION ALL
                              SELECT pph.id_pat_pregnancy,
                                     pph.id_pat_pregnancy_hist,
                                     p.flg_type,
                                     pph.flg_status,
                                     pph.num_gest_weeks,
                                     pph.dt_pat_pregnancy_tstz,
                                     pph.dt_last_menstruation,
                                     pph.flg_menses,
                                     pph.cycle_duration,
                                     pph.flg_use_constraceptives,
                                     pph.dt_contrac_meth_end,
                                     pph.flg_dt_contrac_precision,
                                     pph.dt_intervention,
                                     pph.dt_pdel_lmp,
                                     pph.num_gest_weeks_exam,
                                     -- Previous records shouldn't continue to count the gestational age
                                   nvl2(pph.dt_intervention, pph.dt_init_preg_exam, NULL) dt_init_preg_exam,
                                   nvl2(pph.dt_intervention, pph.dt_init_preg_lmp, NULL) dt_init_preg_lmp,
                                   pph.num_gest_weeks_us,
                                   nvl2(pph.dt_intervention, pph.dt_init_pregnancy, NULL) dt_init_pregnancy,
                                   pph.dt_init_pregnancy dt_init_us_performed,
                                   pph.dt_pdel_correct,
                                   pph.dt_us_performed,
                                   pph.flg_del_onset,
                                   pph.del_duration,
                                   pph.n_children,
                                   pph.flg_complication,
                                   pph.notes_complications,
                                   pph.notes,
                                   pph.flg_dt_interv_precision,
                                   pph.id_inst_intervention,
                                   pph.flg_desc_intervention,
                                   pph.desc_intervention,
                                   pph.flg_extraction,
                                   pph.flg_preg_out_type,
                                   pph.num_births,
                                   pph.num_abortions,
                                   pph.num_gestations,
                                   pph.flg_gest_weeks,
                                   pph.flg_gest_weeks_exam,
                                   pph.flg_gest_weeks_us,
                                   pk_pregnancy_core.get_summ_page_first_title(i_lang,
                                                                               i_prof,
                                                                               pph.id_pat_pregnancy,
                                                                               pph.id_pat_pregnancy_hist,
                                                                               p.flg_type) first_title,
                                   pk_pregnancy_core.check_break_summ_pg_exam(i_lang,
                                                                              i_prof,
                                                                              p.flg_type,
                                                                              pph.num_gest_weeks_exam) break_exam,
                                   pk_pregnancy_core.check_break_summ_pg_us(i_lang,
                                                                            i_prof,
                                                                            p.flg_type,
                                                                            pph.num_gest_weeks_us,
                                                                            pph.dt_pdel_correct,
                                                                            pph.dt_us_performed,
                                                                            pph.n_children) break_us,
                                   pk_pregnancy_core.check_break_summ_pg_compl(i_lang,
                                                                               i_prof,
                                                                               p.flg_type,
                                                                               pph.id_pat_pregnancy,
                                                                               pph.id_pat_pregnancy_hist,
                                                                               pph.flg_complication,
                                                                               pph.notes_complications) break_compl,
                                   pk_pregnancy_core.check_break_summ_pg_out(i_lang,
                                                                             i_prof,
                                                                             p.flg_type,
                                                                             pph.id_pat_pregnancy,
                                                                             pph.flg_status,
                                                                             pph.dt_intervention,
                                                                             pph.id_inst_intervention,
                                                                             pph.flg_desc_intervention,
                                                                             pph.desc_intervention) break_out,
                                   pk_pregnancy_core.check_break_summ_pg_notes(i_lang, i_prof, p.flg_type, pph.notes) break_notes
                              FROM pat_pregnancy_hist pph
                              JOIN pat_pregnancy p
                                ON p.id_pat_pregnancy = pph.id_pat_pregnancy
                             WHERE pph.id_pat_pregnancy = i_pat_pregnancy) pp)
            UNION ALL
            SELECT DISTINCT 0 id_epis_documentation,
                            NULL PARENT,
                            ppf.id_pat_pregn_fetus id_documentation,
                            ppf.id_pat_pregn_fetus id_doc_component,
                            NULL id_doc_element_crit,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_reg,
                            -- TITULO
                            pk_utils.to_bold(decode(flg_preg_out_type,
                                                    pk_pregnancy_core.g_pat_pregn_type_ab,
                                                    l_title_fetus_ab,
                                                    l_title_fetus) || ' ' || ppf.fetus_number) desc_doc_component,
                            chr(10) ||
                            -- estado
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  decode(flg_preg_out_type,
                                                                         pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                         l_label_fetus_ab_status,
                                                                         l_label_fetus_status),
                                                                  pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_STATUS',
                                                                                          ppf.flg_status,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  '') ||
                            --tipo de parto
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_birth_type,
                                                                  pk_sysdomain.get_domain_no_avail('PAT_PREGN_FETUS.FLG_CHILDBIRTH_TYPE',
                                                                                                   ppf.flg_childbirth_type,
                                                                                                   i_lang),
                                                                  l_sep,
                                                                  '') ||
                            -- sexo
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_fetus_gender,
                                                                  pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_GENDER',
                                                                                          ppf.flg_gender,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  '') ||
                            -- peso
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  decode(flg_preg_out_type,
                                                                         pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                         l_label_fetus_weight,
                                                                         l_label_weight),
                                                                  decode(ppf.weight,
                                                                         NULL,
                                                                         NULL,
                                                                         ppf.weight || ' ' ||
                                                                         pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                                                                      i_prof,
                                                                                                                      ppf.id_unit_measure)),
                                                                  l_sep,
                                                                  '') ||
                             decode(l_config_val,
                                    pk_alert_constant.g_no,
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_health,
                                                                         ppf.present_health,
                                                                         l_sep,
                                                                         ''),
                                    pk_pregnancy_core.get_formatted_text(NULL,
                                                                         l_label_flg_health,
                                                                         pk_sysdomain.get_domain('PAT_PREGN_FETUS.CURRENT_STATUS',
                                                                                                 ppf.flg_present_health,
                                                                                                 i_lang),
                                                                         l_sep,
                                                                         ''))
                            
                             desc_element,
                            NULL VALUE,
                            NULL id_doc_area,
                            1 rank_component,
                            1 rank_element,
                            NULL desc_qualification
              FROM pat_pregn_fetus ppf, pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND ppf.id_pat_pregnancy = pp.id_pat_pregnancy
               AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                   instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                   ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
            UNION ALL
            SELECT DISTINCT ppf.id_pat_pregnancy_hist id_epis_documentation,
                            NULL PARENT,
                            ppf.id_pat_pregn_fetus id_documentation,
                            ppf.id_pat_pregn_fetus id_doc_component,
                            NULL id_doc_element_crit,
                            pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_reg,
                            -- TITULO
                            pk_utils.to_bold(decode(flg_preg_out_type,
                                                    pk_pregnancy_core.g_pat_pregn_type_ab,
                                                    l_title_fetus_ab,
                                                    l_title_fetus) || ' ' || ppf.fetus_number) desc_doc_component,
                            chr(10) ||
                            -- estado
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  decode(flg_preg_out_type,
                                                                         pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                         l_label_fetus_ab_status,
                                                                         l_label_fetus_status),
                                                                  pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_STATUS',
                                                                                          ppf.flg_status,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  '') ||
                            --tipo de parto
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_birth_type,
                                                                  pk_sysdomain.get_domain_no_avail('PAT_PREGN_FETUS.FLG_CHILDBIRTH_TYPE',
                                                                                                   ppf.flg_childbirth_type,
                                                                                                   i_lang),
                                                                  l_sep,
                                                                  '') ||
                            -- sexo
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  l_label_fetus_gender,
                                                                  pk_sysdomain.get_domain('PAT_PREGN_FETUS.FLG_GENDER',
                                                                                          ppf.flg_gender,
                                                                                          i_lang),
                                                                  l_sep,
                                                                  '') ||
                            -- peso
                             pk_pregnancy_core.get_formatted_text(NULL,
                                                                  decode(flg_preg_out_type,
                                                                         pk_pregnancy_core.g_pat_pregn_type_ab,
                                                                         l_label_fetus_weight,
                                                                         l_label_weight),
                                                                  decode(ppf.weight,
                                                                         NULL,
                                                                         NULL,
                                                                         ppf.weight || ' ' ||
                                                                         pk_pregnancy_core.get_preg_summ_unit_measure(i_lang,
                                                                                                                      i_prof,
                                                                                                                      ppf.id_unit_measure)),
                                                                  l_sep,
                                                                  '') desc_element,
                            NULL VALUE,
                            NULL id_doc_area,
                            1 rank_component,
                            1 rank_element,
                            NULL desc_qualification
              FROM pat_pregnancy_hist pp, pat_pregn_fetus_hist ppf
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND ppf.id_pat_pregnancy_hist = pp.id_pat_pregnancy_hist
               AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                   instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                   ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
             ORDER BY id_epis_documentation, id_doc_component;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
            RETURN error_handling_ext(i_lang, 'GET_PAT_PREGNANCY_DET', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_pat_pregnancy_det;

    /************************************************************************************************************ 
    * Saves the blood group information
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_episode                     episode ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_blood_type_mother           mother's blood group
    * @param      i_blood_type_father           father's blood group
    * @param      i_flg_antigl_aft_chb          AntiD (after all births)
    * @param      i_flg_antigl_aft_abb          AntiD (after all abortions)
    * @param      i_flg_antigl_need             AntiD need
    * @param      
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_rh
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_blood_type_mother  IN VARCHAR2,
        i_blood_type_father  IN VARCHAR2,
        i_flg_antigl_aft_chb IN pat_pregnancy.flg_antigl_aft_chb%TYPE,
        i_flg_antigl_aft_abb IN pat_pregnancy.flg_antigl_aft_abb%TYPE,
        i_flg_antigl_need    IN pat_pregnancy.flg_antigl_need%TYPE,
        i_titration_value    IN pat_pregnancy.titration_value%TYPE,
        i_flg_antibody       IN pat_pregnancy.flg_antibody%TYPE,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_blood_mother_rh VARCHAR2(2);
        l_blood_mother_gr VARCHAR2(2);
        l_blood_rh        VARCHAR2(2);
        l_blood_gr        VARCHAR2(2);
        l_blood_father_rh VARCHAR2(2);
        l_blood_father_gr VARCHAR2(2);
    
        l_id_prof_rh pat_pregnancy.id_prof_rh%TYPE;
    
        CURSOR c1 IS
            SELECT flg_blood_group, flg_blood_rhesus
              FROM pat_blood_group
             WHERE id_patient = i_patient
               AND flg_status = 'A';
    
        l_rowids_1 table_varchar;
        e_process_event EXCEPTION;
    
        l_exception EXCEPTION;
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET BLOOD TYPE FATHER';
        IF i_blood_type_father IS NOT NULL
        THEN
            IF substr(i_blood_type_father, 0, 1) = '+'
            THEN
                l_blood_father_rh := 'P';
            ELSE
                l_blood_father_rh := 'N';
            END IF;
        END IF;
    
        g_error := 'GET BLOOD TYPE MOTHER';
        IF i_blood_type_mother IS NOT NULL
        THEN
        
            IF substr(i_blood_type_mother, 0, 1) = '+'
            THEN
                l_blood_mother_rh := 'P';
            ELSE
                l_blood_mother_rh := 'N';
            END IF;
        END IF;
    
        g_error := 'SELECT ON BLOOD';
        OPEN c1;
        FETCH c1
            INTO l_blood_gr, l_blood_rh;
        CLOSE c1;
    
        g_error           := 'REPLACE';
        l_blood_father_gr := REPLACE(i_blood_type_father, substr(i_blood_type_father, 0, 1));
        l_blood_mother_gr := REPLACE(i_blood_type_mother, substr(i_blood_type_mother, 0, 1));
    
        g_error := 'CHECH PREGNANCY RH INFO';
        SELECT id_prof_rh
          INTO l_id_prof_rh
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        IF l_id_prof_rh IS NOT NULL
        THEN
            g_error := 'SET RH HIST';
            IF NOT set_pat_pregnancy_rh_hist(i_lang, i_pat_pregnancy, l_blood_gr, l_blood_rh, l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_blood_mother_rh IS NOT NULL
           AND ((l_blood_mother_gr <> nvl(l_blood_gr, 'X')) OR (l_blood_mother_rh <> nvl(l_blood_rh, 'X')))
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
                                            l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'UPDATE PAT PREGNANCY';
        ts_pat_pregnancy.upd(id_pat_pregnancy_in     => i_pat_pregnancy,
                             blood_group_father_in   => l_blood_father_gr,
                             blood_group_father_nin  => FALSE,
                             blood_rhesus_father_in  => l_blood_father_rh,
                             blood_rhesus_father_nin => FALSE,
                             flg_antigl_aft_chb_in   => i_flg_antigl_aft_chb,
                             flg_antigl_aft_chb_nin  => FALSE,
                             flg_antigl_aft_abb_in   => i_flg_antigl_aft_abb,
                             flg_antigl_aft_abb_nin  => FALSE,
                             flg_antigl_need_in      => i_flg_antigl_need,
                             flg_antigl_need_nin     => FALSE,
                             titration_value_in      => i_titration_value,
                             titration_value_nin     => FALSE,
                             flg_antibody_in         => i_flg_antibody,
                             flg_antibody_nin        => FALSE,
                             id_prof_rh_in           => i_prof.id,
                             dt_reg_rh_in            => current_timestamp,
                             id_episode_rh_in        => i_episode,
                             rows_out                => l_rowids_1);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PREGNANCY',
                                      i_rowids     => l_rowids_1,
                                      o_error      => l_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => current_timestamp,
                                      i_dt_first_obs        => current_timestamp,
                                      o_error               => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGNANCY_RH',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_PAT_PREGNANCY_RH', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END set_pat_pregnancy_rh;

    /************************************************************************************************************ 
    * Gets the pregnancy RH summary page
    *
    * @param      i_lang                        default language
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_pat_preg_rh                 pregnancy RH info
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION get_pregn_rh_summ_page
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_pat_preg_rh   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_rh CONSTANT sys_domain.code_domain%TYPE := 'WOMAN_HEALTH.BLOOD_TYPE';
    
    BEGIN
    
        g_error := 'GET CURSOR O_PAT_PREG_RH';
        OPEN o_pat_preg_rh FOR
            SELECT decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') || pbg.flg_blood_group blood_type_mother_val,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') ||
                                           pbg.flg_blood_group),
                                           i_lang) blood_type_mother_desc_val,
                   decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') || pp.blood_group_father blood_type_father_val,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') ||
                                           pp.blood_group_father),
                                           i_lang) blood_type_father_desc_val,
                   --
                   flg_antigl_aft_chb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   --
                   flg_antigl_aft_abb,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   --
                   flg_antigl_need,
                   nvl(pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_NEED', flg_antigl_need, i_lang),
                       pk_pregnancy_core.get_antigl_need_na(i_lang, pp.blood_rhesus_father, pbg.flg_blood_rhesus)) flg_antigl_need_desc_val,
                   --
                   pp.titration_value flg_titration_desc_val,
                   --
                   pp.flg_antibody,
                   pk_sysdomain.get_domain_no_avail('WOMAN_HEALTH.FLG_ANTIBODY', flg_antibody, i_lang) flg_antibody_desc_val,
                   --
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_register,
                   nvl(pp.id_prof_rh, pbg.id_professional) id_prof_rh,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pp.id_prof_rh, pbg.id_professional)) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(pp.id_prof_rh, pbg.id_professional),
                                                    nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz),
                                                    nvl(pp.id_episode_rh, pbg.id_episode)) spec_reg
            
            --            
              FROM pat_pregnancy pp, pat_blood_group pbg
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND pp.id_patient = pbg.id_patient(+)
               AND pbg.flg_status(+) = pk_pregnancy_core.g_pbg_active
               AND (pbg.flg_blood_group IS NOT NULL OR pbg.flg_blood_group IS NOT NULL OR
                   pp.blood_group_father IS NOT NULL OR flg_antigl_aft_chb IS NOT NULL OR
                   flg_antigl_aft_abb IS NOT NULL OR flg_antigl_need IS NOT NULL OR pp.titration_value IS NOT NULL OR
                   pp.flg_antibody IS NOT NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_preg_rh);
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGN_RH_SUMM_PAGE',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_pregn_rh_summ_page;

    /************************************************************************************************************ 
    * Gets the pregnancy RH detail
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_patient                     patient´s ID
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_pat_preg_rh_reg             Cursor with the pregnancy RH info register
    * @param      o_pat_preg_rh_val             Cursor containing the completed RH info for the current pregnancy
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/
    FUNCTION get_pregn_rh_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_pat_preg_rh_reg OUT pk_types.cursor_type,
        o_pat_preg_rh_val OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_domain_rh CONSTANT sys_domain.code_domain%TYPE := 'WOMAN_HEALTH.BLOOD_TYPE';
    
    BEGIN
    
        g_error := 'GET CURSOR O_PAT_PREG_RH_REG';
        OPEN o_pat_preg_rh_reg FOR
            SELECT 0 id_reg,
                   pk_date_utils.date_send_tsz(i_lang, nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz), i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz), i_prof) dt_last_update,
                   nvl(pp.id_prof_rh, pbg.id_professional) id_prof_rh,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(pp.id_prof_rh, pbg.id_professional)) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    nvl(pp.id_prof_rh, pbg.id_professional),
                                                    nvl(pp.dt_reg_rh, pbg.dt_pat_blood_group_tstz),
                                                    nvl(pp.id_episode_rh, pbg.id_episode)) desc_speciality,
                   NULL id_doc_area,
                   pk_pregnancy_core.g_pat_pregn_active flg_status,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pk_pregnancy_core.g_pat_pregn_active, i_lang) desc_status,
                   NULL notes
              FROM pat_pregnancy pp, pat_blood_group pbg
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND (pp.id_prof_rh IS NOT NULL OR pbg.id_pat_blood_group IS NOT NULL)
               AND pp.id_patient = pbg.id_patient(+)
               AND pbg.flg_status(+) = pk_pregnancy_core.g_pbg_active
            UNION ALL
            SELECT pp.id_pat_pregnancy_rh_hist id_reg,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_reg_rh, i_prof) dt_creation,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_reg_rh, i_prof.institution, i_prof.software) dt_register,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_reg_rh, i_prof) dt_last_update,
                   pp.id_prof_rh,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_prof_rh) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, pp.id_prof_rh, pp.dt_reg_rh, pp.id_episode_rh) desc_speciality,
                   NULL id_doc_area,
                   pk_pregnancy_core.g_pat_pregn_active flg_status,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', pk_pregnancy_core.g_pat_pregn_active, i_lang) desc_status,
                   NULL notes
              FROM pat_pregnancy_rh_hist pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        g_error := 'GET CURSOR O_PAT_PREG_RH_VAL';
        OPEN o_pat_preg_rh_val FOR
            SELECT 0 id_reg,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pbg.flg_blood_rhesus, NULL, NULL, 'P', '+', '-') ||
                                           pbg.flg_blood_group),
                                           i_lang) blood_type_mother_desc_val,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') ||
                                           pp.blood_group_father),
                                           i_lang) blood_type_father_desc_val,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   nvl(pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_NEED', flg_antigl_need, i_lang),
                       pk_pregnancy_core.get_antigl_need_na(i_lang, pp.blood_rhesus_father, pbg.flg_blood_rhesus)) flg_antigl_need_desc_val,
                   titration_value flg_titration_desc_val,
                   pk_sysdomain.get_domain_no_avail('WOMAN_HEALTH.FLG_ANTIBODY', flg_antibody, i_lang) flg_antibody_desc_val,
                   -- 
                   pp.dt_reg_rh
              FROM pat_pregnancy pp, pat_blood_group pbg
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
               AND (pp.id_prof_rh IS NOT NULL OR pbg.id_pat_blood_group IS NOT NULL)
               AND pp.id_patient = pbg.id_patient(+)
               AND pbg.flg_status(+) = pk_pregnancy_core.g_pbg_active
            UNION ALL
            SELECT pp.id_pat_pregnancy_rh_hist id_reg,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pp.blood_rhesus_mother, NULL, NULL, 'P', '+', '-') ||
                                           pp.blood_group_mother),
                                           i_lang) blood_type_mother_desc_val,
                   pk_sysdomain.get_domain(l_domain_rh,
                                           (decode(pp.blood_rhesus_father, NULL, NULL, 'P', '+', '-') ||
                                           pp.blood_group_father),
                                           i_lang) blood_type_father_desc_val,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_CHB', flg_antigl_aft_chb, i_lang) flg_antigl_aft_chb_desc_val,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_AFT_ABB', flg_antigl_aft_abb, i_lang) flg_antigl_aft_abb_desc_val,
                   nvl(pk_sysdomain.get_domain('WOMAN_HEALTH.FLG_ANTIGL_NEED', flg_antigl_need, i_lang),
                       pk_pregnancy_core.get_antigl_need_na(i_lang, pp.blood_rhesus_father, pp.blood_rhesus_mother)) flg_antigl_need_desc_val,
                   titration_value flg_titration_desc_val,
                   pk_sysdomain.get_domain_no_avail('WOMAN_HEALTH.FLG_ANTIBODY', flg_antibody, i_lang) flg_antibody_desc_val,
                   --
                   pp.dt_reg_rh
              FROM pat_pregnancy_rh_hist pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy
             ORDER BY dt_reg_rh DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_pat_preg_rh_reg);
            pk_types.open_my_cursor(o_pat_preg_rh_val);
            RETURN error_handling_ext(i_lang, 'GET_PREGN_RH_DET', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_pregn_rh_det;

    /************************************************************************************************************ 
    * Sets the pregnancy fetus info
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_n_children                  Total number of fetus
    * @param      i_fetus_number                Single fetus idetifier number
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_flg_child_weight            list of child weight (one per children)   
    * @param      i_weight_um                   weight unit measure
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/01
    ***********************************************************************************************************/
    FUNCTION set_pat_pregn_fetus
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_n_children          IN pat_pregnancy.n_children%TYPE,
        i_fetus_number        IN NUMBER,
        i_flg_type            IN VARCHAR2,
        i_flg_child_gender    IN table_varchar,
        i_flg_childbirth_type IN table_varchar,
        i_flg_child_status    IN table_varchar,
        i_flg_child_weight    IN table_number,
        i_weight_um           IN table_varchar,
        i_present_health      IN table_varchar,
        i_flg_present_health  IN table_varchar,
        o_id_pat_pregn_fetus  OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_fetus_number NUMBER;
        l_child_config      CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('EXISTS_PARTOGRAM', i_prof);
        l_fetus_info_config CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('FETUS_INFO_VISIBLE', i_prof);
    
        l_flg_g      VARCHAR2(1);
        l_flg_c_st   VARCHAR2(1);
        l_flg_bt     VARCHAR2(1);
        l_flg_weight VARCHAR2(1);
    
        l_flg_gender         pat_pregn_fetus.flg_gender%TYPE;
        l_flg_child_status   pat_pregn_fetus.flg_status%TYPE;
        l_flg_birth_type     pat_pregn_fetus.flg_childbirth_type%TYPE;
        l_weight             pat_pregn_fetus.weight%TYPE;
        l_weight_um          pat_pregn_fetus.id_unit_measure%TYPE;
        l_present_health     pat_pregn_fetus.present_health%TYPE;
        l_flg_present_health pat_pregn_fetus.flg_present_health%TYPE;
    
        l_rows            table_varchar := table_varchar();
        l_pregn_fetus_unk pat_pregn_fetus.flg_status%TYPE;
    
    BEGIN
    
        g_error := 'UPDATE PAT_PREGN_FETUS';
        SELECT nvl(MAX(ppf.fetus_number), 0)
          INTO l_fetus_number
          FROM pat_pregn_fetus ppf
         WHERE ppf.id_pat_pregnancy = i_pat_pregnancy;
    
        IF i_n_children IS NOT NULL
        THEN
        
            FOR i IN 1 .. i_n_children
            LOOP
                IF i_flg_child_gender.count = 0
                   OR i_flg_child_gender(i) IS NULL
                THEN
                    l_flg_gender := NULL;
                ELSE
                    l_flg_gender      := i_flg_child_gender(i);
                    l_pregn_fetus_unk := pk_pregnancy_core.g_pregn_fetus_unk;
                END IF;
            
                IF i_flg_child_weight.count = 0
                   OR i_flg_child_weight(i) IS NULL
                THEN
                    l_weight    := NULL;
                    l_weight_um := NULL;
                ELSE
                    l_weight          := i_flg_child_weight(i);
                    l_weight_um       := i_weight_um(i);
                    l_pregn_fetus_unk := pk_pregnancy_core.g_pregn_fetus_unk;
                END IF;
            
                IF i_present_health.count = 0
                   OR i_present_health(i) IS NULL
                THEN
                    l_present_health := NULL;
                ELSE
                    l_present_health  := i_present_health(i);
                    l_pregn_fetus_unk := pk_pregnancy_core.g_pregn_fetus_unk;
                END IF;
            
                IF i_flg_present_health.count = 0
                   OR i_flg_present_health(i) IS NULL
                THEN
                    l_flg_present_health := NULL;
                ELSE
                    l_flg_present_health := i_flg_present_health(i);
                    l_pregn_fetus_unk    := pk_pregnancy_core.g_pregn_fetus_unk;
                END IF;
            
                IF i_flg_child_status.count = 0
                THEN
                    l_flg_child_status := NULL;
                ELSE
                    l_flg_child_status := i_flg_child_status(i);
                END IF;
            
                IF i_flg_childbirth_type.count = 0
                   OR i_flg_childbirth_type(i) IS NULL
                THEN
                    l_flg_birth_type := NULL;
                ELSE
                    l_flg_birth_type  := i_flg_childbirth_type(i);
                    l_pregn_fetus_unk := pk_pregnancy_core.g_pregn_fetus_unk;
                END IF;
            
                IF i > l_fetus_number
                THEN
                    g_error := 'INSERT INTO PAT_PREGN_FETUS ' || i;
                    INSERT INTO pat_pregn_fetus
                        (id_pat_pregn_fetus,
                         id_pat_pregnancy,
                         flg_gender,
                         fetus_number,
                         flg_childbirth_type,
                         flg_status,
                         weight,
                         id_unit_measure,
                         present_health,
                         flg_present_health)
                    VALUES
                        (seq_pat_pregn_fetus.nextval,
                         i_pat_pregnancy,
                         l_flg_gender,
                         i,
                         l_flg_birth_type,
                         nvl(l_flg_child_status, l_pregn_fetus_unk),
                         l_weight,
                         l_weight_um,
                         l_present_health,
                         l_flg_present_health);
                
                ELSIF l_child_config = g_no
                      OR i_flg_type = pk_pregnancy_core.g_pat_pregn_type_r
                      OR l_fetus_info_config = g_yes
                THEN
                    g_error := 'UPDATE PAT_PREGN_FETUS ' || i;
                    UPDATE pat_pregn_fetus p
                       SET p.flg_gender          = l_flg_gender,
                           p.flg_childbirth_type = l_flg_birth_type,
                           p.flg_status          = nvl(l_flg_child_status, l_pregn_fetus_unk),
                           p.weight              = l_weight,
                           p.id_unit_measure     = l_weight_um,
                           p.present_health      = l_present_health,
                           p.flg_present_health  = l_flg_present_health
                     WHERE p.id_pat_pregnancy = i_pat_pregnancy
                       AND p.fetus_number = i;
                    -- pregnancy was closed by an ultrasound request
                ELSIF i_flg_child_gender.count = 0
                      AND i_flg_child_weight.count = 0
                THEN
                    g_error := 'UPDATE PAT_PREGN_FETUS ' || i;
                    UPDATE pat_pregn_fetus p
                       SET p.flg_childbirth_type = nvl(l_flg_birth_type, p.flg_childbirth_type),
                           p.flg_status          = nvl(p.flg_status, l_flg_child_status)
                     WHERE p.id_pat_pregnancy = i_pat_pregnancy
                       AND p.fetus_number = i;
                END IF;
            END LOOP;
        
            FOR i IN (i_n_children + 1) .. l_fetus_number
            LOOP
                g_error := 'CANCEL PAT_PREGN_FETUS ' || i;
                UPDATE pat_pregn_fetus p
                   SET p.flg_status = pk_pregnancy_core.g_pregn_fetus_cancel
                 WHERE p.id_pat_pregnancy = i_pat_pregnancy
                   AND p.fetus_number = i;
            END LOOP;
        
        ELSE
        
            g_error := 'GET INSERT/UPDATE VALUES';
            IF i_flg_child_gender IS NOT NULL
            THEN
                l_flg_g      := 'Y';
                l_flg_gender := i_flg_child_gender(1);
            END IF;
            IF i_flg_childbirth_type IS NOT NULL
            THEN
                l_flg_bt         := 'Y';
                l_flg_birth_type := i_flg_childbirth_type(1);
            END IF;
            IF i_flg_child_status IS NOT NULL
            THEN
                l_flg_c_st         := 'Y';
                l_flg_child_status := i_flg_child_status(1);
            END IF;
            IF i_flg_child_weight IS NOT NULL
            THEN
                l_flg_weight := 'Y';
                l_weight     := i_flg_child_weight(1);
                l_weight_um  := i_weight_um(1);
            END IF;
        
            -- fetus information was filled using the labor and delivery assessment or the ultrasound result
            IF i_fetus_number > l_fetus_number
            THEN
                l_fetus_number := greatest(l_fetus_number, 1);
            
                FOR i IN l_fetus_number .. i_fetus_number - 1
                LOOP
                    BEGIN
                        SELECT p.id_pat_pregn_fetus
                          INTO o_id_pat_pregn_fetus
                          FROM pat_pregn_fetus p
                         WHERE p.id_pat_pregnancy = i_pat_pregnancy
                           AND p.fetus_number = i;
                    EXCEPTION
                        WHEN no_data_found THEN
                            INSERT INTO pat_pregn_fetus
                                (id_pat_pregn_fetus,
                                 id_pat_pregnancy,
                                 flg_gender,
                                 fetus_number,
                                 flg_childbirth_type,
                                 flg_status,
                                 weight,
                                 id_unit_measure,
                                 present_health)
                            VALUES
                                (seq_pat_pregn_fetus.nextval, i_pat_pregnancy, NULL, i, NULL, NULL, NULL, NULL, NULL);
                    END;
                END LOOP;
            
                g_error := 'INSERT INTO PAT_PREGN_FETUS ' || i_fetus_number;
                INSERT INTO pat_pregn_fetus
                    (id_pat_pregn_fetus,
                     id_pat_pregnancy,
                     flg_gender,
                     fetus_number,
                     flg_childbirth_type,
                     flg_status,
                     weight,
                     id_unit_measure)
                VALUES
                    (seq_pat_pregn_fetus.nextval,
                     i_pat_pregnancy,
                     l_flg_gender,
                     i_fetus_number,
                     l_flg_birth_type,
                     l_flg_child_status,
                     l_weight,
                     l_weight_um)
                RETURNING id_pat_pregn_fetus INTO o_id_pat_pregn_fetus;
            ELSE
                SELECT p.id_pat_pregn_fetus
                  INTO o_id_pat_pregn_fetus
                  FROM pat_pregn_fetus p
                 WHERE p.id_pat_pregnancy = i_pat_pregnancy
                   AND p.fetus_number = i_fetus_number;
            
                g_error := 'UPDATE PAT_PREGN_FETUS';
                UPDATE pat_pregn_fetus p
                   SET p.flg_gender          = decode(l_flg_g, 'Y', l_flg_gender, p.flg_gender),
                       p.flg_childbirth_type = decode(l_flg_bt, 'Y', l_flg_birth_type, p.flg_childbirth_type),
                       p.flg_status          = decode(l_flg_c_st, 'Y', l_flg_child_status, p.flg_status),
                       p.weight              = decode(l_flg_weight, 'Y', l_weight, p.weight),
                       p.id_unit_measure     = decode(l_flg_weight, 'Y', l_weight_um, p.id_unit_measure)
                 WHERE p.id_pat_pregnancy = i_pat_pregnancy
                   AND p.fetus_number = i_fetus_number;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_PAT_PREGN_FETUS', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END set_pat_pregn_fetus;

    /************************************************************************************************************ 
    * Gets all keypad labels and the pregnancy number to be used in the creation screen
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_patient                     patient´s ID
    * @param      o_weeks_measure               Keypad label (weeks)
    * @param      o_weight_measure               Keypad label (weight)    
    * @param      o_num_pregnancy               Pregnancy number
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/06/03
    ***********************************************************************************************************/
    FUNCTION get_pregn_create_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_flg_type        IN pat_pregnancy.flg_type%TYPE,
        o_weeks_measure   OUT VARCHAR2,
        o_weight_measure  OUT pk_types.cursor_type,
        o_input_format    OUT pk_types.cursor_type,
        o_num_pregnancy   OUT NUMBER,
        o_weeks_min_fetus OUT NUMBER,
        o_pregn_summ      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error         := 'GET DESC MEASURES';
        o_weeks_measure := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T001');
        IF NOT pk_pregnancy_core.get_preg_summ_unit_measure(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            o_unit_measures => o_weight_measure,
                                                            o_input_format  => o_input_format,
                                                            o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET LAST PREGNANCIES NUMBERS';
        IF NOT pk_pregnancy_core.get_last_preg_numbers(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_patient => i_patient,
                                                       o_pregn_summ => o_pregn_summ,
                                                       o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        o_weeks_min_fetus := pk_sysconfig.get_config('PREGNANCY_ABORTION_LIMIT', i_prof) -
                             pk_sysconfig.get_config('PREGNANCY_ABORTION_OFFSET', i_prof);
    
        BEGIN
            g_error := 'GET NUM PREGNANCY';
            IF i_flg_type = pk_pregnancy_core.g_pat_pregn_type_c
            THEN
                SELECT nvl(MAX(pp.n_pregnancy), 0) + 1
                  INTO o_num_pregnancy
                  FROM pat_pregnancy pp
                 WHERE pp.id_patient = i_patient
                   AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel;
            ELSIF i_flg_type = pk_pregnancy_core.g_pat_pregn_type_r
            THEN
                SELECT nvl(MAX(pp.n_pregnancy), 0) + 1
                  INTO o_num_pregnancy
                  FROM pat_pregnancy pp
                 WHERE pp.id_patient = i_patient
                   AND pp.flg_status NOT IN
                       (pk_pregnancy_core.g_pat_pregn_cancel, pk_pregnancy_core.g_pat_pregn_active);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                o_num_pregnancy := 1;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_weight_measure);
            pk_types.open_my_cursor(o_pregn_summ);
            RETURN error_handling_ext(i_lang, 'GET_PREGN_CREATE_INFO', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_pregn_create_info;

    /**
    * Gets the institution domain for the pregnancy templates
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids 
    * @param   I_FLG_TYPE institution type: H - hospital, C - primary care, A - both, R - both (reported pregnancy)
    * @param   I_FLG_CONTEXT Context where the method is called: (P) Pregnancy screens
    * @param   O_DOMAINS the cursOr with the domains info  
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    *
    * @author  José Silva
    * @version 1.0 
    * @since   27-06-2008
    */
    FUNCTION get_inst_domain_template
    (
        i_lang        IN sys_domain.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN VARCHAR2,
        i_flg_context IN VARCHAR2 DEFAULT NULL,
        o_inst        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type_a CONSTANT VARCHAR2(1) := 'A';
        l_flg_type_r CONSTANT VARCHAR2(1) := 'R';
        l_flg_type_c CONSTANT VARCHAR2(1) := 'C';
        l_flg_type_u CONSTANT VARCHAR2(1) := 'U';
        l_flg_type pat_pregn_inst_assist.flg_type%TYPE;
    
        l_config_show_inst CONSTANT sys_config.id_sys_config%TYPE := 'PREGNANCY_PROCEDURE_LOC_SHOW_INST';
        l_show_inst sys_config.value%TYPE;
    BEGIN
    
        g_error := 'GET FLG_TYPE';
        IF i_flg_type IN (l_flg_type_a, l_flg_type_r)
        THEN
            l_flg_type := pk_pregnancy_core.g_flg_assist_l;
        ELSE
            l_flg_type := pk_pregnancy_core.g_flg_assist_p;
        END IF;
        l_show_inst := pk_sysconfig.get_config(l_config_show_inst, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_inst FOR
            SELECT 'X' data,
                   NULL id_reg,
                   NULL desc_inst,
                   pk_message.get_message(i_lang, 'COMMON_M002') label,
                   -1 rank,
                   NULL img_name
              FROM dual
             WHERE i_flg_type = l_flg_type_r
                  -- Do not return option "None" when context is specified.
                  -- For instance, in the pregnancy record screens the multichoice allows to clear the selection,
                  -- so this option is not required.
               AND i_flg_context IS NULL
            
            UNION ALL
            
            SELECT pk_pregnancy_core.g_data_i data,
                   to_char(id_reg) id_reg,
                   desc_inst,
                   desc_inst label,
                   0 rank,
                   NULL img_name
              FROM (SELECT i.id_institution id_reg,
                           decode(i_flg_type,
                                  l_flg_type_r,
                                  nvl(i.abbreviation, pk_translation.get_translation(i_lang, i.code_institution)),
                                  pk_translation.get_translation(i_lang, i.code_institution)) desc_inst
                      FROM institution i
                     WHERE i.id_institution = i_prof.institution
                       AND (i_flg_type = l_flg_type_c AND i.flg_type IN (l_flg_type_c, l_flg_type_u) OR
                           (i.flg_type = i_flg_type OR i_flg_type IN (l_flg_type_a, l_flg_type_r))))
             WHERE l_show_inst = pk_alert_constant.g_yes
            
            UNION ALL
            
            SELECT pk_pregnancy_core.g_data_i data,
                   to_char(id_reg) id_reg,
                   desc_inst,
                   desc_inst label,
                   0 rank,
                   NULL img_name
              FROM (SELECT i.id_institution id_reg, pk_translation.get_translation(i_lang, i.code_institution) desc_inst
                      FROM institution i, pat_pregn_inst_assist pi
                     WHERE pi.id_inst_parent = i_prof.institution
                       AND i.id_institution = pi.id_institution
                       AND (i_flg_type = l_flg_type_c AND i.flg_type IN (l_flg_type_c, l_flg_type_u) OR
                           (i.flg_type = i_flg_type OR i_flg_type IN (l_flg_type_a, l_flg_type_r)))
                       AND pi.flg_type = l_flg_type
                     ORDER BY pi.rank, desc_inst) list_i
            
            UNION ALL
            
            SELECT NULL data,
                   '-1' id_reg,
                   pk_message.get_message(i_lang, 'WOMAN_HEALTH_T114') desc_inst,
                   NULL label,
                   0 rank,
                   NULL img_name
              FROM dual
             WHERE i_flg_type NOT IN ( /*l_flg_type_a,*/ l_flg_type_r)
            
            UNION ALL
            
            SELECT *
              FROM (SELECT val data, val id_reg, desc_val desc_inst, desc_val label, rank, img_name
                      FROM sys_domain
                     WHERE code_domain = pk_pregnancy_core.g_code_domain
                       AND id_language = i_lang
                       AND flg_available = pk_pregnancy_core.g_flg_available_y
                       AND i_flg_type IN (l_flg_type_a, l_flg_type_r)
                     ORDER BY rank, label);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_inst);
            RETURN error_handling(i_lang, 'GET_INST_DOMAIN_TEMPLATE', g_error, SQLERRM, FALSE, o_error);
    END get_inst_domain_template;

    /********************************************************************************************
    * Returns the number of new born childs with unusual weigh
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    * @param i_flg_type               weight limit: U - upper limit, L - lower limit
    *                        
    * @return                         number of new born childs
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_fetus_weight
    (
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_type IN VARCHAR2
    ) RETURN NUMBER IS
    
        l_count       NUMBER := 0;
        l_lower_limit NUMBER;
        l_upper_limit NUMBER;
    
        l_id_unit_measure unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        l_id_unit_measure := pk_pregnancy_core.get_preg_summ_unit_measure_id(NULL, i_prof);
    
        IF i_flg_type = pk_pregnancy_core.g_lower_limit
        THEN
        
            l_lower_limit := pk_sysconfig.get_config('ADVERSE_OBSTETRIC_LOWER', i_prof);
        
            SELECT COUNT(*)
              INTO l_count
              FROM pat_pregnancy p, pat_pregn_fetus ppf
             WHERE p.id_patient = i_patient
               AND p.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
               AND p.id_pat_pregnancy = ppf.id_pat_pregnancy
               AND pk_unit_measure.get_unit_mea_conversion(ppf.weight,
                                                           nvl(ppf.id_unit_measure, l_id_unit_measure),
                                                           pk_pregnancy_core.g_adverse_weight_um_id) < l_lower_limit
               AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                   instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                   ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
               AND nvl(ppf.id_unit_measure, l_id_unit_measure) = l_id_unit_measure;
        
            IF l_count = 0
            THEN
                l_count := NULL;
            END IF;
        
            g_count_weight_l := l_count;
        
        ELSIF i_flg_type = pk_pregnancy_core.g_upper_limit
        THEN
        
            l_upper_limit := pk_sysconfig.get_config('ADVERSE_OBSTETRIC_UPPER', i_prof);
        
            SELECT COUNT(*)
              INTO l_count
              FROM pat_pregnancy p, pat_pregn_fetus ppf
             WHERE p.id_patient = i_patient
               AND p.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
               AND p.id_pat_pregnancy = ppf.id_pat_pregnancy
               AND pk_unit_measure.get_unit_mea_conversion(ppf.weight,
                                                           nvl(ppf.id_unit_measure, l_id_unit_measure),
                                                           pk_pregnancy_core.g_adverse_weight_um_id) > l_upper_limit
               AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                   instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                   ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
               AND nvl(ppf.id_unit_measure, l_id_unit_measure) = l_id_unit_measure;
        
            IF l_count = 0
            THEN
                l_count := NULL;
            END IF;
        
            g_count_weight_u := l_count;
        
        END IF;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_count_fetus_weight;

    /********************************************************************************************
    * Returns the number of dead fetus
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of dead fetus
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_dead_fetus
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
    
    BEGIN
    
        SELECT COUNT(*)
          INTO g_count_dead_fetus
          FROM pat_pregnancy p, pat_pregn_fetus ppf
         WHERE p.id_patient = i_patient
           AND (i_pat_pregnancy IS NULL OR p.id_pat_pregnancy = i_pat_pregnancy)
           AND p.flg_status IN (pk_pregnancy_core.g_pat_pregn_active,
                                pk_pregnancy_core.g_pat_pregn_past,
                                pk_pregnancy_core.g_pat_pregn_no)
           AND p.id_pat_pregnancy = ppf.id_pat_pregnancy
           AND instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0;
    
        IF g_count_dead_fetus = 0
        THEN
            g_count_dead_fetus := NULL;
        END IF;
    
        RETURN g_count_dead_fetus;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_dead_fetus;

    /********************************************************************************************
    * Returns the number of abortions
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of abortions
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/01/02
    **********************************************************************************************/
    FUNCTION get_count_abortions
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        SELECT COUNT(*)
          INTO g_count_abortion
          FROM pat_pregnancy p
         WHERE p.id_patient = i_patient
           AND p.flg_status NOT IN (pk_pregnancy_core.g_pat_pregn_active,
                                    pk_pregnancy_core.g_pat_pregn_cancel,
                                    pk_pregnancy_core.g_pat_pregn_past,
                                    pk_pregnancy_core.g_pat_pregn_no,
                                    pk_pregnancy_core.g_pat_pregn_auto_close);
    
        IF g_count_abortion = 0
        THEN
            g_count_abortion := NULL;
        END IF;
    
        RETURN g_count_abortion;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_abortions;

    /********************************************************************************************
    * Returns the number of early deliveries
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of early deliveries
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_early_deliv
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
    
        SELECT COUNT(*)
          INTO g_count_pre_labor
          FROM pat_pregnancy p
         WHERE p.id_patient = i_patient
           AND p.flg_status = pk_pregnancy_core.g_pat_pregn_past
           AND ((p.dt_intervention - p.dt_init_pregnancy < numtodsinterval(37 * 7, 'DAY') AND
               p.dt_init_pregnancy IS NOT NULL AND p.dt_intervention IS NOT NULL AND
               nvl(p.flg_dt_interv_precision, pk_pregnancy_core.g_dt_flg_precision_h) <>
               pk_pregnancy_core.g_dt_flg_precision_y) OR (p.num_gest_weeks < 37 AND p.num_gest_weeks IS NOT NULL));
    
        IF g_count_pre_labor = 0
        THEN
            g_count_pre_labor := NULL;
        END IF;
    
        RETURN g_count_pre_labor;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_early_deliv;

    /********************************************************************************************
    * Returns the number of cesarean sections
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         number of cesarean sections
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/03
    **********************************************************************************************/
    FUNCTION get_count_cesarean
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
    
        l_childbirth_type_c  CONSTANT pat_pregn_fetus.flg_childbirth_type%TYPE := 'C';
        l_childbirth_type_dc CONSTANT pat_pregn_fetus.flg_childbirth_type%TYPE := 'DC';
        l_childbirth_type_dt CONSTANT pat_pregn_fetus.flg_childbirth_type%TYPE := 'DT';
        l_childbirth_type_de CONSTANT pat_pregn_fetus.flg_childbirth_type%TYPE := 'DE';
    
    BEGIN
    
        SELECT COUNT(*)
          INTO g_count_cesarean
          FROM pat_pregnancy p
         WHERE p.id_patient = i_patient
           AND p.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
           AND EXISTS
         (SELECT 0
                  FROM pat_pregn_fetus ppf
                 WHERE ppf.id_pat_pregnancy = p.id_pat_pregnancy
                   AND (instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                       instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0 OR
                       ppf.flg_status = pk_pregnancy_core.g_pregn_fetus_unk)
                   AND ppf.flg_childbirth_type IN
                       (l_childbirth_type_c, l_childbirth_type_dc, l_childbirth_type_dt, l_childbirth_type_de));
    
        IF g_count_cesarean = 0
        THEN
            g_count_cesarean := NULL;
        END IF;
    
        RETURN g_count_cesarean;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_cesarean;

    /********************************************************************************************
    * Returns the first component to place in the adverse obstetric section and makes all calculations included in this section
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                patient ID
    *                        
    * @return                         component text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/07/05
    **********************************************************************************************/
    FUNCTION get_adv_obs_component
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count_1 NUMBER;
        l_count_2 NUMBER;
        l_count_3 NUMBER;
        l_count_4 NUMBER;
        l_count_5 NUMBER;
        l_count_6 NUMBER;
    
        l_lower_limit    CONSTANT NUMBER := pk_sysconfig.get_config('ADVERSE_OBSTETRIC_LOWER', i_prof);
        l_upper_limit    CONSTANT NUMBER := pk_sysconfig.get_config('ADVERSE_OBSTETRIC_UPPER', i_prof);
        l_weight_measure CONSTANT VARCHAR2(200) := pk_pregnancy_core.get_preg_summ_unit_measure(i_lang, i_prof, NULL);
        l_weight_id unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        l_weight_id := pk_pregnancy_core.get_preg_summ_unit_measure_id(i_lang, i_prof);
    
        l_count_1 := get_count_fetus_weight(i_prof, i_patient, pk_pregnancy_core.g_lower_limit);
        l_count_2 := get_count_fetus_weight(i_prof, i_patient, pk_pregnancy_core.g_upper_limit);
        l_count_3 := get_count_dead_fetus(i_prof, i_patient);
        l_count_6 := get_count_abortions(i_prof, i_patient);
        l_count_4 := get_count_early_deliv(i_prof, i_patient);
        l_count_5 := get_count_cesarean(i_prof, i_patient);
    
        IF l_count_1 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_weight_l;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T115') || ' &lt; ' || pk_unit_measure.get_unit_mea_conversion(l_lower_limit,
                                                                                                                              pk_pregnancy_core.g_adverse_weight_um_id,
                                                                                                                              l_weight_id) || ' ' || l_weight_measure;
        ELSIF l_count_2 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_weight_u;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T115') || ' &gt; ' || pk_unit_measure.get_unit_mea_conversion(l_upper_limit,
                                                                                                                              pk_pregnancy_core.g_adverse_weight_um_id,
                                                                                                                              l_weight_id) || ' ' || l_weight_measure;
        ELSIF l_count_3 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_dead_fetus;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T116');
        ELSIF l_count_6 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_abortion;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T121');
        ELSIF l_count_4 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_pre_labor;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T117');
        ELSIF l_count_5 > 0
        THEN
            g_flg_count := pk_pregnancy_core.g_flg_cesarean;
            RETURN pk_message.get_message(i_lang, 'WOMAN_HEALTH_T118');
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_adv_obs_component;

    /********************************************************************************************
    * Migration of all pregnancies from the temporary episode to the definitive
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Definitive patient ID
    * @param i_patient_temp           Temporary patient ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          01/09/2008
    **********************************************************************************************/
    FUNCTION set_match_pat_pregnancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN episode.id_episode%TYPE,
        i_patient_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_pregnancy IS
            SELECT MAX(p.dt_pat_pregnancy_tstz)
              FROM pat_pregnancy p
             WHERE p.id_patient = i_patient
               AND p.flg_status = pk_pregnancy_core.g_pat_pregn_active;
    
        l_dt_pat_pregnancy pat_pregnancy.dt_pat_pregnancy_tstz%TYPE;
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_message_cancel CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_M005';
    
        l_rowids_1 table_varchar;
        e_process_event EXCEPTION;
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'UPDATE PAT PREGNANCY';
        ts_pat_pregnancy.upd(id_patient_in  => i_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_patient = ' || i_patient_temp,
                             rows_out       => l_rowids_1);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PREGNANCY',
                                      i_rowids     => l_rowids_1,
                                      o_error      => l_error);
    
        l_rowids_1 := table_varchar();
    
        g_error := 'OPEN C_PAT_PREGNANCY';
        OPEN c_pat_pregnancy;
        FETCH c_pat_pregnancy
            INTO l_dt_pat_pregnancy;
        CLOSE c_pat_pregnancy;
    
        g_error := 'GET ACTIVE PREGNANCY';
        BEGIN
            SELECT id_pat_pregnancy
              INTO l_id_pat_pregnancy
              FROM pat_pregnancy
             WHERE id_patient = i_patient
               AND dt_pat_pregnancy_tstz <> l_dt_pat_pregnancy
               AND flg_status = pk_pregnancy_core.g_pat_pregn_active;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
        g_error := 'SET PREGNANCY HISTORY';
        IF NOT pk_pregnancy_core.set_pat_pregnancy_hist(i_lang, l_id_pat_pregnancy, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE PAT PREGNANCY';
        ts_pat_pregnancy.upd(id_pat_pregnancy_in      => l_id_pat_pregnancy,
                             flg_status_in            => 'C',
                             id_professional_in       => i_prof.id,
                             dt_pat_pregnancy_tstz_in => current_timestamp,
                             notes_in                 => pk_message.get_message(i_lang, l_message_cancel),
                             rows_out                 => l_rowids_1);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PREGNANCY',
                                      i_rowids     => l_rowids_1,
                                      o_error      => l_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN error_handling(i_lang,
                                  'SET_MATCH_PAT_PREGNANCY',
                                  g_error || ' / ' || l_error.err_desc,
                                  SQLERRM,
                                  TRUE,
                                  o_error);
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_MATCH_PAT_PREGNANCY', g_error, SQLERRM, TRUE, o_error);
    END set_match_pat_pregnancy;

    /********************************************************************************************
    * Returns the pregnancy outcome based on the different fetus status
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_child_status       Child status: Live birth or Still birth
    * @param o_pregn_outcome          Pregnancy outcome
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_child_status IN table_varchar,
        o_pregn_outcome    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_pregn_outcome := pk_pregnancy_core.get_pregnancy_outcome(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_pat_pregnancy      => NULL,
                                                                   i_pat_pregnancy_hist => NULL,
                                                                   i_flg_child_status   => i_flg_child_status);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'GET_PREGNANCY_OUTCOME', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_pregnancy_outcome;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param o_code_formatted         Formatted pregnancy code
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/13
    **********************************************************************************************/
    FUNCTION get_desc_pregnancy_code
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN pat_pregnancy_code.code_state%TYPE,
        i_code_year       IN pat_pregnancy_code.code_year%TYPE,
        i_code_number     IN pat_pregnancy_code.code_number%TYPE,
        o_code_formatted  OUT VARCHAR2,
        o_code_serialized OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_code_formatted := pk_pregnancy_core.get_desc_pregnancy_code(i_lang        => i_lang,
                                                                      i_prof        => i_prof,
                                                                      i_code_state  => i_code_state,
                                                                      i_code_year   => i_code_year,
                                                                      i_code_number => i_code_number);
    
        o_code_serialized := pk_pregnancy_core.get_serialized_code(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_code_state  => i_code_state,
                                                                   i_code_year   => i_code_year,
                                                                   i_code_number => i_code_number);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang,
                                      'GET_DESC_PREGNANCY_CODE',
                                      g_error,
                                      SQLCODE,
                                      SQLERRM,
                                      FALSE,
                                      'S',
                                      o_error);
    END get_desc_pregnancy_code;

    /********************************************************************************************
    * Returns all information to fill the pregnancies summary page in past history area
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                episode ID
    * @param i_pat                    patient ID 
    * @param i_start_date             Start date 
    * @param i_end_date               End date    
    * @param i_doc_area               the doc area ID
    * @param o_doc_area_register      Cursor with the doc area info register
    * @param o_doc_area_val           Cursor containing the completed info for episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.0.5
    * @since                          2011/02/07
    **********************************************************************************************/
    FUNCTION get_sum_page_doc_ar_past_preg
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_pat               IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_start_date        IN pat_pregnancy.dt_pat_pregnancy_tstz%TYPE DEFAULT NULL,
        i_end_date          IN pat_pregnancy.dt_pat_pregnancy_tstz%TYPE DEFAULT NULL,
        o_doc_area_register OUT t_cur_doc_area_pregnancy_ph,
        o_doc_area_val      OUT p_doc_area_val_doc_cur_ph,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sep CONSTANT VARCHAR2(1) := '.';
    
        l_label_sisprenantal    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T126'); --            
        l_label_dt_menstruation CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T127'); --
        l_label_menses          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T128'); --
        l_label_cycle           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T129'); --
        l_label_contracep       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T130'); --
        l_label_contracep_type  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T166'); --
        l_label_dt_contracep    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T131'); --
        l_label_gest_age        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T132'); --
        l_label_gest_reported   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T092'); --
        l_label_edd_lmp         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T133'); --
        l_label_gest_exam       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T148'); --
        l_label_gest_us         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T136'); --
        l_label_edd_us          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T134'); --
        l_label_us_performed    CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T164'); --
        l_label_us_at_gest_age  CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T165'); --
        l_label_fetus_num       CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T078');
        l_label_outcome         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T146'); --
        l_label_compl           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T140'); --
        l_label_interv          CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T141'); --
        l_label_dt_birth        CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T145'); --
        l_label_notes           CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 'WOMAN_HEALTH_T100'); --
    
        l_label_pregnancy CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'WOMAN_HEALTH_T021');
    
        l_label_days         CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              'WOMAN_HEALTH_T158');
        l_closed_by_system   CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              i_prof,
                                                                                              'PAT_PREGNANCY_M006');
        l_label_labour_onset CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                              i_prof,
                                                                                              'WOMAN_HEALTH_T147'); --
    
        l_label_labour_duration CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                                 i_prof,
                                                                                                 'WOMAN_HEALTH_T138'); --                                                                                   
    
    BEGIN
    
        g_error := 'GET CURSOR O_DOC_AREA_REGISTER';
        OPEN o_doc_area_register FOR
            SELECT id_pat_pregnancy id_epis_documentation,
                   NULL id_doc_template,
                   pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_register,
                   pk_date_utils.date_char_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof.institution, i_prof.software) dt_register_chr,
                   id_professional,
                   CASE
                        WHEN flg_status = pk_pregnancy_core.g_pat_pregn_auto_close THEN
                         l_closed_by_system
                        ELSE
                         pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional)
                    END nick_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, id_professional, dt_pat_pregnancy_tstz, id_episode) desc_speciality,
                   i_doc_area id_doc_area,
                   flg_status,
                   pk_sysdomain.get_domain('EPIS_COMPLAINT.FLG_STATUS', flg_status, i_lang) desc_status,
                   decode(id_episode,
                          i_episode,
                          pk_pregnancy_core.g_current_episode_yes,
                          pk_pregnancy_core.g_current_episode_no) flg_current_episode,
                   pregnancy_info notes,
                   pk_date_utils.date_send_tsz(i_lang, dt_pat_pregnancy_tstz, i_prof) dt_last_update,
                   pk_pregnancy_core.g_flg_det_no flg_detail,
                   id_episode,
                   n_pregnancy,
                   pk_episode.get_id_visit(id_episode) id_visit
              FROM (SELECT pp.id_pat_pregnancy,
                           pp.dt_pat_pregnancy_tstz,
                           pp.id_professional,
                           pp.id_episode,
                           pp.flg_status,
                           -- Pregnancy number
                           pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_pregnancy,
                                                                 pp.n_pregnancy,
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Reported intervention date
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_r,
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                        l_label_dt_birth,
                                                                        pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                              i_prof,
                                                                                                              pp.dt_intervention,
                                                                                                              pp.flg_dt_interv_precision),
                                                                        l_sep,
                                                                        pp.first_title)) ||
                           -- SISPRENATAL
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_sisprenantal,
                                                                 pk_pregnancy_core.get_pat_pregnancy_code(i_lang,
                                                                                                          i_prof,
                                                                                                          pp.id_pat_pregnancy,
                                                                                                          NULL),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- LMP
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_dt_menstruation,
                                                                 pk_date_utils.dt_chr(i_lang, dt_last_menstruation, i_prof),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Menses
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_menses,
                                                                 pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MENSES',
                                                                                         pp.flg_menses,
                                                                                         i_lang),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Cycle duration
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_cycle,
                                                                 nvl2(pp.cycle_duration,
                                                                      pp.cycle_duration || ' ' || l_label_days,
                                                                      NULL),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Contraceptive use
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_contracep,
                                                                 pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_USE_CONSTRACEPTIVES',
                                                                                         pp.flg_use_constraceptives,
                                                                                         i_lang),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Contraceptive type
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_contracep_type,
                                                                 pk_pregnancy_core.get_contraception_type(i_lang,
                                                                                                          i_prof,
                                                                                                          pp.id_pat_pregnancy,
                                                                                                          NULL),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Last use of contraceptive
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_dt_contracep,
                                                                 pk_pregnancy_core.get_dt_contrac_end(i_lang,
                                                                                                      i_prof,
                                                                                                      pp.dt_contrac_meth_end,
                                                                                                      pp.flg_dt_contrac_precision),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- Gestational age by LMP / Gestational age
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 decode(pp.flg_type,
                                                                        pk_pregnancy_core.g_pat_pregn_type_c,
                                                                        l_label_gest_age,
                                                                        l_label_gest_reported),
                                                                 pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                             i_prof,
                                                                                                             pp.num_gest_weeks,
                                                                                                             dt_init_preg_lmp,
                                                                                                             pp.dt_intervention,
                                                                                                             pp.flg_status),
                                                                 l_sep,
                                                                 pp.first_title) ||
                           -- EDD by LMP
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_edd_lmp,
                                                                 pk_date_utils.dt_chr(i_lang, pp.dt_pdel_lmp, i_prof),
                                                                 l_sep,
                                                                 '') ||
                           -- Gestational age by examination
                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                       l_label_gest_exam,
                                                                       nvl2(pp.num_gest_weeks_exam,
                                                                            pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                        i_prof,
                                                                                                                        pp.num_gest_weeks_exam,
                                                                                                                        pp.dt_init_preg_exam,
                                                                                                                        pp.dt_intervention,
                                                                                                                        pp.flg_status),
                                                                            NULL),
                                                                       l_sep,
                                                                       pp.first_title,
                                                                       break_exam) ||
                           -- Gestational age by US
                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                       l_label_gest_us,
                                                                       nvl2(pp.num_gest_weeks_us,
                                                                            pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                        i_prof,
                                                                                                                        pp.num_gest_weeks_us,
                                                                                                                        pp.dt_init_pregnancy,
                                                                                                                        pp.dt_intervention,
                                                                                                                        pp.flg_status),
                                                                            NULL),
                                                                       l_sep,
                                                                       pp.first_title,
                                                                       break_us) ||
                           -- EDD by US
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_edd_us,
                                                                 pk_date_utils.dt_chr(i_lang, pp.dt_pdel_correct, i_prof),
                                                                 l_sep,
                                                                 '') ||
                           -- US performed in
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_us_performed,
                                                                 pk_date_utils.dt_chr(i_lang, pp.dt_us_performed, i_prof),
                                                                 l_sep,
                                                                 '') ||
                           -- US performed at gestational age
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_us_at_gest_age,
                                                                 nvl2(pp.dt_us_performed,
                                                                      pk_pregnancy_core.get_pregn_formatted_weeks(i_lang,
                                                                                                                  i_prof,
                                                                                                                  NULL,
                                                                                                                  pp.dt_init_pregnancy,
                                                                                                                  pp.dt_us_performed,
                                                                                                                  pp.flg_status),
                                                                      NULL),
                                                                 l_sep,
                                                                 '') ||
                           -- Number of fetuses
                            pk_pregnancy_core.get_formatted_text(i_doc_area, l_label_fetus_num, pp.n_children, l_sep, '') ||
                           -- Pregnancy outcome
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_r,
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                        l_label_outcome,
                                                                        pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                 pp.flg_status,
                                                                                                                 pp.id_pat_pregnancy,
                                                                                                                 NULL,
                                                                                                                 pk_pregnancy_core.g_type_summ),
                                                                        l_sep,
                                                                        '')) ||
                           -- Procedure place
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_r,
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                        l_label_interv,
                                                                        pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                pp.id_inst_intervention,
                                                                                                                pp.flg_desc_intervention,
                                                                                                                pp.desc_intervention),
                                                                        l_sep,
                                                                        '')) ||
                           -- Labour onset
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_labour_onset,
                                                                 pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_DEL_ONSET',
                                                                                         pp.flg_del_onset,
                                                                                         i_lang),
                                                                 l_sep,
                                                                 '') ||
                           
                           -- Labour duration                                           
                            pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                 l_label_labour_duration,
                                                                 CASE
                                                                     WHEN regexp_like(pp.del_duration, '\w\w:\w\w') THEN
                                                                      pp.del_duration || 'h'
                                                                     WHEN regexp_like(pp.del_duration, '\w\w:\w') THEN
                                                                      regexp_replace(pp.del_duration, '\w\w:\w', pp.del_duration || '0h')
                                                                     WHEN regexp_like(pp.del_duration, '\w:\w\w') THEN
                                                                      regexp_replace(pp.del_duration, '\w:\w\w', '0' || pp.del_duration || 'h')
                                                                     WHEN regexp_like(pp.del_duration, '\w:\w') THEN
                                                                      regexp_replace(pp.del_duration, '\w:\w', '0' || pp.del_duration || '0h')
                                                                 END,
                                                                 l_sep,
                                                                 '') ||
                           
                           -- Complications
                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                       l_label_compl,
                                                                       pk_pregnancy_core.get_preg_complications(i_lang,
                                                                                                                i_prof,
                                                                                                                pp.flg_complication,
                                                                                                                pp.notes_complications,
                                                                                                                pp.id_pat_pregnancy,
                                                                                                                NULL),
                                                                       l_sep,
                                                                       pp.first_title,
                                                                       break_compl) ||
                           -- Pregnancy outcome
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_c,
                                   pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                              l_label_outcome,
                                                                              pk_pregnancy_core.get_pregn_outcome_desc(i_lang,
                                                                                                                       pp.flg_status,
                                                                                                                       pp.id_pat_pregnancy,
                                                                                                                       NULL,
                                                                                                                       pk_pregnancy_core.g_type_summ),
                                                                              l_sep,
                                                                              pp.first_title,
                                                                              break_out)) ||
                           -- Procedure place
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_c,
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                        l_label_interv,
                                                                        pk_pregnancy_core.get_desc_intervention(i_lang,
                                                                                                                pp.id_inst_intervention,
                                                                                                                pp.flg_desc_intervention,
                                                                                                                pp.desc_intervention),
                                                                        l_sep,
                                                                        '')) ||
                           -- Intervention date
                            decode(pp.flg_type,
                                   pk_pregnancy_core.g_pat_pregn_type_c,
                                   pk_pregnancy_core.get_formatted_text(i_doc_area,
                                                                        l_label_dt_birth,
                                                                        pk_pregnancy_core.get_dt_intervention(i_lang,
                                                                                                              i_prof,
                                                                                                              pp.dt_intervention,
                                                                                                              pp.flg_dt_interv_precision),
                                                                        l_sep,
                                                                        pp.first_title)) ||
                           -- Notes
                            pk_pregnancy_core.get_formatted_text_break(i_doc_area,
                                                                       l_label_notes,
                                                                       pp.notes,
                                                                       l_sep,
                                                                       pp.first_title,
                                                                       break_notes) pregnancy_info,
                           pp.n_pregnancy
                      FROM (SELECT id_pat_pregnancy,
                                   flg_type,
                                   flg_status,
                                   n_pregnancy,
                                   id_episode,
                                   id_professional,
                                   num_gest_weeks,
                                   dt_pat_pregnancy_tstz,
                                   dt_last_menstruation,
                                   flg_menses,
                                   cycle_duration,
                                   flg_use_constraceptives,
                                   dt_contrac_meth_end,
                                   flg_dt_contrac_precision,
                                   dt_intervention,
                                   dt_pdel_lmp,
                                   num_gest_weeks_exam,
                                   dt_init_preg_exam,
                                   dt_init_preg_lmp,
                                   num_gest_weeks_us,
                                   dt_init_pregnancy,
                                   dt_pdel_correct,
                                   dt_us_performed,
                                   pregn.flg_del_onset,
                                   pregn.del_duration,
                                   n_children,
                                   flg_complication,
                                   notes_complications,
                                   notes,
                                   flg_dt_interv_precision,
                                   id_inst_intervention,
                                   flg_desc_intervention,
                                   desc_intervention,
                                   '' first_title,
                                   pk_alert_constant.g_no break_exam,
                                   pk_alert_constant.g_no break_us,
                                   pk_alert_constant.g_no break_compl,
                                   pk_alert_constant.g_no break_out,
                                   pk_alert_constant.g_no break_notes
                              FROM pat_pregnancy pregn
                             WHERE id_patient = i_pat
                               AND pregn.dt_pat_pregnancy_tstz >= nvl(i_start_date, pregn.dt_pat_pregnancy_tstz)
                               AND pregn.dt_pat_pregnancy_tstz <= nvl(i_end_date, pregn.dt_pat_pregnancy_tstz)
                            
                            ) pp
                     ORDER BY pp.n_pregnancy DESC);
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        OPEN o_doc_area_val FOR
            SELECT pp.id_pat_pregnancy id_epis_documentation,
                   NULL PARENT,
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   pp.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof) dt_register,
                   pk_date_utils.date_char_tsz(i_lang, pp.dt_pat_pregnancy_tstz, i_prof.institution, i_prof.software) dt_register_chr,
                   NULL desc_doc_component,
                   NULL desc_element,
                   NULL VALUE,
                   i_doc_area id_doc_area,
                   NULL rank_component,
                   NULL rank_element,
                   NULL desc_qualification,
                   decode(pp.id_episode,
                          i_episode,
                          pk_pregnancy_core.g_current_episode_yes,
                          pk_pregnancy_core.g_current_episode_no) flg_current_episode,
                   NULL id_epis_documentation_det,
                   pp.id_episode,
                   pp.id_professional,
                   pk_alert_constant.get_no flg_canceled,
                   pk_alert_constant.get_no flg_outdated
            
              FROM pat_pregnancy pp
             WHERE pp.id_patient = i_pat
               AND pp.dt_pat_pregnancy_tstz >= nvl(i_start_date, pp.dt_pat_pregnancy_tstz)
               AND pp.dt_pat_pregnancy_tstz <= nvl(i_end_date, pp.dt_pat_pregnancy_tstz)
             ORDER BY id_epis_documentation;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_SUM_PAGE_DOC_AR_PAST_PREG',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END get_sum_page_doc_ar_past_preg;

    /********************************************************************************************
    * Check if patient has a active pregnancy
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient id
    *                        
    * @return                         'Y' - if it has a active pregnancy; 'N' - otherwise
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          2013/01/15
    **********************************************************************************************/
    FUNCTION check_pat_is_preg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(1) := pk_alert_constant.g_no;
        l_count PLS_INTEGER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_pregnancy pp
         WHERE flg_status = pk_alert_constant.g_active
           AND id_patient = i_patient;
    
        IF l_count = 0
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    END check_pat_is_preg;

    /********************************************************************************************
    * Check if the patient had a partum less than a month
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient id
    *                        
    * @return                         'Y' - if it had a partum less than one month; 'N' - otherwise
    * 
    * @author                         Alexandre Santos
    * @version                        2.6
    * @since                          2013/01/15
    **********************************************************************************************/
    FUNCTION check_pat_1month_pos_partum
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_dt_last_intervention pat_pregnancy.dt_intervention%TYPE;
        --
        l_ret VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
        BEGIN
            SELECT pp.dt_intervention
              INTO l_dt_last_intervention
              FROM pat_pregnancy pp
             WHERE pp.id_patient = i_patient
               AND pp.dt_intervention = (SELECT MAX(pp1.dt_intervention)
                                           FROM pat_pregnancy pp1
                                          WHERE pp1.id_patient = i_patient)
               AND NOT EXISTS (SELECT 1
                      FROM pat_pregnancy pp1
                     WHERE pp1.id_patient = i_patient
                       AND pp1.flg_status = pk_pregnancy_core.g_pat_pregn_active)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_last_intervention := NULL;
        END;
    
        IF l_dt_last_intervention IS NULL
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            IF pk_date_utils.diff_timestamp(i_left => current_timestamp, i_right => l_dt_last_intervention) <= 30
            THEN
                l_ret := pk_alert_constant.g_yes;
            ELSE
                l_ret := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_ret;
    END check_pat_1month_pos_partum;

    /********************************************************************************************
    * Get pregnancy number
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_pregancy        Pat pregancy id
    *                        
    * @return                         Pregnancy number
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.3
    * @since                          2013/09/25
    **********************************************************************************************/
    FUNCTION get_n_pregnancy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pat_pregancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_n_pregnancy     OUT pat_pregnancy.n_pregnancy%TYPE
    ) RETURN BOOLEAN IS
        l_error t_error_out;
    BEGIN
        g_error := 'get_n_pregnancy. i_id_pat_pregancy: ' || i_id_pat_pregancy;
        pk_alertlog.log_debug(g_error);
        SELECT p.n_pregnancy
          INTO o_n_pregnancy
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_id_pat_pregancy;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_N_PREGNANCY',
                                              l_error);
            RETURN FALSE;
    END get_n_pregnancy;
    ------------------------------------------------------------------------------------
    PROCEDURE job_close_pregnancy IS
        /******************************************************************************
           OBJECTIVO: Close all pregnancys longer than 44 weeks (sys_configurable)
           PARAMETROS:
        
          CRIAÇÃO: 2014/01/14
          NOTAS:
        *********************************************************************************/
        --
        CURSOR c_pat_pregnancy IS
            SELECT t.id_pat_pregnancy, t.id_institution, t.id_software
              FROM (SELECT pp.id_pat_pregnancy,
                           pk_pregnancy_api.get_pregnancy_weeks(NULL, pp.dt_init_pregnancy, NULL, NULL) weeks,
                           e.id_institution,
                           ei.id_software
                      FROM pat_pregnancy pp
                      LEFT JOIN episode e
                        ON e.id_episode = pp.id_episode
                      LEFT JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                     WHERE pp.flg_status = pk_pregnancy_core.g_pat_pregn_active) t
             WHERE t.weeks >=
                   to_number(pk_sysconfig.get_config('PREGNANCY_MAX_NUMBER_OF_WEEKS', t.id_institution, t.id_software))
               AND pk_sysconfig.get_config('PREGNANCY_AUTO_CLOSE', t.id_institution, t.id_software) =
                   pk_alert_constant.g_yes;
    
        l_rowids       table_varchar;
        l_error        t_error_out;
        l_sysdate_tstz pat_pregnancy.dt_auto_closed%TYPE;
        l_exception EXCEPTION;
        l_prof profissional;
        l_lang language.id_language%TYPE;
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
        --
        FOR i IN c_pat_pregnancy
        LOOP
        
            l_prof := profissional(0, i.id_institution, i.id_software);
            l_lang := pk_sysconfig.get_config('LANGUAGE', l_prof);
        
            g_error := 'SAVE PREGNANCY HISTORY';
            IF NOT pk_pregnancy_core.set_pat_pregnancy_hist(l_lang, i.id_pat_pregnancy, l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'call ts_pat_pregnancy.upd';
            ts_pat_pregnancy.upd(id_pat_pregnancy_in      => i.id_pat_pregnancy,
                                 dt_pat_pregnancy_tstz_in => l_sysdate_tstz,
                                 id_professional_in       => l_prof.id,
                                 flg_status_in            => pk_pregnancy_core.g_pat_pregn_auto_close,
                                 dt_auto_closed_in        => l_sysdate_tstz,
                                 rows_out                 => l_rowids);
        
            g_error := 'call t_data_gov_mnt.process_update PAT_PREGNANCY';
            t_data_gov_mnt.process_update(i_lang       => l_lang,
                                          i_prof       => l_prof,
                                          i_table_name => 'PAT_PREGNANCY',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        END LOOP;
    
        COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(l_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'JOB_CLOSE_PREGNANCY',
                                              l_error);
            pk_utils.undo_changes;
    END job_close_pregnancy;

    /********************************************************************************************
    * Returns the pregnancy number of weeks, number of days
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_pregancy        Pat pregancy id
    * @param i_dt_intervention        init pregnancy date
    * @param o_weeks                  number of weeks
    * @param o_days                   number of days
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error                      
    * 
    * @author                         Paulo Teixeira
    * @version                        2.6.3.10
    * @since                          2013/01/21
    **********************************************************************************************/
    FUNCTION get_preg_weeks_days
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_intervention IN VARCHAR2,
        o_weeks           OUT NUMBER,
        o_days            OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_init_preg    pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_intervention pat_pregnancy.dt_intervention%TYPE;
    BEGIN
    
        BEGIN
            SELECT pp.dt_init_pregnancy
              INTO l_dt_init_preg
              FROM pat_pregnancy pp
             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
        EXCEPTION
            WHEN no_data_found THEN
                l_dt_init_preg := NULL;
        END;
    
        l_dt_intervention := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_intervention, NULL);
    
        g_error := 'get o_weeks';
        o_weeks := pk_pregnancy_api.get_pregnancy_weeks(i_prof, l_dt_init_preg, l_dt_intervention, NULL);
        g_error := 'get o_days';
        o_days  := pk_pregnancy_api.get_pregnancy_days(i_prof, l_dt_init_preg, l_dt_intervention, NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PREG_WEEKS_DAYS',
                                              o_error);
        
            RETURN NULL;
    END get_preg_weeks_days;

    /********************************************************************************************
    * Get the last menstruation date from the current patient pregnancy  
    *
    * @param i_patient                Patient ID
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         Last menstruation date
    * 
    * @author                         Gisela Couto
    * @version                        2.5.2.22
    * @since                          2014/08/27
    **********************************************************************************************/
    FUNCTION get_last_menstruation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN DATE IS
        dt_last_menstruation      pat_pregnancy.dt_last_menstruation%TYPE;
        dt_current                TIMESTAMP WITH LOCAL TIME ZONE;
        num_gestation_weeks       NUMBER;
        l_error                   t_error_out;
        l_max_num_gestation_weeks sys_config.value%TYPE;
    
    BEGIN
        g_error := 'i_lang => ' || i_lang || ' id_prof => ' || i_prof.id || ' id_institution => ' || i_prof.institution ||
                   ' id_software => ' || i_prof.software || ' i_patient => ' || i_patient;
        pk_alertlog.log_debug(text => g_error);
    
        g_error := 'VERIFY IF PATIENT IS NULL';
        IF i_patient IS NOT NULL
        THEN
            g_error := 'GET LAST MENSTRUATION DATE';
            BEGIN
            
                SELECT p.dt_last_menstruation
                  INTO dt_last_menstruation
                  FROM pat_pregnancy p
                 WHERE p.id_patient = i_patient
                   AND p.dt_intervention IS NULL
                   AND p.flg_status = pk_pregnancy_core.g_pat_pregn_active;
            EXCEPTION
                WHEN no_data_found THEN
                    dt_last_menstruation := NULL;
                    g_error              := 'NO LAST MENSTRUATION DATE';
            END;
        
            g_error := 'GET CURRENT TIME STAMP';
            SELECT current_timestamp
              INTO dt_current
              FROM dual;
        
            g_error := 'VERIFY IF LAST MENSTRUATION DATE IS NULL';
            IF dt_last_menstruation IS NOT NULL
            
            THEN
                g_error             := 'CALL PK_PREGNANCY.GET_PREGNANCY_NUM_WEEKS';
                num_gestation_weeks := pk_pregnancy.get_pregnancy_num_weeks(i_lang, i_prof, i_patient);
            
                l_max_num_gestation_weeks := pk_sysconfig.get_config('PREGNANCY_MAX_NUMBER_OF_WEEKS', i_prof);
            
                g_error := 'VERIFY IS NUM_WEEKS < MAX_GESTATION_WEEKS';
                IF num_gestation_weeks < l_max_num_gestation_weeks
                THEN
                    RETURN dt_last_menstruation;
                END IF;
            END IF;
        END IF;
        RETURN dt_last_menstruation;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_LAST_MENSTRUATION_DATE',
                                              l_error);
        
            RETURN NULL;
    END get_last_menstruation_date;

    /********************************************************************************************
    * Get the last menstruation date from the current patient pregnancy  
    *
    * @param i_patient                Patient ID
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_date_out               Date returned
    * @param o_error                  Error message
    *                        
    * @return                         Last menstruation date
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/04
    **********************************************************************************************/
    FUNCTION get_last_menstruation_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_date    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        dt_last_menstruation pat_pregnancy.dt_last_menstruation%TYPE;
    BEGIN
    
        g_error              := 'CALL GET_LAST_MENSTRUATION_DATE(' || i_lang || ',[' || i_prof.id || ',' ||
                                i_prof.institution || ',' || i_prof.software || '],' || i_patient || ')';
        dt_last_menstruation := get_last_menstruation_date(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
    
        g_error := 'VERIFY IF THE RETURNED DATE IS NULL';
        IF dt_last_menstruation IS NOT NULL
        THEN
            o_date := to_char(dt_last_menstruation, 'YYYY-MM-DD HH24:MI:SS');
        ELSE
            o_date := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_LAST_MENSTRUATION_DATE',
                                              o_error);
        
            RETURN FALSE;
    END get_last_menstruation_date;

    /*Private*/

    FUNCTION get_doc_area_obstetric_content
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_flg_filter        IN VARCHAR2,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_obstetric_history OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_mess_ini_date sys_message.code_message%TYPE := 'WOMAN_HEALTH_T168';
        l_code_mess_ini_date sys_message.code_message%TYPE := 'WOMAN_HEALTH_T168';
        l_mess               sys_message.desc_message%TYPE;
        l_mess_ini_date      sys_message.desc_message%TYPE;
        l_mess_term_date     sys_message.desc_message%TYPE;
        l_tbl_doc_area       t_doc_area_register;
        l_resp               BOOLEAN;
        l_cursor_temp        t_doc_area_val;
        l_tbl_status         table_varchar;
    
    BEGIN
        g_error := 'GET_DOC_AREA_OBSTETRIC_CONTENT - [' || i_lang || ',' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ',' || i_patient || ',' || i_flg_filter || ',' || i_doc_area || ']';
    
        IF NOT get_sum_page_doc_area_preg_int(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_pat               => i_patient,
                                              i_doc_area          => i_doc_area,
                                              o_doc_area_register => l_tbl_doc_area,
                                              o_doc_area_val      => l_cursor_temp,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error          := 'GET WOMAN_HEALTH MESSAGES';
        l_mess           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_T091');
        l_mess_ini_date  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_T168');
        l_mess_term_date := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_T145');
    
        g_error := 'VERIFY DOC AREA TYPE';
        IF i_doc_area = pk_pregnancy_core.g_doc_area_obs_hist
        THEN
            l_tbl_status := table_varchar(pk_pregnancy_core.g_pat_pregn_active,
                                          pk_pregnancy_core.g_pat_pregn_cancel,
                                          pk_pregnancy_core.g_pat_pregn_auto_close);
        ELSE
            IF i_doc_area = pk_pregnancy_core.g_doc_area_obs_adv
            THEN
                l_tbl_status := table_varchar(pk_pregnancy_core.g_pat_pregn_active,
                                              pk_pregnancy_core.g_pat_pregn_cancel,
                                              pk_pregnancy_core.g_pat_pregn_past,
                                              pk_pregnancy_core.g_pat_pregn_auto_close);
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'GET DATA BY FILTER TYPE - ALL';
        IF g_obstetric_resume_all = i_flg_filter
        THEN
            OPEN o_obstetric_history FOR
            
                SELECT l_mess || ' ' || t.pregnancy_number title,
                       
                       CASE
                            WHEN t.dt_init_pregnancy IS NOT NULL THEN
                             '(' || l_mess_ini_date || ': ' || to_char(trunc(t.dt_init_pregnancy), 'DD-Mon-YYYY') || ')'
                            WHEN t.dt_intervention_tstz IS NOT NULL THEN
                             '(' || l_mess_term_date || ': ' || to_char(trunc(t.dt_intervention_tstz), 'DD-Mon-YYYY') || ')'
                        END AS "DATE"
                  FROM TABLE(l_tbl_doc_area) t
                 WHERE t.flg_preg_status NOT IN (SELECT *
                                                   FROM TABLE(l_tbl_status))
                 ORDER BY CASE
                              WHEN dt_init_pregnancy IS NOT NULL THEN
                               dt_init_pregnancy
                              WHEN dt_intervention_tstz IS NOT NULL THEN
                               dt_intervention_tstz
                              ELSE
                               NULL
                          END DESC;
        
        ELSE
            g_error := 'GET DATA BY FILTER TYPE - LAST';
            IF g_obstetric_resume_last = i_flg_filter
            THEN
                OPEN o_obstetric_history FOR
                    SELECT l_mess || ' ' || t.pregnancy_number title,
                           CASE
                                WHEN t.dt_init_pregnancy IS NOT NULL THEN
                                 '(' || l_mess_ini_date || ': ' || to_char(trunc(t.dt_init_pregnancy), 'DD-Mon-YYYY') || ')'
                                WHEN t.dt_intervention_tstz IS NOT NULL THEN
                                 '(' || l_mess_term_date || ': ' || to_char(trunc(t.dt_intervention_tstz), 'DD-Mon-YYYY') || ')'
                                ELSE
                                 NULL
                            END AS "DATE"
                      FROM TABLE(l_tbl_doc_area) t
                     WHERE t.dt_pat_pregnancy_tstz =
                           (SELECT MAX(t1.dt_pat_pregnancy_tstz)
                              FROM TABLE(l_tbl_doc_area) t1
                             WHERE t1.flg_preg_status NOT IN (SELECT *
                                                                FROM TABLE(l_tbl_status)))
                       AND t.flg_preg_status NOT IN (SELECT *
                                                       FROM TABLE(l_tbl_status));
            
            ELSE
                g_error := 'GET DATA BY FILTER TYPE - MINE';
                IF g_obstetric_resume_mine = i_flg_filter
                THEN
                
                    OPEN o_obstetric_history FOR
                        SELECT l_mess || ' ' || t.pregnancy_number title,
                               CASE
                                    WHEN t.dt_init_pregnancy IS NOT NULL THEN
                                     '(' || l_mess_ini_date || ': ' || to_char(trunc(t.dt_init_pregnancy), 'DD-Mon-YYYY') || ')'
                                    WHEN t.dt_intervention_tstz IS NOT NULL THEN
                                     '(' || l_mess_term_date || ': ' ||
                                     to_char(trunc(t.dt_intervention_tstz), 'DD-Mon-YYYY') || ')'
                                END AS "DATE"
                          FROM TABLE(l_tbl_doc_area) t
                         WHERE t.flg_preg_status NOT IN (SELECT *
                                                           FROM TABLE(l_tbl_status))
                           AND t.id_professional = i_prof.id
                         ORDER BY CASE
                                      WHEN dt_init_pregnancy IS NOT NULL THEN
                                       dt_init_pregnancy
                                      WHEN dt_intervention_tstz IS NOT NULL THEN
                                       dt_intervention_tstz
                                      ELSE
                                       NULL
                                  END DESC;
                
                ELSE
                    g_error := 'GET DATA BY FILTER TYPE - LASTMINE';
                    IF g_obstetric_resume_last_mine = i_flg_filter
                    THEN
                        OPEN o_obstetric_history FOR
                            SELECT l_mess || ' ' || t.pregnancy_number title,
                                   CASE
                                        WHEN t.dt_init_pregnancy IS NOT NULL THEN
                                         '(' || l_mess_ini_date || ': ' ||
                                         to_char(trunc(t.dt_init_pregnancy), 'DD-Mon-YYYY') || ')'
                                        WHEN t.dt_intervention_tstz IS NOT NULL THEN
                                         '(' || l_mess_term_date || ': ' ||
                                         to_char(trunc(t.dt_intervention_tstz), 'DD-Mon-YYYY') || ')'
                                    END AS "DATE"
                              FROM TABLE(l_tbl_doc_area) t
                             WHERE t.flg_preg_status NOT IN (SELECT *
                                                               FROM TABLE(l_tbl_status))
                               AND t.id_professional = i_prof.id
                               AND t.dt_pat_pregnancy_tstz =
                                   (SELECT MAX(t1.dt_pat_pregnancy_tstz)
                                      FROM TABLE(l_tbl_doc_area) t1
                                     WHERE t1.flg_preg_status NOT IN
                                           (SELECT *
                                              FROM TABLE(l_tbl_status)));
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_obstetric_history);
            RETURN error_handling(i_lang, 'GET_DOC_AREA_OBSTETRIC_CONTENT', g_error, SQLERRM, FALSE, o_error);
        
    END get_doc_area_obstetric_content;

    /********************************************************************************************
    * Gets pregnancy date according to the filter type passed. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_flg_filter             Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title and pregnacy tstz
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/05
    **********************************************************************************************/

    FUNCTION get_obstetric_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_flg_filter        IN VARCHAR2,
        o_obstetric_history OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET OBSTETRIC HISTORY - [' || i_lang || ',' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ',' || i_patient || ',' || i_flg_filter || ']';
    
        IF NOT get_doc_area_obstetric_content(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_patient           => i_patient,
                                              i_flg_filter        => i_flg_filter,
                                              i_doc_area          => pk_pregnancy_core.g_doc_area_obs_hist,
                                              o_obstetric_history => o_obstetric_history,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_obstetric_history);
            RETURN error_handling(i_lang, 'GET_OBSTETRIC_HISTORY', g_error, SQLERRM, FALSE, o_error);
        
    END get_obstetric_history;

    /********************************************************************************************
    * Gets obstetric adverse history according to the filter type passed. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_flg_filter             Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title and pregnacy tstz
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/05
    **********************************************************************************************/
    FUNCTION get_obstetric_adverse_history
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_flg_filter                IN VARCHAR2,
        o_obstetric_adverse_history OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET OBSTETRIC ADVERSE HISTORY - [' || i_lang || ',' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ',' || i_patient || ',' || i_flg_filter || ']';
    
        IF NOT get_doc_area_obstetric_content(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_patient           => i_patient,
                                              i_flg_filter        => i_flg_filter,
                                              i_doc_area          => pk_pregnancy_core.g_doc_area_obs_adv,
                                              o_obstetric_history => o_obstetric_adverse_history,
                                              o_error             => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_obstetric_adverse_history);
            RETURN error_handling(i_lang, 'GET OBSTETRIC ADVERSE HISTORY', g_error, SQLERRM, FALSE, o_error);
        
    END get_obstetric_adverse_history;

    /********************************************************************************************
    * Gets obstetric index resume. (TPAL)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_flg_filter             Varchar 'ALL','LAST','MINE','LASTMINE'
    *                        
    * @return                         Title, value and context
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/

    FUNCTION get_obstetric_resume
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_filter IN VARCHAR2,
        o_result     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config_obs_idx CONSTANT sys_config.id_sys_config%TYPE := 'PREGNANCY_OBSTETRIC_INDEX';
        l_val_config_obs_idx sys_config.value%TYPE;
        l_config_obs_idx_count    CONSTANT sys_config.id_sys_config%TYPE := 'OBSTETRIC_INDEX_COUNT_LIVING_STATUS';
        l_config_newborn_cur_stat CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_CURR_STATUS_MULTICHOICE';
    
        l_val_config_obs_idx_count sys_config.value%TYPE;
        l_val_config_bew_born_stat sys_config.value%TYPE;
    
        c_code_msg_term      CONSTANT sys_message.code_message%TYPE := 'EHR_VIEWER_T231';
        c_code_msg_preterm   CONSTANT sys_message.code_message%TYPE := 'EHR_VIEWER_T232';
        c_code_msg_liveborns CONSTANT sys_message.code_message%TYPE := 'EHR_VIEWER_T233';
        c_code_msg_abortions CONSTANT sys_message.code_message%TYPE := 'EHR_VIEWER_T261';
    
        l_indexes_type VARCHAR2(5) := 'TPAL';
    
        l_desc_msg_term      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                     i_code_mess => c_code_msg_term);
        l_desc_msg_preterm   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                     i_code_mess => c_code_msg_preterm);
        l_desc_msg_liveborns sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                     i_code_mess => c_code_msg_liveborns);
        l_desc_msg_abortions sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                     i_code_mess => c_code_msg_abortions);
        l_row_obs_index      v_obstetric_index%ROWTYPE;
    
        l_exception EXCEPTION;
        l_live_children NUMBER;
        l_count_status  NUMBER;
    
    BEGIN
        g_error                    := 'GET INDEXEX CONFIG';
        l_val_config_obs_idx       := pk_sysconfig.get_config(i_code_cf => l_config_obs_idx, i_prof => i_prof);
        l_val_config_obs_idx_count := pk_sysconfig.get_config(i_code_cf => l_config_obs_idx_count, i_prof => i_prof);
        l_val_config_bew_born_stat := pk_sysconfig.get_config(i_code_cf => l_config_newborn_cur_stat, i_prof => i_prof);
    
        g_error := 'VERIFY IF INDEX TYPE TPAL EXISTS';
        IF instr(l_val_config_obs_idx, '|' || l_indexes_type || '|') != 0
        THEN
        
            SELECT *
              INTO l_row_obs_index
              FROM v_obstetric_index v_obs
             WHERE v_obs.id_patient = i_patient;
        
            -- validate if the newborn current status should be used to the obstetric index
            IF l_val_config_obs_idx_count = pk_alert_constant.g_yes
               AND l_val_config_bew_born_stat = pk_alert_constant.g_yes
            THEN
            
                SELECT COUNT(ppf.id_pat_pregnancy)
                  INTO l_count_status
                  FROM pat_pregn_fetus ppf
                 INNER JOIN pat_pregnancy pp
                    ON ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                 WHERE pp.id_patient = i_patient
                   AND pp.flg_status <> 'C'
                   AND ppf.flg_status IN ('A', 'AN')
                   AND ppf.flg_present_health = pk_alert_constant.g_no;
            
                l_live_children := l_row_obs_index.live_children - l_count_status;
            ELSE
                l_live_children := l_row_obs_index.live_children;
            END IF;
        
            g_error := 'CREATE CURSOR WITH RESULTS';
            OPEN o_result FOR
                SELECT l_desc_msg_term title, l_row_obs_index.term counter, g_ended_child_births_context CONTEXT
                  FROM dual
                UNION ALL
                SELECT l_desc_msg_preterm message, l_row_obs_index.preterm counter, g_n_ended_child_births_cont CONTEXT
                  FROM dual
                UNION ALL
                SELECT l_desc_msg_abortions message, l_row_obs_index.abortions counter, g_abortions_pregnancies CONTEXT
                  FROM dual
                UNION ALL
                SELECT l_desc_msg_liveborns message, l_live_children counter, g_alive_children_context CONTEXT
                  FROM dual;
        
            RETURN TRUE;
        ELSE
            RAISE l_exception;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_result);
            RETURN error_handling(i_lang, 'GET_OBSTETRIC_INDEX', g_error, SQLERRM, FALSE, o_error);
    END get_obstetric_resume;

    /********************************************************************************************
    * Gets obstetric index details. (TPAL)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_context                Context - 'TERMO', 'PRETERMO', ''ABORTOSGRAVIDEZES', 'FILHOSVIVOS'    
    * @param i_filter                 Varchar 'ALL','LAST','MINE','LASTMINE'
    *                   
    * @return                         
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/

    FUNCTION get_tpal_index_item_details
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_context IN VARCHAR2,
        i_filter  IN VARCHAR2,
        o_details OUT t_item_index_details,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_mess sys_message.desc_message%TYPE;
    
        dt pat_pregnancy.dt_init_pregnancy%TYPE := NULL;
        l_config_obs_idx_count    CONSTANT sys_config.id_sys_config%TYPE := 'OBSTETRIC_INDEX_COUNT_LIVING_STATUS';
        l_config_newborn_cur_stat CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_CURR_STATUS_MULTICHOICE';
    
        l_val_config_obs_idx_count sys_config.value%TYPE;
        l_val_config_bew_born_stat sys_config.value%TYPE;
        l_live_children            NUMBER;
        l_count_status             NUMBER;
    
    BEGIN
    
        l_val_config_obs_idx_count := pk_sysconfig.get_config(i_code_cf => l_config_obs_idx_count, i_prof => i_prof);
    
        l_val_config_bew_born_stat := pk_sysconfig.get_config(i_code_cf => l_config_newborn_cur_stat, i_prof => i_prof);
    
        IF (i_filter = pk_pregnancy.g_obstetric_resume_all)
        THEN
            g_error := 'VERIFY IF CONTEXT IS ENDED CHILD BIRTHS';
            IF i_context = g_ended_child_births_context
            THEN
                l_mess := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T237');
                SELECT t_item_index_detail(id_pat_pregnancy => patpreg.id_pat_pregnancy,
                                            description      => l_mess,
                                            professional     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                 i_prof    => i_prof,
                                                                                                 i_prof_id => patpreg.id_professional),
                                            dt_register      => CASE
                                                                    WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                     patpreg.dt_init_pregnancy
                                                                    WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                     patpreg.dt_intervention
                                                                END,
                                            dt_register_term => CASE
                                                                    WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                     'N'
                                                                    WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                     'Y'
                                                                END,
                                            dt_register_init => CASE
                                                                    WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                     'Y'
                                                                    WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                     'N'
                                                                END,
                                            speciality       => pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                                                                 i_prof      => i_prof,
                                                                                                 i_prof_id   => patpreg.id_professional,
                                                                                                 i_prof_inst => i_prof.institution),
                                            counter          => NULL)
                  BULK COLLECT
                  INTO o_details
                  FROM pat_pregnancy patpreg
                 WHERE patpreg.id_patient = i_patient
                   AND patpreg.flg_status = pk_pregnancy_core.g_pat_pregn_past
                   AND (patpreg.dt_intervention IS NOT NULL)
                   AND (patpreg.dt_init_pregnancy IS NOT NULL)
                   AND nvl(patpreg.flg_dt_interv_precision, pk_pregnancy_core.g_dt_flg_precision_h) IN
                       (pk_pregnancy_core.g_dt_flg_precision_d, pk_pregnancy_core.g_dt_flg_precision_h)
                   AND patpreg.dt_intervention - patpreg.dt_init_pregnancy >= numtodsinterval(37 * 7, 'DAY');
            
            ELSE
                g_error := 'VERIFY IF CONTEXT IS N ENDED CHILD BIRTHS';
                IF i_context = g_n_ended_child_births_cont
                THEN
                    l_mess := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T238');
                    SELECT t_item_index_detail(id_pat_pregnancy => patpreg.id_pat_pregnancy,
                                                description      => l_mess,
                                                professional     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                     i_prof    => i_prof,
                                                                                                     i_prof_id => patpreg.id_professional),
                                                dt_register      => CASE
                                                                        WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                         patpreg.dt_init_pregnancy
                                                                        WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                         patpreg.dt_intervention
                                                                    END,
                                                dt_register_term => CASE
                                                                        WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                         'N'
                                                                        WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                         'Y'
                                                                    END,
                                                dt_register_init => CASE
                                                                        WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                         'Y'
                                                                        WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                         'N'
                                                                    END,
                                                speciality       => pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                                                                     i_prof      => i_prof,
                                                                                                     i_prof_id   => i_prof.id,
                                                                                                     i_prof_inst => patpreg.id_professional),
                                                counter          => NULL)
                      BULK COLLECT
                      INTO o_details
                      FROM pat_pregnancy patpreg
                     WHERE patpreg.id_patient = i_patient
                       AND patpreg.flg_status = pk_pregnancy_core.g_pat_pregn_past
                       AND (patpreg.dt_intervention IS NOT NULL)
                       AND (patpreg.dt_init_pregnancy IS NOT NULL)
                       AND nvl(patpreg.flg_dt_interv_precision, pk_pregnancy_core.g_dt_flg_precision_h) IN
                           (pk_pregnancy_core.g_dt_flg_precision_d, pk_pregnancy_core.g_dt_flg_precision_h)
                       AND patpreg.dt_intervention - patpreg.dt_init_pregnancy < numtodsinterval(37 * 7, 'DAY');
                ELSE
                    g_error := 'VERIFY IF CONTEXT IS ABORTIONS';
                    IF i_context = g_abortions_pregnancies
                    THEN
                    
                        SELECT t_item_index_detail(id_pat_pregnancy => patpreg.id_pat_pregnancy,
                                                    description      => CASE
                                                                            WHEN instr(g_preg_induced_abortions, '|' || patpreg.flg_status || '|') != 0 THEN
                                                                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T240')
                                                                            WHEN instr(g_preg_spontaneous_abortions, '|' || patpreg.flg_status || '|') != 0 THEN
                                                                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T239')
                                                                            WHEN instr(g_preg_molar, patpreg.flg_status) != 0 THEN
                                                                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T320')
                                                                            WHEN instr(g_preg_etopic, patpreg.flg_status) != 0 THEN
                                                                             pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T241')
                                                                        END,
                                                    
                                                    professional     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                         i_prof    => i_prof,
                                                                                                         i_prof_id => patpreg.id_professional),
                                                    dt_register      => CASE
                                                                            WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                             patpreg.dt_init_pregnancy
                                                                            WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                             patpreg.dt_intervention
                                                                        END,
                                                    dt_register_term => CASE
                                                                            WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                             'N'
                                                                            WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                             'Y'
                                                                        END,
                                                    dt_register_init => CASE
                                                                            WHEN patpreg.dt_init_pregnancy IS NOT NULL THEN
                                                                             'Y'
                                                                            WHEN patpreg.dt_intervention IS NOT NULL THEN
                                                                             'N'
                                                                        END,
                                                    speciality       => pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                                                                         i_prof      => i_prof,
                                                                                                         i_prof_id   => patpreg.id_professional,
                                                                                                         i_prof_inst => i_prof.institution),
                                                    counter          => NULL)
                          BULK COLLECT
                          INTO o_details
                        
                          FROM pat_pregnancy patpreg
                         WHERE patpreg.id_patient = i_patient
                           AND patpreg.flg_status NOT IN
                               (pk_pregnancy_core.g_pat_pregn_active,
                                pk_pregnancy_core.g_pat_pregn_cancel,
                                pk_pregnancy_core.g_pat_pregn_past,
                                pk_pregnancy_core.g_pat_pregn_auto_close);
                    
                    ELSE
                        g_error := 'VERIFY IF CONTEXT IS CHILDREN ALIVE';
                        IF i_context = g_alive_children_context
                        THEN
                            l_mess := pk_message.get_message(i_lang => i_lang, i_code_mess => 'EHR_VIEWER_T242');
                            SELECT t_item_index_detail(id_pat_pregnancy => id_pat_pregnancy,
                                                        description      => l_mess,
                                                        professional     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                             i_prof    => i_prof,
                                                                                                             i_prof_id => prof),
                                                        dt_register      => CASE
                                                                                WHEN dt_init_pregnancy IS NOT NULL THEN
                                                                                 dt_init_pregnancy
                                                                                WHEN dt_intervention IS NOT NULL THEN
                                                                                 dt_intervention
                                                                            END,
                                                        dt_register_term => CASE
                                                                                WHEN dt_init_pregnancy IS NOT NULL THEN
                                                                                 'N'
                                                                                WHEN dt_intervention IS NOT NULL THEN
                                                                                 'Y'
                                                                            END,
                                                        dt_register_init => CASE
                                                                                WHEN dt_init_pregnancy IS NOT NULL THEN
                                                                                 'Y'
                                                                                WHEN dt_intervention IS NOT NULL THEN
                                                                                 'N'
                                                                            END,
                                                        speciality       => pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                                                                             i_prof      => i_prof,
                                                                                                             i_prof_id   => prof,
                                                                                                             i_prof_inst => i_prof.institution),
                                                        counter          => nchildren)
                              BULK COLLECT
                              INTO o_details
                            
                              FROM (SELECT DISTINCT patpreg.id_pat_pregnancy id_pat_pregnancy,
                                                    patpreg.dt_init_pregnancy dt_init_pregnancy,
                                                    patpreg.dt_intervention dt_intervention,
                                                    patpreg.id_professional prof,
                                                    (SELECT COUNT(pf.id_pat_pregn_fetus)
                                                       FROM pat_pregn_fetus pf
                                                      WHERE pf.id_pat_pregnancy = patpreg.id_pat_pregnancy
                                                        AND pf.flg_status IN
                                                            (pk_pregnancy_core.g_pregn_fetus_alive,
                                                             pk_pregnancy_core.g_pregn_fetus_an)
                                                        AND ((l_val_config_obs_idx_count = pk_alert_constant.g_yes AND
                                                            l_val_config_bew_born_stat = pk_alert_constant.g_yes AND
                                                            nvl(pf.flg_present_health, g_yes) = pk_alert_constant.g_yes) OR
                                                            (l_val_config_obs_idx_count = pk_alert_constant.g_no OR
                                                            l_val_config_bew_born_stat = pk_alert_constant.g_no))) nchildren
                                    
                                      FROM pat_pregnancy patpreg
                                     INNER JOIN pat_pregn_fetus patpregfet
                                        ON patpregfet.id_pat_pregnancy = patpreg.id_pat_pregnancy
                                     WHERE patpreg.id_patient = i_patient
                                       AND patpreg.flg_status NOT IN
                                           (pk_pregnancy_core.g_pat_pregn_cancel,
                                            pk_pregnancy_core.g_pat_pregn_auto_close)
                                       AND patpregfet.flg_status IN
                                           (pk_pregnancy_core.g_pregn_fetus_alive, pk_pregnancy_core.g_pregn_fetus_an)
                                       AND ((l_val_config_obs_idx_count = pk_alert_constant.g_yes AND
                                           l_val_config_bew_born_stat = pk_alert_constant.g_yes AND
                                           nvl(patpregfet.flg_present_health, pk_alert_constant.g_yes) =
                                           pk_alert_constant.g_yes) OR
                                           (l_val_config_obs_idx_count = pk_alert_constant.g_no OR
                                           l_val_config_bew_born_stat = pk_alert_constant.g_no)));
                        
                        ELSE
                            RETURN FALSE;
                        
                        END IF;
                    
                    END IF;
                
                END IF;
            
            END IF;
        ELSE
            RETURN FALSE;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_TPAL_INDEX_ITEM_DETAILS', g_error, SQLERRM, FALSE, o_error);
    END get_tpal_index_item_details;

    /********************************************************************************************
    * Gets obstetric index details. (TPAL)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_context                Context - 'TERMO', 'PRETERMO', ''ABORTOSGRAVIDEZES', 'FILHOSVIVOS'  
    * @param i_filter             Varchar 'ALL','LAST','MINE','LASTMINE'                  
    * @return                         
    * 
    * @author                         Gisela Couto
    * @version                        2.6.3.10.1
    * @since                          2014/02/07
    **********************************************************************************************/
    FUNCTION get_obstetric_item_details
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_context IN VARCHAR2,
        i_filter  IN VARCHAR2,
        o_details OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_details        t_item_index_details;
        l_mess_init_date sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'WOMAN_HEALTH_T168');
        l_mess_term_date sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'WOMAN_HEALTH_T145');
    BEGIN
        g_error := 'GET TPAL INDEX ITEM DETAILS - [' || i_lang || ',' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ',' || i_patient || ',' || i_context || ']';
        IF NOT get_tpal_index_item_details(i_lang    => i_lang,
                                           i_prof    => i_prof,
                                           i_patient => i_patient,
                                           i_context => i_context,
                                           i_filter  => i_filter,
                                           o_details => l_details,
                                           o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        OPEN o_details FOR
            SELECT REPLACE(tbl.description, '@1', tbl.counter) AS description,
                   tbl.professional AS professional,
                   CASE
                        WHEN tbl.dt_register_term = 'Y' THEN
                         '(' || l_mess_term_date || ': ' ||
                         pk_date_utils.dt_chr_tsz(i_lang, tbl.dt_register, i_prof.institution, i_prof.software) || ')'
                        WHEN tbl.dt_register_init = 'Y' THEN
                         '(' || l_mess_init_date || ': ' ||
                         pk_date_utils.dt_chr_tsz(i_lang, tbl.dt_register, i_prof.institution, i_prof.software) || ')'
                    END AS dt_register,
                   tbl.speciality AS speciality
              FROM TABLE(l_details) tbl
             ORDER BY tbl.dt_register DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_details);
            RETURN error_handling(i_lang, 'GET_OBSTETRIC_ITEM_DETAILS', g_error, SQLERRM, FALSE, o_error);
        
    END get_obstetric_item_details;

    FUNCTION get_pregnancy_popup_limits
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_value       IN NUMBER DEFAULT NULL,
        o_type_popup  OUT VARCHAR2,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_number_pregn NUMBER;
    
        l_cfg_inf_limit_popup sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_CONTROL_NUMBER_INF_LIMIT',
                                                                               i_prof);
        l_cfg_sup_limit_popup sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_CONTROL_NUMBER_SUP_LIMIT',
                                                                               i_prof);
    
        l_cfg_inf_limit sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_NUM_INF_LIMIT', i_prof);
        l_cfg_sup_limit sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_NUM_SUP_LIMIT', i_prof);
        l_msg_inf_limit sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'WOMAN_HEALTH_M012');
        l_msg_sup_limit sys_message.desc_message%TYPE := REPLACE(pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'WOMAN_HEALTH_M013'),
                                                                 '@1',
                                                                 l_cfg_sup_limit);
    
        l_type_popup_read    VARCHAR2(1 CHAR) := 'R';
        l_type_popup_confirm VARCHAR2(1 CHAR) := 'C';
    BEGIN
    
        o_title_popup := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_T175');
    
        IF i_value IS NULL
        THEN
            SELECT COUNT(*)
              INTO l_number_pregn
              FROM pat_pregnancy pp
             WHERE pp.id_patient = i_patient
               AND pp.flg_status = 'P';
        ELSE
            l_number_pregn := i_value;
        END IF;
    
        IF l_number_pregn >= l_cfg_inf_limit
           AND l_number_pregn < l_cfg_sup_limit
           AND (l_cfg_inf_limit_popup = pk_alert_constant.g_yes)
        THEN
            o_type_popup := l_type_popup_confirm;
            o_msg_popup  := REPLACE(l_msg_inf_limit, '@1', l_number_pregn);
        ELSIF l_number_pregn >= l_cfg_sup_limit
              AND (l_cfg_sup_limit_popup = pk_alert_constant.g_yes)
        THEN
            o_type_popup := l_type_popup_read;
            o_msg_popup  := l_msg_sup_limit;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_LIMITED_PREGNANCY_POPUP', g_error, SQLERRM, FALSE, o_error);
        
    END get_pregnancy_popup_limits;

    FUNCTION get_limited_pregnancy_popup
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_type_popup  OUT VARCHAR2,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT get_pregnancy_popup_limits(i_lang        => i_lang,
                                          i_prof        => i_prof,
                                          i_patient     => i_patient,
                                          o_type_popup  => o_type_popup,
                                          o_title_popup => o_title_popup,
                                          o_msg_popup   => o_msg_popup,
                                          o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_LIMITED_PREGNANCY_POPUP', g_error, SQLERRM, FALSE, o_error);
        
    END get_limited_pregnancy_popup;

    FUNCTION get_patient_age_pregnancy
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_dt_birth    IN VARCHAR2 DEFAULT NULL,
        o_title_popup OUT VARCHAR2,
        o_msg_popup   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient_age       patient.age%TYPE;
        l_patient_dt_birth  patient.dt_birth%TYPE;
        l_pregnancy_date    DATE;
        l_patient_age_union patient.age%TYPE;
    
        l_cfg_below sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_WARN_BELOW_AGE', i_prof);
        l_cfg_inf   sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_WARN_INF_LIM_AGE', i_prof);
        l_cfg_sup   sys_config.value%TYPE := pk_sysconfig.get_config('PREGNANCY_WARN_SUP_LIM_AGE', i_prof);
    
    BEGIN
    
        o_title_popup := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_T175');
    
        SELECT pp.age, pp.dt_birth
          INTO l_patient_age, l_patient_dt_birth
          FROM patient pp
         WHERE pp.id_patient = i_patient;
    
        IF i_dt_birth IS NOT NULL
        THEN
            l_pregnancy_date    := to_date(substr(i_dt_birth, 7, 2) || '/' || substr(i_dt_birth, 5, 2) || '/' ||
                                           substr(i_dt_birth, 0, 4),
                                           'DD/MM/YYYY');
            l_patient_age_union := trunc((months_between(l_patient_dt_birth, l_pregnancy_date) / 12), 0);
        ELSE
            IF l_patient_dt_birth IS NOT NULL
            THEN
                l_patient_age_union := trunc((months_between(SYSDATE, l_patient_dt_birth) / 12), 0);
            ELSIF l_patient_age IS NOT NULL
            THEN
                l_patient_age_union := l_patient_age;
            ELSE
                l_patient_age_union := NULL;
            END IF;
        END IF;
    
        IF l_patient_age_union IS NOT NULL
        THEN
            IF l_patient_age_union <= l_cfg_below
               OR (l_patient_age_union BETWEEN l_cfg_inf AND l_cfg_sup)
            THEN
                o_msg_popup := pk_message.get_message(i_lang => i_lang, i_code_mess => 'WOMAN_HEALTH_M014');
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_PATIENT_AGE_PREGNANY', g_error, SQLERRM, FALSE, o_error);
        
    END get_patient_age_pregnancy;

    /********************************************************************************************
    * Returns the number of lived fetus
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)       
    * @param i_patient                patient ID
    *                        
    * @return                         number of lived fetus
    * 
    * @author                         Vanessa Barsottelli
    * @version                        1.0
    * @since                          01/02/2017
    **********************************************************************************************/
    FUNCTION get_count_lived_fetus
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE DEFAULT NULL
    ) RETURN NUMBER IS
        l_count_lived_fetus NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count_lived_fetus
          FROM pat_pregnancy p
          JOIN pat_pregn_fetus ppf
            ON ppf.id_pat_pregnancy = p.id_pat_pregnancy
         WHERE p.id_patient = i_patient
           AND (i_pat_pregnancy IS NULL OR p.id_pat_pregnancy = i_pat_pregnancy)
           AND p.flg_status IN (pk_pregnancy_core.g_pat_pregn_active,
                                pk_pregnancy_core.g_pat_pregn_past,
                                pk_pregnancy_core.g_pat_pregn_no)
           AND instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0;
    
        RETURN l_count_lived_fetus;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_count_lived_fetus;

    /********************************************************************************************
    * Returns the last pregnancy fetus status condition do NOM024
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    * @param i_patient                patient ID        
    * @param i_pat_pregnancy          pat_pregnancy ID
    *                        
    * @return                         fetus status
    * 
    * @author                         Vanessa Barsottelli
    * @version                        1.0
    * @since                          01/02/2017
    **********************************************************************************************/
    FUNCTION get_past_pregn_fetus_status
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
        l_last_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_fetus_status       pat_pregn_fetus.flg_status%TYPE;
        l_return             VARCHAR2(2char);
    BEGIN
        BEGIN
            SELECT p.id_pat_pregnancy
              INTO l_last_pat_pregnancy
              FROM (SELECT pp1.id_pat_pregnancy,
                           row_number() over(PARTITION BY pp1.id_patient ORDER BY pp1.n_pregnancy DESC) rn
                      FROM pat_pregnancy pp1
                     WHERE pp1.id_patient = i_patient
                       AND pp1.flg_status NOT IN
                           (pk_pregnancy_core.g_pat_pregn_cancel, pk_pregnancy_core.g_pat_pregn_active)
                       AND pp1.n_pregnancy < (SELECT pp2.n_pregnancy
                                                FROM pat_pregnancy pp2
                                               WHERE pp2.id_pat_pregnancy = i_pat_pregnancy)) p
             WHERE p.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_last_pat_pregnancy := NULL;
        END;
    
        IF l_last_pat_pregnancy IS NULL
        THEN
            l_return := 'AS';
        ELSE
            SELECT ppf.flg_status
              INTO l_fetus_status
              FROM pat_pregn_fetus ppf
             WHERE ppf.id_pat_pregnancy = l_last_pat_pregnancy;
        
            IF instr(l_fetus_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0
            THEN
                l_return := 'A';
            ELSIF instr(l_fetus_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0
            THEN
                l_return := 'D';
            ELSIF l_fetus_status = pk_pregnancy_core.g_pregn_fetus_si
            THEN
                l_return := 'SI';
            ELSE
                l_return := 'NE';
            END IF;
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_past_pregn_fetus_status;

    FUNCTION get_fetus_present_health
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
        l_last_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_flg_present_health pat_pregn_fetus.flg_present_health%TYPE;
        l_fetus_status       VARCHAR(2 CHAR);
        l_return             VARCHAR(2 CHAR);
    BEGIN
        l_fetus_status := pk_pregnancy.get_past_pregn_fetus_status(i_prof, i_patient, i_pat_pregnancy);
    
        IF l_fetus_status = 'A'
        THEN
            BEGIN
                SELECT p.id_pat_pregnancy
                  INTO l_last_pat_pregnancy
                  FROM (SELECT pp1.id_pat_pregnancy,
                               row_number() over(PARTITION BY pp1.id_patient ORDER BY pp1.n_pregnancy DESC) rn
                          FROM pat_pregnancy pp1
                         WHERE pp1.id_patient = i_patient
                           AND pp1.flg_status NOT IN
                               (pk_pregnancy_core.g_pat_pregn_cancel, pk_pregnancy_core.g_pat_pregn_active)
                           AND pp1.n_pregnancy < (SELECT pp2.n_pregnancy
                                                    FROM pat_pregnancy pp2
                                                   WHERE pp2.id_pat_pregnancy = i_pat_pregnancy)) p
                 WHERE p.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_last_pat_pregnancy := NULL;
            END;
        
            IF l_last_pat_pregnancy IS NOT NULL
            THEN
                SELECT ppf.flg_present_health
                  INTO l_flg_present_health
                  FROM pat_pregn_fetus ppf
                 WHERE ppf.id_pat_pregnancy = l_last_pat_pregnancy;
            
                l_return := nvl(l_flg_present_health, 'NE');
            END IF;
        
        ELSIF l_fetus_status IN ('D', 'AS')
        THEN
            l_return := 'NA';
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fetus_present_health;

    FUNCTION get_past_pregn_dt_interv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
        l_last_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_dt_intervention    pat_pregnancy.dt_intervention%TYPE;
        l_return             VARCHAR2(200 CHAR);
    BEGIN
        BEGIN
            SELECT p.id_pat_pregnancy, p.dt_intervention
              INTO l_last_pat_pregnancy, l_dt_intervention
              FROM (SELECT pp1.id_pat_pregnancy,
                           pp1.dt_intervention,
                           row_number() over(PARTITION BY pp1.id_patient ORDER BY pp1.n_pregnancy DESC) rn
                      FROM pat_pregnancy pp1
                     WHERE pp1.id_patient = i_patient
                       AND pp1.flg_status NOT IN
                           (pk_pregnancy_core.g_pat_pregn_cancel, pk_pregnancy_core.g_pat_pregn_active)
                       AND pp1.n_pregnancy < (SELECT pp2.n_pregnancy
                                                FROM pat_pregnancy pp2
                                               WHERE pp2.id_pat_pregnancy = i_pat_pregnancy)) p
             WHERE p.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_last_pat_pregnancy := NULL;
        END;
    
        IF l_last_pat_pregnancy IS NOT NULL
        THEN
            l_return := to_char(l_dt_intervention, 'DD/MM/YYYY');
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_past_pregn_dt_interv;

    FUNCTION get_summary_page_sections
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_summary_page IN summary_page.id_summary_page%TYPE,
        i_pat             IN patient.id_patient%TYPE,
        o_sections        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market market.id_market%TYPE;
        l_inst   institution.id_institution%TYPE;
        l_soft   software.id_software%TYPE;
        l_age    patient.age%TYPE;
        l_gender patient.gender%TYPE;
    
        l_register pk_touch_option.t_rec_doc_area_register;
        l_val      pk_touch_option.t_rec_doc_area_val;
    
    BEGIN
    
        SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0)) age_in_years
          INTO l_gender, l_age
          FROM patient p
         WHERE p.id_patient = i_pat;
    
        pk_touch_option.get_dais_cfg_vars(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_summary_page => i_id_summary_page,
                                          o_market       => l_market,
                                          o_inst         => l_inst,
                                          o_soft         => l_soft);
    
        OPEN o_sections FOR
            SELECT pk_translation.get_translation(i_lang, sps.code_summary_page_section) translated_code,
                   sps.id_doc_area doc_area,
                   sps.screen_name,
                   sps.id_sys_shortcut,
                   g_yes flg_write, -- no access check -> write access
                   g_no flg_search, -- no access check -> no search access
                   g_yes flg_no_changes, -- no access check -> no_changes access
                   decode(sps.id_doc_area, NULL, g_no, pk_pregnancy_core.g_doc_area_obs_idx_tmpl, g_yes, g_no) flg_template,
                   sps.height,
                   dais.flg_type,
                   sps.screen_name_after_save,
                   pk_translation.get_translation(i_lang, sps.code_page_section_subtitle) subtitle,
                   da.intern_name_sample_text_type,
                   da.flg_score,
                   sps.screen_name_free_text,
                   dais.flg_scope_type,
                   dais.flg_data_paging_enabled,
                   dais.page_size
              FROM summary_page sp
             INNER JOIN summary_page_section sps
                ON sp.id_summary_page = sps.id_summary_page
             INNER JOIN doc_area da
                ON sps.id_doc_area = da.id_doc_area
             INNER JOIN doc_area_inst_soft dais
                ON da.id_doc_area = dais.id_doc_area
             WHERE sp.id_summary_page = i_id_summary_page
               AND dais.id_institution = l_inst
               AND dais.id_software = l_soft
               AND nvl(dais.id_market, 0) = l_market
               AND (da.gender IS NULL OR da.gender = l_gender OR l_gender = 'I')
               AND (da.age_min IS NULL OR da.age_min <= l_age OR l_age IS NULL)
               AND (da.age_max IS NULL OR da.age_max >= l_age OR l_age IS NULL)
             ORDER BY sps.rank, 1;
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
            pk_types.open_my_cursor(o_sections);
            RETURN FALSE;
    END get_summary_page_sections;

    FUNCTION get_flg_pregn_out_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_flg_pregn OUT pat_pregnancy.flg_preg_out_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT pk_pregnancy_core.get_flg_pregn_out_type(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_episode   => i_episode,
                                                        o_flg_pregn => o_flg_pregn,
                                                        o_error     => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_FLG_PREGN_OUT_TYPE',
                                              o_error);
            RETURN FALSE;
        
    END get_flg_pregn_out_type;

    /********************************************************************************************
    * Gets the obstetric indexes to place in the summary page
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                Patient ID
    *                        
    * @return                         Pregnancy formatted obstetric indexes
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.7.4.1
    * @since                          18/09/2018
    **********************************************************************************************/
    FUNCTION get_obstetric_index
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_obst_index VARCHAR2(4000 CHAR);
    
    BEGIN
        l_obst_index := pk_pregnancy_core.get_obstetric_index(i_lang, i_prof, i_patient, 'T');
        l_obst_index := l_obst_index || ': ' || pk_pregnancy_core.get_obstetric_index(i_lang, i_prof, i_patient, 'C');
        l_obst_index := REPLACE(REPLACE(l_obst_index, '<b>', ''), '</b>', '');
        RETURN l_obst_index;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_obstetric_index;

    /**************************************************************************
    * get import data from current pregnancy
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    *
    * @return varchar2                Current pregnacy description for summary page
    *                                                                         
    * @author                         Ana Moita                   
    * @version                        2.8                            
    * @since                          18/08/2021                            
    **************************************************************************/
    FUNCTION get_sp_current_pregnacy
    
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_pat     IN patient.id_patient%TYPE
    ) RETURN CLOB IS
    
        l_doc_area_register t_doc_area_register;
        l_doc_area_val      t_doc_area_val;
        l_function_name     VARCHAR2(30 CHAR) := 'GET_IMPORT_CURRENT_PREGNANCY';
        l_error             t_error_out;
        l_desc              CLOB; --VARCHAR2(4000 CHAR);
    BEGIN
    
        IF NOT get_sum_page_doc_area_preg_int(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_pat               => i_pat,
                                              i_doc_area          => pk_pregnancy_core.g_doc_area_curr_pregn,
                                              o_doc_area_register => l_doc_area_register,
                                              o_doc_area_val      => l_doc_area_val,
                                              o_error             => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        FOR i IN l_doc_area_val.first .. l_doc_area_val.last
        
        LOOP
            IF i = 1
            THEN
                l_desc := l_doc_area_val(i).desc_doc_component || ': ' || l_doc_area_val(i).desc_element;
            ELSE
                l_desc := l_desc || ' ' || l_doc_area_val(i).desc_doc_component || ' ' || l_doc_area_val(i).desc_element;
            END IF;
        END LOOP;
    
        l_desc := REPLACE(REPLACE(REPLACE(l_desc, '<b>', ''), '</b>', ''), '<br>', '');
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sp_current_pregnacy;
BEGIN
    -- Initialization
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);

END pk_pregnancy;
/
