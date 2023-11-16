/*-- Last Change Revision: $Rev: 2029019 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_transfer_institution IS

    TYPE t_transfer_inst IS TABLE OF transfer_institution%ROWTYPE;

    /********************************************************************************************
    * Creates an institution transfer request (internal function)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_institution_orig    Institution ID from which the patient leaves
    * @param i_id_institution_dest    Institution ID in which the patient arrives
    * @param i_id_transp_entity       Transport ID to be used during the transfer
    * @param i_notes                  Request notes
    * @param i_id_dep_clin_serv       Clinical service ID           
    * @param i_id_transfer_option     Transfer reason selected during the request
    * @param o_dt_creation            Creation date of current institution transfer request
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    *
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          28/09/2009
    * @dependencies                   INTERFACES TEAM (PK_API_EDIS)
    **********************************************************************************************/
    FUNCTION create_transfer_inst_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_dt_creation         OUT transfer_institution.dt_creation_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_institution_orig    Institution ID from which the patient leaves
    * @param i_id_institution_dest    Institution ID in which the patient arrives
    * @param i_id_transp_entity       Transport ID to be used during the transfer
    * @param i_notes                  Request notes
    * @param i_id_dep_clin_serv       Clinical service ID            
    * @param i_id_transfer_option     Transfer reason selected during the request    
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    **********************************************************************************************/
    FUNCTION create_transfer_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_notes_cancel           Cancellation notes
    * @param i_id_cancel_reason       Cancel reason ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          21/04/2008
    **********************************************************************************************/

    FUNCTION cancel_transfer_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN transfer_institution.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates an institution transfer request
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_dt_update              Begin or end date of the institution transfer
    * @param i_flg_status             New status of the institution transfer
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION update_transfer_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN transfer_institution.id_episode%TYPE,
        i_dt_creation IN VARCHAR2,
        i_dt_update   IN VARCHAR2,
        i_flg_status  IN transfer_institution.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all the requested transfers for a given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param o_transfer_inst          Requested transfers for a given episode
    * @param o_flg_create             Y-It is possible to create a new institution transfer request (the episode is active)
    *                                 N-otherwise
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_epis_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN transfer_institution.id_episode%TYPE,
        o_transfer_inst OUT pk_types.cursor_type,
        o_flg_create    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the detail of a given institution transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date    
    * @param o_transfer_inst          Requested transfers for a given episode
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_epis_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN transfer_institution.id_episode%TYPE,
        i_dt_creation  IN VARCHAR2,
        o_transfer_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of available transports to be used in the transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_transp_ent             Transport list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transp_ent_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_transp_ent OUT pk_types.cursor_type,
        o_name       OUT professional.nick_name%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the list of available transports to be used in the transfer
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_dep_clin_serv          Association ID between clinical service and department
    * @param o_transfer_opt           Transfer option list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_transfer_option_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_transfer_opt  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the date to be used on the patients grid
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    *                        
    * @return                         timestamp to show on the grid arrival column
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_grid_task_arrival
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * Gets the date to be used on the patients grid
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    *                        
    * @return                         timestamp to show on the grid departure column
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          22/04/2008
    **********************************************************************************************/

    FUNCTION get_grid_task_departure
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the institution list in order to choose the transfer destination
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_institution            Institution list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          23/04/2008
    **********************************************************************************************/

    FUNCTION get_institution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_institution OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets the clinical service list available in a particular department
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_department             Department ID
    * @param o_clin_serv              Clinical service list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          28/04/2008
    **********************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        o_clin_serv  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Gets the department list available in a particular institution
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_institution            Institution ID
    * @param o_department             Department list
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          29/04/2008
    **********************************************************************************************/
    FUNCTION get_department_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        o_department  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --    
    /********************************************************************************************
    * Migration of institution transfer requests from the temporary episode to the definitive
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Definitive episode ID
    * @param i_episode_temp           Temporary episode ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          24/04/2008
    **********************************************************************************************/

    FUNCTION set_match_transfer_inst
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if there is pending institution transfers for a given episode
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Exists pending transfers: 1 - Yes; 0 - No
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          08/05/2008
    **********************************************************************************************/

    FUNCTION check_epis_transfer(i_episode IN transfer_institution.id_episode%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * Checks if there is pending institution transfers for a given episode
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Exists pending transfers: (Y)Yes; (N)No
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          08/05/2008
    **********************************************************************************************/

    FUNCTION check_transfer_access
    (
        i_episode IN transfer_institution.id_episode%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the header label in case of an institution transfer
    *
    * @param i_id_episode             Episode ID
    *                        
    * @return                         Header label
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          18/07/2008
    **********************************************************************************************/

    FUNCTION get_inst_transfer_message
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Cancels an institution transfer request (internal function)
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Episode ID
    * @param i_dt_creation            Record creation date
    * @param i_notes_cancel           Cancellation notes
    * @param i_id_cancel_reason       Cancel reason ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.0.5.3.4   
    * @since                          07/05/2011
    **********************************************************************************************/

    FUNCTION cancel_transfer_inst_int
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN transfer_institution.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get transfer list for the current institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    *
    * @param o_in_transfer_list       Transfer list for the current institution 
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                 
    * @since                          2011/03/21                                 
    **************************************************************************/
    FUNCTION get_in_transfer_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_in_transfer_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************
    * get transfer list when the current institution is an origin for another institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    *
    * @param o_out_transfer_list      Transfer list for current institution is an origin for another institution
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/21                                
    **************************************************************************/
    FUNCTION get_out_transfer_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_out_transfer_list OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************
    * get transfer list when the current institution is an origin for another institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    *
    * @parma o_in_transfer_list       Transfer list when the institution destination is the current institution
    * @param o_out_transfer_list      Transfer list for current institution is an origin for another institution
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/21                                
    **************************************************************************/

    FUNCTION get_transfer_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_out_list OUT pk_types.cursor_type,
        o_in_list  OUT pk_types.cursor_type,
        o_label1   OUT VARCHAR2,
        o_label2   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * CHECK_PERMISSIONS_DEPART_DATE            Check if the logged professional has permissions 
    *                                          to register the departure date of the active 
    *                                          transfer institution record of the current episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_institution_origin   Origin institution
    * @param i_cfg_departure_date_set  Sys_config value with the professional categories that can
    *                                  register the departure date
    * @param i_flg_status              Tranfer institution record status
    * @param i_id_prof_cat             Professional category Id
    * @param i_departure_date          Departure date
    *
    * @return                          Y - the professional can register the departure date
    *                                  N - Otherwise
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_permissions_depart_date
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution_origin  IN transfer_institution.id_institution_origin%TYPE,
        i_cfg_departure_date_set IN sys_config.value%TYPE,
        i_flg_status             IN transfer_institution.flg_status%TYPE,
        i_id_prof_cat            IN category.id_category%TYPE,
        i_departure_date         IN transfer_institution.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * CHECK_PERMISSIONS_DEPART_DATE            Check if the logged professional has permissions 
    *                                          to register the arrival date of the active 
    *                                          transfer institution record of the current episode
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_institution_origin   Origin institution
    * @param i_cfg_departure_date_set  Sys_config value with the professional categories that can
    *                                  register the departure date
    * @param i_flg_status              Tranfer institution record status
    * @param i_id_prof_cat             Professional category Id
    * @param i_arrival_date            Arrival date
    *
    * @return                          Y - the professional can register the departure date
    *                                  N - Otherwise
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           24-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_permissions_arrival_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution_dest  IN transfer_institution.id_institution_dest%TYPE,
        i_cfg_arrival_date_set IN sys_config.value%TYPE,
        i_flg_status           IN transfer_institution.flg_status%TYPE,
        i_id_prof_cat          IN category.id_category%TYPE,
        i_arrival_date         IN transfer_institution.dt_end_tstz%TYPE
    ) RETURN VARCHAR2;

    /***************************************************************************
    * build string icon for institution transfer state
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_dt_creation_tstz       Creation date               
    *
    * OBS: the id_episode and dt_creation_tstz columns are the PK of transfer_institution
    * so that is necessary theses two parameters to calcule the string icon
    * @return string icon   
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.5.1                                  
    * @since                          2011/03/24                               
    **************************************************************************/

    FUNCTION get_inst_transfer_icon_string
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN transfer_institution.id_episode%TYPE,
        i_dt_creation_tstz IN transfer_institution.dt_creation_tstz%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * check_create_transfer            Check if it is possible to create an institution tranfer 
    *                                  in the current episode
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_id_episode              Episode institution
    * @param o_flg_create              Y-It is possible to create an institution transfer
    *                                  N-otherwise
    *
    * @return                          TRUE-success; FALSE-error
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_create_transfer
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_flg_create OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * CHECK_EPISODES_FOR_VISIT         Check the number of active Episodes in the same visit 
    *
    * @param i_id_episode              Episode ID to all others
    *
    * @return                          More than one episode for visit (Y/N)
    *
    * @author                          António Neto
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION check_episodes_for_visit(i_id_episode IN episode.id_episode%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * GET_TRANSFER_EPIS_DET                Get the transfer service detail and history data.
    *
    * @param   i_lang                      Language associated to the professional executing the request
    * @param   i_prof                      Professional Identification
    * @param   i_id_episode                Episode ID
    * @param   i_dt_creation               Creation Date of Transfer
    * @param   i_flg_screen                Flag of Detail type (D-detail; H-history)
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.4
    * @since                               28-Mar-2011
    **********************************************************************************************/
    FUNCTION get_transfer_epis_det
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_dt_creation IN VARCHAR2,
        i_flg_screen  IN VARCHAR2,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /***************************************************************************
    * Returns the status to be used when getting the icon from sys_domain.
    * Checks if the transfer is being done to the prof institution or 
    * other institution in order to determine which status to return.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_flg_status             Transfer institution status
    * @param i_institution_dest       Destiny institution
    * @param i_id_episode             Episode ID
    * @param i_dt_creation_tstz       Creation date               
    *
    * OBS: the id_episode and dt_creation_tstz columns are the PK of transfer_institution
    * so that is necessary theses two parameters to get the transfer institution record.
    * To be used when it is not given the i_flg_status, i_institution_origin and i_institution_dest
    *
    * @return status of the sys_domain
    *                                                                         
    * @author                         Sofia Mendes                         
    * @version                        2.5.1                                  
    * @since                          24-Mar-2011                              
    **************************************************************************/
    FUNCTION get_domain_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN transfer_institution.flg_status%TYPE,
        i_institution_dest IN transfer_institution.id_institution_origin%TYPE,
        i_id_episode       IN transfer_institution.id_episode%TYPE DEFAULT NULL,
        i_dt_creation_tstz IN transfer_institution.dt_creation_tstz%TYPE DEFAULT NULL
    ) RETURN transfer_institution.flg_status%TYPE;

    /********************************************************************************************
    * Return the most recent transfer institution record of the given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0   
    * @since                          04/10/2011
    **********************************************************************************************/
    FUNCTION tf_most_recent_transfer
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN transfer_institution.id_episode%TYPE
    ) RETURN t_transfer_inst
        PIPELINED;

    /********************************************************************************************
    * Returns only the most recent transfer institution records
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        1.0   
    * @since                          04/10/2011
    **********************************************************************************************/
    FUNCTION tf_most_recent_transfer
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_transfer_inst
        PIPELINED;

    g_error VARCHAR2(4000);
    g_found BOOLEAN;
    g_transfer_inst_cancel CONSTANT transfer_institution.flg_status%TYPE := 'C';
    g_transfer_inst_req    CONSTANT transfer_institution.flg_status%TYPE := 'R';
    g_transfer_inst_transp CONSTANT transfer_institution.flg_status%TYPE := 'T';
    g_transfer_inst_fin    CONSTANT transfer_institution.flg_status%TYPE := 'F';
    --status used in the icons sys_domain to distint a transference to outside
    g_transfer_inst_transp_out CONSTANT VARCHAR2(2) := 'TT';
    --status used in the icons sys_domain to distint a transference to outside
    g_g_transfer_inst_fin_out CONSTANT VARCHAR2(2) := 'FF';

    g_mov_req    CONSTANT movement.flg_status%TYPE := 'R';
    g_mov_transp CONSTANT movement.flg_status%TYPE := 'T';
    g_mov_pend   CONSTANT movement.flg_status%TYPE := 'P';

    g_dateformat CONSTANT VARCHAR2(50) := 'yyyymmddhh24miss TZR';
    g_room_pref  CONSTANT prof_room.flg_pref%TYPE := 'Y';

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_transp_transf CONSTANT transp_entity.flg_type%TYPE := 'T';
    g_transp_all    CONSTANT transp_entity.flg_type%TYPE := 'A';
    g_transp_depart CONSTANT transp_entity.flg_transp%TYPE := 'D';

    g_color_green CONSTANT VARCHAR2(1) := 'G';
    g_color_red   CONSTANT VARCHAR2(1) := 'R';
    g_no_color    CONSTANT VARCHAR2(1) := 'X';

    g_epis_cancel   CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_status_cancel CONSTANT VARCHAR2(1) := 'C';

    g_flg_available CONSTANT VARCHAR2(1) := 'Y';

    g_clin_rec_act CONSTANT clin_record.flg_status%TYPE := 'A';

    g_inst_grp_flg_rel_trf CONSTANT institution_group.flg_relation%TYPE := 'TRF';

    --sys_configs
    g_sc_departure_dt_set CONSTANT sys_config.id_sys_config%TYPE := 'TRANSF_INST_DEPARTURE_DATE_SET';
    g_sc_arrival_dt_set   CONSTANT sys_config.id_sys_config%TYPE := 'TRANSF_INST_ARRIVAL_DATE_SET';
    --sys_domains
    g_sd_flg_status     CONSTANT sys_domain.code_domain%TYPE := 'TRANSFER_INSTITUTION.FLG_STATUS';
    g_sd_flg_status_aux CONSTANT sys_domain.code_domain%TYPE := 'TRANSFER_INSTITUTION.FLG_STATUS_DET';

    --Detail Screen (AN 28-Mar-2011 [ALERT-28312])
    g_detail_d              CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_history_h             CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_transfer_det_active_a CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- type of content to be returned in the detail/history screens
    g_title_t       CONSTANT VARCHAR2(1) := 'T';
    g_content_c     CONSTANT VARCHAR2(1) := 'C';
    g_signature_s   CONSTANT VARCHAR2(1) := 'S';
    g_new_content_n CONSTANT VARCHAR2(1) := 'N';
    g_line_l        CONSTANT VARCHAR2(1) := 'L';

    g_admin_category category.flg_type%TYPE := 'A';
    g_other_category category.flg_type%TYPE := 'D';

END pk_transfer_institution;
/
