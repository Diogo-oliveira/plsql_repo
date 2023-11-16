/*-- Last Change Revision: $Rev: 2028672 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ehr_access AS
    /**
    * check if an episode is cancelled
    *
    * @param i_lang        language preference
    * @param i_prof        professional identification
    * @param i_episode     episode identification
    * @param o_return      Y/N
    * @param o_error        error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-09-30
    * @version v2.6.0.3.3
    * @author paulo teixeira
    */
    FUNCTION check_episode_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_return  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * This package is responsible for checking access to a patient EHR. Its main entry point
    * is through the function check_ehr_access() which returns the access type.
    *
    * @since 2008-05-08
    * @author rui.baeta
    */

    TYPE access_rule_type IS RECORD(
        id_ehr_access_rule ehr_access_rule.id_ehr_access_rule%TYPE,
        id_rule_succeed    ehr_access_rule.id_rule_succeed%TYPE,
        id_rule_fail       ehr_access_rule.id_rule_fail%TYPE,
        flg_type           ehr_access_rule.flg_type%TYPE,
        profile_function   ehr_access_function.function%TYPE,
        prof_function      ehr_access_function.function%TYPE);

    TYPE access_rule_table IS TABLE OF access_rule_type;
    TYPE access_rule_map IS TABLE OF access_rule_type INDEX BY BINARY_INTEGER;

    /**
    * Checks weather this professional has access to this patient EHR.
    *
    * @param i_lang        language preference
    * @param i_prof        professional identification
    * @param i_id_patient  patient id that this professional wants to access to.
    *
    * @param o_access_type access type to this patient EHR (B - Break the Glass
    *                                                       F - Free Access
    *                                                       N - Not allowed)
    * @param o_error       error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-08
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION check_ehr_access
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_access_type OUT NOCOPY VARCHAR2,
        o_error       OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Checks weather this professional has access to this patient EHR.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    *
    * @param o_access_type access type to this patient EHR (B - Break the Glass
    *                                                       F - Free Access
    *                                                       N - Not allowed)
    * @param o_error       error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-08
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION check_ehr_access
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        o_access_type        OUT NOCOPY VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if this professional has to justify an EHR Access.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient identifier
    * @param i_id_episode          episode id that this professional wants to access to.
    * @param i_id_schedule         schedule id that this professional wants to access to.
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-22
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION check_log_need
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_log_need    OUT NOCOPY VARCHAR2,
        o_area        OUT NOCOPY ehr_access_context.id_ehr_access_context%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets access reasons for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_access_area      area context for the reasons
    * @param i_id_episode          episode identifier
    * @param i_id_schedule         schedule identifier
    * @param i_id_dep_clin_serv    dep_clin_serv identifier
    *
    * @param o_access_reasons      cursor containing access reasons for this professional
    * @param o_access_context      cursor containing the labels in order to give a context to the access reasons screen
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_access_reasons
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_access_area   IN ehr_access_reason.id_ehr_access_context%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_access_reasons   OUT pk_types.cursor_type,
        o_access_context   OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets clinical services for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_clin_services       cursor containing clinical services for this professional
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION get_clinical_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_context   IN ehr_access_context.flg_context%TYPE,
        o_clin_services OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the id professional to show in the Professional field
    *
    * @param id_schedule_outp        
    * @param i_episode            
    *
    * @return             id_professional
    *
    * @since 2010-FEB-10
    * @version v2.5
    * @author Sérgio Santos
    */
    FUNCTION get_epis_sch_prof
    (
        i_id_schedule_outp IN schedule_outp.id_schedule_outp%TYPE,
        i_id_episode       IN episode.id_episode%TYPE
    ) RETURN professional.id_professional%TYPE;

    /**
    * Gets current episodes for a patient
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_current_with_me     cursor containing current episodes for this patient with the professional
    * @param o_current_all         cursor containing all the current episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_current_episodes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_current_with_me OUT pk_types.cursor_type,
        o_current_all     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets previous episodes for a patient
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_prev_with_me        cursor containing previous episodes for this patient with the professional
    * @param o_prev_last10         cursor containing the last 10 previous episodes for this patient
    * @param o_prev_all            cursor containing previous episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_previous_episodes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_prev_with_me OUT pk_types.cursor_type,
        o_prev_last10  OUT pk_types.cursor_type,
        o_prev_all     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets scheduled episodes for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_sched_with_me      cursor containing scheduled episodes for this professional
    * @param o_sched_all          cursor containing scheduled episodes for this patient
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_scheduled_episodes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_sched_with_me OUT pk_types.cursor_type,
        o_sched_all     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets EHR events for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_ehr_with_me         cursor containing EHR events for this professional
    * @param o_ehr_all             cursor containing EHR events for this patient
    * @param o_ehr_new             cursor indicating if we can create ehr events
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-19
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION get_ehr_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_ehr_with_me OUT pk_types.cursor_type,
        o_ehr_all     OUT pk_types.cursor_type,
        o_ehr_new     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Records the access to a patient EHR, by a professional.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_schedule         scheduled id
    * @param i_access_type         granted access type (B - Break the Glass
    *                                                   F - Free Access
    *                                                   N - Not allowed)
    * @param i_id_access_reason    list of access reasons used by this professional.
    * @param i_id_dep_clin_serv    selected dep_clin_serv
    * @param i_access_text         access reason free text
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-21
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_ehr_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Records the access to a patient EHR, by a professional. Used inside pk_schedule_api_downstream.create_schedule
    * or any other function that needs to call create_ehr_access. 
    * The original create_ehr_access is invoked by the flash code
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_schedule         scheduled id
    * @param i_access_type         granted access type (B - Break the Glass
    *                                                   F - Free Access
    *                                                   N - Not allowed)
    * @param i_id_access_reason    list of access reasons used by this professional.
    * @param i_id_dep_clin_serv    selected dep_clin_serv
    * @param i_access_text         access reason free text
    * @param i_transaction_id      remote scheduler transaction id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @date     24-05-2011
    * @version  2.6.1.1
    * @author  Telmo 
    */
    FUNCTION create_ehr_access_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_access_area      IN ehr_access_context.id_ehr_access_context%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        i_new_ehr_event    IN VARCHAR2,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Prepares and creates the EHR access
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-05-28
    * @author Pedro Teixeira
    ********************************************************************************************/
    FUNCTION create_ehr_access_new_contact
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_access_flg_type  IN ehr_access_context.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_ehr_access_new_contact
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_access_flg_type  IN ehr_access_context.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_dep_clin_serv    department clinical service id
    * @param i_dt_begin            begin date
    *
    * @param o_id_scheduled        scheduled id - output value
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-11-10
    * @author Pedro Teixeira
    ********************************************************************************************/
    FUNCTION create_ehr_access_new_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_prof_category    IN category.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_ehr_access_new_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_prof_category    IN category.flg_type%TYPE,
        i_flg_context      IN ehr_access_context.flg_context%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        o_id_schedule      OUT schedule.id_schedule%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg              OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates an order set type episode
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_id_episode          episode id
    * @param i_id_scheduled        scheduled id
    *
    * @param o_error               error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-05-27
    * @version v2.6.0.3
    * @author Sérgio Santos
    */
    FUNCTION create_order_set_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_transaction_id   IN VARCHAR2,
        o_episode          OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets access areas for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_areas               cursor containing EHR events for this professional
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-16
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION get_access_areas
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_areas      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns a String with all the access reasons for an ehr access
    *
    * @param i_lang         Language identifier.
    * @param i_patient      Patient id
    * @param i_episode      The title of the visit type.
    * @param i_sep          String separator
    *
    * @return  the string containing all the access reasons
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/05/20
    */
    FUNCTION get_access_reason_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_sep     IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Logs an ehr access to a previous episode
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_patient      Patient id
    * @param i_episode      The title of the visit type.
    * @param i_sep          String separator
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/05/21
    */
    FUNCTION log_access
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_access_type      IN VARCHAR2,
        i_id_access_reason IN table_number,
        i_access_text      IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_access_rules
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN access_rule_table;

    /**
    * Checks if a professional has access to the EHR ACCESS MANAGER
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param o_val          return 'Y' if the professional has access to the EHR ACCESS MANAGER, 'N' otherwise
    
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/08/04
    */
    FUNCTION has_ehr_manager
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_val   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if must show other popups (Visit init, patient responsability)
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_schedule     Schedule id (if available)
    * @param i_episode      Episode id (if available)
    * @param o_val          return 'Y' case must show other popups, 'N' otherwise
    * @param o_error        Error message
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2008/08/04
    */
    FUNCTION show_other_popups
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_val      OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if a certain Alert funcionality can create records in EHR and inactive episodes.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_episode      Episode id
    * @param o_val          return 'Y' has permission to create records, 'N' otherwise
    * @param o_error        Error object
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.4.3
    * @since    2009/03/20
    */
    FUNCTION check_area_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN VARCHAR2,
        o_val     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_area_create_permission
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_area         IN VARCHAR2
    ) RETURN VARCHAR2 result_cache;

    /**
    * Checks if a certain Alert functionality (area) can create records in schedule, EHR or inactive episodes.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         Professional identification
    * @param i_episode      Episode id
    * @param o_val          return 'Y' has permission to create records, 'N' otherwise
    * @param o_error        Error object
    *
    * @return   true if sucess, false otherwise
    *
    * @author   Sérgio Santos
    * @version  2.6.1.1
    * @since    2011/06/05
    */
    FUNCTION check_area_create_perm_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN table_varchar,
        o_area    OUT table_varchar,
        o_val     OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get episode encounters.
    *
    * @param i_lang                language identifier
    * @param i_prof                logged professional structure
    * @param i_id_episode          episode identifier
    * @param i_id_patient          patient identifier
    * @param o_past_enc            past encounters
    * @param o_cur_enc             ongoing encounters
    * @param o_new_enc             new encounter
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009/10/23
    * @version 2.5.0.7
    * @author Pedro Carneiro
    */
    FUNCTION get_encounters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_past_enc   OUT pk_types.cursor_type,
        o_cur_enc    OUT pk_types.cursor_type,
        o_new_enc    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets new contact options
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_options             cursor containing available options when a contact is created
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2008-05-16
    * @version v2.5.0.7.5
    * @author Pedro Teixeira
    */
    FUNCTION get_new_contact_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets administrator new contact options
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_options             cursor containing available options when a contact is created
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2009-01-14
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_adm_contact_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if professional has permission to create scheduled contacts
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION has_sched_permission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN ehr_access_context.flg_context%TYPE
    ) RETURN BOOLEAN;

    /**
    * Checks if professional has permission to create EHR event
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    *
    * @return              true if has permission, false otherwise
    *
    * @since 09-01-2010
    * @version V2.6.0.1
    * @author Pedro Teixeira
    */
    FUNCTION has_ehr_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN;

    /**
    * Get the sch_event associated with the professional a context
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_flg_context         context
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_sched_event
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN ehr_access_context.flg_context%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the sch_event associated with the professional a context
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_flg_context         context
    *
    * @return              true if has permission, false otherwise
    *
    * @since 2010-01-12
    * @version v2.5.0.7.6
    * @author Pedro Teixeira
    */
    FUNCTION get_sched_without_vac
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /**
    * Gets access areas for a professional
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * 
    * @param  o_flg_show           flag show / not show
    * @param o_precaution_list     string containing patient problems precautions
    * @param o_precaution_number     number patient problems precautions
    * @param o_problem_list        string containing patient problems with precautios
    * @param o_problem_number        number patient problems with precautios
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-02-25
    * @version v2.6.0
    * @author Paulo Teixeira
    
    */
    FUNCTION get_precaution_warning
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_precaution_list   OUT VARCHAR2,
        o_precaution_number OUT NUMBER,
        o_problem_list      OUT VARCHAR2,
        o_problem_number    OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_flg_show     Y - if on trial N - Not on trial
    * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
    * @param o_shortcut     id shortcut to trials
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/25
    **********************************************************************************************/
    FUNCTION get_trials_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_trial       OUT pk_types.cursor_type,
        o_responsible OUT pk_types.cursor_type,
        o_shortcut    OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * check if a exception shortcut for patient area is parameterized
    *
    * @param i_lang              language preference
    * @param i_prof              professional identification
    * @param i_shortcut          default shortcut
    * @param o_shortcut_return   shortcut 
    * @param o_error             error message
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2011-08-23
    * @version v2.5
    * @author rita lopes
    */
    FUNCTION check_shortcut_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_shortcut        IN sys_shortcut.id_sys_shortcut%TYPE,
        o_shortcut_return OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Check if a patient is on patient Alerts 
    * 
    * @param i_lang         language identifier 
    * @param i_prof         logged professional structure 
    * @param i_id_patient   PATIENT ID 
    * @param o_flg_show     Y - if on patient alerts N - Not on  patient alerts 
    * @param o_title        modalWindows title 
    * @param o_warning      alerts cursor 
    * @param o_shortcut     id shortcut to  patient alerts 
    * @param o_error        error 
    * 
    * @return               false if errors occur, true otherwise 
    * 
    * @author              Jorge Silva 
    * @version              2.6.1 
    * @since                2012/07/23 
    **********************************************************************************************/
    FUNCTION get_active_patient_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_shortcut   OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_dep_clin_servs_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_dep_clin_servs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_dep         IN VARCHAR2,
        i_id_event       IN VARCHAR2,
        i_id_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        o_dep_clin_servs OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_dep        IN VARCHAR2,
        i_id_clin_serv  IN VARCHAR2,
        i_id_event      IN VARCHAR2,
        i_flg_schedule  IN VARCHAR2,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets the list of departments that a professional has access to.
    *
    * @param i_lang                Language identifier.
    * @param i_prof                Professional.
    * @param i_flg_search          Whether or not should the 'All' option appear on the list.
    * @param i_flg_schedule        Whether or not should the departments be filtered considering the professional's permission to schedule
    * @param i_id_institution      Institution ID
    * @param o_departments         List of departments
    * @param o_perm_msg            Error message to be shown if the professional has no permissions
    * @param o_error               Error message (if an error occurred).
    * 
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_departments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_search     IN VARCHAR2,
        i_flg_schedule   IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        o_departments    OUT pk_types.cursor_type,
        o_perm_msg       OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author              Jorge Silva 
    * @version              2.6.3.9
    * @since                2012/12/04 
    */
    FUNCTION get_events_schedule
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_events      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_events
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_dep       IN VARCHAR2,
        i_flg_search   IN VARCHAR2,
        i_flg_schedule IN VARCHAR2,
        i_flg_dep_type IN VARCHAR2,
        o_events       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --------------------------------------------
    g_exception EXCEPTION;

    g_error        VARCHAR2(32767);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_found        BOOLEAN;
    g_package_name VARCHAR2(32);
    g_pk_owner CONSTANT VARCHAR2(6) := 'ALERT';

    g_sep_reason CONSTANT VARCHAR(10) := ' ';

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_epis_active    CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_cancelled CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_inactive  CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending   CONSTANT episode.flg_status%TYPE := 'P';

    g_epis_info_inactive CONSTANT epis_info.flg_status%TYPE := 'W';

    g_flg_ehr_normal    CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_n;
    g_flg_ehr_ehr       CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_e;
    g_flg_ehr_scheduled CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_s;
    g_flg_ehr_order_set CONSTANT VARCHAR2(1) := 'O';

    g_access_ongoing              CONSTANT ehr_access_context.flg_type%TYPE := 'C';
    g_access_previous             CONSTANT ehr_access_context.flg_type%TYPE := 'P';
    g_access_ehr                  CONSTANT ehr_access_context.flg_type%TYPE := 'E';
    g_access_scheduled            CONSTANT ehr_access_context.flg_type%TYPE := 'S';
    g_access_cancelled            CONSTANT ehr_access_context.flg_type%TYPE := 'I';
    g_access_new_indirect_contact CONSTANT ehr_access_context.flg_type%TYPE := 'N'; -- indirect contact
    g_access_create_contact       CONSTANT ehr_access_context.flg_type%TYPE := 'L';
    g_access_create_schedule      CONSTANT ehr_access_context.flg_type%TYPE := 'M';
    g_access_sign_off             CONSTANT ehr_access_context.flg_type%TYPE := 'O';
    g_access_do_nothing           CONSTANT ehr_access_context.flg_type%TYPE := 'T';
    g_access_goto_patient_area    CONSTANT ehr_access_context.flg_type%TYPE := 'D';
    g_access_previous_at          CONSTANT ehr_access_context.flg_type%TYPE := 'A';

    -----------------------
    g_appointment_type_indirect CONSTANT episode.flg_appointment_type%TYPE := 'S';
    g_appointment_type_direct   CONSTANT episode.flg_appointment_type%TYPE := 'N';
    -----------------------
    g_doctor_category        CONSTANT category.flg_type%TYPE := 'D';
    g_nurse_category         CONSTANT category.flg_type%TYPE := 'N';
    g_nutre_category         CONSTANT category.flg_type%TYPE := 'U';
    g_social_category        CONSTANT category.flg_type%TYPE := 'S';
    g_admin_category         CONSTANT category.flg_type%TYPE := 'A';
    g_sch_care_event_nursing CONSTANT sch_event.id_sch_event%TYPE := 12;
    -----------------------
    g_software_care       CONSTANT software.id_software%TYPE := 3;
    g_software_outpatient CONSTANT software.id_software%TYPE := 1;
    g_software_pp         CONSTANT software.id_software%TYPE := 12;
    g_software_nutre      CONSTANT software.id_software%TYPE := 43;
    g_software_social     CONSTANT software.id_software%TYPE := 24;
  g_software_referral   CONSTANT software.id_software%TYPE := 4;
    -----------------------
    g_sc_nursing_clin_serv     CONSTANT sys_config.id_sys_config%TYPE := 'NEW_NURSING_CONTACT_CLINICAL_SERVICE';
    g_sc_nursing_sched_minutes CONSTANT sys_config.id_sys_config%TYPE := 'NEW_NURSING_SCHEDULE_DURATION_MINUTES';
    g_sc_flg_vacancy           CONSTANT sys_config.id_sys_config%TYPE := 'SCH_NEW_CONTACT_VACANCY_TYPE';
    g_sc_flg_appointment_type  CONSTANT sys_config.id_sys_config%TYPE := 'SCH_NEW_CONTACT_APPOINTMENT_TYPE';
    -----------------------
    g_rule_break_the_glass_access CONSTANT VARCHAR2(1) := 'B'; -- Break the Glass
    g_rule_free_access            CONSTANT VARCHAR2(1) := 'F'; -- Free Access
    g_rule_access_not_allowed     CONSTANT VARCHAR2(1) := 'N'; -- Access not allowed
    g_rule_access_sign_off        CONSTANT VARCHAR2(1) := 'S'; -- Episode Signed off access
    -----------------------
    g_access_failed_rule_error_id  CONSTANT PLS_INTEGER := -20000;
    g_access_failed_rule_error_msg CONSTANT VARCHAR2(200) := 'EHR access rule function returns false!';

    g_access_no_rules_error_id  CONSTANT PLS_INTEGER := -20001;
    g_access_no_rules_error_msg CONSTANT VARCHAR2(200) := 'No EHR access rules found for professional!';

    g_access_no_frule_error_id  CONSTANT PLS_INTEGER := -20002;
    g_access_no_frule_error_msg CONSTANT VARCHAR2(200) := 'Configuration of first rule to execute not found (ID_EHR_ACCESS_FIRST_RULE)!';
    --
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';
    g_flg_consult_sch_type CONSTANT sch_vacancy_usage.flg_sch_type%TYPE := 'C';
    --
    g_flg_context_access      CONSTANT ehr_access_context.flg_context%TYPE := 'A';
    g_flg_context_new_patient CONSTANT ehr_access_context.flg_context%TYPE := 'N';
    --
    g_flg_access_new_contact  CONSTANT ehr_access_context.flg_type%TYPE := 'A';
    g_flg_access_new_schedule CONSTANT ehr_access_context.flg_type%TYPE := 'B';
    g_flg_access_pat_episode  CONSTANT ehr_access_context.flg_type%TYPE := 'C';

    g_area_inp_episode  CONSTANT ehr_access_area_def.area%TYPE := 'INP_EPIS';
    g_area_oris_episode CONSTANT ehr_access_area_def.area%TYPE := 'ORIS_EPIS';

    FUNCTION has_patient_access
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_access     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * Check if a episode is ongoing Out on pass
    * 
    * @param i_lang         language identifier 
    * @param i_prof         logged professional structure 
    * @param i_id_episode   episode identifier
    * @param o_flg_show     Y - if on patient alerts N - Not on  patient alerts 
    * @param o_title        modalWindows title 
    * @param o_warning      alerts cursor 
    * @param o_error        error 
    * 
    * @return               false if errors occur, true otherwise 
    * 
    * @author               CRISTINA.OLIVEIRA
    * @since                2019/04/23 
    **********************************************************************************************/
    FUNCTION check_episode_out_on_pass
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_warning    OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    
    /********************************************************************************************
    * checks if the ok button [to access the patient ehr] is active when searching by cancelled episodes
    *
    * @param  I_LANG                       IN        NUMBER
    * @param  I_PROF                       IN        PROFISSIONAL
    * @param  o_ok_active                  OUT       Y-the ok button should be active. N-otherwise           
    *
    * @return  VARCHAR2
    *
    * @author      Sofia Mendes
    * @version     2.8.0.1
    * @since       06/12/2019
    ********************************************************************************************/
    FUNCTION check_cancel_search_ok_active
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_ok_active OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
END pk_ehr_access;
/
