/*-- Last Change Revision: $Rev: 2051006 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-24 15:52:26 +0000 (qui, 24 nov 2022) $*/
CREATE OR REPLACE PACKAGE pk_alerts IS

    /**######################################################
      GLOBAIS
    ######################################################**/
    --g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_retval       BOOLEAN;

    g_yes      CONSTANT VARCHAR2(1) := 'Y';
    g_no       CONSTANT VARCHAR2(1) := 'N';
    g_selected CONSTANT VARCHAR2(1) := 'S';

    g_alert_read   CONSTANT VARCHAR2(1) := 'L';
    g_flg_read_y   CONSTANT VARCHAR2(1) := 'Y';
    g_flg_read_n   CONSTANT VARCHAR2(1) := 'N';
    g_flg_delete_y CONSTANT VARCHAR2(1) := 'Y';
    g_flg_delete_n CONSTANT VARCHAR2(1) := 'N';

    g_flg_status_r CONSTANT VARCHAR2(1) := 'R';
    g_flg_status_d CONSTANT VARCHAR2(1) := 'D';
    g_flg_status_l CONSTANT VARCHAR2(1) := 'L';
    g_flg_status_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_status_f CONSTANT VARCHAR2(1) := 'F';

    flg_time_harvest_e   CONSTANT VARCHAR2(1) := 'E';
    flg_status_harvest_h CONSTANT VARCHAR2(1) := 'H';

    g_transf_resp_i CONSTANT epis_prof_resp.flg_transf_type%TYPE := 'I';
    g_new_fluids    CONSTANT drug.flg_type%TYPE := 'N';

    g_cat_doctor CONSTANT category.flg_type%TYPE := 'D';

    g_epis_type   CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_active CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inact  CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_canc   CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_pend   CONSTANT episode.flg_status%TYPE := 'P';

    g_fluids CONSTANT VARCHAR2(20) := 'F';
    g_drug   CONSTANT VARCHAR2(1) := 'M';

    g_intervention   CONSTANT VARCHAR2(2) := 'I';
    g_exam           CONSTANT VARCHAR2(2) := 'E';
    g_analysis       CONSTANT VARCHAR2(2) := 'A';
    g_drug_presc     CONSTANT VARCHAR2(2) := 'D';
    g_monitorization CONSTANT VARCHAR2(2) := 'M';
    default_language CONSTANT language.id_language%TYPE := 2;
    g_owner   VARCHAR2(100);
    g_package VARCHAR2(100);
    g_field_available CONSTANT VARCHAR2(0010 CHAR) := g_yes;

    g_alert_user_blocked sys_alert.id_sys_alert%TYPE := 51;

    k_version CONSTANT VARCHAR2(1 CHAR) := 'E';

    /********************************************************************************************
    * Inserts on record into the event table.
    * In this case the visit id and the patient id are obtained from the episode.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_sys_alert           Record to insert
    * @param i_id_episode          Episode ID
    * @param i_id_record           Detail ID (eg. id_analysis_req_det for harvest alerts)
    * @param i_dt_record           Record date (eg. analysis_req_det.dt_begin for harvest alerts)
    * @param i_id_professional     Professional ID (if the alert has a well defined target, null otherwise)
    * @param i_id_room             Room ID (id the alert is to be shown to every professional of a room, null otherwise)
    * @param i_id_clinical_service Clinical Service ID (id the alert is to be shown to every professional of a clinical service, null otherwise)
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
    *                               C- Clinical Service, R- room
    * @param i_replace1            Replace value for alert message
    * @param i_replace2            Replace value for alert message
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Carlos Vieira
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_sys_alert           IN sys_alert.id_sys_alert%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_record           IN sys_alert_event.id_record%TYPE,
        i_dt_record           IN sys_alert_event.dt_record%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_room             IN room.id_room%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_type_dest       IN VARCHAR2,
        i_replace1            IN VARCHAR2,
        i_replace2            IN VARCHAR2,
        i_prof_order          IN NUMBER DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    PROCEDURE purge_all_alerts;
    /********************************************************************************************
    * Deletes records from the event table .
    *
    * @param i_lang                Language Id
    * @param i_episode             Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION purge_daily
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional DEFAULT profissional(0, 0, 0),
        i_purge_day IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Deletes records from the event table .
    *
    * @param i_lang                Language Id
    * @param i_episode             Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event_episode
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_delete  IN VARCHAR2 DEFAULT 'N',
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Esta função calcula as margem de tempo para o alerta expirar
    *
    * @param i_lang        Id do idioma
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE if sucess, FALSE otherwise
    *
    * @author                Carlos Vieira
    * @version               1.0
    * @since                 2009/04/10
    ********************************************************************************************/
    FUNCTION get_expire_nurse_act_exec
    (
        i_lang        IN NUMBER,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_time_lable  IN VARCHAR2
    ) RETURN NUMBER;

    /**
    * Gets value for flg_read in doc_config
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_id_sys_alert alert type id
    * @param   i_profile_template profile id
    *
    * @RETURN
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_config_flg_read
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Inserts on record into the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
    *                               C- Clinical Service, R- room
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        i_flg_type_dest   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Esta função marca os alertas como lidos para um determinado profissional.
    *
    * @param i_lang           Id do idioma
    * @param i_prof           Id do profissional
    * @param i_sys_alert_det  ID do alerta lido
    * @param i_sys_alert      ID do tipo de alerta
    * @param i_test           Indica se deve ser mostrada a mensagem de confirmação
    * @param o_flg_show       Indica se deve ser mostrada a mensagem de confirmação
    * @param o_msg_title      Título da mensagem de confirmação
    * @param o_msg_text       Descrição da mensagem de confirmação
    * @param o_button         Botões a mostrar. N - NÃO, R - LIDO, C - CONFIRMADO ou combinações destes
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author                 Rui Batista
    * @version                1.0
    * @since                  2007/07/11
    ********************************************************************************************/
    FUNCTION set_alert_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_sys_alert_det IN sys_alert_det.id_sys_alert_det%TYPE,
        i_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta função gera alertas de diagnósticos de enfermagem - CIPE.
    *
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/20
    ********************************************************************************************/
    FUNCTION alert_icnp_diag
    (
        i_lang  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta função gera alertas de episódios temporários de Inpatient.
    *
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/24
    ********************************************************************************************/
    FUNCTION alert_inp_temp_episodes
    (
        i_lang  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta função obtém os alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_alert         Array com todos os alertas disponíveis para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/12
    ********************************************************************************************/
    FUNCTION get_prof_alerts
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_alert OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Esta função determina o ID do shortcut para um alerta.
    *
    * @param i_prof          ID do profissional, instituição e software
    * @param i_sys_alert     ID do tipo de alerta
    * @param o_num_alerts    Número de alertas disponível para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/25
    ********************************************************************************************/
    FUNCTION get_alerts_shortcut
    (
        i_prof      IN profissional,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Esta função determina o número de alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_num_alerts    Número de alertas disponível para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/25
    ********************************************************************************************/
    FUNCTION get_prof_alerts_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_num_alerts OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Inserts on record into the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_sys_alert_event    IN sys_alert_event%ROWTYPE,
        o_id_sys_alert_event OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_sys_alert_event    IN sys_alert_event%ROWTYPE,
        i_flg_type_dest      IN VARCHAR2,
        o_id_sys_alert_event OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Inserts on record into the event table.
    * In this case the visit id and the patient id are obtained from the episode.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_sys_alert           Record to insert
    * @param i_id_episode          Episode ID
    * @param i_id_record           Detail ID (eg. id_analysis_req_det for harvest alerts)
    * @param i_dt_record           Record date (eg. analysis_req_det.dt_begin for harvest alerts)
    * @param i_id_professional     Professional ID (if the alert has a well defined target, null otherwise)
    * @param i_id_room             Room ID (id the alert is to be shown to every professional of a room, null otherwise)
    * @param i_id_clinical_service Clinical Service ID (id the alert is to be shown to every professional of a clinical service, null otherwise)
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
                                   C- Clinical Service, R- room
    * @param i_replace1            Replace value for alert message
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_sys_alert           IN sys_alert.id_sys_alert%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_record           IN sys_alert_event.id_record%TYPE,
        i_dt_record           IN sys_alert_event.dt_record%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_room             IN room.id_room%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_type_dest       IN VARCHAR2,
        i_replace1            IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Gets alert message to display
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional, institution and software ids
    * @param i_id_sys_alert    Alert ID
    * @param i_replace1        Replace field #1
    * @param i_replace2        Replace field #2
    * @param i_translate       Translate i_replace1 Y/N
    *
    * @RETURN
    * @author  Rui Batista
    * @version 1.0
    * @since   18-03-2008
    * @changed 2.4.4 Rui Spratley
    */
    FUNCTION get_alert_message
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_replace1     IN VARCHAR2,
        i_replace2     IN VARCHAR2,
        i_translate    IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Deletes records from the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Deletes records from the event table.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution and software ids
    * @param i_id_sys_alert        Sys_alert_event id
    * @param i_id_record           Record id
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Paulo Fonseca
    * @version                     2.5.0.2
    * @since                       2009/04/20
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert_event.id_sys_alert%TYPE,
        i_id_record    IN sys_alert_event.id_record%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns the list of event details for a given alert event
    *
    * @param   i_lang                     language
    * @param   i_prof                     id_do profissional, instituição e software
    * @param   i_id_sys_alert_event       ID do evento
    * @param   o_sys_alert_event_details  List of collected specimens
    * @param   o_error                    error message
    *
    *
    * @author  Paulo Almeida
    * @since   2008/08/08
    **************************************************************************/
    FUNCTION get_sys_alert_event_details
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_sys_alert_event      IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        o_sys_alert_event_details OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Sets the correct professional for a determine alert
    *
    * @param   i_lang                     language
    * @param   i_prof                     id_do profissional, instituição e software
    * @param   i_id_sys_alert             ID do alert
    * @param   i_episode                  Id of episode
    * @param   i_professional             id of professional
    * @param   o_error                    error message
    *
    *
    * @author  Elisabete Bugalho
    * @since   16-04-2010
    **************************************************************************/
    FUNCTION set_alert_professional
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_professional IN professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets alert configuration as type (t_tbl_alert_config) 
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_id_sys_alert alert type id
    * @param   i_profile_template profile id
    *
    * @RETURN  t_tbl_alert_config
    * @author  João Sá
    * @version 1.0
    * @since   02-10-2013
    */
    FUNCTION get_config_as_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN t_tbl_alert_config;

    /*
    * Function used by the idp to create an user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id    
    * @param o_error              Error message    
    * @return                     true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013-10-29
    */
    FUNCTION insert_evt_user_blocked
    (
        i_lang            IN NUMBER,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Function to delete user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id    
    * @param o_error              Error message    
    * @return                     true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013-10-29
    */
    FUNCTION delete_evt_user_blocked
    (
        i_lang            IN NUMBER,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /* set Generated Report alert */
    FUNCTION insert_evt_gen_report
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Function to delete user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id    
    * @param o_error              Error message    
    * @return                     true or false on success or error
    *
    * @author    Rui Gomes
    * @version   2.6.34.0
    * @since     2014-05-08
    */
    FUNCTION delete_evt_gen_report
    (
        i_lang           IN NUMBER,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**/

    FUNCTION is_event_version(i_id_sys_alert IN sys_alert.id_sys_alert%TYPE) RETURN BOOLEAN;

    /*
    * Match sys_alert_events 
    *
    * @param i_lang               Language id
    * @param i_prof               Professional   
    * @param i_id_episode         Old episode identifier 
    * @param i_id_episode_new     New episode identifier 
    * @param i_id_sys_alert       Sys_alert identifier   
    * @param o_error              Error message    
    * @return                     true or false on success or error
    *
    * @author    Gisela Couto
    * @version   2.6.4
    * @since     2015-01-14
    */
    FUNCTION match_sys_alert_event
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_episode     IN sys_alert_event.id_episode%TYPE,
        i_id_episode_new IN sys_alert_event.id_episode%TYPE,
        i_id_sys_alert   IN sys_alert.id_sys_alert%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_sys_alert
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE
    ) RETURN table_number;

    /**
    *  Set user alerts
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION set_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN department.id_department%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    -- private
    PROCEDURE del_sys_alert_prof
    (
        i_prof_id     IN NUMBER,
        i_institution IN NUMBER,
        i_software    IN NUMBER
    );

    /**
    *  Delete alerts from user accordingly to the profiles, software and institution been removed beeing removed.
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION del_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Changes alerts from user accordingly to the profiles, software and institution.
    *
    * @param i_lang                    Language
    * @param i_id_prof                 Professional, institution, software ids.
    * @param i_id_profile_template_old Old Profile id for this user
    * @param i_id_profile_template_new New Profile id for this user
    * @param o_error                   Error message
    *
    * @return     boolean
    * @author     Paulo Teixeira
    * @version    0.1
    * @since      2010-08-17
    */
    FUNCTION change_prof_alerts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_prof                 IN profissional,
        i_id_profile_template_old IN profile_template.id_profile_template%TYPE,
        i_id_profile_template_new IN profile_template.id_profile_template%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all alert id by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_serv_sys_alert
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Get all No alerts configuration flg by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    * @param i_service                Service ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_no_alert_validation
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_patient_alerts_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_id_patient   IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    FUNCTION check_if_alert_expired
    (
        i_prof         IN profissional,
        i_dt_creation  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_sys_alert IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE init_params_list
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION transform
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar        
    ) RETURN VARCHAR2;

    --*****************************************************
    FUNCTION get_flg_ok_enabled
    (
        i_prof               IN profissional,
        i_id_episode         IN NUMBER,
        i_sys_alert          IN NUMBER,
        i_id_software_origin IN NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE init_par_alerts
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    --*******************
    FUNCTION tf_get_prof_alerts
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
        --o_alert OUT pk_types.cursor_type,
    ) RETURN t_tbl_alert;

    FUNCTION set_all_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_selected_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN table_number,
        i_sys_alert     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_anamnesis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_text    IN VARCHAR2
    ) RETURN VARCHAR2;

    -- **********************************************
    FUNCTION set_alert_read_x_days
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_alert_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_alert   IN NUMBER,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION do_alert_message
    (
        i_lang          IN NUMBER,
        i_flg_duplicate IN VARCHAR2,
        i_msg_dup_no    IN VARCHAR2,
        i_msg_dup_yes   IN VARCHAR2,
        i_translate     IN VARCHAR2,
        i_replace1      IN VARCHAR2,
        i_replace2      IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_config_flg_delete
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2;

END pk_alerts;
/
