/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_past_history_api_rep IS

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
    * Invokation of pk_summary_page.get_past_hist_all
    
    * @author                                  Gonçalo Almeida
    * @version                                 0.1
    * @since                                   2011/Mar/02
    ********************************************************************************************/
    FUNCTION get_past_hist_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_current_episode        IN episode.id_episode%TYPE,
        i_scope                  IN NUMBER,
        i_scope_type             IN VARCHAR2,
        i_doc_area               IN doc_area.id_doc_area%TYPE,
        o_doc_area_register      OUT pk_types.cursor_type,
        o_doc_area_val           OUT pk_types.cursor_type,
        o_doc_area               OUT doc_area.id_doc_area%TYPE,
        o_template_layouts       OUT pk_types.cursor_type,
        o_doc_area_component     OUT pk_types.cursor_type,
        o_doc_area_register_tmpl OUT pk_types.cursor_type,
        o_doc_area_val_tmpl      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /****************************************************************************************************************************************************************************************
    * VARIABLES
    *****************************************************************************************************************************************************************************************/
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_exception EXCEPTION;
    --    
    g_error VARCHAR2(2000);

END pk_past_history_api_rep;
/
