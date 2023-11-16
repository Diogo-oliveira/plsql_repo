/*-- Last Change Revision: $Rev: 2027491 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_pregnancy_core IS
    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    --BEGIN AUX XML EXAM FUNCTION
    --Auxiliar functions that extracts exam sequence values
    --This functions simplied the readability of the code
    FUNCTION get_exam_diags
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_diags      IN xmltype
    ) RETURN pk_edis_types.rec_in_epis_diagnosis IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_EXAM_DIAGS';
        --
        l_tbl_id_diags       table_number;
        l_tbl_id_alert_diags table_number;
        l_tbl_descs_diags    table_varchar;
    
    BEGIN
    
        g_error := 'EXTRACT EXAM DIAGS ID''s';
        SELECT c.id_diagnosis, c.id_alert_diagnosis, c.description
          BULK COLLECT
          INTO l_tbl_id_diags, l_tbl_id_alert_diags, l_tbl_descs_diags
          FROM (SELECT VALUE(a) diagnose
                  FROM TABLE(xmlsequence(extract(i_diags, '/DIAGNOSES/*'))) a) b,
               xmltable('/DIAGNOSIS' passing b.diagnose columns --
                        "ID_DIAGNOSIS" NUMBER(24) path '@ID_DIAGNOSIS',
                        "ID_ALERT_DIAGNOSIS" NUMBER(24) path '@ID_ALERT_DIAGNOSIS',
                        "DESCRIPTION" VARCHAR2(200 CHAR) path '@DESC') c;
    
        RETURN pk_diagnosis.get_diag_rec(i_lang            => i_lang,
                                         i_prof            => i_prof,
                                         i_patient         => i_id_patient,
                                         i_episode         => i_id_episode,
                                         i_diagnosis       => l_tbl_id_diags,
                                         i_alert_diagnosis => l_tbl_id_alert_diags,
                                         i_desc_diag       => l_tbl_descs_diags);
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' <-> ' || SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            RETURN NULL;
    END get_exam_diags;

    FUNCTION get_exam_id_clin_quest(i_clin_quest xmltype) RETURN table_number IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_EXAM_ID_CLIN_QUEST';
        --
        l_ret table_number;
    BEGIN
        g_error := 'EXTRACT EXAM CLIN_QUEST ID''s';
        SELECT c.id
          BULK COLLECT
          INTO l_ret
          FROM (SELECT VALUE(a) clin_quest
                  FROM TABLE(xmlsequence(extract(i_clin_quest, '/CLINICAL_QUESTIONS/*'))) a) b,
               xmltable('/CLINICAL_QUESTION' passing b.clin_quest columns --
                        "ID" NUMBER(24) path '@ID') c;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' <-> ' || SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            RETURN table_number();
    END get_exam_id_clin_quest;

    FUNCTION get_exam_clin_resp(i_clin_quest xmltype) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_EXAM_CLIN_RESP';
        --
        l_ret table_varchar;
    
    BEGIN
    
        g_error := 'EXTRACT EXAM CLIN_QUEST RESPONSES';
        SELECT c.response
          BULK COLLECT
          INTO l_ret
          FROM (SELECT VALUE(a) clin_quest
                  FROM TABLE(xmlsequence(extract(i_clin_quest, '/CLINICAL_QUESTIONS/*'))) a) b,
               xmltable('/CLINICAL_QUESTION' passing b.clin_quest columns --
                        "RESPONSE" VARCHAR2(1000 CHAR) path '@RESPONSE') c;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' <-> ' || SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            RETURN table_varchar();
    END get_exam_clin_resp;

    FUNCTION get_exam_clin_notes(i_clin_quest xmltype) RETURN table_varchar IS
        l_func_name CONSTANT VARCHAR2(50) := 'GET_EXAM_CLIN_NOTES';
        --
        l_ret table_varchar;
    
    BEGIN
    
        g_error := 'EXTRACT EXAM CLIN_QUEST NOTES';
        SELECT c.notes
          BULK COLLECT
          INTO l_ret
          FROM (SELECT VALUE(a) clin_quest
                  FROM TABLE(xmlsequence(extract(i_clin_quest, '/CLINICAL_QUESTIONS/*'))) a) b,
               xmltable('/CLINICAL_QUESTION' passing b.clin_quest columns --
                        "NOTES" VARCHAR2(1000 CHAR) path '@NOTES') c;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' <-> ' || SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            RETURN table_varchar();
    END get_exam_clin_notes;
    --END AUX XML EXAM FUNCTION   

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
    
        o_error.err_desc := g_package || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package,
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
                           g_package,
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

    /********************************************************************************************
    * Returns the pregnancy start date
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks (by LMP)
    * @param i_num_weeks_exam         number of weeks (by examination)
    * @param i_num_weeks_us           number of weeks (by US)
    * @param i_dt_intervention        Intervention date (if the pregnancy is closed)
    *                        
    * @return                         pregnancy start date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/31
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_start
    (
        i_prof            IN profissional,
        i_num_weeks       IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_weeks_exam  IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_weeks_us    IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_dt_intervention IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_precision   IN pat_pregnancy.flg_dt_interv_precision%TYPE
    ) RETURN DATE IS
    
        l_init_pregnancy pat_pregnancy.dt_init_pregnancy%TYPE;
        l_num_weeks      pat_pregnancy.num_gest_weeks%TYPE;
    
    BEGIN
    
        l_num_weeks := coalesce(i_num_weeks_us, i_num_weeks_exam, i_num_weeks);
    
        IF i_flg_precision IN (g_dt_flg_precision_h, g_dt_flg_precision_d)
           OR i_dt_intervention IS NULL
        THEN
            l_init_pregnancy := CAST(pk_date_utils.trunc_insttimezone(i_prof,
                                                                      (pk_date_utils.add_to_ltstz(nvl(i_dt_intervention,
                                                                                                      current_timestamp),
                                                                                                  -l_num_weeks * 7,
                                                                                                  'DAY'))) AS DATE);
        END IF;
    
        RETURN l_init_pregnancy;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_pregnancy_start;

    /********************************************************************************************
    * Returns the pregnancy probable end date
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              number of weeks
    * @param i_dt_intervention        Pregnancy start date
    *                        
    * @return                         pregnancy end date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/04
    **********************************************************************************************/
    FUNCTION get_dt_pregnancy_end
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_num_weeks IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days  IN NUMBER,
        i_dt_init   IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN DATE IS
    
        l_end_pregnancy  pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_init        pat_pregnancy.dt_init_pregnancy%TYPE;
        l_num_weeks      pat_pregnancy.num_gest_weeks%TYPE;
        l_num_weeks_exam pat_pregnancy.num_gest_weeks_exam%TYPE;
        l_num_weeks_us   pat_pregnancy.num_gest_weeks_us%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
    BEGIN
    
        g_error := 'GET GESTATION WEEKS';
        IF NOT pk_pregnancy_core.get_gestation_weeks(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_num_weeks      => i_num_weeks,
                                                     i_num_days       => i_num_days,
                                                     i_num_weeks_exam => NULL,
                                                     i_num_days_exam  => NULL,
                                                     i_num_weeks_us   => NULL,
                                                     i_num_days_us    => NULL,
                                                     o_num_weeks      => l_num_weeks,
                                                     o_num_weeks_exam => l_num_weeks_exam,
                                                     o_num_weeks_us   => l_num_weeks_us,
                                                     o_error          => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_dt_init IS NOT NULL
        THEN
            l_dt_init := i_dt_init;
        ELSE
            l_dt_init := get_dt_pregnancy_start(i_prof            => i_prof,
                                                i_num_weeks       => l_num_weeks,
                                                i_num_weeks_exam  => NULL,
                                                i_num_weeks_us    => NULL,
                                                i_dt_intervention => NULL,
                                                i_flg_precision   => NULL);
        END IF;
    
        -- NAEGELES RULE
        l_end_pregnancy := trunc((l_dt_init + numtodsinterval(7, 'DAY')) - numtoyminterval(3, 'MONTH') +
                                 numtoyminterval(1, 'YEAR'));
    
        RETURN l_end_pregnancy;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_pregnancy_end;

    /********************************************************************************************
    * Returns all the information related with the ultrasound by pregnancy weeks and days.
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
        i_dt_us_performed     IN pat_pregnancy.dt_us_performed%TYPE,
        o_num_weeks_performed OUT NUMBER,
        o_num_days_performed  OUT NUMBER,
        o_dt_us_performed     OUT pat_pregnancy.dt_us_performed%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_init   pat_pregnancy.dt_init_pregnancy%TYPE;
        l_exception EXCEPTION;
    
        l_num_weeks           pat_pregnancy.num_gest_weeks%TYPE;
        l_num_weeks_us        pat_pregnancy.num_gest_weeks_us%TYPE;
        l_num_weeks_performed pat_pregnancy.num_gest_weeks_us%TYPE;
    
        l_weeks_performed NUMBER;
        l_days_performed  NUMBER;
        l_aux             DATE;
        l_resp            BOOLEAN;
    BEGIN
    
        o_num_weeks_performed := i_num_weeks_preg_init;
        o_num_days_performed  := i_num_days_preg_init;
        o_dt_us_performed     := i_dt_us_performed;
    
        --Calculate by inserted pregnancy weeks and days.
        g_error := 'GET GESTATION WEEKS';
        IF NOT pk_pregnancy_core.get_gestation_weeks(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_num_weeks      => i_num_weeks_preg_init,
                                                     i_num_days       => i_num_days_preg_init,
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
    
        l_dt_init := get_dt_pregnancy_start(i_prof            => i_prof,
                                            i_num_weeks       => l_num_weeks,
                                            i_num_weeks_exam  => NULL,
                                            i_num_weeks_us    => NULL,
                                            i_dt_intervention => NULL,
                                            i_flg_precision   => NULL);
    
        o_num_weeks_performed := pk_pregnancy_core.get_pregnancy_weeks(i_prof, l_dt_init, i_dt_us_performed, NULL);
    
        o_num_days_performed := pk_pregnancy_core.get_pregnancy_days(i_prof, l_dt_init, i_dt_us_performed, NULL);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_US_DT_INFO', g_error, SQLERRM, FALSE, o_error);
    END get_us_dt_info;

    /********************************************************************************************
    * Returns the pregnancy close date (formatted)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_intervention        Pregnancy start date
    * @param i_flg_precision          Date precision: (H)our, (D)ay, (M)onth or (Y)ear
    *                        
    * @return                         pregnancy end date (formatted)
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/05
    **********************************************************************************************/
    FUNCTION get_dt_intervention
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_intervention IN pat_pregnancy.dt_intervention%TYPE,
        i_flg_precision   IN pat_pregnancy.flg_dt_interv_precision%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_intervention VARCHAR2(200);
        l_flg_precision   pat_pregnancy.flg_dt_interv_precision%TYPE;
    
    BEGIN
    
        l_flg_precision := nvl(i_flg_precision, g_dt_flg_precision_h);
    
        IF l_flg_precision = g_dt_flg_precision_h
        THEN
            l_dt_intervention := pk_date_utils.date_char_tsz(i_lang,
                                                             i_dt_intervention,
                                                             i_prof.institution,
                                                             i_prof.software);
        ELSIF l_flg_precision = g_dt_flg_precision_d
        THEN
            l_dt_intervention := pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                       i_dt_intervention,
                                                                       i_prof.institution,
                                                                       i_prof.software);
        ELSIF l_flg_precision = g_dt_flg_precision_m
        THEN
            l_dt_intervention := pk_date_utils.get_month_year(i_lang, i_prof, i_dt_intervention);
        ELSIF l_flg_precision = g_dt_flg_precision_y
        THEN
            l_dt_intervention := pk_date_utils.get_year(i_lang, i_prof, i_dt_intervention);
        END IF;
    
        RETURN l_dt_intervention;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_intervention;

    /********************************************************************************************
    * Returns the pregnancy close date (formatted)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dt_contrac_end         Last use of contraceptives
    * @param i_flg_precision          Date precision: (H)our, (D)ay, (M)onth or (Y)ear
    *                        
    * @return                         formatted date
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_dt_contrac_end
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dt_contrac_end IN pat_pregnancy.dt_contrac_meth_end%TYPE,
        i_flg_precision  IN pat_pregnancy.flg_dt_contrac_precision%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_contrac_end VARCHAR2(200);
        l_flg_precision  pat_pregnancy.flg_dt_contrac_precision%TYPE;
    
    BEGIN
    
        l_flg_precision := nvl(i_flg_precision, g_dt_flg_precision_d);
    
        IF l_flg_precision = g_dt_flg_precision_d
        THEN
            l_dt_contrac_end := pk_date_utils.date_chr_short_read(i_lang,
                                                                  i_dt_contrac_end,
                                                                  i_prof.institution,
                                                                  i_prof.software);
        ELSIF l_flg_precision = g_dt_flg_precision_m
        THEN
            l_dt_contrac_end := pk_date_utils.get_month_year(i_lang, i_prof, i_dt_contrac_end);
        ELSIF l_flg_precision = g_dt_flg_precision_y
        THEN
            l_dt_contrac_end := pk_date_utils.get_year(i_lang, i_prof, i_dt_contrac_end);
        END IF;
    
        RETURN l_dt_contrac_end;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_contrac_end;

    /********************************************************************************************
    * Returns the number of pregnany weeks (formatted text)
    *
    * @param i_lang                   language ID
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    *                        
    * @return                         number of weeks
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/09/03
    **********************************************************************************************/
    FUNCTION get_pregn_formatted_weeks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_weeks      IN pat_pregnancy.num_gest_weeks%TYPE,
        i_dt_preg    IN DATE,
        i_dt_reg     IN pat_pregnancy.dt_intervention%TYPE,
        i_flg_status IN pat_pregnancy.flg_status%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_weeks NUMBER;
        l_days  NUMBER;
    
        l_code_message sys_message.code_message%TYPE;
    
        l_ret VARCHAR2(200);
    
    BEGIN
    
        g_error := 'GET PREGNANCY WEEKS';
        l_weeks := get_pregnancy_weeks(i_prof, i_dt_preg, i_dt_reg, i_weeks);
        l_days  := get_pregnancy_days(i_prof, i_dt_preg, i_dt_reg, i_weeks);
    
        IF l_weeks >=
           to_number(pk_sysconfig.get_config('PREGNANCY_MAX_NUMBER_OF_WEEKS', i_prof.institution, i_prof.software))
           AND i_flg_status = pk_pregnancy_core.g_pat_pregn_auto_close
        THEN
            l_ret := pk_message.get_message(i_lang, i_prof, 'PAT_PREGNANCY_M007');
        ELSE
        
            IF l_weeks IS NOT NULL
               OR l_days IS NOT NULL
            THEN
                IF nvl(l_days, 0) > 0
                THEN
                    IF l_weeks = 1
                    THEN
                        l_code_message := 'WOMAN_HEALTH_T162';
                    ELSE
                        l_code_message := 'WOMAN_HEALTH_T163';
                    END IF;
                ELSE
                    IF l_weeks = 1
                    THEN
                        l_code_message := 'WOMAN_HEALTH_T160';
                    ELSE
                        l_code_message := 'WOMAN_HEALTH_T161';
                    END IF;
                END IF;
            
                l_ret := REPLACE(pk_message.get_message(i_lang, l_code_message), '@1', nvl(l_weeks, 0));
                l_ret := REPLACE(l_ret, '@2', l_days);
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '0';
    END get_pregn_formatted_weeks;

    /********************************************************************************************
    * Returns the number of pregnany weeks
    *
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    *                        
    * @return                         number of weeks
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/24
    **********************************************************************************************/
    FUNCTION get_pregnancy_weeks
    (
        i_prof    IN profissional,
        i_dt_preg IN DATE,
        i_dt_reg  IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks   IN pat_pregnancy.num_gest_weeks%TYPE
    ) RETURN NUMBER IS
    
        l_dt_reg DATE;
        l_weeks  NUMBER;
    
    BEGIN
    
        g_error  := 'GET PREGNANCY WEEKS';
        l_dt_reg := nvl(CAST(i_dt_reg AS DATE), SYSDATE);
    
        IF i_dt_preg IS NOT NULL
        THEN
            l_weeks := trunc((trunc(l_dt_reg) - trunc(i_dt_preg)) / 7);
        ELSE
            l_weeks := trunc(i_weeks);
        END IF;
    
        IF l_weeks = 0
        THEN
            l_weeks := NULL;
        END IF;
    
        RETURN l_weeks;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_pregnancy_weeks;

    /********************************************************************************************
    * Returns the number of extra pregnancy days
    *
    * @param i_dt_preg                start date
    * @param i_dt_reg                 current or end date
    * @param i_weeks                  number of weeks
    *                        
    * @return                         number of days
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/05/01
    **********************************************************************************************/
    FUNCTION get_pregnancy_days
    (
        i_prof    IN profissional,
        i_dt_preg IN DATE,
        i_dt_reg  IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks   IN pat_pregnancy.num_gest_weeks%TYPE
    ) RETURN NUMBER IS
    
        l_dt_reg DATE;
        l_days   NUMBER;
        l_weeks  NUMBER;
    
    BEGIN
    
        g_error  := 'GET PREGNANCY WEEKS';
        l_dt_reg := nvl(CAST(i_dt_reg AS DATE), SYSDATE);
    
        IF i_dt_preg IS NOT NULL
        THEN
            l_weeks := (trunc(l_dt_reg) - trunc(i_dt_preg)) / 7;
            l_days  := round((l_weeks - trunc(l_weeks)) * 7);
        ELSE
            l_weeks := i_weeks;
            l_days  := round((l_weeks - trunc(l_weeks)) * 7);
        END IF;
    
        IF l_days = 0
        THEN
            l_days := NULL;
        END IF;
    
        RETURN l_days;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_pregnancy_days;

    /********************************************************************************************
    * Gets all gestation weeks (with the included days)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_num_weeks              Number of gestation weeks (by LMP)
    * @param i_day_weeks              Number of extra gestation days (by LMP)
    * @param i_num_weeks_exam         Number of gestation weeks (by examination)
    * @param i_day_weeks_exam         Number of extra gestation days (by examination)
    * @param i_num_weeks_us           Number of gestation weeks (by ultrasound)        
    * @param i_day_weeks_us           Number of extra gestation days (by ultrasound)
    * @param o_num_weeks              Complete gestation weeks (by LMP)
    * @param o_num_weeks_exam         Complete gestation weeks (by examination)
    * @param o_num_weeks_us           Complete gestation weeks (by US)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/30
    **********************************************************************************************/
    FUNCTION get_gestation_weeks
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_num_weeks      IN pat_pregnancy.num_gest_weeks%TYPE,
        i_num_days       IN NUMBER,
        i_num_weeks_exam IN pat_pregnancy.num_gest_weeks_exam%TYPE,
        i_num_days_exam  IN NUMBER,
        i_num_weeks_us   IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_num_days_us    IN NUMBER,
        o_num_weeks      OUT pat_pregnancy.num_gest_weeks%TYPE,
        o_num_weeks_exam OUT pat_pregnancy.num_gest_weeks_exam%TYPE,
        o_num_weeks_us   OUT pat_pregnancy.num_gest_weeks_us%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_num_days IS NOT NULL
        THEN
            o_num_weeks := nvl(i_num_weeks, 0) + (i_num_days / 7);
        ELSE
            o_num_weeks := i_num_weeks;
        END IF;
    
        IF i_num_days_exam IS NOT NULL
        THEN
            o_num_weeks_exam := nvl(i_num_weeks_exam, 0) + (i_num_days_exam / 7);
        ELSE
            o_num_weeks_exam := i_num_weeks_exam;
        END IF;
    
        IF i_num_days_us IS NOT NULL
        THEN
            o_num_weeks_us := nvl(i_num_weeks_us, 0) + (i_num_days_us / 7);
        ELSE
            o_num_weeks_us := i_num_weeks_us;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'GET_GESTATION_WEEKS', g_error, SQLERRM, FALSE, o_error);
    END get_gestation_weeks;

    /********************************************************************************************
    * Returns the formatted text to place in the summary page
    *
    * @param i_doc_area               doc area ID of the section where the text is being formatted    
    * @param i_title                  title string
    * @param i_desc                   body string
    * @param i_sep                    string which separates different lines
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/11
    **********************************************************************************************/
    FUNCTION get_formatted_text_break
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_title       IN VARCHAR2,
        i_desc        IN VARCHAR2,
        i_sep         IN VARCHAR2,
        i_first_title IN VARCHAR2,
        i_flg_break   IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_break VARCHAR2(10);
    
    BEGIN
    
        IF i_flg_break = pk_alert_constant.g_yes
           AND i_title <> i_first_title
        THEN
            l_break := '<br>';
        END IF;
    
        IF i_desc IS NULL
        THEN
            RETURN l_break;
        ELSE
            RETURN l_break || pk_pregnancy_core.get_formatted_text(i_doc_area, i_title, i_desc, i_sep, i_first_title);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_formatted_text_break;

    /********************************************************************************************
    * Returns the formatted text to place in the summary page
    *
    * @param i_doc_area               doc area ID of the section where the text is being formatted    
    * @param i_title                  title string
    * @param i_desc                   body string
    * @param i_sep                    string which separates different lines
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/24
    **********************************************************************************************/
    FUNCTION get_formatted_text
    (
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_title       IN VARCHAR2,
        i_desc        IN VARCHAR2,
        i_sep         IN VARCHAR2,
        i_first_title IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_sep       VARCHAR2(10);
        l_desc      VARCHAR2(4000);
        l_title     sys_message.desc_message%TYPE;
        l_title_sep VARCHAR2(10);
    
    BEGIN
    
        IF i_sep IS NOT NULL
        THEN
            l_sep := i_sep || chr(10);
        ELSE
            l_sep := '';
        END IF;
    
        -- if title is already available in the summary page do not show it again
        IF nvl(i_first_title, 'X') <> i_title
        THEN
            l_title     := i_title;
            l_title_sep := ': ';
        END IF;
    
        IF i_desc IS NOT NULL
        THEN
            l_desc := REPLACE(REPLACE(i_desc, '<', '&lt;'), '>', '&gt;');
        
            IF i_doc_area = g_doc_area_past_hist
            THEN
                RETURN l_title || l_title_sep || i_desc || l_sep;
            ELSE
                RETURN pk_utils.to_bold(l_title) || l_title_sep || l_desc || l_sep;
            END IF;
        END IF;
    
        RETURN '';
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_formatted_text;

    /********************************************************************************************
    * Returns the description of the place in which the labor/abortion occured
    * 
    * @param i_lang                   language ID 
    * @param i_id_institution         institution ID
    * @param i_flg_desc_interv        option selected: D - home; O - free text
    * @param desc_intervention        location description
    * @param i_flg_show_other         show text "Other Hospital" (Y) or not (N)
    *                        
    * @return                         formatted text
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/09/05
    **********************************************************************************************/
    FUNCTION get_desc_intervention
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN pat_pregnancy.id_inst_intervention%TYPE,
        i_flg_desc_interv   IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention IN pat_pregnancy.desc_intervention%TYPE,
        i_flg_show_other    IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
    
        l_sep CONSTANT VARCHAR2(10) := ': ';
        l_desc_interv VARCHAR2(4000);
    
    BEGIN
    
        IF i_id_institution IS NOT NULL
        THEN
            SELECT nvl(i.abbreviation, pk_translation.get_translation(i_lang, i.code_institution))
              INTO l_desc_interv
              FROM institution i
             WHERE i.id_institution = i_id_institution;
        ELSIF i_flg_desc_interv IS NOT NULL
        THEN
            IF i_flg_show_other = 'N'
               AND i_flg_desc_interv = g_other_hospital
            THEN
                -- José Brito 11/02/2009 ALERT-16940
                -- Impedir que o texto "Outro Hospital" apareça repetido
                l_desc_interv := NULL;
            ELSE
                l_desc_interv := pk_sysdomain.get_domain(g_code_domain, i_flg_desc_interv, i_lang);
            END IF;
        END IF;
    
        IF i_desc_intervention IS NOT NULL
           AND l_desc_interv IS NOT NULL
        THEN
            l_desc_interv := l_desc_interv || l_sep || i_desc_intervention;
        ELSE
            l_desc_interv := nvl(l_desc_interv, i_desc_intervention);
        END IF;
    
        RETURN l_desc_interv;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_desc_intervention;

    /********************************************************************************************
    * Returns the type of abortion
    *
    * @param i_flg_status             pregnancy status
    *                        
    * @return                         type of abortion
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/26
    **********************************************************************************************/
    FUNCTION get_abortion_type(i_flg_status IN pat_pregnancy.flg_status%TYPE) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_status IN (g_pat_pregn_active, g_pat_pregn_past, g_pat_pregn_cancel, g_pat_pregn_auto_close)
        THEN
            RETURN '';
        ELSE
            RETURN i_flg_status;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_abortion_type;

    /********************************************************************************************
    * Returns the type of abortion (description)
    *
    * @param i_flg_status             pregnancy status
    * @param i_pat_pregnancy          pregnancy's ID
    * @param i_type_desc              description type: S - summary page; D - detail screen
    *                        
    * @return                         type of abortion
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/04/27
    **********************************************************************************************/
    FUNCTION get_pregn_outcome_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_flg_status         IN pat_pregnancy.flg_status%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_type_desc          IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_desc sys_domain.desc_val%TYPE;
    
        l_flg_status pat_pregnancy.flg_status%TYPE;
    
    BEGIN
    
        IF i_flg_status = g_pat_pregn_cancel
        THEN
        
            SELECT flg_status
              INTO l_flg_status
              FROM (SELECT p.flg_status
                      FROM pat_pregnancy_hist p
                     WHERE p.id_pat_pregnancy = i_pat_pregnancy
                     ORDER BY p.dt_pat_pregnancy_tstz DESC)
             WHERE rownum = 1;
        
            IF l_flg_status <> g_pat_pregn_cancel
            THEN
                l_desc := get_pregn_outcome_desc(i_lang,
                                                 l_flg_status,
                                                 i_pat_pregnancy,
                                                 i_pat_pregnancy_hist,
                                                 i_type_desc);
            END IF;
        ELSIF i_type_desc = g_type_summ
        THEN
            IF i_flg_status IN (g_pat_pregn_past)
            THEN
                l_desc := get_pregnancy_outcome(i_lang, NULL, i_pat_pregnancy, i_pat_pregnancy_hist, NULL);
            ELSIF i_flg_status NOT IN (g_pat_pregn_active, g_pat_pregn_auto_close)
            THEN
                l_desc := pk_sysdomain.get_domain_no_avail('PAT_PREGNANCY.FLG_STATUS', i_flg_status, i_lang);
            END IF;
        ELSIF i_type_desc = g_type_det
        THEN
            IF i_flg_status IN (g_pat_pregn_past)
            THEN
                l_desc := get_pregnancy_outcome(i_lang, NULL, i_pat_pregnancy, i_pat_pregnancy_hist, NULL);
            ELSIF i_flg_status <> g_pat_pregn_active
            THEN
                l_desc := pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_STATUS', i_flg_status, i_lang);
            END IF;
        
        END IF;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_pregn_outcome_desc;

    /********************************************************************************************
    * Returns the viewer category
    *
    * @param i_pat_pregnancy          pregnancy ID
    *                        
    * @return                         viewer category
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/05/26
    **********************************************************************************************/
    FUNCTION get_viewer_category(i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE) RETURN NUMBER IS
    
        l_dt_intervention  pat_pregnancy.dt_intervention%TYPE;
        l_flg_dt_precision pat_pregnancy.flg_dt_interv_precision%TYPE;
        l_dt_init_pregn    pat_pregnancy.dt_init_pregnancy%TYPE;
        l_num_weeks        pat_pregnancy.num_gest_weeks%TYPE;
        l_flg_status       pat_pregnancy.flg_status%TYPE;
    
    BEGIN
    
        SELECT pp.dt_intervention,
               pp.flg_status,
               pp.dt_init_pregnancy,
               pp.num_gest_weeks,
               nvl(pp.flg_dt_interv_precision, g_dt_flg_precision_h)
          INTO l_dt_intervention, l_flg_status, l_dt_init_pregn, l_num_weeks, l_flg_dt_precision
          FROM pat_pregnancy pp
         WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
    
        IF l_dt_intervention IS NULL
           OR l_flg_status IN (g_pat_pregn_active, g_pat_pregn_cancel)
        THEN
            RETURN NULL;
        ELSE
            IF l_flg_status NOT IN (g_pat_pregn_past, g_pat_pregn_no)
            THEN
                RETURN g_pregn_viewer_cat_3;
            ELSE
                IF (l_dt_intervention - l_dt_init_pregn >= numtodsinterval(37 * 7, 'DAY') AND
                   l_dt_init_pregn IS NOT NULL AND l_dt_intervention IS NOT NULL AND
                   l_flg_dt_precision IN (g_dt_flg_precision_h, g_dt_flg_precision_d))
                   OR (l_num_weeks >= 37 AND l_num_weeks IS NOT NULL)
                THEN
                    RETURN g_pregn_viewer_cat_1;
                ELSE
                    RETURN g_pregn_viewer_cat_2;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_viewer_category;

    /********************************************************************************************
    * Gets all complications of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/11/26
    **********************************************************************************************/
    FUNCTION get_preg_complications
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_complication    IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complications IN pat_pregnancy.notes_complications%TYPE,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist  IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret       VARCHAR2(4000);
        l_diagnosis VARCHAR2(4000);
    
        l_domain_compl CONSTANT sys_domain.code_domain%TYPE := 'PAT_PREGNANCY.FLG_COMPLICATION';
    
    BEGIN
    
        l_ret := pk_sysdomain.get_desc_domain_set(i_lang        => i_lang,
                                                  i_code_domain => l_domain_compl,
                                                  i_vals        => i_flg_complication);
    
        IF i_notes_complications IS NOT NULL
        THEN
            IF l_ret IS NOT NULL
            THEN
                l_ret := l_ret || '; ' || i_notes_complications;
            ELSE
                l_ret := i_notes_complications;
            END IF;
        END IF;
    
        SELECT pk_utils.concatenate_list(CURSOR (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                                            i_code               => d.code_icd,
                                                                            i_flg_other          => d.flg_other,
                                                                            i_flg_std_diag       => ad.flg_icd9) diag_desc
                                            FROM (SELECT id_alert_diagnosis
                                                    FROM pat_pregnancy_diagnosis
                                                   WHERE id_pat_pregnancy = i_pat_pregnancy
                                                     AND i_pat_pregnancy_hist IS NULL
                                                  UNION ALL
                                                  SELECT id_alert_diagnosis
                                                    FROM pat_pregnancy_diagnosis_hist
                                                   WHERE id_pat_pregnancy_hist = i_pat_pregnancy_hist) pdiag
                                            JOIN alert_diagnosis ad
                                              ON ad.id_alert_diagnosis = pdiag.id_alert_diagnosis
                                            JOIN diagnosis d
                                              ON d.id_diagnosis = ad.id_diagnosis),
                                         '; ')
          INTO l_diagnosis
          FROM dual;
    
        IF l_diagnosis IS NOT NULL
        THEN
            IF l_ret IS NOT NULL
            THEN
                l_ret := l_ret || '; ' || l_diagnosis;
            ELSE
                l_ret := l_diagnosis;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_preg_complications;

    /********************************************************************************************
    * Gets all contraception type of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_pat_pregnancy          Pat pregnancy ID
    * @param i_pat_pregnancy_hist     Pat pregnancy History ID
    * @param i_other_string           Y/N See other contraception type           
    *
    * @return                        contraception type (description)
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/11/20
    **********************************************************************************************/
    FUNCTION get_contraception_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_other_string       IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
    
        l_contraception_type VARCHAR2(4000);
    
    BEGIN
    
        IF i_other_string = 'Y'
        THEN
            SELECT pk_utils.concatenate_list(CURSOR (SELECT description
                                                FROM (SELECT decode(contract_type,
                                                                    g_desc_contract_type_other,
                                                                    pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                                                   i_prof      => i_prof,
                                                                                                                   i_id_option => contract_type) || ': ' ||
                                                                    other_contraception_type,
                                                                    pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                                                   i_prof      => i_prof,
                                                                                                                   i_id_option => contract_type)) description,
                                                             pk_api_multichoice.get_multichoice_option_rank(i_lang             => i_lang,
                                                                                                            i_prof             => i_prof,
                                                                                                            i_multichoice_type => g_multichoice_type_contrac,
                                                                                                            i_id_option        => contract_type) rank
                                                        FROM (SELECT ppct.id_contrac_type          contract_type,
                                                                     ppct.other_contraception_type other_contraception_type
                                                                FROM pat_preg_cont_type ppct
                                                               WHERE id_pat_pregnancy = i_pat_pregnancy
                                                                 AND i_pat_pregnancy_hist IS NULL
                                                              UNION ALL
                                                              SELECT ppch.id_contrac_type contract_type,
                                                                     ppch.other_contraception_type
                                                                FROM pat_preg_cont_type_hist ppch
                                                               WHERE id_pat_pregnancy_hist = i_pat_pregnancy_hist) pdiag
                                                       ORDER BY CASE
                                                                     WHEN contract_type = g_desc_contract_type_other THEN
                                                                      1
                                                                     ELSE
                                                                      0
                                                                 END ASC,
                                                                rank ASC)),
                                             '; ')
              INTO l_contraception_type
              FROM dual;
        ELSE
            SELECT pk_utils.concatenate_list(CURSOR (SELECT description
                                                FROM (SELECT pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_id_option => contract_type) description,
                                                             pk_api_multichoice.get_multichoice_option_rank(i_lang             => i_lang,
                                                                                                            i_prof             => i_prof,
                                                                                                            i_multichoice_type => g_multichoice_type_contrac,
                                                                                                            i_id_option        => contract_type) rank
                                                        FROM (SELECT ppct.id_contrac_type          contract_type,
                                                                     ppct.other_contraception_type other_contraception_type
                                                                FROM pat_preg_cont_type ppct
                                                               WHERE id_pat_pregnancy = i_pat_pregnancy
                                                                 AND i_pat_pregnancy_hist IS NULL
                                                              UNION ALL
                                                              SELECT ppch.id_contrac_type contract_type,
                                                                     ppch.other_contraception_type
                                                                FROM pat_preg_cont_type_hist ppch
                                                               WHERE id_pat_pregnancy_hist = i_pat_pregnancy_hist) pdiag
                                                       ORDER BY CASE
                                                                     WHEN contract_type = g_desc_contract_type_other THEN
                                                                      1
                                                                     ELSE
                                                                      0
                                                                 END ASC,
                                                                rank ASC)),
                                             '; ')
              INTO l_contraception_type
              FROM dual;
        END IF;
        RETURN l_contraception_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_contraception_type;

    /********************************************************************************************
    * Gets all contraception type id of a specific pregnancy
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_pat_pregnancy          Pat pregnancy ID
    *
    * @return                        contraception type (description)
    * 
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2013/11/20
    **********************************************************************************************/
    FUNCTION get_contraception_type_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN table_varchar IS
        l_return table_varchar := table_varchar();
    BEGIN
        SELECT id_contrac_type
          BULK COLLECT
          INTO l_return
          FROM (SELECT to_char(ppc.id_contrac_type) id_contrac_type,
                       pk_api_multichoice.get_multichoice_option_rank(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_multichoice_type => g_multichoice_type_contrac,
                                                                      i_id_option        => ppc.id_contrac_type) rank
                  FROM pat_preg_cont_type ppc
                 WHERE ppc.id_pat_pregnancy = i_pat_pregnancy
                 ORDER BY CASE
                              WHEN ppc.id_contrac_type = g_desc_contract_type_other THEN
                               1
                              ELSE
                               0
                          END ASC,
                          rank ASC);
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_contraception_type_id;

    /********************************************************************************************
    * Gets all complications in serialized format to be passed to the edition screen
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_serialized_compl
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_complication IN pat_pregnancy.flg_complication%TYPE,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(4000);
    
    BEGIN
    
        SELECT pk_utils.concatenate_list(CURSOR (SELECT id_alert_diagnosis
                                            FROM pat_pregnancy_diagnosis
                                           WHERE id_pat_pregnancy = i_pat_pregnancy),
                                         '|')
          INTO l_ret
          FROM dual;
    
        IF l_ret IS NOT NULL
           AND i_flg_complication IS NOT NULL
        THEN
            l_ret := '|' || l_ret;
        END IF;
    
        RETURN i_flg_complication || l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_serialized_compl;

    /********************************************************************************************
    * Gets the obstetric indexes to place in the summary page
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param i_patient                Patient ID
    * @param i_type                   Formatting type: T - initial type, C - complete obstetric index          
    *                        
    * @return                         Pregnancy formatted obstetric indexes
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/03/28
    **********************************************************************************************/
    FUNCTION get_obstetric_index
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(4000);
    
        l_config_obs_idx          CONSTANT sys_config.id_sys_config%TYPE := 'PREGNANCY_OBSTETRIC_INDEX';
        l_config_obs_idx_count    CONSTANT sys_config.id_sys_config%TYPE := 'OBSTETRIC_INDEX_COUNT_LIVING_STATUS';
        l_config_newborn_cur_stat CONSTANT sys_config.id_sys_config%TYPE := 'NEWBORN_CURR_STATUS_MULTICHOICE';
    
        l_val_config_obs_idx       sys_config.value%TYPE;
        l_val_config_obs_idx_count sys_config.value%TYPE;
        l_val_config_bew_born_stat sys_config.value%TYPE;
    
        l_type_indexes  CONSTANT table_varchar := table_varchar('GP', 'TPAL');
        l_title_indexes CONSTANT table_varchar := table_varchar('WOMAN_HEALTH_T149', 'WOMAN_HEALTH_T151');
    
        l_title_para     CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T150';
        l_title_term     CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T151';
        l_title_preterm  CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T152';
        l_title_abortion CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T153';
        l_title_induced  CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T154';
        l_title_spont    CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T155';
        l_title_living   CONSTANT sys_message.code_message%TYPE := 'WOMAN_HEALTH_T156';
    
        l_row_obs_index v_obstetric_index%ROWTYPE;
        l_live_children NUMBER;
        l_count_status  NUMBER;
    BEGIN
    
        l_val_config_obs_idx       := pk_sysconfig.get_config(i_code_cf => l_config_obs_idx, i_prof => i_prof);
        l_val_config_obs_idx_count := pk_sysconfig.get_config(i_code_cf => l_config_obs_idx_count, i_prof => i_prof);
        l_val_config_bew_born_stat := pk_sysconfig.get_config(i_code_cf => l_config_newborn_cur_stat, i_prof => i_prof);
    
        IF i_type = g_type_obs_idx_t
        THEN
            FOR i IN 1 .. l_type_indexes.count
            LOOP
                IF instr(l_val_config_obs_idx, '|' || l_type_indexes(i) || '|') != 0
                THEN
                    l_ret := pk_message.get_message(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_code_mess => l_title_indexes(i));
                    EXIT;
                END IF;
            END LOOP;
        ELSIF i_type = g_type_obs_idx_c
        THEN
            SELECT *
              INTO l_row_obs_index
              FROM v_obstetric_index v_obs
             WHERE v_obs.id_patient = i_patient;
        
            FOR i IN 1 .. l_type_indexes.count
            LOOP
                IF instr(l_val_config_obs_idx, '|' || l_type_indexes(i) || '|') != 0
                THEN
                    IF l_type_indexes(i) = g_obs_idx_gp
                    THEN
                        l_ret := l_row_obs_index.gravida || '; ' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_obs_idx,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_para),
                                                                      l_row_obs_index.para,
                                                                      '',
                                                                      '') || '.' || chr(10);
                    ELSIF l_type_indexes(i) = g_obs_idx_tpal
                    THEN
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
                    
                        IF l_ret IS NOT NULL
                        THEN
                            l_ret := l_ret ||
                                     pk_utils.to_bold(pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => l_title_term) || ': ');
                        END IF;
                    
                        l_ret := l_ret || l_row_obs_index.term || '; ' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_obs_idx,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_preterm),
                                                                      l_row_obs_index.preterm,
                                                                      '',
                                                                      '') || '; ' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_obs_idx,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_abortion),
                                                                      l_row_obs_index.abortions,
                                                                      '',
                                                                      '') || ' (' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_past_hist,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_spont),
                                                                      l_row_obs_index.spontaneous_abortions,
                                                                      '',
                                                                      '') || '; ' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_past_hist,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_induced),
                                                                      l_row_obs_index.induced_abortions,
                                                                      '',
                                                                      '') || '); ' ||
                                 pk_pregnancy_core.get_formatted_text(g_doc_area_obs_idx,
                                                                      pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             l_title_living),
                                                                      l_live_children,
                                                                      '',
                                                                      '');
                    
                    END IF;
                END IF;
            END LOOP;
        
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_obstetric_index;

    /************************************************************************************************************ 
    * This function creates new pregnacies or updates existing ones for the specified patient
    *
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      o_error                       error message
    *
    * @return     Saves the pregnancy history to be available after all changes
    * @author     José Silva
    * @version    0.1
    * @since      2008/05/25
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_pregnancy_hist pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE;
    
    BEGIN
    
        SELECT seq_pat_pregnancy_hist.nextval
          INTO l_id_pat_pregnancy_hist
          FROM dual;
    
        g_error := 'INSERT INTO PAT_PREGNANCY';
        INSERT INTO pat_pregnancy_hist
            (id_pat_pregnancy_hist,
             id_pat_pregnancy,
             dt_pat_pregnancy_tstz,
             id_professional,
             dt_last_menstruation,
             n_pregnancy,
             dt_intervention,
             n_children,
             flg_status,
             flg_complication,
             notes_complications,
             desc_intervention,
             notes,
             num_gest_weeks,
             num_gest_weeks_exam,
             num_gest_weeks_us,
             id_inst_intervention,
             flg_desc_intervention,
             --
             flg_menses,
             cycle_duration,
             flg_use_constraceptives,
             dt_contrac_meth_end,
             flg_dt_contrac_precision,
             dt_pdel_lmp,
             dt_pdel_correct,
             dt_us_performed,
             flg_del_onset,
             del_duration,
             flg_dt_interv_precision,
             dt_init_preg_exam,
             dt_init_pregnancy,
             dt_init_preg_lmp,
             --
             id_episode,
             id_cdr_call,
             flg_extraction,
             num_births,
             num_abortions,
             num_gestations,
             flg_preg_out_type,
             flg_gest_weeks,
             flg_gest_weeks_exam,
             flg_gest_weeks_us,
             dt_auto_closed)
            SELECT l_id_pat_pregnancy_hist,
                   id_pat_pregnancy,
                   dt_pat_pregnancy_tstz,
                   id_professional,
                   dt_last_menstruation,
                   n_pregnancy,
                   dt_intervention,
                   n_children,
                   flg_status,
                   flg_complication,
                   notes_complications,
                   desc_intervention,
                   notes,
                   num_gest_weeks,
                   num_gest_weeks_exam,
                   num_gest_weeks_us,
                   id_inst_intervention,
                   flg_desc_intervention,
                   --
                   flg_menses,
                   cycle_duration,
                   flg_use_constraceptives,
                   dt_contrac_meth_end,
                   flg_dt_contrac_precision,
                   dt_pdel_lmp,
                   dt_pdel_correct,
                   dt_us_performed,
                   flg_del_onset,
                   del_duration,
                   flg_dt_interv_precision,
                   dt_init_preg_exam,
                   dt_init_pregnancy,
                   dt_init_preg_lmp,
                   --
                   id_episode,
                   p.id_cdr_call,
                   p.flg_extraction,
                   p.num_births,
                   p.num_abortions,
                   p.num_gestations,
                   p.flg_preg_out_type,
                   p.flg_gest_weeks,
                   p.flg_gest_weeks_exam,
                   p.flg_gest_weeks_us,
                   dt_auto_closed
              FROM pat_pregnancy p
             WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        g_error := 'INSERT INTO PAT_PREGN_FETUS';
        INSERT INTO pat_pregn_fetus_hist
            (id_pat_pregnancy_hist,
             id_pat_pregn_fetus,
             flg_gender,
             fetus_number,
             flg_childbirth_type,
             flg_status,
             weight,
             id_unit_measure,
             present_health)
            SELECT l_id_pat_pregnancy_hist,
                   id_pat_pregn_fetus,
                   flg_gender,
                   fetus_number,
                   flg_childbirth_type,
                   flg_status,
                   weight,
                   id_unit_measure,
                   present_health
              FROM pat_pregn_fetus pf
             WHERE pf.id_pat_pregnancy = i_pat_pregnancy
               AND (instr(pf.flg_status, g_pregn_fetus_dead) > 0 OR instr(pf.flg_status, g_pregn_fetus_alive) > 0 OR
                   pf.flg_status = g_pregn_fetus_unk);
    
        g_error := 'UPDATE PREGNANCY DIAGNOSIS';
        INSERT INTO pat_pregnancy_diagnosis_hist
            (id_pat_pregnancy_hist, id_alert_diagnosis)
            SELECT l_id_pat_pregnancy_hist, id_alert_diagnosis
              FROM pat_pregnancy_diagnosis
             WHERE id_pat_pregnancy = i_pat_pregnancy;
    
        g_error := 'UPDATE PAT_PREG_CONT_TYPE_HIST';
        INSERT INTO pat_preg_cont_type_hist
            (id_pat_pregnancy_hist, id_contrac_type, other_contraception_type)
            SELECT l_id_pat_pregnancy_hist, id_contrac_type, other_contraception_type
              FROM pat_preg_cont_type
             WHERE id_pat_pregnancy = i_pat_pregnancy;
    
        g_error := 'UPDATE PREGNANCY CODE';
        INSERT INTO pat_pregnancy_code_hist
            (id_pat_pregnancy_hist, id_geo_state, code_state, code_year, code_number, flg_type)
            SELECT l_id_pat_pregnancy_hist, id_geo_state, code_state, code_year, code_number, flg_type
              FROM pat_pregnancy_code
             WHERE id_pat_pregnancy = i_pat_pregnancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PAT_PREGNANCY_HIST', g_error, SQLERRM, TRUE, o_error);
    END set_pat_pregnancy_hist;

    /************************************************************************************************************ 
    * This function creates a new pregnacy code
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          pregnancy ID
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    * @param o_error                  error message
    *
    *                        
    * @return     true or false on success or error
    *
    * @author     José Silva
    * @version    2.5.1.5
    * @since      2011/04/12
    ***********************************************************************************************************/
    FUNCTION set_pat_pregnancy_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_code_state    IN pat_pregnancy_code.code_state%TYPE,
        i_code_year     IN pat_pregnancy_code.code_year%TYPE,
        i_code_number   IN pat_pregnancy_code.code_number%TYPE,
        i_flg_type      IN pat_pregnancy_code.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_pregnancy_hist pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE;
        l_id_geo_state          pat_pregnancy_code.id_geo_state%TYPE;
        l_code_state            pat_pregnancy_code.code_state%TYPE;
        l_exception             EXCEPTION;
    
    BEGIN
    
        g_error        := 'GET ID_GEO_STATE';
        l_id_geo_state := pk_api_backoffice.get_geo_state_id(i_lang, i_prof, i_code_state);
    
        IF l_id_geo_state IS NULL
        THEN
            l_code_state := i_code_state;
        END IF;
    
        g_error := 'SET PREGNANCY CODE';
        INSERT INTO pat_pregnancy_code
            (id_pat_pregnancy, id_geo_state, code_state, code_year, code_number, flg_type)
        VALUES
            (i_pat_pregnancy, l_id_geo_state, l_code_state, i_code_year, i_code_number, i_flg_type);
    
        g_error := 'SET SERIE CURRENT NUMBER';
        IF NOT pk_api_backoffice.set_serie_current_number(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_code_state     => to_number(i_code_state),
                                                          i_year           => i_code_year,
                                                          i_current_number => i_code_number,
                                                          o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_PAT_PREGNANCY_CODE', g_error, SQLERRM, TRUE, o_error);
    END set_pat_pregnancy_code;

    /************************************************************************************************************ 
    * Sets the pregnancy info (saved from labor and delivery assessments)
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_pat_pregnancy               pregnancy's ID
    * @param      i_doc_area                    doc area ID from the labor/delivery assessment
    * @param      i_fetus_number                Single fetus idetifier number
    * @param      i_flg_type                    record type: E - creation/edition; C - cancel; H - creation/edition with history saving
    * @param      i_flg_childbirth_type         list of child birth types (one per children)
    * @param      i_flg_child_status            list of child status (one per children)   
    * @param      i_flg_child_gender            list of child gender (one per children)
    * @param      i_child_weight                list of child weight (one per children) 
    * @param      i_weight_um                   weight unit measure
    * @param      i_dt_intervention             labor date
    * @param      i_desc_intervention           labor site: description
    * @param      l_flg_desc_interv             labor site: D - home; O - other hospital
    * @param      i_id_inst_interv              labor site: institution ID
    * @param      i_notes_complications         labor complications
    * @param      i_epis_documentation          Epis documentation 
    * @param      o_error                       error message
    *
    * @return     true or false on success or error
    * @author     José Silva
    * @version    0.1
    * @since      2008/09/08
    ***********************************************************************************************************/
    FUNCTION set_pat_pregn_delivery
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_pregnancy       IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_fetus_number        IN NUMBER,
        i_flg_type            IN VARCHAR2,
        i_flg_child_gender    IN table_varchar,
        i_flg_childbirth_type IN table_varchar,
        i_flg_child_status    IN table_varchar,
        i_child_weight        IN table_number,
        i_weight_um           IN table_varchar,
        i_dt_intervention     IN pat_pregnancy.dt_intervention%TYPE,
        i_desc_intervention   IN pat_pregnancy.desc_intervention%TYPE,
        i_flg_desc_interv     IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_id_inst_interv      IN pat_pregnancy.id_inst_intervention%TYPE,
        i_notes_complications IN pat_pregnancy.notes_complications%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_msg_error           OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception_cancel EXCEPTION;
        l_msg_cancel       sys_message.desc_message%TYPE;
    
        l_type_cancel CONSTANT VARCHAR2(1) := 'C';
        l_type_edit   CONSTANT VARCHAR2(1) := 'E';
        l_type_edit_h CONSTANT VARCHAR2(1) := 'H';
    
        l_child_status pat_pregn_fetus.flg_status%TYPE;
        l_flg_status   pat_pregnancy.flg_status%TYPE;
    
        l_fetus_number NUMBER;
    
        l_rowids_1      table_varchar;
        e_process_event EXCEPTION;
    
        l_dt_intervention  pat_pregnancy.dt_intervention%TYPE;
        l_flg_dt_precision pat_pregnancy.flg_dt_interv_precision%TYPE;
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
        l_id_pat_pregn_fetus    pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_women_health_hpg_id   sys_config.value%TYPE;
        l_health_program        health_program.id_health_program%TYPE;
        l_insts                 table_number;
        l_id_pat_health_program pat_health_program.id_pat_health_program%TYPE;
        l_dt_begin_tstz         pat_health_program.dt_begin_tstz%TYPE;
        l_id_patient            patient.id_patient%TYPE;
    
    BEGIN
    
        g_error      := 'GET ERROR MESSAGES';
        l_msg_cancel := pk_message.get_message(i_lang, 'WOMAN_HEALTH_M006');
    
        g_error := 'GET FETUS NUMBER';
        IF i_fetus_number IS NULL
           AND NOT pk_delivery.get_fetus_number(i_lang, i_prof, i_pat_pregnancy, l_fetus_number, l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_doc_area IN (pk_pregnancy_core.g_doc_area_labor, pk_pregnancy_core.g_doc_area_born)
        THEN
        
            IF i_flg_type IN (l_type_cancel, l_type_edit_h)
            THEN
                g_error := 'SAVE PREGNANCY HISTORY';
                IF NOT pk_pregnancy_core.set_pat_pregnancy_hist(i_lang, i_pat_pregnancy, l_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                ts_pat_pregnancy.upd(id_pat_pregnancy_in      => i_pat_pregnancy,
                                     id_professional_in       => i_prof.id,
                                     dt_pat_pregnancy_tstz_in => current_timestamp,
                                     rows_out                 => l_rowids_1);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PREGNANCY',
                                              i_rowids     => l_rowids_1,
                                              o_error      => o_error);
            
                l_rowids_1 := table_varchar();
            
            END IF;
        
            IF i_flg_type = l_type_cancel
            THEN
                g_error := 'CANCEL BORN RECORD';
                IF i_doc_area = pk_pregnancy_core.g_doc_area_born
                THEN
                
                    g_error := 'CALL PK_DELIVERY.VERIFY_CANCEL_BORN_RECORD';
                    IF i_epis_documentation IS NOT NULL
                       AND pk_delivery.verify_cancel_born_record(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_epis_documentation => i_epis_documentation)
                    THEN
                        g_error := 'GET PREGNANCY STATUS';
                        SELECT flg_status
                          INTO l_flg_status
                          FROM pat_pregnancy
                         WHERE id_pat_pregnancy = i_pat_pregnancy;
                    
                        IF l_flg_status = pk_pregnancy_core.g_pat_pregn_past
                        THEN
                            RAISE l_exception_cancel;
                        END IF;
                    END IF;
                
                    g_error := 'GET FETUS STATUS';
                    BEGIN
                        SELECT pk_pregnancy_core.g_pregn_fetus_unk
                          INTO l_child_status
                          FROM pat_pregn_fetus p
                         WHERE p.id_pat_pregnancy = i_pat_pregnancy
                           AND p.fetus_number = i_fetus_number
                           AND p.flg_childbirth_type IS NOT NULL;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_child_status := '';
                    END;
                
                    g_error := 'CANCEL FETUS INFO';
                    IF NOT pk_pregnancy.set_pat_pregn_fetus(i_lang,
                                                            i_prof,
                                                            i_pat_pregnancy,
                                                            NULL,
                                                            i_fetus_number,
                                                            NULL,
                                                            table_varchar(''),
                                                            NULL,
                                                            table_varchar(l_child_status),
                                                            table_number(NULL),
                                                            table_varchar(''),
                                                            table_varchar(''),
                                                            table_varchar(''),
                                                            l_id_pat_pregn_fetus,
                                                            l_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    g_error := 'CANCEL LABOR RECORD';
                ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_labor
                THEN
                    g_error := 'UPDATE PAT PREGNANCY';
                    ts_pat_pregnancy.upd(id_pat_pregnancy_in       => i_pat_pregnancy,
                                         desc_intervention_in      => NULL,
                                         desc_intervention_nin     => FALSE,
                                         flg_desc_intervention_in  => NULL,
                                         flg_desc_intervention_nin => FALSE,
                                         id_inst_intervention_in   => NULL,
                                         id_inst_intervention_nin  => FALSE,
                                         notes_complications_in    => NULL,
                                         notes_complications_nin   => FALSE,
                                         rows_out                  => l_rowids_1);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_PREGNANCY',
                                                  i_rowids     => l_rowids_1,
                                                  o_error      => l_error);
                
                    FOR i IN 1 .. l_fetus_number
                    LOOP
                        g_error := 'GET FETUS STATUS';
                        BEGIN
                            SELECT p.flg_status
                              INTO l_child_status
                              FROM pat_pregn_fetus p
                             WHERE p.id_pat_pregnancy = i_pat_pregnancy
                               AND p.fetus_number = i
                               AND (p.flg_gender IS NOT NULL OR p.weight IS NOT NULL OR
                                   (instr(p.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                   instr(p.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0));
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_child_status := '';
                        END;
                    
                        g_error := 'CANCEL FETUS INFO';
                        IF NOT pk_pregnancy.set_pat_pregn_fetus(i_lang,
                                                                i_prof,
                                                                i_pat_pregnancy,
                                                                NULL,
                                                                i,
                                                                NULL,
                                                                NULL,
                                                                table_varchar(''),
                                                                table_varchar(l_child_status),
                                                                NULL,
                                                                NULL,
                                                                NULL,
                                                                NULL,
                                                                l_id_pat_pregn_fetus,
                                                                l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END LOOP;
                END IF;
            
            ELSIF i_flg_type IN (l_type_edit, l_type_edit_h)
            THEN
                g_error := 'SET BORN RECORD';
                IF i_doc_area = pk_pregnancy_core.g_doc_area_born
                THEN
                    IF i_fetus_number IS NULL
                    THEN
                        SELECT decode(i_dt_intervention, NULL, p.flg_status, 'P'),
                               nvl(i_dt_intervention, p.dt_intervention),
                               nvl2(nvl(i_dt_intervention, p.dt_intervention),
                                    pk_pregnancy_core.g_dt_flg_precision_h,
                                    NULL)
                          INTO l_flg_status, l_dt_intervention, l_flg_dt_precision
                          FROM pat_pregnancy p
                         WHERE p.id_pat_pregnancy = i_pat_pregnancy
                           FOR UPDATE;
                    
                        g_error := 'UPDATE PAT PREGNANCY';
                        ts_pat_pregnancy.upd(id_pat_pregnancy_in        => i_pat_pregnancy,
                                             flg_status_in              => l_flg_status,
                                             dt_intervention_in         => l_dt_intervention,
                                             flg_dt_interv_precision_in => l_flg_dt_precision,
                                             rows_out                   => l_rowids_1);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_PREGNANCY',
                                                      i_rowids     => l_rowids_1,
                                                      o_error      => l_error);
                    
                        l_women_health_hpg_id := pk_sysconfig.get_config('WOMEN_HEALTH_HPG_ID', i_prof);
                    
                        BEGIN
                            l_health_program := to_number(l_women_health_hpg_id);
                        EXCEPTION
                            WHEN value_error THEN
                                l_health_program := NULL;
                        END;
                    
                        IF l_health_program IS NOT NULL
                        THEN
                            SELECT pp.id_patient
                              INTO l_id_patient
                              FROM pat_pregnancy pp
                             WHERE pp.id_pat_pregnancy = i_pat_pregnancy;
                        
                            g_error := 'call pk_list.tf_get_all_inst_group';
                            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
                        
                            g_error := 'select * FROM pat_health_program php';
                            BEGIN
                                SELECT php.id_pat_health_program, php.dt_begin_tstz
                                  INTO l_id_pat_health_program, l_dt_begin_tstz
                                  FROM pat_health_program php
                                 WHERE php.id_patient = l_id_patient
                                   AND php.id_health_program = l_health_program
                                   AND php.id_institution IN
                                       (SELECT /*+opt_estimate(table t rows=1)*/
                                         t.column_value id_institution
                                          FROM TABLE(CAST(l_insts AS table_number)) t)
                                   AND php.flg_status NOT IN (pk_health_program.g_flg_status_cancelled)
                                   AND rownum = 1;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_id_pat_health_program := NULL;
                                    l_dt_begin_tstz         := NULL;
                            END;
                            IF l_flg_status = pk_pregnancy_core.g_pat_pregn_past
                               AND i_dt_intervention IS NOT NULL
                               AND l_id_pat_health_program IS NOT NULL
                            THEN
                                g_error := 'call pk_health_program.set_pat_hpg';
                                IF NOT pk_health_program.set_pat_hpg(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_patient => l_id_patient,
                                                                     --i_pat_hpg => l_id_pat_health_program,
                                                                     i_health_program => l_health_program,
                                                                     i_monitor_loc    => pk_pregnancy.g_flg_mon_inst,
                                                                     -- i_mon_id_inst    => NULL,
                                                                     i_dt_begin => pk_date_utils.date_send_tsz(i_lang,
                                                                                                               l_dt_begin_tstz,
                                                                                                               i_prof),
                                                                     i_dt_end   => i_dt_intervention,
                                                                     i_notes    => NULL,
                                                                     i_action   => 'REMOVE',
                                                                     o_error    => o_error)
                                THEN
                                    RAISE l_exception;
                                END IF;
                            END IF;
                        END IF;
                    
                    ELSE
                    
                        IF i_flg_child_status IS NULL
                        THEN
                            g_error := 'GET FETUS STATUS';
                            BEGIN
                                SELECT pk_pregnancy_core.g_pregn_fetus_unk
                                  INTO l_child_status
                                  FROM pat_pregn_fetus p
                                 WHERE p.id_pat_pregnancy = i_pat_pregnancy
                                   AND p.fetus_number = i_fetus_number
                                   AND p.flg_childbirth_type IS NOT NULL;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_child_status := '';
                            END;
                        END IF;
                    
                        g_error := 'UPDATE PAT PREGN FETUS';
                        IF NOT pk_pregnancy.set_pat_pregn_fetus(i_lang,
                                                                i_prof,
                                                                i_pat_pregnancy,
                                                                NULL,
                                                                i_fetus_number,
                                                                NULL,
                                                                i_flg_child_gender,
                                                                i_flg_childbirth_type,
                                                                nvl(i_flg_child_status, table_varchar(l_child_status)),
                                                                i_child_weight,
                                                                i_weight_um,
                                                                table_varchar(''),
                                                                table_varchar(''),
                                                                l_id_pat_pregn_fetus,
                                                                l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END IF;
                
                    g_error := 'SET LABOR RECORD';
                ELSIF i_doc_area = pk_pregnancy_core.g_doc_area_labor
                THEN
                    IF i_fetus_number IS NULL
                    THEN
                        g_error := 'UPDATE PAT PREGNANCY';
                        ts_pat_pregnancy.upd(id_pat_pregnancy_in       => i_pat_pregnancy,
                                             desc_intervention_in      => i_desc_intervention,
                                             desc_intervention_nin     => FALSE,
                                             flg_desc_intervention_in  => i_flg_desc_interv,
                                             flg_desc_intervention_nin => FALSE,
                                             id_inst_intervention_in   => i_id_inst_interv,
                                             id_inst_intervention_nin  => FALSE,
                                             notes_complications_in    => i_notes_complications,
                                             notes_complications_nin   => FALSE,
                                             rows_out                  => l_rowids_1);
                    
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'PAT_PREGNANCY',
                                                      i_rowids     => l_rowids_1,
                                                      o_error      => l_error);
                    
                    ELSE
                        g_error := 'GET FETUS STATUS';
                        BEGIN
                            SELECT p.flg_status
                              INTO l_child_status
                              FROM pat_pregn_fetus p
                             WHERE p.id_pat_pregnancy = i_pat_pregnancy
                               AND p.fetus_number = i_fetus_number
                               AND (instr(p.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0 OR
                                   instr(p.flg_status, pk_pregnancy_core.g_pregn_fetus_alive) > 0);
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_child_status := '';
                        END;
                    
                        g_error := 'UPDATE PAT PREGN FETUS';
                        IF NOT pk_pregnancy.set_pat_pregn_fetus(i_lang,
                                                                i_prof,
                                                                i_pat_pregnancy,
                                                                NULL,
                                                                i_fetus_number,
                                                                NULL,
                                                                i_flg_child_gender,
                                                                i_flg_childbirth_type,
                                                                table_varchar(nvl(l_child_status,
                                                                                  pk_pregnancy_core.g_pregn_fetus_unk)),
                                                                i_child_weight,
                                                                i_weight_um,
                                                                table_varchar(''),
                                                                table_varchar(''),
                                                                l_id_pat_pregn_fetus,
                                                                l_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    
                    END IF;
                END IF;
            END IF;
            g_error := 'SET PROF INFO';
            ts_pat_pregnancy.upd(id_pat_pregnancy_in      => i_pat_pregnancy,
                                 id_professional_in       => i_prof.id,
                                 dt_pat_pregnancy_tstz_in => current_timestamp,
                                 rows_out                 => l_rowids_1);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PREGNANCY',
                                          i_rowids     => l_rowids_1,
                                          o_error      => o_error);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_cancel THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGN_DELIVERY',
                                      '',
                                      'WOMAN_HEALTH_M006',
                                      l_msg_cancel,
                                      TRUE,
                                      'D',
                                      o_error);
        WHEN l_exception THEN
            RETURN error_handling_ext(i_lang,
                                      'SET_PAT_PREGN_DELIVERY',
                                      g_error || ' / ' || l_error.err_desc,
                                      SQLCODE,
                                      SQLERRM,
                                      TRUE,
                                      'S',
                                      o_error);
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'SET_PAT_PREGN_DELIVERY', g_error, SQLCODE, SQLERRM, TRUE, 'S', o_error);
    END set_pat_pregn_delivery;

    /************************************************************************************************************ 
    * Gets the 'N.A.' label when applicable
    *
    * @param      i_lang                        default language
    * @param      i_prof                        Object (professional ID, institution ID, software ID)   
    * @param      i_rh_father                   Father blood rhesus
    * @param      i_rh_mother                   Mother blood rhesus
    *
    * @return     'N.A.' label
    * @author     José Silva
    * @version    1.0
    * @since      2009/11/20
    ***********************************************************************************************************/
    FUNCTION get_antigl_need_na
    (
        i_lang      IN language.id_language%TYPE,
        i_rh_father IN pat_pregnancy.blood_rhesus_father%TYPE,
        i_rh_mother IN pat_blood_group.flg_blood_rhesus%TYPE
    ) RETURN VARCHAR2 IS
    
        l_msg_na sys_message.desc_message%TYPE;
    
    BEGIN
    
        IF (i_rh_mother = g_blood_rhesus_p AND i_rh_father = g_blood_rhesus_n)
           OR (i_rh_mother = g_blood_rhesus_p AND i_rh_father = g_blood_rhesus_p)
           OR (i_rh_mother = g_blood_rhesus_n AND i_rh_father = g_blood_rhesus_n)
        THEN
            l_msg_na := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_M036');
        END IF;
    
        RETURN l_msg_na;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_antigl_need_na;

    /********************************************************************************************
    * Gets the weight unit measure in the pregnancies summary
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID) 
    * @param i_unit_measure           Unit ID associated with a specific measure
    *                        
    * @return                         weight unit measure (description)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2008/11/26
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_unit_measure IN unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_view_preg_summ CONSTANT vs_soft_inst.flg_view%TYPE := 'PS';
        l_desc_unit_measure VARCHAR2(200);
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
          INTO l_desc_unit_measure
          FROM unit_measure um
         WHERE um.id_unit_measure = nvl(i_unit_measure, get_preg_summ_unit_measure_id(i_lang, i_prof));
    
        RETURN l_desc_unit_measure;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_preg_summ_unit_measure;

    /********************************************************************************************
    * Gets the weight unit measure in the pregnancies summary
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    *                        
    * @return                         weight unit measure (id)
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2010/02/15
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN unit_measure.id_unit_measure%TYPE IS
    
        l_id_unit_measure unit_measure.id_unit_measure%TYPE;
        l_id_inst_mrk     market.id_market%TYPE;
    
    BEGIN
    
        l_id_inst_mrk := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        SELECT id_unit_measure
          INTO l_id_unit_measure
          FROM (SELECT uomg.id_unit_measure
                  FROM unit_measure_group uomg
                 WHERE uomg.id_unit_measure_subtype = g_unit_meas_sub_type_preg
                   AND uomg.id_unit_measure_type = g_unit_meas_type_preg
                   AND (uomg.id_market = l_id_inst_mrk OR
                       (uomg.id_market = 0 AND NOT EXISTS
                        (SELECT 1
                            FROM unit_measure_group x
                           WHERE x.id_unit_measure_type = uomg.id_unit_measure_type
                             AND x.id_unit_measure_subtype = uomg.id_unit_measure_subtype
                             AND x.id_market = l_id_inst_mrk)))
                 ORDER BY uomg.id_unit_measure DESC)
         WHERE rownum = 1;
    
        RETURN l_id_unit_measure;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_preg_summ_unit_measure_id;

    /********************************************************************************************
    * Gets the weight unit measure list to be used in the weight keypad
    *
    * @param i_lang                   The language ID   
    * @param i_prof                   Object (professional ID, institution ID, software ID)   
    * @param o_unit_measures          Unit measure list
    * @param o_error                  error message
    *
    * @return     true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2011/04/14
    **********************************************************************************************/
    FUNCTION get_preg_summ_unit_measure
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_unit_measures OUT pk_types.cursor_type,
        o_input_format  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_inst_mrk market.id_market%TYPE;
        l_config_limit     CONSTANT sys_config.id_sys_config%TYPE := 'FETUS_WEIGHT_MAXIMUM';
        l_config_min_limit CONSTANT sys_config.id_sys_config%TYPE := 'FETUS_WEIGHT_MINIMUM';
    BEGIN
    
        g_error       := 'GET_INSTITUTION_MARKET';
        l_id_inst_mrk := pk_utils.get_institution_market(i_lang, i_prof.institution);
    
        g_error := 'GET CURSOR O_UNIT_MEASURES';
        OPEN o_unit_measures FOR
            SELECT uomg.id_unit_measure,
                   pk_translation.get_translation(i_lang, um.code_unit_measure) desc_unit_measure,
                   uomg.id_unit_measure_type,
                   uomg.id_unit_measure_subtype
              FROM unit_measure_group uomg
              JOIN unit_measure um
                ON um.id_unit_measure = uomg.id_unit_measure
             WHERE uomg.id_unit_measure_subtype = g_unit_meas_sub_type_preg
               AND uomg.id_unit_measure_type = g_unit_meas_type_preg
               AND (uomg.id_market = l_id_inst_mrk OR
                   (uomg.id_market = 0 AND NOT EXISTS
                    (SELECT 1
                        FROM unit_measure_group x
                       WHERE x.id_unit_measure_type = uomg.id_unit_measure_type
                         AND x.id_unit_measure_subtype = uomg.id_unit_measure_subtype
                         AND x.id_market = l_id_inst_mrk)))
             ORDER BY uomg.id_unit_measure DESC;
    
        g_error := 'GET CURSOR O_PAT_PREG_RH_REG';
        OPEN o_input_format FOR
            SELECT pk_sysconfig.get_config(l_config_min_limit, i_prof) val_min,
                   pk_sysconfig.get_config(l_config_limit, i_prof) val_max,
                   '9999.999' format_num
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_unit_measures);
            RETURN error_handling(i_lang, 'GET_PREG_SUMM_UNIT_MEASURE', g_error, SQLERRM, FALSE, o_error);
    END get_preg_summ_unit_measure;

    /************************************************************************************************************ 
    * Sets all the pregnancy numbers of a patient
    *
    * @param      i_lang               language ID
    * @param      i_prof               Object (professional ID, institution ID, software ID)
    * @param      i_patient            patient ID
    * @param      o_error              error message
    *
    * @return                          true or false on success or error
    *
    * @author     José Silva
    * @version    0.1
    * @since      2011/04/05
    ***********************************************************************************************************/
    FUNCTION set_n_pregnancy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_n_pregnancy IS
            SELECT p.id_pat_pregnancy
              FROM pat_pregnancy p
             WHERE id_patient = i_patient
               AND flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
             ORDER BY nvl(p.dt_init_pregnancy, p.dt_intervention) NULLS FIRST, p.dt_pat_pregnancy_tstz;
    
        l_n_pregnancy pat_pregnancy.n_pregnancy%TYPE := 1;
    
        l_rowids table_varchar;
    
    BEGIN
    
        FOR r_pregn IN c_n_pregnancy
        LOOP
            ts_pat_pregnancy.upd(id_pat_pregnancy_in => r_pregn.id_pat_pregnancy,
                                 n_pregnancy_in      => l_n_pregnancy,
                                 rows_out            => l_rowids);
        
            l_n_pregnancy := l_n_pregnancy + 1;
        END LOOP;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PREGNANCY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'SET_N_PREGNANCY', g_error, SQLERRM, TRUE, o_error);
    END set_n_pregnancy;

    /********************************************************************************************
    * Returns the pregnancy outcome based on the different fetus status
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_child_status       Child status: Live birth or Still birth
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_pregnancy_outcome
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_child_status   IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret              VARCHAR2(200 CHAR);
        l_flg_child_status table_varchar;
        l_flg_status_count table_number;
        l_domain_outcome CONSTANT sys_domain.code_domain%TYPE := 'PREGNANCY_OUTCOME';
    
        l_sep VARCHAR2(10);
    
    BEGIN
    
        IF i_pat_pregnancy_hist IS NOT NULL
        THEN
            SELECT ppf.flg_status, COUNT(*)
              BULK COLLECT
              INTO l_flg_child_status, l_flg_status_count
              FROM pat_pregn_fetus_hist ppf
             WHERE ppf.id_pat_pregnancy_hist = i_pat_pregnancy_hist
               AND pk_sysdomain.get_domain(l_domain_outcome, ppf.flg_status, i_lang) IS NOT NULL
             GROUP BY ppf.flg_status;
        ELSIF i_pat_pregnancy IS NOT NULL
        THEN
            SELECT ppf.flg_status, COUNT(*)
              BULK COLLECT
              INTO l_flg_child_status, l_flg_status_count
              FROM pat_pregn_fetus ppf
             WHERE ppf.id_pat_pregnancy = i_pat_pregnancy
               AND pk_sysdomain.get_domain(l_domain_outcome, ppf.flg_status, i_lang) IS NOT NULL
             GROUP BY ppf.flg_status;
        ELSE
            SELECT column_value, COUNT(*)
              BULK COLLECT
              INTO l_flg_child_status, l_flg_status_count
              FROM TABLE(i_flg_child_status)
             WHERE pk_sysdomain.get_domain(l_domain_outcome, column_value, i_lang) IS NOT NULL
             GROUP BY column_value;
        END IF;
    
        FOR i IN 1 .. l_flg_child_status.count
        LOOP
            l_ret := l_ret || l_sep || REPLACE(pk_sysdomain.get_domain(l_domain_outcome, l_flg_child_status(i), i_lang),
                                               '@1',
                                               l_flg_status_count(i));
        
            l_sep := '; ';
        END LOOP;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pregnancy_outcome;

    /********************************************************************************************
    * Gets the first title that appears in a pregnancy record in the summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION get_summ_page_first_title
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_table_name         VARCHAR2(50);
        l_filter_name        VARCHAR2(50);
        l_table_contrac_name VARCHAR2(50);
    
        l_query         VARCHAR2(2000);
        l_query_contrac VARCHAR2(2000);
    
        l_call_sisprenatal VARCHAR2(200);
    
        l_fields       table_varchar;
        l_title_fields table_varchar;
        l_count        NUMBER := 0;
        l_ret          sys_message.desc_message%TYPE;
    
    BEGIN
    
        IF i_pat_pregnancy_hist IS NOT NULL
        THEN
            l_table_name         := 'pat_pregnancy_hist';
            l_filter_name        := 'id_pat_pregnancy_hist';
            l_table_contrac_name := 'PAT_PREG_CONT_TYPE_HIST';
        ELSE
            l_table_name         := 'pat_pregnancy';
            l_filter_name        := 'id_pat_pregnancy';
            l_table_contrac_name := 'PAT_PREG_CONT_TYPE';
        END IF;
    
        IF i_flg_type = g_pat_pregn_type_c
        THEN
            l_call_sisprenatal := 'pk_pregnancy_core.get_pat_pregnancy_code(' || i_lang || ',
                                                profissional(' || i_prof.id || ', ' ||
                                  i_prof.institution || ', ' || i_prof.software || '), ' || i_pat_pregnancy || ', ' ||
                                  nvl(to_char(i_pat_pregnancy_hist), 'NULL') || ')';
        
            l_fields := table_varchar(l_call_sisprenatal,
                                      'DT_LAST_MENSTRUATION',
                                      'FLG_MENSES',
                                      'CYCLE_DURATION',
                                      'FLG_USE_CONSTRACEPTIVES',
                                      'ID_CONTRAC_TYPE',
                                      'DT_CONTRAC_METH_END',
                                      'NUM_GEST_WEEKS',
                                      'NUM_GEST_WEEKS_EXAM',
                                      'NUM_GEST_WEEKS_US');
        
            l_title_fields := table_varchar('WOMAN_HEALTH_T126',
                                            'WOMAN_HEALTH_T127',
                                            'WOMAN_HEALTH_T128',
                                            'WOMAN_HEALTH_T129',
                                            'WOMAN_HEALTH_T130',
                                            'WOMAN_HEALTH_T166',
                                            'WOMAN_HEALTH_T131',
                                            'WOMAN_HEALTH_T132',
                                            'WOMAN_HEALTH_T148',
                                            'WOMAN_HEALTH_T136');
        
        ELSE
            l_fields := table_varchar('DT_INTERVENTION');
        
            l_title_fields := table_varchar('WOMAN_HEALTH_T145');
        
        END IF;
    
        FOR i IN 1 .. l_fields.count
        LOOP
            dbms_output.put_line(REPLACE(l_query, '@1', l_fields(i)));
        
            IF l_fields(i) = 'ID_CONTRAC_TYPE'
            THEN
                l_query := 'BEGIN ' || --
                           '    SELECT COUNT(*) ' || --
                           '      INTO :o_count ' || --
                           '      FROM ' || l_table_contrac_name || ' ' || --
                           '     WHERE ' || l_filter_name || ' = :i_pat_pregnancy ' || --
                           '       AND @1 IS NOT NULL; ' || --
                           'END;';
            
            ELSE
            
                l_query := 'BEGIN ' || --
                           '    SELECT COUNT(*) ' || --
                           '      INTO :o_count ' || --
                           '      FROM ' || l_table_name || ' ' || --
                           '     WHERE ' || l_filter_name || ' = :i_pat_pregnancy ' || --
                           '       AND @1 IS NOT NULL; ' || --
                           'END;';
            END IF;
        
            EXECUTE IMMEDIATE (REPLACE(l_query, '@1', l_fields(i)))
                USING OUT l_count, IN nvl(i_pat_pregnancy_hist, i_pat_pregnancy);
        
            IF l_count > 0
            THEN
                l_ret := pk_message.get_message(i_lang, i_prof, l_title_fields(i));
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_summ_page_first_title;

    /********************************************************************************************
    * Checks if the summary page needs an extra break tag
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION check_break_summ_pg_exam
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type       IN pat_pregnancy.flg_type%TYPE,
        i_num_weeks_exam IN pat_pregnancy.num_gest_weeks_exam%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_type = g_pat_pregn_type_c
           AND i_num_weeks_exam IS NOT NULL
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_break_summ_pg_exam;

    /********************************************************************************************
    * Checks if the summary page needs an extra break tag
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION check_break_summ_pg_us
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_type        IN pat_pregnancy.flg_type%TYPE,
        i_num_weeks_us    IN pat_pregnancy.num_gest_weeks_us%TYPE,
        i_dt_pdel_correct IN pat_pregnancy.dt_pdel_correct%TYPE,
        i_dt_us_performed IN pat_pregnancy.dt_us_performed%TYPE,
        i_n_children      IN pat_pregnancy.n_children%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_type = g_pat_pregn_type_c
           AND (i_num_weeks_us IS NOT NULL OR i_dt_pdel_correct IS NOT NULL OR i_dt_us_performed IS NOT NULL OR
           i_n_children IS NOT NULL)
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_break_summ_pg_us;

    /********************************************************************************************
    * Checks if the summary page needs an extra break tag
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION check_break_summ_pg_compl
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregn_hist     IN pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE,
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT 1
                  FROM pat_pregnancy_diagnosis pd
                 WHERE pd.id_pat_pregnancy = i_pat_pregnancy
                   AND i_pat_pregn_hist IS NULL
                UNION ALL
                SELECT 1
                  FROM pat_pregnancy_diagnosis_hist pd
                 WHERE pd.id_pat_pregnancy_hist = i_pat_pregn_hist);
    
        IF i_flg_type IN (g_pat_pregn_type_c, g_pat_pregn_type_r)
           AND (i_flg_complication IS NOT NULL OR i_notes_complication IS NOT NULL OR l_count > 0)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSIF i_flg_type IS NULL
              AND nvl(i_flg_complication, g_flg_no_prob) <> g_flg_no_prob
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_break_summ_pg_compl;

    /********************************************************************************************
    * Checks if the summary page needs an extra break tag
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION check_break_summ_pg_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN pat_pregnancy.flg_type%TYPE,
        i_notes    IN pat_pregnancy.notes%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_type = g_pat_pregn_type_c
           AND i_notes IS NOT NULL
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_break_summ_pg_notes;

    /********************************************************************************************
    * Checks if the summary page needs an extra break tag
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    * @param i_flg_type               Pregnancy type: (R)eported or (C)urrent pregnancy
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/08
    **********************************************************************************************/
    FUNCTION check_break_summ_pg_out
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN pat_pregnancy.flg_type%TYPE,
        i_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_status        IN pat_pregnancy.flg_status%TYPE,
        i_dt_intervention   IN pat_pregnancy.dt_intervention%TYPE,
        i_inst_intervention IN pat_pregnancy.id_inst_intervention%TYPE,
        i_flg_intervention  IN pat_pregnancy.flg_desc_intervention%TYPE,
        i_desc_intervention IN pat_pregnancy.desc_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_flg_type = g_pat_pregn_type_c
        THEN
            IF i_dt_intervention IS NOT NULL
               OR i_inst_intervention IS NOT NULL
               OR i_flg_intervention IS NOT NULL
               OR i_desc_intervention IS NOT NULL
               OR get_pregn_outcome_desc(i_lang, i_flg_status, i_pat_pregnancy, NULL, g_type_summ) IS NOT NULL
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_break_summ_pg_out;

    /********************************************************************************************
    * Checks if a specific pregnancy has complications
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    *                        
    * @return                         pregnancy outcome
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/11
    **********************************************************************************************/
    FUNCTION check_pregn_complications
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_complication   IN pat_pregnancy.flg_complication%TYPE,
        i_notes_complication IN pat_pregnancy.notes_complications%TYPE,
        i_flg_type           IN pat_pregnancy.flg_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_pregnancy_core.check_break_summ_pg_compl(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_flg_type           => i_flg_type,
                                                           i_pat_pregnancy      => i_pat_pregnancy,
                                                           i_pat_pregn_hist     => NULL,
                                                           i_flg_complication   => i_flg_complication,
                                                           i_notes_complication => i_notes_complication);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_pregn_complications;

    /********************************************************************************************
    * Checks if a specific pregnancy code already exists
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          pregnancy ID (when this function is called within a pregnancy edition)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION check_pregnancy_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_code_state    IN pat_pregnancy_code.code_state%TYPE,
        i_code_year     IN pat_pregnancy_code.code_year%TYPE,
        i_code_number   IN pat_pregnancy_code.code_number%TYPE,
        i_flg_type      IN pat_pregnancy_code.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_count NUMBER;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM pat_pregnancy_code pc
         WHERE (pc.code_state = i_code_state OR
               pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state) = i_code_state)
           AND pc.code_year = i_code_year
           AND pc.code_number = i_code_number
           AND pc.flg_type = i_flg_type
           AND pc.id_pat_pregnancy <> nvl(i_pat_pregnancy, -1);
    
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        END IF;
    
        RETURN pk_alert_constant.g_no;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_pregnancy_code;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    * @param i_flg_type               Type of pregnancy code: S - SIS prenatal (brazilian market)
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_pat_pregnancy_code
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pat_pregnancy_hist IN pat_pregnancy_hist.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
    
        l_row_pren_code pat_pregnancy_code%ROWTYPE;
    
    BEGIN
    
        BEGIN
            SELECT *
              INTO l_row_pren_code.code_state, l_row_pren_code.code_year, l_row_pren_code.code_number
              FROM (SELECT nvl(pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state), pc.code_state),
                           pc.code_year,
                           pc.code_number
                      FROM pat_pregnancy_code pc
                     WHERE pc.id_pat_pregnancy = i_pat_pregnancy
                       AND i_pat_pregnancy_hist IS NULL
                    UNION ALL
                    SELECT nvl(pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state), pc.code_state),
                           pc.code_year,
                           pc.code_number
                      FROM pat_pregnancy_code_hist pc
                     WHERE pc.id_pat_pregnancy_hist = i_pat_pregnancy_hist);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN pk_pregnancy_core.get_desc_pregnancy_code(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_code_state  => l_row_pren_code.code_state,
                                                         i_code_year   => l_row_pren_code.code_year,
                                                         i_code_number => l_row_pren_code.code_number);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_pregnancy_code;

    /********************************************************************************************
    * Gets the formatted pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_desc_pregnancy_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE
    ) RETURN VARCHAR2 IS
    
        l_config_code_mask CONSTANT sys_config.id_sys_config%TYPE := 'SIS_PRE_NATAL_MASK';
        l_code_mask       sys_config.value%TYPE;
        l_mask_number     sys_config.value%TYPE;
        l_grouping_symb   sys_config.value%TYPE;
        l_idx_mask_number NUMBER;
        l_code_state      pat_pregnancy_code.code_state%TYPE;
        l_code_number     VARCHAR2(200);
    
        l_ret VARCHAR2(200);
    
    BEGIN
    
        l_code_mask  := pk_sysconfig.get_config(l_config_code_mask, i_prof);
        l_code_state := REPLACE(i_code_state, '.0');
    
        l_grouping_symb := pk_sysconfig.get_config(i_code_cf => 'GROUPING_SYMBOL', i_prof => i_prof);
    
        IF l_code_mask IS NOT NULL
           AND i_code_number IS NOT NULL
        THEN
            l_idx_mask_number := instr(l_code_mask, '0');
            l_mask_number     := substr(l_code_mask, l_idx_mask_number, 9);
        
            IF length(l_code_state) = 1
            THEN
                l_code_state := '0' || l_code_state;
            END IF;
        
            l_code_number := to_char(i_code_number,
                                     l_mask_number,
                                     'NLS_NUMERIC_CHARACTERS = '' ' || l_grouping_symb || ''' ');
        
            l_ret := REPLACE(l_code_mask, 'YY', i_code_year);
            l_ret := REPLACE(l_ret, 'SS', l_code_state);
            l_ret := REPLACE(l_ret, l_mask_number, l_code_number);
        
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_desc_pregnancy_code;

    /********************************************************************************************
    * Gets the serialized pregnancy code to be used in the keypad
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_code_number            Numeric code
    *                        
    * @return                         code already exists: (Y)es or (N)o
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/14
    **********************************************************************************************/
    FUNCTION get_serialized_code
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_state  IN pat_pregnancy_code.code_state%TYPE,
        i_code_year   IN pat_pregnancy_code.code_year%TYPE,
        i_code_number IN pat_pregnancy_code.code_number%TYPE
    ) RETURN VARCHAR2 IS
    
        l_config_code_mask CONSTANT sys_config.id_sys_config%TYPE := 'SIS_PRE_NATAL_MASK';
        l_code_mask       sys_config.value%TYPE;
        l_mask_number     sys_config.value%TYPE;
        l_idx_mask_number NUMBER;
        l_code_state      pat_pregnancy_code.code_state%TYPE;
        l_code_number     VARCHAR2(200);
    
        l_ret VARCHAR2(200);
    
    BEGIN
    
        l_code_mask  := pk_sysconfig.get_config(l_config_code_mask, i_prof);
        l_code_state := REPLACE(i_code_state, '.0');
    
        IF l_code_mask IS NOT NULL
           AND i_code_number IS NOT NULL
        THEN
            l_idx_mask_number := instr(l_code_mask, '0');
            l_mask_number     := REPLACE(substr(l_code_mask, l_idx_mask_number, 9), 'G');
        
            IF length(l_code_state) = 1
            THEN
                l_code_state := '0' || l_code_state;
            END IF;
        
            l_code_number := TRIM(to_char(i_code_number, l_mask_number));
        
            l_ret := l_code_state || i_code_year || l_code_number;
        
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_serialized_code;

    /********************************************************************************************
    * Gets the serialized pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_pregnancy          Pregnancy ID
    *                        
    * @return                         serialized code
    * 
    * @author                         José Silva
    * @version                        2.5.1.9
    * @since                          24-11-2011
    **********************************************************************************************/
    FUNCTION get_serialized_code
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
    
        l_row_pren_code pat_pregnancy_code%ROWTYPE;
    
    BEGIN
    
        BEGIN
            SELECT *
              INTO l_row_pren_code.code_state, l_row_pren_code.code_year, l_row_pren_code.code_number
              FROM (SELECT nvl(pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state), pc.code_state),
                           pc.code_year,
                           pc.code_number
                      FROM pat_pregnancy_code pc
                     WHERE pc.id_pat_pregnancy = i_pat_pregnancy);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
        RETURN pk_pregnancy_core.get_serialized_code(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_code_state  => l_row_pren_code.code_state,
                                                     i_code_year   => l_row_pren_code.code_year,
                                                     i_code_number => l_row_pren_code.code_number);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_serialized_code;

    /********************************************************************************************
    * Gets the next available pregnancy code
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_state             State code
    * @param i_code_year              Year code
    * @param i_starting_number        Serie starting number
    * @param i_ending_number          Serie ending number
    *                        
    * @return                         Next available pregnancy code
    * 
    * @author                         José Silva
    * @version                        2.5.1.5
    * @since                          2011/04/13
    **********************************************************************************************/
    FUNCTION get_pregnancy_next_code
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN pat_pregnancy_code.code_state%TYPE,
        i_code_year       IN pat_pregnancy_code.code_year%TYPE,
        i_starting_number IN NUMBER,
        i_ending_number   IN NUMBER
    ) RETURN pat_pregnancy_code.code_number%TYPE IS
    
        l_ret            pat_pregnancy_code.code_number%TYPE;
        l_current_number NUMBER;
    
    BEGIN
    
        l_current_number := pk_api_backoffice.get_serie_current_number(i_lang,
                                                                       i_prof,
                                                                       i_code_state,
                                                                       i_code_year,
                                                                       i_starting_number,
                                                                       i_ending_number);
    
        SELECT MAX(pc.code_number)
          INTO l_ret
          FROM pat_pregnancy_code pc
         WHERE (pc.code_state = i_code_state OR
               pk_api_backoffice.get_code_state(i_lang, i_prof, pc.id_geo_state) = i_code_state)
           AND pc.code_year = i_code_year
           AND pc.flg_type = g_pregn_code_s -- SIS prenatal
           AND pc.code_number BETWEEN i_starting_number AND i_ending_number;
    
        IF l_ret IS NULL
        THEN
            l_ret := greatest(i_starting_number, nvl(l_current_number, -1));
        ELSIF l_ret < l_current_number
        THEN
            l_ret := l_current_number;
        ELSIF l_ret > i_ending_number
        THEN
            RETURN NULL;
        ELSIF l_ret = i_ending_number
        THEN
            -- 21/07/2011 RMGM: added because when series reach last number, the next code exceeded the serie max limit
            RETURN l_ret;
        ELSE
            l_ret := l_ret + 1;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pregnancy_next_code;

    /********************************************************************************************
    * Gets the pregnancy trimester (based on the ultrasound criteria)
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_flg_weeks_criteria  Weeks criteria (C - chronologic, U - ultrasound)
    * @param   i_dt_init_preg_lmp    Pregnancy initial date (chronologic criteria)
    * @param   i_dt_exam_result_tstz Exam result date
    * @param   i_weeks_pregnancy     Gestation weeks (ultrasound criteria)
    *
    * @RETURN  Pregnancy trimester
    *
    * @author  José Silva
    * @version 1.0
    * @since   14-04-2011
    **********************************************************************************************/
    FUNCTION get_ultrasound_trimester
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_weeks_criteria  IN exam_result_pregnancy.flg_weeks_criteria%TYPE,
        i_dt_init_preg_lmp    IN pat_pregnancy.dt_init_preg_lmp%TYPE,
        i_dt_exam_result_tstz IN exam_result.dt_exam_result_tstz%TYPE,
        i_weeks_pregnancy     IN exam_result_pregnancy.weeks_pregnancy%TYPE
    ) RETURN NUMBER IS
    
        l_ret NUMBER;
    
    BEGIN
    
        IF i_flg_weeks_criteria = g_pregnant_criteria
        THEN
            l_ret := pk_woman_health.conv_weeks_to_trimester(nvl(pk_pregnancy_core.get_pregnancy_weeks(i_prof,
                                                                                                       i_dt_init_preg_lmp,
                                                                                                       i_dt_exam_result_tstz,
                                                                                                       NULL),
                                                                 i_weeks_pregnancy));
        ELSE
            l_ret := pk_woman_health.conv_weeks_to_trimester(i_weeks_pregnancy);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ultrasound_trimester;

    /********************************************************************************************
    * Gets the number of fetus of a specific pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  Number of fetus
    *
    * @author  José Silva
    * @version 2.5.1.5
    * @since   30-05-2011
    **********************************************************************************************/
    FUNCTION get_fetus_number
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN NUMBER IS
    
        l_ret pat_pregnancy.n_children%TYPE;
    
    BEGIN
    
        g_error := 'GET FETUS NUMBER';
        SELECT p.n_children
          INTO l_ret
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fetus_number;

    /********************************************************************************************
    * Gets a specific fetus record ID
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_fetus_number        fetus number
    *
    * @RETURN  Number of fetus
    *
    * @author  José Silva
    * @version 2.5.1.5
    * @since   30-05-2011
    **********************************************************************************************/
    FUNCTION get_pregn_fetus_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_fetus_number  IN pat_pregn_fetus.fetus_number%TYPE
    ) RETURN pat_pregn_fetus.id_pat_pregn_fetus%TYPE IS
    
        l_ret pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
    
    BEGIN
    
        g_error := 'GET FETUS ID';
        SELECT p.id_pat_pregn_fetus
          INTO l_ret
          FROM pat_pregn_fetus p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy
           AND p.fetus_number = i_fetus_number;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pregn_fetus_id;

    /********************************************************************************************
    * Get all the pregnants that will be exported to the SISPRENATAL archive
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_scope               scope of the extraction: (I)nside or (O)utside pregnancies (based on the SISPRENATAL code)
    * @param   o_patient             patient IDs
    * @param   o_pat_pregnancy       pregnancy IDs
    *
    * @return                        true or false on success or error
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   17-11-2011
    **********************************************************************************************/
    FUNCTION get_pat_sisprenatal
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN VARCHAR2,
        i_institution   IN institution.id_institution%TYPE,
        o_patient       OUT table_number,
        o_pat_pregnancy OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_config_pregn_interval CONSTANT sys_config.id_sys_config%TYPE := 'SISPRENATAL_MAX_PUERPERAL';
    
        l_num_max_days NUMBER;
    
    BEGIN
    
        g_error        := 'GET NUM MAX WEEKS';
        l_num_max_days := to_number(pk_sysconfig.get_config(l_config_pregn_interval, i_prof));
    
        g_error := 'GET PREGNANCIES ID LIST';
        SELECT DISTINCT pregn.id_patient, pregn.id_pat_pregnancy
          BULK COLLECT
          INTO o_patient, o_pat_pregnancy
          FROM (SELECT pp.id_patient,
                       pp.id_pat_pregnancy,
                       pp.dt_init_pregnancy,
                       pp.dt_intervention,
                       pp.flg_status,
                       pk_api_backoffice.check_inst_serie_number(i_lang,
                                                                 i_prof,
                                                                 pc.code_number,
                                                                 pc.code_state,
                                                                 pc.id_geo_state,
                                                                 to_char(pp.dt_init_pregnancy, 'YYYY')) has_code
                  FROM pat_pregnancy pp
                  JOIN pat_pregnancy_code pc
                    ON pc.id_pat_pregnancy = pp.id_pat_pregnancy
                 WHERE pp.flg_status = g_pat_pregn_active
                    OR ((trunc(SYSDATE) - trunc(pp.dt_intervention)) < l_num_max_days AND
                       pp.flg_status <> g_pat_pregn_cancel)) pregn
          JOIN episode epis
            ON epis.id_patient = pregn.id_patient
           AND epis.id_institution = nvl(i_institution, epis.id_institution)
         WHERE ((i_scope = pk_api_sisprenatal_out.g_sisprenatal_in AND has_code = pk_alert_constant.g_yes) OR
               (i_scope = pk_api_sisprenatal_out.g_sisprenatal_out AND has_code = pk_alert_constant.g_no) OR
               (i_scope = pk_api_sisprenatal_out.g_sisprenatal_int AND epis.dt_begin_tstz > pregn.dt_intervention AND
               (pregn.flg_status NOT IN (g_pat_pregn_active, g_pat_pregn_past)) OR EXISTS
                (SELECT 0
                    FROM pat_pregn_fetus ppf
                   WHERE ppf.id_pat_pregnancy = pregn.id_pat_pregnancy
                     AND instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0)) OR i_scope IS NULL)
           AND epis.dt_begin_tstz > pregn.dt_init_pregnancy
         ORDER BY id_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling_ext(i_lang, 'GET_PAT_SISPRENATAL', g_error, SQLCODE, SQLERRM, FALSE, 'S', o_error);
    END get_pat_sisprenatal;

    /********************************************************************************************
    * Get the last menstruation date of a given pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  Last menstuation date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_dt_lmp_pregn
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN pat_pregnancy.dt_last_menstruation%TYPE IS
    
        l_dt_lmp pat_pregnancy.dt_last_menstruation%TYPE;
    
    BEGIN
    
        g_error := 'GET FETUS ID';
        SELECT p.dt_last_menstruation
          INTO l_dt_lmp
          FROM pat_pregnancy p
         WHERE p.id_pat_pregnancy = i_pat_pregnancy;
    
        RETURN l_dt_lmp;
    END get_dt_lmp_pregn;

    /********************************************************************************************
    * Get the date of the first episode that occured during the pregnancy
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_flg_type_date       return date: (F)irst or (L)ast episode
    *
    * @RETURN  First or last episode date
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   18-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_dt_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_flg_type_date IN VARCHAR2
    ) RETURN DATE IS
    
        l_dt_begin episode.dt_begin_tstz%TYPE;
    
        CURSOR c_epis_dt IS
            SELECT e.dt_begin_tstz
              FROM pat_pregnancy p
              JOIN episode e
                ON e.id_patient = p.id_patient
             WHERE p.id_pat_pregnancy = i_pat_pregnancy
               AND e.dt_begin_tstz > p.dt_init_pregnancy
             ORDER BY CASE i_flg_type_date
                          WHEN pk_pregnancy_api.g_flg_dt_first_epis THEN
                           e.dt_begin_tstz
                      END ASC,
                      CASE i_flg_type_date
                          WHEN pk_pregnancy_api.g_flg_dt_last_epis THEN
                           e.dt_begin_tstz
                      END DESC;
    
    BEGIN
    
        g_error := 'GET FETUS ID';
        OPEN c_epis_dt;
        FETCH c_epis_dt
            INTO l_dt_begin;
        CLOSE c_epis_dt;
    
        RETURN CAST((pk_date_utils.trunc_insttimezone(i_prof, l_dt_begin)) AS DATE);
    END get_pregn_dt_epis;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the pregnancy episode type 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pregn_dt_interv     pregnancy labour/abortion date
    * @param   i_pregn_flg_status    pregnancy status
    * @param   i_epis_dt_begin       episode begin date
    * @param   i_epis_dt_end         episode end date
    *
    * @RETURN  Episode code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   21-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_episode_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pregn_dt_interv  IN pat_pregnancy.dt_intervention%TYPE,
        i_pregn_flg_status IN pat_pregnancy.flg_status%TYPE,
        i_epis_dt_begin    IN episode.dt_begin_tstz%TYPE,
        i_epis_dt_end      IN episode.dt_end_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_epis VARCHAR2(1 CHAR);
        l_ret_epis_normal    CONSTANT VARCHAR2(1 CHAR) := '1';
        l_ret_epis_labour    CONSTANT VARCHAR2(1 CHAR) := '3';
        l_ret_epis_puerperal CONSTANT VARCHAR2(1 CHAR) := '5';
        l_ret_epis_abortion  CONSTANT VARCHAR2(1 CHAR) := '9';
    
        l_epis_dt_begin DATE;
        l_epis_dt_end   DATE;
        l_dt_interv     DATE;
    
    BEGIN
    
        g_error         := 'GET TRUNCATED DATES';
        l_epis_dt_begin := CAST((pk_date_utils.trunc_insttimezone(i_prof, i_epis_dt_begin)) AS DATE);
        l_epis_dt_end   := CAST((pk_date_utils.trunc_insttimezone(i_prof, i_epis_dt_end)) AS DATE);
        l_dt_interv     := CAST((pk_date_utils.trunc_insttimezone(i_prof, i_pregn_dt_interv)) AS DATE);
    
        g_error := 'CHECK EPISODE TYPE';
        IF l_dt_interv BETWEEN l_epis_dt_begin AND l_epis_dt_end
        THEN
            IF i_pregn_flg_status IN (g_pat_pregn_active, g_pat_pregn_past)
            THEN
                l_ret_epis := l_ret_epis_labour;
            ELSE
                l_ret_epis := l_ret_epis_abortion;
            END IF;
        ELSIF l_epis_dt_begin < l_dt_interv
              OR (i_pregn_flg_status = g_pat_pregn_active AND l_epis_dt_begin IS NOT NULL)
        THEN
            l_ret_epis := l_ret_epis_normal;
        ELSIF l_epis_dt_begin >= l_dt_interv
        THEN
            l_ret_epis := l_ret_epis_puerperal;
        END IF;
    
        RETURN l_ret_epis;
    END get_pregn_episode_type;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the labour/abortion location 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pregn_flg_interv    labour/abortion location
    *
    * @RETURN  Location code
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_location_code
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pregn_flg_interv IN pat_pregnancy.flg_desc_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_location VARCHAR2(2 CHAR);
        l_ret_loc_unk    CONSTANT VARCHAR2(2 CHAR) := '00';
        l_ret_loc_home   CONSTANT VARCHAR2(2 CHAR) := '20';
        l_ret_loc_hosp   CONSTANT VARCHAR2(2 CHAR) := '30';
        l_ret_loc_ignore CONSTANT VARCHAR2(2 CHAR) := '99';
    
    BEGIN
    
        g_error := 'GET INTERVENTION LOCATION CODE';
        CASE i_pregn_flg_interv
            WHEN g_desc_intervention_inst THEN
                l_ret_location := l_ret_loc_hosp;
            WHEN g_desc_intervention_other THEN
                l_ret_location := l_ret_loc_hosp;
            WHEN g_desc_intervention_home THEN
                l_ret_location := l_ret_loc_home;
            ELSE
                l_ret_location := l_ret_loc_unk;
        END CASE;
    
        RETURN l_ret_location;
    END get_pregn_location_code;

    /********************************************************************************************
    * Get the pregnancy birth type
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    *
    * @RETURN  pregnancy birth type
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   22-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_birth_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE
    ) RETURN VARCHAR2 IS
    
        l_birth_type pat_pregn_fetus.flg_childbirth_type%TYPE;
    
        -- currently the SISPRENATAL file only accepts one birth type
        CURSOR c_pregn_fetus IS
            SELECT ppf.flg_childbirth_type
              FROM pat_pregn_fetus ppf
             WHERE ppf.id_pat_pregnancy = i_pat_pregnancy
               AND nvl(ppf.flg_status, g_pregn_fetus_cancel) = g_pregn_fetus_cancel
             ORDER BY ppf.fetus_number;
    
    BEGIN
    
        g_error := 'GET CHILD BIRTH TYPE';
        OPEN c_pregn_fetus;
        FETCH c_pregn_fetus
            INTO l_birth_type;
        CLOSE c_pregn_fetus;
    
        RETURN l_birth_type;
    END get_pregn_birth_type;

    /********************************************************************************************
    * Get the SISPRENATAL code that represents the pregnancy interruption type 
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_pat_pregnancy       pregnancy ID
    * @param   i_pregn_flg_status    pregnancy status
    *
    * @RETURN  Type of abortion
    *
    * @author  José Silva
    * @version 2.5.1.9
    * @since   25-11-2011
    **********************************************************************************************/
    FUNCTION get_pregn_inter_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat_pregnancy    IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_pregn_flg_status IN pat_pregnancy.flg_status%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_pregnancy VARCHAR2(2 CHAR);
        l_ret_pregn_abortion CONSTANT VARCHAR2(2 CHAR) := '01';
        l_ret_pregn_death    CONSTANT VARCHAR2(2 CHAR) := '04';
        l_ret_pregn_other    CONSTANT VARCHAR2(2 CHAR) := '99';
        l_count NUMBER;
    
    BEGIN
    
        g_error := 'CHECK EPISODE TYPE';
        IF i_pregn_flg_status NOT IN (g_pat_pregn_active, g_pat_pregn_past)
        THEN
            l_ret_pregnancy := l_ret_pregn_abortion;
        ELSE
            SELECT COUNT(*)
              INTO l_count
              FROM pat_pregn_fetus ppf
             WHERE ppf.id_pat_pregnancy = i_pat_pregnancy
               AND instr(ppf.flg_status, pk_pregnancy_core.g_pregn_fetus_dead) > 0;
        
            IF l_count > 0
            THEN
                l_ret_pregnancy := l_ret_pregn_death;
            END IF;
        
        END IF;
    
        RETURN l_ret_pregnancy;
    END get_pregn_inter_type;

    /********************************************************************************************
    * Checks if a specific pregnancy has an early puerperal period
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_dt_init_pregn       pregnancy begin date
    * @param   i_dt_intervention     pregnancy end date
    *
    * @RETURN  Early puerperal code
    *
    * @author  José Silva
    * @version 2.5.1.10
    * @since   13-12-2011
    **********************************************************************************************/
    FUNCTION get_pregn_early_puerperal
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_dt_init_pregn   IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_intervention IN pat_pregnancy.dt_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_ret_pregnancy VARCHAR2(1 CHAR);
        l_ret_normal CONSTANT VARCHAR2(1 CHAR) := '0';
        l_ret_early  CONSTANT VARCHAR2(1 CHAR) := '1';
        l_num_weeks NUMBER;
        l_config_numweeks CONSTANT sys_config.id_sys_config%TYPE := 'SISPRENATAL_EARLY_PUERPERAL';
        l_max_weeks NUMBER;
    
    BEGIN
    
        l_ret_pregnancy := l_ret_normal;
    
        IF i_dt_intervention IS NOT NULL
        THEN
            l_max_weeks := pk_sysconfig.get_config(i_code_cf => l_config_numweeks, i_prof => i_prof);
            l_num_weeks := get_pregnancy_weeks(i_prof, i_dt_init_pregn, i_dt_intervention, NULL);
        
            IF l_num_weeks < l_max_weeks
            THEN
                l_ret_pregnancy := l_ret_early;
            END IF;
        
        END IF;
    
        RETURN l_ret_pregnancy;
    END get_pregn_early_puerperal;

    /********************************************************************************************
    * Get the first episode ID after the pregnancy begin date
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_dt_init_pregn       pregnancy begin date
    *
    * @RETURN  Episode ID
    *
    * @author  José Silva
    * @version 2.5.1.11
    * @since   29-12-2011
    **********************************************************************************************/
    FUNCTION get_pregn_first_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_dt_init_pregn IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN episode.id_episode%TYPE IS
    
        l_id_episode episode.id_episode%TYPE;
    
        CURSOR c_epis IS
            SELECT epis.id_episode
              FROM episode epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
             WHERE epis.id_patient = i_patient
               AND ei.flg_unknown = pk_alert_constant.g_no
               AND epis.flg_status <> pk_alert_constant.g_cancelled
               AND epis.dt_begin_tstz > i_dt_init_pregn
             ORDER BY epis.dt_begin_tstz;
    
    BEGIN
    
        g_error := 'FETCH FIRST EPISODE';
        OPEN c_epis;
        FETCH c_epis
            INTO l_id_episode;
        CLOSE c_epis;
    
        RETURN l_id_episode;
    END get_pregn_first_epis;
    FUNCTION get_flg_pregn_out_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_flg_pregn OUT pat_pregnancy.flg_preg_out_type%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            SELECT z.flg_preg_out_type
              INTO o_flg_pregn
              FROM (SELECT a.flg_preg_out_type
                    
                      FROM pat_pregnancy a
                     WHERE id_episode = i_episode
                       AND a.flg_status != pk_alert_constant.g_cancelled
                     ORDER BY a.dt_pat_pregnancy_tstz DESC) z
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_pregn := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_CORE',
                                              'GET_FLG_PREGN_OUT_TYPE',
                                              o_error);
            RETURN FALSE;
    END get_flg_pregn_out_type;

    /**
    * Returns the last recorded values of pregnancies numbers (number of abortion, birth and getation)
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_patient             Patient identifier
    *
    * @param o_pregn_summ             Array with last registered numbers for pregnancies summary
    * @param o_error                  error information
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Anna Kurowska
    * @version                        2.7.1
    * @since                          07-Aug-2017
    */
    FUNCTION get_last_preg_numbers
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_pregn_summ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'GET last recorded values of pregnancies numbers';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_last_preg_numbers');
        OPEN o_pregn_summ FOR
            SELECT t_int.num_births, t_int.num_abortions, t_int.num_gestations
              FROM (SELECT /*+opt_estimate(table,t,scale_rows=0.1)*/
                     pp.num_births, pp.num_abortions, pp.num_gestations
                      FROM pat_pregnancy pp
                     WHERE pp.id_patient = i_id_patient
                       AND pp.flg_status <> pk_pregnancy_core.g_pat_pregn_cancel
                     ORDER BY pp.dt_pat_pregnancy_tstz DESC) t_int
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_pregn_summ);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_LAST_PREG_NUMBERS',
                                              o_error);
        
            RETURN FALSE;
    END get_last_preg_numbers;

    FUNCTION get_preg_weeks_unk
    (
        i_prof                IN profissional,
        i_dt_preg             IN DATE,
        i_dt_reg              IN pat_pregnancy.dt_intervention%TYPE,
        i_weeks               IN pat_pregnancy.num_gest_weeks%TYPE,
        i_flg_gest_weeks      IN pat_pregnancy.flg_gest_weeks%TYPE,
        i_flg_gest_weeks_exam IN pat_pregnancy.flg_gest_weeks_exam%TYPE,
        i_flg_gest_weeks_us   IN pat_pregnancy.flg_gest_weeks_us%TYPE
    ) RETURN NUMBER IS
    
        l_dt_reg DATE;
        l_weeks  NUMBER;
        l_value_unknown CONSTANT VARCHAR2(20) := '99';
    BEGIN
    
        g_error  := 'GET GET_PREG_WEEKS_UNK';
        l_dt_reg := nvl(CAST(i_dt_reg AS DATE), SYSDATE);
    
        IF i_dt_preg IS NOT NULL
        THEN
            l_weeks := trunc((trunc(l_dt_reg) - trunc(i_dt_preg)) / 7);
        ELSE
            l_weeks := trunc(i_weeks);
        END IF;
    
        IF l_weeks = 0
           OR l_weeks IS NULL
        THEN
            IF i_flg_gest_weeks = 'U'
               OR i_flg_gest_weeks_exam = 'U'
               OR i_flg_gest_weeks_us = 'U'
            THEN
                l_weeks := l_value_unknown;
            ELSE
                l_weeks := NULL;
            END IF;
        END IF;
    
        RETURN l_weeks;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_preg_weeks_unk;
BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_pregnancy_core;
/
