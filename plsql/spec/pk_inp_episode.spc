/*-- Last Change Revision: $Rev: 2028743 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:39 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_inp_episode IS

    /*******************************************************************************************************************************************
    * CREATE_EPISODE                  Function that creates one new INPATIENT episode (episode and visit) and return new episode identifier.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with this new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with this new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with this new episode
    * @param I_ID_BED                 BED identifier that should be associated with this new episode
    * @param I_DT_BEGIN               Episode start date (begin date) that should be associated with this new episode
    * @param I_DT_DISCHARGE           Episode discharge date that should be associated with this new episode
    * @param I_ANAMNESIS              Anamnesis information that should be associated with this new episode
    * @param I_FLG_SURGERY            Information if new episode should be associated with an cirurgical episode
    * @param I_TYPE                   EPIS_TYPE identifier that should be associated with this new episode
    * @param I_DT_SURGERY             Surgery date that should be associated with ORIS episode associated with this new episode
    * @param I_ID_PREV_EPISODE        EPISODE identifier that represents the parent episode that should be associated with this new episode
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with this new episode
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_INP_EPISODE         INPATIENT episode identifier created for this new patient
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/08
    *
    *******************************************************************************************************************************************/
    FUNCTION create_episode
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_patient       IN NUMBER,
        i_id_dep_clin_serv IN NUMBER,
        i_id_room          IN NUMBER,
        i_id_bed           IN NUMBER,
        i_dt_begin         IN VARCHAR2,
        i_dt_discharge     IN VARCHAR2,
        i_flg_hour_origin  IN VARCHAR2 DEFAULT pk_discharge.g_disch_flg_hour_dh,
        i_anamnesis        IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_type             IN NUMBER,
        i_dt_surgery       IN VARCHAR2,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_id_inp_episode   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CREATE_EPISODE_NO_COMMIT        Function that creates one new INPATIENT episode (episode and visit) and return new episode identifier.
    *                                 NOTE: - This function hasn't transactional control (COMMIT)
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with this new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with this new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with this new episode
    * @param I_ID_BED                 BED identifier that should be associated with this new episode
    * @param I_DT_BEGIN               Episode start date (begin date) that should be associated with this new episode
    * @param I_FLG_DT_BEGIN_WITH_TSTZ Indicates if is necessary consider current timezone of dt_begin ('Y' - Yes; 'N' - No)
    * @param I_DT_DISCHARGE           Episode discharge date that should be associated with this new episode
    * @param I_ANAMNESIS              Anamnesis information that should be associated with this new episode
    * @param I_FLG_SURGERY            Information if new episode should be associated with an cirurgical episode
    * @param I_TYPE                   EPIS_TYPE identifier that should be associated with this new episode
    * @param I_DT_SURGERY             Surgery date that should be associated with ORIS episode associated with this new episode
    * @param I_ID_PREV_EPISODE        EPISODE identifier that represents the parent episode that should be associated with this new episode
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with this new episode
    * @param I_TRANSACTION_ID         Scheduler 3.0 transaction ID
    * @param O_ID_INP_EPISODE         INPATIENT episode identifier created for this new patient
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises err_create_all_surgery  Error in surgery creation
    * @raises err_set_epis_anamnesis  Error creating anamnesis
    * @raises err_ins_episode         Error creating episode
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/08
    *
    *******************************************************************************************************************************************/
    FUNCTION create_episode_no_commit
    (
        i_lang                   IN NUMBER,
        i_prof                   IN profissional,
        i_id_patient             IN NUMBER,
        i_id_dep_clin_serv       IN NUMBER,
        i_id_room                IN NUMBER,
        i_id_bed                 IN NUMBER,
        i_dt_begin               IN VARCHAR2,
        i_flg_dt_begin_with_tstz IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_discharge           IN VARCHAR2,
        i_flg_hour_origin        IN VARCHAR2 DEFAULT pk_discharge.g_disch_flg_hour_dh,
        i_anamnesis              IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_type                   IN NUMBER,
        i_dt_surgery             IN VARCHAR2,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_transaction_id         IN VARCHAR2,
        i_id_visit               IN visit.id_visit%TYPE,
        i_inst_dest              IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set              IN VARCHAR2 DEFAULT 'N',
        i_flg_compulsory         IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason   IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason      IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_inp_episode         OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE_DISCH          Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROFESSIONAL           Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_TYPE                   Type of surgery ('A' - Ambulatory)
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/09/09
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_episode_disch
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_visit             IN visit.id_visit%TYPE,
        i_id_professional      IN profissional,
        i_epis_type            IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv     IN NUMBER,
        i_id_room              IN NUMBER,
        i_dt_begin             IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext       IN VARCHAR2,
        i_flg_type             IN VARCHAR2,
        i_type                 IN VARCHAR2,
        i_dt_surgery           IN VARCHAR2,
        i_flg_surgery          IN VARCHAR2,
        i_id_prev_episode      IN episode.id_prev_episode%TYPE,
        i_transaction_id       IN VARCHAR2,
        i_flg_compulsory       IN episode.flg_compulsory%TYPE DEFAULT NULL,
        i_id_compulsory_reason IN episode.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason    IN episode.compulsory_reason%TYPE DEFAULT NULL,
        o_id_episode           OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CALL_INS_EPISODE                Create an episode for an patient with send parameters (including dates) and returns id_visit created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_DT_CREATION            Episode creation date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMITION_NOTES      Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param i_transaction_id         remote transaction identifier
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user. 
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records 
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.5
    * @since                          2009/09/09
    *
    *******************************************************************************************************************************************/
    FUNCTION call_ins_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_dt_creation            IN episode.dt_creation%TYPE,
        i_id_episode_ext         IN epis_ext_sys.value%TYPE,
        i_flg_type               IN episode.flg_type%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admition_notes      IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration          IN visit.flg_migration%TYPE,
        i_transaction_id         IN VARCHAR2,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE DEFAULT NULL,
        o_id_episode             OUT episode.id_episode%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CALL_UPD_EPISODE                update an episode for an episode with send parameters (including dates) 
    * 
    * @param I_LANG                   Language ID for translations    
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries   
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode        
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_FIRST_DEP_CLIN_SERV first DEP_CLIN_SERV identifier that should be associated with the episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date in (Format: TIMESTAMP WITH LOCAL TIME ZONE)        
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge    
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMISSION_NOTES     Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_transaction_id         remote transaction identifier
    * @param i_allocation_commit      Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * @raises   l_internal_error      Internal error on call_upd_episode
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          2009/10/01
    *
    *******************************************************************************************************************************************/
    FUNCTION call_upd_episode
    (
        i_lang                         IN language.id_language%TYPE,
        i_prof_resp                    IN profissional,
        i_prof_intf                    IN profissional,
        i_id_episode                   IN episode.id_episode%TYPE,
        i_id_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv       IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                      IN room.id_room%TYPE,
        i_id_bed                       IN epis_info.id_bed%TYPE,
        i_flg_type                     IN bed.flg_type%TYPE,
        i_desc_bed                     IN bed.desc_bed%TYPE,
        i_dt_begin                     IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                      IN episode.flg_ehr%TYPE,
        i_dt_disch_sched               IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_admition_notes               IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes           IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode              IN episode.id_prev_episode%TYPE,
        i_transaction_id               IN VARCHAR2,
        i_allocation_commit            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_creation_allocation       IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_dt_creation_resp             IN epis_prof_resp.dt_execute_tstz%TYPE DEFAULT NULL,
        i_flg_resp_type                IN epis_multi_prof_resp.flg_resp_type%TYPE DEFAULT NULL,
        i_epis_flg_type                IN episode.flg_type%TYPE DEFAULT NULL,
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_bed_allocation               OUT VARCHAR2,
        o_exception_info               OUT sys_message.desc_message%TYPE,
        o_error                        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_EPIS_DIAGNOSIS              Function that returns diagnosis associated with one episode
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be searched
    * @param O_DIAGNOSIS              Diagnosis associated with episode identifier
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          N.A.
    *
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION get_epis_diagnosis
    (
        i_lang       IN NUMBER,
        i_id_prof    IN profissional,
        i_id_episode IN NUMBER,
        o_diagnosis  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * CHECK_INPATIENTS                Function that validates if one new INPATIENT episode can be created
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new episode
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_DT_BEGIN               Episode begin date
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns '1' if success, otherwise returns '0'
    * 
    * @raises l_my_exception          Error when is not possible create an new INPATIENT episode
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         JSILVA
    * @version                        1.0
    * @since                          2007/04/17
    * 
    * @author                         Luís Maia
    * @version                        2.0
    * @since                          2009/05/11
    *
    *******************************************************************************************************************************************/
    FUNCTION check_inpatients
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_begin         IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * CHECK_OBS_EPISODE        Checks if 'i_id_episode' is an OBS episode.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional info.
    * @param i_id_episode      Episode ID
    * @param o_error           Error message
    * 
    * @return                  TRUE if it's an OBS episode, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-Jun-04
    *
    ******************************************************************************/
    FUNCTION check_obs_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /***************************************************************************************************************
    * Patient efectivation through an existing admission schedule
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    remote transaction identifier
    * @param      i_id_cancel_reason  Cancel_reason identifier
    * @param      i_bed_allocation    Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   12-10-2009
    *
    ****************************************************************************************************/
    FUNCTION register_admission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_bed_allocation   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Cancel an efectivation (the inverse operation of register_admission)
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_episode           ID_EPISODE to register
    * @param      i_id_patient        Patient identifier
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    remote transaction identifier
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   20-10-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_registration
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Cancels an admission schedule with cancelation reason: Patient did not show.
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional     
    * @param      i_id_schedule       Schedule identifier
    * @param      i_transaction_id    Scheduler 3.0 transaction ID
    * @param      i_id_cancel_reason  Cancel_reason identifier
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   22-10-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_schedule_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * SET_MATCH_SCHEDULE_INP                upates tables: schedule_inp_bed. To be used on match functionality
    *
    * @param i_lang                          Language ID
    * @param i_prof                          Profissional array
    * @param i_episode_temp                  Temporary episode
    * @param i_episode                       Episode identifier 
    * @param o_error                         Error object
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.5.0.7
    * @since                                 2009/11/03
    **********************************************************************************************/
    FUNCTION set_match_schedule_inp
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************    
    * Returns the current value of the scheduled discharge date for the provided episode    
    *    
    * @param i_lang                ID language    
    * @param i_prof                Object with user info    
    * @param i_episode             ID of episode    
    *        
    *    
    * @return                      Timestamp with the current value of the scheduled discharge date     
    *                            
    * @author                      RicardoNunoAlmeida    
    * @version                     2.5.0.7    
    * @since                       2009/12/16    
    **********************************************************************************************/
    FUNCTION get_disch_schedule_curr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN discharge_schedule.dt_discharge_schedule%TYPE;

    /**********************************************************************************************
    * Checks if a given episode has already been registered
    *
    * @param i_lang                ID language   
    * @param i_episode             ID of episode      
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.5.0.7.8
    * @since                       2010/03/24
    **********************************************************************************************/
    FUNCTION is_epis_registered
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the actions to be shown in the scheduled grid, according to the configuration 
    * that indicates if it is being used the ALERT SCHEDULER in the intitution.
    *
    * @param i_lang                ID language   
    * @param i_prof                Professional
    * @param i_prof_follow         'Y' if the PROF_FOLLOW subject actions will be returned
    * @param o_actions             Output cursor
    * @param o_error                         Error object
    *
    * @return                      Y-registered episode; N-not registered episode
    *                        
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       25-Aug-2010
    **********************************************************************************************/
    FUNCTION get_sch_grid_actions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_follow IN VARCHAR2,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;



    FUNCTION get_admission_discharge
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_episode_info OUT pk_types.cursor_type,
        o_diag         OUT pk_types.cursor_type,
        o_surgical     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN; 
    
    -- ********************************************************************************
    -- *********************************** GLOBALS ************************************
    -- ********************************************************************************   
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);
    --
    -- Private exceptions
    e_call_error EXCEPTION;
    --
    g_max_length           NUMBER;
    g_software_intern_name VARCHAR2(3);
    g_sysdate_tstz         TIMESTAMP WITH LOCAL TIME ZONE;
    g_ret                  BOOLEAN;
    g_error                VARCHAR2(4000);

    g_bed_flg_vacant VARCHAR2(0050);
    g_bed_flg_filled VARCHAR2(0050);
    g_bed_permanent  VARCHAR2(0050);
    g_bed_temporary  VARCHAR2(0050);

    g_visit_active       VARCHAR2(0050);
    g_id_epis_type       NUMBER;
    g_anamnesis_flg_type VARCHAR2(0050);

    g_cat_flg_available VARCHAR2(0050);
    g_cat_flg_prof      VARCHAR2(0050);

    g_epis_stat_inactive VARCHAR2(0050);

    g_episode_flg_status_active   VARCHAR2(0050);
    g_episode_flg_status_temp     VARCHAR2(0050);
    g_episode_flg_status_canceled VARCHAR2(0050);
    g_episode_flg_status_inactive VARCHAR2(0050);

    g_epis_info_efectiv VARCHAR2(0050);

    g_pat_allergy_cancel VARCHAR2(0050);
    g_pat_habit_cancel   VARCHAR2(0050);
    g_pat_problem_cancel VARCHAR2(0050);
    g_pat_notes_cancel   VARCHAR2(0050);
    g_pat_blood_active   VARCHAR2(0050);

    g_found BOOLEAN;

    g_epis_temporary  VARCHAR2(0050);
    g_epis_definitive VARCHAR2(0050);

    -- JS, 2007-09-21: New model of problems and relevant diseases
    g_pat_history_diagnosis_y VARCHAR2(1);
    g_pat_history_diagnosis_n VARCHAR2(1);

    g_discharge_flg_status_a CONSTANT discharge.flg_status%TYPE := 'A';
    g_discharge_flg_status_p CONSTANT discharge.flg_status%TYPE := 'P';
    g_discharge_flg_status_r CONSTANT discharge.flg_status%TYPE := 'R';

    g_hplan_active    CONSTANT pat_health_plan.flg_status%TYPE := 'A';
    g_default_hplan_y CONSTANT pat_health_plan.flg_default%TYPE := 'Y';

    g_flg_template_type CONSTANT doc_template_context.flg_type%TYPE := 'S';

    -- Types of episodes
    g_flg_ehr_n CONSTANT episode.flg_ehr%TYPE := 'N';

    g_scheduled_episode CONSTANT episode.flg_ehr%TYPE := 'S';

    g_soft_edis CONSTANT software.id_software%TYPE := 8;
    g_soft_inp  CONSTANT software.id_software%TYPE := 11;

    -- sys_config identifier that indicated if the institution is using the ALERT SCHEDULER
    g_has_scheduler           CONSTANT sys_config.id_sys_config%TYPE := 'ADMISSION_SCHEDULER_EXISTS';
    g_sch_grid_actions        CONSTANT action.subject%TYPE := 'INP_SCH_ACTION_BUTTON';
    g_sch_grid_actions_follow CONSTANT action.subject%TYPE := 'PROF_FOLLOW';
    g_from_state_a            CONSTANT VARCHAR2(1) := 'A';
    g_from_state_s            CONSTANT VARCHAR2(1) := 'S';
    g_from_state_n            CONSTANT VARCHAR2(1) := 'N';
    g_from_state_y            CONSTANT VARCHAR2(1) := 'Y';
    g_from_state_m            CONSTANT VARCHAR2(1) := 'M';

    -- cancel reason area of the cancel reason used to cancel an allocation
    g_alloc_cancel_reason_area CONSTANT NUMBER := 39;

    g_alloc_cancel_reason CONSTANT NUMBER := 137;
END;
/
