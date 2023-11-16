/*-- Last Change Revision: $Rev: 2050136 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-14 14:41:05 +0000 (seg, 14 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_date_utils AS

    g_validate_error BOOLEAN;

    exc_impossible_date EXCEPTION;
    PRAGMA EXCEPTION_INIT(exc_impossible_date, -01878);

    --correct FR dates from "28/MAI /2013" to "28/MAI/2013"
    --this is an oracle behaviour that needs to be overriden
    FUNCTION correct_date(i_dt_str IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
        IF instr(i_dt_str, '/') > 0
        THEN
            RETURN regexp_replace(i_dt_str, '[[:space:]]+\/', '/');
        ELSIF instr(i_dt_str, '-') > 0
        THEN
            l_return := regexp_replace(i_dt_str, '[[:space:]]+\-', '-');
        ELSE
            l_return := rtrim(i_dt_str);
        END IF;
    
        l_return := REPLACE(l_return, '.', '');
    
        RETURN l_return;
    
    END;

    FUNCTION add_days
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_amount IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dd VARCHAR2(0100 CHAR);
        l_mm VARCHAR2(0100 CHAR);
        l_yy VARCHAR2(0100 CHAR);
        l_hr VARCHAR2(0100 CHAR);
        l_mi VARCHAR2(0100 CHAR);
        l_ss VARCHAR2(0100 CHAR);
    
        l_session_tz    VARCHAR2(0100 CHAR);
        l_date_vc2      VARCHAR2(0100 CHAR);
        l_timestamp_vc2 VARCHAR2(0100 CHAR);
        l_date          DATE;
    
        l_return TIMESTAMP WITH LOCAL TIME ZONE;
    
        k_mask_yyyy   CONSTANT VARCHAR2(0010 CHAR) := '0000';
        k_mask_2digit CONSTANT VARCHAR2(0010 CHAR) := '00';
        k_mask_date   CONSTANT VARCHAR2(0010 CHAR) := 'YYYYMMDD';
    
        xx VARCHAR2(0100 CHAR);
    BEGIN
    
        -- get session timezone
        l_session_tz := sessiontimezone;
    
        -- extract info for date
        l_yy := to_char(extract(YEAR FROM(i_date)), k_mask_yyyy);
        l_mm := to_char(extract(MONTH FROM(i_date)), k_mask_2digit);
        l_dd := to_char(extract(DAY FROM(i_date)), k_mask_2digit);
    
        l_hr := to_char(extract(hour FROM(i_date)), k_mask_2digit);
        l_mi := to_char(extract(minute FROM(i_date)), k_mask_2digit);
        l_ss := to_char(extract(SECOND FROM(i_date)), k_mask_2digit);
    
        -- convert to date and amount of days
        l_date := to_date(l_yy || l_mm || l_dd, k_mask_date) + i_amount;
    
        l_date_vc2 := to_char(l_date, k_mask_date);
    
        pk_date_utils.set_dst_time_check_off;
        l_timestamp_vc2 := l_date_vc2 || l_hr || l_mi || l_ss;
    
        l_return := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_timestamp_vc2,
                                                  i_timezone  => l_session_tz);
        pk_date_utils.set_dst_time_check_on;
    
        RETURN l_return;
    
    END add_days;

    /** 
    * to_timestamp_tz_dst - returns a timestamp with a given timezone or with the institution timezone.
    * Checks get_dst_time_flag function to choose whether to raise an oracle error (ORA-01878) 
    * or to return a valid timestamp (next valid hour for given timestamp). 
    * Solves daylight saving time problems, when given hour doesn't exist.
    *
    * @param      I_LANG                    Prefered language ID for this professional
    * @param      i_timestamp_str           String containing timestamp in i_timestamp_frmt format
    * @param      i_timezone_str            String containing timezone in i_timezone_frmt format
    * @param      i_timestamp_frmt          Format for i_timestamp_str
    * @param      i_timezone_frmt           Format for i_timezone_str
    *
    * ORA-01878 proof
    *
    * @return     timestamp with time zone
    * @author     FO
    * @version    2.5.0.7
    * @since      2009/10/22
    */
    FUNCTION to_timestamp_tz_dst
    (
        i_lang           IN language.id_language%TYPE,
        i_timestamp_str  IN VARCHAR2,
        i_timezone_str   IN VARCHAR2,
        i_timestamp_frmt IN VARCHAR2,
        i_timezone_frmt  IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_error t_error_out;
    
        l_sp            VARCHAR2(010 CHAR);
        l_hour_frmt     VARCHAR2(100 CHAR);
        l_dt_tmp        VARCHAR2(100 CHAR);
        l_flag          BOOLEAN;
        l_loop_count    PLS_INTEGER;
        l_timestamp     TIMESTAMP WITH TIME ZONE;
        l_timestamp_str VARCHAR2(200 CHAR);
        k_null CONSTANT VARCHAR2(0020 CHAR) := '<null>';
        --exc_impossible_date EXCEPTION;
        exc_too_much_loop EXCEPTION;
    
        --PRAGMA EXCEPTION_INIT(exc_impossible_date, -01878);
    
        -- FUNCTION GETS IMMEDIATE VALID HOUR FROM GIVEN DAY
        FUNCTION transform_date(i_value IN VARCHAR2) RETURN VARCHAR2 IS
            l_date   TIMESTAMP;
            l_dt_tmp VARCHAR2(100 CHAR);
        BEGIN
        
            -- ADD 1 HOUR TO TRANSFORM INVALID TIME FOR FIRST VALID TIME SINCE GIVEN TIME
            l_date := trunc(to_date(i_value, i_timestamp_frmt), l_hour_frmt) + INTERVAL '1' hour;
        
            -- CONVERT DATE TO CHAR
            l_dt_tmp := to_char(l_date, i_timestamp_frmt);
        
            RETURN correct_date(l_dt_tmp);
        
        END transform_date;
    BEGIN
        -- INIT SECTION
        g_error         := 'INITIALIZING';
        l_sp            := chr(32);
        l_hour_frmt     := 'HH';
        l_timestamp_str := i_timestamp_str;
    
        -- Check Validation       
        l_flag := get_dst_time_flag; --TRUE; --always true for dst validation in trunc_inst...
    
        <<main_process>>CASE l_flag
            WHEN TRUE THEN
            
                g_error := 'Conversion to_timestamp_tz using as arguments: ';
                g_error := g_error || ' l_timestamp_str = ' || coalesce(l_timestamp_str, k_null);
                g_error := g_error || ' i_timezone_str = ' || coalesce(i_timezone_str, k_null);
                g_error := g_error || ' i_timestamp_frmt = ' || coalesce(i_timestamp_frmt, k_null);
                g_error := g_error || ' i_timezone_frmt = ' || coalesce(i_timezone_frmt, k_null);
            
                pk_alertlog.log_debug(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => 'to_timestamp_tz_dst',
                                      owner           => g_package_owner);
            
                g_error := 'DO NOT VALIDATE ORA-01878';
            
                l_timestamp := to_timestamp_tz(l_timestamp_str || l_sp || i_timezone_str,
                                               i_timestamp_frmt || l_sp || i_timezone_frmt);
            
            WHEN FALSE THEN
                g_error := 'VALIDATE ORA-01878';
                <<validation_loop>>
                WHILE l_flag = FALSE
                LOOP
                
                    l_loop_count := l_loop_count + 1;
                
                    <<validate_time>>
                    BEGIN
                        g_error     := 'TRY';
                        l_timestamp := to_timestamp_tz(l_timestamp_str || l_sp || i_timezone_str,
                                                       i_timestamp_frmt || l_sp || i_timezone_frmt);
                        l_flag      := TRUE;
                    
                    EXCEPTION
                        WHEN exc_impossible_date THEN
                            g_error := 'CATCH';
                            l_flag  := FALSE;
                    END validate_time;
                
                    IF l_flag = FALSE
                    THEN
                        g_error := 'TRANSFORM';
                        -- CONVERT DATE TO CHAR
                        l_timestamp_str := transform_date(l_timestamp_str);
                    ELSE
                        EXIT validation_loop;
                    END IF;
                
                END LOOP validation_loop;
            
        END CASE main_process;
    
        RETURN l_timestamp;
    
    EXCEPTION
        WHEN exc_impossible_date THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'to_timestamp_tz_dst',
                                              o_error    => l_error);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'to_timestamp_tz_dst',
                                              o_error    => l_error);
        
            RETURN NULL;
    END to_timestamp_tz_dst;

    /** 
    * from_tz_dst - returns a timestamp with a given timezone or with the institution timezone.
    * Checks get_dst_time_flag function to choose whether to raise an oracle error (ORA-01878) 
    * or to return a valid timestamp (next valid hour for given timestamp). 
    * Solves daylight saving time problems, when given hour doesn't exist.
    *
    * @param      I_LANG                    Prefered language ID for this professional
    * @param      i_timestamp               Timestamp to convert
    * @param      i_timezone                Timezone where the timestamp is to be considered
    *
    * ORA-01878 proof
    *
    * @return     timestamp with time zone
    * @author     FO
    * @version    2.5.0.7
    * @since      2009/10/22
    */
    FUNCTION from_tz_dst
    (
        i_lang      IN language.id_language%TYPE,
        i_timestamp IN TIMESTAMP,
        i_timezone  IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
    
        l_error t_error_out;
    
        l_sp             VARCHAR2(010 CHAR);
        l_hour_frmt      VARCHAR2(100 CHAR);
        l_dt_tmp         VARCHAR2(100 CHAR);
        l_flag           BOOLEAN;
        l_loop_count     PLS_INTEGER;
        l_timestamp      TIMESTAMP;
        l_timestamp_temp TIMESTAMP WITH TIME ZONE;
    
        --exc_impossible_date EXCEPTION;
        exc_too_much_loop EXCEPTION;
    
        --PRAGMA EXCEPTION_INIT(exc_impossible_date, -01878);
    
        -- FUNCTION GETS IMMEDIATE VALID HOUR FROM GIVEN DAY
        FUNCTION transform_date(i_value IN TIMESTAMP) RETURN TIMESTAMP IS
            l_dt_tmp TIMESTAMP;
        BEGIN
        
            -- ADD 1 HOUR TO TRANSFORM INVALID TIME FOR FIRST VALID TIME SINCE GIVEN TIME
            l_dt_tmp := trunc(i_value, l_hour_frmt) + INTERVAL '1' hour;
        
            RETURN l_dt_tmp;
        
        END transform_date;
    BEGIN
        -- INIT SECTION
        g_error     := 'INITIALIZING';
        l_hour_frmt := 'HH';
        l_timestamp := i_timestamp;
    
        -- Check Validation       
        l_flag := get_dst_time_flag;
    
        <<main_process>>CASE l_flag
            WHEN TRUE THEN
                g_error          := 'DO NOT VALIDATE ORA-01878';
                l_timestamp_temp := from_tz(l_timestamp, i_timezone);
            
            WHEN FALSE THEN
                g_error := 'VALIDATE ORA-01878';
                <<validation_loop>>
                WHILE l_flag = FALSE
                LOOP
                
                    l_loop_count := l_loop_count + 1;
                
                    <<validate_time>>
                    BEGIN
                        g_error          := 'TRY';
                        l_timestamp_temp := from_tz(l_timestamp, i_timezone);
                        l_flag           := TRUE;
                    
                    EXCEPTION
                        WHEN exc_impossible_date THEN
                            g_error := 'CATCH';
                            l_flag  := FALSE;
                    END validate_time;
                
                    IF l_flag = FALSE
                    THEN
                        g_error := 'TRANSFORM';
                        -- CONVERT DATE TO CHAR
                        l_timestamp := transform_date(l_timestamp);
                    ELSE
                        EXIT validation_loop;
                    END IF;
                
                END LOOP validation_loop;
            
        END CASE main_process;
    
        RETURN l_timestamp_temp;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'from_tz_dst',
                                              o_error    => l_error);
        
            RETURN NULL;
        
    END from_tz_dst;

    /**
    * This function returns TRUE if validation of DST time by the database is active. Returns false if DST time is "corrected".
    *
    * @author   Carlos Ferreira
    * @version  1,0
    * @since    2007/10/15
    */
    FUNCTION get_dst_time_flag RETURN BOOLEAN IS
    BEGIN
        RETURN g_validate_error;
    END get_dst_time_flag;

    /**
    * This function returns the cached NLS_CODE for a given language.
    * Private function.
    *
    * @param i_lang                Language identifier.
    *
    * @return NLS_CODE
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/09/03
    */
    FUNCTION get_nls_code(i_lang language.id_language%TYPE) RETURN language.nls_code%TYPE IS
        l_nls_code  language.nls_code%TYPE;
        l_func_name VARCHAR2(32) := 'GET_NLS_CODE';
        l_error     t_error_out;
    BEGIN
        g_error := 'TEST LAST LANGUAGE';
        IF i_lang IS NOT NULL
           AND g_last_language IS NOT NULL
           AND i_lang = g_last_language
        THEN
            l_nls_code := g_last_nls_code;
        ELSIF i_lang IS NULL
        THEN
            l_nls_code := NULL;
        ELSE
            g_error := 'GET NLS_CODE';
            -- Get NLS_CODE
            BEGIN
                SELECT nls_code
                  INTO l_nls_code
                  FROM LANGUAGE
                 WHERE id_language = i_lang;
            EXCEPTION
                WHEN no_data_found THEN
                    l_nls_code := NULL;
            END;
            g_last_nls_code := l_nls_code;
            g_last_language := i_lang;
        END IF;
    
        RETURN l_nls_code;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NLS_CODE',
                                              l_error);
            RETURN NULL;
    END get_nls_code;

    FUNCTION get_elapsed_sysdate
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre a data actual e a data indicada 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg VARCHAR2(50);
        l_error       t_error_out;
    BEGIN
        g_error := 'CALL TO GET_ELAPSED';
        IF NOT get_elapsed_sysdate(i_lang => i_lang, i_date => i_date, o_elapsed => l_elapsed_msg, o_error => l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN correct_date(l_elapsed_msg);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_SYSDATE',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION get_elapsed_sysdate
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre a data actual e a data indicada 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ELAPSED - tempo decorrido 
               O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          CORRECÇÃO: JR 2005/06/16 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
        l_fmt_sssss    VARCHAR2(10 CHAR);
        l_fmt_hh_mi    VARCHAR2(10 CHAR);
        l_msg_019      sys_message.desc_message%TYPE;
        l_msg_020      sys_message.desc_message%TYPE;
        l_tmp_time     VARCHAR2(1000 CHAR);
        l_trc_time     VARCHAR2(1000 CHAR);
        l_mn           VARCHAR2(1 CHAR);
        l_sp           VARCHAR2(1 CHAR);
    BEGIN
    
        g_error := 'CALCULATE L_ELAPSED_TIME';
    
        l_fmt_sssss := 'sssss';
        l_fmt_hh_mi := 'hh24:mi';
        l_mn        := '-';
        l_sp        := chr(32);
        l_msg_019   := pk_message.get_message(i_lang, 'COMMON_M019');
        l_msg_020   := pk_message.get_message(i_lang, 'COMMON_M020');
    
        l_elapsed_time := SYSDATE - i_date;
        g_error        := 'GET L_ELAPSED_MSG';
    
        l_tmp_time := to_char(to_date(lpad(trunc(l_elapsed_time * 24 * 3600), 5, 0), l_fmt_sssss), l_fmt_hh_mi);
        l_trc_time := trunc(l_elapsed_time) || l_sp || l_msg_020;
    
        CASE
            WHEN ((l_elapsed_time >= 0) AND (l_elapsed_time < 1)) THEN
                l_elapsed_msg := l_tmp_time;
            WHEN ((l_elapsed_time >= 1) AND (l_elapsed_time < 2)) THEN
                l_elapsed_msg := '1 ' || l_msg_019;
            WHEN l_elapsed_time >= 2 THEN
                l_elapsed_msg := l_trc_time;
            WHEN ((l_elapsed_time > -1) AND (l_elapsed_time < 0)) THEN
                l_elapsed_msg := l_mn || l_tmp_time;
            WHEN ((l_elapsed_time > -2) AND (l_elapsed_time <= -1)) THEN
                l_elapsed_msg := '-1 ' || l_msg_019;
            WHEN l_elapsed_time <= -2 THEN
                l_elapsed_msg := l_mn || l_trc_time;
        END CASE;
    
        o_elapsed := l_elapsed_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_SYSDATE',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_elapsed_abs
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre a data actual e a data indicada 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg VARCHAR2(50);
        l_error       t_error_out;
    BEGIN
        g_error := 'CALL TO GET_ELAPSED_ABS';
        IF NOT get_elapsed_abs(i_lang => i_lang, i_date => i_date, o_elapsed => l_elapsed_msg, o_error => l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN correct_date(l_elapsed_msg);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION get_elapsed_abs
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre a data actual e a data indicada 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          CORRECÇÃO: JR 2005/06/16 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
    BEGIN
        g_error        := 'CALCULATE L_ELAPSED_TIME';
        l_elapsed_time := SYSDATE - i_date;
        g_error        := 'GET L_ELAPSED_MSG';
        IF ((l_elapsed_time > -1) AND (l_elapsed_time < 1))
        THEN
            l_elapsed_msg := to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time >= 1) AND (l_elapsed_time < 2))
              OR ((l_elapsed_time > -2) AND (l_elapsed_time <= -1))
        THEN
            l_elapsed_msg := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF l_elapsed_time >= 2
              OR l_elapsed_time <= -2
        THEN
            l_elapsed_msg := trunc(abs(l_elapsed_time)) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        END IF;
        o_elapsed := l_elapsed_msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_elapsed
    (
        i_lang    IN language.id_language%TYPE,
        i_date1   IN DATE,
        i_date2   IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre as datas indicadas 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE1 - data  
                  I_DATE2 - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          CORRECÇÃO: JR 2005/06/16 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
    BEGIN
        g_error        := 'CALCULATE L_ELAPSED_TIME';
        l_elapsed_time := i_date2 - i_date1;
        g_error        := 'GET L_ELAPSED_MSG';
        IF ((l_elapsed_time > -1) AND (l_elapsed_time < 1))
        THEN
            l_elapsed_msg := to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time >= 1) AND (l_elapsed_time < 2))
              OR ((l_elapsed_time > -2) AND (l_elapsed_time <= -1))
        THEN
            l_elapsed_msg := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF l_elapsed_time >= 2
              OR l_elapsed_time <= -2
        THEN
            l_elapsed_msg := trunc(abs(l_elapsed_time)) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        END IF;
        o_elapsed := l_elapsed_msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_elapsed
    (
        i_lang  IN language.id_language%TYPE,
        i_date1 IN DATE,
        i_date2 IN DATE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar o tempo decorrido entre as datas indicadas 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE1 - data  
                  I_DATE2 - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/02 
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg VARCHAR2(50);
        l_error       t_error_out;
    BEGIN
        IF NOT get_elapsed(i_lang    => i_lang,
                           i_date1   => i_date1,
                           i_date2   => i_date2,
                           o_elapsed => l_elapsed_msg,
                           o_error   => l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN correct_date(l_elapsed_msg);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION date_char
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data, com ":" entre as horas e os minutos 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/11
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF NOT g_date_hour_format.exists('DATE_HOUR_FORMAT' || '|' || i_inst || '|' || i_soft)
        THEN
            g_date_hour_format('DATE_HOUR_FORMAT' || '|' || i_inst || '|' || i_soft) := pk_sysconfig.get_config('DATE_HOUR_FORMAT',
                                                                                                                i_inst,
                                                                                                                i_soft);
        END IF;
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date,
                                        g_date_hour_format('DATE_HOUR_FORMAT' || '|' || i_inst || '|' || i_soft))); -- HH24:MI"h" DD-Mon-YYYY
        ELSE
            RETURN correct_date(to_char(i_date,
                                        g_date_hour_format('DATE_HOUR_FORMAT' || '|' || i_inst || '|' || i_soft),
                                        'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- HH24:MI"h" DD-Mon-YYYY
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION dt_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/11 
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format)); -- DD-Mon-YYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION dt_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - data  
                                 I_INST - Instituição 
                                 I_SOFT - aplicação 
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2006/01/19 
          ALTERAÇÃO:   
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT', i_inst, i_soft);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format)); -- DD-Mon-YYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION dt_chr_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/11 
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('HOUR_FORMAT', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format)); -- DD-Mon-YYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_HOUR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION dt_chr_date_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/11 
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_HOUR_FORMAT', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format)); -- DD-Mon-YYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_DATE_HOUR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION date_char_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE, --) RETURN VARCHAR2 IS
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/23 
          NOTAS: 
        *********************************************************************************/
        l_error t_error_out;
    
    BEGIN
        g_hour_format := pk_sysconfig.get_config('HOUR_FORMAT', i_inst, i_soft);
        RETURN correct_date(to_char(i_date, g_hour_format)); -- HH24:MI"h" 
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR_HOUR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION trunc_dt_char
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE, --) RETURN VARCHAR2 IS
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - data
                                 I_PROF - profissional  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/23 
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_trunc_dt_format := pk_sysconfig.get_config('TRUNC_DT_FORMAT', i_inst, i_soft);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_trunc_dt_format)); -- DDMonYY
        ELSE
            RETURN correct_date(to_char(i_date, g_trunc_dt_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DDMonYY
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_DT_CHAR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION date_send
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data em string plana 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: JR 2005/06/15 
          NOTAS: formato utilizado para mandar datas ao Flash para ser manipuladas 
        *********************************************************************************/
        l_error t_error_out;
    BEGIN
        g_date_hour_send_format := pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_prof);
        RETURN correct_date(to_char(i_date, g_date_hour_send_format)); -- YYYYMMDDHH24MISS -- 
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data em string plana 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_institution            institution id                   
    * @param i_software               software id 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/04/09
    **********************************************************************************************/
    FUNCTION date_send
    (
        i_lang        IN language.id_language%TYPE,
        i_date        IN DATE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
    BEGIN
        g_date_hour_send_format := pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_institution, i_software);
    
        RETURN correct_date(to_char(i_date, g_date_hour_send_format)); -- YYYYMMDDHH24MISS -- 
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND',
                                              l_error);
            RETURN NULL;
    END;
    --
    --FUNCTION GET_DATE_TODAY RETURN VARCHAR2 IS
    /******************************************************************************
       OBJECTIVO:   Formatação dO SYSDATE em string plana 
     
      CRIAÇÃO: AA 2005/11/18 
      NOTAS: formato utilizado para mandar datas ao Flash para ser manipuladas 
          SS: Não está a ser usada....
    *********************************************************************************/
    /*
    I_PROF PROFISSIONAL;
    BEGIN
    
      I_PROF := PROFISSIONAL(NULL, 2, 1); --------------------------SS: ATENÇÃO: instituição e software estão fixos
      G_DATE_HOUR_SEND_FORMAT := PK_SYSCONFIG.GET_CONFIG('DATE_HOUR_SEND_FORMAT');
      RETURN TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'); -- YYYYMMDDHH24MISS -- 
    
    END;*/

    FUNCTION compare_dates
    (
        i_date1 IN DATE,
        i_date2 IN DATE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar G se I_DATE1 é posterior a I_DATE2 
                  L se I_DATE1 é anterior a I_DATE2 
               E se I_DATE1 é igual a I_DATE2 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE1 - data  
                  I_DATE2 - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/08/06 
          NOTAS: 
        *********************************************************************************/
        l_error t_error_out;
    BEGIN
        IF i_date1 > i_date2
        THEN
            RETURN 'G';
        ELSIF i_date1 < i_date2
        THEN
            RETURN 'L';
        ELSE
            RETURN 'E';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COMPARE_DATES',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION get_elapsed_abs_er(i_date IN DATE) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Função copiada da base de dados do ER
           PARAMETROS:   
          CRIAÇÃO: RB 2006/02/21
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg VARCHAR2(50);
        l_error       t_error_out;
    
    BEGIN
        IF NOT get_elapsed_abs_er(i_date, l_elapsed_msg, l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN correct_date(l_elapsed_msg);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_ER',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION get_elapsed_abs_er
    (
        i_date          IN DATE,
        o_elapsed       OUT VARCHAR2,
        o_error_message OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Função copiada da base de dados do ER
           PARAMETROS:   
          CRIAÇÃO: RB 2006/02/21
          NOTAS: 
        *********************************************************************************/
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
    BEGIN
        l_elapsed_time := SYSDATE - i_date;
        IF ((l_elapsed_time > -1) AND (l_elapsed_time < 1))
        THEN
            l_elapsed_msg := to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time >= 1) AND (l_elapsed_time < 2))
              OR ((l_elapsed_time > -2) AND (l_elapsed_time <= -1))
        THEN
            l_elapsed_msg := '1 ' || g_day;
        ELSIF l_elapsed_time >= 2
              OR l_elapsed_time <= -2
        THEN
            l_elapsed_msg := trunc(abs(l_elapsed_time)) || ' ' || g_days;
        END IF;
        o_elapsed := l_elapsed_msg;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_ER',
                                              o_error_message);
            RETURN FALSE;
    END;

    FUNCTION dt_chr_short
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data, sem os hífens a separar os campos
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: RB 2006/04/11 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format_short := pk_sysconfig.get_config('DATE_FORMAT_SHORT', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format_short)); -- DDMonYYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format_short, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_SHORT',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Converter a data tendo em conta uma unidade de conversão
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids                  
    * @param i_units                  Unidade de conversão  
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/05
    **********************************************************************************************/
    FUNCTION get_conversion_date
    (
        i_lang  IN language.id_language%TYPE,
        i_date  IN DATE,
        i_prof  IN profissional,
        i_units IN triage_units.conversion%TYPE
    ) RETURN VARCHAR2 IS
        l_elapsed_msg  VARCHAR2(50 CHAR);
        l_elapsed_time NUMBER;
        l_sysdate      VARCHAR2(200);
        l_error        t_error_out;
    BEGIN
        g_date_hour_send_format := pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_prof);
        l_elapsed_time          := SYSDATE - i_date;
        --
        IF i_units = g_min
        THEN
            -- Minutos
            IF ((l_elapsed_time > -1) AND (l_elapsed_time < 1))
            THEN
                l_elapsed_msg := trunc(abs(l_elapsed_time) * 1440);
            ELSE
                l_elapsed_msg := trunc(abs(l_elapsed_time)) * 1440;
            END IF;
        END IF;
    
        RETURN correct_date(l_elapsed_msg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONVERSION_DATE',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids                  
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/10/07
    **********************************************************************************************/
    FUNCTION dt_hour_chr_short
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF i_lang = 2
        THEN
            g_date_format := pk_sysconfig.get_config('DATE_HOUR_FORMAT_SHORT', i_prof);
        ELSE
            g_date_format := pk_sysconfig.get_config('DATE_MASK02', i_prof);
        END IF;
        --
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_HOUR_CHR_SHORT',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids                  
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/10/07
    **********************************************************************************************/
    FUNCTION date_time_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF i_lang = 2
        THEN
            g_date_format := pk_sysconfig.get_config('DATE_TIME_FORMAT', i_prof);
        ELSE
            g_date_format := pk_sysconfig.get_config('DATE_MASK03', i_prof);
        END IF;
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_institution            institution id                   
    * @param i_software               software id 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/05/14
    **********************************************************************************************/
    FUNCTION date_time_chr
    (
        i_lang        IN language.id_language%TYPE,
        i_date        IN DATE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF i_lang = 2
        THEN
            g_date_format := pk_sysconfig.get_config('DATE_TIME_FORMAT', i_institution, i_software);
        ELSE
            g_date_format := pk_sysconfig.get_config('DATE_MASK03', i_institution, i_software);
        END IF;
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/10/07
    **********************************************************************************************/
    FUNCTION date_chr_extend
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF i_lang = 2
        THEN
            g_date_format := pk_sysconfig.get_config('DATE_FORMAT_EXTEND_EN', i_prof);
        ELSE
            g_date_format := pk_sysconfig.get_config('DATE_FORMAT_EXTEND', i_prof);
        END IF;
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_EXTEND',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION date_chr_space
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - Data  
               Saida: O_ERROR - Erro 
         
          CRIAÇÃO: SS 2006/11/14   
          NOTAS: 
        *********************************************************************************/
        --
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT_SPACE', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION date_chr_space
    (
        i_lang        IN language.id_language%TYPE,
        i_date        IN DATE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 'DD Mon, yyyy'
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - Data  
               Saida: O_ERROR - Erro 
         
          CRIAÇÃO: ASM 2007/05/24
          NOTAS: 
        *********************************************************************************/
        --
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_SPACE_FORMAT', i_institution, i_software);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/10/09
    **********************************************************************************************/
    FUNCTION date_hour_chr_extend
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        IF i_lang = 2
        THEN
            g_date_format := pk_sysconfig.get_config('DATE_HOUR_FORMAT_EXTEND', i_prof);
        ELSE
            g_date_format := pk_sysconfig.get_config('DATE_MASK01', i_prof);
        END IF;
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR_EXTEND',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/10/07
    **********************************************************************************************/
    FUNCTION date_chr_short_read
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT_SHORT_READ', i_prof);
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_institution            institution id                   
    * @param i_software               software id 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/05/07
    **********************************************************************************************/
    FUNCTION date_chr_short_read
    (
        i_lang        IN language.id_language%TYPE,
        i_date        IN DATE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT_SHORT_READ', i_institution, i_software);
    
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Retornar o tempo decorrido entre a data actual e a data indicada  
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_separator              Limitador entre dias e horas                  
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/11/23
    **********************************************************************************************/
    FUNCTION get_elapsed_date
    (
        i_lang      IN language.id_language%TYPE,
        i_date      IN DATE,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_elapsed_msg VARCHAR2(50);
        l_error       t_error_out;
    BEGIN
        g_error := 'CALL get_elapsed_date';
        IF NOT get_elapsed_date(i_lang      => i_lang,
                                i_date      => i_date,
                                i_separator => i_separator,
                                o_elapsed   => l_elapsed_msg,
                                o_error     => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN correct_date(l_elapsed_msg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_DATE',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Retornar o tempo decorrido entre a data actual e a data indicada  
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_separator              Limitador entre dias e horas                   
    * @param o_elapsed                Devolve o tempo decorrido entre a data actual e a data indicada   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/11/23
    **********************************************************************************************/
    FUNCTION get_elapsed_date
    (
        i_lang      IN language.id_language%TYPE,
        i_date      IN DATE,
        i_separator IN VARCHAR2,
        o_elapsed   OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
    BEGIN
        g_error        := 'CALCULATE L_ELAPSED_TIME';
        l_elapsed_time := SYSDATE - i_date;
        --
        g_error := 'GET L_ELAPSED_MSG';
        IF ((l_elapsed_time >= 0) AND (l_elapsed_time < 1))
        THEN
            l_elapsed_msg := to_char(to_date(lpad(trunc(l_elapsed_time * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time >= 1) AND (l_elapsed_time < 2))
        THEN
            l_elapsed_msg := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019') || ' ' || i_separator || ' ' ||
                             to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF l_elapsed_time >= 2
        THEN
            l_elapsed_msg := trunc(l_elapsed_time) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020') || ' ' ||
                             i_separator || ' ' ||
                             to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time > -1) AND (l_elapsed_time < 0))
        THEN
            l_elapsed_msg := '-' ||
                             to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((l_elapsed_time > -2) AND (l_elapsed_time <= -1))
        THEN
            l_elapsed_msg := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M019') || ' ' || i_separator || ' ' ||
                             to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF l_elapsed_time <= -2
        THEN
            l_elapsed_msg := '-' || trunc(l_elapsed_time) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020') || ' ' ||
                             i_separator || ' ' ||
                             to_char(to_date(lpad(trunc(abs(l_elapsed_time) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        END IF;
        --
        o_elapsed := l_elapsed_msg;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_DATE',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION dt_year_day_hour_chr_short
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - Data  
               Saida: O_ERROR - Erro 
         
          CRIAÇÃO: JS 2006/12/16   
          NOTAS: 
        *********************************************************************************/
        --
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT_YEAR_DAY_HOUR_SHORT', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_YEAR_DAY_HOUR_CHR_SHORT',
                                              l_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Formatação da data 
    *
    * @param i_lang                   the id language
    * @param i_date                   date
    * @param i_prof                   professional, software and institution ids 
    *
    * @return                         description
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/19 
    **********************************************************************************************/
    FUNCTION date_hour_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
    
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_HOUR', i_prof);
        --
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
    
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format));
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR',
                                              l_error);
            RETURN NULL;
    END;

    FUNCTION get_elapsed_minutes_abs(i_date IN DATE) RETURN NUMBER IS
    BEGIN
        RETURN round(abs(i_date - SYSDATE) * 24 * 60);
    END;

    FUNCTION dt_chr_month
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Formatação da data no formato "MONTH YYYY" 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                I_DATE - data  
               Saida:   O_ERROR - erro 
         
          CRIAÇÃO: CRS 2005/03/11 
          ALTERAÇÃO: JR 2005/06/16 - incluído suporte multi-idioma  
          NOTAS: 
        *********************************************************************************/
        CURSOR c_get_nls_code IS
            SELECT nls_code
              FROM LANGUAGE
             WHERE id_language = i_lang;
        l_nls_code language.nls_code%TYPE := NULL;
        l_error    t_error_out;
    BEGIN
        g_date_format := pk_sysconfig.get_config('DATE_FORMAT_MONTH', i_prof);
        OPEN c_get_nls_code;
        FETCH c_get_nls_code
            INTO l_nls_code;
        CLOSE c_get_nls_code;
        IF l_nls_code IS NULL
        THEN
            RETURN correct_date(to_char(i_date, g_date_format)); -- DD-Mon-YYYY 
        ELSE
            RETURN correct_date(to_char(i_date, g_date_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''')); -- DD-Mon-YYYY 
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_MONTH',
                                              l_error);
            RETURN NULL;
    END;

    /** 
    *  Get_timestamp_anytimezone criteria
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    *
    * @return     varchar2
    * @author     SB
    * @version    0.1
    * @since      2007/07/23
    */
    FUNCTION get_timestamp_str_base
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        i_timezone  IN VARCHAR2,
        i_format    IN VARCHAR2 DEFAULT g_dateformat
    ) RETURN VARCHAR2 IS
        l_timezone timezone_region.timezone_region%TYPE;
        l_return   VARCHAR2(1000 CHAR);
        l_error    t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone to use
        IF NOT get_timezone(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_timezone => i_timezone,
                            o_timezone => l_timezone,
                            o_error    => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET_TIMESTAMP';
        -- Get string
        l_return := to_char(i_timestamp at TIME ZONE l_timezone, i_format);
    
        RETURN correct_date(l_return);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_STR',
                                              l_error);
        
            RETURN NULL;
    END get_timestamp_str_base;

    --    FUNCTION get_timestamp_str_with_timezone
    FUNCTION get_timestamp_str_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        i_timezone  IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN get_timestamp_str_base(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_timestamp => i_timestamp,
                                      i_timezone  => i_timezone,
                                      i_format    => g_dateformat_tzh_tzm);
    
    END get_timestamp_str_tstz;
    /** 
    *  Get_timestamp_anytimezone criteria
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    *
    * @return     varchar2
    * @author     SB
    * @version    0.1
    * @since      2007/07/23
    */
    FUNCTION get_timestamp_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        i_timezone  IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN get_timestamp_str_base(i_lang      => i_lang,
                                      i_prof      => i_prof,
                                      i_timestamp => i_timestamp,
                                      i_timezone  => i_timezone,
                                      i_format    => g_dateformat);
    
    END get_timestamp_str;

    /** 
    *  get_string_tstz - String to TSTZ
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    *
    * ORA-01878 proof
    *
    * @return     varchar2
    * @author     SB
    * @version    0.1
    * @since      2007/07/23
    */
    FUNCTION get_string_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN VARCHAR2 DEFAULT to_char(current_timestamp, g_dateformat),
        i_timezone  IN VARCHAR2,
        i_mask      IN VARCHAR2 DEFAULT g_dateformat
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_return TIMESTAMP WITH TIME ZONE;
        l_error  t_error_out;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ';
        -- Get timestamp
        IF i_timestamp IS NOT NULL
           AND get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp,
                               i_timezone  => i_timezone,
                               i_mask      => i_mask,
                               o_timestamp => l_return,
                               o_error     => l_error)
        THEN
            RETURN l_return;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN exc_impossible_date THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_string_tstz 1',
                                              o_error    => l_error);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_TSTZ 1',
                                              l_error);
            l_return := NULL;
            RETURN l_return;
    END get_string_tstz;

    /** 
    *  get_string_tstz - String to TSTZ. Checks get_dst_time_flag function to choose 
    * whether to raise an oracle error (ORA-01878) or to return a valid timestamp (next valid hour for given timestamp). 
    * Solves daylight saving time problems, when given hour doesn't exist.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    * @param      O_TIMESTAMP                  Output timestmap
    * @param      O_ERROR                      error
    *
    * ORA-01878 proof
    *
    * @return     varchar2
    * @author     SB
    * @version    0.1
    * @since      2007/07/23
    */
    FUNCTION get_string_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN VARCHAR2 DEFAULT to_char(current_timestamp, g_dateformat),
        i_timezone  IN VARCHAR2,
        i_mask      IN VARCHAR2 DEFAULT g_dateformat,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
    
        l_timezone  timezone_region.timezone_region%TYPE;
        l_tzr       VARCHAR2(100 CHAR);
        l_full_frmt VARCHAR2(100 CHAR);
        l_hour_frmt VARCHAR2(100 CHAR);
        l_dt_tmp    VARCHAR2(100 CHAR);
    
    BEGIN
    
        IF i_timestamp IS NOT NULL
        THEN
        
            g_error := 'CALL GET_TIMEZONE';
            -- Get timezone to use
            IF NOT get_timezone(i_lang     => i_lang,
                                i_prof     => i_prof,
                                i_timezone => i_timezone,
                                o_timezone => l_timezone,
                                o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- *****************************************************************
            -- INIT SECTION
            l_full_frmt := i_mask;
            l_tzr       := 'TZR';
        
            l_timestamp := to_timestamp_tz_dst(i_lang           => i_lang,
                                               i_timestamp_str  => i_timestamp,
                                               i_timezone_str   => l_timezone,
                                               i_timestamp_frmt => l_full_frmt,
                                               i_timezone_frmt  => l_tzr);
        
            o_timestamp := l_timestamp;
        
        ELSE
            o_timestamp := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN exc_impossible_date THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_string_tstz 2',
                                              o_error    => o_error);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_TSTZ 2',
                                              o_error);
        
            o_timestamp := NULL;
        
            RETURN FALSE;
        
    END get_string_tstz;

    /*******************************************************************************************************************************************
    * SET_DST_TIME_CHECK              Procedure that set validation for Daylight saving time on or off
    * 
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2009/10/14
    *******************************************************************************************************************************************/
    PROCEDURE set_dst_time_check_on IS
    BEGIN
        g_validate_error := TRUE;
    END set_dst_time_check_on;
    PROCEDURE set_dst_time_check_off IS
    BEGIN
        g_validate_error := FALSE;
    END set_dst_time_check_off;

    /*******************************************************************************************************************************************
    * GET_STRING_TSTZ_STR             Function that returns timestamp with TZH from an DATE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param ACTUAL_DATE              Date to be converted
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    *
    * ORA-01878 proof
    * 
    * @return                         Returns DATE IN TIMESTAMP FORMAT
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/14
    *******************************************************************************************************************************************/
    FUNCTION get_string_tstz_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        actual_date IN DATE
    ) RETURN VARCHAR2 IS
        l_dt_creation_tstz TIMESTAMP WITH TIME ZONE;
        o_error            t_error_out;
    BEGIN
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => to_char(actual_date, pk_alert_constant.g_dt_yyyymmddhh24miss),
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_creation_tstz,
                                             o_error     => o_error)
        THEN
            g_error := 'ERROR_CONVERTING_INTO_TIMESTAMP';
            RETURN g_error;
        END IF;
        --
        RETURN correct_date(to_char(l_dt_creation_tstz, pk_alert_constant.g_dt_tzh));
    END get_string_tstz_str;

    /** 
    *  Get_timestamp_anytimezone criteria
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMESTAMP_STR              Timestamp wth timezone to input passed as string
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    
    * @param      O_TIMESTAMP                  Timestamp variable output
    * @param      O_TIMESTAMP_STR              Timestamp variable ouput as string
    * @param      O_ERROR                      error
    *
    * ORA-01878 proof
    * 
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/23
    */
    FUNCTION at_time_zone
    (
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timezone  IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        SELECT i_timestamp at TIME ZONE (SELECT i_timezone
                                           FROM dual)
          INTO l_timestamp
          FROM dual;
    
        RETURN l_timestamp;
    
    END at_time_zone;

    -- *********************************************
    FUNCTION at_time_zone
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timezone  IN VARCHAR2 DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_timezone  VARCHAR2(1000 CHAR);
    BEGIN
    
        IF i_timezone IS NULL
        THEN
            l_timezone := get_timezone_base(i_prof => i_prof, i_timezone => i_timezone);
        END IF;
    
        l_timestamp := at_time_zone(i_timestamp => i_timestamp, i_timezone => l_timezone);
    
        RETURN l_timestamp;
    
    END at_time_zone;

    -- *********************************************
    FUNCTION get_timestamp_anytimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_timestamp     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_timestamp_str IN VARCHAR2 DEFAULT to_char(current_timestamp, g_dateformat),
        i_timezone      IN VARCHAR2,
        o_timestamp     OUT TIMESTAMP WITH TIME ZONE,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_timezone          timezone_region.timezone_region%TYPE;
        l_current_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_timestamp         TIMESTAMP WITH LOCAL TIME ZONE;
        l_timestamp_str     VARCHAR2(200 CHAR);
    BEGIN
    
        l_current_timestamp := current_timestamp;
        l_timestamp         := nvl(i_timestamp, l_current_timestamp);
        l_timestamp_str     := nvl(i_timestamp_str, to_char(l_current_timestamp, g_dateformat));
    
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone to use
        IF NOT get_timezone(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_timezone => i_timezone,
                            o_timezone => l_timezone,
                            o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET_TIMESTAMP';
        pk_alertlog.log_debug(text            => g_error,
                              object_name     => g_package_name,
                              sub_object_name => 'get_timestamp_anytimezone',
                              owner           => g_package_owner);
    
        IF i_timestamp IS NULL
        THEN
            o_timestamp := get_string_tstz(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_timestamp => l_timestamp_str,
                                           i_timezone  => l_timezone);
        
            IF o_timestamp IS NULL
            THEN
                --o_timestamp := l_current_timestamp at TIME ZONE(l_timezone);
                o_timestamp := at_time_zone(i_timestamp => l_current_timestamp, i_timezone => l_timezone);
            
            END IF;
        ELSE
            --o_timestamp := l_timestamp at TIME ZONE(l_timezone);
            o_timestamp := at_time_zone(i_timestamp => l_timestamp, i_timezone => l_timezone);
        
        END IF;
    
        IF i_timestamp_str IS NULL
        THEN
            --o_timestamp_str := to_char(l_timestamp at TIME ZONE(l_timezone), g_dateformat);
            o_timestamp_str := to_char(at_time_zone(i_timestamp => l_timestamp, i_timezone => l_timezone), g_dateformat);
        
        ELSE
            o_timestamp_str := to_char(get_string_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => l_timestamp_str,
                                                       i_timezone  => l_timezone),
                                       g_dateformat);
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
                                              'GET_TIMESTAMP_ANYTIMEZONE',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_anytimezone;

    /** 
    * Converts a timestamp with local time zone to a timestamp with the time zone of the professional's institution.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_INST                       Institution
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      O_TIMESTAMP                  Timestamp variable output
    * @param      O_ERROR                      error
    *
    * ORA-01878 proof
    * 
    * @return     boolean
    * @author     Nuno Guerreiro
    * @version    0.1
    * @since      2007/08/08
    */
    FUNCTION get_timestamp_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timezone  IN VARCHAR2,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(64 CHAR) := 'GET_TIMESTAMP_INSTTIMEZONE';
        l_timezone      timezone_region.timezone_region%TYPE;
        l_timestamp_str VARCHAR2(200 CHAR);
    BEGIN
    
        IF i_timestamp IS NULL
        THEN
            o_timestamp := NULL;
        ELSE
            IF NOT get_timestamp_anytimezone(i_lang          => i_lang,
                                             i_prof          => profissional(NULL, i_inst, NULL),
                                             i_timestamp     => i_timestamp,
                                             i_timezone      => i_timezone,
                                             o_timestamp     => o_timestamp,
                                             o_timestamp_str => l_timestamp_str,
                                             o_error         => o_error)
            THEN
                RETURN FALSE;
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
                                              'GET_TIMESTAMP_INSTTIMEZONE',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_insttimezone;

    FUNCTION get_timestamp_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(64 CHAR) := 'GET_TIMESTAMP_INSTTIMEZONE(6)';
        l_timezone      timezone_region.timezone_region%TYPE;
        l_timestamp_str VARCHAR2(200 CHAR);
    BEGIN
    
        RETURN pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                        i_inst      => i_inst,
                                                        i_timestamp => i_timestamp,
                                                        i_timezone  => NULL,
                                                        o_timestamp => o_timestamp,
                                                        o_error     => o_error);
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
    END get_timestamp_insttimezone;

    /** 
    * Converts a date from flash layer to a timestamp with the time zone of the professional's institution.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_INST                       Institution
    * @param      I_DATE                       Date from user's input
    *
    * ORA-01878 proof
    * 
    * @return     timestamp with time zone
    * @author     Fábio Oliveira
    * @version    0.1
    * @since      2009/01/23
    */
    FUNCTION get_timestamp_insttimezone
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_timezone timezone_region.timezone_region%TYPE;
        l_error    t_error_out;
        l_ret      BOOLEAN;
    
        l_hhmiss      VARCHAR2(9 CHAR) := ' 00:00:00';
        l_hhmiss_mask VARCHAR2(11 CHAR) := ' HH24:MI:SS';
    BEGIN
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone to use
        IF NOT get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_date || l_hhmiss,
                               i_timezone  => l_timezone,
                               i_mask      => 'DD-MM-YYYY' || l_hhmiss_mask);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END;

    /** 
    * Converts a timestamp with local time zone to a timestamp with the time zone of the professional's institution.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_INST                       Institution
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input        
    *
    * @return     TIMESTAMP WITH TIME ZONE
    * @author     Sofia Mendes
    * @version    2.5.0.5
    * @since      2009/07/22
    */
    FUNCTION get_timestamp_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_func_name VARCHAR2(64) := 'GET_TIMESTAMP_INSTTIMEZONE';
        l_timezone  timezone_region.timezone_region%TYPE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone 
        l_timezone := get_timezone(i_lang => i_lang, i_prof => profissional(NULL, i_inst, NULL));
    
        g_error := 'GET_TIMESTAMP';
        -- Get timestamp  
        RETURN i_timestamp at TIME ZONE l_timezone;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END get_timestamp_insttimezone;

    /*
    * Calculates the difference between two timestamps.
    * 
    * @param i_lang             Language identifier.
    * @param i_timestamp_1      Timestamp
    * @param i_timestamp_2      Timestamp
    * @param o_days_diff        Difference between the two timestamps (in days)
    * @param o_error            Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/02
    */
    FUNCTION get_timestamp_diff
    (
        i_lang        IN language.id_language%TYPE,
        i_timestamp_1 IN TIMESTAMP WITH TIME ZONE,
        i_timestamp_2 IN TIMESTAMP WITH TIME ZONE,
        o_days_diff   OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_TIMESTAMP_DIFF(1)';
        l_days      NUMBER;
        l_hours     NUMBER;
        l_minutes   NUMBER;
        l_seconds   NUMBER;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF_SEP';
        -- Get difference
        IF NOT get_timestamp_diff_sep(i_lang        => i_lang,
                                      i_timestamp_1 => i_timestamp_1,
                                      i_timestamp_2 => i_timestamp_2,
                                      o_days        => l_days,
                                      o_hours       => l_hours,
                                      o_minutes     => l_minutes,
                                      o_seconds     => l_seconds,
                                      o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        o_days_diff := l_days + l_hours / 24 + l_minutes / 1440 + l_seconds / 86400;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_DIFF',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_diff;

    /*
    * Calculates the difference between two timestamps.
    * 
    * @param i_timestamp_1      Timestamp
    * @param i_timestamp_2      Timestamp
    * 
    * @return Difference (in days).
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/02
    */
    FUNCTION get_timestamp_diff
    (
        i_timestamp_1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timestamp_2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER DETERMINISTIC IS
        l_func_name VARCHAR2(64) := 'GET_TIMESTAMP_DIFF(2)';
        l_diff      NUMBER := NULL;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Calculate difference
        IF NOT get_timestamp_diff(i_lang        => NULL,
                                  i_timestamp_1 => i_timestamp_1,
                                  i_timestamp_2 => i_timestamp_2,
                                  o_days_diff   => l_diff,
                                  o_error       => l_error)
        THEN
            l_diff := NULL;
        END IF;
    
        RETURN l_diff;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_DIFF',
                                              l_error);
            RETURN NULL;
    END get_timestamp_diff;

    /*
    * Calculates the number of days, hours, minutes and seconds between two timestamps.
    * 
    * @param i_lang             Language identifier.
    * @param i_timestamp_1      Timestamp
    * @param i_timestamp_2      Timestamp
    * @param o_days             Number of days (integer)
    * @param o_hours            Number of hours (integer)
    * @param o_minutes          Number of minutes (integer)
    * @param o_seconds          Number of seconds (integer)
    * @param o_error            Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/02
    */
    FUNCTION get_timestamp_diff_sep
    (
        i_lang        IN language.id_language%TYPE,
        i_timestamp_1 IN TIMESTAMP WITH TIME ZONE,
        i_timestamp_2 IN TIMESTAMP WITH TIME ZONE,
        o_days        OUT NUMBER,
        o_hours       OUT NUMBER,
        o_minutes     OUT NUMBER,
        o_seconds     OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_TIMESTAMP_DIFF_SEP';
        l_timestamp INTERVAL DAY(6) TO SECOND;
    BEGIN
        g_error := 'GET DIFFERENCE';
        /*SELECT extract(DAY FROM(i_timestamp_1 - i_timestamp_2)),
             extract(hour FROM(i_timestamp_1 - i_timestamp_2)),
             extract(minute FROM(i_timestamp_1 - i_timestamp_2)),
             extract(SECOND FROM(i_timestamp_1 - i_timestamp_2))
        INTO o_days, o_hours, o_minutes, o_seconds
        FROM dual;*/
    
        -- modified by Fábio Oliveira 11/06/2008
        l_timestamp := (i_timestamp_1 - i_timestamp_2);
        o_days      := extract(DAY FROM(l_timestamp));
        o_hours     := extract(hour FROM(l_timestamp));
        o_minutes   := extract(minute FROM(l_timestamp));
        o_seconds   := extract(SECOND FROM(l_timestamp));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_DIFF_SEP',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_diff_sep;

    /*
    * Compares two timestamps.
    * 
    * @param i_prof               Professional
    * @param i_timestamp1         Timestamp
    * @param i_timestamp2         Timestamp
    * 
    * @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION compare_dates_tsz
    (
        i_prof  IN profissional,
        i_date1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'COMPARE_DATES_TSZ';
        l_date1     TIMESTAMP WITH TIME ZONE;
        l_date2     TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CONVERT DATE1';
        -- Convert date1
        IF NOT get_timestamp_insttimezone(i_lang      => NULL,
                                          i_inst      => i_prof.institution,
                                          i_timestamp => i_date1,
                                          o_timestamp => l_date1,
                                          o_error     => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CONVERT DATE2';
        -- Convert date2
        IF NOT get_timestamp_insttimezone(i_lang      => NULL,
                                          i_inst      => i_prof.institution,
                                          i_timestamp => i_date2,
                                          o_timestamp => l_date2,
                                          o_error     => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'COMPARE TIMESTAMPS';
        IF l_date1 > l_date2
        THEN
            RETURN 'G';
        ELSIF l_date1 < l_date2
        THEN
            RETURN 'L';
        ELSE
            RETURN 'E';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COMPARE_DATES_TSZ',
                                              l_error);
            RETURN NULL;
    END compare_dates_tsz;

    /*
    * Compares two timestamps.
    * 
    * @param i_timestamp1         Timestamp
    * @param i_timestamp2         Timestamp
    * 
    * @return 'G' if i_timestamp1 is more recent than i_timestamp2, 'E' if they are equal, 'L' otherwise 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION compare_dates_str
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_timestamp1_str IN VARCHAR2,
        i_timezone_1     IN VARCHAR2 DEFAULT NULL,
        i_timestamp2_str IN VARCHAR2,
        i_timezone_2     IN VARCHAR2 DEFAULT NULL,
        o_result         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'COMPARE_DATES_STR';
        l_timestamp_1 TIMESTAMP WITH TIME ZONE;
        l_timestamp_2 TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'GET TIMESTAMP1';
        -- Convert timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp1_str,
                               i_timezone  => i_timezone_1,
                               o_timestamp => l_timestamp_1,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET TIMESTAMP2';
        -- Convert timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp2_str,
                               i_timezone  => i_timezone_2,
                               o_timestamp => l_timestamp_2,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error  := 'CALL COMPARE_DATES_TSZ';
        o_result := compare_dates_tsz(i_prof, l_timestamp_1, l_timestamp_2);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COMPARE_DATES_STR',
                                              o_error);
            RETURN FALSE;
    END compare_dates_str;

    /*
    * Returns a timestamp formatted using i_format and the language's NLS_CODE.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_format Format
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_common
    (
        i_lang   IN language.id_language%TYPE,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format IN VARCHAR2,
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name           VARCHAR2(200) := 'DATE_COMMON';
        l_nls_code            language.nls_code%TYPE := NULL;
        l_date                TIMESTAMP WITH TIME ZONE;
        l_error               t_error_out;
        l_formatted_timestamp VARCHAR2(4000);
    BEGIN
        g_error := 'GET FORMAT FROM sys_config';
        -- Get date format
        IF NOT g_date_hour_format.exists(i_format || '|' || i_inst || '|' || i_soft)
        THEN
            g_date_hour_format(i_format || '|' || i_inst || '|' || i_soft) := pk_sysconfig.get_config(i_format,
                                                                                                      i_inst,
                                                                                                      i_soft);
        END IF;
    
        g_error := 'CALL TO_CHAR_INSTTIMEZONE';
        -- Format timestamp
        IF to_char_insttimezone(i_lang      => i_lang,
                                i_prof      => profissional(NULL, i_inst, i_soft),
                                i_timestamp => i_date,
                                i_mask      => g_date_hour_format(i_format || '|' || i_inst || '|' || i_soft),
                                o_string    => l_formatted_timestamp,
                                o_error     => l_error)
        THEN
            RETURN correct_date(l_formatted_timestamp);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_COMMON',
                                              l_error);
            RETURN NULL;
    END date_common;

    /**********************************************************************************************
    * Returns the year (or current year) on the format YYYY
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_timestamp                Timestamp with local timezone
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Joao Martins
    * @version                          1.0
    * @since                            2008/07/09
    **********************************************************************************************/
    FUNCTION get_year
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
        -- nothing to declare
    BEGIN
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_timestamp,
                           i_format => 'DATE_YEAR',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    END;

    /**********************************************************************************************
    * Returns the name of the month
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_timestamp                Timestamp with local timezone
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Joao Martins
    * @version                          1.0
    * @since                            2008/07/09
    **********************************************************************************************/
    FUNCTION get_month
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
	
		-- code implemented because java injects null, default value wont work.
		if i_timestamp is null
			l_timestamp := current_timestamp;
		else
			l_timestamp := i_timestamp;
		end if;
	
        RETURN date_common(i_lang   => i_lang,
                           i_date   => l_timestamp,
                           i_format => 'DATE_MONTH',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    END;

    /**********************************************************************************************
    * Returns the month and day on the format Mon DD
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_timestamp                Timestamp with local timezone
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Joao Martins
    * @version                          1.0
    * @since                            2008/07/09
    **********************************************************************************************/
    FUNCTION get_month_day
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        -- nothing to declare
    BEGIN
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_timestamp,
                           i_format => 'DATE_MONTH_DAY',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    END;

    /**********************************************************************************************
    * Returns the hour on the short format HH24:Mi
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_timestamp                Timestamp with local timezone
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Joao Martins
    * @version                          1.0
    * @since                            2008/07/09
    **********************************************************************************************/
    FUNCTION get_hour_short
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        -- nothing to declare
    BEGIN
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_timestamp,
                           i_format => 'DATE_TIME_SHORT',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    END;

    /*
    * Formats a timestamp using DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro (CRS)
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_char_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHAR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_HOUR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR_TSZ',
                                              l_error);
            RETURN NULL;
    END date_char_tsz;

    /*
    * Formats a timestamp using DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp (string)
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro (CRS)
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_char_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHAR_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHAR_TSZ';
            RETURN date_char_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR_STR',
                                              l_error);
            RETURN NULL;
    END date_char_str;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    * 
    * @author CRS
    * @version alpha
    * @since 2005/03/23
    */
    FUNCTION date_char_hour_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHAR_HOUR_TSZ(1)';
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'HOUR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR_HOUR_TSZ',
                                              l_error);
            RETURN NULL;
    END date_char_hour_tsz;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp (string)
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_char_hour_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHAR_HOUR_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHAR_HOUR_TSZ';
            RETURN date_char_hour_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHAR_HOUR_STR',
                                              l_error);
            RETURN NULL;
    END date_char_hour_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_EXTEND_EN (English) or DATE_FORMAT_EXTEND (others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro (Emília Taborda)
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_extend_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(32) := 'DATE_CHR_EXTEND_TSZ(1)';
        l_date_format VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        g_error := 'GET FORMAT';
        -- Get date format
        IF i_lang = g_english_lang
        THEN
            l_date_format := 'DATE_FORMAT_EXTEND_EN';
        ELSE
            l_date_format := 'DATE_FORMAT_EXTEND';
        END IF;
    
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => l_date_format,
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_EXTEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_chr_extend_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_EXTEND_EN (English) or DATE_FORMAT_EXTEND (others) parameters.
    * 
    * @param i_lang            Language identifier.
    * @param i_date            Timestamp
    * @param i_prof            Professional
    * @param i_timezone        Timezone
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_extend_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHAR_EXTEND_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHAR_EXTEND_TSZ';
            RETURN date_chr_extend_tsz(i_lang => i_lang, i_date => l_timestamp, i_prof => i_prof);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_EXTEND_STR',
                                              l_error);
            RETURN NULL;
    END date_chr_extend_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT_READ parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_short_read_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHR_SHORT_READ_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_SHORT_READ',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ_TSZ',
                                              l_error);
            RETURN NULL;
    END date_chr_short_read_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT_READ parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    * @param i_timezone  Timezone
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_short_read_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHAR_SHORT_READ_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHR_SHORT_READ_TSZ';
            RETURN date_chr_short_read_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ_STR',
                                              l_error);
            RETURN NULL;
    END date_chr_short_read_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT_READ parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_short_read_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHR_SHORT_READ_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_CHR_SHORT_READ_TSZ';
        -- Format date
        RETURN date_chr_short_read_tsz(i_lang => i_lang,
                                       i_date => i_date,
                                       i_inst => i_prof.institution,
                                       i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ_TSZ',
                                              l_error);
            RETURN NULL;
    END date_chr_short_read_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT_READ parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_prof      Professional
    * @param i_timezone  Timezone
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_short_read_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHAR_SHORT_READ_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHR_SHORT_READ_TSZ';
            -- Format timestamp
            RETURN date_chr_short_read_tsz(i_lang => i_lang,
                                           i_date => l_timestamp,
                                           i_inst => i_prof.institution,
                                           i_soft => i_prof.software);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SHORT_READ_STR',
                                              l_error);
            RETURN NULL;
    END date_chr_short_read_str;

    /*
    * Formats a timestamp according to DATE_SPACE_FORMAT parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_space_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHR_SPACE_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_SPACE_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE_TSZ',
                                              l_error);
            RETURN NULL;
    END date_chr_space_tsz;

    /*
    * Formats a timestamp according to DATE_SPACE_FORMAT parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    * @param i_timezone  Timezone
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_space_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHR_SPACE_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_CHR_SPACE_TSZ';
            -- Format date
            RETURN date_chr_space_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE_STR',
                                              l_error);
            RETURN NULL;
    END date_chr_space_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_SPACE parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_prof      Professional
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_space_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_CHR_SPACE_TSZ(3)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_SPACE',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE_TSZ',
                                              l_error);
            RETURN NULL;
    END date_chr_space_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_SPACE parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_prof      Professional
    * @param i_timezone  Timezone
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_chr_space_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_CHR_SPACE_STR(4)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
        
            g_error := 'CALL DATE_CHR_SPACE_TSZ';
            -- Format date
            RETURN date_chr_space_tsz(i_lang => i_lang, i_date => l_timestamp, i_prof => i_prof);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_CHR_SPACE_STR',
                                              l_error);
            RETURN NULL;
    END date_chr_space_str;

    /*
    * Formats a timestamp according to DATE_HOUR parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_prof      Professional
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_hour_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_HOUR_CHR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_HOUR',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END date_hour_chr_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_prof      Professional
    * @param i_timezone  Timezone
    *
    * @return Formatted timestamp
    * 
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_hour_chr_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_HOUR_CHR_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_HOUR_CHR_TSZ';
            -- Format date
            RETURN date_hour_chr_tsz(i_lang => i_lang, i_date => l_timestamp, i_prof => i_prof);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR_STR',
                                              l_error);
            RETURN NULL;
    END date_hour_chr_str;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_EXTEND (English) or DATE_MASK01 (others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro (Emília Taborda)
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_hour_chr_extend_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(32) := 'DATE_HOUR_CHR_EXTEND_TSZ(1)';
        l_date_format VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        g_error := 'GET FORMAT';
        -- Get date format
        IF i_lang = g_english_lang
        THEN
            l_date_format := 'DATE_HOUR_FORMAT_EXTEND';
        ELSE
            l_date_format := 'DATE_MASK01';
        END IF;
    
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => l_date_format,
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR_EXTEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_hour_chr_extend_tsz;

    /*
    * Formats a timestamp according to DATE_SHORTMONTH_HOUR_FORMAT_EXTEND (English) or DATE_MASK04 (others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp
    *
    * @author Patrícia Neto
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_mon_hour_format_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name   VARCHAR2(32) := 'DATE_MON_HOUR_FORMAT_TSZ(1)';
        l_date_format VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        g_error := 'GET FORMAT';
        -- Get date format
        IF i_lang = g_english_lang
        THEN
            l_date_format := 'DATE_SHORTMONTH_HOUR_FORMAT_EXTEND';
        ELSE
            l_date_format := 'DATE_MASK04';
        END IF;
    
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => l_date_format,
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_MON_HOUR_FORMAT_TSZ',
                                              l_error);
            RETURN NULL;
    END date_mon_hour_format_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_EXTEND (English) or DATE_MASK01 (others) parameters.
    * 
    * @param i_lang            Language identifier.
    * @param i_date            Timestamp
    * @param i_prof            Professional
    * @param i_timezone        Timezone
    * 
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro (Emília Taborda)
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION date_hour_chr_extend_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_HOUR_CHR_EXTEND_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_HOUR_CHR_EXTEND_TSTZ';
            RETURN date_hour_chr_extend_tsz(i_lang => i_lang, i_date => l_timestamp, i_prof => i_prof);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_HOUR_CHR_EXTEND_STR',
                                              l_error);
            RETURN NULL;
    END date_hour_chr_extend_str;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_send_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_SEND_TSZ(2)';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_HOUR_SEND_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_send_tsz;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp.
    * @param i_prof   Professional.
    * 
    * @return Formatted timestamp. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_send_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_SEND_TSZ(1)';
        l_format    VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_SEND_TSZ';
        -- Get format
        RETURN date_send_tsz(i_lang => i_lang,
                             i_date => i_date,
                             i_inst => i_prof.institution,
                             i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_send_tsz;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer. 
    *
    * @param i_lang       Language identifier
    * @param i_date       Timestamp
    * @param i_prof       Professional
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_send_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_SEND_STR(3)';
        l_format    VARCHAR2(4000);
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        -- Format timestamp
        g_error := 'CALL DATE_SEND_STR';
        RETURN date_send_str(i_lang     => i_lang,
                             i_date     => i_date,
                             i_inst     => i_prof.institution,
                             i_soft     => i_prof.software,
                             i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_STR',
                                              l_error);
            RETURN NULL;
    END date_send_str;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer. 
    *
    * @param i_lang       Language identifier
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_send_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_SEND_STR(4)';
        l_format    VARCHAR2(4000);
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_ANYTIMEZONE';
        -- Get timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            -- Format timestamp
            g_error := 'CALL DATE_SEND_TSTZ';
            RETURN date_send_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_STR',
                                              l_error);
            RETURN NULL;
    END date_send_str;

    /*
    * Formats a timestamp according to the DAY_YEAR_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_dayyear_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_DAYYEAR_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DAY_YEAR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_dayyear_tsz;

    /*
    * Formats a timestamp according to the MONTH_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_month_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_MONTH_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'MONTH_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_month_tsz;

    /*
    * Formats a timestamp according to the YEAR_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_year_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_YEAR_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'YEAR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_year_tsz;

    /*
    * Formats a timestamp according to the DAY_MONTH_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_daymonth_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_DAYMONTH_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DAY_MONTH_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_daymonth_tsz;

    /*
    * Formats a timestamp according to the YEAR_MONTH_DAY_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_yearmonthday_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_YEARMONTHDAY_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'YEAR_MONTH_DAY_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_yearmonthday_tsz;

    /*
    * Formats a timestamp according to the DAY_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_day_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_DAY_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DAY_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_day_tsz;

    /*
    * Formats a timestamp according to the WEEK_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/13
    */
    FUNCTION date_week_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_WEEK_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'WEEK_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_week_tsz;

    /*
    * Formats a timestamp according to the HOUR_MIN_FORMAT format.
    * It is used to format dates, before sending them to the Flash layer.
    *
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp. 
    *
    * @author Sofia Mendes
    * @version 2.5.2
    * @since 2009/06/14
    */
    FUNCTION date_hourmin_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_HOURMIN_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'HOUR_MIN_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_SEND_TSZ',
                                              l_error);
            RETURN NULL;
    END date_hourmin_tsz;

    /*
    * Formats a timestamp according to DATE_TIME_FORMAT (English) or DATE_MASK03 (Others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_time_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_TIME_CHR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_TIME_CHR_TSZ';
        RETURN date_time_chr_tsz(i_lang => i_lang,
                                 i_date => i_date,
                                 i_inst => i_prof.institution,
                                 i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END date_time_chr_tsz;

    /*
    * Formats a timestamp according to DATE_TIME_FORMAT (English) or DATE_MASK03 (Others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_time_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_TIME_CHR_TSZ(2)';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'SET FORMAT';
        -- Set format
        IF i_lang = g_english_lang
        THEN
            l_format := 'DATE_TIME_FORMAT';
        ELSE
            l_format := 'DATE_MASK03';
        END IF;
    
        g_error := 'CALL DATE_COMMON';
        -- Format date
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => l_format,
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END date_time_chr_tsz;

    /*
    * Formats a timestamp according to DATE_TIME_FORMAT (English) or DATE_MASK03 (Others) parameters.
    * 
    * @param i_lang       Language identifier
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_time_chr_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_TIME_CHR_STR(3)';
        l_format    VARCHAR2(4000);
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DATE_TIME_CHR_TSZ';
            -- Format timestamp
            RETURN date_time_chr_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR_STR',
                                              l_error);
            RETURN NULL;
    END date_time_chr_str;

    /*
    * Formats a timestamp according to DATE_TIME_FORMAT (English) or DATE_MASK03 (Others) parameters.
    * 
    * @param i_lang       Language identifier
    * @param i_date       Timestamp
    * @param i_prof       Professional
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION date_time_chr_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DATE_TIME_CHR_STR(4)';
        l_format    VARCHAR2(4000);
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_TIME_CHR_STR';
        -- Format timestamp
        RETURN date_time_chr_str(i_lang     => i_lang,
                                 i_date     => i_date,
                                 i_inst     => i_prof.institution,
                                 i_soft     => i_prof.software,
                                 i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DATE_TIME_CHR_STR',
                                              l_error);
            RETURN NULL;
    END date_time_chr_str;

    /*
    * Formats a timestamp according to DATE_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_TSZ';
        -- Format timestamp
        RETURN dt_chr_tsz(i_lang => i_lang, i_date => i_date, i_inst => i_prof.institution, i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_TSZ';
            -- Format timestamp
            RETURN dt_chr_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_str;

    /*
    * Formats a timestamp according to DATE_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_STR';
        -- Format timestamp
        RETURN dt_chr_str(i_lang     => i_lang,
                          i_date     => i_date,
                          i_inst     => i_prof.institution,
                          i_soft     => i_prof.software,
                          i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_str;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_date_hour_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_DATE_HOUR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_HOUR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_DATE_HOUR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_date_hour_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_date_hour_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_DATE_HOUR_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_DATE_HOUR_TSZ';
        -- Format timestamp
        RETURN dt_chr_date_hour_tsz(i_lang => i_lang,
                                    i_date => i_date,
                                    i_inst => i_prof.institution,
                                    i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_DATE_HOUR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_date_hour_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_date_hour_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_DATE_HOUR_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_DATE_HOUR_TSZ';
            -- Format timestamp
            RETURN dt_chr_date_hour_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_DATE_HOUR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_date_hour_str;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_date_hour_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_DATE_HOUR_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_DATE_HOUR_STR';
        -- Format timestamp
        RETURN dt_chr_date_hour_str(i_lang     => i_lang,
                                    i_date     => i_date,
                                    i_inst     => i_prof.institution,
                                    i_soft     => i_prof.software,
                                    i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_DATE_HOUR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_date_hour_str;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_hour_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_HOUR_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'HOUR_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_HOUR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_hour_tsz;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_hour_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_HOUR_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_HOUR_TSZ';
        -- Format timestamp
        RETURN dt_chr_hour_tsz(i_lang => i_lang,
                               i_date => i_date,
                               i_inst => i_prof.institution,
                               i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_HOUR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_hour_tsz;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_hour_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_HOUR_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_HOUR_TSZ';
            -- Format timestamp
            RETURN dt_chr_hour_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_HOUR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_hour_str;

    /*
    * Formats a timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_hour_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_HOUR_STRS(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_HOUR_STR';
        -- Format timestamp
        RETURN dt_chr_hour_str(i_lang     => i_lang,
                               i_date     => i_date,
                               i_inst     => i_prof.institution,
                               i_soft     => i_prof.software,
                               i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_HOUR_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_hour_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_MONTH parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_month_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_MONTH_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_MONTH',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_MONTH_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_month_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_MONTH parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_month_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_MONTH_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_MONTH_TSZ';
        -- Format timestamp
        RETURN dt_chr_month_tsz(i_lang => i_lang,
                                i_date => i_date,
                                i_inst => i_prof.institution,
                                i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_MONTH_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_month_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_MONTH parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_month_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_MONTH_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_MONTH_TSZ';
            -- Format timestamp
            RETURN dt_chr_month_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_MONTH_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_month_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_MONTH parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_month_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_MONTH_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_MONTH_STR';
        -- Format timestamp
        RETURN dt_chr_month_str(i_lang     => i_lang,
                                i_date     => i_date,
                                i_inst     => i_prof.institution,
                                i_soft     => i_prof.software,
                                i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_MONTH_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_month_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_SHORT_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_SHORT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_SHORT_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_SHORT';
        -- Format timestamp
        RETURN dt_chr_short_tsz(i_lang => i_lang,
                                i_date => i_date,
                                i_inst => i_prof.institution,
                                i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_SHORT_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_SHORT_TSZ';
            -- Format timestamp
            RETURN dt_chr_short_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_short_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_SHORT_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_SHORT_STR';
        -- Format timestamp
        RETURN dt_chr_short_str(i_lang     => i_lang,
                                i_date     => i_date,
                                i_inst     => i_prof.institution,
                                i_soft     => i_prof.software,
                                i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_short_str;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_SHORT (English) or DATE_MASK02 (Others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_hour_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_HOUR_CHR_SHORT_TSZ(1)';
        l_format    VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'SET FORMAT';
        -- Set format
        IF i_lang = g_english_lang
        THEN
            l_format := 'DATE_HOUR_FORMAT_SHORT';
        ELSE
            l_format := 'DATE_MASK02';
        END IF;
    
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => l_format,
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_HOUR_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_hour_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_SHORT (English) or DATE_MASK02 (Others) parameters.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_hour_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_HOUR_SHORT_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_HOUR_CHR_SHORT_TSZ';
        -- Format timestamp
        RETURN dt_hour_chr_short_tsz(i_lang => i_lang,
                                     i_date => i_date,
                                     i_inst => i_prof.institution,
                                     i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_HOUR_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_hour_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_SHORT (English) or DATE_MASK02 (Others) parameters
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_hour_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_HOUR_SHORT_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_HOUR_CHR_SHORT_TSZ';
            -- Format timestamp
            RETURN dt_hour_chr_short_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_HOUR_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_hour_chr_short_str;

    /*
    * Formats a timestamp according to DATE_HOUR_FORMAT_SHORT (English) or DATE_MASK02 (Others) parameters.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_hour_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_HOUR_CHR_SHORT_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_HOUR_CHR_SHORT_STR';
        -- Format timestamp
        RETURN dt_hour_chr_short_str(i_lang     => i_lang,
                                     i_date     => i_date,
                                     i_inst     => i_prof.institution,
                                     i_soft     => i_prof.software,
                                     i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_HOUR_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_hour_chr_short_str;

    /*
    * Formats a timestamp according to 24_HOUR_FORMAT (no minutes).
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author José Silva
    * @since 2010/06/03
    */
    FUNCTION dt_24hour_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_24HOUR_CHR_TSZ';
        l_error     t_error_out;
    BEGIN
    
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => '24_HOUR_FORMAT',
                           i_inst   => i_prof.institution,
                           i_soft   => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_24HOUR_CHR_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_24hour_chr_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_DAY_HOUR_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_year_day_hour_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_YEAR_DAY_HOUR_SHORT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_year_day_hour_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_DAY_HOUR_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_year_day_hour_chr_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ';
        -- Format timestamp
        RETURN dt_year_day_hour_chr_short_tsz(i_lang => i_lang,
                                              i_date => i_date,
                                              i_inst => i_prof.institution,
                                              i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_year_day_hour_chr_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_DAY_HOUR_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_year_day_hour_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_YEAR_DAY_HOUR_CHR_SHORT_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_YEAR_DAY_HOUR_CHR_SHORT_TSZ';
            -- Format timestamp
            RETURN dt_year_day_hour_chr_short_tsz(i_lang => i_lang,
                                                  i_date => l_timestamp,
                                                  i_inst => i_inst,
                                                  i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_YEAR_DAY_HOUR_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_year_day_hour_chr_short_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_DAY_HOUR_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION dt_year_day_hour_chr_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_YEAR_DAY_HOUR_CHR_SHORT_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_YEAR_DAY_HOUR_CHR_SHORT_STR';
        -- Format timestamp
        RETURN dt_year_day_hour_chr_short_str(i_lang     => i_lang,
                                              i_date     => i_date,
                                              i_inst     => i_prof.institution,
                                              i_soft     => i_prof.software,
                                              i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_YEAR_DAY_HOUR_CHR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_year_day_hour_chr_short_str;

    /*
    * Convert a timestamp considering a conversion unit.
    * 
    * @param i_lang   Language identifier
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * @param i_units  Conversion unit
    * 
    * @return Converted timestamp
    *
    * @author Nuno Guerreiro (Emília Taborda)
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_conversion_date_tsz
    (
        i_lang  IN language.id_language%TYPE,
        i_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof  IN profissional,
        i_units IN triage_units.conversion%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name    VARCHAR2(32) := 'GET_CONVERSION_DATE_TSZ(1)';
        l_elapsed_msg  VARCHAR2(50);
        l_elapsed_time NUMBER;
        l_error        t_error_out;
        l_date         TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CONVERT DATE';
        -- Convert date
        IF NOT get_timestamp_insttimezone(i_lang      => NULL,
                                          i_inst      => i_prof.institution,
                                          i_timestamp => i_date,
                                          o_timestamp => l_date,
                                          o_error     => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET DIFF';
        -- Get difference between the current timestamp and the one given as a parameter
        IF get_timestamp_diff(i_lang        => i_lang,
                              i_timestamp_1 => current_timestamp,
                              i_timestamp_2 => i_date,
                              o_days_diff   => l_elapsed_time,
                              o_error       => l_error)
        THEN
            g_error := 'GET MESSAGE';
            -- Get message
            IF i_units = g_min
            THEN
                -- Minutes
                IF ((l_elapsed_time > -1) AND (l_elapsed_time < 1))
                THEN
                    l_elapsed_msg := trunc(abs(l_elapsed_time) * 1440);
                ELSE
                    l_elapsed_msg := trunc(abs(l_elapsed_time)) * 1440;
                END IF;
            END IF;
            RETURN correct_date(l_elapsed_msg);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONVERSION_DATE_TSZ',
                                              l_error);
            RETURN NULL;
    END get_conversion_date_tsz;

    /*
    * Convert a timestamp considering a conversion unit.
    * 
    * @param i_lang       Language identifier
    * @param i_date       Timestamp
    * @param i_prof       Professional
    * @param i_units      Conversion unit
    * @param i_timezone   Timezone      
    * 
    * @return Converted timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_conversion_date_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_units    IN triage_units.conversion%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_CONVERSION_DATE_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Get timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => i_prof,
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL GET_CONVERSION_DATE_TSZ';
            -- Convert timestamp
            RETURN get_conversion_date_tsz(i_lang  => i_lang,
                                           i_date  => l_timestamp,
                                           i_prof  => i_prof,
                                           i_units => i_units);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONVERSION_DATE_STR',
                                              l_error);
            RETURN NULL;
    END get_conversion_date_str;

    /*
    * Gets the description of an elapsed time (absolute value).
    * 
    * @param i_lang      Language identifier.
    * @param i_elapsed   Elapsed time (1 = 1 day)
    * @param o_desc      Description
    * @param o_error     Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_abs_desc
    (
        i_lang    IN NUMBER,
        i_elapsed IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_DESC';
    BEGIN
        g_error := 'GET DESCRIPTION';
        -- Get absolute description
        IF ((i_elapsed > -1) AND (i_elapsed < 1))
        THEN
            o_desc := to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed >= 1) AND (i_elapsed < 2))
              OR ((i_elapsed > -2) AND (i_elapsed <= -1))
        THEN
            o_desc := '1 ' || lower(pk_message.get_message(i_lang, 'COMMON_M019'));
        ELSIF i_elapsed >= 2
              OR i_elapsed <= -2
        THEN
            o_desc := trunc(abs(i_elapsed)) || ' ' || lower(pk_message.get_message(i_lang, 'COMMON_M020'));
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
                                              'GET_ELAPSED_ABS_DESC',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_abs_desc;

    /*
    * Gets the description of an elapsed time (absolute value) till years.
    * 
    * @param i_lang      Language identifier.
    * @param i_elapsed   Elapsed time (1 = 1 day)
    * @param o_desc      Description
    * @param o_error     Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Tiago Silva
    * @version alpha
    * @since 2007/09/06
    */
    FUNCTION get_elapsed_abs_desc_years
    (
        i_lang    IN NUMBER,
        i_elapsed IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_DESC_YEARS';
    BEGIN
        g_error := 'GET DESCRIPTION';
        -- Get absolute description
        IF ((i_elapsed > -1) AND (i_elapsed < 1))
        THEN
            o_desc := to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed >= 1) AND (i_elapsed < 2))
              OR ((i_elapsed > -2) AND (i_elapsed <= -1))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF i_elapsed > -365
              AND i_elapsed < 365
        THEN
            o_desc := trunc(abs(i_elapsed)) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        ELSIF ((i_elapsed >= 365) AND (i_elapsed < 730))
              OR ((i_elapsed > -730) AND (i_elapsed <= -365))
        THEN
        
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M049');
        ELSIF i_elapsed >= 730
              OR i_elapsed <= -730
        THEN
            o_desc := trunc(abs(i_elapsed) / 365) || ' ' || pk_message.get_message(i_lang, 'COMMON_M050');
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
                                              'GET_ELAPSED_ABS_DESC_YEARS',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_abs_desc_years;

    /*
    * Gets the extended description of an elapsed time.
    * 
    * @param i_lang      Language identifier.
    * @param i_elapsed   Elapsed time (1 = 1 day)
    * @param i_separator Separator
    * @param o_desc      Description
    * @param o_error     Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_ext_desc
    (
        i_lang      IN NUMBER,
        i_elapsed   IN NUMBER,
        i_separator IN VARCHAR2,
        o_desc      OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_EXT_DESC';
    BEGIN
        g_error := 'GET DESCRIPTION';
        -- Get description
        IF ((i_elapsed >= 0) AND (i_elapsed < 1))
        THEN
            o_desc := to_char(to_date(lpad(trunc(i_elapsed * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed >= 1) AND (i_elapsed < 2))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019') || ' ' || i_separator || ' ' ||
                      to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF i_elapsed >= 2
        THEN
            o_desc := trunc(i_elapsed) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020') || ' ' || i_separator || ' ' ||
                      to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed > -1) AND (i_elapsed < 0))
        THEN
            o_desc := '-' || to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed > -2) AND (i_elapsed <= -1))
        THEN
            o_desc := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M019') || ' ' || i_separator || ' ' ||
                      to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF i_elapsed <= -2
        THEN
            o_desc := '-' || trunc(i_elapsed) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020') || ' ' ||
                      i_separator || ' ' ||
                      to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
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
                                              'GET_ELAPSED_EXT_DESC',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_ext_desc;

    /*
    * Gets the description of an elapsed time.
    * 
    * @param i_lang      Language identifier.
    * @param i_elapsed   Elapsed time (1 = 1 day)
    * @param i_separator Separator
    * @param o_desc      Description
    * @param o_error     Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_desc
    (
        i_lang    IN NUMBER,
        i_elapsed IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_DESC';
    BEGIN
        g_error := 'GET DESCRIPTION';
        -- Get description
        IF ((i_elapsed >= 0) AND (i_elapsed < 1))
        THEN
            o_desc := to_char(to_date(lpad(trunc(i_elapsed * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed >= 1) AND (i_elapsed < 2))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF i_elapsed >= 2
        THEN
            o_desc := trunc(i_elapsed) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        ELSIF ((i_elapsed > -1) AND (i_elapsed < 0))
        THEN
            o_desc := '-' || to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed > -2) AND (i_elapsed <= -1))
        THEN
            o_desc := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF i_elapsed <= -2
        THEN
            o_desc := '-' || trunc(abs(i_elapsed)) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
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
                                              'GET_ELAPSED_DESC',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_desc;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - timestamp2).
    * 
    * @param i_lang    Language identifier.
    * @param i_date1   Timestamp 1
    * @param i_date2   Timestamp 2
    * @param o_elapsed Description
    * @param o_error   Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_tsz
    (
        i_lang    IN language.id_language%TYPE,
        i_date1   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date2   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_ELAPSED_TSZ(1)';
        l_elapsed_msg  VARCHAR2(50) := NULL;
        l_elapsed_time NUMBER;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Calculate elapsed time
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => i_date1,
                                  i_timestamp_2 => i_date2,
                                  o_days_diff   => l_elapsed_time,
                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_DESC';
        -- Get description
        IF NOT
            get_elapsed_abs_desc(i_lang => i_lang, i_elapsed => l_elapsed_time, o_desc => o_elapsed, o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ELAPSED_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp) till years.
    * 
    * @param i_lang    Language identifier.
    * @param i_date    Timestamp
    * @param o_elapsed Description
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Tiago Silva
    * @version alpha
    * @since 2007/09/06
    */
    FUNCTION get_elapsed_tsz_years
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name    VARCHAR2(32) := 'GET_ELAPSED_TSZ_YEARS';
        l_elapsed      VARCHAR2(4000);
        l_elapsed_time NUMBER;
        l_error        t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Calculate elapsed time
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => i_date,
                                  i_timestamp_2 => current_timestamp,
                                  o_days_diff   => l_elapsed_time,
                                  o_error       => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_DESC';
        -- Get description
        IF get_elapsed_abs_desc_years(i_lang    => i_lang,
                                      i_elapsed => l_elapsed_time,
                                      o_desc    => l_elapsed,
                                      o_error   => l_error)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_DTSZ_YEARS',
                                              l_error);
            RETURN NULL;
    END get_elapsed_tsz_years;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - timestamp2).
    * 
    * @param i_lang    Language identifier.
    * @param i_date1   Timestamp 1
    * @param i_date2   Timestamp 2
    * @param o_elapsed Description
    * @param o_error   Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Susana Seixas
    * @version alpha
    * @since 2007/08/17
    */
    FUNCTION get_elapsed_tsz
    (
        i_lang  IN language.id_language%TYPE,
        i_date1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_date2 IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_TSZ(2)';
        l_elapsed   VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_ELAPSED_ABS_TSZ';
        -- Get difference
        IF get_elapsed_tsz(i_lang    => i_lang,
                           i_date1   => i_date1,
                           i_date2   => i_date2,
                           o_elapsed => l_elapsed,
                           o_error   => l_error)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - timestamp2).
    * 
    * @param i_lang        Language identifier.
    * @param i_date1       Timestamp 1
    * @param i_date2       Timestamp 2
    * @param o_elapsed     Description
    * @param o_error       Error message, if an error occurred.
    * @param i_timezone1   Timezone 1
    * @param i_timezone2   Timezone 2
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date1     IN VARCHAR2,
        i_date2     IN VARCHAR2,
        o_elapsed   OUT VARCHAR2,
        o_error     OUT t_error_out,
        i_timezone1 IN VARCHAR2 DEFAULT NULL,
        i_timezone2 IN VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'GET_ELAPSED_STR(2)';
        l_timestamp_1 TIMESTAMP WITH TIME ZONE;
        l_timestamp_2 TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'GET TIMESTAMP1';
        -- Convert timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_date1,
                               i_timezone  => i_timezone1,
                               o_timestamp => l_timestamp_1,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET TIMESTAMP2';
        -- Convert timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_date2,
                               i_timezone  => i_timezone2,
                               o_timestamp => l_timestamp_2,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_TSZ';
        -- Get elapsed time description
        RETURN get_elapsed_tsz(i_lang    => i_lang,
                               i_date1   => l_timestamp_1,
                               i_date2   => l_timestamp_2,
                               o_elapsed => o_elapsed,
                               o_error   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_STR',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_str;

    /*
    * Gets the description aboutthe time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date1       Timestamp 1
    * @param o_elapsed     Description
    * @param o_error       Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_abs_tsz
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_ELAPSED_ABS_TSZ(1)';
        l_elapsed_time NUMBER;
    BEGIN
        g_error := 'CALL GET_ELAPSED_TSZ';
        -- Get difference
        RETURN get_elapsed_tsz(i_lang    => i_lang,
                               i_date1   => i_date,
                               i_date2   => current_timestamp,
                               o_elapsed => o_elapsed,
                               o_error   => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_abs_tsz;

    /*
    * Gets the description about an elapsed time between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
    * 
    * @return Description
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_abs_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_TSZ(2)';
        l_elapsed   VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_ELAPSED_ABS_TSZ';
        -- Get difference
        IF get_elapsed_abs_tsz(i_lang => i_lang, i_date => i_date, o_elapsed => l_elapsed, o_error => l_error)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_abs_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
    * @param o_elapsed     Description
    * @param o_error       Error message, if an error occurred.
    * @param i_timezone    Timezone
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_abs_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN VARCHAR2,
        o_elapsed  OUT VARCHAR2,
        o_error    OUT t_error_out,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_STR(1)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_ANYTIMEZONE';
        -- Convert timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_date,
                               i_timezone  => i_timezone,
                               o_timestamp => l_timestamp,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_TSZ';
        -- Get difference
        RETURN get_elapsed_abs_tsz(i_lang => i_lang, i_date => l_timestamp, o_elapsed => o_elapsed, o_error => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_abs_str;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
    * @param i_timezone    Timezone
    * 
    * @return Description
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_abs_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN VARCHAR2,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_ABS_STR(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
        l_elapsed   VARCHAR2(4000);
    BEGIN
        g_error := 'CALL GET_ELAPSED_ABS_STR';
        -- Get description
        IF get_elapsed_abs_str(i_lang     => i_lang,
                               i_prof     => i_prof,
                               i_date     => i_date,
                               o_elapsed  => l_elapsed,
                               o_error    => l_error,
                               i_timezone => i_timezone)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_ABS_STR',
                                              l_error);
            RETURN NULL;
    END get_elapsed_abs_str;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
    * @param i_separator   Date and time separator
    * @param o_elapsed     Description
    * @param o_error       Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_date_tsz
    (
        i_lang      IN language.id_language%TYPE,
        i_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_separator IN VARCHAR2,
        o_elapsed   OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_ELAPSED_DATE_TSZ(1)';
        l_elapsed_time NUMBER;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Calculate elapsed time
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => current_timestamp,
                                  i_timestamp_2 => i_date,
                                  o_days_diff   => l_elapsed_time,
                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_EXT_DESC';
        -- Get description
        RETURN get_elapsed_ext_desc(i_lang      => i_lang,
                                    i_elapsed   => l_elapsed_time,
                                    i_separator => i_separator,
                                    o_desc      => o_elapsed,
                                    o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_DATE_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_date_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
    * @param i_separator   Date and time separator
    * 
    * @return Description
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_date_tsz
    (
        i_lang      IN language.id_language%TYPE,
        i_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR IS
        l_func_name   VARCHAR2(32) := 'GET_ELAPSED_DATE_TSZ(1)';
        l_elapsed_msg VARCHAR2(50) := NULL;
        l_error       t_error_out;
    BEGIN
        g_error := 'CALL GET_ELAPSED_DATE_TSZ';
        -- Get description
        IF get_elapsed_date_tsz(i_lang      => i_lang,
                                i_date      => i_date,
                                i_separator => i_separator,
                                o_elapsed   => l_elapsed_msg,
                                o_error     => l_error)
        THEN
            RETURN l_elapsed_msg;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_DATE_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_date_tsz;

    /*
    * Returns the number of seconds elapsed between i_date and current_timestamp.
    *
    * @param i_date      Timestamp
    *
    * @return number of seconds
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_minutes_abs_tsz(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER IS
        l_func_name VARCHAR2(32) := 'GET_ELAPSED_MINUTES_ABS_TSZ';
        l_time      NUMBER;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET MINUTES';
        -- Get minutes
        IF get_timestamp_diff(i_lang        => NULL,
                              i_timestamp_1 => i_date,
                              i_timestamp_2 => current_timestamp,
                              o_days_diff   => l_time,
                              o_error       => l_error)
        THEN
            RETURN round(abs(l_time * 1440));
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_MINUTES_ABS_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_minutes_abs_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (i_date - current_timestamp).
    *
    * @param i_lang        Language
    * @param i_date        Timestamp
    * @param o_elapsed     Description
    * @param o_error       Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_sysdate_tsz
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_SYSDATE_TSZ(1)';
        l_diff      NUMBER;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Get difference
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => current_timestamp,
                                  i_timestamp_2 => i_date,
                                  o_days_diff   => l_diff,
                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_DESC';
        -- Get description
        IF NOT get_elapsed_desc(i_lang => i_lang, i_elapsed => l_diff, o_desc => o_elapsed, o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ELAPSED_SYSDATE_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_sysdate_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (i_date - current_timestamp).
    *
    * @param i_lang        Language
    * @param i_date        Timestamp
    * 
    * @return Description
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION get_elapsed_sysdate_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_ELAPSED_SYSDATE_TSZ(2)';
        l_elapsed   VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_ELAPSED_SYSDATE_TSZ';
        -- Get description
        IF get_elapsed_sysdate_tsz(i_lang => i_lang, i_date => i_date, o_elapsed => l_elapsed, o_error => l_error)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_SYSDATE_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_sysdate_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (i_date - current_timestamp).
    *
    * @param i_lang        Language
    * @param i_date        Timestamp
    * 
    * @return Description
    *
    * @author Ana Matos
    * @version alpha
    * @since 2008/04/05
    */
    FUNCTION get_elapsed_time_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_ELAPSED_TIME_TSZ(2)';
        l_elapsed   VARCHAR2(4000);
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_ELAPSED_TIME_TSZ';
        -- Get description
        IF get_elapsed_time_tsz(i_lang => i_lang, i_date => i_date, o_elapsed => l_elapsed, o_error => l_error)
        THEN
            RETURN correct_date(l_elapsed);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ELAPSED_TIME_TSZ',
                                              l_error);
            RETURN NULL;
    END get_elapsed_time_tsz;

    /*
    * Gets the description about the time elapsed between two timestamps (i_date - current_timestamp).
    *
    * @param i_lang        Language
    * @param i_date        Timestamp
    * 
    * @return Description
    *
    * @author Ana Matos
    * @version alpha
    * @since 2008/05/05
    */
    FUNCTION get_elapsed_time_tsz
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_SYSDATE_TSZ(1)';
        l_diff      NUMBER;
    BEGIN
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Get difference
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => current_timestamp,
                                  i_timestamp_2 => i_date,
                                  o_days_diff   => l_diff,
                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_ELAPSED_TIME_DESC';
        -- Get description
        IF NOT get_elapsed_time_desc(i_lang => i_lang, i_elapsed => l_diff, o_desc => o_elapsed, o_error => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_ELAPSED_TIME_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_time_tsz;

    /*
    * Gets the description of an elapsed time.
    * 
    * @param i_lang      Language identifier.
    * @param i_elapsed   Elapsed time (1 = 1 day)
    * @param i_separator Separator
    * @param o_desc      Description
    * @param o_error     Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Ana Matos
    * @version alpha
    * @since 2008/05/05
    */
    FUNCTION get_elapsed_time_desc
    (
        i_lang    IN NUMBER,
        i_elapsed IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'GET_ELAPSED_DESC';
    BEGIN
        g_error := 'GET DESCRIPTION';
        -- Get description
        IF ((i_elapsed >= 0) AND (i_elapsed < 1))
        THEN
            o_desc := to_char(to_date(lpad(trunc(i_elapsed * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed >= 1) AND (i_elapsed < 2))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF ((i_elapsed >= 2) AND (i_elapsed < 30))
        THEN
            o_desc := trunc(i_elapsed) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        ELSIF ((i_elapsed >= 30) AND (i_elapsed < 60))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M060');
        ELSIF ((i_elapsed >= 60) AND (i_elapsed < 365) AND trunc(i_elapsed / 30) < 12)
        THEN
            o_desc := trunc(i_elapsed / 30) || ' ' || pk_message.get_message(i_lang, 'COMMON_M061');
        ELSIF ((trunc(i_elapsed / 30) = 12 OR (i_elapsed >= 365)) AND (i_elapsed < 730))
        THEN
            o_desc := '1 ' || pk_message.get_message(i_lang, 'COMMON_M049');
        ELSIF (i_elapsed >= 730)
        THEN
            o_desc := trunc(i_elapsed / 365) || ' ' || pk_message.get_message(i_lang, 'COMMON_M050');
        
        ELSIF ((i_elapsed > -1) AND (i_elapsed < 0))
        THEN
            o_desc := '-' || to_char(to_date(lpad(trunc(abs(i_elapsed) * 24 * 3600), 5, 0), 'sssss'), 'hh24:mi');
        ELSIF ((i_elapsed > -2) AND (i_elapsed <= -1))
        THEN
            o_desc := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M019');
        ELSIF ((i_elapsed <= -2) AND (i_elapsed > -30))
        THEN
            o_desc := '-' || trunc(abs(i_elapsed)) || ' ' || pk_message.get_message(i_lang, 'COMMON_M020');
        ELSIF ((i_elapsed <= -30) AND (i_elapsed > -60))
        THEN
            o_desc := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M060');
        ELSIF ((i_elapsed <= -60) AND (i_elapsed > -365) AND (trunc(i_elapsed / 30) > -12))
        THEN
            o_desc := '-' || trunc(abs(i_elapsed) / 30) || ' ' || pk_message.get_message(i_lang, 'COMMON_M061');
        ELSIF ((trunc(i_elapsed / 30) = -12 OR (i_elapsed <= -365)) AND (i_elapsed > -730))
        THEN
            o_desc := '-1 ' || pk_message.get_message(i_lang, 'COMMON_M049');
        ELSIF (i_elapsed <= -730)
        THEN
            o_desc := '-' || trunc(abs(i_elapsed) / 365) || ' ' || pk_message.get_message(i_lang, 'COMMON_M050');
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
                                              'GET_ELAPSED_TIME_DESC',
                                              o_error);
            RETURN FALSE;
    END get_elapsed_time_desc;

    /*
    * Formats the current timestamp according to DATE_HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION sysdate_char
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'SYSDATE_CHAR';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_CHAR_TSZ';
        -- Get description
        RETURN date_char_tsz(i_lang => i_lang,
                             i_date => current_timestamp,
                             i_inst => i_prof.institution,
                             i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SYSDATE_CHAR',
                                              l_error);
            RETURN NULL;
    END sysdate_char;

    /*
    * Formats the current timestamp according to HOUR_FORMAT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/03
    */
    FUNCTION sysdate_char_hour
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'SYSDATE_CHAR';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_CHAR_HOUR_TSZ';
        -- Get description
        RETURN date_char_hour_tsz(i_lang => i_lang,
                                  i_date => current_timestamp,
                                  i_inst => i_prof.institution,
                                  i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SYSDATE_CHAR_HOUR',
                                              l_error);
            RETURN NULL;
    END sysdate_char_hour;

    /*
    * Returns the current timestamp formatted in three 
    * different shapes: current date, current time, 
    * and date/time to send to the Flash layer.
    * 
    * @param i_lang         Language identifier.
    * @param i_prof         Professional
    * @param o_date         Current date
    * @param o_hour         Current time
    * @param o_date_hour    Date/time to send to the Flash layer
    * @param o_error        Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION sysdate_date_hour
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_date      OUT VARCHAR2,
        o_hour      OUT VARCHAR2,
        o_date_hour OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(200) := 'SYSDATE_DATE_HOUR';
    BEGIN
        g_error := 'CALL DT_CHR_TSZ';
        -- Get current date
        o_date := dt_chr_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        g_error := 'CALL DT_CHR_HOUR_TSZ';
        -- Get current time
        o_hour := dt_chr_hour_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        g_error := 'CALL DATE_SEND_TSZ';
        -- Get current time formatted to be sent to the Flash layer
        o_date_hour := date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        IF o_date IS NULL
           OR o_hour IS NULL
           OR o_date_hour IS NULL
        THEN
            RETURN FALSE;
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
                                              'SYSDATE_DATE_HOUR',
                                              o_error);
            RETURN FALSE;
    END sysdate_date_hour;

    /*
    * Formats a timestamp using the TRUNC_DT_FORMAT parameter.
    *
    * @param i_lang       Language
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    *
    * @return Formatted timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/06
    */
    FUNCTION trunc_dt_char_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'TRUNC_DT_CHAR_TSZ';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Get description
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'TRUNC_DT_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_DT_CHAR_TSZ',
                                              l_error);
            RETURN NULL;
    END trunc_dt_char_tsz;

    /*
    * Adds a number of days to a timestamp.
    * It works for timestamps as sysdate+NUM_DAYS works for dates.
    *
    * @return Resulting timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/07
    */
    FUNCTION add_days_to_tstz
    (
        i_timestamp IN TIMESTAMP WITH TIME ZONE,
        i_days      IN NUMBER
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_func_name VARCHAR2(200) := 'ADD_DAYS_TO_TSTZ';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL ADD_TO_TSTZ';
        -- Add days
        RETURN add_to_ltstz(i_timestamp => i_timestamp, i_amount => i_days, i_unit => 'DAY');
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ADD_DAYS_TO_TSTZ',
                                              l_error);
            RETURN NULL;
    END add_days_to_tstz;

    FUNCTION add_to_ltstz
    (
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_amount    IN NUMBER,
        i_unit      IN VARCHAR2 DEFAULT 'DAY'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_func_name VARCHAR2(200) := 'ADD_TO_TSTZ';
        l_error     t_error_out;
        k_tot_months CONSTANT NUMBER := 12;
    BEGIN
        g_error := 'ADD TO TIMESTAMP';
    
        IF i_unit IS NOT NULL
        THEN
        
            CASE i_unit
                WHEN 'YEAR' THEN
                    --l_timestamp := i_timestamp + numtoyminterval(i_amount * k_tot_months, 'MONTH');
                    l_timestamp := CAST(add_months(i_timestamp, i_amount * k_tot_months) AS TIMESTAMP WITH LOCAL TIME ZONE);
                
                WHEN 'MONTH' THEN
                    --l_timestamp := i_timestamp + numtoyminterval(i_amount, 'MONTH');
                    l_timestamp := CAST(add_months(i_timestamp, i_amount) AS TIMESTAMP WITH LOCAL TIME ZONE);
                ELSE
                    l_timestamp := i_timestamp + numtodsinterval(i_amount, i_unit);
            END CASE;
        
        END IF;
    
        RETURN l_timestamp;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END add_to_ltstz;

    FUNCTION add_to_ltstz2
    (
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_amount    IN NUMBER,
        i_unit      IN VARCHAR2 DEFAULT 'DAY'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_func_name VARCHAR2(200 CHAR) := 'ADD_TO_LTSTZ';
        l_error     t_error_out;
    BEGIN
        g_error := 'ADD TO TIMESTAMP';
        IF i_unit IS NOT NULL
           AND i_unit IN ('YEAR', 'MONTH')
        THEN
            l_timestamp := i_timestamp + numtoyminterval(i_amount, i_unit);
        ELSIF i_unit IS NOT NULL
        THEN
            l_timestamp := i_timestamp + numtodsinterval(i_amount, i_unit);
        ELSE
            l_timestamp := i_timestamp + numtodsinterval(i_amount, 'DAY');
        END IF;
    
        RETURN l_timestamp;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END add_to_ltstz2;

    /*
    * Extracts the date and time components from a timestamp with time zone, which is previously converted to the correct timezone.
    * 
    * @param i_lang     Language identifier.
    * @param i_prof     Professional
    * @param o_years    Years
    * @param o_months   Months
    * @param o_days     Days
    * @param o_hours    Hours
    * @param o_minutes  Minutes
    * @param o_seconds  Seconds
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/07
    */
    FUNCTION extract_from_tstz
    (
        i_lang      language.id_language%TYPE,
        i_prof      profissional,
        i_timestamp TIMESTAMP WITH LOCAL TIME ZONE,
        o_years     OUT NUMBER,
        o_months    OUT NUMBER,
        o_days      OUT NUMBER,
        o_hours     OUT NUMBER,
        o_minutes   OUT NUMBER,
        o_seconds   OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(200) := 'EXTRACT_FROM_TSTZ';
        l_utc_timestamp TIMESTAMP WITH TIME ZONE;
        l_timestamp     TIMESTAMP WITH TIME ZONE;
        l_timezone      timezone_region.timezone_region%TYPE;
    BEGIN
        g_error := 'TEST TIMESTAMP';
        IF i_timestamp IS NOT NULL
        THEN
            g_error := 'CALL GET_TIMEZONE';
            -- Get timezone
            IF NOT get_timezone(i_lang     => i_lang,
                                i_prof     => i_prof,
                                i_timezone => NULL,
                                o_timezone => l_timezone,
                                o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'CONVERT TIMESTAMP';
            -- Convert timestamp to the correct timezone
            l_timestamp := i_timestamp at TIME ZONE l_timezone;
        
            g_error := 'EXTRACT';
            -- Get timestamp components
            SELECT to_number(to_char(l_timestamp, 'YYYY')),
                   to_number(to_char(l_timestamp, 'MM')),
                   to_number(to_char(l_timestamp, 'DD')),
                   to_number(to_char(l_timestamp, 'HH24')),
                   to_number(to_char(l_timestamp, 'MI')),
                   to_number(to_char(l_timestamp, 'SS'))
              INTO o_years, o_months, o_days, o_hours, o_minutes, o_seconds
              FROM dual;
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
                                              'EXTRACT_FROM_TSTZ',
                                              o_error);
            RETURN FALSE;
    END extract_from_tstz;

    /*
    * Applies the to_char function to a timestamp, after converting it to the professional institution's timezone.
    * 
    * @param i_lang       Language identifier.
    * @param i_prof       Professional,
    * @param i_timestamp  Timestamp
    * @param i_mask       Mask to use for formatting the timestamp
    * @param o_string     Formatted timestamp.
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/08
    */
    FUNCTION to_char_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2,
        i_timezone  IN VARCHAR2 DEFAULT NULL,
        o_string    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'TO_CHAR_INSTTIMEZONE';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_nls_code  language.nls_code%TYPE;
    BEGIN
        g_error := 'CONVERT TIMESTAMP';
        -- Convert timestamp
        IF NOT get_timestamp_insttimezone(i_lang      => NULL,
                                          i_inst      => i_prof.institution,
                                          i_timestamp => i_timestamp,
                                          i_timezone  => i_timezone,
                                          o_timestamp => l_timestamp,
                                          o_error     => o_error)
        THEN
            o_string := NULL;
            RETURN FALSE;
        END IF;
    
        IF i_lang IS NOT NULL
        THEN
            -- Get NLS code
            g_error    := 'GET NLS_CODE';
            l_nls_code := get_nls_code(i_lang);
        END IF;
    
        g_error := 'FORMAT TIMESTAMP';
        -- Format date
        IF l_nls_code IS NULL
        THEN
            o_string := to_char(l_timestamp, i_mask);
        ELSE
            o_string := TRIM(to_char(l_timestamp, i_mask, 'NLS_DATE_LANGUAGE=''' || l_nls_code || ''''));
            o_string := REPLACE(o_string, '.', '');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHAR_INSTTIMEZON',
                                              o_error);
            RETURN FALSE;
    END to_char_insttimezone;

    /*
    * Applies the to_char function to a timestamp, after converting it to the professional institution's timezone.
    * 
    * @param i_prof       Professional,
    * @param i_timestamp  Timestamp
    * @param i_mask       Mask to use for formatting the timestamp
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/08
    */
    FUNCTION to_char_insttimezone
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name           VARCHAR2(64) := 'TO_CHAR_INSTTIMEZONE(1)';
        l_formatted_timestamp VARCHAR2(4000);
        l_error               t_error_out;
    BEGIN
        g_error := 'CALL TO_CHAR_INSTTIMEZONE';
        -- Format timestamp
        IF to_char_insttimezone(i_lang      => NULL,
                                i_prof      => i_prof,
                                i_timestamp => i_timestamp,
                                i_mask      => i_mask,
                                o_string    => l_formatted_timestamp,
                                o_error     => l_error)
        THEN
            RETURN correct_date(l_formatted_timestamp);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHART_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END to_char_insttimezone;

    /*
    * Applies the to_char function to a timestamp, after converting it to the professional institution's timezone.
    * 
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timestamp  Timestamp
    * @param i_mask       Mask to use for formatting the timestamp
    * 
    * @return Formatted timestamp 
    *
    * @author Susana Seixas
    * @version alpha
    * @since 2007/08/13
    */
    FUNCTION to_char_insttimezone
    (
        i_inst      IN institution.id_institution%TYPE,
        i_soft      IN software.id_software%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name           VARCHAR2(64) := 'TO_CHAR_INSTTIMEZONE(1)';
        l_formatted_timestamp VARCHAR2(4000);
        l_error               t_error_out;
    BEGIN
        g_error := 'CALL TO_CHAR_INSTTIMEZONE';
        -- Format timestamp
        IF to_char_insttimezone(i_lang      => NULL,
                                i_prof      => profissional(NULL, i_inst, i_soft),
                                i_timestamp => i_timestamp,
                                i_mask      => i_mask,
                                o_string    => l_formatted_timestamp,
                                o_error     => l_error)
        THEN
            RETURN correct_date(l_formatted_timestamp);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHAR_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END to_char_insttimezone;

    /*
    * Applies the to_char function to a timestamp, after converting it to the professional institution's timezone.
    * 
    * @param i_lang       Language ID
    * @param i_prof       Professional
    * @param i_timestamp  Timestamp
    * @param i_mask       Mask to use for formatting the timestamp
    * 
    * @return Formatted timestamp 
    *
    * @author José Silva
    * @version alpha
    * @since 2008/01/16
    */
    FUNCTION to_char_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2,
        i_timezone  IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name           VARCHAR2(64) := 'TO_CHAR_INSTTIMEZONE(1)';
        l_formatted_timestamp VARCHAR2(4000);
        l_error               t_error_out;
    BEGIN
        g_error := 'CALL TO_CHAR_INSTTIMEZONE';
        -- Format timestamp
        IF to_char_insttimezone(i_lang      => i_lang,
                                i_prof      => i_prof,
                                i_timestamp => i_timestamp,
                                i_mask      => i_mask,
                                i_timezone  => i_timezone,
                                o_string    => l_formatted_timestamp,
                                o_error     => l_error)
        THEN
            RETURN correct_date(l_formatted_timestamp);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHAR_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END to_char_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_lang         Language identifier.
    * @param i_prof         Professional
    * @param i_timestamp    Timestamp to truncate
    * @oaram i_format       Format (like in trunc)
    * @param o_timestamp    Truncated timestamp
    * @param o_error        Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * ORA-01878 proof
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/09
    */
    FUNCTION trunc_insttimezone
    (
        i_lang      IN VARCHAR2,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2 DEFAULT 'DD',
        i_timezone  IN VARCHAR2,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'TRUNC_INSTTIMEZONE(1)';
        l_timezone  timezone_region.timezone_region%TYPE;
        l_format    VARCHAR2(200);
    
        l_timestamp_base TIMESTAMP;
        l_timestamp      TIMESTAMP WITH TIME ZONE;
        k_mask CONSTANT VARCHAR2(0200 CHAR) := 'yyyymmddhh24miss TZR';
    
    BEGIN
        g_error  := 'GET FORMAT';
        l_format := nvl(i_format, 'DD');
    
        g_error := 'TEST TIMESTAMP';
        IF i_timestamp IS NOT NULL
        THEN
            IF (i_timezone IS NULL)
            THEN
                g_error := 'CALL GET_TIMEZONE';
                -- Get timezone to use
                IF NOT get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                l_timezone := i_timezone;
            END IF;
        
            g_error := 'TRUNCATE';
            -- Truncate timestamp
            IF l_timezone IS NOT NULL
            THEN
                IF upper(l_format) = 'SS'
                THEN
                    o_timestamp := to_timestamp_tz(to_char_insttimezone(i_prof, i_timestamp, k_mask), k_mask);
                
                ELSE
                    set_dst_time_check_off;
                    --l_timestamp      :=i_timestamp at TIME ZONE l_timezone;
                
                    -- instruction should not be changed, former code was having error 1858
                    -- Bug oracle?
                    SELECT i_timestamp at TIME ZONE (SELECT l_timezone
                                                       FROM dual)
                      INTO l_timestamp
                      FROM dual;
                    --
                
                    l_timestamp_base := CAST(trunc(l_timestamp, l_format) AS TIMESTAMP with local time zone);
                    o_timestamp      := from_tz_dst(i_lang      => i_lang,
                                                    i_timestamp => l_timestamp_base,
                                                    i_timezone  => l_timezone);
                    set_dst_time_check_on;
                END IF;
            END IF;
        ELSE
            o_timestamp := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_timestamp := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTTIMEZONE',
                                              o_error);
            RETURN FALSE;
    END trunc_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_prof         Professional
    * @param i_timestamp    Timestamp to truncate
    * @param i_format       Format (like in trunc)
    * 
    * @return Truncated timestamp
    *
    * @author Sofia Mendes
    * @version 2.7.3
    * @since 2018/05/03
    */
    FUNCTION trunc_insttimezone
    (
        i_lang      IN VARCHAR2,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2 DEFAULT 'DD',
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'TRUNC_INSTTIMEZONE(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate    
        RETURN trunc_insttimezone(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_timestamp => i_timestamp,
                                  i_format    => i_format,
                                  i_timezone  => NULL,
                                  o_timestamp => o_timestamp,
                                  o_error     => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTTIMEZONE',
                                              o_error);
            RETURN FALSE;
    END trunc_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_prof         Professional
    * @param i_timestamp    Timestamp to truncate
    * @param i_format       Format (like in trunc)
    * 
    * @return Truncated timestamp
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/09
    */
    FUNCTION trunc_insttimezone
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2 DEFAULT 'DD'
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_func_name VARCHAR2(64) := 'TRUNC_INSTTIMEZONE(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate    
        IF trunc_insttimezone(i_lang      => NULL,
                              i_prof      => i_prof,
                              i_timestamp => i_timestamp,
                              i_format    => i_format,
                              i_timezone  => NULL,
                              o_timestamp => l_timestamp,
                              o_error     => l_error)
        THEN
            RETURN l_timestamp;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END trunc_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_prof         Professional
    * @param i_timestamp    Timestamp to truncate
    * @param i_format       Format (like in trunc)
    * 
    * @return Truncated timestamp
    *
    * @author Sofia Mendes
    * @version 2.7.3
    * @since 2018/05/03
    */
    FUNCTION trunc_insttimezone
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2,
        i_timezone  IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_func_name VARCHAR2(64) := 'TRUNC_INSTTIMEZONE(4)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate    
        IF trunc_insttimezone(i_lang      => NULL,
                              i_prof      => i_prof,
                              i_timestamp => i_timestamp,
                              i_format    => i_format,
                              i_timezone  => i_timezone,
                              o_timestamp => l_timestamp,
                              o_error     => l_error)
        THEN
            RETURN l_timestamp;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END trunc_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timestamp    Timestamp to truncate
    * @param i_format       Format (like in trunc)
    * 
    * @return Truncated timestamp
    *
    * @author Susana Seixas
    * @version alpha
    * @since 2007/08/14
    */
    FUNCTION trunc_insttimezone
    (
        i_inst      IN institution.id_institution%TYPE,
        i_soft      IN software.id_software%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2 DEFAULT 'DD'
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_func_name VARCHAR2(64) := 'TRUNC_INSTTIMEZONE(2)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate    
        IF trunc_insttimezone(i_lang      => NULL,
                              i_prof      => profissional(NULL, i_inst, i_soft),
                              i_timestamp => i_timestamp,
                              i_format    => i_format,
                              i_timezone  => NULL,
                              o_timestamp => l_timestamp,
                              o_error     => l_error)
        THEN
            RETURN l_timestamp;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTIMEZONE',
                                              l_error);
            RETURN NULL;
    END trunc_insttimezone;

    /*
    * Truncates a timestamp using the institution's timezone.
    * 
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timestamp    Timestamp to truncate
    * @param i_format       Format (like in trunc)
    * 
    * @return Truncated timestamp
    *
    * @author Sofia Mendes
    * @version 2.6.0.5.2
    * @since 11-Mar-2011
    */
    FUNCTION trunc_insttimezone_str
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_format    IN VARCHAR2 DEFAULT 'DD'
    ) RETURN VARCHAR2 IS
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
        l_str       VARCHAR2(4000);
    BEGIN
        g_date_hour_send_format := pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_prof.institution, i_prof.software);
    
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate    
        IF trunc_insttimezone(i_lang      => NULL,
                              i_prof      => i_prof,
                              i_timestamp => i_timestamp,
                              i_format    => i_format,
                              i_timezone  => NULL,
                              o_timestamp => l_timestamp,
                              o_error     => l_error)
        THEN
            l_str := to_char(l_timestamp, g_date_hour_send_format);
            RETURN correct_date(l_str);
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TRUNC_INSTTIMEZONE_STR',
                                              l_error);
            RETURN NULL;
    END trunc_insttimezone_str;

    /*
    * Gets the time zone to use for a given professional.
    * The time zone region indicated by i_timezone has precedence over the professional institution's timezone.
    * 
    * @param i_lang        Language identifier.
    * @param i_prof        Professional
    * @param i_timezone    Preferred time zone (or NULL)
    * @param o_timezone    Time zone to use
    * @param o_error  Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/09
    */

    FUNCTION get_timezone_region(i_institution IN NUMBER) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(1000 CHAR);
    BEGIN
    
        SELECT b.timezone_region
          BULK COLLECT
          INTO tbl_return
          FROM institution a
          JOIN timezone_region b
            ON a.id_timezone_region = b.id_timezone_region
         WHERE a.id_institution = nvl(i_institution, 0);
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_timezone_region;

    -- *******************************************************
    FUNCTION get_timezone_base
    (
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_timezone VARCHAR2(1000 CHAR);
    BEGIN
    
        IF g_last_institution IS NOT NULL
           AND g_last_timezone IS NOT NULL
           AND g_last_institution = i_prof.institution
           AND i_timezone IS NULL
        THEN
            l_timezone := g_last_timezone;
        ELSIF i_timezone IS NOT NULL
        THEN
            -- Override timezone and don't save time zone
            l_timezone := i_timezone;
        ELSE
            g_error := 'GET TIME ZONE';
            -- Get institution's timezone
            l_timezone := get_timezone_region(i_institution => i_prof.institution);
        
            -- Save timezone information   
            g_last_institution := i_prof.institution;
            g_last_timezone    := l_timezone;
        END IF;
    
        RETURN l_timezone;
    
    END get_timezone_base;

    FUNCTION get_timezone
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL,
        o_timezone OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_TIMEZONE';
    BEGIN
        g_error := 'CHECK TIMEZONE CACHE';
    
        o_timezone := get_timezone_base(i_prof => i_prof, i_timezone => i_timezone);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_timezone := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEZONE',
                                              o_error);
            RETURN FALSE;
    END get_timezone;

    /*
    * Gets the time zone to use for a given professional.
    * The time zone region indicated by i_timezone has precedence over the professional institution's timezone.
    * 
    * @param i_lang        Language identifier.
    * @param i_prof        Professional
    * 
    * @return Timezone for given institution
    *
    * @author Fábio Oliveira
    * @since 2009/01/23
    */
    FUNCTION get_timezone
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_timezone timezone_region.timezone_region%TYPE;
        l_error    t_error_out;
        --l_ret      BOOLEAN;
    BEGIN
        g_error    := 'GET TIME ZONE';
        l_timezone := get_timezone_base(i_prof => i_prof, i_timezone => i_timezone);
        --l_ret   := get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => l_error);
    
        RETURN correct_date(l_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMEZONE',
                                              l_error);
            RETURN NULL;
    END get_timezone;

    /*
    * Converts a string to a timestamp and then truncates it, using the desired format.
    * 
    * @param i_lang        Language identifier
    * @param i_prof        Professional
    * @param i_timestamp   String representing the timestamp
    * @param i_timezone    Timezone to use (or NULL to use the institution's default)
    * @param i_format      Format to use (like in trunc)
    * @param o_timestamp   Truncated timestamp
    * @param o_error       Error message, if an error occurred
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/10
    */
    FUNCTION get_string_trunc_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN VARCHAR2,
        i_timezone  IN VARCHAR2 DEFAULT NULL,
        i_format    IN VARCHAR2 DEFAULT 'DD',
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_STRING_TRUNC_TSTZ';
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ';
        -- Convert to timestamp      
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp,
                               i_timezone  => i_timezone,
                               o_timestamp => l_timestamp,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TRUNC_INSTTIMEZONE';
        -- Truncate timestamp
        IF NOT trunc_insttimezone(i_lang      => i_lang,
                                  i_prof      => i_prof,
                                  i_timestamp => l_timestamp,
                                  i_format    => i_format,
                                  i_timezone  => NULL,
                                  o_timestamp => o_timestamp,
                                  o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_timestamp := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_TRUNC_TSTZ',
                                              o_error);
            RETURN FALSE;
    END get_string_trunc_tstz;

    /*
    * Converts the strings that represent timestamps to timestamps with time zone
    * and then calculates the number of days between the two timestamps.
    * 
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_timestamp_1    String representing the first timestamp.
    * @param i_timezone_1     Timezone to use for converting the first timestamp.
    * @param i_timestamp_2    String representing the second timestamp.
    * @param i_timezone_2     Timezone to use for converting the secnnd timestamp.    
    * @param o_days_diff      Number of days between the two timestamps.
    * @param o_error          Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/10
    */
    FUNCTION get_timestamp_diff_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_timestamp_1 IN VARCHAR2,
        i_timezone_1  IN VARCHAR2 DEFAULT NULL,
        i_timestamp_2 IN VARCHAR2,
        i_timezone_2  IN VARCHAR2 DEFAULT NULL,
        o_days_diff   OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(64) := 'GET_TIMESTAMP_DIFF_STR';
        l_timestamp_1 TIMESTAMP WITH TIME ZONE;
        l_timestamp_2 TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ FOR l_timestamp_1';
        -- Convert first timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp_1,
                               i_timezone  => i_timezone_1,
                               o_timestamp => l_timestamp_1,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_timestamp_2';
        -- Convert second timestamp
        IF NOT get_string_tstz(i_lang      => i_lang,
                               i_prof      => i_prof,
                               i_timestamp => i_timestamp_2,
                               i_timezone  => i_timezone_2,
                               o_timestamp => l_timestamp_2,
                               o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_TIMESTAMP_DIFF';
        -- Obtain difference between timestamps
        IF NOT get_timestamp_diff(i_lang        => i_lang,
                                  i_timestamp_1 => l_timestamp_1,
                                  i_timestamp_2 => l_timestamp_2,
                                  o_days_diff   => o_days_diff,
                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_days_diff := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_DIFF_STR',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_diff_str;

    /*
    * Calculates the number of minutes since the start of the day.
    * 
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_timestamp      Timestamp.
    * @param o_minutes        Number of minutes.
    * @param o_error          Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/10
    */
    FUNCTION get_min_since_day_start_tsz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_minutes   OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_MINUTES_SINCE_TRUNC_TSZ(1)';
        l_timezone  timezone_region.timezone_region%TYPE;
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_hours     NUMBER := 0;
        l_minutes   NUMBER := 0;
    BEGIN
        g_error := 'TEST TIMESTAMP';
        IF i_timestamp IS NOT NULL
        THEN
            g_error := 'CALL GET_TIMEZONE';
            -- Get timezone
            IF NOT get_timezone(i_lang     => i_lang,
                                i_prof     => i_prof,
                                i_timezone => NULL,
                                o_timezone => l_timezone,
                                o_error    => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error     := 'CONVERT TIMESTAMP';
            l_timestamp := i_timestamp at TIME ZONE l_timezone;
        
            g_error   := 'EXTRACT MINUTES';
            l_minutes := extract(minute FROM l_timestamp);
        
            g_error := 'EXTRACT HOURS';
            l_hours := extract(hour FROM l_timestamp);
        
            g_error   := 'GET MINUTES';
            o_minutes := l_hours * 60 + l_minutes;
        ELSE
            o_minutes := NULL;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_minutes := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MIN_SINCE_DAY_START_TSZ',
                                              o_error);
            RETURN FALSE;
    END get_min_since_day_start_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_inst   Institution
    * @param i_soft   Software
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/27
    */
    FUNCTION dt_chr_year_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_YEAR_SHORT_TSZ(1)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        -- Format timestamp
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'DATE_FORMAT_YEAR_SHORT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_YEAR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_year_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_SHORT parameter.
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/27
    */
    FUNCTION dt_chr_year_short_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_YEAR_SHORT_TSZ(2)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_YEAR_SHORT_TSZ';
        -- Format timestamp
        RETURN dt_chr_year_short_tsz(i_lang => i_lang,
                                     i_date => i_date,
                                     i_inst => i_prof.institution,
                                     i_soft => i_prof.software);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_YEAR_SHORT_TSZ',
                                              l_error);
            RETURN NULL;
    END dt_chr_year_short_tsz;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/27
    */
    FUNCTION dt_chr_year_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'DT_CHR_YEAR_SHORT_STR(3)';
        l_timestamp TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'GET TIMESTAMP';
        -- Convert timestamp
        IF get_string_tstz(i_lang      => i_lang,
                           i_prof      => profissional(NULL, i_inst, i_soft),
                           i_timestamp => i_date,
                           i_timezone  => i_timezone,
                           o_timestamp => l_timestamp,
                           o_error     => l_error)
        THEN
            g_error := 'CALL DT_CHR_YEAR_SHORT_TSZ';
            -- Format timestamp
            RETURN dt_chr_year_short_tsz(i_lang => i_lang, i_date => l_timestamp, i_inst => i_inst, i_soft => i_soft);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_YEAR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_year_short_str;

    /*
    * Formats a timestamp according to DATE_FORMAT_YEAR_SHORT parameter.
    * 
    * @param i_lang       Language identifier.
    * @param i_date       Timestamp
    * @param i_inst       Institution
    * @param i_soft       Software
    * @param i_timezone   Timezone
    * 
    * @return Formatted timestamp 
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/08/27
    */
    FUNCTION dt_chr_year_short_str
    (
        i_lang     IN language.id_language%TYPE,
        i_date     IN VARCHAR2,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DT_CHR_YEAR_SHORT_STR(4)';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DT_CHR_YEAR_SHORT_STR';
        -- Format timestamp
        RETURN dt_chr_year_short_str(i_lang     => i_lang,
                                     i_date     => i_date,
                                     i_inst     => i_prof.institution,
                                     i_soft     => i_prof.software,
                                     i_timezone => i_timezone);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DT_CHR_YEAR_SHORT_STR',
                                              l_error);
            RETURN NULL;
    END dt_chr_year_short_str;

    FUNCTION diff_timestamp
    (
        i_left  TIMESTAMP WITH LOCAL TIME ZONE,
        i_right TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_res   NUMBER;
        l_error t_error_out;
    BEGIN
        g_error := 'CALC DIFF';
        SELECT extract(DAY FROM val) + extract(hour FROM val) / 24 + extract(minute FROM val) / 1440 +
               extract(SECOND FROM val) / 86400
          INTO l_res
          FROM (SELECT i_left - i_right val
                  FROM dual);
        RETURN l_res;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DIFF_TIMESTAMP',
                                              l_error);
            RETURN NULL;
    END diff_timestamp;

    /*
    * Gets the list of months and week days.
    * @param i_lang           Language identifier.
    * @param o_months         List of months.
    * @param o_week_days      List of week days.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/04/20
    */
    FUNCTION get_months_and_days
    (
        i_lang      IN language.id_language%TYPE,
        o_months    OUT pk_types.cursor_type,
        o_week_days OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_day_prefix VARCHAR2(13) := 'SCH_MONTHVIEW';
        l_msg_week_days  table_varchar := table_varchar('DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB');
    
    BEGIN
        -- Months
        g_error := 'OPEN O_MONTHS';
        OPEN o_months FOR
            SELECT month_desc, short_month
              FROM (SELECT LEVEL id_month,
                           l.nls_code,
                           to_char(to_date(LEVEL, 'MM'), 'Month', 'NLS_DATE_LANGUAGE = ' || '''' || l.nls_code || '''') month_desc,
                           to_char(to_date(LEVEL, 'MM'), 'Mon', 'NLS_DATE_LANGUAGE = ' || '''' || l.nls_code || '''') short_month
                      FROM (SELECT nls_code
                              FROM LANGUAGE
                             WHERE id_language = i_lang) l
                    CONNECT BY LEVEL <= 12)
             ORDER BY id_month;
    
        -- Weekdays
        g_error := 'OPEN O_WEEK_DAYS';
        OPEN o_week_days FOR
            SELECT desc_message, upper(substr(desc_message, 1, 1)) abrv
              FROM (SELECT /*+ opt_estimate(table t rows=1) */
                     rownum id_day,
                     pk_message.get_message(i_lang, l_msg_day_prefix || '_' || t.column_value) desc_message
                      FROM TABLE(CAST(l_msg_week_days AS table_varchar)) t)
             ORDER BY id_day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_MONTHS_AND_DAYS',
                                              o_error);
            pk_types.open_my_cursor(o_months);
            pk_types.open_my_cursor(o_week_days);
        
            RETURN FALSE;
    END get_months_and_days;

    /*
    *  String timestamp to string timestamp with institution timezone
    *  Used to save a data obtained from UI adding institution timezone as string.
    *
    * @param      I_LANG            Prefered language ID for this professional
    * @param      I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param      I_STR_TIMESTAMP   String timestamp to input
    *
    * @return     String timestamp with institution TZR
    *
    * @author     Ariel Geraldo Machado
    * @version    1.0 (v2.4.3)
    * @since      2008/05/23
    */
    FUNCTION get_string_strtimezone
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_str_timestamp IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_timezone timezone_region.timezone_region%TYPE;
        l_return   VARCHAR2(100);
        l_error    t_error_out;
    BEGIN
        IF i_str_timestamp IS NOT NULL
        THEN
            -- Gets timezone to use
            g_error := 'CALL GET_TIMEZONE';
            IF get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => l_error)
            THEN
                -- Add institution timezone to input string
                g_error  := 'GET_TIMESTAMP';
                l_return := i_str_timestamp || ' ' || l_timezone;
            ELSE
                l_return := NULL;
            END IF;
        ELSE
            l_return := NULL;
        END IF;
    
        RETURN correct_date(l_return);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_STRTIMEZONE',
                                              l_error);
            RETURN NULL;
    END get_string_strtimezone;

    /** 
    * Get string with current timestamp in format 'YYYYMMDDhh24miss'.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_TIMESTAMP_STR              Converted timestamp
    * @param      O_ERROR                      Error message
    *
    * @return     TRUE if successfull. FALSE otherwise.
    
    * @author     José Brito
    * @version    0.1
    * @since      2009/01/13
    */
    FUNCTION get_current_timestamp_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error         := 'CONVERT CURRENT TIMESTAMP';
        o_timestamp_str := to_char(current_timestamp, g_dateformat);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CURRENT_TIMESTAMP_STR',
                                              o_error);
            RETURN FALSE;
    END get_current_timestamp_str;

    /*
    /********************************************************************************************
    * Applies the to_char function to a timestamp.  
    * Important! This function doesn't convert the i_timestamp to institution time zone. 
    * You normally should use to_char_insttimezone().
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_timestamp              Timestamp
    * @param i_mask                   Mask to use for formatting the timestamp
    *
    * @param o_string                 Formatted timestamp.
    * @param o_error                  Error message, if an error occurred.
    * 
    * @return                         True if successful, false otherwise. 
    *
    * @author                         Ariel Geraldo Machado  (based on Nuno Guerreiro's code)                                                                                   
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/02                                                                                               
    ********************************************************************************************/
    FUNCTION to_char_timezone
    (
        i_lang      IN language.id_language%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2,
        o_string    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nls_code language.nls_code%TYPE;
    BEGIN
    
        IF i_lang IS NOT NULL
        THEN
            -- Get NLS code
            g_error    := 'GET NLS_CODE';
            l_nls_code := get_nls_code(i_lang);
        END IF;
    
        g_error := 'FORMAT TIMESTAMP';
        -- Format date
        IF l_nls_code IS NULL
        THEN
            o_string := to_char(i_timestamp, i_mask);
        ELSE
            o_string := to_char(i_timestamp, i_mask, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            o_string := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHAR_TIMEZONE',
                                              o_error);
            RETURN FALSE;
    END to_char_timezone;

    /********************************************************************************************
    * Applies the to_char function to a timestamp.  
    * Important! This function doesn't convert the i_timestamp to institution time zone. 
    * You normally should use to_char_insttimezone().
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_timestamp              Timestamp
    * @param i_mask                   Mask to use for formatting the timestamp
    *
    * @return                         A formatted string value
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado  (based on Nuno Guerreiro's code)                                                                                   
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/02/02                                                                                               
    ********************************************************************************************/
    FUNCTION to_char_timezone
    (
        i_lang      IN language.id_language%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_mask      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_formatted_timestamp VARCHAR2(4000);
        l_error               t_error_out;
    BEGIN
        g_error := 'CALL TO_CHAR_TIMEZONE';
        -- Format timestamp
        IF to_char_timezone(i_lang      => i_lang,
                            i_timestamp => i_timestamp,
                            i_mask      => i_mask,
                            o_string    => l_formatted_timestamp,
                            o_error     => l_error)
        THEN
            RETURN correct_date(l_formatted_timestamp);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TO_CHAR_TIMEZONE',
                                              l_error);
            RETURN NULL;
    END to_char_timezone;

    /********************************************************************************************
    * This function returns a value from 1 to 7 identifying the day of the week, where
    * Monday is 1 and Sunday is 7.
    * Note: In Oracle, depending on the NLS_Territory setting, different days of the week are 1.
    * Examples:
    *   U.S., Canada, Monday = 2;  Most European countries, Monday = 1;
    *   Most Middle-Eastern countries, Monday = 3.
    *   For Bangladesh, Monday = 4.
    *
    * @param i_date          Input date parameter
    *
    * @return                Return the day of the week
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.5
    * @since                 2009/03/03
    ********************************************************************************************/
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER IS
    BEGIN
        RETURN 1 + MOD(to_number(to_char(i_date, 'J')), 7);
    END week_day_standard;

    /********************************************************************************************
    * This function returns a date with next week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with next week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION next_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    
        l_next_day TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_next_day := i_date;
    
        IF week_day_standard(l_next_day) = i_weekday_standard
        THEN
            l_next_day := l_next_day + 7;
            RETURN l_next_day;
        ELSE
            WHILE week_day_standard(l_next_day) != i_weekday_standard
            LOOP
                l_next_day := l_next_day + 1;
            END LOOP;
            RETURN l_next_day;
        END IF;
    END next_day_standard;

    /********************************************************************************************
    * This function returns a date with previous week day applied to an input date
    *
    * @param i_date          Input date parameter
    * @param i_weekday_standard   Input weekday 
    *
    * @return                Return the date with previous week day
    * 
    * @raises                
    *
    * @author                Nuno Miguel Ferreira
    * @version               V.2.4.3
    * @since                 2008/12/03
    ********************************************************************************************/
    FUNCTION previous_day_standard
    (
        i_date             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_weekday_standard IN NUMBER
    ) RETURN DATE IS
        l_offset       NUMBER;
        l_previous_day TIMESTAMP WITH LOCAL TIME ZONE;
        l_a            NUMBER;
        l_b            NUMBER;
    BEGIN
        l_offset := to_number(to_char(g_ref_date, 'D'));
    
        l_a := i_weekday_standard + l_offset;
    
        l_b := MOD(l_a, 7);
        IF l_b = 0
        THEN
            l_b := 7;
        END IF;
    
        SELECT CAST(next_day(pk_date_utils.add_days_to_tstz(i_date, -8), l_b) AS TIMESTAMP WITH LOCAL TIME ZONE)
          INTO l_previous_day
          FROM dual;
        RETURN l_previous_day;
    END previous_day_standard;

    /**********************************************************************************************
    * Returns the months of year. To be used on multichoices. the flg_select is 'Y' to the month
    * correspondent to the i_date parameter
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_date                          Date to be considered to the default month
    * @param o_months                        Output data
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.4
    * @since                                 2009/06/22
    **********************************************************************************************/
    FUNCTION get_months_with_default
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN VARCHAR2,
        o_months OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_MONTHS_AND_DAYS';
        l_date      TIMESTAMP WITH TIME ZONE;
        l_month     VARCHAR2(2);
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ FOR i_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL TO_CHAR_INSTTIMEZZONE';
        IF NOT pk_date_utils.to_char_insttimezone(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => l_date,
                                                  i_mask      => 'MM',
                                                  o_string    => l_month,
                                                  o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET o_months FOR';
        OPEN o_months FOR
            SELECT data,
                   label,
                   CASE
                        WHEN to_number(data) = to_number(l_month) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END AS flg_select,
                   data AS order_field
              FROM (SELECT substr(code_message, 11) AS data, code_message, desc_message AS label
                      FROM sys_message sm
                     WHERE sm.id_language = i_lang
                       AND (code_message LIKE 'SCH_MONTH__' OR code_message LIKE 'SCH_MONTH___'))
             ORDER BY length(code_message) ASC, code_message;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_months);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_months_with_default;

    FUNCTION get_weekdays_with_default
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN VARCHAR2,
        o_weekdays OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_WEEKDAYS_BY_DEFAULT';
        l_weekdays  sch_reprules.weekdays%TYPE;
        l_week_days VARCHAR2(32);
        l_date      TIMESTAMP WITH TIME ZONE;
    BEGIN
        g_error := 'CALL GET_STRING_TSTZ FOR i_date';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error     := 'GET DAYS OF WEEK';
        l_week_days := to_char(week_day_standard(l_date /*to_date(i_dt_begin, 'yyyymmddhh24miss')*/));
    
        g_error := 'OPEN o_weekdays';
        OPEN o_weekdays FOR
            SELECT decode(code_message,
                          'SCH_MONTHVIEW_SEG',
                          1,
                          'SCH_MONTHVIEW_TER',
                          2,
                          'SCH_MONTHVIEW_QUA',
                          3,
                          'SCH_MONTHVIEW_QUI',
                          4,
                          'SCH_MONTHVIEW_SEX',
                          5,
                          'SCH_MONTHVIEW_SAB',
                          6,
                          7) data,
                   a.label,
                   decode(instr(l_week_days,
                                decode(code_message,
                                       'SCH_MONTHVIEW_SEG',
                                       1,
                                       'SCH_MONTHVIEW_TER',
                                       2,
                                       'SCH_MONTHVIEW_QUA',
                                       3,
                                       'SCH_MONTHVIEW_QUI',
                                       4,
                                       'SCH_MONTHVIEW_SEX',
                                       5,
                                       'SCH_MONTHVIEW_SAB',
                                       6,
                                       7)),
                          0,
                          pk_alert_constant.g_no,
                          NULL,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_select
              FROM (SELECT pk_message.get_message(i_lang, sm.code_message) AS label, code_message
                      FROM sys_message sm
                     WHERE sm.code_message IN ('SCH_MONTHVIEW_SEG',
                                               'SCH_MONTHVIEW_TER',
                                               'SCH_MONTHVIEW_QUA',
                                               'SCH_MONTHVIEW_QUI',
                                               'SCH_MONTHVIEW_SEX',
                                               'SCH_MONTHVIEW_SAB',
                                               'SCH_MONTHVIEW_DOM')
                       AND id_language = i_lang) a
             ORDER BY data;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_weekdays);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_weekdays_with_default;

    /********************************************************************************************
    * Add X months to a date.
    * When the resulting month has as many or fewer days than the initial month, and when the initial day of the month is greater 
    * than the number of days in the resulting month, then the resulting day should fall on the last day of the resulting month
    * When the resulting month has more days than the initial month, and when the initial day is the last day of the initial month, 
    * then the resulting day of the resulting month should be the same as the initial day.
    *
    * @param i_lang           language ID
    * @param i_prof           Professional identification
    * @param i_date           Input date
    * @param i_nr_of_months   Nr of months to add    
    * @param o_error          error message
    *
    * @return                 Timestamp with time zone
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/23    
    ********************************************************************************************/
    FUNCTION non_ansi_add_months
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN TIMESTAMP WITH TIME ZONE,
        i_nr_of_months IN INTEGER,
        o_error        OUT t_error_out
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_date TIMESTAMP WITH TIME ZONE;
    BEGIN
        l_date := add_months(i_date, i_nr_of_months);
        IF to_char(i_date, 'DD') < to_char(l_date, 'DD')
        THEN
            l_date := i_date + numtoyminterval(i_nr_of_months, 'month');
        END IF;
        RETURN l_date;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'NON_ANSI_ADD_MONTHS',
                                              o_error    => o_error);
    END non_ansi_add_months;

    /********************************************************************************************    
    * Returns the day short label correspondent to the inputed date.
    *
    * @param i_lang                           language ID
    * @param i_prof                           Professional identification       
    * @param i_date                           Date    
    * @param o_error                          error message
    *
    * @return                 success/fail
    * 
    * @raises                
    *
    * @author                Sofia Mendes
    * @version               V.2.5.4
    * @since                 2009/06/29    
    ********************************************************************************************/
    FUNCTION get_day_label
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2 IS
        l_weekday   NUMBER;
        l_day_msg   VARCHAR2(30 CHAR);
        l_day_label VARCHAR2(4000);
    BEGIN
        l_weekday := pk_date_utils.week_day_standard(i_date => i_date);
    
        l_day_msg := CASE
                         WHEN l_weekday = 1 THEN
                          g_msg_wday_1
                         WHEN l_weekday = 2 THEN
                          g_msg_wday_2
                         WHEN l_weekday = 3 THEN
                          g_msg_wday_3
                         WHEN l_weekday = 4 THEN
                          g_msg_wday_4
                         WHEN l_weekday = 5 THEN
                          g_msg_wday_5
                         WHEN l_weekday = 6 THEN
                          g_msg_wday_6
                         ELSE
                          g_msg_wday_7
                     END;
    
        SELECT pk_message.get_message(i_lang, sm.code_message)
          INTO l_day_label
          FROM sys_message sm
         WHERE sm.code_message = l_day_msg
           AND sm.id_language = i_lang;
        RETURN correct_date(l_day_label);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END get_day_label;

    /********************************************************************************************    
    * Returns the configuration first day of week
    *
    * @param i_prof   Professional identification       
    *
    * @return         Configuration first day of week; 1 - Monday; ...; 7 - Sunday;
    * 
    * @raises                
    *
    * @author         Alexandre Santos
    * @version        V.2.5.5
    * @since          2009/06/29    
    ********************************************************************************************/
    FUNCTION get_first_day_of_week(i_prof IN profissional) RETURN NUMBER IS
    BEGIN
        RETURN to_number(pk_sysconfig.get_config('FIRST_DAY_OF_WEEK', i_prof));
    END get_first_day_of_week;

    FUNCTION get_db_first_wk_day
    (
        i_date        IN TIMESTAMP WITH TIME ZONE,
        i_week_format IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_week_num     NUMBER;
        l_week_num_ant NUMBER;
        l_date         TIMESTAMP WITH TIME ZONE;
    BEGIN
        l_week_num := to_number(to_char(i_date, i_week_format));
    
        FOR i IN 1 .. 6
        LOOP
            l_date         := i_date - i;
            l_week_num_ant := to_number(to_char(l_date, i_week_format));
        
            IF (l_week_num_ant != l_week_num)
            THEN
                l_date := l_date + 1;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_date;
    END get_db_first_wk_day;

    /********************************************************************************************    
    * Returns the week number for the given date
    *
    * @param i_prof           Professional identification       
    * @param i_date           Date    
    * @param i_week_format    WW - current week number based on the first day of the year  
    *                         IW - current week number based on the configuration value for the first day of week
    * @return                 Date week number
    * 
    * @raises                
    *
    * @author                 Alexandre Santos
    * @version                V.2.5.5
    * @since                  2009/06/29    
    ********************************************************************************************/
    FUNCTION get_week_number
    (
        i_prof        IN profissional,
        i_date        IN TIMESTAMP WITH TIME ZONE,
        i_week_format IN VARCHAR2
    ) RETURN NUMBER IS
        l_wk_fmt_iw   VARCHAR2(2) := 'IW';
        l_wk_fmt_ww   VARCHAR2(2) := 'WW';
        l_day_fmt     VARCHAR2(1) := 'D';
        l_week_format VARCHAR2(2);
    
        l_first_day_cfg NUMBER;
        l_last_day_cfg  NUMBER;
    
        l_date_week_day_db  NUMBER;
        l_date_std_week_day NUMBER;
    
        l_cfg_first_week_day DATE;
        l_cfg_last_week_day  DATE;
        l_db_first_week_day  DATE;
        l_db_last_week_day   DATE;
    
        l_last_day_last_year  DATE;
        l_last_day_curr_year  DATE;
        l_last_week_last_year NUMBER;
        l_last_week_curr_year NUMBER;
    
        l_week_num NUMBER;
    
        l_cfg_error EXCEPTION;
    BEGIN
        IF (i_week_format IS NULL)
        THEN
            l_week_format := pk_sysconfig.get_config('WEEK_DEFAULT_FORMAT', i_prof);
        ELSE
            l_week_format := i_week_format;
        END IF;
    
        IF (l_week_format = l_wk_fmt_iw)
        THEN
            l_first_day_cfg := pk_date_utils.get_first_day_of_week(i_prof);
        ELSIF (l_week_format = l_wk_fmt_ww)
        THEN
            l_first_day_cfg := NULL;
        ELSE
            RAISE l_cfg_error;
        END IF;
    
        IF (l_first_day_cfg IS NULL)
        THEN
            l_week_num := to_number(to_char(i_date, l_wk_fmt_ww));
        ELSIF (l_first_day_cfg BETWEEN 1 AND 7)
        THEN
            IF (l_first_day_cfg = 1)
            THEN
                l_last_day_cfg := 7;
            ELSE
                l_last_day_cfg := l_first_day_cfg - 1;
            END IF;
        
            l_date_week_day_db  := to_number(to_char(i_date, l_day_fmt));
            l_date_std_week_day := pk_date_utils.week_day_standard(i_date);
        
            --Config week
            IF (l_first_day_cfg = 1)
            THEN
                IF (l_date_std_week_day = 1)
                THEN
                    l_cfg_first_week_day := i_date;
                ELSE
                    l_cfg_first_week_day := i_date - (l_date_std_week_day - 1);
                END IF;
            ELSE
                IF (l_date_std_week_day < l_first_day_cfg)
                THEN
                    l_cfg_first_week_day := i_date - (7 - (l_first_day_cfg + 1 - (l_date_std_week_day + 1)));
                ELSIF (l_date_std_week_day = l_first_day_cfg)
                THEN
                    l_cfg_first_week_day := i_date;
                ELSE
                    l_cfg_first_week_day := i_date - (l_date_std_week_day - l_first_day_cfg);
                END IF;
            END IF;
        
            l_cfg_last_week_day := l_cfg_first_week_day + 6;
        
            --Database week
            l_db_first_week_day := get_db_first_wk_day(i_date, l_week_format);
            l_db_last_week_day  := l_db_first_week_day + 6;
        
            l_week_num := to_number(to_char(i_date, l_wk_fmt_iw));
        
            IF (l_cfg_first_week_day < l_db_first_week_day)
            THEN
                l_week_num := l_week_num - 1;
            ELSIF (l_cfg_last_week_day > l_db_last_week_day AND i_date > l_db_last_week_day)
            THEN
                l_week_num := l_week_num + 1;
            END IF;
        
            l_last_day_last_year  := to_date(to_char(to_number(to_char(i_date, 'YYYY')) - 1) || '-12-31', 'YYYY-MM-DD');
            l_last_day_curr_year  := to_date(to_char(i_date, 'YYYY') || '-12-31', 'YYYY-MM-DD');
            l_last_week_last_year := to_number(to_char(l_last_day_last_year, l_wk_fmt_iw));
            l_last_week_curr_year := to_number(to_char(l_last_day_curr_year, l_wk_fmt_ww));
        
            IF (l_last_week_last_year = 1)
            THEN
                l_last_week_last_year := to_number(to_char(l_last_day_last_year, l_wk_fmt_ww)) - 1;
            END IF;
        
            IF (l_week_num < 1)
            THEN
                l_week_num := l_last_week_last_year;
            ELSIF (l_week_num > l_last_week_curr_year)
            THEN
                l_week_num := 1;
            END IF;
        ELSE
            RAISE l_cfg_error;
        END IF;
    
        RETURN l_week_num;
    END get_week_number;

    /**********************************************************************************************
    * Returns the month-year (or current month-year) on the format Mon-YYYY
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_timestamp                Timestamp with local timezone
    *
    * @return                           formated date
    *                        
    * @author                           Paulo Teixeira
    * @version                          1.0
    * @since                            2010/07/29
    **********************************************************************************************/
    FUNCTION get_month_year
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp
    ) RETURN VARCHAR2 IS
        l_nls_code language.nls_code%TYPE;
        l_string   sys_config.value%TYPE;
        l_format   sys_config.value%TYPE := pk_sysconfig.get_config('DATE_MONTH_YEAR_FORMAT',
                                                                    i_prof.institution,
                                                                    i_prof.software);
    BEGIN
        IF i_lang IS NOT NULL
        THEN
            -- Get NLS code
            g_error    := 'GET NLS_CODE';
            l_nls_code := get_nls_code(i_lang);
        END IF;
    
        g_error := 'FORMAT TIMESTAMP';
        -- Format date
        IF l_nls_code IS NULL
        THEN
            l_string := to_char(i_timestamp, l_format);
        ELSE
            l_string := to_char(i_timestamp, l_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''');
        END IF;
    
        RETURN correct_date(l_string);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Returns the month-year (or current month-year) on the format Mon-YYYY
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_date                     Date
    *
    * @return                           formated date
    *                        
    * @author                           Elisabete Bugalho
    * @version                          1.0
    * @since                            2013/05/09
    **********************************************************************************************/
    FUNCTION get_month_year
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN DATE
    ) RETURN VARCHAR2 IS
        l_nls_code language.nls_code%TYPE;
        l_string   sys_config.value%TYPE;
        l_format   sys_config.value%TYPE := pk_sysconfig.get_config('DATE_MONTH_YEAR_FORMAT',
                                                                    i_prof.institution,
                                                                    i_prof.software);
    BEGIN
        IF i_lang IS NOT NULL
        THEN
            -- Get NLS code
            g_error    := 'GET NLS_CODE';
            l_nls_code := get_nls_code(i_lang);
        END IF;
    
        g_error := 'FORMAT TIMESTAMP';
        -- Format date
        IF l_nls_code IS NULL
        THEN
            l_string := to_char(i_date, l_format);
        ELSE
            l_string := to_char(i_date, l_format, 'NLS_DATE_LANGUAGE=''' || l_nls_code || '''');
        END IF;
    
        RETURN correct_date(l_string);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    /********************************************************************************************    
    * Returns elapsed time in hours
    *
    * @param i_lang           Language id
    * @param i_date           Date    
    * @return                 Number of hours
    * 
    * @raises                
    *
    * @author                 Alexandre Santos
    * @version                V.2.5.1
    * @since                  2010/08/31    
    ********************************************************************************************/
    FUNCTION get_elapsed_hours
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_days    NUMBER;
        l_hours   NUMBER;
        l_minutes NUMBER;
        l_seconds NUMBER;
        l_error   t_error_out;
    BEGIN
        IF NOT pk_date_utils.get_timestamp_diff_sep(i_lang        => i_lang,
                                                    i_timestamp_1 => current_timestamp,
                                                    i_timestamp_2 => i_date,
                                                    o_days        => l_days,
                                                    o_hours       => l_hours,
                                                    o_minutes     => l_minutes,
                                                    o_seconds     => l_seconds,
                                                    o_error       => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN correct_date(l_days * 24 + l_hours || ':' || to_char(to_date(l_minutes, 'mi'), 'mi'));
    END get_elapsed_hours;

    /**********************************************************************************************
    * Get the start and end dates of a given time period (ex. TODAY, LASTYEAR,...)    
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param i_scale                  Time Scale: THISYEAR, THISMONTH, THISWEEK   
    *                                             TODAY, LASTDAY 
    *                                             LASTWEEK, LASTMONTH, LASTYEAR
    * @param o_start_date             Time interval start date
    * @param o_end_date               Time interval end date
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          02-Feb-2011 
    **********************************************************************************************/
    FUNCTION get_scale_dates
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scale      IN VARCHAR2,
        o_start_date OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'get start and end dates. i_scale: ' || i_scale;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => 'get_scale_dates',owner => g_package_owner);
    
        IF (i_scale = g_scale_thisyear)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_year_format);
            o_end_date   := pk_date_utils.add_to_ltstz(i_timestamp => o_start_date,
                                                       i_amount    => 1,
                                                       i_unit      => g_scale_year);
            --THIS MONTH
        ELSIF (i_scale = g_scale_thismonth)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_month_format);
            o_end_date   := pk_date_utils.add_to_ltstz(i_timestamp => o_start_date,
                                                       i_amount    => 1,
                                                       i_unit      => g_scale_month);
            --THIS WEEK
        ELSIF (i_scale = g_scale_thisweek)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_week_format);
            o_end_date   := pk_date_utils.add_days_to_tstz(o_start_date, 7);
        ELSIF (i_scale = g_scale_today)
        THEN
            o_start_date := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp);
            o_end_date   := pk_date_utils.add_days_to_tstz(o_start_date, 1);
        
        ELSIF (i_scale = g_scale_lastday)
        THEN
            o_end_date   := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp);
            o_start_date := pk_date_utils.add_days_to_tstz(o_end_date, -1);
        ELSIF (i_scale = g_scale_lastweek)
        THEN
            o_end_date   := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_week_format);
            o_start_date := pk_date_utils.add_days_to_tstz(o_end_date, -6);
        ELSIF (i_scale = g_scale_lastmonth)
        THEN
            o_end_date   := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_month_format);
            o_start_date := pk_date_utils.add_to_ltstz(i_timestamp => o_end_date,
                                                       i_amount    => -1,
                                                       i_unit      => g_scale_month);
        
        ELSIF i_scale = g_scale_last24h
        THEN
        
            o_end_date   := current_timestamp;
            o_start_date := pk_date_utils.add_to_ltstz(i_timestamp => o_end_date, i_amount => -24, i_unit => 'HOUR');
        
        ELSIF i_scale = g_scale_last48h
        THEN
            o_end_date   := current_timestamp;
            o_start_date := pk_date_utils.add_to_ltstz(i_timestamp => o_end_date, i_amount => -48, i_unit => 'HOUR');
        
        ELSIF (i_scale = g_scale_lastyear)
        THEN
            o_end_date   := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                             i_timestamp => current_timestamp,
                                                             i_format    => g_year_format);
            o_start_date := pk_date_utils.add_to_ltstz(i_timestamp => o_end_date,
                                                       i_amount    => -1,
                                                       i_unit      => g_scale_year);
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
                                              'GET_SCALE_DATES',
                                              o_error);
            RETURN FALSE;
    END get_scale_dates;

    /*
    * Calculates the number of years,months between two timestamps.
    * 
    * @param i_lang             Language identifier.
    * @param i_timestamp_1      Timestamp
    * @param i_timestamp_2      Timestamp
    * @param o_years            Number of years (integer)
    * @param o_months           Number of months (integer)
    * @param o_error            Error message, if an error occurred.
    * 
    * @return True if successful, false otherwise. 
    *
    * @author Sofia Mendes
    * @version 2.6.0.5.2
    * @since 01-Mar-2011
    */
    FUNCTION get_timestamp_diff_sep
    (
        i_lang        IN language.id_language%TYPE,
        i_timestamp_1 IN TIMESTAMP WITH TIME ZONE,
        i_timestamp_2 IN TIMESTAMP WITH TIME ZONE,
        o_years       OUT NUMBER,
        o_months      OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error  := 'GET DIFFERENCE';
        o_years  := trunc(months_between(i_timestamp_2, i_timestamp_1) / 12);
        o_months := MOD(trunc(months_between(i_timestamp_2, i_timestamp_1)), 12);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_DIFF_SEP',
                                              o_error);
            RETURN FALSE;
    END get_timestamp_diff_sep;

    /********************************************************************************************
    * Gets begin date of the specific period
    *
    * @param i_lang                  Language ID for translations
    * @param i_prof                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_interval_nr           Number of hours/days/weeks/months
    * @param i_interval              Interval - (H)ours/(D)ays/(W)eeks/(M)onths
    * @param i_dt_end                Final date of the period - by default: current date
    * @param o_dt_begin              Begin date of the given period
    * @param o_error                 Error message
    *
    * @return                        True on sucess otherwise false
    *
    * @author                        Anna Kurowska
    * @since                         13-Feb-2013
    * @version                       2.6.3
    ********************************************************************************************/
    FUNCTION get_period_begin_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_interval_nr IN PLS_INTEGER DEFAULT 7,
        i_interval    IN VARCHAR2 DEFAULT 'D',
        i_dt_end      IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        o_dt_begin    OUT TIMESTAMP WITH TIME ZONE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_interv_nr_neg NUMBER := (-1 * i_interval_nr);
        l_func_name     VARCHAR2(30) := 'GET_PERIOD_BEGIN_DATE';
    BEGIN
        g_error := 'CALL ADD_TO_TSTZ, interval :' || i_interval;
    
        CASE i_interval
            WHEN pk_alert_constant.g_time_interval_hour THEN
                o_dt_begin := pk_date_utils.add_to_ltstz(i_timestamp => i_dt_end,
                                                         i_amount    => l_interv_nr_neg,
                                                         i_unit      => 'HOUR');
            WHEN pk_alert_constant.g_time_interval_day THEN
                o_dt_begin := pk_date_utils.add_days_to_tstz(i_dt_end, l_interv_nr_neg);
            WHEN pk_alert_constant.g_time_interval_week THEN
                l_interv_nr_neg := l_interv_nr_neg * 7;
                o_dt_begin      := pk_date_utils.add_days_to_tstz(i_dt_end, l_interv_nr_neg);
            WHEN pk_alert_constant.g_time_interval_month THEN
                o_dt_begin := pk_date_utils.non_ansi_add_months(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_date         => i_dt_end,
                                                                i_nr_of_months => l_interv_nr_neg,
                                                                o_error        => o_error);
        END CASE;
    
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
    END get_period_begin_date;

    /** 
    * Converts a date from flash layer to a timestamp with the time zone of the professional's institution.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_INST                       Institution
    * @param      I_DATE                       Date from user's input
    *
    * ORA-01878 proof
    * 
    * @return     timestamp with time zone
    * @author     Carlos Ferreira
    * @version    0.1
    * @since      2013/07/08
    */
    FUNCTION get_timestamp_insttimezone
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN VARCHAR2,
        i_format IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH TIME ZONE IS
        l_timezone timezone_region.timezone_region%TYPE;
        l_error    t_error_out;
        l_ret      BOOLEAN;
    
    BEGIN
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone to use
        IF NOT
            pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, o_timezone => l_timezone, o_error => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_date,
                                             i_timezone  => l_timezone,
                                             i_mask      => i_format);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TIMESTAMP_INSTTIMEZONE',
                                              l_error);
            RETURN NULL;
    END get_timestamp_insttimezone;

    FUNCTION get_gmt_offset
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_tz     VARCHAR2(30 CHAR);
        l_offset VARCHAR2(30 CHAR);
        l_cfg    sys_config.value%TYPE;
    BEGIN
        l_cfg := pk_sysconfig.get_config(i_code_cf => 'GMT_ON_DATE', i_prof => i_prof);
    
        l_tz := pk_date_utils.get_timezone(i_lang => i_lang, i_prof => i_prof, i_timezone => NULL);
    
        IF l_tz IS NOT NULL
        THEN
            SELECT regexp_replace(tz_offset(l_tz), '[^a-z0-9\+\-\:]*', '', 1, 0, 'i')
              INTO l_offset
              FROM dual;
        END IF;
    
        IF l_offset IS NOT NULL
        THEN
            IF nvl(l_cfg, 'N') = 'Y'
            THEN
                RETURN 'GMT ' || l_offset;
            ELSE
                RETURN '';
            END IF;
        ELSE
            RETURN '';
        END IF;
    
    END get_gmt_offset;

    /**********************************************************************************************
    * Date formatting. Function overload without date param to be called in Flash
    *
    * @param i_lang                   Language ID
    * @param i_prof                   professional, software and institution IDs
    *
    * @return                         Formatted date
    *                        
    * @author                         Sergio Dias
    * @version                        2.6.3.11
    * @since                          Feb-6-2014
    **********************************************************************************************/
    FUNCTION date_hour_chr_extend
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'DATE_HOUR_CHR_EXTEND';
        l_error     t_error_out;
    BEGIN
        RETURN pk_date_utils.date_hour_chr_extend(i_lang => i_lang,
                                                  i_date => pk_date_utils.get_timestamp_insttimezone(i_lang => i_lang,
                                                                                                     i_inst => i_prof.institution),
                                                  i_prof => i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END date_hour_chr_extend;

    FUNCTION convert_dt_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN DATE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_time     TIMESTAMP;
        l_time_tz  TIMESTAMP WITH TIME ZONE;
        l_time_tsz TIMESTAMP WITH LOCAL TIME ZONE;
        l_timezone timezone_region.timezone_region%TYPE;
    
        l_func_name VARCHAR2(30) := 'convert_dt_tsz';
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL GET_TIMEZONE';
        -- Get timezone to use
        IF NOT get_timezone(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_timezone => NULL,
                            o_timezone => l_timezone,
                            o_error    => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        l_time := CAST(i_date AS TIMESTAMP);
    
        pk_date_utils.set_dst_time_check_off;
    
        l_time_tz  := pk_date_utils.from_tz_dst(i_lang => i_lang, i_timestamp => l_time, i_timezone => l_timezone);
        l_time_tsz := CAST(l_time_tz AS TIMESTAMP WITH LOCAL TIME ZONE);
    
        pk_date_utils.set_dst_time_check_on;
    
        RETURN l_time_tz;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END convert_dt_tsz;
    --
    FUNCTION max_date(i_date IN table_timestamp_tstz) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        max_dt TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        IF (i_date IS NULL OR NOT i_date.exists(1))
        THEN
            RETURN NULL;
        ELSE
            max_dt := NULL;
            FOR i IN 1 .. i_date.count
            LOOP
                IF max_dt IS NULL
                THEN
                    max_dt := i_date(i);
                ELSIF i_date(i) IS NOT NULL
                      AND max_dt IS NOT NULL
                      AND max_dt < i_date(i)
                THEN
                    max_dt := i_date(i);
                END IF;
            END LOOP;
        END IF;
    
        RETURN max_dt;
    
    END max_date;

    -- Added to support EMR-805
    FUNCTION date_yearmonth_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(200) := 'DATE_YEARMONTH_TSZ';
        l_format    VARCHAR2(4000);
        l_date      TIMESTAMP WITH TIME ZONE;
        l_error     t_error_out;
    BEGIN
        g_error := 'CALL DATE_COMMON';
        RETURN date_common(i_lang   => i_lang,
                           i_date   => i_date,
                           i_format => 'YEAR_MONTH_FORMAT',
                           i_inst   => i_inst,
                           i_soft   => i_soft);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END date_yearmonth_tsz;

    -----------------------------------------------------------
    -- return the difference between dates in hours
    FUNCTION get_date_hour_diff
    (
        l_dt_1 TIMESTAMP WITH LOCAL TIME ZONE,
        l_dt_2 TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_error  t_error_out;
        l_result BOOLEAN;
    
        l_days    NUMBER;
        l_hours   NUMBER;
        l_minutes NUMBER;
        l_seconds NUMBER;
    
        l_hours_diff NUMBER;
    BEGIN
        l_result := get_timestamp_diff_sep(i_lang        => NULL,
                                           i_timestamp_1 => l_dt_1,
                                           i_timestamp_2 => l_dt_2,
                                           o_days        => l_days,
                                           o_hours       => l_hours,
                                           o_minutes     => l_minutes,
                                           o_seconds     => l_seconds,
                                           o_error       => l_error);
    
        l_hours_diff := l_days * 24 + l_hours + l_minutes / 60 + l_seconds / 3600;
    
        RETURN l_hours_diff;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATE_HOUR_DIFF',
                                              l_error);
            RETURN NULL;
    END;

BEGIN

    g_last_institution := NULL;
    g_last_timezone    := NULL;
    g_last_language    := NULL;
    g_last_nls_code    := NULL;
    g_validate_error   := TRUE;
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_date_utils;
/
