/*-- Last Change Revision: $Rev: 2028747 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_grid AS

    g_owner          VARCHAR2(0050);
    g_error          VARCHAR2(4000);
    g_package        VARCHAR2(0050);
    g_dia_flg_type   VARCHAR2(0050);
    g_epis_active    VARCHAR2(0050);
    g_epis_cancelled VARCHAR2(0050);
    g_inp_epis_type  NUMBER;
    g_sr_epis_type   NUMBER;
    g_ret            BOOLEAN;


    g_diet_requested VARCHAR2(0050);

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

    g_discharge_active         VARCHAR2(0050);
    g_software_intern_name     VARCHAR2(0050);
    g_epis_flg_status_active   VARCHAR2(0050);
    g_epis_flg_status_inactive VARCHAR2(0050);
    g_epis_flg_status_temp     VARCHAR2(0050);
    g_epis_flg_status_canceled VARCHAR2(0050);

    g_status_movement_t VARCHAR2(0050);

    g_selected VARCHAR2(1);

    g_flg_dpt_type VARCHAR2(0050);

    g_disch_flg_status_active discharge.flg_status%TYPE;
    g_disch_flg_status_pend   discharge.flg_status%TYPE;
    g_disch_flg_status_cancel discharge.flg_status%TYPE;
    g_disch_flg_status_reopen discharge.flg_status%TYPE;

    g_cat_doctor category.flg_type%TYPE;
    g_cat_nurse  category.flg_type%TYPE;

    g_epis_flg_type_def episode.flg_type%TYPE;

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';
    g_task_monitor  CONSTANT VARCHAR2(1) := 'M';
    g_task_interv   CONSTANT VARCHAR2(1) := 'I';
    g_task_edu      CONSTANT VARCHAR2(1) := 'T'; -- Patient education

    g_flg_ehr_normal    CONSTANT VARCHAR2(1) := 'N';
    g_flg_ehr_scheduled CONSTANT VARCHAR2(1) := 'S';

    g_discharge_flg_status_a CONSTANT discharge.flg_status%TYPE := 'A';
    g_discharge_flg_status_p CONSTANT discharge.flg_status%TYPE := 'P';

    g_inp_epis_type_code CONSTANT VARCHAR2(200) := 'EPIS_TYPE.CODE_EPIS_TYPE.5';

    g_sch_flg_status_letter    CONSTANT VARCHAR2(1) := 'A';
    g_rgt_flg_status_letter    CONSTANT VARCHAR2(1) := 'I';
    g_cnc_flg_status_letter    CONSTANT VARCHAR2(1) := 'N';
    g_cncsch_flg_status_letter CONSTANT VARCHAR2(1) := 'C';

    g_discharge_schedule_flg      CONSTANT VARCHAR2(1) := 'S';
    g_desc_discharge_flg_status_p CONSTANT VARCHAR2(200) := 'INP_MAIN_GRID_DISCHARGE_T002';
    g_desc_discharge_flg_status_a CONSTANT VARCHAR2(200) := 'INP_MAIN_GRID_DISCHARGE_T001';
    g_desc_discharge_flg_status_s CONSTANT VARCHAR2(200) := 'INP_MAIN_GRID_DISCHARGE_T004';
    g_desc_disch_flg_status_adm   CONSTANT VARCHAR2(200) := 'INP_MAIN_GRID_DISCHARGE_T005';

    g_phy_presc_profile   CONSTANT NUMBER := 655;
    g_grid_task_def_pos   CONSTANT NUMBER := 2;
    g_grid_task_delimiter CONSTANT VARCHAR2(1) := '|';

    -- Sys_config id to the display period of the cancelled episodes in the grids
    g_cf_canc_epis_time  CONSTANT sys_config.id_sys_config%TYPE := 'CANCELLED_EPISODES_DISPLAY_TIME';
    g_cf_pat_gender_abbr CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';
    g_cf_epis_status     CONSTANT sys_config.id_sys_config%TYPE := 'EPIS_INFO.FLG_STATUS';
    g_cf_disch_epis_time  CONSTANT sys_config.id_sys_config%TYPE := 'DISCHARGED_EPISODES_DISPLAY_TIME';

    g_sort_mask    CONSTANT VARCHAR2(6) := '00000';
    g_six          CONSTANT PLS_INTEGER := 6;
    g_zero         CONSTANT PLS_INTEGER := 0;
    g_one          CONSTANT PLS_INTEGER := 1;
    g_zero_varchar CONSTANT VARCHAR2(1) := '0';

    --Handoff responsabilities constants
    g_show_in_grid    CONSTANT VARCHAR2(1) := 'G';
    g_show_in_tooltip CONSTANT VARCHAR2(1) := 'T';

    FUNCTION get_diagnosis_grid
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_diagnosis_grid
    (
        i_lang            IN NUMBER,
        i_id_professional IN NUMBER,
        i_id_institution  IN NUMBER,
        i_id_software     IN NUMBER,
        i_id_episode      IN NUMBER
    ) RETURN VARCHAR2;

    --FUNCTION GET_INTERNMENTS( I_LANG IN NUMBER, I_PROF IN PROFISSIONAL, I_ID_PATIENT  IN NUMBER, I_FLG_WHICH  IN VARCHAR2, O_GRID OUT PK_TYPES.CURSOR_TYPE, O_ERROR OUT VARCHAR2) RETURN BOOLEAN;
    FUNCTION get_all_inpatients
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_flg_which  IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_anamnesis  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_grid_all_pat_aux
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   GRELHA DO AUXILIAR
       PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL
                             I_PROF - ID DO PROF Q ACEDE
    
                    SAIDA:   O_GRID - ARRAY
                             O_ERROR - ERRO
    
      CRIAÇÃO: SS 2006/11/08
      NOTAS:
    *********************************************************************************/

    /********************************************************************************************
    * Returns the discharge type: P-pending discharge, A-active discharge, S-expected discharge, 
    *                             null - no discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    *
    * @return                        Discharge type message
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         07/12/2009
    ********************************************************************************************/
    FUNCTION get_epis_status_icon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_flg_status IN episode.flg_status%TYPE,
        i_flg_dsch_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_grid_all_pat_adm
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Returns the information to fill the patients grid. Only the scheduled episodes are shown.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_obs                 OBS or non OBS services
    * @param o_grid                    Episodes information and the assotiated tasks
    * @param o_risk_label              Label related to the risk assessment column
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           29-11-2006
    **********************************************************************************************/
    FUNCTION get_scheduled_episodes
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_view  IN view_option.screen_identifier%TYPE,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if the episode has a discharge. 
    * If professional is doctor checks if there is a doctor discharge
    * If professional is nurse checks if there is a nurse discharge
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    *
    * @RETURN  'Y' - there is a discharge; 'N' - otherwise
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   28-10-2009
    **********************************************************************************************/
    FUNCTION check_discharge_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN discharge.flg_type_disch%TYPE;

    /********************************************************************************************
    * Returns the discharge type message: indicated if it is an active, 
    *                                pending or predicted discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    * @param i_flg_dsch_status       Flg discharge status P-pending, A-sctive, S-expected discharge
    *
    * @return                        Discharge type message
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_msg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_dsch_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the discharge type: P-pending discharge, A-active discharge, S-expected discharge, 
    *                             null - no discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    *
    * @return                        Discharge type message
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_flg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN discharge.flg_status%TYPE;

    /********************************************************************************************
    *  Get grid task str. For the prescription profile the monitoring and positioning shortcuts
    *  should not be returned 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids    
    * @param I_STR                     GRID_TASK text
    * @param I_POSITION                Position of the date field
    * @param i_id_profile_template     Profile template identifier
    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *    
    * @author                          Sofia Mendes
    * @version                         2.6.0.1
    * @since                           22-10-2009
    **********************************************************************************************/
    FUNCTION get_grid_task_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_str                 IN VARCHAR2,
        i_position            IN NUMBER DEFAULT g_grid_task_def_pos
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the schedule status.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    * @param   i_id_schedule Schedule identifier
    *
    * @RETURN  EPISODe schedule flg_status
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   28-Jun-2011
    **********************************************************************************************/
    FUNCTION get_wl_sch_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN wtl_epis.id_episode%TYPE,
        i_id_schedule IN wtl_epis.id_schedule%TYPE
    ) RETURN wtl_epis.flg_status%TYPE;

    /********************************************************************************************
    * Get the schedule status.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    *
    * @RETURN  EPISODe schedule flg_status
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   28-Jun-2011
    **********************************************************************************************/
    FUNCTION get_sch_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN wtl_epis.id_episode%TYPE
    ) RETURN wtl_epis.flg_status%TYPE;

    /********************************************************************************************
    * Returns  label related to the risk assessment column 
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    *
    * @return                        Discharge type message
    *
    * @author                        Filipe Silva
    * @version                       2.6.1.2
    * @since                         19/07/2011
    ********************************************************************************************/
    FUNCTION get_risk_label
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_risk_label OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_keys IN table_varchar DEFAULT NULL,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );


    FUNCTION get_pats_from_pref_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
	
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_diet_name_t        CONSTANT VARCHAR2(1) := 'T';
    g_discharge_shortcut CONSTANT VARCHAR2(13 CHAR) := 'ADM_DISCHARGE';

    --INP AN 22-Mar-2011 [ALERT-28312]
    g_flg_service_transfer_s   CONSTANT VARCHAR2(2 CHAR) := '@S';
    g_sysdomain_service_transf CONSTANT VARCHAR2(30 CHAR) := 'EPIS_PROF_RESP.TRANSFER_STATUS';

END pk_inp_grid;
/
