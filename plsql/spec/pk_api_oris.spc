/*-- Last Change Revision: $Rev: 2028477 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_oris IS
    /********************************************************************************************
    * Creates an episode
    *
    * @param i_lang              Language ID
    * @param i_id_patient        Patient ID
    * @param i_prof              Professional, institution and software IDs
    * @param i_id_visit          Visit ID (may be NULL)
    * @param i_dt_creation       Episode creation date
    * @param i_dt_begin          Episode begin date
    * @param i_id_episode_ext    External episode value
    * @param i_flg_ehr           Episode type: N-Normal, S-Planning, E-EHR
    * @param i_id_dep_clin_serv  Clinic service ID
    * @param i_flg_migration     Migration flag: M-migrated A-normal
    * @param i_id_room           Room to schedule
    * @param i_id_external_sys   External episode identifier
    * @param o_episode_new       Created episode ID
    * @param o_error             Error message
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Sérgio Dias
    * @since                     2010/08/20
    * @Notes                     ALERT-118077
    ********************************************************************************************/
    FUNCTION create_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN OUT patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_creation      IN episode.dt_creation%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_migration    IN episode.flg_migration%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        o_episode_new      OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Import professionals in the surgery team
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional, institution and software IDs
    * @param i_id_episode       Associated episode ID
    * @param i_tbl_prof         Professional IDs table 
    * @param i_tbl_catg         Professional sub-categories table
    * @param i_tbl_status       Record status table -     'N' - new record
                                                          'C' - changed record
                                                          'D' - delete record
    * @param i_dt_reg           Team creation time
    
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-118232
    ********************************************************************************************/
    FUNCTION set_sr_prof_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_tbl_prof   IN table_number,
        i_tbl_catg   IN table_number,
        i_tbl_status IN table_varchar,
        i_dt_reg     IN sr_prof_team_det.dt_reg_tstz%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert surgery times
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional, institution and software IDs
    * @param i_id_episode               Associated episode ID
    * @param i_id_sr_surgery_time       Surgery time type ID 
    * @param i_dt_surgery_time_det      Surgery time value
    * @param i_dt_reg                   Record creation date
    *
    * @param o_id_sr_epis_interv_desc   Created record ID
    * @param o_error                    Error message
    *
    * @return                           TRUE/FALSE
    *
    * @author                           Sérgio Dias
    * @since                            2010/08/20
    * @Notes                            ALERT-118237
    ********************************************************************************************/
    FUNCTION set_surgery_times
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_surgery_time     IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_dt_surgery_time_det    IN sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE,
        i_dt_reg                 IN sr_surgery_time_det.dt_reg_tstz %TYPE,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert intervention descriptions
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional, institution and software IDs
    * @param i_id_episode                Associated episode ID
    * @param i_id_sr_epis_interv         Intervention ID 
    * @param i_desc_intervention         Intervention description
    * @param i_dt_interv_desc            Intervention description insertion date
    *
    * @param o_id_sr_epis_interv_desc    Created record ID
    * @param o_error                     Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-118237
    ********************************************************************************************/
    FUNCTION set_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_epis_interv      IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_desc_intervention      IN sr_epis_interv_desc.desc_interv%TYPE,
        i_dt_interv_desc         IN sr_epis_interv_desc.dt_interv_desc_tstz%TYPE,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Imports an intervention  
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_dt_interv_start        Intervention start date
    * @param i_dt_interv_end          Intervention end date
    * @param i_id_episode             Episode ID
    * @param i_id_sr_intervention     Intervention ID
    * @param i_flg_type               Intervention type
    * @param i_flg_status             Intervention status
    * @param i_dt_req                 Request date
    * @param i_name_interv            Intervention name (not coded)
    * @param i_laterality             Laterality
    * @param i_id_diagnosis           Diagnosis ID
    * @param i_notes                  Intervention notes
    * @param i_flg_surg_request       Indicates if this surgical procedure was requested as part of the surgery/admission requests (Yes) or as part of proposed surgery (No)
    * @param i_diag_desc_sp           Desc diagnosis from the diagnosis of the surgical procedures
    
    * @param o_id_sr_epis_interv      Created record ID
    * @param o_error                  Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-116342
         ********************************************************************************************/
    FUNCTION set_epis_surg_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_dt_interv_start    IN sr_epis_interv.dt_interv_start_tstz%TYPE,
        i_dt_interv_end      IN sr_epis_interv.dt_interv_end_tstz%TYPE,
        i_id_episode         IN sr_epis_interv.id_episode%TYPE,
        i_id_sr_intervention IN sr_epis_interv.id_sr_intervention%TYPE,
        i_flg_type           IN sr_epis_interv.flg_type%TYPE,
        i_flg_status         IN sr_epis_interv.flg_status%TYPE,
        i_dt_req             IN sr_epis_interv.dt_req_tstz%TYPE,
        i_name_interv        IN sr_epis_interv.name_interv%TYPE,
        i_laterality         IN sr_epis_interv.laterality%TYPE,
        i_id_diagnosis       IN epis_diagnosis.id_diagnosis%TYPE,
        i_notes              IN sr_epis_interv.notes%TYPE,
        i_flg_surg_request   IN sr_epis_interv.flg_surg_request%TYPE,
        i_diag_desc_sp       IN epis_diagnosis.desc_epis_diagnosis%TYPE, --desc diagnosis from surgical procedure
        o_id_sr_epis_interv  OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgery time for a specific visit.
    *
    * @param i_lang                 Id language
    * @param i_prof                 Professional, software and institution ids
    * @param i_id_visit             Id visit
    * @param i_dt_begin             Start date for surgery time
    * @param i_dt_end               End date for surgery time
    * 
    * @param o_surgery_time_def     Cursor with all type of surgery times.
    * @param o_surgery_times        Cursor with surgery times by visit.
    * @param o_error                Error message
    *
    * @return                       TRUE/FALSE
    *
    * @author                       Jorge Canossa
    * @since                        2010/10/24
    ********************************************************************************************/

    FUNCTION get_surgery_times_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set surgery times
    *
    * @param i_lang                 ID language
    * @param i_sr_surgery_time      ID Surgery time type
    * @param i_id_episode           ID episode
    * @param i_dt_surgery_time      Surgery time/date
    * @param i_prof                 Professional, institution and software IDs
    * @param i_test                 Test flag:  Y - validate
    *                                           N - execute 
    * @param i_dt_reg               Record date
    * 
    * @param o_flg_show             Show message: Y/N
    * @param o_msg_result           Message to show
    * @param o_title                Message title
    * @param o_button               Buttons to show: NC - Yes/No button
    *                                            C - Read button 
    * @param o_error                Error message
    *
    * @return                       TRUE/FALSE
    *
    * @author                       Jorge Canossa
    * @since                        2010/09/01
    ********************************************************************************************/

    FUNCTION set_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_dt_surgery_time IN VARCHAR2,
        i_prof            IN profissional,
        i_test            IN VARCHAR2,
        i_transaction_id  IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_title           OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_flg_refresh     OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates episode data
    *
    * @param i_id_episode           Episode ID
    * @param i_lang                 Language ID
    * @param i_prof                 Professional, institution and software IDs
    * @param i_dt_creation          Episode creation date
    * @param i_dt_begin             Episode begin date
    * @param i_flg_ehr              Episode type: N-Normal, S-Planning, E-EHR
    * @param i_id_dep_clin_serv     Clinic service ID
    * @param o_error                Error message
    *
    * @return                       TRUE/FALSE
    *
    * @author                       Sérgio Dias
    * @since                        2010/08/20
    * @Notes                        ALERT-116342
    ********************************************************************************************/
    FUNCTION update_episode
    (
        i_id_episode       IN episode.id_episode%TYPE,
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dt_creation      IN episode.dt_creation%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Imports an intervention  
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_id_sr_epis_interv      Intervention ID
    * @param i_dt_interv_start        Intervention start date
    * @param i_dt_interv_end          Intervention end date
    * @param i_id_sr_intervention     Intervention code ID
    * @param i_flg_type               Intervention type
    * @param i_flg_status             Intervention status
    * @param i_dt_req                 Request date
    * @param i_name_interv            Intervention name (not coded)
    * @param i_laterality             Laterality
    * @param i_id_diagnosis           Diagnosis ID
    * @param i_notes                  Intervention notes
    * @param i_flg_surg_request       Indicates if this surgical procedure was requested as part of the surgery/admission requests (Yes) or as part of proposed surgery (No)
    * @param i_diag_desc_sp           Desc diagnosis from the diagnosis of the surgical procedures
    
    * @param o_error                  Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/13
    * @Notes                    ALERT-
    ********************************************************************************************/
    FUNCTION update_epis_surg_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_dt_interv_start    IN sr_epis_interv.dt_interv_start_tstz%TYPE,
        i_dt_interv_end      IN sr_epis_interv.dt_interv_end_tstz%TYPE,
        i_id_sr_intervention IN sr_epis_interv.id_sr_intervention%TYPE,
        i_flg_type           IN sr_epis_interv.flg_type%TYPE,
        i_flg_status         IN sr_epis_interv.flg_status%TYPE,
        i_dt_req             IN sr_epis_interv.dt_req_tstz%TYPE,
        i_name_interv        IN sr_epis_interv.name_interv%TYPE,
        i_laterality         IN sr_epis_interv.laterality%TYPE,
        i_id_diagnosis       IN epis_diagnosis.id_diagnosis%TYPE,
        i_notes              IN sr_epis_interv.notes%TYPE,
        i_flg_surg_request   IN sr_epis_interv.flg_surg_request%TYPE,
        i_diag_desc_sp       IN epis_diagnosis.desc_epis_diagnosis%TYPE, --desc diagnosis from surgical procedure
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update intervention descriptions
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional, institution and software IDs
    * @param i_id_sr_epis_interv_desc    Intervention description ID
    * @param i_desc_intervention         Intervention description
    * @param i_dt_interv_desc            Intervention description date
    * @param i_id_episode                Episode ID
    * @param i_id_sr_epis_interv         Intervention ID
    *
    * @param o_error                     Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/13
    * @Notes                    ALERT-118237
    ********************************************************************************************/
    FUNCTION update_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv_desc IN sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        i_desc_intervention      IN sr_epis_interv_desc.desc_interv%TYPE,
        i_dt_interv_desc         IN sr_epis_interv_desc.dt_interv_desc_tstz%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_epis_interv      IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgery_times
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_patient       Patient Id
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   António Neto
    * @version                  2.6.1
    * @since                    2011-04-08
    *
    *********************************************************************************************/
    FUNCTION get_summ_interv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_interv     OUT NOCOPY pk_types.cursor_type,
        o_labels     OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if some occurrence of a surgery with given surgical procedures was initiated (surgery start date)
    * after the given date.
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    * @param i_id_sr_intervention    Surgical Procedure Id
    * @param i_start_date            Lower date to be considered
    * @param o_flg_started_procedure Y-the surgical procedure was started after the given date. N-otherwise
    * @param o_id_epis_sr_interv     List with the epis_sr_interv
    * @param o_error                 Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sofia Mendes
    * @version                  2.6.1
    * @since                    19-Apr-2011
    *
    *********************************************************************************************/
    FUNCTION check_surg_procedure
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patiet             IN patient.id_patient%TYPE,
        i_id_sr_intervention    IN intervention.id_intervention%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_started_procedure OUT VARCHAR2,
        o_id_epis_sr_interv     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * List of coded surgical procedures for an institution       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    * @param o_surg_proc_list         List of coded surgical procedures 
    * @param o_error                  Error message 
    *           
    * @return                         TRUE/FALSE                                                             
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surgical_procedures
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_surg_proc_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * return coded surgical procedure description       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_sr_intervention     Intervention ID                       
    *
    * @return                         Surgical procedure description                                                           
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surg_procedure_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Cancel the surgical procedures and the supplies were chosen by the professional.
    * For the other supplies, will be deleted the association of the surgical procedure.     
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode ID
    * @param i_cancel_reason          Cancel reason surgical procedure
    * @param i_notes                  Cancel notes
    *
    * @param o_error                  Error
    *                                                                         
    * @author                         Rita Lopes                            
    * @since                          2012/07/27                                 
    **************************************************************************/

    FUNCTION set_cancel_epis_surg_proc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_cancel_reason IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_surgery_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        o_episodes OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get current state of surgical positioning for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_positionings_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of admission to the operating room for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_sr_receive_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of proposed surgery (surgical procedure) for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_proposed_sr_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    *  Get current state of Pre-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_pre_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    *  Get current state of Intra-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_intra_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of post-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_post_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of surgical reserves for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_reserves_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get current state of intervention record for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_interv_rec_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_oris_episode_by_inpatient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_oris_episode OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_error              VARCHAR2(4000);
    g_default_impact_msg VARCHAR2(200);

END pk_api_oris;
/
