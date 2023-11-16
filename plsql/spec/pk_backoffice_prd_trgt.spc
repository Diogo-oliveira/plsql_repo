/*-- Last Change Revision: $Rev: 2028523 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_prd_trgt IS

    -- Author  : SUSANA.SILVA
    -- Created : 18-05-2009 17:50:23
    -- Purpose : Production Target functionality

    /** @headcom
    * Public Function. Get Production target information
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param       o_production_target         Production target cursor
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_production_target
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        o_production_target OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Create/Edit Production target
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_production_target        Production Target identification
    * @param      i_subject                  Subject identification
    * @param      i_flag_subject             Flag Subject: D-Professional, S-Speciality
    * @param      i_type_schedule            Schedule Type identification
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      i_type_event               Event Type identification
    * @param      i_start_date               Target start date
    * @param      i_end_date                 Target end date
    * @param      i_target                   Target value
    * @param      i_notes                    Notes
    * @param      o_id_production_target     Production target record id
    * @param      o_id_production_target_hist     Production target history record id
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION set_production_target
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_production_target         IN production_target.id_production_target%TYPE,
        i_subject                   IN NUMBER,
        i_flag_subject              IN VARCHAR2,
        i_type_schedule             IN NUMBER,
        i_dep_clin_serv             IN NUMBER,
        i_type_event                IN NUMBER,
        i_start_date                IN VARCHAR2,
        i_end_date                  IN VARCHAR2,
        i_target                    IN NUMBER,
        i_notes                     IN VARCHAR2,
        o_id_production_target      OUT NUMBER,
        o_id_production_target_hist OUT NUMBER,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get subject search
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_search_subject           Subject search
    * @param      o_subject                  Cursor - subject
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_subject_search
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_search_subject IN VARCHAR2,
        o_subject        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get subject search
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_flag_category            Flag Subject search
    * @param      o_subject                  Cursor - subject
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_subject
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_flag_category IN VARCHAR2,
        o_subject       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Cancel production target
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_production_target      Production target identification
    * @param      o_id_production_target_hist   Production target history record identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION set_cancel_production_target
    (
        i_lang                      IN LANGUAGE.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_production_target      IN production_target.id_production_target%TYPE,
        o_id_production_target_hist OUT production_target_hist.id_production_target_hist%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get schedule type
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_dcs_subject               Service/speciality identification
    * @param      o_schedule_type             Cursor schedule type
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_schedule_type
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_dcs_subject   IN production_target.id_dcs_subject%TYPE,
        o_schedule_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get production target data
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_prod_target            Production target identification
    * @param      o_prod_target_data          Cursor with data about production target
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_production_target_data
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prod_target   IN production_target.id_production_target%TYPE,
        o_prod_target_data OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get appointment type
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      i_flag_sch_type            Flag scheduling type
    * @param      o_appointment_type          Cursor with data about appointment type
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_appointment_type
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flag_sch_type    IN sch_dep_type.dep_type%TYPE,
        o_appointment_type OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get event
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_flag                      Flag scheduling type
    * @param      i_dep_clin_serv            Service/speciality identification
    * @param      o_event                    Cursor with data about event type
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_event
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_flag          IN sch_dep_type.dep_type%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_event         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get detail
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    * @param      i_id_production_target      Production target identification
    * @param      o_detail                    Cursor with data about the target
    * @param      o_detail_hist               Cursor with data about the target  history
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_detail
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_production_target IN production_target.id_production_target%TYPE,
        o_detail               OUT pk_types.cursor_type,
        o_detail_hist          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get subject appointment
    *
    * @param      I_LANG                      Language identification
    * @param      i_flag_subject              Professional identification
    * @param      id_subject                  Subject identification
    * @param      id_dcs                      Service/speciality identification
    * @param      o_flag                      Output Cursor
    * @param      o_error                     Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_subject_appointment
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_flag_subject IN VARCHAR2,
        id_subject     IN NUMBER,
        id_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flag         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Calculate the possible values:  Number of vacancy available for target
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_possible
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER;

    /** @headcom
    * Public Function. Calculate the probable values:  Number of scheduler apointments
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_probable
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER;

    /** @headcom
    * Public Function. Calculate the real values:  Number of  apointments
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_real
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_dt_start                IN production_target.dt_start%TYPE,
        i_dt_end                  IN production_target.dt_end%TYPE,
        i_id_institution          IN production_target.id_institution%TYPE
    ) RETURN NUMBER;

    /** @headcom
    * Public Function. Calculate the possible, probable, real, probability possible, probability real, probability real values
    *
    * @param      I_LANG                      Language identification
    * @param      i_id_professional_subject   Professional - subject identification
    * @param      i_id_dcs_subject            Service/speciality - subject identification
    * @param      i_id_dcs_type_slot          Service/speciality - Type of event identification
    * @param      i_id_sch_event              Event types
    * @param      i_id_sch_dep_type           Scheduling types
    * @param      i_dt_start                  Start date
    * @param      i_dt_end                    End date
    * @param      i_id_institution            Institution identification
    * @param      i_target_value              Target values
    * @param      o_statistical_information   Cursor with statistical information
    * @param      o_error            Institution identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/06/16
    */

    FUNCTION get_statistical_information
    
    (
        i_lang                    IN LANGUAGE.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_professional_subject IN production_target.id_professional_subject%TYPE,
        i_id_dcs_subject          IN production_target.id_dcs_subject%TYPE,
        i_id_dcs_type_slot        IN production_target.id_dcs_type_slot%TYPE,
        i_id_sch_event            IN production_target.id_sch_event%TYPE,
        i_id_sch_dep_type         IN production_target.id_sch_dep_type%TYPE,
        i_start_date              IN VARCHAR2,
        i_end_date                IN VARCHAR2,
        i_id_institution          IN production_target.id_institution%TYPE,
        i_target_value            IN production_target.target%TYPE,
        o_statistical_information OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get dep_clin_Serv identification
    *
    * @param      I_LANG                      Language identification
    * @param      i_prof                      Professional identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/28
    */

    FUNCTION get_dep_clin_serv
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number;

    /** @headcom
    * Public Function. Get schedule type identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_sch_dep_type
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN sch_dep_type.id_sch_dep_type%TYPE
    ) RETURN VARCHAR2;

    /** @headcom
    * Public Function. Get clinical service identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_clinical_service
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    /** @headcom
    * Public Function. Get event identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_sch_event
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN sch_event.id_sch_event%TYPE
    ) RETURN VARCHAR2;

    /** @headcom
    * Public Function. Get department identification
    *
    * @param      I_LANG                     Language identification
    * @param      i_id                       Schedule type identification
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2009/08/31
    */

    FUNCTION get_department
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_id   IN department.id_department%TYPE
    ) RETURN VARCHAR2;

    g_error VARCHAR2(4000);
    my_exception EXCEPTION;
    g_professional CONSTANT VARCHAR2(1) := 'P';
    g_speciality   CONSTANT VARCHAR2(1) := 'S';
    g_doctor       CONSTANT VARCHAR2(1) := 'D';
    g_physician_category      category.id_category%TYPE := 1;
    g_administrative_category category.id_category%TYPE := 4;

END pk_backoffice_prd_trgt;
/
