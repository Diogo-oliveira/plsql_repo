/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_past_history_api IS
    /****************************************************************************************************************************************************************************************
      ********************
      * PUBLIC FUNCTIONS *
      ********************
    *****************************************************************************************************************************************************************************************/

    /****************************************************************************************************************************************************************************************
    * GETS
    *****************************************************************************************************************************************************************************************/

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
    /********************************************************************************************
    * Returns the query for the past medical history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_flg_diag_call          Function is called by diagnosis deepnaves. Y - Yes; N - Otherwise
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_medical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_diag_call     IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        o_doc_area_register OUT NOCOPY pk_summary_page.doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_med_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the query for the past surgical history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes   
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/05/30
    **********************************************************************************************/
    FUNCTION get_past_hist_surgical
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns the query for the congenital anomalies past history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes                                          
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @version                        1.0   
    * @since                          2007/08/08
    **********************************************************************************************/
    FUNCTION get_past_hist_cong_anom
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_current_episode   IN episode.id_episode%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        o_doc_area_register OUT NOCOPY pk_summary_page.s_doc_area_register_cur,
        o_doc_area_val      OUT NOCOPY pk_summary_page.doc_area_val_past_surg_cur,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --  
    /********************************************************************************************
    * Returns the relevant notes info
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional object (professional ID, institution ID, software ID)
    * @param i_current_episode        Current episode ID
    * @param i_scope                  Scope
    * @param i_scope_type             Scope type
    * @param i_doc_area               Documentation area
    * @param o_doc_area_register      Documentation register cursor
    * @param o_doc_area_val           Documentation values cursor
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.2
    * @since                          30-08-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_relev_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Returns last activa past history records for dashboards
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_episode            Episode ID
    * @param   i_patient            Patient ID
    * @param   o_past_med_hist      Cursor containing active past history records
    * @param   o_error              Error message
    * 
    * @author  Rui Duarte
    * @version 2.6.1.5
    * @since   11/11/2011
    **********************************************************************************************/
    FUNCTION get_ph_summary_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        o_past_history OUT pk_types.cursor_type,
        o_error        OUT t_error_out
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

END pk_past_history_api;
/
