/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_past_history_api_rep IS

    /****************************************************************************************************************************************************************************************
      ********************
      * PUBLIC FUNCTIONS *
      ********************
    *****************************************************************************************************************************************************************************************/

    /****************************************************************************************************************************************************************************************
    * GETS
    *****************************************************************************************************************************************************************************************/

    /********************************************************************************************
    * Gets the last review made in an episode
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_id_episode                Episode ID
    * @param o_last_review               Last review result
    * @param o_error                     Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sergio Dias
    * @version                        2.6.1.1
    * @since                          Jun-01-2011
    **********************************************************************************************/
    FUNCTION get_past_hist_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN NUMBER,
        o_last_review   OUT VARCHAR2,
        o_review_status OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PAST_HIST_LAST_REVIEW';
    BEGIN
        IF NOT pk_past_history.get_past_hist_review(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_episode    => i_id_episode,
                                                    o_last_review   => o_last_review,
                                                    o_review_status => o_review_status,
                                                    o_error         => o_error)
        
        THEN
            g_error := 'pk_past_history.get_past_hist_last_review has failed';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_last_review := '';
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END get_past_hist_review;
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_past_hist_det';
        IF NOT pk_past_history.get_past_hist_det(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_id_episode        => i_id_episode,
                                                 i_id_patient        => i_id_patient,
                                                 i_doc_area          => i_doc_area,
                                                 i_pat_hist_diag     => i_pat_hist_diag,
                                                 i_all               => TRUE,
                                                 i_flg_ft            => i_flg_ft,
                                                 i_epis_document     => i_epis_document,
                                                 o_doc_area_register => o_doc_area_register,
                                                 o_doc_area_val      => o_doc_area_val,
                                                 o_epis_doc_register => o_epis_doc_register,
                                                 o_epis_document_val => o_epis_document_val,
                                                 o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_det',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_epis_doc_register);
            pk_types.open_my_cursor(o_epis_document_val);
            RETURN FALSE;
    END get_past_hist_det;
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO FUNCTION INTERNAL GET_PAST_HIST_ALL';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_past_history.get_past_hist_all(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_current_episode        => i_current_episode,
                                                 i_scope                  => i_scope,
                                                 i_scope_type             => i_scope_type,
                                                 i_doc_area               => i_doc_area,
                                                 o_doc_area_register      => o_doc_area_register,
                                                 o_doc_area_val           => o_doc_area_val,
                                                 o_doc_area_register_tmpl => o_doc_area_register_tmpl,
                                                 o_doc_area_val_tmpl      => o_doc_area_val_tmpl,
                                                 o_doc_area               => o_doc_area,
                                                 o_template_layouts       => o_template_layouts,
                                                 o_doc_area_component     => o_doc_area_component,
                                                 o_error                  => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAST_HIST_ALL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_past_hist_all;
    --
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_past_history_api_rep;
/
