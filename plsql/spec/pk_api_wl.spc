/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_wl IS

    /********************************************************************************************
    * This function receives the two mandatory arguments (ticket id and episode id) and based on that
    * settles itself for a course of action, that can go from following the regular workflow to simply
    * updating the ticket with the id of the episode.
    *
    * @param i_lang                  The language ID.
    * @param i_prof                  The ALERT professional.
    * @param i_epis                  The episode to associate.
    * @param i_id_prof_next          The ID of the next ALERT professional.
    * @param i_clin_serv             The ID of the clinical service the patient intends to visit.
    * @param dt_consult              Date of the consult.
    * @param i_id_mach               The ID of the machine of the ALERT professional that will receive the patient.
    * @param i_room                  The ID of the room where the consult will take place.
    * @param io_ticket               The ticket to associate. OUT: the ticket ID of the following line.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_id_prof_next IN professional.id_professional%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_dt_consult   IN wl_waiting_line.dt_consult_tstz%TYPE,
        i_id_mach      IN wl_machine.id_wl_machine%TYPE,
        i_room         IN room.id_room%TYPE,
        io_ticket      IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to allocate professionals to queues. If no queues are provided, the professional is assumed to be
    * an ancillary and is allocated to all non-medical queues.
    *
    * @param i_prof                  The ALERT professional.
    * @param i_machine               The machine the professional is logged on.
    * @param i_queues                The queues to allocate the professional to.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_prof_queues
    (
        i_prof    IN profissional,
        i_machine IN wl_machine.id_wl_machine%TYPE,
        i_queues  IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the available queues for a machine.
    *
    * @param i_machine               The machine.
    * @param o_queues                Array containing the IDs of the available queues.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_get_prof_queues
    (
        i_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues  OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return information related to the available queues for a machine.
    *
    * @param i_lang                  The ID of the language in which the queue information should be displayed
    * @param i_machine               The machine.
    * @param o_queues                Array containing the IDs of the available queues.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_get_prof_queues_info
    (
        i_lang    IN language.id_language%TYPE,
        i_machine IN wl_machine.id_wl_machine%TYPE,
        o_queues  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the ALERT ID of the provided machine name.
    *
    * @param i_machine_name               The name machine requiring identification.
    * @param o_machine                    The machine ID.
    * @param o_error                      Errors.
    ********************************************************************************************/
    FUNCTION intf_get_machine
    (
        i_machine_name IN wl_machine.machine_name%TYPE,
        o_machine_id   OUT wl_machine.id_wl_machine%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Executes the required steps to allow that an external system can trigger "call" commands in WL's screens.
    * The only mandatory argument is the id of the machine - should the ticket not be provided, the function searches for the next ticket to call.
    *
    * Notes:
    * - As of version 2.4.3, WL was not yet prepared to accept requests in a language other than Portuguese (from Portugal).
    * As a result every required language argument is hard-coded to value 1 (Portuguese). In 2.4.4 this function will be
    * adapted to allow the specification of a language.
    *
    *
    * @param i_lang                 The language ID.
    * @param i_prof                 The professional that called the function. If NULL, it defaults to (0,0,0)
    * @param i_machine              The machine that called the function.
    * @param i_flg_prioritary       Defines if the application should mind prioritary queues or not.
    * @param io_ticket              (OPTIONAL) Specifies the ticket to be called by WL, and returns the ticket called by WL.
    * @param o_error                Errors.
    ********************************************************************************************/
    FUNCTION intf_get_next_call
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_machine        IN wl_machine.id_wl_machine%TYPE,
        i_flg_prioritary IN NUMBER,
        io_ticket        IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function receives the two mandatory arguments (ticket id and episode id) and based on that
    * settles itself for a course of action, that can go from following the regular workflow to simply
    * updating the ticket with the id of the episode.
    * If you pass id_ticket NULL, this function will automatically create one ticket
    *
    * @param i_lang                  The language ID.
    * @param i_prof                  The ALERT professional.
    * @param i_epis                  The episode to associate.
    * @param i_id_prof_next          The ID of the next ALERT professional.
    * @param i_clin_serv             The ID of the clinical service the patient intends to visit.
    * @param dt_consult              Date of the consult.
    * @param i_id_mach               The ID of the machine of the ALERT professional that will receive the patient.
    * @param i_room                  The ID of the room where the consult will take place.
    * @param i_id_wl_queue           ID of the Queue that the ticket 
    * @param io_ticket               The ticket to associate. OUT: the ticket ID of the following line.
    * @param o_error                 Errors.
    ********************************************************************************************/
    FUNCTION intf_set_ticket_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_id_prof_next IN professional.id_professional%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_dt_consult   IN wl_waiting_line.dt_consult_tstz%TYPE,
        i_id_mach      IN wl_machine.id_wl_machine%TYPE,
        i_room         IN room.id_room%TYPE,
        i_id_wl_queue  IN wl_queue.id_wl_queue%TYPE,
        io_ticket      IN OUT wl_waiting_line.id_wl_waiting_line%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_ret   BOOLEAN;
    g_lang  language.id_language%TYPE;
    g_error VARCHAR2(4000);
    g_prof  profissional;

    g_flg_type_queue_doctor   VARCHAR2(1);
    g_flg_type_queue_nurse    VARCHAR2(1);
    g_flg_type_queue_registar VARCHAR2(1);
    g_flg_type_queue_nur_cons VARCHAR2(1);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_api_wl;
/
