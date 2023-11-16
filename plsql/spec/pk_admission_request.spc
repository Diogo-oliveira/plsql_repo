/*-- Last Change Revision: $Rev: 2028439 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_admission_request IS

    -- Public function and procedure declarations

    FUNCTION set_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_diagnosis_adm_req IN pk_edis_types.rec_in_epis_diagnosis,
        i_adm_request       IN adm_request.id_adm_request%TYPE,
        i_episode_inp       IN episode.id_episode%TYPE,
        i_episode_sr        IN episode.id_episode%TYPE,
        i_timestamp         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_cdr_call       IN cdr_call.id_cdr_call%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_indication_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_specs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_indication_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_clin_serv   IN clinical_service.id_clinical_service%TYPE,
        o_indications OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_location_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ward_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ward_list_ds
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv_list_ds
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        i_dep_clin_serv  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_type_list_ds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        i_adm_type IN admission_type.id_admission_type%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bed_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_type_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_mixed_nursing_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nurse_intake_yesno_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_preparation_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_location IN institution.id_institution%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_physicians_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_physicians_list_ds
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_professional  IN professional.id_professional%TYPE,
        i_id_inst_dest  IN department.id_institution%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_nit_location_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_indication_search
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_indication IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_indication_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_adm_indication    IN adm_indication.id_adm_indication%TYPE,
        o_avg_duration      OUT adm_indication.avg_duration%TYPE,
        o_u_lvl_id          OUT wtl_urg_level.id_wtl_urg_level%TYPE,
        o_u_lvl_duration    OUT wtl_urg_level.duration%TYPE,
        o_u_lvl_description OUT pk_translation.t_desc_translation,
        o_dt_begin          OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_location          OUT institution.id_institution%TYPE,
        o_location_desc     OUT pk_translation.t_desc_translation,
        o_ward              OUT department.id_department%TYPE,
        o_ward_desc         OUT pk_translation.t_desc_translation,
        o_dep_clin_serv     OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc    OUT pk_translation.t_desc_translation,
        o_professional      OUT professional.id_professional%TYPE,
        o_prof_desc         OUT pk_translation.t_desc_translation,
        o_adm_type          OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc     OUT pk_translation.t_desc_translation,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_defaults_with_location
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_location       IN institution.id_institution%TYPE,
        o_ward           OUT department.id_department%TYPE,
        o_ward_desc      OUT pk_translation.t_desc_translation,
        o_dep_clin_serv  OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc OUT pk_translation.t_desc_translation,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_desc      OUT pk_translation.t_desc_translation,
        o_adm_type       OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc  OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_defaults_with_ward
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_ward           IN department.id_department%TYPE,
        o_dep_clin_serv  OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_clin_serv_desc OUT pk_translation.t_desc_translation,
        o_professional   OUT professional.id_professional%TYPE,
        o_prof_desc      OUT pk_translation.t_desc_translation,
        o_adm_type       OUT admission_type.id_admission_type%TYPE,
        o_adm_type_desc  OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_defaults_with_dcs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_professional  OUT professional.id_professional%TYPE,
        o_prof_desc     OUT pk_translation.t_desc_translation,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION undelete_admission_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_adm_req IN adm_request.id_adm_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets a new admission request
    *
    * @param i_lang                           language id
    * @param i_prof                           professional tuple
    * @param i_req_episode                    current episode
    * @param i_patient                        current patient
    * @param i_adm_indication                 indication for admission id
    * @param i_diagnosis                      list with diagnoses
    * @param i_diag_statuses                  list with the diagnoses statuses
    * @param i_spec_notes                     list with diagnoses notes
    * @param i_diag_notes                     notes for the diagnoses set
    * @param i_dest_inst                      location requested
    * @param i_adm_type                       admission type
    * @param i_department                     department requested
    * @param i_room_type                      room type
    * @param i_dep_clin_serv                  specialty requested
    * @param i_pref_room                      preferred room
    * @param i_mixed_nursing                  mixed nursing preference
    * @param i_bed_type                       bed type
    * @param i_dest_prof                      professional requested to take the admission
    * @param i_adm_preparation                admission preparation
    * @param i_expect_duration                admission's expected duration
    * @param i_dt_admission                   date of admission (final)
    * @param i_notes                          entered notes
    * @param i_flg_nit                        flag indicating need for a nurse intake
    * @param i_dt_nit_suggested               date suggested for the nurse intake
    * @param i_id_nit_dcs                        dep_clin_serv for nurse intake
    * @param i_timestamp                      current_timestamp
    * @param i_waiting_list                   waiting list id
    * @param i_dt_sched_period_start          date expected for episode beginning
    * @param i_flg_process_event              Y-should be despoleted the process insert or update in the admission_request table
    * @param io_dest_episode                  episode id
    * @param o_visit                          visit id for the new admission episode
    * @param o_flg_ins_upd                    'I' - insert new record; 'U'- update record
    * @param o_error                          error
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Fábio Oliveira
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION set_adm_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_req_episode           IN adm_request.id_upd_episode%TYPE,
        i_patient               IN patient.id_patient%TYPE,
        i_adm_indication        IN adm_request.id_adm_indication%TYPE,
        i_adm_ind_desc          IN adm_request.adm_indication_ft%TYPE,
        i_dest_inst             IN adm_request.id_dest_inst%TYPE,
        i_adm_type              IN adm_request.id_admission_type%TYPE,
        i_department            IN adm_request.id_department%TYPE,
        i_room_type             IN adm_request.id_room_type%TYPE,
        i_dep_clin_serv         IN adm_request.id_dep_clin_serv%TYPE,
        i_pref_room             IN adm_request.id_pref_room%TYPE,
        i_mixed_nursing         IN adm_request.flg_mixed_nursing%TYPE,
        i_bed_type              IN adm_request.id_bed_type%TYPE,
        i_dest_prof             IN adm_request.id_dest_prof%TYPE,
        i_adm_preparation       IN adm_request.id_adm_preparation%TYPE,
        i_expect_duration       IN adm_request.expected_duration%TYPE,
        i_notes                 IN adm_request.notes%TYPE,
        i_flg_nit               IN adm_request.flg_nit%TYPE,
        i_dt_nit_suggested      IN adm_request.dt_nit_suggested%TYPE,
        i_nit_dcs               IN adm_request.id_nit_dcs%TYPE,
        i_timestamp             IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_waiting_list          IN waiting_list.id_waiting_list%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        io_dest_episode         IN OUT episode.id_episode%TYPE,
        i_transaction_id        IN VARCHAR2,
        i_flg_process_event     IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_regimen               IN VARCHAR2 DEFAULT NULL,
        i_beneficiario          IN VARCHAR2 DEFAULT NULL,
        i_precauciones          IN VARCHAR2 DEFAULT NULL,
        i_contactado            IN VARCHAR2 DEFAULT NULL,
        i_order_set             IN VARCHAR2,
        i_id_mrp                IN NUMBER DEFAULT NULL,
        i_id_written_by         IN NUMBER DEFAULT NULL,
        i_ri_prof_spec          IN NUMBER DEFAULT NULL,
        i_flg_compulsory        IN VARCHAR2 DEFAULT NULL,
        i_id_compulsory_reason  IN adm_request.id_compulsory_reason%TYPE DEFAULT NULL,
        i_compulsory_reason     IN adm_request.compulsory_reason%TYPE DEFAULT NULL,
        o_adm_request           OUT adm_request.id_adm_request%TYPE,
        o_visit                 IN OUT visit.id_visit%TYPE,
        o_flg_ins_upd           OUT VARCHAR2,
        o_rows                  OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if an admission indication is valid
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_room                       room ID
    * @param i_adm_indication             admission indication ID
    * @param o_adm_type                   admission type configured for the associated department
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION check_room_adm_indication
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_room           IN room.id_room%TYPE,
        i_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_flg_valid      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if a nurse intake is configured for the selected location
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_location                   location ID
    * @param o_flg_valid                  the admission indication is valid: Y - yes, N - no
    * @param o_nit_dcs                    id_dep_clin_serv for the nurse intake location
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Fábio Oliveira
    * @version                            1.0   
    * @since                              26-06-2009
    **********************************************************************************************/
    FUNCTION check_nit_location
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_location  IN institution.id_institution%TYPE,
        o_flg_valid OUT VARCHAR2,
        o_nit_dcs   OUT sys_config.value%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of rooms for a specific department
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_department                 department ID
    * @param o_room                       room list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN room.id_department%TYPE,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of departments for a specific institution
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_institution                institution ID
    * @param o_department                 department list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              25-04-2009
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_department  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of departments for the given list of institutions
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_ids_inst                   institution IDs
    * @param o_department                 department list
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Telmo Castro
    * @version                            2.6.0.3
    * @since                              07-06-2010
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ids_inst   IN table_number,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_DURATION                    Returns admission request expected duration in format days hours. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_DURATION               Surgery duration in hours
    * 
    * @return                         Returns one string with duration in hours
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_duration
    (
        i_lang      IN language.id_language%TYPE,
        i_durantion IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * CONCATENATE_LIST                Returns string with concatenation of an list of strings in an CURSOR
    * 
    * @param P_CURSOR                 Cursor with all data to join in the same string
    * 
    * @return                         Returns STRING with all elements of P_CURSOR concatenation if success, otherwise returns NULL
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/04
    *******************************************************************************************************************************************/
    FUNCTION concatenate_list(p_cursor IN SYS_REFCURSOR) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_ALL_DIAGNOSIS_STR           Returns all diagnosis of a patient
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_EPISODE             Episode id that is soposed to retunr information
    * 
    * @return                         Returns STRING with all diagnosis if success, otherwise returns NULL
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/04
    *******************************************************************************************************************************************/
    FUNCTION get_all_diagnosis_str
    (
        i_lang       language.id_language%TYPE,
        i_id_episode episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Returns admission Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PATIENT             Patient id that is supposed to return information
    * @param I_FLG_CONTEXT            Grid information aggregated or not ('A' - Aggregated, 'C' - Categorized)
    * @param O_GRID_PLANNED           Cursor that returns available information for current patient which admissions are planned
    * @param O_GRID_EMERGENT          Cursor that returns available information for current patient which admissions are emergent
    * @param O_PROF_EDITABLE          Current professional can edit current request ('Y' - Yes, 'N' - No)
    * @param O_PROF_ACCESS_OK         Current professional have OK button active in main GRID ('Y' - Yes, 'N' - No)
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS" and "user_exception"
    * 
    * @author                         António Neto
    * @version                        2.6.1
    * @since                          19-May-2011
    *******************************************************************************************************************************************/
    FUNCTION get_admission_grid_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_flg_context    IN VARCHAR2,
        o_grid_planned   OUT pk_types.cursor_type,
        o_grid_emergent  OUT pk_types.cursor_type,
        o_prof_editable  OUT VARCHAR2,
        o_prof_access_ok OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_INTAKE_STATUS_STR           Returns nurse intake to the first state collumn in Surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SR_POS_STATUS          SR_POS_STATUS id
    * @param I_ID_WAITING_LIST        Waiting List id
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns the status string information
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/28
    *******************************************************************************************************************************************/
    FUNCTION get_intake_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_adm_request  IN adm_request.id_adm_request%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN VARCHAR2;

    FUNCTION cancel_admission_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_adm_req IN adm_request.id_adm_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_req_diag_ds
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_flg_status  IN adm_req_diagnosis.flg_status%TYPE,
        o_diag        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_req_diag
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        o_diag        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_req_diag_string
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_adm_req_diag_string
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_timestamp   IN VARCHAR2
    ) RETURN VARCHAR2;

    /******************************************************************************
    *  Given an id_episode and id_waiting_list returns admission request data.
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_episode        ID of the episode
    *  @param  i_id_waiting_list   ID of the waiting list request
    *  @param  i_all               Y=all rows  N=only active rows
    *  @param  o_adm_request       Admission request       
    *  @param  o_diag              Diagnosis
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     Alexandre Santos
    *  @version                    2.5.0.2
    *  @since                      2009-04-29
    *
    ******************************************************************************/
    FUNCTION get_admission_request_ds
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_waiting_list      IN waiting_list.id_waiting_list%TYPE,
        i_all                  IN VARCHAR2 DEFAULT 'Y',
        o_dt_admission         OUT adm_request.dt_admission%TYPE,
        o_id_dep_clin_serv     OUT NUMBER,
        o_desc_dep_clin_serv   OUT VARCHAR2,
        o_id_prof_spec_adm     OUT NUMBER,
        o_desc_prof_spec_adm   OUT VARCHAR2,
        o_id_adm_phys          OUT NUMBER,
        o_name_adm_phys        OUT VARCHAR2,
        o_id_mrp               OUT NUMBER,
        o_name_mrp             OUT VARCHAR2,
        o_id_written_by        OUT NUMBER,
        o_name_written_by      OUT VARCHAR2,
        o_id_compulsory        OUT VARCHAR2,
        o_desc_compulsory      OUT VARCHAR2,
        o_id_compulsory_opt    OUT VARCHAR2,
        o_desc_compulsory_opt  OUT VARCHAR2,
        o_id_adm_indication    OUT NUMBER,
        o_desc_adm_indication  OUT VARCHAR2,
        o_id_admission_type    OUT NUMBER,
        o_desc_adm_type        OUT VARCHAR2,
        o_expected_duration    OUT NUMBER,
        o_id_adm_preparation   OUT NUMBER,
        o_desc_adm_preparation OUT VARCHAR2,
        o_id_dest_inst         OUT NUMBER,
        o_desc_dest_inst       OUT VARCHAR2,
        o_id_department        OUT NUMBER,
        o_desc_depart          OUT VARCHAR2,
        o_id_room_type         OUT NUMBER,
        o_desc_room_type       OUT VARCHAR2,
        o_flg_mixed_nursing    OUT VARCHAR2,
        o_id_bed_type          OUT NUMBER,
        o_desc_bed_type        OUT VARCHAR2,
        o_id_pref_room         OUT NUMBER,
        o_dep_pref_room        OUT NUMBER,
        o_desc_pref_room       OUT VARCHAR2,
        o_flg_nit              OUT VARCHAR2,
        o_flg_nit_desc         OUT VARCHAR2,
        o_dt_nit_suggested     OUT VARCHAR2,
        o_id_nit_dcs           OUT NUMBER,
        o_nit_dt_sugg_send     OUT VARCHAR2,
        o_nit_dt_sugg_char     OUT VARCHAR2,
        o_nit_location         OUT VARCHAR2,
        o_notes                OUT VARCHAR2,
        o_diag                 OUT pk_types.cursor_type,
        o_id_regimen           OUT VARCHAR2,
        o_desc_regimen         OUT VARCHAR2,
        o_id_beneficiario      OUT VARCHAR2,
        o_desc_beneficiario    OUT VARCHAR2,
        o_id_precauciones      OUT VARCHAR2,
        o_desc_precauciones    OUT VARCHAR2,
        o_id_contactado        OUT VARCHAR2,
        o_desc_contactado      OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_admission_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_all             IN VARCHAR2 DEFAULT 'Y',
        o_adm_request     OUT pk_types.cursor_type,
        o_diag            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_request_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_wtl         IN waiting_list.id_waiting_list%TYPE,
        o_title       OUT pk_types.cursor_type,
        o_description OUT pk_types.cursor_type,
        o_info        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_indication_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_waiting_list IN waiting_list.id_waiting_list%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Given an indication for admission ID returns the admission description
    *
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_lang                preferred language ID
    * @param    i_id_adm_indication   indication for admission ID
    *
    * @return   varchar2              admission description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_adm_indication_desc
    (
        i_prof              IN profissional,
        i_lang              IN language.id_language%TYPE,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_search_professionals_nl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_text       IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_prof_templ OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professionals_nl
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_templ IN profile_template.id_profile_template%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_templ_nl
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_adm_req_alert
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        i_wtl   IN waiting_list.id_waiting_list%TYPE,
        i_profs IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************************************************
    *
    * Returns the type and description of the provided bed
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_bed               ID of the bed.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_bed_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_bed     IN bed.id_bed%TYPE,
        o_desc_bt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bed_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_bed  IN bed.id_bed%TYPE
    ) RETURN VARCHAR2;

    /***************************************************************************************************************
    *
    * Returns the description of the provided room
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_room               ID of the room.
    * @param      o_error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   21-07-2009
    *
    ****************************************************************************************************/
    FUNCTION get_room_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_room    IN room.id_room%TYPE,
        o_desc_rt OUT pk_translation.t_desc_translation,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * GET_ADMISSION_REQUESTS          Returns admission Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_REQ_STATUS             Admission Request Status: S-scheduled, N-not scheduled, C-cancelled
    * @param I_FLG_EHR                Episode flg_ehr (N-registered episodes; S-scheduled episodes [not registered])
    * @param I_PATIENT                Patient id that is soposed to retunr information
    * @param i_id_epis_documentation  Barthel Index Evaluation ID
    * @param i_id_wtlist              filter for id_waiting list
    * @param O_GRID                   Cursor that returns available information for current patient id
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/02/22
    *******************************************************************************************************************************************/
    FUNCTION get_admission_requests
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_req_status            IN wtl_epis.flg_status%TYPE,
        i_flg_ehr               IN episode.flg_ehr%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        i_id_wtlist             IN waiting_list.id_waiting_list%TYPE DEFAULT NULL,
        o_adm_requests          OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_NURSE_INTAKE_ICONS          Returns all the icons that can appear in the nurse intake column of the admission grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DATA                   Icons
    * @param O_ERROR                  Error stuf    
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/03/23
    *******************************************************************************************************************************************/
    FUNCTION get_nurse_intake_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_REQ_STATUS_ICONS            Returns all the icons that can appear in the admission/surgery
    *                                 status column of the admission/surgery grid. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DATA                   Icons
    * @param O_ERROR                  Error stuf    
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0
    * @since                          2010/03/23
    *******************************************************************************************************************************************/
    FUNCTION get_req_status_icons
    (
        i_lang  IN sys_domain.id_language%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_AR_EPISODES                 Returns admission Request episodes for a specific id patient. 
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_PATIENT                Patient id that is soposed to retunr information
    * @param I_START_DT               Start date to be consider to filter data
    * @param I_END_DT                 End date to be consider to filter data
    * 
    * @return                         Returns a table function of Ongoing or Future Events of Admission Request
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          02-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION get_ar_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_tbl_ar_episodes;

    /**
    * Get Future Events task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient id
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               JORGE SILVA
    * @version               2.6.2
    * @since               2012/09/03
    */
    FUNCTION get_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_adm_request IN adm_request.id_adm_request%TYPE,
        i_desc_type   IN VARCHAR2
    ) RETURN CLOB;
    /**
    * Get future events desc
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               future events description
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_fe_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    /**
    * get_can_admit
    *
    * @param i_lang              language identifier
    * @param i_prof              logged professional structure
    * @param i_id_episode        episode  identifier
    *
    * @return               get_can_admit
    *
    * @author              Paulo Teixeira
    * @version              2.6
    * @since                2014/10/02
    */
    FUNCTION get_can_admit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION handle_unav
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_current_section   IN ds_component.internal_name%TYPE,
        i_unav_num          IN NUMBER DEFAULT 1,
        io_tab_sections     IN OUT t_table_ds_sections,
        io_tab_def_events   IN OUT t_table_ds_def_events,
        io_tab_events       IN OUT t_table_ds_events,
        io_tab_items_values IN OUT t_table_ds_items_values,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_need_surgery              IN VARCHAR2 DEFAULT 'N',
        i_waiting_list              IN waiting_list.id_waiting_list%TYPE,
        i_component_name            IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type            IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_adm_indication            IN adm_indication.id_adm_indication%TYPE,
        i_inst_location             IN institution.id_institution%TYPE,
        i_id_department             IN department.id_department%TYPE,
        i_dep_clin_serv             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dep_clin_serv_surg        IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_lvl_urg               IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_id_surg_proc_princ        IN intervention.id_intervention%TYPE,
        i_unav_val                  IN NUMBER,
        i_unav_begin                IN VARCHAR2,
        i_unav_duration             IN NUMBER,
        i_unav_duration_mea         IN unit_measure.id_unit_measure%TYPE,
        i_unav_end                  IN VARCHAR2,
        i_ask_hosp                  IN VARCHAR2,
        i_order_set                 IN VARCHAR2,
        i_anesth_field              IN VARCHAR2,
        i_anesth_value              IN VARCHAR2,
        i_adm_phy                   IN professional.id_professional%TYPE,
        o_section                   OUT pk_types.cursor_type,
        o_def_events                OUT pk_types.cursor_type,
        o_events                    OUT pk_types.cursor_type,
        o_items_values              OUT pk_types.cursor_type,
        o_data_val                  OUT CLOB,
        o_data_diag                 OUT pk_types.cursor_type,
        o_data_proc                 OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_supplies           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_duration_unit_measure_ds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hours        IN adm_request.expected_duration%TYPE,
        i_date         IN adm_request.dt_admission%TYPE,
        o_value        OUT NUMBER,
        o_unit_measure OUT unit_measure.id_unit_measure%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_task_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN adm_request.id_adm_request%TYPE,
        o_task_instr   OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION copy_adm_request_wf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_adm_request IN adm_request.id_adm_request%TYPE,
        i_id_episode     IN adm_request.id_dest_episode%TYPE DEFAULT NULL,
        i_dt_request     IN adm_request.dt_admission%TYPE DEFAULT NULL,
        i_sur_need       IN VARCHAR2,
        o_id_adm_request OUT adm_request.id_adm_request%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_predefined_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reason_admission_ft RETURN NUMBER;

    FUNCTION get_adm_req_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_adm_req_instructions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    FUNCTION get_adm_req_action_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_action       IN co_sign.id_action%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_adm_req_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_adm_request  IN adm_request.id_adm_request%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_duration_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN adm_request.expected_duration%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_sr_episode_by_inp(i_waiting_list waiting_list.id_waiting_list%TYPE) RETURN episode.id_episode%TYPE;

    FUNCTION inactivate_inpatient_admission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    g_flg_context_aggregated_a  CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_context_categorized_c CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_insert CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_update CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_wlt_status_c CONSTANT VARCHAR2(1) := 'C';

    g_prof_temp_edis_phy CONSTANT NUMBER := 483;
    g_prof_temp_inp_phy  CONSTANT NUMBER := 857;
    g_prof_temp_out_phy  CONSTANT NUMBER := 951;

    g_adm_req_alert CONSTANT sys_alert.id_sys_alert%TYPE := 64;

    g_ri_reason_admission CONSTANT VARCHAR2(20 CHAR) := 'RI_REASON_ADMISSION';
    g_ri_diagnoses        CONSTANT VARCHAR2(20 CHAR) := 'RI_DIAGNOSES';
    g_ri_loc_int          CONSTANT VARCHAR2(20 CHAR) := 'RI_LOC_INT';
    g_ri_serv_adm         CONSTANT VARCHAR2(20 CHAR) := 'RI_SERV_ADM';
    g_ri_esp_int          CONSTANT VARCHAR2(20 CHAR) := 'RI_ESP_INT';
    g_ri_phys_adm         CONSTANT VARCHAR2(20 CHAR) := 'RI_PHYS_ADM';
    g_ri_mrp              CONSTANT VARCHAR2(20 CHAR) := 'RI_MRP';
    g_ri_written_by       CONSTANT VARCHAR2(20 CHAR) := 'RI_WRITTEN_BY';
    g_rs_type_int         CONSTANT VARCHAR2(20 CHAR) := 'RS_TYPE_INT';
    g_ri_durantion        CONSTANT VARCHAR2(20 CHAR) := 'RI_DURANTION';
    g_ri_prepar           CONSTANT VARCHAR2(20 CHAR) := 'RI_PREPAR';
    g_ri_type_room        CONSTANT VARCHAR2(20 CHAR) := 'RI_TYPE_ROOM';
    g_ri_regimen          CONSTANT VARCHAR2(20 CHAR) := 'RI_REGIMEN';
    g_ri_beneficiario     CONSTANT VARCHAR2(20 CHAR) := 'RI_BENEFICIARIO';
    g_ri_precauciones     CONSTANT VARCHAR2(20 CHAR) := 'RI_PRECAUCIONES';
    g_ri_contactado       CONSTANT VARCHAR2(20 CHAR) := 'RI_CONTACTADO';
    g_ri_mix_room         CONSTANT VARCHAR2(20 CHAR) := 'RI_MIX_ROOM';
    g_rs_type_bed         CONSTANT VARCHAR2(20 CHAR) := 'RS_TYPE_BED';
    g_ri_pref_room        CONSTANT VARCHAR2(20 CHAR) := 'RI_PREF_ROOM';
    g_ri_need_nurse_cons  CONSTANT VARCHAR2(20 CHAR) := 'RI_NEED_NURSE_CONS';
    g_ri_loc_nurse_cons   CONSTANT VARCHAR2(20 CHAR) := 'RI_LOC_NURSE_CONS';
    g_ri_date_nurse_cons  CONSTANT VARCHAR2(20 CHAR) := 'RI_DATE_NURSE_CONS';
    g_ri_notes            CONSTANT VARCHAR2(20 CHAR) := 'RI_NOTES';
    g_rs_sur_need         CONSTANT VARCHAR2(20 CHAR) := 'RS_SUR_NEED';
    g_rs_loc_surgery      CONSTANT VARCHAR2(20 CHAR) := 'RS_LOC_SURGERY';
    g_rs_spec_surgery     CONSTANT VARCHAR2(20 CHAR) := 'RS_SPEC_SURGERY';
    g_rs_global_anesth    CONSTANT VARCHAR2(20 CHAR) := 'RS_GLOBAL_ANESTH';
    g_rs_local_anesth     CONSTANT VARCHAR2(20 CHAR) := 'RS_LOCAL_ANESTH';
    g_rs_pref_surg        CONSTANT VARCHAR2(20 CHAR) := 'RS_PREF_SURG';
    g_rs_proc_surg        CONSTANT VARCHAR2(20 CHAR) := 'RS_PROC_SURG';
    g_rs_prev_duration    CONSTANT VARCHAR2(20 CHAR) := 'RS_PREV_DURATION';
    g_rs_uci              CONSTANT VARCHAR2(20 CHAR) := 'RS_UCI';
    g_rs_ext_spec         CONSTANT VARCHAR2(20 CHAR) := 'RS_EXT_SPEC';
    g_rs_cont_danger      CONSTANT VARCHAR2(20 CHAR) := 'RS_CONT_DANGER';
    g_rs_pref_time        CONSTANT VARCHAR2(20 CHAR) := 'RS_PREF_TIME';
    g_rs_mot_pref_time    CONSTANT VARCHAR2(20 CHAR) := 'RS_MOT_PREF_TIME';
    g_rs_notes            CONSTANT VARCHAR2(20 CHAR) := 'RS_NOTES';
    g_rip_begin_per       CONSTANT VARCHAR2(20 CHAR) := 'RIP_BEGIN_PER';
    g_rip_duration        CONSTANT VARCHAR2(20 CHAR) := 'RIP_DURATION';
    g_rip_end_per         CONSTANT VARCHAR2(20 CHAR) := 'RIP_END_PER';
    g_rsp_lvl_urg         CONSTANT VARCHAR2(20 CHAR) := 'RSP_LVL_URG';
    g_rsp_begin_sched     CONSTANT VARCHAR2(20 CHAR) := 'RSP_BEGIN_SCHED';
    g_rsp_end_sched       CONSTANT VARCHAR2(20 CHAR) := 'RSP_END_SCHED';
    g_rsp_time_min        CONSTANT VARCHAR2(20 CHAR) := 'RSP_TIME_MIN';
    g_rsp_sugg_dt_surg    CONSTANT VARCHAR2(20 CHAR) := 'RSP_SUGG_DT_SURG';
    g_rsp_sugg_dt_int     CONSTANT VARCHAR2(20 CHAR) := 'RSP_SUGG_DT_INT';
    g_rv_request          CONSTANT VARCHAR2(20 CHAR) := 'RV_REQUEST';
    g_rv_dt_verif         CONSTANT VARCHAR2(20 CHAR) := 'RV_DT_VERIF';
    g_rv_notes_req        CONSTANT VARCHAR2(20 CHAR) := 'RV_NOTES_REQ';
    g_rv_decision         CONSTANT VARCHAR2(20 CHAR) := 'RV_DECISION';
    g_rv_valid            CONSTANT VARCHAR2(20 CHAR) := 'RV_VALID';
    g_rv_notes_decis      CONSTANT VARCHAR2(20 CHAR) := 'RV_NOTES_DECIS';

    g_request_inpatient CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_INPATIENT';
    g_request_surgery   CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_SURGERY';
    g_request_ind_per   CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_IND_PER';
    g_request_sched_per CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_SCHED_PER';
    g_request_ver_op    CONSTANT VARCHAR2(20 CHAR) := 'REQUEST_VER_OP';

    g_type_sr_proc   CONSTANT VARCHAR2(20 CHAR) := 'TYPE_SR_PROC';
    g_type_diagnosis CONSTANT VARCHAR2(20 CHAR) := 'TYPE_DIAGNOSIS';

    g_dyn_unit_meas_type CONSTANT NUMBER := 1807;
    g_unit_measure_hours CONSTANT NUMBER := 1041;
    g_unit_measure_days  CONSTANT NUMBER := 1039;

    g_flg_status_pd CONSTANT VARCHAR2(2 CHAR) := 'PD';

    -- EMR-2497 
    g_disc_fe_notes_st     CONSTANT VARCHAR2(35 CHAR) := 'DISCHARGE_SUR_FUTURE_EVENT_NOTES';
    g_disc_adm_fe_notes_st CONSTANT VARCHAR2(35 CHAR) := 'DISCHARGE_ADM_FUTURE_EVENT_NOTES';
    g_rs_notes_p           CONSTANT VARCHAR2(20 CHAR) := 'RS_NOTES_P';

    g_reason_admission_ft          CONSTANT NUMBER(24) := -1;
    g_reas_adm_event_target_active CONSTANT ds_event_target.id_ds_event_target%TYPE := 1912;

END pk_admission_request;
/
