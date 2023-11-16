/*-- Last Change Revision: $Rev: 2028945 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:54 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule IS
    -- This package provides the logic for ALERT Scheduler.
    -- @author Nuno Guerreiro
    -- @version alpha

    ------------------------------ PUBLIC FUNCTIONS ---------------------------

    /*
    *  search for the free vacancy keyword in the given list.
    *  To be used inside sql.
    *
    * @param i_status     string with list of status values in csv form
    * 
    * @return  Y = keyword present  N = not present
    *
    * @author   Telmo
    * @version  2.5
    * @date     25-03-2009
    */
    FUNCTION get_only_vacs(i_status VARCHAR2) RETURN VARCHAR2;

    /**
    * Returns the description of the patient's default health plan.
    * To be used inside a SELECT statement.
    *
    * @param   i_lang         Language.
    * @param   i_id_patient   Patient identifier.
    * @param   i_id_inst      Institution.
    *
    * @return  the description of the patient's default health plan
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/06
    */
    FUNCTION get_health_plan
    (
        i_lang       NUMBER,
        i_id_patient patient.id_patient%TYPE,
        i_id_inst    institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /**
    * This function is used to internally to call pk_sysdomain.get_domain.
    * It logs a warning if the domain description value does not exist.
    * Note: As it is a mere encapsulation of pk_sysdomain.get_domain it does not
    * follow the common return type as stated on the best practices.
    * To be used inside SELECTs, for instance.
    *
    * @param i_lang         Language (just used for error messages).
    * @param i_code_dom     Domain code.
    * @param i_val          Domain value.
    *
    * @return   Domain description value.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION get_domain_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_code_dom IN sys_domain.code_domain%TYPE,
        i_val      IN sys_domain.val%TYPE
    ) RETURN VARCHAR2;

    /*
    * Gets a list of strings from a CSV string.
    *
    * @param i_list CSV List of strings.
    *
    * @return List (table_varchar) of strings.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/08
    */
    FUNCTION get_list_string_csv(i_list VARCHAR2) RETURN table_varchar;

    /*
    * Gets a list of numbers from a CSV string.
    *
    * @param i_list CSV List of numbers.
    *
    * @return List (table_number) of numbers.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/08
    */
    FUNCTION get_list_number_csv(i_list VARCHAR2) RETURN table_number;

    /**
    * This function is used inside WHERE clauses to check if a string element is inside a string list.
    *
    * @param i_element      Element
    * @param i_list         List
    *
    * @return   1 if the element is found, 0 otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/30
    */
    FUNCTION exist_inside_list
    (
        i_element VARCHAR2,
        i_list    VARCHAR2
    ) RETURN NUMBER;

    FUNCTION exists_inside_table_number
    (
        i_number NUMBER,
        i_table  table_number
    ) RETURN BOOLEAN;

    /**
    * Gets an event' s translated description.
    * To be used inside SELECTs.
    *
    * @param i_lang               Language identifier
    * @param i_id_sch_event       Event identifier
    * @param o_string             Event's translated description
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_sch_event
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sch_event IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2;

    FUNCTION string_institution
    (
        i_lang    IN language.id_language%TYPE,
        i_id_inst IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the department description.
    * To be used inside SELECTs.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_dep          Department identifier
    *
    * @return  Translated description of the department
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_department
    (
        i_lang   IN language.id_language%TYPE,
        i_id_dep IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a room' s translated description.
    * To be used inside SELECTs.
    * @param i_lang             Language identifier.
    * @param i_id_room          Room identifier
    *
    * @return  Room description
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the scheduling type translated description.
    * To be used inside SELECTs.
    *
    * @param i_lang               Language identifier
    * @param i_id_inst            inst id
    *
    * @return  output string
    *
    * @author  Telmo
    * @version 2.5.0.4
    * @since   26-06-2009
    */
    FUNCTION string_sch_type
    (
        i_lang     IN language.id_language%TYPE,
        i_dep_type IN sch_dep_type.dep_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets an origin' s translated description.
    *
    * @param i_lang                Language identifier.
    * @param i_id_origin           Origin identifier.
    *
    * @return  Translated description.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_origin
    (
        i_lang      IN language.id_language%TYPE,
        i_id_origin IN origin.id_origin%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the clinical service (based on a dep_clin_serv) description.
    * To be used inside SELECTs.
    *
    * @param   i_lang            Language identifier.
    * @param   i_id_clin_serv    Clinical service identifier
    *
    * @return  Clinical service description
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_clin_serv_by_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a reason' s translated description
    * To be used inside SELECTs
    * @param i_lang               Language identifier.
    * @param i_id_reason          Reason identifier
    *
    * @return  Reason
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_reason
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_reason IN schedule.id_reason%TYPE,
        i_flg_rtype IN schedule.flg_reason_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the description for i_id_lang, in the LANGUAGE domain.
    * To be used inside SELECTs.
    *
    * @param   i_lang           Language identifier.
    * @param   i_id_lang        Language domain value.
    * @param   o_string         Language description.
    * @param   o_error          Error message (if an error occurred).
    *
    * @return  True if successful executed, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_language
    (
        i_lang    IN language.id_language%TYPE,
        i_id_lang IN language.id_language%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the localized date.
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_prof            Professional
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2;

    /**
    * Gets the localized date.
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_prof            Professional
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_dt_birth
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN DATE
    ) RETURN VARCHAR2;

    /**
    * Gets the localized date (including hours and minutes).
    * To be used on SELECT statements.
    *
    * @param   i_lang            Language identifier.
    * @param   i_prof            Professional
    * @param   i_date            Date to localize.
    *
    * @return  Localized date.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION string_date_hm
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2;

    /**
    * Gets the professional's nick name.
    * To be used inside SELECTs.
    *
    * @param   i_lang       Language identifier.
    * @param   i_id_prof    Professional identifier
    *
    * @return  Professional's nick
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    --FUNCTION string_professional_nick(i_id_prof IN professional.id_professional%TYPE) RETURN VARCHAR2;

    /**
    * Gets the translated duration between two dates.
    * To be used on SELECT statements.
    *
    * @param i_lang       Language identification
    * @param i_dt_begin   Start date.
    * @param i_dt_end     End date.
    *
    * @return  Translated duration
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/23
    */
    FUNCTION string_duration
    (
        i_lang     IN NUMBER,
        i_dt_begin IN TIMESTAMP WITH TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION string_service
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR2;
    /**
    * Gets the dep_clin_serv translated description.
    * To be used inside a SELECT.
    *
    * @param   i_lang                     Language identifier.
    * @param   i_id_dep_clin_serv         Department-Clinical Service identifier
    *
    * @return  Translated description or NULL if none is found.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/03
    */
    FUNCTION string_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_dep_clin_serv IN clinical_service.id_clinical_service%TYPE
    ) RETURN VARCHAR;

    /**
    * This function returns the number of the clinical record associated with a patient within an institution.
    * To be used inside SELECTs.
    *
    * @param i_id_patient Patient
    * @param i_id_inst     Institution
    *
    * @return number of the clinical record
    *
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/26
    */
    FUNCTION get_num_clin_record
    (
        i_id_patient IN clin_record.id_patient%TYPE,
        i_id_inst    IN clin_record.id_institution%TYPE
    ) RETURN clin_record.num_clin_record%TYPE;

    /**
    * Returns all the schedule status for the multi-choice except for the
    * pending state. Though it exists, it must not be on the multichoice,
    * for readibility sake.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       Whether or not the 'All' item should be put on the multi-choice.
    * @param      o_status           List of status
    * @param      o_error            Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @since      2006/04/10
    */
    FUNCTION get_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_search IN VARCHAR2,
        i_sch_type   IN VARCHAR2,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of schedule cancelation reasons.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_actions          list of compatible events
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @version    alpha
    * @since      2006/04/10
    */
    FUNCTION get_cancelation_reasons
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cancelation_reason
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_can_reason IN sch_cancel_reason.id_sch_cancel_reason% TYPE,
        o_desc       OUT pk_translation.t_desc_translation,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of rooms.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_id_dep           Department(s)
    * @param      i_flg_search       Whether or not should the 'All' value be shown
    * @param      o_rooms            Rooms
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/04/26
    */
    FUNCTION get_rooms
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_dep     IN VARCHAR2,
        i_flg_search IN VARCHAR2,
        o_rooms      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of durations.
    *
    * @param i_lang               Language.
    * @param i_prof               Professional.
    * @param i_flg_search         Whether or not should the 'All' option be returned within the o_durations cursor.
    * @param o_durations          List of durations.
    * @param o_error              Error message (if an error has occurred).
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/04/27
    */
    FUNCTION get_durations
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_search IN VARCHAR2,
        o_durations  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of schedule reasons.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
    * @param      o_reasons              Schedule reasons
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/04/27
    *
    * UPDATED
    * added COMPLAINTDOCTOR_T012 in result
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    25-09-2008 
    */
    FUNCTION get_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_flg_search       IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the number of unplanned schedules for a given vacancy.
    * To be used inside a SELECT statement
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_args                   UI search arguments.
    * @param i_id_sch_vacancy         Vacancy
    *
    * @return     Number of unplanned schedules.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/07
    */
    FUNCTION get_unplanned_sch_count
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_args           IN table_varchar,
        i_id_sch_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE
    ) RETURN NUMBER;

    /**
    * This function returns the availability for each day on a given period.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                Arguments.
    * @param i_id_patient          Patient.
    * @param i_semester            Whether or not this function is being called to fill the semester calendar.
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_days_conflicts      List of total conflicting appointments per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_dcs_availability     Availability for each day and DCS (for the first N DCSs of the day).
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/04/26
    */
    FUNCTION get_availability
    (
        i_lang             IN language.id_language%TYPE DEFAULT NULL,
        i_prof             IN profissional,
        i_args             IN table_varchar,
        i_id_patient       IN patient.id_patient%TYPE,
        i_semester         IN VARCHAR2,
        o_days_status      OUT table_varchar,
        o_days_date        OUT table_varchar,
        o_days_free        OUT table_number,
        o_days_sched       OUT table_number,
        o_dcs_availability OUT pk_types.cursor_type,
        o_days_conflicts   OUT table_number,
        o_patient_icons    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the vacancies on a predefined range of days.
    *
    * @param i_lang         Language Identifier
    * @param i_prof         Professional
    * @param i_args         UI Arguments (includes: event, start date (single), institution, department-clinical service and professional lists)
    * @param i_id_event     Table of schedule events
    * @param o_values       Return values
    * @param o_error        Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    *
    * UDPDATED
    * added MFR scheduler case. Parameter i_args has a new index (9) for physiatry areas.
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     12-01-2009
    *
    * UDPDATED
    * table of id events removed from i_args and added in new parameter to prevent error 
    * @author   Jose Antunes
    * @version  2.5
    * @date     15-05-2009
    *
    * UDPDATED
    * removed i_args 
    * @author   Jose Antunes
    * @version  2.5
    * @date     15-05-2009
    */
    FUNCTION get_proximity_vacants
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_event       IN table_number,
        i_dt_vacant      IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_dcs         IN table_number,
        i_id_prof        IN table_number,
        i_id_exam        IN table_number,
        i_id_analysis    IN table_number,
        i_id_dep         IN department.id_department%TYPE,
        i_id_physareas   IN table_number,
        o_values         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Returns the vacancies on a predefined range of days.
    *
    * @param i_lang         Language Identifier
    * @param i_prof         Professional
    * @param i_args         UI Arguments (includes: event, start date (single), institution, department-clinical service and professional lists)
    * @param o_values       Return values
    * @param o_error        Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/30
    */
    FUNCTION get_proximity_vacants
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_events IS RECORD(
        data         VARCHAR2(1000 CHAR),
        id_sch_event VARCHAR2(1000 CHAR),
        label_full   pk_translation.t_desc_translation,
        label        pk_translation.t_desc_translation,
        flg_select   VARCHAR2(0001 CHAR),
        order_field  NUMBER(12),
        order_field2 NUMBER(12),
        no_prof      VARCHAR2(0001 CHAR));

    TYPE c_events IS REF CURSOR RETURN t_rec_events;
    TYPE t_coll_events IS TABLE OF t_rec_events;

    PROCEDURE open_my_cursor_events(i_cursor IN OUT c_events);

    /*
    * Gets the list of events.
    * @param i_lang               Language.
    * @param i_prof               Professional
    * @param i_id_dep             Department.
    * @param i_flg_search         Whether or not should the events be selected based on its type. (in 'N' cases, the first event is the only one selected).
    * @param i_flg_schedule       Whether or not should the events be filtered considering the professional's permission to schedule
    * @param i_flg_dep_type       Events should be filtered by sch_dep_type because the same department may have events with several sch_dep_type(s)
    * @param o_events             List of events.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    *
    * UPDATED
    * check of sch_event.flg_available was missing
    * @author  Telmo Castro
    * @date     23-04-2008
    * @version  2.4.3
    *
    * REVISED
    * inclusion of new flag sch_event_dcs.flg_available
    * @author  Telmo Castro
    * @date     24-04-2008
    * @version  2.4.3
    *
    * UPDATED
    * added check of sch_permission.flg_permission
    * @author  Telmo Castro
    * @date    15-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * added i_flg_dep_type
    * @author  Luís Gaspar
    * @date    28-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * main query updated to cope with the new possibility of having the same department spread out through several dep_type (see sch_department)
    * @author  Telmo Castro
    * @date    11-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * a tabela sch_event_soft nao traz qualquer vantagem neste momento. Como tem de ser configurada manualmente pode impedir o funcionamento
    * correcto da agenda se determinado software nao estiver associado ao evento pretendido.
    * @author  Telmo Castro
    * @date    17-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * added i_flg_event_def and i_flg_prof
    * @author  Jose Antunes
    * @date    26-08-2008
    * @version 2.4.3
    *
    * UPDATED
    * Remoção de SQL dinamico. Simplificacao de funcao
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     17-10-2008
    */
    FUNCTION get_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_flg_search    IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        i_flg_dep_type  IN VARCHAR2,
        i_flg_event_def IN VARCHAR2 DEFAULT NULL,
        i_flg_prof      IN VARCHAR2 DEFAULT NULL,
        o_events        OUT c_events,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of languages (including the default language, which is automatically selected).
    * @param i_lang               Language.
    * @param i_prof               Professional
    * @param i_id_patient         Patient.
    * @param i_flg_search         Whether or not should the 'All' option be included.
    * @param o_languages          List of languages.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_languages
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_search IN VARCHAR2,
        o_languages  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of origins.
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_flg_search         Whether or not should the 'All' origin be included on the list.
    * @param o_origins            List of origins.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_origins
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_origins        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the label for search patient by field. (Document or plan)
    *
    * @param i_lang      Language identifier.
    * @param i_prof      Professional.
    * @param o_label     Label.
    * @param o_error     Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_search_field_label
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_label OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the patient family physician name.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_patient         Patient identifier.    
    *
    * @return  Professional name.
    * @author  Sofia Mendes
    * @version 2.5.0.7.2
    * @since   2009/11/17    
    */
    FUNCTION get_pat_family_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * Gets the list of patients.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_name               Name to search for.
    * @param i_dt_birth           Date of birth.
    * @param i_search_value       Value of the document or plan.
    * @param i_id_patient         Patient identifier.
    * @param o_patients           List of patients.
    * @param o_error              Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/02
    */
    FUNCTION get_patients
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_name         IN patient.name%TYPE DEFAULT NULL,
        i_dt_birth     IN VARCHAR2 DEFAULT NULL,
        i_search_value IN VARCHAR2 DEFAULT NULL,
        i_id_patient   IN patient.id_patient%TYPE,
        o_patients     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves all patient information
    *
    * @param      i_lang             Language.
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_id_patient       Patient id
    * @param      o_patient_info     All information about the patient
    * @param      o_error            Error message (if an error occurred).
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2006/05/02
    */
    FUNCTION get_patient_detail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_patient_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @since      2006/05/02
    */
    FUNCTION get_months_and_days
    (
        i_lang      IN language.id_language%TYPE,
        o_months    OUT pk_types.cursor_type,
        o_week_days OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_dep_clin_servs IS RECORD(
        data        VARCHAR2(1000 CHAR),
        label       pk_translation.t_desc_translation,
        flg_select  VARCHAR2(1),
        order_field NUMBER(12));

    TYPE c_dep_clin_servs IS REF CURSOR RETURN t_rec_dep_clin_servs;
    TYPE t_coll_dep_clin_servs IS TABLE OF t_rec_dep_clin_servs;

    PROCEDURE open_my_cursor_dcs(i_cursor IN OUT c_dep_clin_servs);

    /*
    * Gets the list of clinical services from a department, for a given event, professional or episode.
    * @param i_lang             Language identifier.
    * @param i_prof             Professional who is calling this function.
    * @param i_id_dep           Department identifier.
    * @param i_id_event         Event identifier.
    * @param i_id_episode       Episode identifier.
    * @param i_flg_search       Whether or not should the 'All' option be included
    * @param i_flg_schedule        Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_dep_clin_servs   List of clinical services.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/03
    */
    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dep         IN VARCHAR2,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        o_dep_clin_servs OUT c_dep_clin_servs,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_sch_prof IS RECORD(
        data        NUMBER(24),
        label       pk_translation.t_desc_translation,
        flg_select  VARCHAR2(1),
        order_field NUMBER(12));

    TYPE c_sch_prof IS REF CURSOR RETURN t_rec_sch_prof;
    TYPE t_coll_sch_prof IS TABLE OF t_rec_sch_prof;

    PROCEDURE open_my_cursor_sch_prof(i_cursor IN OUT c_sch_prof);
    /*
    * Gets the list of professionals on whose schedules the logged professional
    * has permission to read or schedule.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional identifier.
    * @param i_id_dep           Department identifier.
    * @param i_id_clin_serv     Department-Clinical service identifier.
    * @param i_id_event         Event identifier.
    * @param i_flg_schedule     Whether or not should the events be filtered considering the professional's permission to schedule
    * @param o_professionals    List of processionals.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/03
    */
    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_clin_serv  IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        o_professionals OUT c_sch_prof,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of a professional's permissions for using departments.
    * Only the departments that are associated with the professional on SCH_PERMISSION_DEPT get a 'Y' as flg_select.
    *
    * @param i_lang             Language identifier.
    * @param i_prof             Professional who is logged on.
    * @param i_target_prof      Professional whose permissions are being listed.
    * @param o_permissions      List of permissions.
    * @param o_error            Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/04
    *
    * REVISED
    * @author  Telmo Castro
    * @date    21-04-2008
    * @version 2.4.3
    * Now reads: only the departments that are associated to the professional through prof_dep_clin_serv.
    */
    FUNCTION get_permission_depts
    (
        i_lang        language.id_language%TYPE,
        i_prof        profissional,
        i_target_prof professional.id_professional%TYPE,
        o_permissions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the colors (by name and by DCS) to use on the Scheduler.
    *
    * @param i_lang                    Language identifier.
    * @param i_prof                    Professional
    * @param i_id_dep                  Department
    * @param i_flg_named_colors        Whether or not should the named colors be returned: 'Y', 'N'
    * @param o_named_colors            List of named colors (if i_flg_named_colors = 'Y')
    * @param o_dcs_colors              List of DCS colors (if DCS colors are activated)
    * @param o_use_dcs_colors          Whether or not should the UI used DCS colors.
    * @param o_max_dcs_colors          Maximum number of colors to display per cell.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    */
    FUNCTION get_colors
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep           IN department.id_department%TYPE,
        i_flg_named_colors IN VARCHAR2,
        o_named_colors     OUT pk_types.cursor_type,
        o_dcs_colors       OUT pk_types.cursor_type,
        o_use_dcs_colors   OUT VARCHAR2,
        o_max_dcs_colors   OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    TYPE t_rec_departments IS RECORD(
        data        VARCHAR2(24),
        label       pk_translation.t_desc_translation,
        flg_type    VARCHAR2(2),
        flg_select  VARCHAR2(1),
        data_flag   VARCHAR2(50),
        order_field NUMBER(12),
        dep_type    VARCHAR2(100));

    TYPE c_dep IS REF CURSOR RETURN t_rec_departments;
    TYPE t_coll_departments IS TABLE OF t_rec_departments;

    PROCEDURE open_my_cursor_dep(i_cursor IN OUT c_dep);

    /*
    * Gets the list of departments that a professional has access to.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option appear on the list.
    * @param i_flg_schedule        Whether or not should the departments be filtered considering the professional's permission to schedule
    * @param o_departments         List of departments
    * @param o_perm_msg            Error message to be shown if the professional has no permissions
    * @param o_error               Error message (if an error occurred).
    *
    * @return     True if successful, false otherwise.
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2006/05/07
    *
    * UPDATED
    * sch_permission_dept abolished - permission for departments now derived from prof_dep_clin_serv, dep_clin_serv, department
    * @author  Telmo Castro
    * @date    21-04-2008
    * @version 2.4.3
    *
    * UPDATED
    * new sch_permission scenarios: prof1+prof2+dcs OR prof1+dcs
    * @author  Telmo Castro
    * @date    19-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * nurse consult departments description is appended with a message
    * @author  Luís Gaspar
    * @date    28-05-2008
    * @version 2.4.3
    *
    * UPDATED
    * main query updated to cope with the new possibility of having the same department spreaded through several dep_type (see sch_department)
    * @author  Telmo Castro
    * @date    11-07-2008
    * @version 2.4.3
    *
    * UPDATED
    * added column data_flag to output which is concat of columns data and dep_type
    * @author  Telmo Castro
    * @date    22-07-2008
    * @version 2.4.3
    */
    FUNCTION get_departments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        o_departments    OUT c_dep,
        o_perm_msg       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month and year.
    * To be used inside SELECTs.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    *
    * @return     String date
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/014
    */

    FUNCTION get_dmy_string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month and year.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    * @param      o_described_date   date in text mode
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Ricardo Pinho
    * @version    alpha
    * @since      2006/04/10
    */

    FUNCTION get_dmy_string_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        o_described_date OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by day, month, year, hour and minute.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    *
    * @return     varchar type, the writen date
    * @author     Nuno Guerreiro (Tiago Ferreira)
    * @version    alpha
    * @since      2007/05/08
    */
    FUNCTION get_dmyhm_string_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Converts a date into string using for it a mask defined in sys_message.
    * This date is composed by month and year.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_date             date to convert
    * @param      o_described_date   date in text mode
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/05/08
    */
    FUNCTION get_my_string_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_date           IN VARCHAR2,
        o_described_date OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieve statistics for the available and scheduled appointments
    *
    * @param      i_lang             Professional default language
    * @param      i_prof             Professional object which refers the identity of the function caller
    * @param      i_args             Arguments used to retrieve stats
    * @param      o_vacants          Vacants information
    * @param      o_schedules        Schedule information
    * @param      o_titles           Title information
    * @param      o_flg_vancay       Vacancy flags information
    * @param      o_error            Error information if exists
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/11
    */
    FUNCTION get_schedules_statistics
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_args        IN table_varchar,
        o_vacants     OUT pk_types.cursor_type,
        o_schedules   OUT pk_types.cursor_type,
        o_titles      OUT pk_types.cursor_type,
        o_flg_vacancy OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a patient's events that are inside a time range.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_id_patient     Patient identifier.
    * @param i_dt_schedule    Selected date.
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/11
    */
    FUNCTION get_proximity_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_dt_schedule IN VARCHAR2,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Identifies if the institution uses a generic appointment or not
    *
    * @param    i_lang          Language
    * @param    i_prof          Professional information (future use)
    * @param    i_institution   Institution to be verified
    * @param    o_flag          Flag with true or false result
    * @param    o_error         Error description if anything wrong occurs
    *
    * @author  Tiago Ferreira
    * @version alpha
    * @since   2007/02/13
    */
    FUNCTION get_generic_appoint_flag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN VARCHAR2,
        o_flag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the details of the schedules that are dragged, by dragging a full day into the clipboard
    *
    * @param i_lang
    * @param i_prof
    * @param i_args
    * @param o_schedules
    * @param o_error
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/14
    */
    FUNCTION get_schedules_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets all the vacancy types for the multi-choice
    *
    * @param      i_lang             Language identifier.
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       Whether or not should the 'All' option be listed
    * @param      o_vacancy_types    List of vacancy types
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro
    * @version    alpha
    * @since      2007/05/14
    */
    FUNCTION get_vacancy_types
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_search    IN VARCHAR2,
        o_vacancy_types OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedule's patients.
    *
    * @param i_lang                         Language.
    * @param i_prof                         Professional.
    * @param i_id_schedule                  Schedule identifier.
    * @param o_patients                     Details.
    * @param o_error                        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise.
    *
    * @author  Sofia Mendes
    * @version 2.5.x
    * @since   2009/06/17
    *    
    */
    FUNCTION get_schedule_patients
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_patients    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_referral
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN p1_external_request.id_external_request%TYPE;

    /*
    * Gets the schedule's details.
    *
    * @param i_lang                         Language.
    * @param i_prof                         Professional.
    * @param i_id_schedule                  Schedule identifier.
    * @param o_schedule_details             Details.
    * @param o_error                        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/14
    *
    * UPDATED
    * alterado parametro desc_reason do cursor o_schedule_details
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    */
    FUNCTION get_schedule_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_schedule_details OUT pk_types.cursor_type,
        o_patients         OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns list of eventual schedules (not yet created) for a single visit.
    * to be used in the popup that open when the user drags the patient into one of the marked vacancies
    * belonging to a combo. 
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           combination id
    * @param i_ids_codes          combo lines to be processed. its a table_table_number with pairs of (id_code, id_vacancy). 
    * @param o_sv_details         output cursor
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     26-06-2009
    */
    FUNCTION get_schedule_sv_details
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_combi   IN sch_combi.id_sch_combi%TYPE,
        i_ids_codes  IN table_table_number,
        o_sv_details OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set a new schedule notification.
    *
    * @param    i_lang           Language
    * @param    i_prof           Professional
    * @param    i_id_schedule    Schedule identification
    * @param    i_notification   Notification flag
    * @param    o_error           Error message if something goes wrong
    *
    * @author  Tiago Ferreira
    * @version 1.0
    * @since   2006/12/21
    */
    FUNCTION set_schedule_notification
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_schedule   IN schedule.id_schedule%TYPE,
        i_notification  IN schedule.flg_notification%TYPE,
        i_flg_notif_via IN schedule.flg_notification_via%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * integration version
    */
    FUNCTION set_schedule_notification
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_notification   IN schedule.flg_notification%TYPE,
        i_flg_notif_via  IN schedule.flg_notification_via%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a professional's permission to access a given professional's schedule.
    *
    * @param    i_lang                 Language identifier.
    * @param    i_prof                 Professional.
    * @param    i_id_dep_clin_serv     Department-Clinical service identifier.
    * @param    i_id_sch_event         Event identifier.
    * @param    i_id_prof              Professsional identifier (target professional).
    * @param    o_error                Error message if something goes wrong
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/15
    */
    FUNCTION get_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        o_permission       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION get_message
    (
        i_lang    IN language.id_language%TYPE,
        i_message IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * This function is used to replace several tokens in a given string.
    * It is used internally by functions/procedures that need to perform
    * token replacement, such as string_date.
    *
    * @param i_lang         Language (just used for error messages).
    * @param i_string       String with all the tokens to replace.
    * @param i_tokens       Nested table that contains the list of tokens to replace.
    * @param i_replacements Nested table that contains the list of replacements.
    * @param o_string       String with all the replacements made (or '' on error).
    * @param o_error        Error description if it exists.
    *
    * @return   True if successful executed, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION replace_tokens
    (
        i_lang         IN language.id_language%TYPE,
        i_string       IN VARCHAR2,
        i_tokens       IN table_varchar,
        i_replacements IN table_varchar,
        o_string       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Pushes messages into a global message stack.
    * Private function.
    *
    * @param    i_message       The message string
    *
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2007/01/17
    *
    * UPDATED
    * added field idx so that one can identify messages
    * @author Telmo Castro
    * @date   29-08-2008
    * @version 2.4.3
    */
    PROCEDURE message_push
    (
        i_message IN VARCHAR2,
        i_idxmsg  IN NUMBER
    );

    FUNCTION message_push_html
    (
        i_lang            IN language.id_language%TYPE,
        i_message         IN VARCHAR2,
        i_idxmsg          IN NUMBER,
        i_enclose_tag     IN VARCHAR2,
        i_enclose_tag_end IN VARCHAR2,
        i_breakline_tag   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Flushes messages returning them on the output parameter.
    * Private function.
    *
    * @param    o_message       The compilation of stack's messages
    *
    * @author  Ricardo Pinho
    * @version alpha
    * @since   2007/01/17
    */
    PROCEDURE message_flush(o_message OUT VARCHAR2);

    /**
    * Checks if a professional has write access to another professional or some clinical service's schedule
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional information
    * @param    i_id_dep_clin_serv       Department-Clinical service
    * @param    i_id_sch_event           Event
    * @param    i_id_prof                Target professional
    *
    * @author  Tiago Ferreira
    * @version alpha
    * @since   2007/02/13
    */
    FUNCTION has_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    FUNCTION has_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Checks if a professional list, associated to schedule (SCH_RESOURCE), has write access to another professional or some clinical service's schedule
    *
    * @param    i_lang                   Language
    * @param    i_prof                   Professional information
    * @param    i_id_dep_clin_serv       Department-Clinical service
    * @param    i_id_sch_event           Event
    * @param    i_id_schedule            Schedule ID
    *
    * @author  Nuno Miguel Ferreira
    * @version 2.5.0.4
    * @since   2009/06/23
    */
    FUNCTION has_permission_by_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * Gets the patient's icons.
    *
    * @param i_lang            Language identifier.
    * @param i_prof            Professional
    * @param i_args            UI args.
    * @param i_id_patient      Patient identifier.
    * @param o_patient_icons   Patient icons.
    * @param o_error           Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    FUNCTION get_patient_icons
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_args          table_varchar,
        i_id_patient    patient.id_patient%TYPE,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Creates a generic schedule (exams, consults, etc).
    * All other create functions should use this for core functionality.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param i_dt_end             Schedule end date
    * @param i_flg_vacancy        Vacancy flag.
    * @param i_schedule_notes     Notes.
    * @param i_id_lang_translator Translator's language identifier.
    * @param i_id_lang_preferred  Preferred language identifier.
    * @param i_id_reason          Reason.
    * @param i_id_origin          Origin.
    * @param i_id_schedule_ref    Appointment that this appointment replaces (on reschedules).
    * @param i_id_room            Room.
    * @param i_reason_notes       Reason for appointment in free-text.
    * @param i_show_vacancy_warn  Whether or not should a warning be issued if no vacancies are available.
    * @param i_do_overlap         null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be
    *                             issued with Y or N
    * @param i_id_consult_vac     id da vaga. Pode vir null
    * @param i_sch_option         'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param i_id_episode         episode id
    * @param i_id_sch_combi_detail used in single visit. this id relates this schedule with the combination detail line
    * @param o_id_schedule        Identifier of the new schedule.
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_overlapfound       an overlap was found while trying to save this schedule and no instruction was given on how to decide
    * @param o_error              Error message if something goes wrong
    *
    * @return   True if successful, false otherwise or if overlap found and no do_overlap supplied
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     26-05-2008
    *
    * UPDATED
    * schedule_outp.i_flg_sched_request_type movido para schedule.flg_request_type
    * @author  Telmo Castro
    * @version 2.4.3
    * @date     03-06-2008
    *
    * UPDATED
    * novo campo id_episode
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    13-06-2008
    *
    * UPDATED
    * a flg_sch_type passa a ser calculada aqui
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    25-08-2008
    *
    * UPDATED
    * novo campo i_id_complaint
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    04-09-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    *
    * UPDATED
    * alert-7740. getting vacancy data needs permission check 
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     17-10-2008
    *
    * UPDATED
    * ALERT-10162. updated call to check_vacancy_usage - new parameter i_id_dept. 
    * Also, new message screen to respond to l_vacancy_needed exceptions.
    * @author  Telmo Castro
    * @date    19-11-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * ALERT-11352.
    * Implementation of the 'edit vacancy' option inside the create_schedule. 
    * Such option can arise when the user changes one or more parameters that turn the previous chosen vacancy inadequate.
    * When that happens, there are 2 ways of action. If sch_vacancy configuration says we can edit the vacancy, then that is
    * the preferred action. Otherwise, the schedule is created without a vacancy association.
    * @author  Telmo Castro
    * @date    12-12-2008
    * @version 2.4.3.x
    *
    * UPDATED
    * Change i_id_patient data type from number to table_number (because of group schedules)
    * @author  Sofia Mendes
    * @date     15-06-2009
    * @version  2.5.x
    *
    * UPDATED
    * ALERT-34561. no_data_founds vindos desta funçao vao directamente para o UI. 
    * a partir de agora passam a ser apresentados como mensagem na popup das validacoes
    * @author  Telmo
    * @version 2.5.0.4
    * @date    15-07-2009
    *
    * UPDATED
    * New parameter i_id_institution: in order to allow to schedule to a institution diferent from i_prof.institution
    * @author  Sofia Mendes
    * @date     29-07-2009
    * @version  2.5.0.5
    *
    * UPDATED alert-8202. deixa de receber o id_exam
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    13-10-2009
    */
    FUNCTION create_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN table_number,
        i_id_dep_clin_serv      IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event          IN schedule.id_sch_event%TYPE,
        i_id_prof               IN sch_resource.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_flg_vacancy           IN schedule.flg_vacancy%TYPE,
        i_schedule_notes        IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator    IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred     IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason             IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin             IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref       IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room               IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type          IN schedule.flg_sch_type%TYPE,
        i_id_analysis           IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes          IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type      IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via      IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_show_vacancy_warn     IN BOOLEAN DEFAULT TRUE,
        i_do_overlap            IN VARCHAR2,
        i_id_consult_vac        IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option            IN VARCHAR2,
        i_id_episode            IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_complaint          IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_flg_present           IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_prof_leader        IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_multidisc          IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail   IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE DEFAULT NULL,
        i_flg_status            IN schedule.flg_status%TYPE DEFAULT NULL,
        i_id_institution        IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule           OUT schedule.id_schedule%TYPE,
        o_flg_proceed           OUT VARCHAR2,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * special create_schedule for single visits. creates an appointment for each detail
    * line of the combination supplied. APPOINTMENTS CAN BE OF VARIOUS SCHEDULING TYPES,
    * BUT ONLY THOSE WITH THE TRADITIONAL VACANCY TYPE, THAT IS, VACANCIES WITHOUT THE 
    * SLOT CONCEPT.
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_combi           combination id
    * @param i_ids_codes          comb. detail lines that are to be processed. table_table_number(table_number(id_code, id_vacancy), ...)
    * @param i_ids_patients       patient ids. Its a table number in order to support group appoints.
    * @param i_id_episode         episode id
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg                Message body to be displayed in flash
    * @param o_msg_title          Message title
    * @param o_error              error data
    *
    * return true / false
    *
    * @author   Telmo
    * @version  2.5.0.4
    * @date     23-06-2009
    */
    FUNCTION create_schedule_sv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_combi       IN sch_combi.id_sch_combi%TYPE,
        i_ids_codes      IN table_table_number,
        i_ids_patients   IN table_number,
        i_id_episode     IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_institution IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the cancel reason messsage to be used on reschedule operation.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.    
    * @param i_dt_begin               Start date
    * @param o_schedule_cancel_notes  Output message    
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Sofia Mendes (adapatado)
    * @version  2.5.x
    * @since    2009/06/17
    */
    FUNCTION get_cancel_notes_msg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_dt_begin              IN VARCHAR2,
        o_schedule_cancel_notes OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Reschedules an appointment.
    *
    * @param i_lang                   Language identifier.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Identifier of the appointment to be rescheduled.
    * @param i_id_prof                Target professional.
    * @param i_dt_begin               Start date
    * @param i_dt_end                 End date
    * @param i_do_overlap             null | Y | N. Instructions in case of an overlap found. If null, execution stops and another call should be
    *                                 issued with Y or N
    * @param i_id_consult_vac         id da vaga. Se for <> null significa que se trata de uma marcaçao normal ou alem-vaga
    * @param i_sch_option             'V'= marcar numa vaga; 'A'= marcar alem-vaga; 'F'= marcar sem vaga (fora do horario normal); 'U'= e' um update(vem do update_schedule)
    * @param o_id_schedule            Identifier of the new schedule.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/23
    *
    * UPDATED
    * added parameters to cope with new create_schedule
    * @author  Telmo Castro
    * @date    01-07-2008
    * @version 2.4.3
    */
    FUNCTION create_reschedule
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_old_id_schedule IN schedule.id_schedule%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_dt_begin        IN VARCHAR2,
        i_dt_end          IN VARCHAR2,
        i_do_overlap      IN VARCHAR2,
        i_id_consult_vac  IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_sch_option      IN VARCHAR2,
        i_id_institution  IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule     OUT schedule.id_schedule%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_flg_proceed     OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function is used to internally to call pk_sysconfig.get_config.
    * It logs a warning if the message does not exist.
    *
    * @param i_lang            Language (just used for error messages).
    * @param i_id_sysconfig    Parameter identifier.
    * @param i_prof            Professional.
    * @param o_config          Parameter value.
    * @param o_error           Error message (if an error occurred).
    *
    * @return   True if successful, false otherwise.
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/05/02
    */
    FUNCTION get_config
    (
        i_lang         IN language.id_language%TYPE,
        i_id_sysconfig IN sys_config.id_sys_config%TYPE,
        i_prof         IN profissional,
        o_config       OUT sys_config.value%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follows this schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    */
    FUNCTION validate_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv  IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event      IN schedule.id_sch_event%TYPE,
        i_id_prof           IN sch_resource.id_professional%TYPE,
        i_dt_begin          IN VARCHAR2,
        i_id_institution    IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_physiatry_area IN physiatry_area.id_physiatry_area%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follows this schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *
    * @param i_lang               Language
    * @param i_prof               Professional identification
    * @param i_id_patient         Patient identification
    * @param i_id_dep_clin_serv   Association between department and clinical service
    * @param i_id_sch_event       Event type
    * @param i_id_prof            Professional schedule target
    * @param i_dt_begin           Schedule begin date
    * @param o_error              Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Miguel Ferreira
    * @version  2.5.0.4
    * @since 01-07-2009
    */
    FUNCTION validate_schedule_multidisc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN table_number,
        i_dt_begin         IN VARCHAR2,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Determines if the given schedule information follow schedule rules :
    *  - Begin date cannot be null
    *  - Begin date should not be lower than the current date
    *  - Patient should not have the same appointment type for the same day
    *  - First appointment should not exist if a first appointment is being created
    *  - Episode validations
    *
    * @param i_lang                   Language.
    * @param i_prof                   Professional.
    * @param i_old_id_schedule        Old schedule identifier.
    * @param i_id_dep_clin_serv       Department-Clinical service identifier.
    * @param i_id_sch_event           Event identifier.
    * @param i_id_prof                Professional that carries out the schedule.
    * @param i_dt_begin               Begin date.
    * @param o_flg_proceed            Set to 'Y' if there is additional processing needed.
    * @param o_flg_show               Set to 'Y' if there is a message to show.
    * @param o_msg                    Message body.
    * @param o_msg_title              Message title.
    * @param o_button                 Buttons to show.
    * @param o_sv_stop                warning to the caller telling that this reschedule violates dependencies inside a single visit
    * @param o_error                  Error message if something goes wrong
    *
    * @return   TRUE if process is ok, FALSE otherwise
    * @author   Nuno Guerreiro (Tiago Ferreira)
    * @version  1.0
    * @since 2007/05/22
    *
    * UPDATED
    * i_id_dep_clin_serv can be null when validating exams reschedule
    * @author  Jose Antunes
    * @version 2.4.3
    * @date    01-09-2008
    */
    FUNCTION validate_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_old_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_tab_patients     IN table_number DEFAULT table_number(),
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_sv_stop          OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an appointment. This overload does what the cancel_schedule used to do before scheduler 3 showed up.
    * IT is still needed for use by pk_sr_grid, pk_schedule_exam and pk_schedule_outp.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo
    * @version  2.6.0.1
    * @date     18-05-2010
    */
    FUNCTION cancel_schedule_old
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an appointment.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /* previous cancel_schedule will call this one. 
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param i_transaction_id     SCH 3 bd transaction id
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo
    * @version 2.6.0.1
    * @date    17-05-2010
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancels an appointment. integration version
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param io_transaction_id    Transaction ID
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param o_error              Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/23
    *
    * UPDATED
    * added call to pk_p1_ext_sys.update_referral_status
    * @author  Jose Antunes
    * @date    04-08-2008
    * @version 2.4.3
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        io_transaction_id  IN OUT VARCHAR2,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * cancel an entire sv or only one of its schedules
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_cancel_all         Y = cancel all single visit schedules  N = cancel this one schedule
    * @param i_id_schedule        Schedule identifier.
    * @param i_id_cancel_reason   Cancel reason
    * @param i_cancel_notes       Cancel notes.
    * @param o_error              Error message, if an error occurred.
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.5.0.4
    * @date    29-06-2009
    */
    FUNCTION cancel_schedule_sv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_cancel_all       IN VARCHAR2 DEFAULT 'N',
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function returns (via output parameters) the begin and end dates
    * for the first compatible vacancy.
    *
    * @param i_lang                     Language identifier.
    * @param i_prof                     Professional.
    * @param i_search_date_begin        Begin date (for searching).
    * @param i_search_date_end          End date (for searching).
    * @param i_dt_begin                 Original schedule's begin date.
    * @param i_flg_sch_type             Type of schedule.
    * @param i_sch_event                Event type.
    * @param i_id_dep_clin_serv         Department's Clinical service.
    * @param i_id_prof                  Target professional.
    * @param i_id_exam                  Exam identifier.
    * @param i_id_analysis              Analysis identifier.
    * @param o_hour_begin               Begin date for the first compatible vacancy.
    * @param o_hour_end                 End date for the first compatible vacancy.
    * @param o_unplanned                1 if the schedule is to be created as unplanned, 0 otherwise.
    * @param o_error                    Error message (if an error occurred).
    *
    * @return  True if successful, false otherwise.
    * @author  Nuno Guerreiro (Tiago Ferreira)
    * @version alpha
    * @since   2007/04/26
    *
    * UPDATED
    * added parameter i_id_physarea to make this thang compatible with mfr scheduler
    *
    * @author  Telmo
    * @version 2.4.3.x
    * @date    29-01-2009
    */
    FUNCTION get_first_valid_vacancy
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_search_date_begin IN VARCHAR2,
        i_search_date_end   IN VARCHAR2,
        i_dt_begin          IN VARCHAR2,
        i_flg_sch_type      IN schedule.flg_sch_type%TYPE,
        i_sch_event         IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_dep_clin_serv  IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_prof           IN sch_consult_vacancy.id_prof%TYPE,
        i_id_physarea       IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        i_id_institution    IN institution.id_institution%TYPE DEFAULT NULL,
        o_hour_begin        OUT VARCHAR2,
        o_hour_end          OUT VARCHAR2,
        o_unplanned         OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Validates multiple reschedules.
    *
    * @param i_lang               Language identifier.
    * @param i_prof               Professional.
    * @param i_schedule           List of schedules (identifiers) to reschedule.
    * @param i_id_prof            Target professional's identifier.
    * @param i_dt_begin           Start date.
    * @param i_dt_end             End date.
    * @param i_id_dep             Selected department's identifier.
    * @param i_id_dep_clin_serv   Selected Department-Clinical Service's identifier.
    * @param i_id_event           Selected event's identifier.
    * @param i_id_exam            Selected exam's identifier.
    * @param i_id_analysis        Selected analysis' identifier.
    * @param i_id_phys_area       Selected physiatry area identifier
    * @param o_list_sch_hour      List of schedule identifiers + start date + end date (for schedules that can be rescheduled).
    * @param o_flg_proceed        Set to 'Y' if there is additional processing needed.
    * @param o_flg_show           Set to 'Y' if there is a message to show.
    * @param o_msg                Message body.
    * @param o_msg_title          Message title.
    * @param o_button             Buttons to show.
    * @param o_error              Error message if something goes wrong
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/25
    */
    FUNCTION validate_mult_reschedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_schedules        IN table_varchar,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_dep           IN VARCHAR2 DEFAULT NULL,
        i_id_dep_clin_serv IN VARCHAR2 DEFAULT NULL,
        i_id_event         IN VARCHAR2 DEFAULT NULL,
        i_id_exam          IN VARCHAR2 DEFAULT NULL,
        i_id_analysis      IN VARCHAR2 DEFAULT NULL,
        i_id_phys_area     IN VARCHAR2 DEFAULT NULL,
        o_list_sch_hour    OUT table_varchar,
        o_flg_proceed      OUT VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns data for the multiple search cross-view.
    *
    * @param i_lang   Language identifier.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    */
    FUNCTION get_availability_cross_mult
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_table_varchar,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the availability for the cross-view.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional.
    * @param i_args         UI args.
    * @param o_vacants      Vacancies.
    * @param o_schedules    Schedules.
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/28
    */
    FUNCTION get_availability_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_vacants   OUT pk_types.cursor_type,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the translation needs for use on the translators' cross-view.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_args           UI Args.
    * @param o_schedules      Translation needs.
    * @param o_error          Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/06/28
    */
    FUNCTION get_translators_crossview
    (
        i_lang      IN language.id_language%TYPE DEFAULT NULL,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns all the notification types for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_flg_search       flag to set if the "all" type is used or not
    * @param      o_notification_types   list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2006/12/21
    */
    FUNCTION get_notification_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_search         IN VARCHAR2,
        o_notification_types OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns all the scheduling ways (meios de marcacao) for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_via_types       list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Telmo Castro
    * @version    2.4.3
    * @since      12-05-2008
    */
    FUNCTION get_schedule_vias
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_via_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns all the request types for the multi-choice
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      o_req_types        list of types
    * @param      o_error            Error message
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Telmo Castro
    * @version    2.4.3
    * @since      12-05-2008
    */
    FUNCTION get_request_types
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_via_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets an image's name, according to the functionality type (next vacancies or appointments)
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_next_type      Next vacancies or appointments
    * @param i_schedule       Appointment
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2007/05/11
    */
    FUNCTION get_image_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_next_type IN sys_domain.code_domain%TYPE,
        i_schedule  IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    /*
    * Gets a professional's schedules that are inside a time range.
    *
    * @param i_lang           Language identifier.
    * @param i_prof           Professional.
    * @param i_dt_schedule    Selected date
    * @param i_args           UI search arguments
    * @param o_future_apps    List of events.
    * @param o_error          Error message (if an error occurred).
    *
    * @return     boolean type       "False" on error or "True" if success
    * @author     Tiago Ferreira
    * @version    alpha
    * @since      2007/05/11
    */
    FUNCTION get_proximity_schedules
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_schedule IN VARCHAR2,
        i_args        IN table_varchar,
        o_future_apps OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * It resets the vacancies to the default values for the given institution.
    * Default values are stored in SCH_DEFAULT_CONSULT_VACANCY.
    *
    * @param   i_id_inst      Institution
    * @param   i_id_software  Software
    * @param   i_lang         Language
    * @param   o_error        Error message if an error occurred
    *
    * @return  boolean type   , "False" on error or "True" if success
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version 0.1
    * @since   2007/07/04
    */
    FUNCTION reset
    (
        i_id_inst     IN institution.id_institution%TYPE,
        i_id_software IN software.id_software%TYPE,
        i_lang        IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates consult schedules.
    * NOTE: this function is used by PK_RESET only.
    *
    * @param      i_lang               Default language
    * @param      i_patient            Patient
    * @param      i_id_clin_serv       Clinical service (consult type)
    * @param      i_id_prof_schedules  Professional who creates the schedule
    * @param      i_prof_scheduled     Professional who is scheduled
    * @param      i_dep                Department
    * @param      i_dt_target          Target date
    * @param      o_error              Error coming right at you!!!! data to return
    * @param      i_id_sch_event       Event (optional)
    *
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Cláudia Silva)
    * @version    alpha
    * @since      2007/07/05
    */
    FUNCTION create_schedule_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_patient           IN sch_group.id_patient%TYPE,
        i_id_clin_serv      IN clinical_service.id_clinical_service%TYPE,
        i_id_prof_schedules IN profissional,
        i_prof_scheduled    IN professional.id_professional%TYPE,
        i_dep               IN department.id_department%TYPE,
        i_dt_target         IN schedule_outp.dt_target_tstz%TYPE,
        i_flg_present       IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_multidisc      IN schedule.id_multidisc%TYPE DEFAULT NULL,
        o_error             OUT t_error_out,
        i_id_sch_event      IN sch_event.id_sch_event%TYPE DEFAULT NULL
    ) RETURN BOOLEAN;

    /*
    * Sets the permission flag for several tuples of event-target professional-dcs, for a given professional.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Logged professional.
    * @param i_flg_permission      Permission flag ('S' schedule, 'R' read)
    * @param i_to_prof             Professional whose permissions are being altered.
    * @param i_on_profs            Target professionals list.
    * @param i_events              Events list.
    * @param i_on_dep_clin_servs   Department-Clinical service associations list
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/10
    */
    FUNCTION set_permission
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_permission    IN sch_permission.flg_permission%TYPE,
        i_to_prof           IN sch_permission.id_prof_agenda%TYPE,
        i_on_profs          IN table_number,
        i_events            IN table_number,
        i_on_dep_clin_servs IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the clinical service identifier.
    *
    * @param   i_id_dcs         dep_clin_serv identifier
    *
    * @return  Returns associated clinical service identifier
    * @author  Nuno Guerreiro (Ricardo Pinho)
    * @version alpha
    * @since   2007/04/24
    */
    FUNCTION get_id_clin_serv(i_id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE)
        RETURN clinical_service.id_clinical_service%TYPE;

    /**
    * This function returns the availability for each day on a given period.
    * For that, it considers one or more lists of search criteria.
    * Each day can be fully scheduled, half scheduled or empty.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria matrix (each element represent a search criteria set).
    * @param i_id_patient          Patient.
    * @param o_days_status         List of status per date.
    * @param o_days_date           List of dates.
    * @param o_days_free           List of total free slots per date.
    * @param o_days_sched          List of total schedules per date.
    * @param o_patient_icons       Patient icons for showing the days when the patient has schedules.
    * @param o_error               Error message (if an error occurred).
    * @return  True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/07/19
    */
    FUNCTION get_availability_mult
    (
        i_lang          IN language.id_language%TYPE DEFAULT NULL,
        i_prof          IN profissional,
        i_args          IN table_table_varchar,
        i_id_patient    IN patient.id_patient%TYPE,
        o_days_status   OUT table_varchar,
        o_days_date     OUT table_varchar,
        o_days_free     OUT table_number,
        o_days_sched    OUT table_number,
        o_patient_icons OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Performs the core validation for creating appointments using the
    * multi-search screens.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_args                UI search criteria.
    * @param i_sch_args            Appointment criteria.
    * @param i_flg_sch_type        Schedule type
    * @param o_dt_begin            Appointment's start date
    * @param o_dt_end              Appointment's end date
    * @param o_flg_proceed         Whether or not should the screen perform additional processing after this execution
    * @param o_flg_show            Whether or not should a semantic error message be shown to the used
    * @param o_msg                 Semantic error message to show (if invalid parameters were given or an invalid action was attempted)
    * @param o_msg_title           Semantic error title message
    * @param o_button              Buttons to show
    * @param o_flg_vacancy         Vacancy flag
    * @param o_error  Error message, if an error occurred.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/07/23
    */
    FUNCTION validate_schedule_mult
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_args         IN table_varchar,
        i_sch_args     IN table_varchar,
        i_flg_sch_type IN VARCHAR2,
        o_dt_begin     OUT VARCHAR2,
        o_dt_end       OUT VARCHAR2,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_flg_vacancy  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a vacancy is available, taking into account the professional's absence periods
    *
    * @param   i_id_vacancy  Vacancy identifier
    *
    * @return  'Y' if the vacancy is available, 'N' otherwise
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/17
    */
    FUNCTION is_vacancy_available(i_id_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE) RETURN VARCHAR2;

    /**
    * Checks if an appointment is on conflict, taking into account the professional's absence periods
    *
    * @param   i_id_sch  Schedule identifier
    *
    * @return  'Y' if the appointment is on conflict, 'N' otherwise
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/17
    */
    FUNCTION is_conflicting(i_id_sch IN schedule.id_schedule%TYPE) RETURN VARCHAR2;

    /**
    * Gets the list of conflicting appointments, from those passed as argument.
    *
    * @param  i_lang                    Language identifier
    * @param  i_prof                    Professional
    * @param  i_list_sch                List of appointments to test
    * @param  o_list_sch                List of conflicting appointments
    * @param  o_error                   Error message.
    *
    * @return True if successful, false otherwise.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since  2007/09/17
    */
    FUNCTION get_conflicting_appointments
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_list_sch IN table_number,
        o_list_sch OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the details of the appointments that are conflicting with some absence period.
    *
    * @param i_lang       Language identifier
    * @param i_prof       Professional
    * @param i_args       UI Search criteria
    * @param o_schedules  Appointments' details
    * @param o_error      Error message, if an error ocurred
    *
    * @return True if successful, false otherwise.
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/18
    */
    FUNCTION get_conflicts_to_clipboard
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_args      IN table_varchar,
        o_schedules OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Configuration of vacancies in present institution and software, as given by table sch_vacancy_usage.
    * configuration comprises:
    * flg_use = (Y/N) Indicates whether or not should vacancies be consumed. That is, if a schedule’s creation should mark the vacancy as used
    * flg_sched_without_vac = (Y/N) Indicates if it is possible to create schedules without an associated vacancy. In this case the column
    *                         schedule.id_sch_consult_vacancy stays empty.
    * flg_edit_vac = (Y/N) Indicates that a schedule’s vacancy (if there is one) can be modified if that same schedule is altered.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_dept                  department id
    * @param i_dep_type                 scheduling type
    * @param o_flg_use                  see above
    * @param o_flg_sched_without_vac    see above
    * @param o_flg_edit_vac             see above
    *
    * @return True if successful, false otherwise.
    *
    * @author  Telmo castro
    * @version 2.4.3
    * @since   24-05-2008
    */
    FUNCTION get_vacancy_config
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_dept               IN sch_department.id_department%TYPE,
        i_dep_type              IN sch_department.flg_dep_type%TYPE,
        i_id_institution        IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_use               OUT sch_vacancy_usage.flg_use%TYPE,
        o_flg_sched_without_vac OUT sch_vacancy_usage.flg_sched_without_vac%TYPE,
        o_flg_edit_vac          OUT sch_vacancy_usage.flg_edit_vac%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    *  Inactiva o episódio e a visita para o agendamento cancelado (EHR ACCESS)
    *
    * @param i_lang         the id language
    * @param i_prof         profissional
    * @param i_id_schedule  id do agendamento
    * @return               TRUE if sucess, FALSE otherwise
    *
    * @author               Teresa Coutinho
    * @version              1.0
    * @since                2008/05/24
    **********************************************************************************************/

    FUNCTION cancel_sch_epis_ehr
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_sysdate      IN DATE,
        i_sysdate_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks schedule overlap with existing schedules.
    * Overlap checked against the professional and institution.
    *
    * @param   i_lang              Language
    * @param   i_id_prof              Professional id
    * @param   i_id_institution    institution id
    * @param   i_start_date        Schedule start date
    * @param   i_end_date          Schedule End date
    * @param   o_overlap           Overlap flag. Y - with overlap. N - no overlap
    * @param   o_error             Error message if an error occurred
    *
    * @return  boolean type        "False" on error or "True" if success
    * @author  Luís Gaspar
    * @version 0.1
    * @since   2008/05/27
    */
    FUNCTION get_schedule_overlap
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN sch_resource.id_professional%TYPE,
        i_id_institution IN sch_resource.id_institution%TYPE,
        i_start_date     IN schedule.dt_begin_tstz%TYPE,
        i_end_date       IN schedule.dt_end_tstz%TYPE,
        o_overlap        OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks vacancy overlap with existing vacancies.
    * Overlap checked against the professional and institution and free vacancies don't overlap.
    *
    * @param   i_lang              Language
    * @param   i_prof              Professional.
    * @param   i_start_date        Schedule start date
    * @param   i_end_date          Schedule End date
    * @param   o_overlap           Overlap flag. Y - with overlap. N - no overlap
    * @param   o_error             Error message if an error occurred
    *
    * @return  boolean type        "False" on error or "True" if success
    * @author  Luís Gaspar
    * @version 0.1
    * @since   2008/05/26
    */
    FUNCTION get_vac_overlap
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_start_date IN schedule.dt_begin_tstz%TYPE,
        i_end_date   IN schedule.dt_end_tstz%TYPE,
        o_overlap    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of schedule reasons, depending on sys_config configuration.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_episode              Episode ID
    * @param      i_flg_type             register type: E - edit, N - new
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
    * @param      o_reasons              Schedule reasons
    * @param      o_value_conf           Value of configuration - (R)eason, (C)omplaint
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Jose Antunes
    * @version    0.1
    * @since      2008/09/02
    */
    FUNCTION get_schedule_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_type         IN VARCHAR2,
        i_flg_search       IN VARCHAR2,
        o_reasons          OUT pk_types.cursor_type,
        o_value_conf       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a complaint's translated description
    * To be used inside SELECTs
    *
    * @param i_lang
    * @param i_id_complaint
    *
    * @author  Jose Antunes
    * @version 0.1
    * @since   2008/09/04
    */
    FUNCTION string_complaint
    (
        i_lang         IN language.id_language%TYPE,
        i_id_complaint IN schedule.id_reason%TYPE
    ) RETURN VARCHAR2;

    /*
    * Gets the details of the appointments to be put on the clipboard.
    *
    * @param i_lang
    * @param i_prof
    * @param i_args
    * @param o_schedules
    * @param o_error
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/09/18
    *
    * UPDATED
    * Adição de coluna exam_name ao cursor
    * @author   Jose Antunes
    * @version  2.4.3.x
    * @date     20-10-2008
    */
    FUNCTION get_appointments_clip_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_list_schedules IN table_number,
        o_schedules      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a list of schedule reasons, depending on sys_config configuration.
    *
    * @param      i_lang                 Language
    * @param      i_prof                 Professional
    * @param      i_id_dep_clin_serv     Department-clinical service
    * @param      i_id_patient           Patient
    * @param      i_episode              Episode ID
    * @param      i_flg_type             register type: E - edit, N - new
    * @param      i_flg_search           Whether or not should the 'All' option be returned in o_reasons cursor.
    * @param      i_consult_req          id of consult requisition
    * @param      o_reasons              Schedule reasons
    * @param      o_error                Error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Elisabete Bugalho
    * @version    0.1
    * @since      2009/03/25
    */
    FUNCTION get_schedule_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN VARCHAR2,
        i_id_patient       IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_type         IN VARCHAR2,
        i_flg_search       IN VARCHAR2,
        i_consult_req      IN consult_req.id_consult_req%TYPE,
        o_reasons          OUT pk_types.cursor_type,
        o_value_conf       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_validation_msgs
    (
        i_lang         IN language.id_language%TYPE,
        i_code_msg     IN sys_message.code_message%TYPE,
        i_pkg_name     IN VARCHAR2,
        i_replacements IN table_varchar,
        o_message      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_repeatition_patterns
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_repeat_by_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_on_weeks_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN VARCHAR2,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_end_by_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_yes_no_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_availability_cross_sv
    (
        i_lang       IN language.id_language%TYPE DEFAULT NULL,
        i_prof       IN profissional,
        i_startdate  IN VARCHAR2,
        i_id_combi   IN sch_combi.id_sch_combi%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_vacancies  OUT pk_types.cursor_type,
        o_schedules  OUT pk_types.cursor_type,
        o_combos     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Schedule for Multidisciplinary Appointments
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param .....
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Nuno Miguel Ferreira
    * @version                               2.5.0.4
    * @since                                 2009/06/19
    **********************************************************************************************/
    FUNCTION create_schedule_multidisc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN table_number,
        i_id_dep_clin_serv_list   IN table_number,
        i_id_sch_event            IN schedule.id_sch_event%TYPE,
        i_id_prof_list            IN table_number,
        i_dt_begin                IN VARCHAR2,
        i_dt_end                  IN VARCHAR2,
        i_flg_vacancy             IN schedule.flg_vacancy%TYPE,
        i_schedule_notes          IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_translator      IN schedule.id_lang_translator%TYPE DEFAULT NULL,
        i_id_lang_preferred       IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason               IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin               IN schedule.id_origin%TYPE DEFAULT NULL,
        i_id_schedule_ref         IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_room                 IN schedule.id_room%TYPE DEFAULT NULL,
        i_flg_sch_type            IN schedule.flg_sch_type%TYPE DEFAULT 'C',
        i_id_exam                 IN exam.id_exam%TYPE DEFAULT NULL,
        i_id_analysis             IN analysis.id_analysis%TYPE DEFAULT NULL,
        i_reason_notes            IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_flg_request_type        IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_flg_schedule_via        IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_show_vacancy_warn       IN BOOLEAN DEFAULT TRUE,
        i_do_overlap              IN VARCHAR2,
        i_id_consult_vac_list     IN table_number,
        i_sch_option              IN VARCHAR2,
        i_id_episode              IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_id_complaint            IN complaint.id_complaint%TYPE DEFAULT NULL,
        i_flg_present             IN schedule.flg_present%TYPE DEFAULT NULL,
        i_id_prof_leader          IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_id_dep_clin_serv_leader IN schedule.id_dcs_requested%TYPE,
        i_id_multidisc            IN schedule.id_multidisc%TYPE DEFAULT NULL,
        i_id_sch_combi_detail     IN schedule.id_sch_combi_detail%TYPE DEFAULT NULL,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_id_schedule             OUT schedule.id_schedule%TYPE,
        o_flg_proceed             OUT VARCHAR2,
        o_flg_show                OUT VARCHAR2,
        o_msg                     OUT VARCHAR2,
        o_msg_title               OUT VARCHAR2,
        o_button                  OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS
    ------------------------- SERIES APPOINTMENTS FUNCTIONS

    -- FUNCTION INS_SCH_SERIES_RECURSION
    FUNCTION ins_schedule_recursion
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE,
        i_flg_regular           IN schedule_recursion.flg_regular%TYPE DEFAULT NULL,
        i_flg_timeunit          IN schedule_recursion.flg_timeunit%TYPE DEFAULT NULL,
        i_num_take              IN schedule_recursion.num_take%TYPE DEFAULT NULL,
        i_num_freq              IN schedule_recursion.num_freq%TYPE DEFAULT NULL,
        i_id_interv_presc_det   IN schedule_recursion.id_interv_presc_det%TYPE DEFAULT NULL,
        i_repeat_frequency      IN schedule_recursion.repeat_frequency%TYPE DEFAULT NULL,
        i_weekdays              IN schedule_recursion.weekdays%TYPE DEFAULT NULL,
        i_week                  IN schedule_recursion.week%TYPE DEFAULT NULL,
        i_day_month             IN schedule_recursion.day_month%TYPE DEFAULT NULL,
        i_month                 IN schedule_recursion.month%TYPE DEFAULT NULL,
        i_begin_date            IN schedule_recursion.dt_begin%TYPE DEFAULT NULL,
        i_end_date              IN schedule_recursion.dt_end%TYPE DEFAULT NULL,
        i_flg_type_rep          IN schedule_recursion.flg_type_rep%TYPE DEFAULT NULL,
        i_flg_type              IN schedule_recursion.flg_type%TYPE DEFAULT NULL,
        o_id_schedule_recursion OUT schedule_recursion.id_schedule_recursion%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    -- FUNCTION GET_SCH_SERIES_COMPUTED_DATES       
    FUNCTION get_sch_series_computed_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_timeunit   IN VARCHAR2,
        i_flg_end_by     IN VARCHAR2,
        i_nr_events      IN NUMBER,
        i_repeat_every   IN NUMBER,
        i_weekday        IN NUMBER,
        i_day_of_month   IN NUMBER,
        i_week           IN NUMBER,
        i_sch_start_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_sch_end_date   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_month          IN NUMBER,
        o_flg_irregular  OUT VARCHAR2,
        o_dates          OUT table_timestamp_tz,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- FUNCTION CANCEL_SCHEDULE_SERIES
    FUNCTION cancel_schedule_series
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_flg_all_series   IN VARCHAR2 DEFAULT 'N',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_schedule_series
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_sch_series  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION val_sch_series_computed_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_vacancy          OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_sch_series_appointments
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_id_prof          IN sch_resource.id_professional%TYPE,
        i_start_date       IN VARCHAR2,
        i_end_date         IN VARCHAR2,
        -- compute dates arguments
        i_flg_timeunit            IN VARCHAR2,
        i_flg_end_by              IN VARCHAR2,
        i_nr_events               IN NUMBER,
        i_repeat_every            IN NUMBER,
        i_weekday                 IN NUMBER,
        i_day_of_month            IN NUMBER,
        i_week                    IN NUMBER,
        i_rep_start_date          IN VARCHAR2,
        i_rep_end_date            IN VARCHAR2,
        i_month                   IN NUMBER,
        i_id_institution          IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_irregular           OUT VARCHAR2,
        o_sch_series_appointments OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION is_series_appointment(i_id_schedule IN schedule.id_schedule%TYPE) RETURN VARCHAR2;

    FUNCTION get_repeatition_pat(i_id_schedule IN schedule.id_schedule%TYPE) RETURN VARCHAR2;

    FUNCTION validate_conflict
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_mode        IN NUMBER DEFAULT 1
        
    ) RETURN VARCHAR2;

    FUNCTION validate_before_confirm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_sch_event     IN schedule.id_sch_event%TYPE,
        i_flg_sch_type     IN schedule.flg_sch_type%TYPE,
        i_id_dep_clin_serv IN schedule.id_dcs_requested%TYPE,
        i_tab_status       IN table_varchar,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_flg_show         OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION confirm_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_value_date_schedule
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_schedule_recursion IN schedule_recursion.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_num_events_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_schedule_recursion IN schedule.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_schedule_profs
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule_recursion.id_schedule_recursion%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_notifications
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_patient   IN sch_group.id_patient%TYPE,
        o_domain       OUT pk_types.cursor_type,
        o_actual_event OUT pk_types.cursor_type,
        o_to_notify    OUT pk_types.cursor_type,
        o_notified     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_notifications
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_tab_id_nots      IN table_number,
        i_tab_types        IN table_varchar,
        i_flg_notification IN schedule.flg_notification%TYPE,
        i_flg_not_via      IN schedule.flg_schedule_via%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_value_det_schedule
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_schedule_intervention IN VARCHAR2,
        i_code                  IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_locations
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION calc_icon
    (
        i_lang        IN language.id_language%TYPE,
        i_id_sched    IN NUMBER,
        i_id_inst     IN schedule.id_instit_requested%TYPE,
        i_id_dcs      IN schedule.id_dcs_requested%TYPE,
        i_id_event    IN schedule.id_sch_event%TYPE,
        i_dt_begin    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end      IN schedule.dt_end_tstz%TYPE,
        i_id_prof     IN sch_resource.id_professional%TYPE,
        i_id_room     IN schedule.id_room%TYPE,
        i_flg_tempor  IN schedule_sr.flg_temporary%TYPE,
        i_flg_status  IN schedule.flg_status%TYPE,
        i_flg_vacancy IN schedule.flg_vacancy%TYPE,
        i_id_vac      IN schedule.id_sch_consult_vacancy%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_count_and_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_count       OUT NUMBER,
        o_rank        OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_and_rank
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sch_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_sch   IN schedule.id_schedule%TYPE,
        o_sch_type OUT schedule.flg_sch_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION is_notified
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_notifications_mfr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notifications_series
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_notifications_general
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tab_id_schedule IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_conf_pend_schs2
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_id_flg_notification IN schedule.flg_notification%TYPE,
        i_id_schedule_actual  IN schedule.id_schedule%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function returns the patient ongoing tasks, in this context schedules, that can be canceled.
    * Output is in a special form, the type tr_tasks_list.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_patient        patient id
    *
    * @return tf_tasks_list      this is a nested table of object tr_tasks_list
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    24-05-2010
    */
    FUNCTION get_ongoing_tasks_scheduler
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN sch_group.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function cancels the task identified by i_id_task.
    * In case of success, function returns true. Otherwise returns false and o_msg_error is filled.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_task           task id (id_schedule). must be one of those coming out of a previous get_ongoing_tasks_scheduler invocation.
    * @param   I_FLG_REASON      Reason for the WF suspension: 'D' (Death)
    * @param i_transaction_id    trans. id for remote scheduler actions. If this function's invoker wants control over transactions must supply one
    * @param o_msg_error         output error msg 
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    24-05-2010
    */
    FUNCTION suspend_task_scheduler
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task        IN NUMBER,
        i_flg_reason     IN VARCHAR2,
        i_transaction_id IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * ALERT-14509. Interruption of workflows due to patient decease. 
    * This function reactivates a task identified by i_id_task which was previously cancelled by mistake.
    * In case of success, function returns true. Otherwise returns false and o_msg_error is filled.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_task           task id (id_schedule). task to reactivate
    * @param i_transaction_id    trans. id for remote scheduler actions. If this function's invoker wants control over transactions must supply one
    * @param o_msg_error         output error msg 
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    24-05-2010
    */
    FUNCTION reactivate_task_scheduler
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task        IN NUMBER,
        i_transaction_id IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* 
    * SCH-2812 
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.1.0.1
    * @date    10-05-2011
    */
    FUNCTION get_procedure_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_flg_sch_type IN schedule.flg_sch_type%TYPE,
        i_id_sch_event IN schedule.id_sch_event%TYPE,
        i_id_dcs_req   IN schedule.id_dcs_requested%TYPE
    ) RETURN VARCHAR2;

    /* ALERT-298702
    * Lista de profissionais que foram agendados para um dado paciente.
    * Exclui agendamentos cancelados.
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.4.2.1
    * @date    16-10-2014
    */
    FUNCTION get_patient_scheds
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /* ALERT-303513 
    * Add schedule notes to a schedule. A backup is performed.
    *
    * @param i_lang              Language ID
    * @param i_id_schedule       target schedule
    * @param i_notes             new schedule_notes
    * @param o_error             error info
    *
    * @return   true/false
    *
    * @author  Telmo
    * @version 2.6.4.3
    * @date    10-12-2014
    */
    FUNCTION set_schedule_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_notes       IN schedule.schedule_notes%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_appointment_type
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_sch_event IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_schedule_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /**
    * Returns the video conference information for video conference room 
    *
    * @param i_lang                language id
    * @param i_institution         institution id
    * @param i_software            software id
    * @param i_speciality          id_dcs_requested
    * @param i_id_professional     Professional id
    * @param i_dt_schedule         appointment schedule date
    * @param o_server_time         server time
    * @param o_waiting_time        average of waiting time for video conferece appointments
    * @param o_speciality_desc
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Ana Moita
    * @since                       10-07-2020
    * @version                     2.8.1.6
    */

    FUNCTION get_videoconf_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_schedule        IN sch_api_map_ids.id_schedule_ext%TYPE,
        o_server_time     OUT VARCHAR2,
        o_waiting_time    OUT NUMBER,
        o_speciality_desc OUT VARCHAR2,
        o_id_professional OUT NUMBER,
        o_inst_name       OUT VARCHAR2,
        o_inst_logo       OUT BLOB,        
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_videoconf_prof(i_id_schedule IN schedule.id_schedule%TYPE) RETURN NUMBER;

    FUNCTION set_videoconf_pat_register
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------- GLOBALS -----------------------------------
    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    /* Message stack for storing multiple warning/error messages. */
    TYPE t_msg_stack IS RECORD(
        idxmsg NUMBER(4),
        msg    VARCHAR2(2000));

    TYPE t_table_msg_stack IS TABLE OF t_msg_stack;
    g_msg_stack t_table_msg_stack;

    /* Date date mask. */
    g_default_date_mask CONSTANT VARCHAR2(16) := 'yyyymmddhh24mi';
    /* Date date mask with no time. */
    g_default_date_no_time_mask CONSTANT VARCHAR2(16) := 'yyyymmdd';
    /* Date time mask. */
    g_default_time_mask CONSTANT VARCHAR2(16) := 'hh24mi';
    /* Default time mask for presentation */
    g_default_time_mask_msg CONSTANT VARCHAR2(16) := 'hh24:mi';
    /* Date day mask. */
    g_default_day_mask CONSTANT VARCHAR2(2) := 'dd';
    /* Date month mask. */
    g_default_month_mask CONSTANT VARCHAR2(2) := 'mm';
    /* Date year mask. */
    g_default_year_mask CONSTANT VARCHAR2(4) := 'yyyy';
    /* Hour mask */
    g_default_hour_mask CONSTANT VARCHAR2(4) := 'hh24';
    /* Minute mask */
    g_default_minute_mask CONSTANT VARCHAR2(2) := 'mi';

    /* Default number of days for proximity checks (e.g. vacants, schedules, etc) */
    g_range_days_default CONSTANT NUMBER(3) := 365;

    /* Icon name prefix */
    g_icon_prefix CONSTANT VARCHAR(6) := 'xxxxxx';

    /* Message code for <Day> of <Month> of <Year>. */
    g_day_of_month_of_year CONSTANT VARCHAR2(8) := 'SCH_T026';
    /* Message code for <Month> of <Year>. */
    g_month_of_year CONSTANT VARCHAR2(8) := 'SCH_T040';
    /* Message code for <Day> of <Month> of <Year> at <Hours> and <Minutes> */
    g_day_of_month_of_year_hm CONSTANT VARCHAR2(8) := 'SCH_T119';
    /* Message code for 'hours'. */
    g_hours CONSTANT VARCHAR2(8) := 'SCH_T100';
    /* Message code for 'hour'. */
    g_hour CONSTANT VARCHAR2(8) := 'SCH_T102';
    /* Message code for 'minute'. */
    g_minute CONSTANT VARCHAR2(8) := 'SCH_T101';
    /* Message code for 'minutes'. */
    g_minutes CONSTANT VARCHAR2(8) := 'SCH_T099';
    /* Message code for 'and'. */
    g_date_and CONSTANT VARCHAR2(8) := 'SCH_T103';
    /* Message code for 'All' */
    g_msg_all CONSTANT VARCHAR2(9) := 'SCH_Todos';
    /* Message for localized date mask */
    g_msg_date_mask CONSTANT VARCHAR2(8) := 'SCH_T125';

    /* Message for department label */
    g_department_label CONSTANT VARCHAR2(8) := 'SCH_T001';
    /* Message for appointment type label */
    g_appt_type_label CONSTANT VARCHAR2(8) := 'SCH_T002';
    /* Message for event type label */
    g_evt_tp_label CONSTANT VARCHAR2(8) := 'SCH_T003';
    /* Message for professional label */
    g_professional_label CONSTANT VARCHAR2(8) := 'SCH_T004';
    /* Message for duplicate events */
    g_dup_evt_label CONSTANT VARCHAR2(8) := 'SCH_T113';
    /* Message for begin date lower than current date */
    g_dt_bg_lw_cr_dt CONSTANT VARCHAR2(8) := 'SCH_T111';
    /* Message for a first existing appointment */
    g_first_exist CONSTANT VARCHAR2(8) := 'SCH_T115';
    /* Schedule does not match the search parameters, therefore it can't be rescheduled */
    g_sch_does_not_match_params CONSTANT VARCHAR2(8) := 'SCH_M136';
    /* Cancel button label */
    g_cancel_button CONSTANT VARCHAR2(8) := 'SCH_T065';
    /* Rescheduled from <date> to <date> message */
    g_rescheduled_from_to CONSTANT VARCHAR2(8) := 'SCH_T117';

    /* Title for group reschedule confirmation */
    g_resched_group CONSTANT VARCHAR2(8) := 'SCH_T721';

    /* Title for group reschedule confirmation */
    g_resched_group_pat CONSTANT VARCHAR2(8) := 'SCH_T723';

    /* Message for episode rules first appoitment */
    g_epis_rule_first CONSTANT VARCHAR2(8) := 'SCH_M001';
    /* Message for episode rules subsequent appointment */
    g_epis_rule_subsequent CONSTANT VARCHAR2(8) := 'SCH_M002';

    /* Prefix for getting days of the week */
    g_msg_monthview_prefix CONSTANT VARCHAR2(13) := 'SCH_MONTHVIEW';
    /* Prefix for getting month names */
    g_msg_month_prefix CONSTANT VARCHAR2(9) := 'SCH_MONTH';
    /* Prefix for getting day names */
    g_msg_day_prefix CONSTANT VARCHAR2(13) := 'SCH_MONTHVIEW';

    /* First appointment events */
    g_event_occurrence_first CONSTANT VARCHAR2(1) := 'F';
    /* Subsequent appointment events */
    g_event_occurrence_subs CONSTANT VARCHAR2(1) := 'S';
    /* Both (first + subsequent) appointment events */
    g_event_occurrence_both CONSTANT VARCHAR2(1) := 'B';
    /* Normal events (nor first neither subsequent) */
    g_event_occurrence_normal CONSTANT VARCHAR2(1) := 'N';
    /* Subsequent and first appointment events */
    g_event_occurrence_sub_first CONSTANT VARCHAR2(1) := 'T';

    /* Schedule warning (vacancy is already occupied) title */
    g_sched_msg_warning_title CONSTANT VARCHAR2(8) := 'SCH_T123';

    /* Schedule error title */
    g_sched_msg_error_title CONSTANT VARCHAR2(8) := 'SCH_T112';

    /* Schedule warning (vacancy is already occupied) */
    g_sched_msg_warning CONSTANT VARCHAR2(8) := 'SCH_T132';

    /* Schedule warning (vacancy is not occupied) */
    g_sched_msg_warning_not_occu CONSTANT VARCHAR2(8) := 'SCH_T269';

    /* Ignore and proceed message */
    g_sched_msg_ignore_proceed CONSTANT VARCHAR2(8) := 'SCH_T122';

    /* OK message */
    g_sched_msg_ok CONSTANT VARCHAR2(8) := 'SCH_T133';

    /* OK message */
    g_sched_msg_read CONSTANT VARCHAR2(8) := 'SCH_T809';

    /* Confirmation message for a single reschedule */
    g_single_reschedule_conf CONSTANT VARCHAR2(8) := 'SCH_T093';

    /* Confirmation message for a single reschedule */
    g_single_reschedule_conf_past CONSTANT VARCHAR2(8) := 'SCH_M133';

    /* Message to be shown when a reschedule fails due to a bad event. */
    g_sched_msg_resched_bad_event CONSTANT VARCHAR2(8) := 'SCH_T105';

    /* Message to be shown when a reschedule fails due to a bad exam. */
    g_sched_msg_resched_bad_exam CONSTANT VARCHAR2(8) := 'SCH_T275';

    /* Message to be shown when a reschedule fails due to a bad department-clinical service. */
    g_sched_msg_resched_bad_dcs CONSTANT VARCHAR2(8) := 'SCH_T104';

    /* Message to be shown when a schedule creation (multiple-search) fails due to a bad department-clinical service. */
    g_sched_msg_sched_mult_bad_dcs CONSTANT VARCHAR2(8) := 'SCH_T149';

    /* Message to be shown when a schedule creation (multiple-search) fails due to a bad event. */
    g_sched_msg_sched_mult_bad_evt CONSTANT VARCHAR2(8) := 'SCH_T150';

    /* Message to be shown when a schedule creation (multiple-search) fails due to a bad professional. */
    g_sched_msg_sched_mult_bad_prf CONSTANT VARCHAR2(8) := 'SCH_T151';

    /* Message to be shown when a schedule creation (multiple-search) fails due to a bad exam. */
    g_sched_msg_sched_mult_bad_exm CONSTANT VARCHAR2(8) := 'SCH_T152';

    /* Message to be shown when a schedule creation (multiple-search) fails due to a bad analysis. */
    g_sched_msg_sched_mult_bad_ans CONSTANT VARCHAR2(8) := 'SCH_T153';

    /* Message (includes patient name) to be shown when a schedule is rescheduled as "unplanned" */
    g_resched_unplanned_with_name CONSTANT VARCHAR2(8) := 'SCH_M125';

    /* Message (includes patient name) to be shown when a schedule cannot be rescheduled  */
    g_resched_no_vacancy_name CONSTANT VARCHAR2(8) := 'SCH_M127';

    /* Message to be shown when a schedule cannot be rescheduled */
    g_resched_no_vacancy CONSTANT VARCHAR2(8) := 'SCH_M128';

    /* Message (includes patient name) to be shown when a schedule can be rescheduled */
    g_resched_ok_with_name CONSTANT VARCHAR2(8) := 'SCH_M129';

    /* Message to be shown when a schedule can be rescheduled */
    g_resched_ok CONSTANT VARCHAR2(8) := 'SCH_M130';

    /* Message to be shown when a schedule is created as "unplanned" (multi-search)*/
    g_sched_mult_unplanned CONSTANT VARCHAR2(8) := 'SCH_M137';

    /* Message to be shown when a schedule cannot be created (multi-search) */
    g_sched_mult_no_vacancy CONSTANT VARCHAR2(8) := 'SCH_M138';

    /* Confirmation label */
    g_sched_mult_confirmation CONSTANT VARCHAR2(8) := 'SCH_T154';

    /* Problems label */
    g_sched_mult_problems CONSTANT VARCHAR2(8) := 'SCH_T155';

    /* Message to be shown when a schedule can be created (multi-search) */
    g_sched_mult_ok CONSTANT VARCHAR2(8) := 'SCH_M139';

    /* Title for reschedule confirmation */
    g_resched_confirm CONSTANT VARCHAR2(8) := 'SCH_T092';

    /* Message to be shown when a schedule is rescheduled as "unplanned" */
    g_resched_unplanned CONSTANT VARCHAR2(8) := 'SCH_M126';

    /* Valid reschedules */
    g_resched_valid_ones CONSTANT VARCHAR2(8) := 'SCH_M131';

    /* Invalid reschedules */
    g_resched_invalid_ones CONSTANT VARCHAR2(8) := 'SCH_M132';

    /* Confirm reschedules */
    g_resched_confirm_msg CONSTANT VARCHAR2(8) := 'SCH_M134';

    /* Confirm reschedules (some in the past) */
    g_resched_confirm_msg_past CONSTANT VARCHAR2(8) := 'SCH_M135';

    /* Additional message for departments */
    g_dep_additional_msg CONSTANT VARCHAR2(8) := 'SCH_T142';

    /* Message to be shown when an appointment is created outside the professional's contract duration */
    g_dt_not_in_contract CONSTANT VARCHAR2(8) := 'SCH_M142';

    /* Acknowledgement message */
    g_msg_ack CONSTANT VARCHAR2(8) := 'SCH_T146';

    /* Acknowledgment message title */
    g_sched_msg_ack_title CONSTANT VARCHAR2(8) := 'SCH_T147';

    /* Acknowledgment message title (multiple-search)*/
    g_sched_mult_msg_ack_title CONSTANT VARCHAR2(8) := 'SCH_T156';

    /* Error message if a schedule is not delivered in the external system */
    g_interface_sch_error_msg CONSTANT VARCHAR2(9) := 'SCH_T143';
    /* Error message if a schedule is not delivered in the external system */
    g_interface_cancel_error_msg CONSTANT VARCHAR2(9) := 'SCH_T144';

    /* Message shown when the professional has no read/write permissions whatsoever */
    g_missing_param_rw CONSTANT VARCHAR2(8) := 'SCH_M140';
    /* Message shown when the professional has no write permissions whatsoever */

    g_missing_param_w CONSTANT VARCHAR2(8) := 'SCH_M141';

    g_warning_title CONSTANT sys_message.code_message%TYPE := 'SCH_T044';

    /* Additional message for departments with nursering */
    g_dep_additional_msg_nurse CONSTANT VARCHAR2(8) := 'SCH_T257';

    /* Yes message */
    g_common_yes CONSTANT VARCHAR2(12) := 'COMMON_M022';
    /* No message */
    g_common_no CONSTANT VARCHAR2(12) := 'COMMON_M023';

    /* Schedule warning (overlap found) title */
    g_sched_msg_overlapfound CONSTANT VARCHAR2(8) := 'SCH_T258';

    /* Schedule warning (overlap found) go back button */
    g_sched_msg_goback CONSTANT VARCHAR2(8) := 'SCH_T259';

    /* Schedule warning (overlap found) overlap button */
    g_sched_msg_dooverlap CONSTANT VARCHAR2(8) := 'SCH_T260';

    /* Schedule warning  unexpected vacancy found  title*/
    g_sched_msg_unexvacfound CONSTANT VARCHAR2(8) := 'SCH_T261';

    /* Schedule warning (schedule without vacancy) button */
    g_sched_msg_schedwithvac CONSTANT VARCHAR2(8) := 'SCH_T262';

    /* Schedule warning (schedule without vacancy) button */
    g_sched_msg_schedwithoutvac CONSTANT VARCHAR2(8) := 'SCH_T263';

    /* Update schedule cancel notes */
    g_msg_update_schedule CONSTANT VARCHAR2(8) := 'SCH_T264';

    /* 'Warning' title for message dialogs*/
    g_msg_warning CONSTANT VARCHAR2(8) := 'SCH_T265';

    /* no permission to schedule */
    g_sched_msg_no_permission CONSTANT VARCHAR2(8) := 'SCH_T276';

    /*Schedule warning - vacancy needed */
    g_sched_msg_vacancyneeded CONSTANT VARCHAR2(8) := 'SCH_T302';

    /*status search field - livre */
    g_sched_msg_freevacs CONSTANT VARCHAR2(8) := 'SCH_T332';

    /*status search field - ocupado */
    g_sched_msg_allvacs CONSTANT VARCHAR2(8) := 'SCH_T333';

    /*single visit detail line reschedule attempt*/
    g_sched_msg_sv_resched CONSTANT VARCHAR2(8) := 'SCH_T719';

    /* Schedule warning  no vacancy usage config*/
    g_sched_msg_no_vac_usage CONSTANT VARCHAR2(8) := 'SCH_T747';

    /* Episode type configuration */
    g_sched_epis_type_config CONSTANT VARCHAR2(9) := 'EPIS_TYPE';

    /* OK button on flash */
    g_ok_button_code CONSTANT VARCHAR2(7) := 'C829664';

    /* Cancel button on flash */
    g_cancel_button_code CONSTANT VARCHAR2(7) := 'NC86464';

    /* OK button on flash */
    g_r_button_code CONSTANT VARCHAR2(7) := 'R829664';

    /* List of all the days of the week. (each day's message is g_msg_month_prefix + element of g_msg_week_days. */
    g_msg_week_days CONSTANT table_varchar := table_varchar('DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB');

    /* Complaint sample text type */
    g_complaint_sample_text_type CONSTANT VARCHAR2(6) := 'QUEIXA';

    /* Schedule status: pending */
    g_status_pending CONSTANT VARCHAR2(1) := 'P';
    /* Schedule status: requested */
    g_status_requested CONSTANT VARCHAR2(1) := 'R';
    /* Schedule status: scheduled */
    g_status_scheduled CONSTANT VARCHAR2(1) := 'A';
    /* Schedule status: with schedule (domain value) */
    g_status_with_schedule CONSTANT VARCHAR2(2) := 'A';
    /* Schedule status: with schedule image exams (domain value) */
    g_status_with_schedule_ie CONSTANT VARCHAR2(2) := 'AE';
    /* Schedule status: with schedule analysis (domain value) */
    g_status_with_schedule_a CONSTANT VARCHAR2(2) := 'AA';
    /* Schedule status: with schedule other exams (domain value) */
    g_status_with_schedule_oe CONSTANT VARCHAR2(2) := 'AO';
    /* Schedule status: without schedule (domain value) */
    g_status_without_schedule CONSTANT VARCHAR2(2) := 'SA';
    /* Status: Active */
    g_status_active CONSTANT VARCHAR2(1) := 'A';
    /*Pending schedule for iteration with Scheduler 2.0*/
    g_sched_status_cache CONSTANT VARCHAR2(1 CHAR) := 'V';
    /* Selected status for FLG_STATUS on PROF_DEP_CLIN_SERV */
    g_status_pdcs_selected CONSTANT VARCHAR2(1) := 'S';

    /* Schedule permission: Schedule */
    g_permission_schedule CONSTANT VARCHAR2(1) := 'S';
    /* Schedule permission: Read */
    g_permission_read CONSTANT VARCHAR2(1) := 'R';
    /* Schedule permission: No access (only for internal use) */
    g_permission_none CONSTANT VARCHAR2(1) := 'N';

    /* Unknown ID for WHERE clauses */
    g_unknown_id CONSTANT VARCHAR(5) := '-9999';

    /* Message code for when no data is found. */
    g_msg_no_data_found CONSTANT VARCHAR2(13) := 'NO_DATA_FOUND';
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    /* Log message for missing translations. */
    g_missing_translation CONSTANT VARCHAR2(25) := 'Missing translation for: ';
    /* Log message for missing messages. */
    g_missing_message CONSTANT VARCHAR2(21) := 'Missing message for: ';
    /* Log message for missing domain values. */
    g_missing_domain CONSTANT VARCHAR2(30) := 'Missing sys_domain value for: ';
    /* Log message for missing config values. */
    g_missing_config CONSTANT VARCHAR2(30) := 'Missing sys_config value for: ';
    /* Log message for missing color */
    g_missing_color CONSTANT VARCHAR2(29) := 'Missing sch_color color for: ';
    /* Log messages for invalid record key */
    g_invalid_record_key CONSTANT VARCHAR2(30) := 'Invalid record key';

    /* Flag type for image exams */
    g_exam_image_flg_type CONSTANT VARCHAR2(1) := 'I';

    /* Administrative category type flag */
    g_administrative_cat CONSTANT VARCHAR2(1) := 'A';

    /* Search patient by document. */
    g_search_pat_by_document CONSTANT VARCHAR2(1) := 'D';
    /* Search patient by plan. */
    g_search_pat_by_plan CONSTANT VARCHAR2(1) := 'P';
    /* "Search patient by" parameter. */
    g_search_pat_by_parameter CONSTANT VARCHAR2(21) := 'SCH_SEARCH_PATIENT_BY';

    /* Parameter that defines the maximum number of results on searches */
    g_num_record_search_parameter CONSTANT VARCHAR2(17) := 'NUM_RECORD_SEARCH';

    /* All identifier */
    g_all CONSTANT NUMBER(2) := -10;
    /* None identifier */
    g_none CONSTANT NUMBER(2) := -20;

    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    /* Gender: undefined */
    g_gender_undefined CONSTANT VARCHAR2(1) := 'I';

    /* More than one card */
    g_more_than_one_card CONSTANT VARCHAR2(19) := 'SCH_MaisQueUmCartao';
    /* SNS Health plan type */
    g_health_plan_type_sns CONSTANT VARCHAR2(1) := 'S';
    /* ADSE Health plan type */
    g_health_plan_type_adse CONSTANT VARCHAR2(1) := 'A';
    /* SAMS Health plan type */
    g_health_plan_type_sams CONSTANT VARCHAR2(1) := 'M';
    /* Health insurance health plan type */
    g_health_plan_type_insurance CONSTANT VARCHAR2(1) := 'G';

    /* Color prefix */
    g_color_prefix CONSTANT VARCHAR2(2) := '0x';

    /* Flag day status: empty */
    g_day_status_empty CONSTANT VARCHAR2(1) := 'E';
    /* Flag day status: half-empty (or half-full :) )*/
    g_day_status_half CONSTANT VARCHAR2(1) := 'H';
    /* Flag day status: full */
    g_day_status_full CONSTANT VARCHAR2(1) := 'F';
    /* Flag day status: void (no vacancies or schedules) */
    g_day_status_void CONSTANT VARCHAR2(1) := 'N';
    /* Flag day status: unavailable */
    g_day_status_unavailable CONSTANT VARCHAR2(1) := 'U';

    /* Schedule status: scheduled */
    g_sched_status_scheduled CONSTANT VARCHAR2(1) := 'A';
    /* Schedule status: requested */
    g_sched_status_requested CONSTANT VARCHAR2(1) := 'R';
    /* Schedule status: pending */
    g_sched_status_pending CONSTANT VARCHAR2(1) := 'P';
    /* Schedule status: cancelled */
    g_sched_status_cancelled CONSTANT VARCHAR2(1) := 'C';
    /* Schedule status: temporary. Only for MFR scheduler*/
    g_sched_status_temporary CONSTANT VARCHAR2(1) := 'T';
    -- pending approval
    g_sched_status_pend_approval CONSTANT VARCHAR2(1) := 'V';

    /* Schedule flag vacancy domain */
    g_schedule_flg_vacancy_domain CONSTANT VARCHAR2(20) := 'SCHEDULE.FLG_VACANCY';
    /* Event flag image domain */
    g_sch_event_flg_img_domain CONSTANT VARCHAR2(17) := 'SCH_EVENT.FLG_IMG';
    /* Schedule status flag domain */
    g_sched_flg_sch_status_domain CONSTANT VARCHAR2(23) := 'SCHEDULE.FLG_SCH_STATUS';
    /* Schedule flag status domain */
    g_schedule_flg_status_domain CONSTANT VARCHAR2(19) := 'SCHEDULE.FLG_STATUS';
    /* Schedule flag notification status domain */
    g_sched_flg_notif_status CONSTANT VARCHAR2(32) := 'SCHEDULE.FLG_NOTIFICATION';
    /* Status for professional vacants domain */
    g_schedule_status_prof_vac CONSTANT VARCHAR2(28) := 'SCHEDULE.STATUS_PROF_VACANTS';
    /* Status for patient schedules domain */
    g_schedule_status_pat_sch CONSTANT VARCHAR2(29) := 'SCHEDULE.STATUS_PAT_SCHEDULES';
    /* Schedule via*/
    g_sched_flg_sch_via CONSTANT VARCHAR2(32) := 'SCHEDULE.FLG_SCHEDULE_VIA';
    /* Schedule request type (este campo esta na schedule_outp*/
    g_sched_flg_req_type CONSTANT VARCHAR2(36) := 'SCHEDULE.FLG_REQUEST_TYPE';

    /* Language domain */
    g_sched_language_domain CONSTANT VARCHAR2(8) := 'LANGUAGE';

    /* Yes or no domain code */
    g_yes_no_domain CONSTANT VARCHAR2(6) := 'YES_NO';

    /* 'Yes' value used on the EXAM table's flags. */
    g_yes_pt CONSTANT VARCHAR2(1) := 'S';

    /* Status for professional vacants domain value: Without vacant */
    g_without_vacant CONSTANT VARCHAR2(2) := 'NV';
    /* Status for professional vacants (consult) domain value: With vacant */
    g_with_vacant CONSTANT VARCHAR2(2) := 'V';
    /* Status for professional vacants (exams) domain value: With vacant */
    g_with_vacant_exam CONSTANT VARCHAR2(2) := 'VE';
    /* Status for professional vacants (analysies) domain value: With vacant */
    g_with_vacant_analysis CONSTANT VARCHAR2(2) := 'VA';
    /* Status for professional vacants (other exams) domain value: With vacant */
    g_with_vacant_other_exams CONSTANT VARCHAR2(2) := 'VO';
    /* Status for professional vacants (nurse) domain value: With vacant */
    g_with_vacant_nurse CONSTANT VARCHAR2(2) := 'VN';
    /* Status for professional vacants (PMR) domain value: With vacant */
    g_with_vacant_pmr CONSTANT VARCHAR2(2) := 'VM';
    /* Status for professional vacants (PMR) domain value: With vacant */
    g_with_vacant_nutrition CONSTANT VARCHAR2(2) := 'VU';

    /* Flag for image exams */
    g_image_exam_flg CONSTANT VARCHAR2(1) := 'I';

    /* Consult icon */
    g_consult_icon sys_message.img_name%TYPE := 'ScheduleConsult32Icon';
    /* Exam icon */
    g_exam_icon sys_message.img_name%TYPE := 'ScheduleExam32Icon';
    /* MFR icon */
    g_mfr_icon sys_message.img_name%TYPE := 'ScheduleMfr32Icon';
    /* MFR icon for temporary schedule without overlapping*/
    g_mfr_icon_no_conflict sys_message.img_name%TYPE := 'SCH_WaitingNotConflictIcon';
    /* MFR icon for temporary schedule with overlapping*/
    g_mfr_icon_conflict sys_message.img_name%TYPE := 'SCH_WaitingConflictIcon';

    /* Proximity events' range configuration */
    g_range_proximity_events CONSTANT VARCHAR2(26) := 'SCH_RANGE_PROXIMITY_EVENTS';
    /* Proximity schedules' range configuration */
    g_range_proximity_sch CONSTANT VARCHAR2(23) := 'SCH_RANGE_PROXIMITY_SCH';

    /*codes for the icon images*/
    g_sched_icon_temp_conflict CONSTANT VARCHAR2(50) := 'SCH_SchedulingConflictTemporaryIcon';
    g_sched_icon_temp          CONSTANT VARCHAR2(50) := 'SCH_SchedulingTemporaryIcon';
    g_sched_icon_perm_conflict CONSTANT VARCHAR2(50) := 'SCH_SchedulingConflictFinalIcon';
    --    g_sched_icon_perm              CONSTANT VARCHAR2(2) := 'A';

    /* True */
    g_msg_true CONSTANT VARCHAR2(4) := 'TRUE';
    /* False */
    g_msg_false CONSTANT VARCHAR2(5) := 'FALSE';

    /* Check button */
    g_check_button CONSTANT VARCHAR2(1) := 'R';

    /* Episode type configuration */
    g_config_epis_type CONSTANT VARCHAR2(9) := 'EPIS_TYPE';

    /* Maximum decimal precision for advanced search */
    g_max_decimal_prec CONSTANT NUMBER := 9;

    g_sch_max_rec_events    CONSTANT VARCHAR2(18) := 'SCH_MAX_REC_EVENTS';
    g_sch_max_rec_vacants   CONSTANT VARCHAR2(19) := 'SCH_MAX_REC_VACANTS';
    g_sch_max_rec_schedules CONSTANT VARCHAR2(21) := 'SCH_MAX_REC_SCHEDULES';

    /* Notified */
    g_sched_flg_notif_pending CONSTANT VARCHAR2(1) := 'P';
    /* Pending notification */
    g_sched_flg_notif_notified CONSTANT VARCHAR2(1) := 'N';
    /* confirmed by patient */
    g_sched_flg_notif_confirmed CONSTANT VARCHAR2(1) := 'C';
    /*default scheduling via*/
    g_default_flg_sch_via CONSTANT VARCHAR2(1) := 'T';
    /*default request types*/
    g_default_sched_flg_req_type CONSTANT VARCHAR2(1) := 'M';

    /*default request types nurse*/
    g_def_sched_flg_req_type_nurse CONSTANT VARCHAR2(1) := 'E';

    /*default request types nurse*/
    g_prof_cat_nurse CONSTANT VARCHAR2(1) := 'N';

    /*default duration */
    g_default_duration CONSTANT VARCHAR2(20) := 'SCH_DEFAULT_DURATION';

    g_sysdate TIMESTAMP WITH TIME ZONE;
    /* DEFAULT EPISODE */
    g_instit_cs CONSTANT institution.flg_type%TYPE := 'C'; -- Private Care
    g_instit_hs CONSTANT institution.flg_type%TYPE := 'H'; -- Hospital
    g_instit_pp CONSTANT institution.flg_type%TYPE := 'P'; -- Private Practice
    g_consult VARCHAR(1);
    /* FLG_SCHED VALES */
    g_1med CONSTANT schedule_outp.flg_sched%TYPE := 'D';
    g_2med CONSTANT schedule_outp.flg_sched%TYPE := 'M';
    g_1esp CONSTANT schedule_outp.flg_sched%TYPE := 'P';
    g_2esp CONSTANT schedule_outp.flg_sched%TYPE := 'Q';

    g_selected CONSTANT VARCHAR2(1) := 'S';

    g_sch_scheduled  CONSTANT VARCHAR2(1) := g_sched_status_scheduled;
    g_sch_canceled   CONSTANT VARCHAR2(1) := g_sched_status_cancelled;
    g_status_deleted CONSTANT VARCHAR2(1) := 'D';
    g_status_unknown CONSTANT VARCHAR2(1) := 'B';

    /* Named colors */
    g_color_type_named CONSTANT VARCHAR2(1) := 'N';
    /* Specialty colors */
    g_color_type_specialty CONSTANT VARCHAR2(1) := 'D';

    /* DCS Colors config */
    g_config_use_dcs_colors CONSTANT VARCHAR2(18) := 'SCH_USE_DCS_COLORS';

    /* DCS Max Colors config */
    g_config_max_dcs_colors CONSTANT VARCHAR2(18) := 'SCH_MAX_DCS_COLORS';

    /* Group consult */
    g_group_consult CONSTANT VARCHAR2(32) := 'GROUP_CONSULT';

    /*options for parameter i_sch_option in create_schedule */

    g_sch_option_invacancy CONSTANT VARCHAR2(1) := 'V';

    g_sch_option_unplanned CONSTANT VARCHAR2(1) := 'A';

    g_sch_option_novacancy CONSTANT VARCHAR2(1) := 'F';

    g_sch_option_update CONSTANT VARCHAR2(1) := 'U';

    g_sch_option_force_novacancy CONSTANT VARCHAR2(1) := 'X';

    /*estados para as slots mfr */
    g_slot_status_permanent CONSTANT VARCHAR2(1) := 'P';
    g_slot_status_temporary CONSTANT VARCHAR2(1) := 'T';

    /*validate_schedule function constants */
    g_begindatelower  CONSTANT NUMBER(3) := 200;
    g_contractdates   CONSTANT NUMBER(3) := 100;
    g_sameappointment CONSTANT NUMBER(3) := 300;

    /* Indexes for call arguments (i_args) */
    idx_dt_begin          CONSTANT NUMBER(2) := 1;
    idx_dt_end            CONSTANT NUMBER(2) := 2;
    idx_id_inst           CONSTANT NUMBER(2) := 3;
    idx_id_dep            CONSTANT NUMBER(2) := 4;
    idx_id_dep_clin_serv  CONSTANT NUMBER(2) := 5;
    idx_event             CONSTANT NUMBER(2) := 6;
    idx_id_prof           CONSTANT NUMBER(2) := 7;
    idx_id_reason         CONSTANT NUMBER(2) := 8;
    idx_id_room           CONSTANT NUMBER(2) := 9;
    idx_id_notes          CONSTANT NUMBER(2) := 10;
    idx_duration          CONSTANT NUMBER(2) := 11;
    idx_preferred_lang    CONSTANT NUMBER(2) := 12;
    idx_type              CONSTANT NUMBER(2) := 13;
    idx_status            CONSTANT NUMBER(2) := 14;
    idx_translation_needs CONSTANT NUMBER(2) := 15;
    idx_interval_begin    CONSTANT NUMBER(2) := 16;
    idx_interval_end      CONSTANT NUMBER(2) := 17;
    idx_id_origin         CONSTANT NUMBER(2) := 18;
    idx_time_begin        CONSTANT NUMBER(2) := 19;
    idx_time_end          CONSTANT NUMBER(2) := 20;
    idx_view              CONSTANT NUMBER(2) := 21;
    idx_reason_notes      CONSTANT NUMBER(2) := 22;
    idx_id_exam           CONSTANT NUMBER(2) := 23;
    idx_id_analysis       CONSTANT NUMBER(2) := idx_id_exam;
    idx_flg_prep          CONSTANT NUMBER(2) := 24;
    idx_id_phys_area      CONSTANT NUMBER(2) := 25; -- este so e' usado no pk_schedule_mfr

    idx_sch_args_dcs      CONSTANT NUMBER(2) := 1;
    idx_sch_args_event    CONSTANT NUMBER(2) := 2;
    idx_sch_args_prof     CONSTANT NUMBER(2) := 3;
    idx_sch_args_patient  CONSTANT NUMBER(2) := 4;
    idx_sch_args_exam     CONSTANT NUMBER(2) := 5;
    idx_sch_args_analysis CONSTANT NUMBER(2) := idx_sch_args_exam;

    g_found        BOOLEAN; -- tco 24/05/2008
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp; -- tco 24/05/2008
    g_episode_inactive CONSTANT VARCHAR2(1) := 'I'; -- tco 24/05/2008
    g_episode_active   CONSTANT VARCHAR2(1) := 'A'; -- tco 24/05/2008
    g_schedule_ehr     CONSTANT VARCHAR2(1) := 'S'; -- tco 24/05/2008

    g_status_mailed      CONSTANT VARCHAR2(1) := 'M';
    g_status_canceled    CONSTANT VARCHAR2(1) := 'C';
    g_status_failed      CONSTANT VARCHAR2(1) := 'F';
    g_status_sched       CONSTANT VARCHAR2(1) := 'S';
    g_notification_conf  CONSTANT VARCHAR2(1) := 'C';
    g_notification_notif CONSTANT VARCHAR2(1) := 'N';
    g_id_cancel_failed   CONSTANT NUMBER(2) := 10;

    g_event_first_med    CONSTANT NUMBER(1) := 1;
    g_event_subs_med     CONSTANT NUMBER(1) := 2;
    g_event_first_spec   CONSTANT NUMBER(1) := 3;
    g_event_subs_spec    CONSTANT NUMBER(1) := 4;
    g_event_exam         CONSTANT NUMBER(1) := 7;
    g_event_mfr          CONSTANT NUMBER(2) := 11;
    g_event_oexam        CONSTANT NUMBER(2) := 13;
    g_event_group        CONSTANT NUMBER(2) := 10;
    g_event_multidisc    CONSTANT NUMBER(2) := 20;
    g_event_single       CONSTANT NUMBER(2) := 21;
    g_event_first_nutri  CONSTANT NUMBER(2) := 15;
    g_event_first_social CONSTANT NUMBER(2) := 40;

    g_reason CONSTANT VARCHAR2(1) := 'R';
    g_exception EXCEPTION;

    g_msg_not_repeat  CONSTANT VARCHAR2(30) := 'SCH_T624';
    g_msg_daily       CONSTANT VARCHAR2(30) := 'SCH_T625';
    g_msg_weekly      CONSTANT VARCHAR2(30) := 'SCH_T626';
    g_msg_monthly     CONSTANT VARCHAR2(30) := 'SCH_T627';
    g_msg_yearly      CONSTANT VARCHAR2(30) := 'SCH_T628';
    g_msg_day_week    CONSTANT VARCHAR2(30) := 'SCH_T629';
    g_msg_day_month   CONSTANT VARCHAR2(30) := 'SCH_T630';
    g_msg_day_st_week CONSTANT VARCHAR2(30) := 'SCH_T632';
    g_msg_day_nd_week CONSTANT VARCHAR2(30) := 'SCH_T633';
    g_msg_day_tr_week CONSTANT VARCHAR2(30) := 'SCH_T634';
    g_msg_day_ft_week CONSTANT VARCHAR2(30) := 'SCH_T635';
    g_msg_ls_week     CONSTANT VARCHAR2(30) := 'SCH_T636';
    g_msg_date        CONSTANT VARCHAR2(30) := 'SCH_T637';
    g_msg_nr_events   CONSTANT VARCHAR2(30) := 'SCH_T638';
    g_msg_yes         CONSTANT VARCHAR2(30) := 'SCH_T647';
    g_msg_no          CONSTANT VARCHAR2(30) := 'SCH_T648';

    -- series of appointments
    g_weekdays         CONSTANT NUMBER := 7;
    g_day_timeunit     CONSTANT VARCHAR2(30) := 'D';
    g_week_timeunit    CONSTANT VARCHAR2(30) := 'W';
    g_year_timeunit    CONSTANT VARCHAR2(30) := 'Y';
    g_month_timeunit   CONSTANT VARCHAR2(30) := 'M';
    g_end_by_date      CONSTANT VARCHAR2(30) := 'D';
    g_end_by_nr_events CONSTANT VARCHAR2(30) := 'E';

    g_series_date_format CONSTANT VARCHAR2(30) := 'dd-mm-yyyy';
    g_msg_no_vacancy     CONSTANT VARCHAR2(30) := 'SCH_T717';
    g_msg_min            CONSTANT VARCHAR2(30) := 'SCH_T718';

    g_sch_recursion_series CONSTANT VARCHAR2(30) := 'S';
    g_sch_recursion_mfr    CONSTANT VARCHAR2(30) := 'P';
    g_notification_via     CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE.FLG_NOTIFICATION_VIA';

    --notifications 
    g_notif_mfr          CONSTANT VARCHAR2(30) := 'M';
    g_notif_series       CONSTANT VARCHAR2(30) := 'S';
    g_notif_others       CONSTANT VARCHAR2(30) := 'O';
    g_flg_status_sched_c CONSTANT schedule.flg_status%TYPE := 'C';
END pk_schedule;
/
