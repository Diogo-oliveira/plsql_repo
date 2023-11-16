CREATE OR REPLACE PACKAGE pk_api_inpatient IS

    -- Created : 30-07-2009 15:29:24
    -- Purpose : API for INPATIENT

    /********************************************************************************************
    * SET_TRANSFER_INPATIENT       This function creates service transfers for a specific episode
    *                              USE: INTERFACE TEAM
    *
    * @param i_lang                language id
    * @param i_prof                professional id (INTERFACE PROFESSIOAL USED FOR MIGRATION)
    * @param i_rec_episode         Episode registry information
    * @param i_trf_reason          Transfer reason
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.5.0.6
    * @since                       2009/09/09
    * @dependents                  INTERFACE TEAM
    **********************************************************************************************/
    FUNCTION set_transfer_inpatient
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rec_episode       IN pk_api_visit.rec_episode,
        i_trf_reason        IN VARCHAR2,
        i_id_bed            IN bed.id_bed%TYPE,
        i_dt_transfer       IN VARCHAR2,
        o_id_epis_prof_resp OUT epis_prof_resp.id_epis_prof_resp%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * MIG_SERVICE_TRANSFER
    *
    * @param i_lang                   the id language
    * @param i_id_episode             Episode Id
    * @param i_id_patient             Patient Id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_department_orig     Id department origin
    * @param i_id_department_dest     Id department destiny
    * @param i_id_dep_clin_serv       Id dep_clin_serv
    * @param i_trf_reason             Transfer reason
    * @param i_id_prof_dest           destiny professional identifier
    * @param i_dt_trf_requested       date of request
    * @param i_notes                  note of request
    * @param i_clinical_service       desteny clinical service identifier
    * @param i_dt_trf_accepted        date of transfer acceptance
    * @param i_trf_answer             Transfer acceptance answer (notes)
    * @param i_id_room                room identifier
    * @param i_id_bed                 bed identifier
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @version                        2.6.0.4
    * @since                          20/Ago/2010
    **********************************************************************************************/
    FUNCTION mig_service_transfer
    (
        i_lang               IN language.id_language%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_prof               IN profissional,
        i_id_department_orig IN epis_prof_resp.id_department_orig%TYPE,
        i_id_department_dest IN epis_prof_resp.id_department_dest%TYPE,
        i_id_dep_clin_serv   IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_trf_reason         IN epis_prof_resp.trf_reason%TYPE,
        --
        i_id_prof_dest     IN epis_prof_resp.id_prof_to%TYPE,
        i_dt_trf_requested IN epis_prof_resp.dt_trf_requested_tstz%TYPE,
        i_notes            IN epis_prof_resp.notes_clob%TYPE,
        i_clinical_service IN epis_prof_resp.id_clinical_service_dest%TYPE,
        --
        i_dt_trf_accepted IN epis_prof_resp.dt_trf_accepted_tstz%TYPE,
        i_trf_answer      IN epis_prof_resp.trf_answer%TYPE,
        i_id_room         IN epis_prof_resp.id_room%TYPE,
        i_id_bed          IN epis_prof_resp.id_bed%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_EPISODE                Get inpatient episodes according to parameter.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/10
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof_resp        IN profissional,
        i_prof_intf        IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_id_sched         IN epis_info.id_schedule%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_health_plan      IN health_plan.id_health_plan%TYPE,
        i_epis_type        IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_bed           IN epis_info.id_bed%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE,
        i_flg_type         IN episode.flg_type%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_dt_disch_sched   IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery       IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_EPISODE                Get inpatient episodes according to parameter.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/10
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof_resp        IN profissional,
        i_prof_intf        IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_id_sched         IN epis_info.id_schedule%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_health_plan      IN health_plan.id_health_plan%TYPE,
        i_epis_type        IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_bed           IN epis_info.id_bed%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE,
        i_flg_type         IN episode.flg_type%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_dt_disch_sched   IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery       IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_admition_notes   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_bed_allocation   OUT VARCHAR2,
        o_exception_info   OUT sys_message.desc_message%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_EPISODE                Get inpatient episodes according to parameter.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.1
    * @since                          07-06-2011
    * @dependents                     INTERFACE TEAM
    *                                 ADT TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_visit               IN visit.id_visit%TYPE,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext         IN epis_ext_sys.value%TYPE,
        i_flg_type               IN episode.flg_type%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        o_id_episode             OUT episode.id_episode%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_EPISODE                Get inpatient episodes according to parameter.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_ID_EPISODE_EXT         EPISODE_EXT identifier that should be associated with new episode
    * @param I_FLG_TYPE               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_DT_SURGERY             Episode SURGERY date
    * @param I_FLG_SURGERY            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param I_ID_EXTERNAL_SYS        EXTERNAL_SYS identifier that should be associated with new episode
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
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
    * @version                        2.6.0.4
    * @since                          19/Aug/2010
    * @dependents                     MIGRATION TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof_resp        IN profissional,
        i_prof_intf        IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_id_sched         IN epis_info.id_schedule%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_health_plan      IN health_plan.id_health_plan%TYPE,
        i_epis_type        IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_bed           IN epis_info.id_bed%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE,
        i_flg_type         IN episode.flg_type%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_dt_disch_sched   IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery       IN VARCHAR2,
        i_flg_surgery      IN VARCHAR2,
        i_admition_notes   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_id_prev_episode  IN episode.id_prev_episode%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration    IN visit.flg_migration%TYPE,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_bed_allocation   OUT VARCHAR2,
        o_exception_info   OUT sys_message.desc_message%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Get inpatient episodes according to parameter.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_VISIT               VISIT identifier that should be associated with new episode
    * @param I_ID_SCHED               SCHEDULE identifier that should be associated with new episode
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_HEALTH_PLAN            HEALTH_PLAN identifier that should be associated with new episode
    * @param I_EPIS_TYPE              EPIS_TYPE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
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
    * @author                         António Neto
    * @version                        2.6.1.2
    * @since                          19-Jul-2011
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_visit               IN visit.id_visit%TYPE,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext         IN epis_ext_sys.value%TYPE,
        i_flg_type               IN episode.flg_type%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admition_notes      IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_flg_migration          IN visit.flg_migration%TYPE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        o_id_episode             OUT episode.id_episode%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_UPD_EPISODE                Update inpatient episodes according to parameter(s).
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.5.0.7
    * @since                          2009/10/01
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_upd_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_flg_bed_type           IN bed.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_UPD_EPISODE                Update inpatient episodes according to parameter(s).
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param O_ID_EPISODE             EPISODE identifier corresponding to created episode
    * @param O_BED_ALLOCATION         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param O_EXCEPTION_INFO         Error message to be displayed to the user.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.8
    * @since                          2010/Mar/11
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_upd_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_flg_bed_type           IN bed.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        o_bed_allocation         OUT VARCHAR2,
        o_exception_info         OUT sys_message.desc_message%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_VISIT                  Create an visit for an patient with send parameters (including dates) and returns id_visit created
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new visit
    * @param I_EXTERNAL_CAUSE         EXTERNAL_CAUSE identifier that should be associated with new visit
    * @param I_DATE_TSTZ              Begining date with TIMESTAMP WITH LOCAL TIME ZONE
    * @param O_ID_VISIT               VISIT identifier corresponding to created visit
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/10
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_date_tstz      IN visit.dt_begin_tstz%TYPE,
        o_id_visit       OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_INS_VISIT                  Create an visit for an patient with send parameters (including dates) and returns id_visit created
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with new visit
    * @param I_EXTERNAL_CAUSE         EXTERNAL_CAUSE identifier that should be associated with new visit
    * @param I_DATE_TSTZ              Begining date with TIMESTAMP WITH LOCAL TIME ZONE
    * @param I_ID_ORIGIN              Origin identifier
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param O_ID_VISIT               VISIT identifier corresponding to created visit
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @value  I_FLG_MIGRATION         {*} 'A'- ALERT visits {*} 'M'- Migrated records {*} 'T'- Test records
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.6.0.4
    * @since                          19/Aug/2010
    * @dependents                     MIGRATION TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_ins_visit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_date_tstz      IN visit.dt_begin_tstz%TYPE,
        i_id_origin      IN visit.id_origin%TYPE,
        i_flg_migration  IN visit.flg_migration%TYPE,
        o_id_visit       OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create visit and episode for ADT
    *
    * @param i_lang                   Language ID
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param i_id_patient             Patient ID
    * @param i_id_visit               Visit ID
    * @param i_external_cause         External cause for admission
    * @param i_dt_begin               Admission date in TSTZ format
    * @param i_id_sched               Schedule ID
    * @param i_health_plan            Patient health plan
    * @param i_epis_type              Episode Type
    * @param i_id_dep_clin_serv       Dep clinical service
    * @param i_id_room                Room
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param i_id_episode_ext         External Episode ID
    * @param i_flg_type               Episode type ('T' - TEMPORARY, 'D' - DEFINITIVE)
    * @param i_flg_ehr                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param i_dt_disch_sched         Schedule discharge
    * @param i_admition_notes         Admition notes
    * @param i_dt_admission_notes     Admition notes Date/Time
    * @param i_dt_surgery             Date of surgery
    * @param i_flg_surgery            Indicates if this episode has an SURGERY episode associated: ('Y' - Yes, 'N' - No)
    * @param i_id_prev_episode        Previous Episode ID
    * @param i_id_external_sys        External System ID
    * @param I_ID_ORIGIN              Origin identifier
    * @param I_FLG_MIGRATION          Shows type of visit ('A' for ALERT visits, 'M' for migrated records, 'T' for test records)
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * @param o_id_episode             Episode ID returned
    * @param o_error                  Error executing function
    *
    * @author                         António Neto
    * @since                          19-Jul-2011
    * @version                        2.6.1.2
    * @dependents                     INTERFACE TEAM
    **********************************************************************************************/
    FUNCTION ins_visit_and_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_intf              IN profissional,
        i_prof_resp              IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_visit               IN visit.id_visit%TYPE,
        i_external_cause         IN visit.id_external_cause%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_id_sched               IN epis_info.id_schedule%TYPE,
        i_health_plan            IN health_plan.id_health_plan%TYPE,
        i_epis_type              IN episode.id_epis_type%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_id_episode_ext         IN VARCHAR2,
        i_flg_type               IN VARCHAR2,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes     IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_dt_surgery             IN VARCHAR2,
        i_flg_surgery            IN VARCHAR2,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        i_id_external_sys        IN epis_ext_sys.id_external_sys%TYPE,
        i_id_origin              IN visit.id_origin%TYPE,
        i_flg_migration          IN visit.flg_migration%TYPE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        i_id_waiting_list        IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_id_episode             OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * UPD_VISIT_AND_EPISODE           Update visit and episode for ADT
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF_RESP              Professional that should be responsable for this episode
    * @param I_PROF_INTF              Professional of interfaces that should be associated with current creation registries
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with new episode
    * @param I_ID_DEP_CLIN_SERV       DEP_CLIN_SERV identifier that should be associated with new episode
    * @param I_ID_ROOM                ROOM identifier that should be associated with new episode
    * @param I_ID_BED                 BED identifier that shoul be associated with new episode
    * @param I_FLG_BED_TYPE           BED type ('P'-permanent; 'T'-temporary)
    * @param I_DESC_BED               Description associated with this bed
    * @param I_DT_BEGIN               Episode begin date (format: TIMESTAMP WITH LOCAL TIME ZONE)
    * @param I_FLG_EHR                Type of EHR episode ('N' - Normal episode, 'E' - EHR event, 'S' - Episode preparation of a scheduled event)
    * @param I_DT_DISCH_SCHED         Espected date for current episode discharge
    * @param I_ADMITION_NOTES         Admition notes
    * @param I_DT_ADMISSION_NOTES     Admition notes Date/Time
    * @param I_ID_PREV_EPISODE        EPISODE identifier that should be associated with new episode (PREV_EPISODE identifier)
    * @param i_dt_transportation_srt  Transportation date
    * @param i_id_transp_entity       Transportation identaty
    * @param i_transp_flg_time        Transportation moment in episode ('E' - início do episódio, 'S' - alta administrativa, 'T' - transporte s/ episódio)
    * @param i_transp_notes           Transportation notes
    * @param i_origin                 Visit origem
    * @param i_external_cause         Visit external cause
    * @param i_companion              Patient companion
    * @param i_internal_type          Called from (A) Arrived by (T) Triage
    * @param i_current_timestamp      Transportation creation date
    * @param i_dt_creation_allocation Date in which the bed allocation was done
    * @param i_dt_creation_resp       Hand-off date
    * @param i_flg_type_upd           Type of information update ('U' - Normal update; 'E' - Efectivation)
    * @param i_id_schedule            Schedule identifier
    * @param i_transaction_id         Remote transaction identifier from Scheduler 3.0
    * @param i_id_cancel_reason       Cancel_reason identifier to send to Scheduler 3.0
    * @param I_FLG_RESP_TYPE          Check if flag main overall responsability is to be set ((E - default) Episode (O) overall - patient responsability)
    * @param o_bed_allocation         Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param o_exception_info         Error message to be displayed to the user.
    * @param o_error                  If an error accurs, this parameter will have information about the error
    *
    * @author                         Luís Maia
    * @since                          2010/Apr/06
    * @version                        2.6.0.1
    * @dependents                     ADT TEAM
    **********************************************************************************************/
    FUNCTION upd_visit_and_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_resp              IN profissional,
        i_prof_intf              IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_dep_clin_serv       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_first_dep_clin_serv IN epis_info.id_first_dep_clin_serv%TYPE,
        i_id_room                IN room.id_room%TYPE,
        i_id_bed                 IN epis_info.id_bed%TYPE,
        i_flg_bed_type           IN bed.flg_type%TYPE,
        i_desc_bed               IN bed.desc_bed%TYPE,
        i_dt_begin               IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr                IN episode.flg_ehr%TYPE,
        i_dt_disch_sched         IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_admition_notes         IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_admission_notes     IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE DEFAULT NULL,
        i_id_prev_episode        IN episode.id_prev_episode%TYPE,
        --
        i_dt_transportation_str  IN VARCHAR2,
        i_id_transp_entity       IN transportation.id_transp_entity%TYPE,
        i_transp_flg_time        IN transportation.flg_time%TYPE,
        i_transp_notes           IN transportation.notes%TYPE,
        i_origin                 IN visit.id_origin%TYPE,
        i_external_cause         IN visit.id_external_cause%TYPE,
        i_companion              IN epis_info.companion%TYPE,
        i_internal_type          IN VARCHAR2, -- (A) Arrived by (T) Triage
        i_current_timestamp      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_creation_allocation IN bmng_allocation_bed.dt_creation%TYPE,
        i_dt_creation_resp       IN epis_prof_resp.dt_execute_tstz%TYPE,
        i_flg_resp_type          IN epis_multi_prof_resp.flg_resp_type%TYPE,
        --
        i_flg_type_upd     IN VARCHAR2,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_epis_flg_type    IN episode.flg_type%TYPE,
        --
        i_flg_allow_bed_alloc_inactive IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        --
        o_bed_allocation OUT VARCHAR2,
        o_exception_info OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Returns the data of the bed allocations associated with the provided episode.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_episode           ID_EPISODE to check
    * @param      o_result            Y/N : Yes for existing bed allocations, no for no available bed allocations
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   16-11-2009
    *
    ****************************************************************************************************/
    FUNCTION get_epis_bed_allocation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * BMNG_RESET                        Cleans all data regarding beds and related info for the episodes provided.
    *
    * @param      i_prof                RESET professional
    * @param      i_episodes            ID of the episodes to be freed
    * @param      i_allocation_commit   Indicates if bed allocation should sent information to scheduler 3.0 ('Y' - Yes; 'N' - No)
    * @param      o_error               If an error accurs, this parameter will have information about the error
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author                           RicardoNunoAlmeida
    * @version                          2.5.0.7.6.1
    * @since                            11-FEB-2010
    * @dependents                       RESET TEAM
    *******************************************************************************************************************************************/
    FUNCTION bmng_reset
    
    (
        i_prof              IN profissional,
        i_episodes          IN table_number,
        i_allocation_commit IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    * Function that executes a positioning movement
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_epis_pos          EPIS_POSITION identifier
    * @param      i_dt_exec_str       date of positioning execution
    * @param      i_notes             execution notes
    * @param      i_rot_interv        rotation interval
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN                         TRUE or FALSE
    * @author                         Luís Maia
    * @version                        2.6.0.4
    * @since                          2010-Ago-30
    * @dependents                     PDMS TEAM
    ****************************************************************************************************/
    FUNCTION set_epis_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_pos    IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str IN VARCHAR2,
        i_notes       IN epis_positioning.notes%TYPE,
        i_rot_interv  IN epis_positioning.rot_interval%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * SET_EPIS_POS_STATUS                    Set an epis_positioning to interrupted
      *
      * @param       i_lang                    language id
      * @param       i_prof                    professional information
      * @param       i_pos_status              epis_positioning id
      * @param       i_flg_status              New status ('I' - Discontinued)
      * @param       i_notes                   Status change notes
    * @param       i_id_cancel_reason        Cancel reason Id
      * @param       o_error                   error information
      *
      * @return      boolean                   true on success, otherwise false
      *
      * @author                                Emilia Taborda
      * @version                               2.4.0
      * @since                                 2006/Nov/18
      *
      * @author                                Luís Maia
      * @version                               2.6.0.4
      * @since                                 2010-Ago-30
      * @dependents                            PDMS TEAM
      ********************************************************************************************/
    FUNCTION set_epis_pos_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the disposition date and label.
    *
    * @param i_lang                          ID language
    * @param i_prof                          Logged professional
    * @param i_row_ei                        EPIS_INFO row_type
    *
    * @param o_disp_date                     Disposition date
    * @param o_disp_date_tstz                Disposition date (timestamp with local time zone)
    * @param o_disp_label                    Disposition label
    * @param o_error                         Error message
    *
    * @return                                True on success, false otherwise
    *
    * @author                                Luís Maia
    * @version                               2.6.0.3.2
    * @since                                 2010-Ago-31
    * @dependents                            PDMS TEAM
    *                                        PRIVATE PRACTICE
    **********************************************************************************************/
    FUNCTION get_inp_disposition_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_row_ei         IN epis_info%ROWTYPE,
        o_disp_date      OUT VARCHAR2,
        o_disp_date_tstz OUT epis_info.dt_med_tstz%TYPE,
        o_disp_label     OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_epis_hidrics_reports         Get hidric detail information.
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPIS_HIDRICS           ID_EPIS_HIDRICS identifier
    * @param   i_flg_scope            Scope: P -patient; E- episode; V-visit
    * @param   i_scope                id_patient if i_flg_scope = 'P'
    *                                 id_visit if i_flg_scope = 'V'
    *                                 id_episode if i_flg_scope = 'E'
    * @param   i_flg_report_type      Report type: C-complete; D-detailed
    * @param   i_start_date           Start date to be considered
    * @param   i_end_date             End date to be considered
    * @param   i_show_balances        Y-The balances info (o_epis_hid_b cursor) is returned. N-otherwise.
    * @param O_EPIS_HID               Cursor that returns the intake and output requets
    * @param O_EPIS_HID_D             Cursor that returns hidrics detail (the takes of each request)
    * @param O_EPIS_HID_B             Cursor that returns hidrics balances
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          12-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_hidrics_reports
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_hidrics    IN epis_hidrics.id_epis_hidrics%TYPE,
        i_flg_scope       IN VARCHAR2, -- P -patient; E- episode; V-visit
        i_scope           IN patient.id_patient%TYPE,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_show_balances   IN VARCHAR2,
        o_epis_hid        OUT pk_types.cursor_type,
        o_epis_hid_d      OUT pk_types.cursor_type,
        o_epis_hid_b      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a Service Transfer
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, Software and Institution ids
    * @param i_id_episode              Episode ID
    * @param i_id_patient              Patient ID
    * @param i_id_epis_prof_resp       Service Transfer ID
    * @param i_id_department_dest      Destination Department ID
    * @param i_dt_cancel               Date of cancelation
    * @param i_cancel_notes            Notes of cancelation
    * @param i_id_cancel_reason        Cancel reason ID
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          António Neto
    * @version                         2.6.1.0.1
    * @since                           21-Apr-2011
    *
    **********************************************************************************************/
    FUNCTION cancel_service_transfer
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_epis_prof_resp  IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_id_department_dest IN epis_prof_resp.id_department_dest%TYPE,
        i_dt_cancel          IN VARCHAR2,
        i_cancel_notes       IN VARCHAR2,
        i_id_cancel_reason   IN epis_prof_resp.id_cancel_reason%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************************************************************
    * SET_BED_ACTION                      This funciton intends to be an API to the interfaces team to perform the following action over a given bed:
    *                                     - block
    *                                     - unblock
    *                                     - clean
    *                                     - contamine
    *                                     - set as being cleaned
    *                                     - clean concluded
	*									  - free
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_BED                    Bed identifier. Mandatory field.
    * @param  I_FLG_ORIGIN_ACTION_UX      Type of action: FLAG defined in flash layer
    * @param  I_DT_BEGIN                  Date in which this action start counting. Can be used on block, dirty, contamined action
    * @param  I_DT_END                    Date in which this action became outdated. Can be used on block, dirty, contamined action
    * @param  I_ID_BMNG_REASON            Reason identifier associated with current action. Mandatory for block bed.
    *                                     It is not shown in application in the other options
    * @param  I_NOTES                     Notes written by professional when creating current registry .
    *                                      Can be used on block, dirty, contamined actions
	* @param  I_ID_EPISODE                     Episode identifier.
	* @param  I_ID_PATIENT                     Patient identifier.
	* @param  I_ID_BMNG_ALLOC_BED                     Bed Management Allocation Bed identifier.
    * @param  O_BED_ALLOCATION            Indicates if bed allocation was succeceful ('Y' - Yes; 'N' - No)
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_ORIGIN_ACTION_UX      {*} 'B'-  BLOCK
    *                                     {*} 'U'-  UNBLOCK
    *                                     {*} 'D'-  DIRTY
    *                                     {*} 'C'-  CONTAMINED
    *                                     {*} 'I'-  CLEANING IN PROCESS
    *                                     {*} 'L'-  CLEANING CONCLUDED
	*                                     {*} 'V'-  FREE
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author                  Sofia Mendes
    * @version                 2.6.1.4
    * @since                   31-Oct-2011
    *******************************************************************************************************************************************/
    FUNCTION set_bed_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_bed             IN bed.id_bed%TYPE,
        i_flg_action         IN VARCHAR2,
        i_dt_begin           IN bmng_action.dt_begin_action%TYPE DEFAULT current_timestamp,
        i_dt_end             IN bmng_action.dt_end_action%TYPE,
        i_notes              IN bmng_action.action_notes%TYPE,
        i_id_bmng_reason     IN bmng_action.id_bmng_reason%TYPE,
        i_dt_creation        IN bmng_allocation_bed.dt_creation%TYPE DEFAULT NULL,
        i_transaction_id     IN VARCHAR2,
		i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_bmng_alloc_bed  IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        o_bed_action_allowed OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

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
    * @author                         Vanessa Barsottelli
    * @version                        2.6.4
    * @since                          10/08/2014
    *
    *******************************************************************************************************************************************/
    FUNCTION create_sch_admission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_bed           IN bed.id_bed%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_discharge     IN VARCHAR2,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_id_inp_episode   OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

END pk_api_inpatient;
/
