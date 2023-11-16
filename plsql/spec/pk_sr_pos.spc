/*-- Last Change Revision: $Rev: 2028983 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_pos IS

    /**************************************************************************
    *                                                                         *
    *  Auxiliary function used on admission request creation and edition      *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   01-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN schedule_sr.id_waiting_list%TYPE,
        i_id_episode_sr       IN schedule_sr.id_episode%TYPE,
        i_id_sr_pos_status    IN sr_pos_schedule.id_sr_pos_status%TYPE DEFAULT NULL,
        i_dt_pos_suggested    IN VARCHAR2 DEFAULT NULL,
        i_req_notes           IN sr_pos_schedule.req_notes%TYPE DEFAULT NULL,
        io_id_sr_pos_schedule IN OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_decision_notes      IN sr_pos_schedule.decision_notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pos_req_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE
    ) RETURN t_tbl_pos_req_detail;

    FUNCTION get_pos_decision_ds
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_flg_return_opts    IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_pos_dt_sugg        OUT VARCHAR2,
        o_pos_dt_sugg_chr    OUT VARCHAR2,
        o_pos_notes          OUT VARCHAR2,
        o_pos_sr_stauts      OUT NUMBER,
        o_pos_desc_decision  OUT VARCHAR2,
        o_pos_valid_days     OUT NUMBER,
        o_pos_desc_notes     OUT VARCHAR2,
        o_pos_need_op        OUT VARCHAR2,
        o_pos_need_op_desc   OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pos_decision
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_flg_return_opts    IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_pos_validation     OUT pk_types.cursor_type,
        o_pos_decision       OUT pk_types.cursor_type,
        o_pos_validity       OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_POS_STATUS_ICONS            Returns all the icons that can appear in the POS status column of the admission/surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DATA                   Icons
    * @param O_ERROR                  
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         
    * @version                        2.6.0
    * @since                          2010/03/31
    *******************************************************************************************************************************************/
    FUNCTION get_pos_status_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * GET_SUMMARY_POS_DECISION                                                *
    *                                                                         *
    *                                                                         *
    * @param I_LANG                   Language ID for translations            *
    * @param I_PROF                   Professional ID, Institution ID,        *
    *                                 Software ID                             *
    * @param i_id_episode             episode id                              *
    *                                                                         *
    * @return                         Returns                                 *
    *                                                                         *
    *                                                                         *
    * @raises                         PL/SQL generic error "OTHERS" and       *
    *                                 "wtl_exception"                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/07                              *
    **************************************************************************/
    FUNCTION get_summary_pos_decision
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used on pos request validation                                 *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   02-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_validation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_status   IN sr_pos_schedule.id_sr_pos_status%TYPE,
        i_days_valid         IN sr_pos_schedule.valid_days%TYPE,
        i_dt_valid           IN VARCHAR2,
        i_decision_notes     IN sr_pos_schedule.decision_notes%TYPE,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used on pos request                                            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   08-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested   IN VARCHAR2,
        i_req_notes          IN sr_pos_schedule.req_notes%TYPE,
        o_id_sr_pos_schedule OUT sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used add tasks to action button                                *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   08-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        i_episode    IN episode.id_episode%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used to populate pharmaceutical's grid                         *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used to return information on pharmacyst evaluation            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_drug_presc     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used to save pharmacyst evaluation                             *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION set_pos_pharm
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_id_prescription     IN table_number,
        i_prescription_type   IN table_varchar,
        i_notes_assessment    IN table_varchar,
        i_notes_evaluation    IN sr_pos_pharm.notes_evaluation%TYPE,
        o_id_sr_pos_pharm     OUT sr_pos_pharm.id_sr_pos_pharm%TYPE,
        o_id_sr_pos_pharm_det OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used to cancel pharmacyst evaluation                           *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION cancel_pos_pharm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sr_pos_pharm  IN sr_pos_pharm.id_sr_pos_pharm%TYPE,
        i_id_cancel_reason IN sr_pos_pharm.id_cancel_reason%TYPE,
        i_notes_cancel     IN sr_pos_pharm.notes_cancel%TYPE,
        o_id_sr_pos_pharm  OUT sr_pos_pharm.id_sr_pos_pharm%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Sets or updates a POS appointment request                               *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_patient                    patient to set the request to       *
    * @param i_episode                    requested admission episode         *
    * @param i_flg_edit                   record type: A - add, R - remove,   *
    *                                     E - edit                            *
    * @param i_consult_req                consult_req ID                      *
    * @param i_dep_clin_serv              appointment type                    *
    * @param i_dt_scheduled_str           appointment date                    *
    * @param io_consult_req               new consult_req ID                  *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                             true or false on success or error   *
    *                                                                         *
    * @author                             José Silva                          *
    * @version                            1.0                                 *
    * @since                              25-04-2009                          *
    **************************************************************************/
    FUNCTION set_pos_appointment_req
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_flg_edit         IN VARCHAR2,
        i_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_notes_req        IN consult_req.notes%TYPE,
        io_consult_req     IN OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns information to put in the POS Detail screen                     *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_approval_type              aproval type                        *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_approval_resume            Cursor with process resume info     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/02                              *
    **************************************************************************/
    FUNCTION get_pos_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_pos_schedule IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        o_pos_detail         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    *                                                                         *
    * function used to return information on pharmacyst evaluation            *
    *                                                                         *
    * @RETURN  TRUE or FALSE                                                  *
    * @author                                                                 *
    * @version 1.0                                                            *
    * @since   13-04-2010                                                     *
    *                                                                         *
    **************************************************************************/
    FUNCTION get_pos_pharm_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN schedule_sr.id_episode%TYPE,
        o_pos_validation OUT pk_types.cursor_type,
        o_drug_presc     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Check to POS status to know if is necessary to show the warning message
    *
    * @param i_lang           Id language
    * @param i_prof           Id professional, institution and software
    * @param i_episode        ID episode
    *
    * @return                 Yes or no
    * 
    * @author                 Filipe Silva
    * @version                2.6.0.1
    * @since                  2010/04/15
       **********************************************************************/
    FUNCTION check_pos_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Returns POS request permission for the professional                     *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_create_permission          Flag with info about create POS     *
    *                                     permission for the professional     *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/04/02                              *
    **************************************************************************/
    FUNCTION check_pos_request_permission
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_create_permission OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_pos_is_expired
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_date       IN sr_pos_schedule.dt_valid%TYPE,
        i_flg_status IN sr_pos_status.flg_status%TYPE
    ) RETURN VARCHAR2;

    -- GLOBAL VARS
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_SR_POS';

    -- Logic vars   
    g_pos_pharm_inactive CONSTANT VARCHAR2(1) := 'I';
    g_pos_pharm_active   CONSTANT VARCHAR2(1) := 'A';
    g_pos_pharm_outd     CONSTANT VARCHAR2(1) := 'O';
    g_pos_pharm_cancel   CONSTANT VARCHAR2(1) := 'C';

    g_pos_pharm_det_active CONSTANT VARCHAR2(1) := 'A';
    g_pos_pharm_det_outd   CONSTANT VARCHAR2(1) := 'O';
    g_pos_pharm_det_cancel CONSTANT VARCHAR2(1) := 'C';

    g_pos_schedule_active sr_pos_schedule.flg_status%TYPE := 'A';
    g_pos_schedule_cancel sr_pos_schedule.flg_status%TYPE := 'C';
    g_pos_schedule_outd   sr_pos_schedule.flg_status%TYPE := 'O';

    g_action_flg_default     action.flg_default%TYPE := 'D';
    g_action_flg_non_default action.flg_default%TYPE := 'N';

    g_flg_new    CONSTANT VARCHAR2(1) := 'N';
    g_flg_edit   CONSTANT VARCHAR2(1) := 'E';
    g_flg_remove CONSTANT VARCHAR2(1) := 'R';

    g_pos_requisition CONSTANT VARCHAR(1) := 'R';
    g_pos_decision    CONSTANT VARCHAR(1) := 'D';

    g_pos_dt_valid_lower CONSTANT VARCHAR(1) := 'L';

    g_sr_pos_status_no_decision CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 5;
    g_sr_pos_status_not_needed  CONSTANT sr_pos_status.id_sr_pos_status%TYPE := 6;    

END pk_sr_pos;
/
