/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_past_history_ux IS

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
            o_last_review   := '';
            o_review_status := '';
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'get_ph_mode';
        l_dbg_msg   VARCHAR2(200 CHAR);
    BEGIN
    
        g_error := 'CALL get_past_hist_treatments_intern';
        IF NOT pk_past_history.get_ph_mode(i_lang     => i_lang,
                                           i_prof     => i_prof,
                                           i_doc_area => i_doc_area,
                                           o_modes    => o_modes,
                                           o_error    => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_ph_mode;
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_past_hist_all_grid';
        IF NOT pk_past_history.get_past_hist_all_grid(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_episode   => i_id_episode,
                                                      i_id_patient   => i_id_patient,
                                                      i_doc_area     => i_doc_area,
                                                      i_past_hist_id => i_past_hist_id,
                                                      i_past_hist_ft => i_past_hist_ft,
                                                      o_doc_area_val => o_doc_area_val,
                                                      o_ph_ft_text   => o_ph_ft_text,
                                                      o_ph_ft_id     => o_ph_ft_id,
                                                      o_error        => o_error)
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
                                              'get_past_hist_all_grid',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_past_hist_all_grid;
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_past_hist_all_grid';
        IF NOT pk_past_history.get_past_hist_search_types(i_lang     => i_lang,
                                                          i_prof     => i_prof,
                                                          i_doc_area => i_doc_area,
                                                          o_domains  => o_domains,
                                                          o_error    => o_error)
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
                                              'GET_PAST_HIST_SEARCH_TYPES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_past_hist_search_types;
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_search_past_hist';
        IF NOT pk_past_history.get_search_past_hist(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_doc_area  => i_doc_area,
                                                    i_search    => i_search,
                                                    i_pat       => i_pat,
                                                    i_flg_type  => i_flg_type,
                                                    o_diagnosis => o_diagnosis,
                                                    o_error     => o_error)
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
                                              'GET_SEARCH_PAST_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_diagnosis);
            RETURN FALSE;
    END get_search_past_hist;
    --

    /********************************************************************************************
    * Returns the diagnoses for the current complaint/type of appointment (Both standards diagnoses - like ICD9 - and ALERT diagnoses)
    
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param i_doc_area               Doc area ID
    * @param o_diagnosis              Cursor containing the diagnoses info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Ariel Machado 
    * @version                        v2.5.0.7       
    * @since                          2009/10/21 (code-refactoring)
    *
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_context_alert_diagnosis';
        IF NOT pk_past_history.get_context_alert_diagnosis(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_pat            => i_pat,
                                                           i_doc_area       => i_doc_area,
                                                           o_diagnosis      => o_diagnosis,
                                                           o_diag_not_class => o_diag_not_class,
                                                           o_error          => o_error)
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
                                              'GET_CONTEXT_ALERT_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_diag_not_class);
            RETURN FALSE;
    END get_context_alert_diagnosis;
    --

    /********************************************************************************************
    * Returns the procedures and exams (Treatments)
    *
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_pat                    Patient ID
    * @param o_treatments             Cursor containing the treatments info
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_context_treatments';
        IF NOT pk_past_history.get_context_treatments(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_pat             => i_pat,
                                                      o_treatments      => o_treatments,
                                                      o_treat_not_class => o_treat_not_class,
                                                      o_error           => o_error)
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
                                              'GET_CONTEXT_TREATMENTS',
                                              o_error);
            pk_types.open_my_cursor(o_treatments);
            pk_types.open_my_cursor(o_treat_not_class);
            RETURN FALSE;
    END get_context_treatments;
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_past_hist_last_update';
        IF NOT pk_past_history.get_past_hist_last_update(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_pat         => i_pat,
                                                         i_episode     => i_episode,
                                                         o_last_update => o_last_update,
                                                         o_error       => o_error)
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
                                              'GET_PAST_HIST_LAST_UPDATE',
                                              o_error);
            pk_types.open_my_cursor(o_last_update);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_past_hist_last_update;
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_complications';
        IF NOT pk_past_history.get_complications(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 o_problem_compl => o_problem_compl,
                                                 o_error         => o_error)
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
                                              'get_complications',
                                              o_error);
            pk_types.open_my_cursor(o_problem_compl);
            RETURN FALSE;
    END get_complications;
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
    * Returns the query for the past history summary page
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_episode             Current episode ID
    * @param i_id_patient             Patient ID
    * @param i_doc_area               Doc area ID   
    * @param o_doc_area_register      Doc area data
    * @param o_doc_area_val           Documentation data for the patient's episodes     
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_past_history.get_past_hist_all(i_lang                   => i_lang,
                                                 i_prof                   => i_prof,
                                                 i_current_episode        => i_id_episode,
                                                 i_scope                  => i_id_patient,
                                                 i_scope_type             => pk_alert_constant.g_scope_type_patient,
                                                 i_doc_area               => i_doc_area,
                                                 o_doc_area_register      => o_doc_area_register,
                                                 o_doc_area_val           => o_doc_area_val,
                                                 o_doc_area_register_tmpl => o_doc_area_register_tmpl,
                                                 o_doc_area_val_tmpl      => o_doc_area_val_tmpl,
                                                 o_doc_area               => o_doc_area,
                                                 o_template_layouts       => o_template_layouts,
                                                 o_doc_area_component     => o_doc_area_component,
                                                 o_error                  => o_error);
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
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END get_past_hist_all;
    --
    /********************************************************************************************
    **********************************************************************************************/

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
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_past_history.check_dup_icd_ph(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_episode            => i_episode,
                                                i_doc_area           => i_doc_area,
                                                i_id_diagnosis_list  => i_id_diagnosis_list,
                                                i_id_alert_diag_list => i_id_alert_diag_list,
                                                o_flg_show           => o_flg_show,
                                                o_msg                => o_msg,
                                                o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        IF o_msg IS NOT NULL
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    
    END check_dup_icd_ph;
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_past_history.cancel_past_history(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_doc_area              => i_doc_area,
                                                   i_id_episode            => i_id_episode,
                                                   i_id_patient            => i_id_patient,
                                                   i_record_id             => i_record_id,
                                                   i_ph_free_text          => i_ph_free_text,
                                                   i_id_cancel_reason      => i_id_cancel_reason,
                                                   i_cancel_notes          => i_cancel_notes,
                                                   i_id_epis_documentation => i_id_epis_documentation,
                                                   o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING CANCEL_PAST_HIST FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAST_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PAST_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_past_history;
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
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL, --42
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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'SET_PAST_HIST_ALL';
    BEGIN
        -- store coded and free text info (the function checks if there is anything to store)
        IF NOT pk_past_history.set_past_hist_all(i_lang                       => i_lang,
                                                 i_prof                       => i_prof,
                                                 i_episode                    => i_episode,
                                                 i_pat                        => i_pat,
                                                 i_doc_area                   => i_doc_area,
                                                 i_dt_diagnosed               => i_dt_diagnosed,
                                                 i_dt_diagnosed_precision     => i_dt_diagnosed_precision,
                                                 i_flg_status                 => i_flg_status,
                                                 i_flg_nature                 => i_flg_nature,
                                                 i_diagnosis                  => i_diagnosis,
                                                 i_phd_outdated               => i_phd_outdated,
                                                 i_desc_pat_history_diagnosis => i_desc_pat_history_diagnosis,
                                                 i_notes                      => i_notes,
                                                 i_id_cancel_reason           => i_id_cancel_reason,
                                                 i_cancel_notes               => i_cancel_notes,
                                                 i_precaution_measure         => i_precaution_measure,
                                                 i_flg_warning                => i_flg_warning,
                                                 i_ph_ft_id                   => i_ph_ft_id,
                                                 i_ph_ft_text                 => i_ph_ft_text,
                                                 i_exam                       => i_exam,
                                                 i_intervention               => i_intervention,
                                                 dt_execution                 => i_dt_execution,
                                                 i_dt_execution_precision     => i_dt_execution_precision,
                                                 i_cdr_call                   => i_cdr_call,
                                                 i_id_family_relationship     => i_id_family_relationship,
                                                 i_flg_death_cause            => i_flg_death_cause,
                                                 i_familiar_age               => i_familiar_age,
                                                 i_phd_diagnosis              => i_phd_diagnosis,
                                                 i_prof_cat_type              => i_prof_cat_type,
                                                 i_doc_template               => i_doc_template,
                                                 i_epis_documentation         => i_epis_documentation,
                                                 i_flg_type                   => i_flg_type,
                                                 i_id_documentation           => i_id_documentation,
                                                 i_id_doc_element             => i_id_doc_element,
                                                 i_id_doc_element_crit        => i_id_doc_element_crit,
                                                 i_value                      => i_value,
                                                 i_notes_template             => i_notes_template,
                                                 i_id_doc_element_qualif      => i_id_doc_element_qualif,
                                                 i_epis_context               => i_epis_context,
                                                 i_summary_and_notes          => i_summary_and_notes,
                                                 i_episode_context            => i_episode_context,
                                                 i_flg_table_origin           => i_flg_table_origin,
                                                 i_vs_element_list            => i_vs_element_list,
                                                 i_vs_save_mode_list          => i_vs_save_mode_list,
                                                 i_vs_list                    => i_vs_list,
                                                 i_vs_value_list              => i_vs_value_list,
                                                 i_vs_uom_list                => i_vs_uom_list,
                                                 i_vs_scales_list             => i_vs_scales_list,
                                                 i_vs_date_list               => i_vs_date_list,
                                                 i_vs_read_list               => i_vs_read_list,
                                                 o_seq_phd                    => o_seq_phd,
                                                 o_epis_documentation         => o_epis_documentation,
                                                 o_error                      => o_error)
        THEN
            RETURN FALSE; -- RAISE g_exception;
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_past_hist_all;
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
     * @reason   ALERT-52344
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT pk_past_history.set_past_history_review(i_lang,
                                                       i_prof,
                                                       i_episode,
                                                       i_id_past_history,
                                                       i_review_notes,
                                                       i_ft_flg,
                                                       i_id_epis_documentation,
                                                       o_error)
        
        THEN
            g_error := 'SET_PAT_HISTORY_REVIEW has failed';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / ERROR CALLING SET_PAT_HISTORY_REVIEW FUNCTION',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_HISTORY_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SUMMARY_PAGE',
                                              'SET_PAST_HISTORY_REVIEW',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_pat_history_review;

    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_relationship OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'call pk_past_history.get_family_relationships';
        RETURN pk_past_history.get_family_relationships(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        o_relationship => o_relationship,
                                                        o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FAMILY_RELATIONSHIPS',
                                              o_error);
            RETURN FALSE;
    END get_family_relationships; --
    FUNCTION get_death_cause
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_domains OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --'PAT_PROBLEM.FLG_COMPL_DESC'
        g_error := 'GET CURSOR';
        IF NOT pk_past_history.get_death_cause(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               o_domains => o_domains,
                                               o_error   => o_error)
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
                                              'get_death_cause',
                                              o_error);
            pk_types.open_my_cursor(o_domains);
            RETURN FALSE;
    END get_death_cause;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_past_history_ux;
/
