/*-- Last Change Revision: $Rev: 2026636 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_alert_constant IS

    FUNCTION get_no RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_no;
    END get_no;
    FUNCTION get_yes RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_yes;
    END get_yes;
    FUNCTION get_available RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_alert_constant.g_available;
    END get_available;

    /*******************************************************************************************************************************************
    * Nome :                          date_hour_send_format                                                                                    *
    * Descrição:  Return global format date to sent to flash                                                                                   *
    *                                                                                                                                          *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    *                                                                                                                                          *
    * @raises                         Generic oracle error                                                                                     *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    PROCEDURE date_hour_send_format(i_prof IN profissional) IS
    BEGIN
        pk_alertlog.log_debug('Mark 1');
        g_date_hour_send_format := pk_sysconfig.get_config('DATE_HOUR_SEND_FORMAT', i_prof => i_prof);
    EXCEPTION
        WHEN OTHERS THEN
            g_date_hour_send_format := 'yyyymmddhh24miss';
    END;

    /*******************************************************************************************************************************************
    * Nome :                          GET_TIMESCALE_ID                                                                                         *
    * Descrição:  Return TIMESCALE IDENTIFIERS                                                                                                 *
    *                                                                                                                                          *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    PROCEDURE get_timescale_id IS
    BEGIN
        pk_alertlog.log_debug('Mark 1');
        g_decade := 1;
        g_year   := 2;
        g_month  := 3;
        g_week   := 4;
        g_day    := 5;
        g_hour   := 6;
        g_shift  := 7;
    END;
    /*******************************************************************************************************************************************
    * Nome :                          get_timezone                                                                                             *
    * Descrição:  Return timezone for each institution                                                                                         *
    *                                                                                                                                          *
    * @param I_PROF                   Vector com a informação relativa  ao profissional, instituição e software                                *
    * @param i_prof                   Professional                                                                                             *
    * @param o_error                  Error message, if an error occurred.                                                                     *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/04/17                                                                                               *
    *******************************************************************************************************************************************/
    PROCEDURE get_timezone
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) IS
        ok BOOLEAN;
    BEGIN
        ok := pk_date_utils.get_timezone(i_lang     => i_lang,
                                         i_prof     => i_prof,
                                         i_timezone => NULL,
                                         o_timezone => g_institution_timezone,
                                         o_error    => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            SELECT tr.timezone_region
              INTO g_institution_timezone
              FROM institution i, timezone_region tr
             WHERE tr.id_timezone_region = i.id_timezone_region
               AND id_institution = i_prof.institution;
        
    END;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_alert_constant;
/
