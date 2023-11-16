/*-- Last Change Revision: $Rev: 2028480 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_clindoc_in IS

    -- Author  : Luís Maia
    -- Created : 28-07-2011 19:00:00
    -- Purpose : Handle PFH (from clinical documentation BU) calls to medication

    -- Structure used in labour and delivery
    TYPE t_delivery_rec_drug_val IS RECORD(
        VALUE              VARCHAR2(200),
        icon               VARCHAR2(200),
        id_drug_presc_plan NUMBER(24, 0),
        reg                VARCHAR2(1 CHAR),
        flg_reg            VARCHAR2(1 CHAR),
        time_value         VARCHAR2(200),
        dt_begin           TIMESTAMP WITH LOCAL TIME ZONE,
        dt_end             TIMESTAMP WITH LOCAL TIME ZONE,
        flg_take_type      VARCHAR2(200 CHAR),
        dt_read            VARCHAR2(200),
        hour_vs            NUMBER,
        id_drug            VARCHAR2(200 CHAR),
        dt_reg             TIMESTAMP WITH LOCAL TIME ZONE);

    /*********************************************************************************************
    * Get decription of given medication
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_PRESC                 id of prescribed drug
    *
    * @RETURN                             string of drug prescribed or null if no_data_found, or error msg
    * @author                             Luís Maia
    * @version                            2.6.0.1.2
    * @since                              28-JUL-2011
    *
    **********************************************************************************************/
    FUNCTION get_med_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN pk_rt_core_all.t_big_num
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the episode medication list. Used to get the most recent records when registering
    * a new AMPLE/SAMPLE/CIAMPEDS assessment.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_type                   Return list of ID's or labels
    *
    * @value i_type                   {*} 'ID' Get list of ID's {*} 'LABEL' Get list of labels
    * @value i_separator              {*} ',' ID separator {*} ',, ' Label separator
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN VARCHAR2
    ) RETURN table_varchar;

    /********************************************************************************************
    * Gets the ABCDE assessment medication text
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_record_id              Medication record ID
    * @param i_id_episode             Episode ID
    * @param i_flg_type               Type of prescription
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_record_id  IN NUMBER,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN epis_abcde_meth_param.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if "No Home medication" or "Cannot name medication" was chosen
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_episode                Episode ID
    * @param i_record_id    Medication list ID
    * @param i_flg_type               Type of record: P - medication list, PO - medication det
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_record_id IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_flg_type  IN epis_abcde_meth_param.flg_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if "No Home medication" or "Cannot name medication" was chosen or if medication
    * is active
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_pat_medication_list    Reported medication ID
    * @param i_pat_medication_det     Medication det ID
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION check_abcde_medication_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_medication_list IN pk_rt_med_pfh.r_presc.id_presc%TYPE,
        i_pat_medication_det  IN pk_rt_med_pfh.r_presc.id_presc%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the episode medication ID list. 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_patient             Patient ID
    *                        
    * @return                         Medication IDs
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medication_id_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Get medication list used in the abcde multichoice
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_medication_list    List of PAT_MEDICATION_LIST IDs
    * @param i_id_episode             the episode ID
    * @param o_medication             Medication info to multichoice use
    * @param o_options                Medication options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_abcde_medic_multichoice
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat_medication_list IN table_number,
        i_id_episode          IN episode.id_episode%TYPE,
        o_medication          OUT pk_types.cursor_type,
        o_options             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the ID's of the options available in the "Home Medication" screen
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param o_id_global_info          Option ID's
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           30-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_abcde_editor_lookup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_id_global_info OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the medication data (reported medication and "home medication" options)
    * for the trauma detail screen.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_epis_abcde_meth      ABCDE assessment ID
    * @param o_medication              Medication data
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           04-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_trauma_hist_medic_by_id
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_medication         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all drug prescriptions included in a given period or a specific date
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_visit                 visit ID   
    * @param i_num_hours             number of hours that will be represented in the partogram graph
    * @param i_dt_birth              devilery start date 
    * @param i_flg_type              Output type: G - graph, T - table
    *        
    * @return o_drug_val             drug prescriptions    
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_val
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_visit     IN visit.id_visit%TYPE,
        i_num_hours IN table_number,
        i_dt_birth  IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        i_flg_type  IN VARCHAR2,
        o_drug_val  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all drugs prescribed during labor
    *
    * @param i_lang                  language ID
    * @param i_prof                  professional, software and institution ids
    * @param i_visit                 visit ID       
    * @param i_dt_birth              devilery start date     
    *        
    * @return o_drug                 drug prescriptions
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         06-05-2008   
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_param
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_drug     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all drugs prescribed during labor and the associated prescription date
    *
    * @param i_lang                  language ID
    * @param i_prof                  professional, software and institution ids
    * @param i_visit                 visit ID       
    * @param i_dt_birth              delivery start date   
    *
    * @return o_time                 drug prescriptions   
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         14-07-2008 
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_time     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all drugs prescribed during labor
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs
    * @param i_visit                 visit ID     
    * @param i_dt_birth              delivery start date     
    * 
    * @return o_drugs                all drug prescriptions during labor
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN epis_doc_delivery.dt_delivery_tstz%TYPE,
        o_drugs    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the detail of an administered medication available in the partogram graph/table
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_reg                administered medication ID 
    *        
    * @return o_val_det              drug detail    
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         06-05-2008
    * @dependents                    PK_WOMAN_HEALTH
    ********************************************************************************************/
    FUNCTION get_delivery_drug_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_reg  IN drug_presc_plan.id_drug_presc_plan%TYPE,
        o_val_det OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the maximum time limit in the partogram graph (drug records)
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID
    * @param i_visit                      visit ID
    * @param i_dt_birth                   delivery begin date
    * @param o_dt_drug                    drug record dates
    * @param o_duration                   duration of continuous medication 
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              05-06-2009
    * @dependents                         PK_DELIVERY
    **********************************************************************************************/
    FUNCTION get_delivery_max_drug
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_drug  OUT table_number,
        o_duration OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the drug time records to be placed in the partogram table
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution IDs     
    * @param i_visit                 visit ID     
    * @param i_dt_birth              delivery start date
    *
    * @return                        drug administration/prescription dates
    *
    * @author                        José Silva
    * @version                       1.0    
    * @since                         01-09-2007
    * @dependents                    PK_DELIVERY
    ********************************************************************************************/
    FUNCTION get_delivery_drug_time_t
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_dt_birth IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN table_timestamp_tz;

    /********************************************************************************************
    * Gets all prescriptions associated with the patient treatment
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_episode               episode ID   
    *        
    * @return                        true or false on success or error
    *
    * @author                        José Silva
    * @version                       2.6.1.1    
    * @since                         24-05-2011
    * @dependents                    PK_HAND_OFF
    ********************************************************************************************/
    FUNCTION get_hand_off_treatment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_hand_off_treatment;

    /********************************************************************************************
    * Gets the description of a prescribed medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_drug_presc_det            Drug prescription detail ID
    *
    * @return  Drug information (episode and description)
    *
    * @author       José Silva
    * @version      v2.6.1.1
    * @since        06-06-2011
    * @dependents   PK_SUSPENDED_TASKS
    ********************************************************************************************/
    FUNCTION get_drug_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_drug_presc_det IN episode.id_episode%TYPE
    ) RETURN tf_hand_off_treatment;

    /**********************************************************************************************
    * Prescriptions list grouped by status
    *
    * @param i_lang                   the id language
    * @param i_epis                   episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_title                  Status titles
    * @param o_drug                   Drugs list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/07/18  
    * @dependents                     PK_HAND_OFF
    **********************************************************************************************/
    FUNCTION get_hand_off_presc_status
    (
        i_lang  IN language.id_language%TYPE,
        i_epis  IN episode.id_episode%TYPE,
        i_prof  IN profissional,
        o_title OUT table_clob,
        o_drug  OUT table_clob,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if an episode has prescriptions (used in the informative grid)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode ID
    *
    * @return  number of episode prescriptions
    *
    * @author       José Silva
    * @version      v2.6.1.1
    * @since        06-06-2011
    * @dependents   PK_INFORMATION
    ********************************************************************************************/
    FUNCTION check_inf_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the list of medication for a given episode or patient (only the ones administered)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_visit                     Visit id
    * @param   i_episode                   Episode id
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_epis_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_visit   IN visit.id_visit%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific outside medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_prescription_pharm        Outside medication ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_medication
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_prescription_pharm IN prescription_pharm.id_prescription_pharm%TYPE,
        o_med                OUT pk_api_complications.api_comp_cur,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific prescribed medication
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_drug_presc_det            Drug prescription ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_drug_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        o_med            OUT pk_api_complications.api_comp_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific drug classification
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_pharm_group               Pharm group ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_pharm_group
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pharm_group IN mi_med_pharm_group.group_id%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_med         OUT pk_api_complications.api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific drug (ID and description)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_drug                      Drug ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_drug    IN mi_med.id_drug%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific outside drug classification
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_pharm_group               Pharm group ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_med_group
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pharm_group IN me_pharm_group.group_id%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_med         OUT pk_api_complications.api_comp_cur,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a specific outside drug (ID and description)
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_emb_id                    Drug ID
    * @param   i_episode                   Episode ID
    * @param   o_med                       Medication list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Silva
    * @version      v2.6
    * @since        30-12-2009
    * @dependents   PK_API_COMPLICATIONS
    ********************************************************************************************/
    FUNCTION get_compl_out_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_emb_id  IN me_med.emb_id%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_med     OUT pk_api_complications.api_comp_cur,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the drug prescription information to be placed in the todo list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis                   Episode ID
    * @param   i_flg_type                  Type of todo: (P)ending or (D)epending tasks
    * @param   i_flg_count                 Task counter: Yes or No
    * @param   i_visit_desc                Visit description to be used in the grid
    * @param   i_dt_server                 Serialized server date to be used in the grid
    * @param   o_task_count                Task counter
    * @param   o_tasks                     Task list
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Brito
    * @version      2.4.3
    * @since        2008-Sep-03
    * @dependents   PK_TODO_LIST
    ********************************************************************************************/
    FUNCTION get_todo_drug_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis    IN episode.id_episode%TYPE,
        i_flg_type   IN todo_task.flg_type%TYPE,
        i_flg_count  IN VARCHAR2,
        i_visit_desc IN VARCHAR2,
        i_dt_server  IN VARCHAR2,
        o_task_count OUT NUMBER,
        o_tasks      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the drug information related to co-sign, to be placed in the todo list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode ID
    * @param   i_drug_presc_det            Drug prescription ID
    * @param   i_flg_type                  Type of information: (D)escription or (T)ime
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author       José Brito
    * @version      2.4.3
    * @since        2008-Sep-03
    * @dependents   PK_TODO_LIST
    ********************************************************************************************/
    FUNCTION get_todo_drug_cosign
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_flg_type       IN VARCHAR2
    ) RETURN tf_med_tasks;

    /**********************************************************************************************
    * Returns episode's drug prescriptions information like it will be shown on Tracking View.
    *
    * @param i_lang                        language's id
    * @param i_prof                        professional's related data (ID, Institution and Software)
    * @param i_episode                     episode's id from which the data will be gathered
    * @param i_sysdate                     current system date
    * @param i_external_tr                 external tracking view (Y) Yes (N) No
    *
    * @return           drug information to be used in the grid
    *
    * @author           João Eiras
    * @version          2.4.4
    * @dependents       PK_TRACKING_VIEW
    *
    * -- ATTENTION: new medication statuses need to be included as parameters here
    **********************************************************************************************/
    FUNCTION get_tracking_view_drug
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_sysdate     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_external_tr IN VARCHAR2
    ) RETURN pk_edis_types.table_line;

    /**********************************************************************************************
    * Checks if there is any medication tasks to be performed by the Respiratory Therapist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    *
    * @return                         Medication list
    *                        
    * @author                         José Silva
    * @version                        2.6.1.1 
    * @since                          2011/05/29
    * @dependents                     PK_RT_TECH
    **********************************************************************************************/
    FUNCTION get_rt_epis_drug_count
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks;

    /**********************************************************************************************
    * Gets the delayed medication to be performed by the Respiratory Therapist
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    *
    * @return                         medication list. Format: SHORTCUT|DATA|TIPO|COR|TEXTO/NOME_ICON[;...]
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/10/19
    *
    * UPDATED: ALERT-19390
    * @author                         Telmo Castro
    * @date                           09-03-2009
    * @version                        2.5
    * @dependents                     PK_RT_TECH
    **********************************************************************************************/
    FUNCTION get_rt_epis_drug_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks;

    /********************************************************************************************
    * Gets all prescriptions
    *
    * @param i_lang                  language ID       
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_episode            episode ID
    *        
    * @return                        true or false on success or error
    *
    * @author                        Filipe Silva
    * @version                       2.6.1.2    
    * @since                         23-Aug-2011
    * @dependents                    PK_EDIS_SUMMARY; PK_PROTOCOLS
    ********************************************************************************************/
    FUNCTION get_presc_treatment
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN tf_medication_pfh;

    /**
    * Check prescriptions for a given product.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_product   product identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_presc_by_product
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_id_product IN table_varchar,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check prescriptions for a given ingredient group.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_ing_group    ingredient group identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ingred_grp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_ing_group  IN VARCHAR2,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check prescriptions for a given ingredient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_ingredient ingredient identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ingred
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_time          IN TIMESTAMP,
        i_id_ingredient IN VARCHAR2,
        o_presc         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check prescriptions for a given DDI.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_ddi       ddi identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_ddi
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_time       IN TIMESTAMP,
        i_id_ddi     IN VARCHAR2,
        o_presc      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check prescriptions for a given drug group.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   patient identifier
    * @param i_time         minimum register date
    * @param i_id_pharm_theraps drug group identifier
    * @param o_presc        prescription identifiers list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/01
    */
    FUNCTION get_cdr_by_pharm_theraps
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_time             IN TIMESTAMP,
        i_id_pharm_theraps IN VARCHAR2,
        o_presc            OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the administration list for hidrics screen (Intake and output) for IV fluids
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_VISIT      The id visit
    * @param  I_ID_UNIT       The unit measure
    * @param  I_DT_BEGIN      The begin date for task execution
    * @param  I_DT_END        The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-02
    *
    ********************************************************************************************/
    FUNCTION get_list_fluid_balance
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_visit   IN visit.id_visit%TYPE,
        i_id_unit    IN unit_measure.id_unit_measure%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc   IN table_number DEFAULT NULL,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN pk_rt_types.g_t_fluid_balance
        PIPELINED;

    /********************************************************************************************
    * This function returns information about prescription administrations
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_VISIT      The id visit
    * @param  I_DT_BEGIN      The begin date for task execution
    * @param  I_DT_END        The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-02
    *
    ********************************************************************************************/
    FUNCTION get_list_administrations
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_visit IN visit.id_visit%TYPE,
        i_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN pk_rt_types.g_t_administrations
        PIPELINED;

    /********************************************************************************************
    * This function returns information about related medication
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  i_id_patient    Patient identifier
    * @param  i_id_episode    Episode identifier
    * @param  i_dt_begin      Begin date
    * @param  i_dt_end        End date
    *
    * @author  Sofia Mendes
    * @since   05-Set-2011
    *
    ********************************************************************************************/
    FUNCTION get_list_presc_previous
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN episode.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN pk_rt_types.g_tbl_presc_previous
        PIPELINED;

    /********************************************************************************************
    * This functions returns 'Y' if the prescription is in an active state, otherwise 'N'
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  i_id_presc      Presc ID    
    *
    * @author  Sofia Mendes
    * @since   11-Oct-2011
    *
    ********************************************************************************************/
    FUNCTION is_active_presc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_presc IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function merges information from old patient or episode to new one
    *
    * @param    I_LANG              The language ID           
    * @param    I_PROF              The professional information        
    * @param    I_OLD_ID_PATIENT    The old patient ID, if I_NEW_ID_PATIENT is filled this field is mandatory
    * @param    I_NEW_ID_PATIENT    The new patient ID, if I_OLD_ID_PATIENT is filled this field is mandatory
    * @param    I_OLD_ID_EPISODE    The old episode ID, if I_NEW_ID_EPISODE is filled this field is mandatory         
    * @param    I_NEW_ID_EPISODE    The new episode ID, if I_OLD_ID_EPISODE is filled this field is mandatory             
    * @param    O_ERROR          
    *
    * @author  Bruno Rego
    * @version 2.6.1.1
    * @since   2011-07-27 
    *
    ********************************************************************************************/
    FUNCTION match_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_old_id_patient IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_new_id_patient IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_old_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        i_new_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get ingredient description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ingred    ingredient identifier
    *
    * @return               ingredient description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    FUNCTION get_ingredients_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ingred IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get ingredient group description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_ing_group ingredient group identifier
    *
    * @return               ingredient group description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    FUNCTION get_ing_group_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_ing_group IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Unfolds a prescription into CDS concepts.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_presc     prescription identifier
    * @param o_products     products with hierarchy
    * @param o_id_products_no_hierarch        Products without hierarchy
    * @param o_ddis         interaction groups
    * @param o_ingreds      ingredients
    * @param o_ing_groups   ingredient groups
    * @param o_pharm_theraps pharmacotherapeutic groups
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/09
    */
    PROCEDURE get_cdr_concepts_by_presc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_presc                IN VARCHAR2,
        o_products                OUT table_table_varchar,
        o_id_products_no_hierarch OUT table_varchar,
        o_ddis                    OUT table_table_varchar,
        o_ingreds                 OUT table_table_varchar,
        o_ing_groups              OUT table_table_varchar,
        o_pharm_theraps           OUT table_table_varchar,
        o_error                   OUT t_error_out
    );

    /********************************************************************************************
    * procedure gives the cdr concepts for a given product
    *
    * @param    I_LANG                                       IN        id language
    * @param    I_PROF                                       IN        profissional
    * @param    i_id_presc                                   IN        list of Prescription id,
    * @param    o_id_products                                IN        Products
    * @param    o_id_ddis                                    IN        ddi
    * @param    o_id_ingredients                             IN        ingredients 
    * @param    o_id_ing_groups                              IN        ingredients groups 
    
    * @param    O_ERROR                    
    *
    * @author   Sofia Mendes
    * @version   2.6.4
    * @since    02-06-2014
    *
    ********************************************************************************************/
    PROCEDURE get_cdr_concepts_by_prod
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_product_sup IN table_varchar,
        o_products       OUT table_table_varchar,
        o_ddis           OUT table_table_varchar,
        o_ingreds        OUT table_table_varchar,
        o_ing_groups     OUT table_table_varchar,
        o_pharm_theraps  OUT table_table_varchar,
        o_error          OUT t_error_out
    );

    /**
    * Get a summary of exterior prescriptions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_ext_med_summ_p
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_epis      IN table_number,
        o_presc_ext OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a summary of local prescriptions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_local_med_summ_p
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_epis    IN table_number,
        o_presc   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a summary of pharmacy requests.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_pharm_req_summ_p
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_epis      IN table_number,
        o_pharm_req OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a summary of pharmacy requests.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_epis         episode identifiers list
    * @param o_presc_ext    cursor
    * @param o_error        error
    *
    * @return               false, if errors occur, or true, otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/14
    */
    FUNCTION get_prev_med_summ_s
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_epis       IN table_number,
        o_medication OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_allergy         pat_allergy identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_pa
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN presc_pat_problem.id_pat_allergy%TYPE,
        i_flg_status     IN presc_pat_problem.flg_status %TYPE,
        i_flg_type       IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_history_diagnosis         pat_history_diagnosis identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_phd
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_pat_history_diagnosis IN presc_pat_problem.id_pat_history_diagnosis%TYPE,
        i_flg_status               IN presc_pat_problem.flg_status %TYPE,
        i_flg_type                 IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Gets the medication counter from presc_pat_problem, used on pk_problems
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat_problem         pat_problem identifier
    * @param i_flg_status             presc_pat_problem flag status
    * @param i_flg_type               presc_pat_problem flag type
    *                        
    * @return                         number
    * 
    * @author                         Paulo Teixeira
    * @version                        1.0
    * @since                          2011/05/23
    * @dependents                     PK_PROBLEMS
    **********************************************************************************************/
    FUNCTION get_medication_counter_pp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN presc_pat_problem.id_pat_problem%TYPE,
        i_flg_status     IN presc_pat_problem.flg_status %TYPE,
        i_flg_type       IN presc_pat_problem.flg_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Returns the sum of admistration list for IV fluids
    *
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  i_id_epis_hidrics       The id epis_hidrics
    * @param  I_DT_BEGIN              The begin date for task execution
    * @param  I_DT_END                The end date for task execution
    * @param  I_ID_PRESC              Prescription ID
    *
    * @author  Filipe Silva
    * @since   2011-09-19
    *
    ********************************************************************************************/
    FUNCTION get_fluid_balance_med_tot
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        i_dt_begin        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc        IN pk_rt_core_all.t_big_num DEFAULT NULL
    ) RETURN NUMBER;

    /********************************************************************************************
    * Get patient's medication
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat_medication_list    List of PAT_MEDICATION_LIST IDs
    * @param i_id_episode             the episode ID
    * @param o_pat_medication_list    Medication info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.1.2
    * @since                          2011-09-20
    * @dependents                     PK_ABCDE_METHODOLOGY
    **********************************************************************************************/
    FUNCTION get_previous_medication
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure updates prec episode, saving the previous in the presc.id_prev_episode
    * only to be used for GRID_TASK processing
    *
    * @param  i_lang                     The language ID
    * @param  i_prof                     The professional array
    * @param  i_id_episode               Previous episode
    * @param  i_new_episode              New episode
    * @param  o_error                    The error object
    *
    * @author                            Pedro Teixeira
    * @since                             24/05/2011
    ********************************************************************************************/
    PROCEDURE set_presc_new_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        i_new_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE,
        o_error       OUT t_error_out
    );

    /*********************************************************************************************
    * This function will update the Grid Task for a certain episode
    *
    * @param i_lang               The ID of the user language
    * @param i_prof               The profissional array
    * @param i_id_episode         Episode Id
    *
    *
    * @author  Pedro Teixeira 
    * @since   2011/08/19
    **********************************************************************************************/
    PROCEDURE process_epis_grid_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN pk_rt_med_pfh.r_presc.id_epis_create%TYPE
    );

    /********************************************************************************************
    * Returns dates takes
    *
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_EPIS_HIDRICS       The id epis_hidrics
    * @param  I_DT_BEGIN              The begin date for task execution
    * @param  I_DT_END                The end date for task execution
    *
    * @author  Filipe Silva
    * @since   2011-09-21
    *
    ********************************************************************************************/
    FUNCTION get_fluid_balance_med_dates
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE
    ) RETURN table_timestamp_tz;

    /********************************************************************************************
    * Get's medication patient
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param o_pat_medication_list    Medication info 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author  Filipe Silva
    * @since   2011-09-22
    *
    ********************************************************************************************/
    FUNCTION get_prev_medication_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-07
    *
    ********************************************************************************************/
    FUNCTION call_cancel_rep_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN pk_rt_core_all.t_big_num,
        i_id_reason   IN pk_rt_core_all.t_big_num,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT 'Y',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function descontinue or cancel the prescription depending on the current state
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PRESC      The prescription Id
    *
    * @author  Pedro Teixeira
    * @since   2011-09-07
    *
    ********************************************************************************************/
    FUNCTION call_cancel_rep_medication
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_presc    IN table_number,
        i_id_reason   IN pk_rt_core_all.t_big_num,
        i_reason      IN VARCHAR2,
        i_notes       IN VARCHAR2,
        i_flg_confirm IN VARCHAR2 DEFAULT 'Y',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get's active medication patient
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_filter_date            Filter date
    * @param o_pat_medication_list    Medication info 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    *
    * @author  Filipe Silva
    * @since   2011-09-23
    *
    ********************************************************************************************/
    FUNCTION get_current_medication
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_filter_date         IN INTERVAL DAY TO SECOND,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET_DRUG_FLUIDS_NUM
    *
    * @param i_id_episode          episode identifier
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @version                     2.6.1.1
    * @since                       2011/04/21
    * @dependents                  PK_DISCHARGE.CHECK_DISCHARGE
    **********************************************************************************************/
    FUNCTION get_drug_fluids_num
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER;

    /*******************************************************************************************************************************************
    * Get all current active information related with the medication for the patitent                                                          *
    *                                                                                                                                          *
    * @ param i_lang             Id do idioma                                                                                                  *
    * @ param i_prof             professional array                                                                                            *
    * @ param i_id_patient       patient OD                                                                                                    *
    * @ param o_active_med                                                                                                                     *
    *                                                                                                                                          *
    * @ param o_error                                                                                                                          *
    *                                                                                                                                          *
    * @return                     TRUE if success and FALSE otherwise                                                                          *
    *                                                                                                                                          *
    * @author                      Filipe Silva                                                                                            *
    * @version                     1.0                                                                                                         *
    * @since                       2011/09/24                                                                                                  *
    *@notes                        a espera de uma api da "nova" farmacia ALERT-113674
    *******************************************************************************************************************************************/
    FUNCTION get_active_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prescription   IN table_number,
        i_prescription_type IN table_varchar,
        o_active_med        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get medication reconciliation info
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_patient              Patient ID
    * @param i_id_episode              Episode ID
    * @param o_info                    Medication reconciliation data
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           29-Sep-2011
    *
    **********************************************************************************************/
    FUNCTION get_reconciliation_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get information to the confirmation screen
    *
    * @author  Pedro Teixeira
    * @since   2011-09-23
    ********************************************************************************************/
    FUNCTION get_confirmation_screen_data
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        o_confirm_msg            OUT VARCHAR2,
        o_confirmation_title     OUT VARCHAR2,
        o_continue_button_msg    OUT VARCHAR2,
        o_back_button_msg        OUT VARCHAR2,
        o_field_type_header      OUT VARCHAR2,
        o_field_pharm_header     OUT VARCHAR2,
        o_field_last_dose_header OUT VARCHAR2,
        o_inactive_icon          OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a patient's medication. Used in PFH dashboards/summary screens.
    * Adapted from pk_medication_current.get_history_medication_dash.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_hist_med     cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/30
    */
    FUNCTION get_history_medication_dash
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_hist_med OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a patient's current medication descriptions.
    * Used in the ambulatory SOAP screen.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_this_episode cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/10/03
    */
    FUNCTION get_cur_med_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_id_workflow IN table_number_id
    ) RETURN table_varchar;

    /********************************************************************************************
    * Returns list of descriptions for prescription ID's
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_tab_presc               Table with prescription ID's
    * @param o_presc_description       Set of prescription descriptions
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Brito
    * @version                         2.6
    * @since                           10-Oct-2011
    *
    **********************************************************************************************/
    FUNCTION get_presc_description
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_tab_presc         IN table_number_id,
        o_presc_description OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get allergy rxnorm
    *
    * @version                       2.6.1.2
    * @since                         2011/10/06
    **********************************************************************************************/
    FUNCTION get_allergy_rxnorm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_allergy IN NUMBER,
        o_info       OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns generic information about reported medication 
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_PATIENT    The ids to filter data
    * @param  I_DT_BEGIN      The cursor output with prescription history changes
    * @param  I_DT_END        The cursor output with prescription history changes
    * @param  i_history_data  [Y,N] checks if history data will be shown
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   2011-11-10 
    *
    ********************************************************************************************/
    FUNCTION get_list_report_active_presc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_visit     IN visit.id_visit%TYPE DEFAULT NULL,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_history_data IN VARCHAR2 DEFAULT 'N'
    ) RETURN pk_rt_types.g_tbl_list_prescription_basic
        PIPELINED;

    /********************************************************************************************
    * This procedure sets the information about home medication global information.
    *
    * @param i_lang                    The user language ID
    * @param i_prof                    The profissional information array
    * @param i_id_patient              The patient ID 
    * @param i_id_episode              The the prescription report info details
    * @param io_id_review              The ID review
    * @param i_global_info             The global information multichoice
    * @param o_error                   The output error
    *
    * @author  Bruno Rego
    * @version alpha
    * @since   2011/09/08
    ********************************************************************************************/
    FUNCTION set_hm_review_global_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pk_rt_med_pfh.r_presc.id_patient%TYPE,
        i_id_episode  IN NUMBER,
        io_id_review  IN OUT NUMBER,
        i_global_info IN NUMBER,
        o_info        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the list of ingredients of a set of products.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_products  product identifiers list
    * @param o_id_ingreds   ingredient identifiers list
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/01/20
    */
    PROCEDURE get_ingredients_by_products
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_products IN table_varchar,
        o_id_ingreds  OUT table_varchar
    );

    /********************************************************************************************
    * Get decriptions used on Single Page and Single Note functionality of a given medication
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_PRESC                 id of prescribed drug
    * @param   I_FLG_COMPLETE             Flag indicating if description is complete ('Y'-complete; 'N'-Incomplete)
    * @param   [I_FLG_WITH_NOTES]         Flag that indicates if the notes preffix is in the instructions or not
    * @param   [I_FLG_WITH_STATUS]        Flag that indicates if the status should be in the description or not
    * @param   [I_FLG_WITH_RECON_NOTES]   Flag that indicates if the reconciliation notes should be in the description or not
    *
    * @return                             string of drug prescribed or null if no_data_found, or error msg
    *
    * @author                             Luís Maia
    * @version                            2.6.2
    * @since                              24-Jan-2012
    *
    **********************************************************************************************/
    FUNCTION get_single_page_med_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_presc              IN table_number,
        i_flg_complete          IN VARCHAR2,
        i_flg_with_notes        IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_status       IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_yes,
        i_flg_with_recon_notes  IN pk_types.t_flg_char DEFAULT pk_alert_constant.g_no,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE DEFAULT NULL,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL
    ) RETURN pk_prog_notes_types.t_tasks_descs;

    /********************************************************************************************
    * get home medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              19-MAR-2012
    ********************************************************************************************/
    FUNCTION get_home_med_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get local medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin                  IN       class origin
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              19-MAR-2012
    ********************************************************************************************/
    FUNCTION get_presc_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get reconciliation medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_presc                prescription id  
    * @param       i_class_origin_context class origin context
    * @param       o_action               cursor with prescription actions
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              19-MAR-2012
    ********************************************************************************************/
    FUNCTION get_recon_med_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_presc                IN epis_pn_det_task.id_task%TYPE,
        i_class_origin_context IN VARCHAR2,
        o_action               OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get local medication actions for a given prescription  
    *
    * @param       i_lang                 the language id
    * @param       i_prof                 the profissional
    * @param       i_id_patient           Patient ID
    * @param       i_id_episode           Episode ID
    * @param       i_id_presc             prescription id  
    * @param       i_id_action            Action ID
    * @param       o_info                 cursor with action info
    * @param       o_error                structure for error handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Sofia Mendes
    * @since                              23-MAR-2012
    ********************************************************************************************/
    FUNCTION set_review_presc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN presc.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_presc   IN table_number,
        i_id_action  IN table_number,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_VISIT            
    *
    * @author Joel Lopes
    * @since  2014-07-24
    *
    ********************************************************************************************/

    FUNCTION get_rt_epis_presc_id_drug
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks;

    /********************************************************************************************
    * @param  I_LANG                  The language id
    * @param  I_PROF                  The profissional
    * @param  I_ID_VISIT            
    *
    * @author Joel Lopes
    * @since  2014-07-24
    *
    ********************************************************************************************/

    FUNCTION get_rt_epis_drug_desc_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN tf_med_tasks;

    /********************************************************************************************
    * alert_product_tr performance questions by pedro pinheiro
    *
    * @return  type
    *
    * @author      Joel Lopes
    * @version     2.6.5.0
    * @since       27/03/2015
    *
    ********************************************************************************************/

    FUNCTION get_list_fluid_balance_basic
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_visit   IN visit.id_visit%TYPE,
        i_dt_begin   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_presc   IN table_number DEFAULT NULL,
        i_id_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN t_tbl_list_fluid_balance;

    -- globals
    g_hours_in_a_day CONSTANT NUMBER(6) := 24;

    g_type_graph CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_flg_date   CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_flg_active CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';

    g_hour_mask CONSTANT VARCHAR2(4 CHAR) := 'HOUR';

    g_zero_chr CONSTANT VARCHAR2(1 CHAR) := '0';
    g_zero     CONSTANT NUMBER(6) := 0;
    g_one      CONSTANT NUMBER(6) := 1;

    -- medication workflows
    wf_institution CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_institution;
    wf_ambulatory  CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_ambulatory;
    wf_report      CONSTANT NUMBER(24, 0) := pk_rt_med_pfh.wf_report;

    --unit measure ML identifiers
    g_um_ml     CONSTANT unit_measure.id_unit_measure%TYPE := 10012;
    g_um_ml_fr  CONSTANT unit_measure.id_unit_measure%TYPE := 901000000060;
    g_um_ml_qsp CONSTANT unit_measure.id_unit_measure%TYPE := 901900000006;

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

END pk_api_pfh_clindoc_in;
/
