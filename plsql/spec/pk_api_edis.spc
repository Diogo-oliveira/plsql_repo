/*-- Last Change Revision: $Rev: 2028469 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_edis IS

    -- Author  : JOSE.SILVA
    -- Created : 17-07-2009 11:48:05
    -- Purpose : API used to access EDIS functionalities

    /**######################################################
      GLOBALS
    ######################################################**/
    g_owner   VARCHAR2(50);
    g_package VARCHAR2(50);
    g_error   VARCHAR2(4000);

    /**######################################################
      CONSTANTS
    ######################################################**/
    g_transfer_inst_cancel CONSTANT transfer_institution.flg_status%TYPE := pk_transfer_institution.g_transfer_inst_cancel;
    g_transfer_inst_req    CONSTANT transfer_institution.flg_status%TYPE := pk_transfer_institution.g_transfer_inst_req;
    g_transfer_inst_transp CONSTANT transfer_institution.flg_status%TYPE := pk_transfer_institution.g_transfer_inst_transp;
    g_transfer_inst_fin    CONSTANT transfer_institution.flg_status%TYPE := pk_transfer_institution.g_transfer_inst_fin;

    /**
    * This function changes the id_patient of the i_old_episode
    * and associated visit to the i_new_patient
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_new_patient new patient id
    * @param i_old_episode id of episode for which the associated patient will change
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error
    */
    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function marges all the information of the two patients into i_patient, including episodes
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp tmeporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_match_all_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Used to cancel episodes through external administrative systems.
    * Allows to cancel EDIS/UBU, Inpatient, Outpatient and Private Practice episodes.
    *
    * @param i_lang                           language id
    * @param i_id_episode                     episode id
    * @param i_prof                           professional id, software and institution
    * @param i_cancel_reason                  motive of cancellation
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Unknown / José Brito (edited)
    * @version                                1.0  
    * @since                                  2008-06-05
    ********************************************************************************************/
    FUNCTION intf_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * INTF_CREATE_TRANSF_INST         This function is responsible for creating an institution transfer request.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with institution transfer
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with institution transfer
    * @param I_ID_INSTITUTION_ORIG    Institution ID from which the patient leaves
    * @param I_ID_INSTITUTION_DEST    Institution ID in which the patient arrives
    * @param I_ID_TRANSP_ENTITY       Transport ID to be used during the transfer
    * @param I_NOTES                  Request notes
    * @param I_ID_DEP_CLIN_SERV       ID_DEP_CLIN_SERV identifier (associate Department and Clinical service ID's in destiny institution 
    * @param I_ID_TRANSFER_OPTION     Transfer reason selected during the request
    * @param O_DT_CREATION            Creation date of current institution transfer request
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/21
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_create_transf_inst
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

    /*******************************************************************************************************************************************
    * INTF_UPD_TRANSF_INST            Updates an institution transfer request
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with institution transfer
    * @param I_DT_CREATION            Record creation date
    * @param I_DT_UPDATE              Begin or end date of the institution transfer
    * @param I_FLG_STATUS             New status of the institution transfer ('C' - Cancel transfer; 'T' - Approve transfer in destiny institution; 'F' - Finalized transfer in destiny institution; 'R' - Request transfer)
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/21
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_upd_transf_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_dt_creation IN transfer_institution.dt_creation_tstz%TYPE,
        i_dt_update   IN transfer_institution.dt_begin_tstz%TYPE,
        i_flg_status  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**
    * API to add a free text History of Present Illness to a episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_notes        Notes   
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO / Filipe Machado
    * @version 2.5.0.8
    * @since   05-Jul-10
    */

    FUNCTION intf_add_hpi_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_notes              IN epis_documentation.notes%TYPE,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * API to set the professional responsible for the a array of episodes
    * 
    *  Record the requests for transfer of responsibility
    *   The transfer of responsibility may be carried out over several episodes.
    *   Is it possible to perform transf. responsibility for one or more professionals.
    *   The same may happen with the specialties, one or more specialties.
    * 
    * @param i_lang                   id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array of professionals who were asked to transfer responsibility   
    * @param i_tot_epis               Array with the total number of episodes for which was requested transfer of responsibility
    * @param i_epis_pat               Array IDs episodes / patients for whom it was requested transfer of responsibility
    * @param i_cs_or_dept             Array of clinical services or departments where the request was made to transfer responsibility        
    * @param i_notes                  Array of Notes
    * @param i_flg_type               Professional Category: S - Social Worker; D - Doctor, N - Nurse
    * @param i_flg_resp               It can take two values: G -  Assume responsibility of the patient in the entry screens
                                                              H -  Hand-Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Request date, if needed.
    * @param i_id_speciality          Destination speciality ID. Must be the same for all professionals in 'i_prof_to'.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.4
    * @since                          2010-08-17
    **********************************************************************************************/
    FUNCTION intf_create_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_to       IN table_varchar,
        i_tot_epis      IN table_number,
        i_epis_pat      IN table_number,
        i_cs_or_dept    IN table_number,
        i_notes         IN table_varchar,
        i_flg_type      IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp      IN VARCHAR2,
        i_flg_profile   IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality IN speciality.id_speciality%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**
    * API to add a free text History of Present Illness to a episode with flg_status and creation date
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_notes        Notes   
    * @param   i_flg_status    
    * @param   i_dt_creation   
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Pedro Maia
    * @version 2.6.0.3
    * @since   24-Jan-11
    */
    FUNCTION intf_add_hpi_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_notes              IN epis_documentation.notes%TYPE,
        i_flg_status         IN epis_documentation.flg_status%TYPE,
        i_dt_creation        IN epis_documentation.dt_creation_tstz%TYPE,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel a Transfer Institution
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, Software and Institution ids
    * @param i_id_episode              Episode ID
    * @param i_dt_creation             Begin Date of transfer 
    * @param i_notes_cancel            Notes of cancelation
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
    FUNCTION intf_cancel_transf_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets the match log information
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, Software and Institution ids
    * @param i_id_prof_match           Professional that executed the match process
    * @param i_dt_match                Date of the match execution 
    * @param i_episode_temp            Temporary episode that was deleted during the episode merge
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Silva
    * @version                         2.6.0.5
    * @since                           17-05-2011
    **********************************************************************************************/
    FUNCTION intf_upd_match_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_match IN professional.id_professional%TYPE,
        i_dt_match      IN match_epis.dt_match_tstz%TYPE,
        i_episode_temp  IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that adds the 'payment made' care stage to the episode
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
    FUNCTION intf_set_care_state_pyt_made
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
      * @version               2.6.2
      * @since                 2014/08/25
      ********************************************************************************************/
    FUNCTION intf_set_care_state_wait_f_pyt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Encapsulates the logic of saving (create or update) a announced arrival patient
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_announced_arrival     Announced arrival id 
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    * <ANNOUNCED_ARRIVAL ID_ANNOUNCED_ARRIVAL="" ID_EPISODE="">
    *   <!-- ID_EPISODE -> Only put this arg to substitute the old call to CREATE_ANN_ARRIVAL_BY_EPI - Creation in pre-hospital screen inside patient area -->
    *   <!-- ID_ANNOUNCED_ARRIVAL -> Only used when editing a existing recorded (Instead of calls to SET_ANN_ARRIVAL and SET_ANN_ARRIVAL_PRE_HOSP) -->
    *   <PATIENT NAME="" GENDER="" DT_BIRTH="" AGE="" ADDRESS="" CITY="" ZIP_CODE="" />
    *   <INCIDENT DT_ACCIDENT="" TYPE_INJURY="" CONDITION="" ZIP_CODE="" LATITUDE="" LONGITUDE="" />
    *   <REFERRAL_ARRIV REFERRED_BY="" SPECIALITY="" CLINICAL_SERVICE="" ED_PHYSICIAN="" DT_EXPECTED_ARRIVAL="" />
    *   <ACT_EMERG_SERV DT_REPORT_MKA="" CPA_CODE="" TRANSPORT_NUMBER="" DT_RIDE_OUT="" DT_ARRIVAL="" />
    *   <TRIAGE FLG_MECH_INJ="" MECH_INJURY_FT="" >
    *     <VITAL_SIGNS>
    *       <VITAL_SIGN ID="" VAL="" UNIT_MEAS="" />
    *     </VITAL_SIGNS>
    *   </TRIAGE>
    *   <TRANSFER_HOSP DT_DRV_AWAY="" />
    *   <RTC FLG_PROT_DEVICE="" FLG_RTA_PAT_TYPE="" RTA_PAT_TYPE_FT="" FLG_IS_DRIV_OWN="" FLG_POLICE_INVOLVED="" POLICE_NUM="" POLICE_STATION="" POLICE_ACCIDENT_NUM="" />
    * </ANNOUNCED_ARRIVAL>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    FUNCTION set_announced_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_params            IN CLOB,
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates a new complaint (used when admitting a new episode) 
    *
    * @param i_lang                 language ID
    * @param i_episode              episode id
    * @param i_prof                 professional object
    * @param i_desc                 complaint description 
    * @param o_id_epis_anamnesis    new complaint ID           
    * @param o_error                Error message
    * 
    * @return                       true or false on success or error
    * 
    * @author                       José Silva
    * @version                      2.6.1
    * @since                        09-May-2012 
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN epis_anamnesis.id_episode%TYPE,
        i_prof                   IN profissional,
        i_desc                   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_epis_anamnesis_tstz IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        o_id_epis_anamnesis      OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get triage board vital signs
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_episode          Episode id
    * @param i_id_triage_board     Triage board id
    * @param i_id_triage_type      Triage type id
    * @param i_pat_gender          Patient gender
    *    
    * @return                      Table with vital sign id's
    *
    * @author                      Alexandre Santos
    * @version                     2.6.3
    * @since                       04-03-2012
    **********************************************************************************************/
    FUNCTION tf_triage_board_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_triage_board IN triage_board.id_triage_board%TYPE,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_pat_gender      IN patient.gender%TYPE DEFAULT NULL
    ) RETURN table_number;

    /********************************************************************************************
    * Get triage discriminator vital signs
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_episode          Episode id
    * @param i_id_triage_discrim   Triage Discriminator id
    * @param i_id_triage_type      Triage type id
    * @param i_pat_gender          Patient gender
    *    
    * @return                      Table with vital sign id's
    *
    * @author                      Alexandre Santos
    * @version                     2.6.3
    * @since                       04-03-2012
    **********************************************************************************************/
    FUNCTION tf_triage_discrim_vital_signs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_triage_discrim IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_triage_type    IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_pat_gender        IN patient.gender%TYPE DEFAULT NULL
    ) RETURN table_number;

    /********************************************************************************************
      * Returns professional responsible for patient
      *
      * @param   i_lang                     Language ID
      * @param   i_prof                     Professional data
      * @param   i_scope                    Scope - 'P'
    * @param   i_id_scope                 id - patient_id
      *
      *                        
      * @return  Episode responsible ID
      * 
      * @author                         Gisela Couto
      * @version                        2.6.4.0
      * @since                          05-May-2014
      **********************************************************************************************/
    FUNCTION get_prof_resp_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_scope    IN VARCHAR2,
        i_id_scope IN patient.id_patient%TYPE
    ) RETURN t_resp_professional_cda;

    /********************************************************************************************
    * Function to add/edit/remove a set of allergies. 
    * @param i_lang                Language
    * @param i_prof                Professional
    * @param i_scope               Scope - 'P' Patient
    * @param i_id_scope            Scope id
    * @param i_id_episode          Episode id
    * @param i_entries_to_add      Allergies to add
    * @param i_entries_to_edit     Allergies to edit
    * @param i_entries_to_remove   Allergies to remove
    * @param i_cdr_call            Flash warning id
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION set_allergies_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_entries_to_add    IN t_tab_allergies_cdas_new,
        i_entries_to_edit   IN t_tab_allergies_cdas_new,
        i_entries_to_remove IN t_tab_allergies_cdas_new,
        i_cdr_call          IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION get_mapping_allergy_conc_cda
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_source_codes         IN table_varchar,
        i_source_coding_scheme IN VARCHAR2,
        i_target_coding_scheme IN VARCHAR2,
        i_id_med_context       IN VARCHAR2 DEFAULT NULL,
        o_target_codes         OUT table_varchar,
        o_target_display_names OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_edis;
/
