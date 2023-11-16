/*-- Last Change Revision: $Rev: 2028433 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_abcde_methodology IS

    -- Author  : SERGIO.CUNHA
    -- Created : 25-06-2009 14:19:28
    -- Purpose : ABCDE assessment methodology

    /********************************************************************************************
    * Trauma and ABCDE history page
    *
    * @param i_lang                   The language ID 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param o_ann_arrival_list       announced arrival
    * @param o_pre_hospital           pre hospital accident
    * @param o_pre_hosp_vs            vs of pre_hosp_acc
    * @param o_trauma_hist            ABCDE assessment history
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_trauma_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        o_ann_arrival_list OUT pk_types.cursor_type,
        o_pre_hospital     OUT pk_types.cursor_type,
        o_pre_hosp_vs      OUT pk_types.cursor_type,
        o_trauma_hist      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************************
    * The function returns the string with the id/ desc os all allergies and allergies unawareness registred throw trauma.
    *
    * @param i_lang                   The language ID
        * @param i_prof                   Object (professional ID, institution ID, software ID)
        * @param i_id_episode             the episode ID
    * @param i_type                   the type as two values possible: {ID, LABEL}
    * @param i_separator              The separator as teo values possible:{',' ,',, '}
    * @return                         String with the allergies descriptions
    *  
      * @author                         Pedro Fernandes
      * @version                        2.6.1.2
      * @since                          01-09-2011
    */
    FUNCTION get_allergy_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_type       IN VARCHAR2,
        i_separator  IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************************************
    * Gets the episode allergy/allergy unawareness list. Used to get the most recent records when registering
      * a new AMPLE/SAMPLE/CIAMPEDS assessment.
    *
    * @param i_lang                   The language ID
      * @param i_prof                   Object (professional ID, institution ID, software ID)
      * @param i_id_episode             the episode ID
    * @param i_epis_abcde_meth        The abecde episode 
    * @param i_separator              The separator as teo values possible:{',' ,',, '}
    * @return                         Allergy text 
    *
    * @author                         Pedro Fernandes
      * @version                        2.6.1.2
      * @since                          01-09-2011
    ************************************************************************************************************************/

    FUNCTION get_allergy_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE
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
    * @param i_separator              List items separator
    *
    * @value i_type                   {*} 'ID' Get list of ID's {*} 'LABEL' Get list of labels
    * @value i_separator              {*} ',' ID separator {*} ',, ' Label separator
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    **********************************************************************************************/
    FUNCTION get_medication_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_type       IN VARCHAR2,
        i_separator  IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the ABCDE assessment medication text
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis_abcde_meth     Assessment record ID
    *                        
    * @return                         Medication text
    * 
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/15
    **********************************************************************************************/
    FUNCTION get_medication_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get ABCDE assessment data (AMPLE/SAMPLE/CIAMPEDS) for a given episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_get_titles             Return titles in a cursor?
    * @param i_most_recent            Get the most recent (active) record only?
    * @param o_titles                 ABCDE assessment field titles
    * @param o_trauma_hist            ABCDE assessment history
    * @param o_error                  Error message
    *
    * @value i_get_titles             {*} 'Y' Yes {*} 'N' No
    * @value i_most_recent            {*} 'Y' Yes {*} 'N' No - default
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Brito
    * @version                        1.0
    * @since                          2011/01/04
    **********************************************************************************************/
    FUNCTION get_abcde_summary
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_get_titles  IN VARCHAR2,
        i_most_recent IN VARCHAR2 DEFAULT 'N',
        o_titles      OUT pk_types.cursor_type,
        o_trauma_hist OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Set ABCDE information
      *
      * @param i_lang                       The language ID
      * @param i_prof                       Object (professional ID, institution ID, software ID)
      * @param i_id_episode                 the episode ID
      * @param i_id_epis_abcde_meth         EPIS_ABCDE_METH - NULL if it is a new registry
      * @param i_flg_meth_type              Type of ABCDE registry (A)mple / (S)ample / (C)iampeds
      * @param i_chief_complaint            List of epis_complaint
      * @param i_imunisation                Imunisation information (Free text)
      * @param i_allergies                  List of pat_allergy
    * @param i_allergies_unawareness      Allergie unawareness Id
      * @param i_medication                 List of pat_medication_list
      * @param i_past_medical               Past medical information (Free text)
      * @param i_parents_impression         Parents impression information (Free text)
      * @param i_event                      Event information (Free text)
      * @param i_diet                       Diet information (Free text)
      * @param i_diapers                    Diapers information (Free text)
      * @param i_sympthoms                  Sympthoms information (Free text)
      * @param i_last_meal                  Last meal information (Free text)
      * @param o_id_epis_abcde_meth         Inserted EPIS_ABCDE_METH
      * @param o_id_epis_abcde_meth_param   Inserted EPIS_ABCDE_METH_PARAM
      * @param o_error                      Error message
      *                        
      * @return                             true or false on success or error
      * 
      * @author                             Sérgio Cunha
      * @version                            1.0
      * @since                              2009/07/05
      **********************************************************************************************/
    FUNCTION set_trauma_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth       IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        i_flg_meth_type            IN abcde_meth.flg_meth_type%TYPE,
        i_chief_complaint          IN table_number,
        i_imunisation              IN epis_abcde_meth_param.param_text%TYPE,
        i_allergies                IN table_number,
        i_allergies_unawareness    IN pat_allergy_unawareness.id_allergy_unawareness%TYPE,
        i_medication               IN table_number,
        i_past_medical             IN epis_abcde_meth_param.param_text%TYPE,
        i_parents_impression       IN epis_abcde_meth_param.param_text%TYPE,
        i_event                    IN epis_abcde_meth_param.param_text%TYPE,
        i_diet                     IN epis_abcde_meth_param.param_text%TYPE,
        i_diapers                  IN epis_abcde_meth_param.param_text%TYPE,
        i_sympthoms                IN epis_abcde_meth_param.param_text%TYPE,
        i_last_meal                IN epis_abcde_meth_param.param_text%TYPE,
        o_id_epis_abcde_meth       OUT table_number,
        o_id_epis_abcde_meth_param OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel ABCDE assessment (AMPLE/SAMPLE/CIAMPEDS).
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_id_episode           Episode ID
    * @param   i_id_patient           Patient ID
    * @param   i_id_epis_abcde_meth   ABCDE assessment ID
    * @param   i_tab_task             Associated tasks ID (allergies, reported medication)
    * @param   i_tab_type             Associated tasks type: (A) Allergies (P) Reported medication - prescription
    * @param   i_id_cancel_reason     Cancel reason ID
    * @param   i_cancel_reason        Cancel reason (free text)
    * @param   i_cancel_notes         Cancellation notes
    * @param   o_error                error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    **********************************************************************************************/
    FUNCTION cancel_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        i_tab_task           IN table_number,
        i_tab_type           IN table_varchar,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes       IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Return registered allergies and reported medication 
      *
      * @param   i_lang                 Language ID
      * @param   i_prof                 Professional info
      * @param   i_id_episode           Episode ID
      * @param   i_id_patient           Patient ID
      * @param   i_id_epis_abcde_meth   ABCDE assessment ID
      * @param   o_allergies            Allergies data
    * @param   o_allergies_unawareness Allergies Unawareness data
      * @param   o_medication           Reported medication data
      * @param   o_error                Error message
      *                        
      * @return  TRUE if successfull, FALSE otherwise
      * 
      * @author                         José Brito
      * @version                        2.6.0
      * @since                          15-03-2010
      **********************************************************************************************/
    FUNCTION get_trauma_hist_by_id
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth    IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_allergies_unawareness OUT pk_types.cursor_type,
        o_allergies             OUT pk_types.cursor_type,
        o_medication            OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return all data registered in a given ABCDE assessment.
    *
    * @param   i_lang                 Language ID
    * @param   i_prof                 Professional info
    * @param   i_id_episode           Episode ID
    * @param   i_id_epis_abcde_meth   ABCDE assessment ID
    * @param   o_trauma_detail        Assessment data
    * @param   o_error                Error message
    *                        
    * @return  TRUE if successfull, FALSE otherwise
    * 
    * @author                         José Brito
    * @version                        2.6.0
    * @since                          15-03-2010
    **********************************************************************************************/
    FUNCTION get_trauma_hist_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_trauma_detail      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get selected AMPLE information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_ample                  AMPLE information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_ample_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_ample              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get selected SAMPLE information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_sample                  SAMPLE information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_sample_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_sample             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get selected CIAMPEDS information
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_epis_abcde_meth     EPIS_ABCDE_METH ID
    * @param o_ciampeds                  CIAMPEDS information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_ciampeds_trauma_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_abcde_meth IN epis_abcde_meth.id_epis_abcde_meth%TYPE,
        o_ciampeds           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's allergys
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param o_pat_allergy_list       Alergies info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_pat_allergy_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        o_pat_allergy_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's medication
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_patient             the patient ID
    * @param o_pat_medication_list    PAT_MEDICATION_LIST information
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_pat_medication_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        o_pat_medication_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get episode associated complaint
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param o_epis_complaint_list    Complaint info to multichoice use
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION get_epis_complaint_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_epis_complaint_list OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get edition options
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_options                Available edition options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION edit_assess_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get creations options available by patient's age and professional profile
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_patient             the patient ID
    * @param i_id_episode             the episode ID
    * @param o_options                Available creation options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sérgio Cunha
    * @version                        1.0
    * @since                          2009/07/05
    **********************************************************************************************/
    FUNCTION create_assess_options
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_options    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the summary page description for a specific section
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_internal_name          Section internal name
    *                        
    * @return                         Section description
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/07
    **********************************************************************************************/
    FUNCTION get_summ_section_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_internal_name IN summary_page_section.internal_name%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Trauma and ABCDE summary page sections
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param o_sections               Cursor containing the sections info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/06
    **********************************************************************************************/
    FUNCTION get_summary_sections
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_sections OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Trauma and ABCDE summary page
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             the episode ID
    * @param i_id_doc_area            doc area IDs (primary and secondary assessment)
    * @param o_trauma                 Trauma score information
    * @param o_ann_arrival_list       announced arrival
    * @param o_pre_hosp               Pre-hospital assessment
    * @param o_pre_hosp               Pre-hospital assessment (vital signs)
    * @param o_prim_assess            Primary assessment (physician and nurse)
    * @param o_sec_assess             Secondary assessment (physician and nurse)
    * @param o_trauma_hist_titles     ABCDE assessment field titles
    * @param o_trauma_hist            ABCDE assessment data
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2009/07/04
    **********************************************************************************************/
    FUNCTION get_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_doc_area        IN table_number,
        o_trauma             OUT pk_types.cursor_type,
        o_ann_arrival_list   OUT pk_types.cursor_type,
        o_pre_hosp           OUT pk_types.cursor_type,
        o_pre_hosp_vs        OUT pk_types.cursor_type,
        o_prim_assess_reg    OUT pk_types.cursor_type,
        o_prim_assess_val    OUT pk_types.cursor_type,
        o_sec_assess_reg     OUT pk_types.cursor_type,
        o_sec_assess_val     OUT pk_types.cursor_type,
        o_trauma_hist_titles OUT pk_types.cursor_type,
        o_trauma_hist        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get medication description
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
    **********************************************************************************************/
    FUNCTION get_pat_medic_multichoice
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

    g_error VARCHAR2(2000);
    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_flg_active   CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_inactive CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_no_home_medication_id     CONSTANT NUMBER(6) := -2;
    g_cannot_name_medication_id CONSTANT NUMBER(6) := -3;

    g_list_id    CONSTANT VARCHAR2(24 CHAR) := 'ID';
    g_list_label CONSTANT VARCHAR2(24 CHAR) := 'LABEL';
    g_list_type  CONSTANT VARCHAR2(24 CHAR) := 'TYPE';

    g_list_id_sep    CONSTANT VARCHAR2(24 CHAR) := ',';
    g_list_label_sep CONSTANT VARCHAR2(24 CHAR) := ',, ';

END pk_abcde_methodology;
/
