/*-- Last Change Revision: $Rev: 2028590 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_date_utils AS

    g_dateformat      VARCHAR2(30 CHAR) := 'YYYYMMDDHH24MISS'; --'YYYY-MM-DD HH24:MI:SS TZR';
    g_dateformat_msec VARCHAR2(30 CHAR) := 'YYYYMMDDHH24MISSFF9';
    g_dateformat_tzh_tzm VARCHAR2(30 CHAR) := 'YYYYMMDDHH24MISSTZH:TZM';
    g_date_minute_format VARCHAR2(30 CHAR) := 'YYYY-MM-DD HH24:MI:SS'; --'YYYY-MM-DD HH24:MI:SS';

    /**
    * This function returns TRUE if validation of DST time by the database is active. Returns false if DST time is "corrected".
    *
    * @author   Carlos Ferreira
    * @version  1,0
    * @since    2007/10/15
    */
    FUNCTION get_dst_time_flag RETURN BOOLEAN;

    PROCEDURE set_dst_time_check_on;
    PROCEDURE set_dst_time_check_off;

    FUNCTION get_elapsed_sysdate
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2;

    FUNCTION get_elapsed_sysdate
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_elapsed_abs
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2;

    FUNCTION get_elapsed_abs
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_elapsed
    (
        i_lang    IN language.id_language%TYPE,
        i_date1   IN DATE,
        i_date2   IN DATE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_elapsed
    (
        i_lang  IN language.id_language%TYPE,
        i_date1 IN DATE,
        i_date2 IN DATE
    ) RETURN VARCHAR2;

    FUNCTION date_char
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION dt_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION dt_chr
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION dt_chr_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION dt_chr_date_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION date_char_hour
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION trunc_dt_char
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION date_send
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;

    FUNCTION compare_dates
    (
        i_date1 IN DATE,
        i_date2 IN DATE
    ) RETURN VARCHAR2;

    FUNCTION get_elapsed_abs_er(i_date IN DATE) RETURN VARCHAR2;

    FUNCTION get_elapsed_abs_er
    (
        i_date          IN DATE,
        o_elapsed       OUT VARCHAR2,
        o_error_message OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION dt_chr_short
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;

    FUNCTION date_chr_space
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION date_chr_space
    (
        i_lang        IN language.id_language%TYPE,
        i_date        IN DATE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    ) RETURN BOOLEAN;

    FUNCTION dt_year_day_hour_chr_short
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
    /**
    * Retorna numero de minutos entre sydate e a data passada
    */
    FUNCTION get_elapsed_minutes_abs(i_date IN DATE) RETURN NUMBER;

    FUNCTION dt_chr_month
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_TIMESTAMP_STR_WITH_TIMEZONE  Function that returns varchar2 with TZH:TZM from an TIMESTAMP
    * 
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TIMESTAMP                  Timestamp wth timezone to input
    * @param      I_TIMEZONE                   Timezone to which we want to convert the date
    * 
    * @return     varchar2
    * 
    * @author                         Gilberto Rocha
    * @version                        2.8.2.0
    * @since                          2020/10/12
    *******************************************************************************************************************************************/
    FUNCTION get_timestamp_str_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        i_timezone  IN VARCHAR2
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    * @author     Sofia Mendes
    * @version    2.7.4
    * @since      2018/05/04
    */
    FUNCTION get_timestamp_insttimezone
    (
        i_lang      IN language.id_language%TYPE,
        i_inst      IN institution.id_institution%TYPE,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timezone  IN VARCHAR2,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        o_timestamp OUT TIMESTAMP WITH TIME ZONE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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
        WITH TIME ZONE;

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
        WITH TIME ZONE;

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
        WITH TIME ZONE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN NUMBER DETERMINISTIC;

    /*
    * Calculates the number of days, hours, minutes and seconds between two timestamps.
    * 
    * @param i_lang             Language identifier.
    * @param i_timestamp_1      Timestamp
    * @param i_timestamp_2      Timestamp
    * @param o_years            Number of years (integer)
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to DATE_SPACE_FORMAT parameter.
    *
    * @param i_lang      Language identifier
    * @param i_date      Timestamp
    * @param i_inst      Institution
    * @param i_soft      Software
    * @param i_timezone  Timezone
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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    FUNCTION date_mon_hour_format_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to the DATE_HOUR_SEND_FORMAT format.
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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /*
    * Formats a timestamp according to 24_HOUR_FORMAT (no minutes).
    * 
    * @param i_lang   Language identifier.
    * @param i_date   Timestamp
    * @param i_prof   Professional
    * 
    * @return Formatted timestamp 
    *
    * @author Jos?Silva
    * @since 2010/06/03
    */
    FUNCTION dt_24hour_chr_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /*
    * Gets the elapsed time between two timestamps.
    * 
    * @param i_lang   Language identifier.
    * @param i_date1  Timestamp
    * @param o_error  Error message, if an error occurred.
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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
    * 
    * @param i_lang        Language identifier.
    * @param i_date        Timestamp 1
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
    ) RETURN BOOLEAN;

    /*
    * Gets the description about the time elapsed between two timestamps (timestamp1 - current_timestamp).
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
    ) RETURN VARCHAR2;

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
        i_date     IN VARCHAR2 DEFAULT NULL,
        o_elapsed  OUT VARCHAR2,
        o_error    OUT t_error_out,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR;

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
    FUNCTION get_elapsed_minutes_abs_tsz(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    FUNCTION get_elapsed_time_tsz
    (
        i_lang    IN language.id_language%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_elapsed OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_elapsed_time_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_elapsed_time_desc
    (
        i_lang    IN NUMBER,
        i_elapsed IN NUMBER,
        o_desc    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
        WITH TIME ZONE;

    FUNCTION add_to_ltstz
    (
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_amount    IN NUMBER,
        i_unit      IN VARCHAR2 DEFAULT 'DAY'
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    * @author Jos?Silva
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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        WITH TIME ZONE;

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
        WITH TIME ZONE;

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
        WITH TIME ZONE;

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
    ) RETURN VARCHAR2;

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
    FUNCTION get_timezone
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL,
        o_timezone OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /**
    * Calculates the difference between timestamps.
    * This is similar to date subtraction (left-right),
    * and returns an integer, which represents the amount
    * of days between, with decimal part
    * @param i_left left timestamp
    * @param i_right right timestamp
    * @return the difference
    * @since 28-08-2007
    * @author João Eiras
    **/
    FUNCTION diff_timestamp
    (
        i_left  TIMESTAMP WITH LOCAL TIME ZONE,
        i_right TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    /** 
    * Get string with current timestamp in format 'YYYYMMDDhh24miss'.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_TIMESTAMP_STR              Converted timestamp
    * @param      O_ERROR                      Error message
    *
    * @return     TRUE if successfull. FALSE otherwise.
    
    * @author     Jos?Brito
    * @version    0.1
    * @since      2009/01/13
    */
    FUNCTION get_current_timestamp_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Applies the to_char function to a timestamp.  
    * Important! This function doesn't convert the i_timestamp to institution time zone. 
    * You normally should use to_char_insttimezone().
    * 
    * @param i_lang                   Language ID                                                                                              
    * @param i_prof                   Professional, software and institution ids                                                                                                                                          
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
    ) RETURN VARCHAR2;

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
    FUNCTION week_day_standard(i_date IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN NUMBER;

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
        WITH LOCAL TIME ZONE;
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
    ) RETURN DATE;

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
    ) RETURN BOOLEAN;

    FUNCTION get_weekdays_with_default
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN VARCHAR2,
        o_weekdays OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

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
        WITH TIME ZONE;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************    
    * Returns the standard first day of week
    *
    * @param i_prof                           Professional identification       
    *
    * @return                 Standard day of week; 1 - Monday; ...; 7 - Sunday;
    * 
    * @raises                
    *
    * @author                Alexandre Santos
    * @version               V.2.5.5
    * @since                 2009/06/29    
    ********************************************************************************************/
    FUNCTION get_first_day_of_week(i_prof IN profissional) RETURN NUMBER;

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
    ) RETURN NUMBER;

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;
    /* Error variable */
    g_error VARCHAR2(4000);

    /* English language code */
    g_english_lang CONSTANT NUMBER := 2;

    /* Package owner */
    g_package_owner VARCHAR2(32);

    /* Package name */
    g_package_name VARCHAR2(32);

    /* Last institution used */
    g_last_institution NUMBER;
    /* Last timezone used */
    g_last_timezone timezone_region.timezone_region%TYPE;
    /* Last language used */
    g_last_language language.id_language%TYPE;
    /* Last NLS code used */
    g_last_nls_code language.nls_code%TYPE;

    g_sysdate DATE;

    TYPE t_sys_config_value IS TABLE OF sys_config.value%TYPE INDEX BY VARCHAR2(300);

    g_date_hour_format t_sys_config_value;

    g_date_format sys_config.value%TYPE;

    g_date_format_short sys_config.value%TYPE;

    g_hour_format sys_config.value%TYPE;

    g_trunc_dt_format sys_config.value%TYPE;

    g_date_hour_send_format sys_config.value%TYPE;

    g_day VARCHAR2(200) := pk_message.get_message(1, 'COMMON_M019');

    g_days VARCHAR2(200) := pk_message.get_message(1, 'COMMON_M020');

    g_min VARCHAR2(1) := '1';

    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_ref_date CONSTANT DATE := to_date('20000102', 'YYYYMMDD');

    /* Message for weekday 1 */
    g_msg_wday_1 CONSTANT VARCHAR2(8) := 'SCH_T314';
    /* Message for weekday 2 */
    g_msg_wday_2 CONSTANT VARCHAR2(8) := 'SCH_T315';
    /* Message for weekday 3 */
    g_msg_wday_3 CONSTANT VARCHAR2(8) := 'SCH_T316';
    /* Message for weekday 4 */
    g_msg_wday_4 CONSTANT VARCHAR2(8) := 'SCH_T317';
    /* Message for weekday 5 */
    g_msg_wday_5 CONSTANT VARCHAR2(8) := 'SCH_T318';
    /* Message for weekday 6 */
    g_msg_wday_6 CONSTANT VARCHAR2(8) := 'SCH_T319';
    /* Message for weekday 7 */
    g_msg_wday_7 CONSTANT VARCHAR2(8) := 'SCH_T320';

    g_scale_thisyear  CONSTANT VARCHAR2(10) := 'THISYEAR';
    g_scale_thismonth CONSTANT VARCHAR2(10) := 'THISMONTH';
    g_scale_thisweek  CONSTANT VARCHAR2(10) := 'THISWEEK';
    g_scale_today     CONSTANT VARCHAR2(10) := 'TODAY';
    g_scale_lastday   CONSTANT VARCHAR2(10) := 'LASTDAY';
    g_scale_lastweek  CONSTANT VARCHAR2(10) := 'LASTWEEK';
    g_scale_lastmonth CONSTANT VARCHAR2(10) := 'LASTMONTH';
    g_scale_lastyear  CONSTANT VARCHAR2(10) := 'LASTYEAR';
    g_scale_last24h   CONSTANT VARCHAR2(10) := 'LAST_24H';
    g_scale_last48h   CONSTANT VARCHAR2(10) := 'LAST_48H';

    g_scale_year   CONSTANT VARCHAR2(4) := 'YEAR';
    g_scale_month  CONSTANT VARCHAR2(5) := 'MONTH';
    g_scale_week   CONSTANT VARCHAR2(4) := 'WEEK';
    g_year_format  CONSTANT VARCHAR2(4) := 'YYYY';
    g_month_format CONSTANT VARCHAR2(4) := 'MM';
    g_week_format  CONSTANT VARCHAR2(4) := 'DAY';

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
        WITH TIME ZONE;

    /** 
    * get GMT offset
    *
    * @param      i_lang                       prefered language id for this professional
    * @param      i_prof                       Institution
    *
    * @return     GMT offset
    * @author     Rui Spratley
    * @version    2.6.3.9
    * @since      2013/12/19
    */
    FUNCTION get_gmt_offset
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

    FUNCTION convert_dt_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN DATE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION max_date(i_date IN table_timestamp_tstz) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION date_yearmonth_tsz
    (
        i_lang IN language.id_language%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_inst IN institution.id_institution%TYPE,
        i_soft IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION add_days
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_amount IN NUMBER
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    -- *******************************************************
    FUNCTION get_timezone_base
    (
        i_prof     IN profissional,
        i_timezone IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    -- *********************************************
    FUNCTION at_time_zone
    (
        i_prof      IN profissional,
        i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_timezone  IN VARCHAR2 DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH TIME ZONE;

    -----------------------------------------------------------
    -- return the difference between dates in hours
    FUNCTION get_date_hour_diff
    (
        l_dt_1 TIMESTAMP WITH LOCAL TIME ZONE,
        l_dt_2 TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

END pk_date_utils;
/
