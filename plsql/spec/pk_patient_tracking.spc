/*-- Last Change Revision: $Rev: 2028854 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_tracking IS

    -- Author  : FABIO.OLIVEIRA
    -- Created : 25-02-2009 14:25:35
    -- Purpose : Package used for patient tracking purposes

    -- Public function and procedure declarations
    /********************************************************************************************
    * Retrieves the list of statuses and it's availability
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_data          Cursor holding the list of statuses to show
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION get_profile_care_stages
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_flg_clear OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the patient's current care status
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_flg_stage     Status to set
    * @param i_flg_ins_type  Type of record creation
    * @param i_flg_active    Is active care state?
    * @param o_date          Current date
    * @param o_error         Error ocurred
    *
    * @values i_flg_ins_type  A - Automatically
    *                         M - Manually
    *                         I - Interface
    *
    * @values i_flg_active    Y - Yes
    *                         N - No
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION set_care_stage_no_commit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_stage    IN care_stage.flg_stage%TYPE,
        i_flg_ins_type IN care_stage.flg_ins_type%TYPE DEFAULT 'A',
        i_flg_active   IN care_stage.flg_active%TYPE DEFAULT 'Y',
        o_date         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the patient's current care status. Does commit
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_flg_stage     Status to set
    * @param o_stage         Status string to display
    * @param o_destination   Episode destination (conultation requests or discharge department)
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION set_care_stage
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_flg_stage   IN care_stage.flg_stage%TYPE,
        o_stage       OUT VARCHAR2,
        o_destination OUT VARCHAR2,
        o_rank        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /* FUNCTIONS FOR EHR VIEWER */
    /********************************************************************************************
    * Returns a list of different patient care stages and the number of patients in each stage
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param o_data          Cursor with the returning data
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION get_statuses_summary_all
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list of different patient care stages and the number of registered patients in 
    * each stage
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param o_data          Cursor with the returning data
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION get_statuses_summary_reg
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a list of different patient care stages and the number of temporary patients in 
    * each stage
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param o_data          Cursor with the returning data
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/02/26
    ********************************************************************************************/
    FUNCTION get_statuses_summary_nrg
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that retrieves the current status string for display
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_date          Current date in flash format
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/03/05
    ********************************************************************************************/
    FUNCTION get_care_stage_grid_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get current state rank
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional
    * @param i_episode           Definitive episode ID
    *
    * @return                The current state rank
    *
    * @author                Sérgio Santos
    * @version               2.6.1
    * @since                 2012/03/22
    ********************************************************************************************/
    FUNCTION get_current_state_rank
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN sys_domain.rank%TYPE;

    /********************************************************************************************
    * Function that restores the care status for 'Waiting for Disposition' when a disposition is cancelled
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/03/05
    ********************************************************************************************/
    FUNCTION restore_care_stage_disposition
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that sets an episode as 'Discharged'
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/03/05
    ********************************************************************************************/
    FUNCTION set_care_stage_disposition
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that chooses the correct care status flow when matching two episodes
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Fábio Oliveira
    * @version               2.5
    * @since                 2009/03/05
    ********************************************************************************************/
    FUNCTION match_care_stage
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set automatic patient tracking status, after pending medical discharge, according to the
    * status configured in DISCH_REAS_DEST.
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional
    * @param i_episode             Definitive episode ID
    * @param i_id_disch_reas_dest  Discharge reason / Discharge destination ID
    * @param o_error               Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                José Brito
    * @version               2.5
    * @since                 2009/07/30
    ********************************************************************************************/
    FUNCTION set_auto_disposition_status
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set automatic patient tracking status, after a consult is made.
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional
    * @param i_episode             episode ID
    * @param o_error               Error ocurred
    *
    * @return                      False if an error ocurred and True if not
    *
    * @author                      Alexandre Santos
    * @version                     2.5.0.7.8
    * @since                       2010/09/06
    ********************************************************************************************/
    FUNCTION set_auto_opinion_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set patient tracking status, after the consult reply is made.
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional
    * @param i_episode             episode ID
    * @param i_flg_status          opinion status
    * @param o_error               Error ocurred
    *
    * @return                      False if an error ocurred and True if not
    *
    * @author                      Alexandre Santos
    * @version                     2.5.0.7.8
    * @since                       2010/09/06
    ********************************************************************************************/
    FUNCTION set_after_opinion_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_status IN opinion.flg_state%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the patient death status if the patient died during the episode
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional
    * @param i_episode             episode ID
    * @param i_dt_deceased         decease date
    * @param o_error               Error ocurred
    *
    * @return                      False if an error ocurred and True if not
    *
    * @author                      José Silva
    * @version                     2.6.1
    * @since                       2011/03/11
    ********************************************************************************************/
    FUNCTION set_patient_death_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that sets an episode as 'Waiting for payment' (Only in Chile market) 
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6.2
    * @since                 2011/10/24
    ********************************************************************************************/
    FUNCTION set_care_stage_triage
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that adds the 'payment made' care stage to the episode
    * This function is used by Interfaces Team and is called by a external system 
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6.2
    * @since                 2011/10/24
    ********************************************************************************************/
    FUNCTION set_cs_payment_made
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that adds the 'Wainting for payment' care stage to the episode
    * This function is used by Interfaces Team and is called by a external system 
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Gisela Couto
    * @version               2.6.4
    * @since                 2014/08/25
    ********************************************************************************************/
    FUNCTION set_cs_wait_fr_payment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that adds the 'In Treatment' care stage to the episode
    * This function is called by PK_VISIT.SET_FIRST_OBS and by PK_EPIS_ER_LAW_CORE.SET_EPIS_ER_LAW when activating ER law
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_episode         Definitive episode ID
    * @param i_flg_triage_call The origin of this function call was triage?
    * @param i_flg_er_law      Activation of ER law?
    * @param o_error           Error ocurred
    *
    * @values i_flg_triage_call  Y - Yes
    *                            N - No
    *
    * @values i_flg_er_law       Y - Yes
    *                            N - No
    *
    * @return                  False if an error ocurred and True if not
    *
    * @author                  Alexandre Santos
    * @version                 2.6.2
    * @since                   2011/10/24
    ********************************************************************************************/
    FUNCTION set_care_stage_in_treat
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_triage_call IN VARCHAR2,
        i_flg_er_law      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that resets the care stage when ER law is cancelled
    * This function is called by PK_EPIS_ER_LAW_CORE.CANCEL_EPIS_ER_LAW when cancelling ER law
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_episode         Definitive episode ID
    * @param o_error           Error ocurred
    *
    * @return                  False if an error ocurred and True if not
    *
    * @author                  Alexandre Santos
    * @version                 2.6.2
    * @since                   2011/10/24
    ********************************************************************************************/
    FUNCTION reset_care_stage_er_law
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that resets the care stage when disposition is cancelled
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_episode         episode ID
    * @param o_error           Error ocurred
    *
    * @return                  False if an error ocurred and True if not
    *
    * @author                  Elisabete Bugalho
    * @version                 2.6.1
    * @since                   2013/01/03
    ********************************************************************************************/

    FUNCTION reset_care_stage_disposition
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set automatic patient tracking status, after reopening episode
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional
    * @param i_episode             episode ID
    * @param o_error               Error ocurred
    *
    * @return                      False if an error ocurred and True if not
    *
    * @author                      Elisabete Bugalho 
    * @version                     2.6.1
    * @since                       2013/01/04
    ********************************************************************************************/
    FUNCTION set_auto_reopen_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that resets the care stage when death registration is cancelled
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_episode         episode ID
    * @param o_error           Error ocurred
    *
    * @return                  False if an error ocurred and True if not
    *
    * @author                  Elisabete Bugalho
    * @version                 2.6.1
    * @since                   2013/01/04
    ********************************************************************************************/

    FUNCTION reset_care_stage_death
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- Defines waiting status type in the patient tracking. WPA - Waiting for administrative process completion; WPY - Wainting for payment.
    g_config_wait_compl_stat_type CONSTANT sys_config.id_sys_config%TYPE := 'WAITING_COMPLETION_STATUS_TYPE';

    -- Defines process completion status type in the patient tracking. APD - Administrative process done; PMY - Payment made.
    g_config_compl_done_stat_type CONSTANT sys_config.id_sys_config%TYPE := 'COMPLETION_DONE_STATUS_TYPE';

END pk_patient_tracking;
/
