/*-- Last Change Revision: $Rev: 2027278 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_util IS

    /********************************************************************************************************************************************
    * GET_TIME_FRAME_INT         Function that returns the corresponding time frame for a given date
    *
    * @param  I_LANG             Language associated to the professional executing the request
    * @param  I_PROF             Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DATE             Date
    * @param  O_TIME_FRAME_DESC  Time frame description
    * @param  O_TIME_FRAME_RANK  Time frame rank
    *
    * @return                   Returns the time frame interval
    *                           Possible return values:
    *                            NULL - On error
    *                            Future
    *                            Next year
    *                            Future events in this year
    *                            Next month
    *                            Future events in this month
    *                            Next week
    *                            This week
    *                            Last week
    *                            Past events in this month
    *                            Last month
    *                            Past events in this year
    *                            Last year
    *                            Past
    *
    * @author  Alexandre Santos
    * @version 2.5.0.5
    * @since   24-Jul-2009
    *******************************************************************************************************************************************/
    FUNCTION get_time_frame_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_time_frame_desc OUT sys_message.desc_message%TYPE,
        o_time_frame_rank OUT PLS_INTEGER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_curr_year  PLS_INTEGER;
        l_curr_month PLS_INTEGER;
        l_curr_week  PLS_INTEGER;
        --
        l_dt_year  PLS_INTEGER;
        l_dt_month PLS_INTEGER;
        l_dt_week  PLS_INTEGER;
        --
        l_time_frame_num NUMBER;
        l_time_frame     sys_message.desc_message%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_curr_year  := to_number(to_char(g_sysdate_tstz, pk_alert_constant.g_dt_yyyy));
        l_curr_month := to_number(to_char(g_sysdate_tstz, pk_alert_constant.g_dt_mm));
        l_curr_week  := pk_date_utils.get_week_number(i_prof, g_sysdate_tstz, pk_alert_constant.g_dt_iw);
    
        l_time_frame_num := NULL;
        l_time_frame     := NULL;
    
        IF (i_date IS NOT NULL)
        THEN
            l_dt_year  := to_number(to_char(i_date, pk_alert_constant.g_dt_yyyy));
            l_dt_month := to_number(to_char(i_date, pk_alert_constant.g_dt_mm));
            l_dt_week  := pk_date_utils.get_week_number(i_prof, i_date, pk_alert_constant.g_dt_iw);
        
            g_error := 'DATE IS NOT NULL';
            pk_alertlog.log_debug(g_error);
        
            IF (l_dt_year = l_curr_year)
            THEN
                IF (l_dt_month = l_curr_month)
                THEN
                    IF (l_dt_week = l_curr_week)
                    THEN
                        l_time_frame_num := g_this_week; -- This Week
                    ELSIF (l_dt_week < l_curr_week)
                    THEN
                        IF (l_curr_week - 1 = l_dt_week)
                        THEN
                            l_time_frame_num := g_last_week; -- Last Week
                        ELSE
                            l_time_frame_num := g_past_events_this_month; -- Past events in this Month
                        END IF;
                    ELSIF (l_dt_week > l_curr_week)
                    THEN
                        IF (l_curr_week + 1 = l_dt_week)
                        THEN
                            l_time_frame_num := g_next_week; -- Next Week
                        ELSE
                            l_time_frame_num := g_future_this_month; -- Future events in this Month
                        END IF;
                    END IF;
                ELSIF (l_dt_month < l_curr_month)
                THEN
                    IF (l_curr_month - 1 = l_dt_month)
                    THEN
                        l_time_frame_num := g_last_month; -- Last Month
                    ELSE
                        l_time_frame_num := g_past_events_this_year; -- Past events in this Year
                    END IF;
                ELSIF (l_dt_month > l_curr_month)
                THEN
                    IF (l_curr_month + 1 = l_dt_month)
                    THEN
                        l_time_frame_num := g_next_month; -- Next Month
                    ELSE
                        l_time_frame_num := g_future_this_year; -- Future events in this Year
                    END IF;
                END IF;
            ELSIF (l_dt_year < l_curr_year)
            THEN
                IF (l_curr_year - 1 = l_dt_year)
                THEN
                    l_time_frame_num := g_last_year; -- Last Year
                ELSE
                    l_time_frame_num := g_past; -- Past
                END IF;
            ELSIF (l_dt_year > l_curr_year)
            THEN
                IF (l_curr_year + 1 = l_dt_year)
                THEN
                    l_time_frame_num := g_next_year; -- Next Year
                ELSE
                    l_time_frame_num := g_future; -- Future
                END IF;
            END IF;
        END IF;
    
        IF (l_time_frame_num IS NOT NULL)
        THEN
            g_error := 'L_TIME_FRAME_NUM= ' || l_time_frame_num;
            pk_alertlog.log_debug(g_error);
            l_time_frame := pk_message.get_message(i_lang, g_msg_bmng_timeframe_m || to_char(l_time_frame_num));
            --
            o_time_frame_rank := l_time_frame_num;
        ELSE
            --This week
            g_error := 'L_TIME_FRAME_NUM IS NULL';
            pk_alertlog.log_debug(g_error);
            l_time_frame := pk_message.get_message(i_lang, g_msg_bmng_timeframe_m7);
            --
            o_time_frame_rank := g_this_week;
        END IF;
    
        o_time_frame_desc := l_time_frame;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_FRAME_INT',
                                              o_error);
        
            RETURN FALSE;
    END get_time_frame_int;

    /********************************************************************************************************************************************
    * GET_TIME_FRAME_DESC                 Function that returns the corresponding time frame description for a given date
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DATE                      Date of registry
    *
    * 
    * @return                             Returns VARCHAR2 with TIME_FRAME_DESCRIPTION if success, otherwise returns NULL
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.7
    * @since                              2009/10/02
    *******************************************************************************************************************************************/
    FUNCTION get_time_frame_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_time_frame_num NUMBER;
        l_time_frame     sys_message.desc_message%TYPE;
        l_err            t_error_out;
    BEGIN
        --
        IF NOT get_time_frame_int(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_date            => i_date,
                                  o_time_frame_desc => l_time_frame,
                                  o_time_frame_rank => l_time_frame_num,
                                  o_error           => l_err)
        THEN
            RETURN l_time_frame;
        END IF;
    
        RETURN l_time_frame;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_FRAME_DESC',
                                              l_err);
        
            RETURN NULL;
    END get_time_frame_desc;

    /**
    * Function that returns the corresponding time frame description for a given time frame rank
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_time_frame_rank    Time frame rank
    *
    * @return  Time frame description if success, otherwise returns NULL
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.1.8.2
    * @since   14-10-2011
    */
    FUNCTION get_time_frame_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_time_frame_rank IN PLS_INTEGER
    ) RETURN VARCHAR2 IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_time_frame_desc';
        l_time_frame sys_message.desc_message%TYPE;
        l_err        t_error_out;
    BEGIN
        l_time_frame := pk_message.get_message(i_lang, g_msg_bmng_timeframe_m || to_char(i_time_frame_rank));
        RETURN l_time_frame;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => l_err);
            RETURN NULL;
    END get_time_frame_desc;

    /********************************************************************************************************************************************
    * GET_TIME_FRAME_RANK                 Function that returns the corresponding time frame rank for a given date
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DATE                      Date of registry
    *
    * 
    * @return                             Returns VARCHAR2 with TIME_FRAME_DESCRIPTION if success, otherwise returns NULL
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.7
    * @since                              2009/10/02
    *******************************************************************************************************************************************/
    FUNCTION get_time_frame_rank
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN PLS_INTEGER IS
        l_time_frame_num PLS_INTEGER;
        l_time_frame     sys_message.desc_message%TYPE;
        l_err            t_error_out;
    BEGIN
        --
        IF NOT get_time_frame_int(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_date            => i_date,
                                  o_time_frame_desc => l_time_frame,
                                  o_time_frame_rank => l_time_frame_num,
                                  o_error           => l_err)
        THEN
            RETURN l_time_frame_num;
        END IF;
    
        RETURN l_time_frame_num;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIME_FRAME_RANK',
                                              l_err);
        
            RETURN NULL;
    END get_time_frame_rank;

    -- ################################################################################

    /******************************************************************************
    NAME: LEAST_LENGTH
    CREATION INFO: CARLOS FERREIRA 2006/09/08
    GOAL: FORMATS DATES
    
    PARAMETERS:
    ----------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION             |
    ---------------------------------------------------------------------------------|
    ----------------------------------------------------------------------------------
    OBS: Messages are limited to a length of 255 chars ( system limitation ).
    
    *********************************************************************************/
    FUNCTION least_length
    (
        i_big_word   IN VARCHAR2,
        i_small_word IN VARCHAR2,
        i_max_length IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF length(i_small_word) <= i_max_length
        THEN
            l_return := i_small_word;
        END IF;
        IF length(i_big_word) <= i_max_length
        THEN
            l_return := i_big_word;
        END IF;
    
        RETURN l_return;
    
    END least_length;
    -- ####################################################################################################

    /******************************************************************************
    NAME: DD_MON_YYYY
    CREATION INFO: CARLOS FERREIRA 2006/09/08
    GOAL: FORMATS DATES
    
    PARAMETERS:
    ----------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION             |
    ---------------------------------------------------------------------------------|
    ----------------------------------------------------------------------------------
    OBS: Messages are limited to a length of 255 chars ( system limitation ).
    
    *********************************************************************************/
    FUNCTION dd_mon_yyyy
    (
        i_lang IN NUMBER,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_date_utils.dt_chr(i_lang, i_date, i_prof);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END dd_mon_yyyy;
    -- ####################################################################################################

    /******************************************************************************
    NAME: HH24_MI_H
    CREATION INFO: CARLOS FERREIRA 2006/09/08
    GOAL: FORMATS DATES
    
    PARAMETERS:
    ----------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION             |
    ---------------------------------------------------------------------------------|
    ----------------------------------------------------------------------------------
    OBS: Messages are limited to a length of 255 chars ( system limitation ).
    
    *********************************************************************************/
    FUNCTION hh24_mi_h
    (
        i_lang IN NUMBER,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_date_utils.dt_chr_hour(i_lang, i_date, i_prof);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END hh24_mi_h;
    -- ####################################################################################################

    FUNCTION get_nch_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_nch  IN bmng_action.nch_capacity%TYPE
    ) RETURN PLS_INTEGER IS
        l_nch_median PLS_INTEGER;
        l_nch_avg    PLS_INTEGER;
        l_err        t_error_out;
    BEGIN
        g_error      := 'GET SYS_CONFIGS';
        l_nch_median := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_median,
                                                i_prof.institution,
                                                i_prof.software);
        l_nch_avg    := pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_dep,
                                                i_prof.institution,
                                                i_prof.software);
    
        g_error := 'COMPARE VALUES';
        IF i_nch < l_nch_avg
        THEN
            RETURN 1;
        ELSIF i_nch >= l_nch_avg
              AND i_nch <= l_nch_median
        THEN
            RETURN 2;
        ELSE
            RETURN 3;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_INT',
                                              l_err);
        
            RETURN NULL;
        
    END get_nch_int;

    /******************************************************************************
    NAME: DO_LOG
    CREATION INFO: CARLOS FERREIRA 2006/09/08
    GOAL: SAVES INTO TABLE LOG A RECORD WITH THE LAST LOG INFO
    
    PARAMETERS:
    ----------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION             |
    ---------------------------------------------------------------------------------|
    I_PACKAGE          | VARCHAR2               | IN  | NOME DO PACKAGE ORIGEM       |
    I_COMM             | VARCHAR2               | IN  | LAST COMMENT                 |
    ----------------------------------------------------------------------------------
    OBS:
    
    *********************************************************************************/
    PROCEDURE do_log
    (
        i_package IN VARCHAR2,
        i_comm    IN VARCHAR2
    ) IS
        error_do_nothing EXCEPTION;
    BEGIN
        NULL;
    EXCEPTION
        WHEN error_do_nothing THEN
            NULL;
        WHEN OTHERS THEN
            NULL;
    END do_log;

    /*******************************************************************************************************************************************
    * get_pat_and_visit               Get patient from i_id_episode (if not null) or i_id_visit (if not null) if the scope is PAtient
    *                                 Get visit from i_id_episode (if not null) if the scope is Visit    
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param   i_flg_scope            Scope: P -patient; E- episode; V-visit; S-session
    * @param   i_id_episode           Episode identifier; mandatory if i_flg_scope='E'
    * @param   i_id_patient           Patient identifier; mandatory if i_flg_scope='P'
    * @param   i_id_visit             Visit identifier; mandatory if i_flg_scope='V'     
    * @param   o_id_patient           Patient id    
    * @param   o_id_visit             Visit id
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          22-Dec-2010
    *******************************************************************************************************************************************/
    FUNCTION get_pat_and_visit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_scope  IN VARCHAR2, -- P -patient; E- episode; V-visit
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_id_patient OUT patient.id_patient%TYPE,
        o_id_visit   OUT visit.id_visit%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_invalid_arguments EXCEPTION;
    BEGIN
        g_error := 'CHECK ARGUMENTS';
        IF (i_flg_scope = pk_inp_util.g_scope_patient_p AND i_id_patient IS NULL AND i_id_episode IS NOT NULL)
        THEN
            g_error      := 'CALL pk_Episode.get_epis_patient. i_id_episode: ' || i_id_episode;
            o_id_patient := pk_episode.get_epis_patient(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode);
        ELSIF (i_flg_scope = pk_inp_util.g_scope_patient_p AND i_id_patient IS NULL AND i_id_visit IS NOT NULL)
        THEN
            g_error := 'GET ID_PATIENT: i_id_visit: ' || i_id_visit;
            SELECT v.id_patient
              INTO o_id_patient
              FROM visit v
             WHERE v.id_visit = i_id_visit;
        
        ELSIF (i_flg_scope = pk_inp_util.g_scope_visit_v AND i_id_visit IS NULL AND i_id_episode IS NOT NULL)
        THEN
            g_error    := 'CALL pk_Episode.get_id_visit. i_id_episode: ' || i_id_episode;
            o_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
        ELSIF (i_flg_scope = pk_inp_util.g_scope_visit_v AND i_id_visit IS NOT NULL)
        THEN
            o_id_visit := i_id_visit;
        ELSE
            IF ((i_flg_scope = pk_inp_util.g_scope_visit_v AND i_id_patient IS NULL AND i_id_episode IS NOT NULL) OR
               (i_flg_scope = pk_inp_util.g_scope_episode_e AND i_id_episode IS NULL))
            THEN
                RAISE l_invalid_arguments;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_AND_VISIT',
                                              o_error);
            RETURN FALSE;
    END get_pat_and_visit;

    /********************************************************************************************
    * get_format_interval            Get the interval description in format: X hours Y minutes,
    *                                given the interval in minutes
    *
    * @param i_hours                 Interval in hours
    * @param i_minutes               Interval in minutes
    *
    * @return                        Returns the conversion of interval to Time (x hours y minutes)
    * Function based pk_inp_hidrics.get_interval_desc 
    * @author                        Filipe Silva
    * @since                         07-Jul-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_format_interval
    (
        i_lang    IN language.id_language%TYPE,
        i_hours   IN NUMBER,
        i_minutes IN NUMBER
    ) RETURN VARCHAR2 IS
    
        l_desc VARCHAR2(1000 CHAR);
    
        l_msg_hour    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, g_code_msg_hour);
        l_msg_hours   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, g_code_msg_hours);
        l_msg_minute  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, g_sm_minute);
        l_msg_minutes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, g_sm_minutes);
    
    BEGIN
    
        IF (i_hours > 0)
        THEN
            IF (i_hours = g_one_hour_unit)
            THEN
                l_desc := i_hours || ' ' || l_msg_hour;
            ELSE
                l_desc := i_hours || ' ' || l_msg_hours;
            END IF;
        END IF;
    
        IF (i_minutes > 0)
        THEN
            l_desc := CASE
                          WHEN l_desc IS NOT NULL THEN
                           l_desc || ' '
                      END;
        
            IF (i_minutes = g_one_hour_unit)
            THEN
                l_desc := l_desc || i_minutes || ' ' || l_msg_minute;
            ELSE
                l_desc := l_desc || i_minutes || ' ' || l_msg_minutes;
            END IF;
        
        END IF;
    
        RETURN l_desc;
    
    END get_format_interval;

-- ******************************************************************************
-- ********************************  CONSTRUCTOR   ******************************
-- ******************************************************************************
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
