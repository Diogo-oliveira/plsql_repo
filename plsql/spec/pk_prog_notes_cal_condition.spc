CREATE OR REPLACE PACKAGE pk_prog_notes_cal_condition IS

    -- Author  : AMANDAH_LEE
    -- Created : 2017/12/4 ¤W¤È 10:54:46
    -- Purpose : 

    -- Public type declarations
    TYPE note_det_rec IS RECORD(
        note_id              NUMBER(24),
        note_short_date      VARCHAR2(15 CHAR), -- Date of registry last update
        note_short_hour      VARCHAR2(10 CHAR), -- Time of registry last update
        id_note_type         NUMBER(24), -- note type identifier
        note_type_desc       VARCHAR2(100 CHAR), -- note description
        note_flg_status      VARCHAR2(2 CHAR), -- id_pn_note_type and dt_event final status
        note_flg_status_desc VARCHAR2(50 CHAR), -- note flg_status description
        note_info_desc       VARCHAR2(200 CHAR), --note flg_codition status description ex: procedure note future show proposed
        note_prof_signature  VARCHAR2(200 CHAR),
        id_prof              NUMBER(24),
        note_flg_ok          VARCHAR2(1 CHAR),
        note_flg_cancel      VARCHAR2(1 CHAR),
        note_nr_addendums    NUMBER(24),
        flg_editable         VARCHAR2(1 CHAR),
        flg_write            VARCHAR2(1 CHAR),
        viewer_category      NUMBER(24),
        viewer_category_desc VARCHAR2(50 CHAR));
    TYPE note_det_tbl IS TABLE OF note_det_rec;

    -- Public constant declarations
    g_sysconf_dformate_code CONSTANT VARCHAR2(11 CHAR) := 'DATE_FORMAT';

    --Canlendar and epis_pn status list
    g_proposed CONSTANT VARCHAR2(2 CHAR) := 'NE';
    g_on_time  CONSTANT VARCHAR2(2 CHAR) := 'O';
    g_delay    CONSTANT VARCHAR2(2 CHAR) := 'DE';
    --new type for show future note
    g_future_proposed CONSTANT VARCHAR2(2 CHAR) := 'FP';

    --FLG_CAL_TYPE
    g_admission_problem_listing CONSTANT VARCHAR2(3 CHAR) := 'APL';
    g_antibiotic_record CONSTANT VARCHAR2(2 CHAR) := 'AR';
    g_holiday_signature         CONSTANT VARCHAR2(2 CHAR) := 'HS';
    g_procedure_note            CONSTANT VARCHAR2(3 CHAR) := 'PRN';
    g_attending_progress_note   CONSTANT VARCHAR2(3 CHAR) := 'APN';
    g_progress_note             CONSTANT VARCHAR2(2 CHAR) := 'PN';
    g_weekly_summary            CONSTANT VARCHAR2(2 CHAR) := 'WS';

    -- FLG_CAL_TIME_FILTER
    g_admission_date      CONSTANT VARCHAR2(2 CHAR) := 'A';
    g_eips_pn_event_date  CONSTANT VARCHAR2(2 CHAR) := 'EN';
    g_eips_pn_create_date CONSTANT VARCHAR2(2 CHAR) := 'EC';

    -- Public variable declarations
    --< variablename > < datatype >;

    -- Public function and procedure declarations
    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_area                All pn_area number
    * @param i_id_episode             Episode ID
    * @param i_begin_date             Get note list begin date
    * @param i_end_date               Get note list end date
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_all_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pn_area    IN table_number,
        i_id_episode IN episode.id_episode%TYPE,
        i_begin_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_note_lists OUT t_coll_note_type_condition,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get pn_area list use pn_area internal name
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_internal_name          PN_AREA internal name
    *
    * @param o_pn_area_lists          All PN_AREA ID
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-05                       
    **************************************************************************/
    FUNCTION get_pn_area_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN table_varchar,
        o_pn_area_lists OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get dates in specific period
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_bdate                  begin date of period
    * @param i_edate                  begin date of period
    * @param o_dates                  All dates of this period
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-30                       
    **************************************************************************/
    FUNCTION get_dates_of_period
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_bdate IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_edate IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_dates OUT table_timestamp,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * get begin and end date in current week
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_date                   date of this week
    * @param o_bdate                  begin date of this week
    * @param o_edate                  end date of this week
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-30                       
    **************************************************************************/
    FUNCTION get_f_e_date_of_week
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_bdate OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_edate OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dates OUT table_timestamp,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get calendar header name of date
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_nls_code               nls code
    * @param i_date                   Calendar every date name
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_name_of_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_note_type_list         Note type list need to use
    * @param i_admission_date         Admission date
    * @param i_discharge_date         Discharge date
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    * @param o_expect_note            cursor with all expect note
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_expect_note
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_note_type_list IN t_coll_note_type_condition,
        i_admission_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_discharge_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_begin_date     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_expect_note    OUT t_coll_note_type_dt,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_note_type_list         Note type list need to use
    * @param i_admission_date         Admission date
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    * @param o_expect_note            cursor with all expect note
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_exist_note
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        i_note_type_list     IN t_coll_note_type_condition,
        i_pn_area_inter_name IN VARCHAR2,
        i_admission_date     IN TIMESTAMP WITH LOCAL TIME ZONE, --CALERT-1265
        i_begin_date         IN TIMESTAMP WITH LOCAL TIME ZONE, --CALERT-1265
        i_end_date           IN TIMESTAMP WITH LOCAL TIME ZONE, --CALERT-1265
        o_exist_note_det     OUT t_coll_calendar_note_det,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Use id_epis_pn to get diffrent description for this epis_pn, 
    * 1. If note is procedure note, the epis_pn description is id_task_type=g_task_ph_templ
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION note_det_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        i_nt_flg_type IN VARCHAR2,
        i_epis_pn     IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_note_type_list         all note type list
    * @param i_exist_notes            all exist notes list
    * @param i_expect_notes           all expect notes list
    *
    * @param o_calendar_note_det      return calendar note detail to check status
    * @param o_note_det               cursor with all note detail
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-1                       
    **************************************************************************/
    FUNCTION get_note_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_note_type_list    IN t_coll_note_type_condition,
        i_exist_note_det    IN t_coll_calendar_note_det,
        i_expect_notes      IN t_coll_note_type_dt,
        o_calendar_note_det OUT t_coll_calendar_note_det,
        o_note_det          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Get all note every day status 
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_note_det      All calendar note detail data
    * @param i_note_type_condition    All Note type parameter
    * @param i_dates_of_week          All dates of week
    *
    * @param o_note_lists             cursor with the information for all notes
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-5                       
    **************************************************************************/
    FUNCTION get_note_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_calendar_note_det   IN t_coll_calendar_note_det,
        i_note_type_condition IN t_coll_note_type_condition,
        i_dates_of_week       IN table_timestamp,
        o_note_lists          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get calendar title period
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_bdate                  begin date of period
    * @param i_edate                  begin date of period
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_period
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_begin_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get note type time status
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-18                       
    **************************************************************************/
    FUNCTION get_exist_note_time_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_flg_cal_time_filter IN pn_note_type_mkt.flg_cal_time_filter%TYPE,
        i_cal_delay_time      IN pn_note_type_mkt.cal_delay_time%TYPE,
        i_cal_icu_delay_time  IN pn_note_type_mkt.cal_icu_delay_time%TYPE,
        i_dt_create           IN epis_pn.dt_create%TYPE,
        i_dt_pn_date          IN epis_pn.dt_pn_date%TYPE,
        i_dt_admission        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get note type(surposed) time status
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_nt_flg_type            PN_NOTE_TYPE flg_cal_type
    * @param i_epis_pn                epis_pn ID
    * @param i_begin_date             begin date
    * @param i_end_date               end_date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-18                       
    **************************************************************************/
    FUNCTION get_expect_note_time_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_event_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_cal_type       IN pn_note_type_mkt.flg_cal_type%TYPE,
        i_cal_delay_time     IN pn_note_type_mkt.cal_delay_time%TYPE,
        i_cal_icu_delay_time IN pn_note_type_mkt.cal_icu_delay_time%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Get note type(surposed) time status
    * 
    * @param i_dt_event_date     date
    * @param i_dt                date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-04                       
    **************************************************************************/
    FUNCTION check_weekly_summary_range
    (
        i_dt_event_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt            IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER;

    /**************************************************************************
    * Get holiday list
    * 
    * @param i_prof              Profissional ID
    * @param i_dt_begin          begin date
    * @param i_dt_end            end date
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-12                       
    **************************************************************************/
    FUNCTION get_holidays
    (
        i_prof           IN profissional,
        i_dt_begin       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_admission_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN table_timestamp;

    /**************************************************************************
    * Get canlendar first date
    * 
    * @param i_prof              Profissional ID
    *
    *
    * @author                         Amanda Lee
    * @version                        2.7.3
    * @since                          2018-01-17                       
    **************************************************************************/
    FUNCTION get_first_date_of_week(i_prof IN profissional) RETURN NUMBER;
END pk_prog_notes_cal_condition;
/
