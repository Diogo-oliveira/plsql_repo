/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_past_history_ux IS
    /****************************************************************************************************************************************************************************************
      ********************
      * PUBLIC FUNCTIONS *
      ********************
    *****************************************************************************************************************************************************************************************/

    /****************************************************************************************************************************************************************************************
    * GETS
    *****************************************************************************************************************************************************************************************/

    /********************************************************************************************
    * Gets review info of the current patient
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_episode                Episode ID
    * @param o_last_review               Last review result
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        2.6.1.4
    * @since                          04-Nov-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN NUMBER,
        o_last_review   OUT VARCHAR2,
        o_review_status OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
     * get the past history mode(s) of documenting data
     *
     * @param i_lang                          Language ID
     * @param i_prof                          Profissional array
     * @param i_doc_area                      ID doc area   
     * @param o_modes                         Cursor with the values of the flags
     * @param o_error                         error message, if error occurs
     *
     * @return BOOLEAN
     *
     * @version  2.6.1
     * @since    12-Apr-2011
     * @author   Filipe Machado
     * @reason   ALERT-65577
    */
    FUNCTION get_ph_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN episode.id_episode%TYPE,
        o_modes    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the query for the past history grid
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc Area ID
    * @param i_phd                    Pat History Diagnosis/Pat notes ID
    
    * @param o_doc_area_val           Documentation data for the patient's episodes   
    * @param o_ph_ft                  Patient past history free text                                      
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        1.0   
    * @since                          2010-Dec-09
    **********************************************************************************************/
    FUNCTION get_past_hist_all_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_past_hist_id IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_past_hist_ft IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_val OUT pk_types.cursor_type,
        o_ph_ft_text   OUT pat_past_hist_free_text.text%TYPE,
        o_ph_ft_id     OUT pat_past_hist_free_text.id_pat_ph_ft%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns all diagnosis and treatments
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc area ID
    * @param i_search                 String to search
    * @param i_pat                    Patient ID
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        2.6.1    
    * @since                          2010/06/13
    **********************************************************************************************/
    FUNCTION get_search_past_hist
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        i_search    IN VARCHAR2,
        i_pat       IN patient.id_patient%TYPE,
        i_flg_type  IN table_varchar,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns configured standards(ICD9,ICPC,etc.) that can be used in Past-History diagnoses(advanced search)
    * or treatment types (Image Exams, Other Exams, Procedures...etc)
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Current profissional
    * @param o_domains                   Available past history diagnoses to search
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Rui Duarte
    * @version 
    * @since   10-Nov-09
    **********************************************************************************************/
    FUNCTION get_past_hist_search_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_domains  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the diagnosis for the current complaint/type of appointment (Both standards diagnosis - like ICD9 - and ALERT diagnosis)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/16
    **********************************************************************************************/
    FUNCTION get_context_alert_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_pat            IN patient.id_patient%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_diagnosis      OUT pk_types.cursor_type,
        o_diag_not_class OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the procedures and exams (Treatments)
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param o_treatmenst             Cursor containing the treatments info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Filipe Machado 
    * @version                        v2.6.1       
    * @since                          16-Apr-2011
    *
    **********************************************************************************************/
    FUNCTION get_context_treatments
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pat             IN patient.id_patient%TYPE,
        o_treatments      OUT pk_types.cursor_type,
        o_treat_not_class OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
    * Returns the lastest update information for the past history summary page
    *
    * @param i_lang        Language ID
    * @param i_prof        Current professional
    * @param i_pat         Patient ID
    * @param i_episode     Episode ID
    * @param o_sections    Cursor containing the sections info
    *
    * @param o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.1
    * @since   07-Apr-10 (code-refactoring)
    */
    FUNCTION get_past_hist_last_update
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_last_update OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the possible values for complications for a past surgical history.
    *
    * @param i_lang              language id
    * @param i_prof              professional type
    * @param o_problem_compl     Cursor with possible options for the complications
    * @param o_error             Error message
    *
    * @return                    true (sucess), false (error)
    *
    * @author                    Rui de Sousa Neves
    * @version                   1.0
    * @since                     30-09-2007
    **********************************************************************************************/

    FUNCTION get_complications
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_problem_compl OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Returns the details for the past history summary page (medical and surgical history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param i_pat_hist_diag          Past History Diagnosis ID   
    * @param i_flg_ft                 If provided id is from a free text or a diagnosis ID - Yes (Y) No (N) 
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui Duarte
    * @version                        2.6.0.5 
    * @since                          2010-Dec-16
    **********************************************************************************************/
    FUNCTION get_past_hist_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_pat_hist_diag     IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_flg_ft            IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_epis_document     IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_epis_doc_register OUT pk_types.cursor_type,
        o_epis_document_val OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /********************************************************************************************
    * Returns the query for the past history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param o_doc_area_register      Cursor containing information about registers (professional, record date, status, etc.)
    * @param o_doc_area_val           Cursor containing information about data values saved in registers
    * @param o_doc_area               Doc area ID
    * @param o_template_layouts       Cursor containing the layout for each template used
    * @param o_doc_area_component     Cursor containing the components for each template used 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        o_doc_area_register      OUT pk_types.cursor_type,
        o_doc_area_val           OUT pk_types.cursor_type,
        o_doc_area_register_tmpl OUT pk_types.cursor_type,
        o_doc_area_val_tmpl      OUT pk_types.cursor_type,
        o_doc_area               OUT doc_area.id_doc_area%TYPE,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /****************************************************************************************************************************************************************************************
    * SETS
    *****************************************************************************************************************************************************************************************/

    /********************************************************************************************
    * Cancels records for past history
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               Doc Area ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_record_id              Pat History Diagnosis ID or Free Text ID
    * @param i_ph_free_text           Value that indicates if "i_record_id" is a past_history_diagnosis_id or a free_text_id
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes   
    * @param i_id_epis_documentation  Template info ID
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/06/05
    *
    * @reviewed                       Sergio Dias
    * @version                        2.6.1.2
    * @since                          Jun-30-2011
    **********************************************************************************************/
    FUNCTION cancel_past_history
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_record_id             IN NUMBER,
        i_ph_free_text          IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_id_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes          IN pat_problem_hist.cancel_notes%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
    * @author  Sergio Dias
    * @version 2.6.1.1
    * @since   May-30-2011
    */
    FUNCTION set_past_hist_all
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_pat                        IN patient.id_patient%TYPE,
        i_doc_area                   IN doc_area.id_doc_area%TYPE,
        i_dt_symptoms                IN table_varchar, --6
        i_dt_diagnosed               IN table_varchar,
        i_dt_diagnosed_precision     IN table_varchar,
        i_flg_status                 IN table_varchar,
        i_flg_nature                 IN table_varchar,
        i_diagnosis                  IN table_number,
        i_phd_outdated               IN NUMBER,
        i_desc_pat_history_diagnosis IN table_varchar,
        i_notes                      IN table_varchar, --14
        i_id_cancel_reason           IN table_number,
        i_cancel_notes               IN table_varchar,
        i_precaution_measure         IN table_table_number,
        i_flg_warning                IN table_varchar,
        i_dt_resolution              IN table_varchar,
        i_ph_ft_id                   IN pat_past_hist_free_text.id_pat_ph_ft%TYPE, --20
        i_ph_ft_text                 IN pat_past_hist_free_text.text%TYPE,
        i_exam                       IN table_number,
        i_intervention               IN table_number,
        i_dt_execution               IN table_varchar,
        i_dt_execution_precision     IN table_varchar,
        i_cdr_call                   IN cdr_call.id_cdr_call%TYPE,
        i_id_family_relationship     IN table_number,
        i_flg_death_cause            IN table_varchar,
        i_familiar_age               IN table_number,
        i_phd_diagnosis              IN table_number,
        --
        i_prof_cat_type         IN category.flg_type%TYPE, --30
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number, --36
        i_value                 IN table_varchar,
        i_notes_template        IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL, --40
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number, --48
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number, --51
        o_seq_phd               OUT table_number,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /**
     * This functions sets a past history as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
    */
    FUNCTION set_pat_history_review
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_past_history       IN table_number,
        i_review_notes          IN review_detail.review_notes%TYPE,
        i_ft_flg                IN table_varchar,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_death_cause
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_dup_icd_ph
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number DEFAULT NULL,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /****************************************************************************************************************************************************************************************
    * VARIABLES
    *****************************************************************************************************************************************************************************************/
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_exception EXCEPTION;
    --    
    g_error VARCHAR2(2000);

END pk_past_history_ux;
/
