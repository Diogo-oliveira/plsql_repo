/*-- Last Change Revision: $Rev: 2028948 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:55 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_api_ui IS

    -- Author  : TELMO.CASTRO
    -- Created : 11-03-2010
    -- Purpose : UI specific functions. Such function include PFH-scheduler data fetching 

    -- Public type declarations

    -- Public constant declarations
    g_sysdate_tstz CONSTANT TIMESTAMP WITH TIME ZONE := current_timestamp;

    -- Public variable declarations
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(30);
    g_error         VARCHAR2(4000);
    g_exception EXCEPTION;

    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    -- Public function and procedure declarations

    /* To be used by UI in patient clinical area -> discharge screen -> schedule subsequent appointment 
    * and similar places. This functions returns the appointment id content needed by the scheduler 3 screen.
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, etc.
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof           Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    * @param o_id_content        id_appointment as needed by scheduler 3. comes from appointment table. Previously this came from column id_content, now gone
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @date                       11-03-2010
    * 
    * UPDATE 19-10-2010: column appointment.id_content no longer exists, replaced by id_appointment. I opted to leave the function name unchanged
    * so as to not disturb UI layer
    */
    FUNCTION get_id_content
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dep_type    IN sch_event.dep_type%TYPE,
        i_flg_occurr  IN sch_event.flg_occurrence%TYPE,
        i_id_dcs      IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof    IN VARCHAR2,
        o_id_content  OUT appointment.id_appointment%TYPE,
        o_flg_proceed OUT VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* To be used by referral 
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, U=nutrition apps, AS=social worker app
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof          Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    *
    * @return                     appointment.id_appointment%TYPE (varchar)
    *
    * @author                     Telmo
    * @version                    2.6.0.4  ALERT-14479
    * @date                       22-10-2010
    */
    FUNCTION get_id_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dep_type   IN sch_event.dep_type%TYPE,
        i_flg_occurr IN sch_event.flg_occurrence%TYPE,
        i_id_dcs     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof   IN VARCHAR2
    ) RETURN appointment.id_appointment%TYPE;

    /* This function applies the id content provided by the function get_id_content or get_ids to several consult requisitions.
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_list          List of consult_req ids or exam ids
    * @param i_flg_type_list    List of id type (C - Consult, E - Exam)
    * @param o_id_content        list id content as needed by scheduler 3. comes from appointment table
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     SS
    * @version                    2.6.0.3
    * @date                       01-07-2010
    */
    FUNCTION get_cr_exam_id_content_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_list       IN table_number,
        i_flg_type_list IN table_varchar,
        o_id_content    OUT table_varchar,
        o_flg_proceed   OUT VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Fetch the screen information about procedures' schedule
    * Function used by Reports
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_id_schedule              External Schedule  identification
    * @param i_id_patient               PAtient identification
    * @param o_domain                   tipo de valores para as notificacoes
    * @param o_actual_event             Cursor with the actual event data   
    * @param o_to_notify                Cursor with the events to be notified  
    * @param o_notified                 Cursor with the notified events
    * @param o_error                    Error message
    *
    * @return                           TRUE if success, FALSE otherwise
    *                        
    * @author                           Carlos Nogueira
    * @version                          2.6.0.1
    * @since                            2010/03/24
    **********************************************************************************************/
    FUNCTION get_notifications
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_schedule_ext IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_id_patient      IN sch_group.id_patient%TYPE,
        o_domain          OUT pk_types.cursor_type,
        o_actual_event    OUT pk_types.cursor_type,
        o_to_notify       OUT pk_types.cursor_type,
        o_notified        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /* return exam id_content. UI needed this
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_exam            exam id on which to base the search
    * @param o_id_content         output
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      29-03-2010
    */
    FUNCTION get_id_content_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_exam    IN exam.id_exam%TYPE,
        o_id_content OUT exam.id_content%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /* return exams id_contents. UI needed this
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_exam          exam ids on which to base the search
    * @param o_ids_content       output list
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      29-03-2010
    */
    FUNCTION get_ids_content_exam
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ids_exam    IN table_number,
        o_ids_content OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Confirms a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION confirm_pending_sched
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Removes a pending schedule.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_transaction_id              Scheduler transaction identifier
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009      
    */
    FUNCTION remove_pending_sched
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the schedule's details.
    *
    * @param i_lang                         Language.
    * @param i_prof                         Professional.
    * @param i_id_schedule                  Schedule identifier.
    * @param o_schedule_details             Details.
    * @param o_patients                     Patient Details.
    * @param o_error                        Error message, if an error occurred.
    *
    * @return  True if successful, false otherwise. 
    * @author  Sérgio Santos
    * @version 1.0
    * @since   22-12-2009   
    *
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
    * notifies scheduler 3 about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 PFH schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.3.4
    * @date    29-10-2010
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets scheduler external schedule id
    *
    * @param i_lang               Language identifier
    * @param i_id_schedule        Schedule identifier
    * @param o_id_schedule        Schedule identifier in new Scheduler
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo Castro
    * @version 2.6.1.1
    * @since   13-05-2011
    */
    FUNCTION get_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_schedule_api_ui;
/
