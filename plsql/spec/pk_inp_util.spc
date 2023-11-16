/*-- Last Change Revision: $Rev: 2028756 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_util IS

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
    ) RETURN VARCHAR2;

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
    ) RETURN VARCHAR2;

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
    ) RETURN PLS_INTEGER;

    FUNCTION least_length
    (
        i_big_word   IN VARCHAR2,
        i_small_word IN VARCHAR2,
        i_max_length IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION dd_mon_yyyy
    (
        i_lang IN NUMBER,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    FUNCTION hh24_mi_h
    (
        i_lang IN NUMBER,
        i_date IN DATE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    PROCEDURE do_log
    (
        i_package IN VARCHAR2,
        i_comm    IN VARCHAR2
    );

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_msg_bmng_timeframe_m  CONSTANT VARCHAR2(30) := 'BMNG_TIMEFRAME_M';
    g_msg_bmng_timeframe_m7 CONSTANT VARCHAR2(30) := 'BMNG_TIMEFRAME_M7';

    g_this_week              CONSTANT PLS_INTEGER := 7; -- This week
    g_last_week              CONSTANT PLS_INTEGER := 8; -- Last Week
    g_past_events_this_month CONSTANT PLS_INTEGER := 9; -- Past events in this Month
    g_next_week              CONSTANT PLS_INTEGER := 6; -- Next Week
    g_future_this_month      CONSTANT PLS_INTEGER := 5; -- Future events in this Month
    g_last_month             CONSTANT PLS_INTEGER := 10; -- Last Month
    g_past_events_this_year  CONSTANT PLS_INTEGER := 11; -- Past events in this Year
    g_next_month             CONSTANT PLS_INTEGER := 4; -- Next Month
    g_future_this_year       CONSTANT PLS_INTEGER := 3; -- Future events in this Year
    g_last_year              CONSTANT PLS_INTEGER := 12; -- Last Year
    g_past                   CONSTANT PLS_INTEGER := 13; -- Past
    g_next_year              CONSTANT PLS_INTEGER := 2; -- Next Year
    g_future                 CONSTANT PLS_INTEGER := 1; -- Future

    g_code_msg_hour  CONSTANT sys_message.code_message%TYPE := 'BMNG_T130';
    g_code_msg_hours CONSTANT sys_message.code_message%TYPE := 'BMNG_T131';
    g_sm_minute      CONSTANT sys_message.code_message%TYPE := 'HIDRICS_M063';
    g_sm_minutes     CONSTANT sys_message.code_message%TYPE := 'HIDRICS_M064';
    g_one_hour_unit  CONSTANT PLS_INTEGER := 1;

    -- Scope to be used in the diaries get info
    g_scope_session_s CONSTANT VARCHAR2(1) := 'S';
    g_scope_episode_e CONSTANT VARCHAR2(1) := 'E';
    g_scope_patient_p CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit_v   CONSTANT VARCHAR2(1) := 'V';

    /* Package info */
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);

    /* Error tracking */
    g_error VARCHAR2(4000);

END;
/
