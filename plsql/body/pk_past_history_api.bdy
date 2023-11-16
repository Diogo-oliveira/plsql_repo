/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_past_history_api IS

    PROCEDURE open_my_cursor(i_cursor IN OUT pk_summary_page.doc_area_register_cur) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_episode,
                   NULL flg_current_episode,
                   NULL nick_name,
                   NULL desc_speciality,
                   NULL dt_register,
                   NULL id_doc_area,
                   NULL flg_status,
                   NULL dt_register_chr,
                   NULL id_professional,
                   NULL notes,
                   NULL id_pat_history_diagnosis,
                   NULL flg_detail,
                   NULL flg_external,
                   NULL flg_free_text,
                   NULL flg_reviewed,
                   NULL id_visit
              FROM dual
             WHERE 1 = 0;
    END;

    PROCEDURE open_my_cursor(i_cursor IN OUT pk_summary_page.doc_area_val_past_med_cur) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_episode,
                   NULL dt_register,
                   NULL nick_name,
                   NULL desc_past_hist,
                   NULL desc_past_hist_all,
                   NULL flg_status,
                   NULL desc_status,
                   NULL flg_nature,
                   NULL desc_nature,
                   NULL flg_current_episode,
                   NULL flg_current_professional,
                   NULL flg_last_record,
                   NULL flg_last_record_prof,
                   NULL id_diagnosis,
                   NULL flg_outdated,
                   NULL flg_canceled,
                   NULL day_begin,
                   NULL month_begin,
                   NULL year_begin,
                   NULL onset,
                   NULL dt_register_chr,
                   NULL desc_flg_status,
                   NULL dt_register_order,
                   NULL dt_pat_history_diagnosis_tstz,
                   NULL flg_external,
                   NULL id_pat_history_diagnosis,
                   NULL desc_past_hist_short,
                   NULL id_professional,
                   NULL code_icd,
                   NULL flg_other,
                   NULL rank,
                   NULL status_diagnosis,
                   NULL icon_status,
                   NULL avail_for_select,
                   NULL default_new_status,
                   NULL default_new_status_desc,
                   NULL id_alert_diagnosis,
                   NULL dt_pat_history_diagnosis_rep,
                   NULL flg_free_text
              FROM dual
             WHERE 1 = 0;
    END;

    PROCEDURE open_cursor_if_closed(i_cursor IN OUT pk_summary_page.doc_area_register_cur) IS
    BEGIN
        IF NOT i_cursor%ISOPEN
        THEN
            OPEN i_cursor FOR
                SELECT NULL id_episode,
                       NULL flg_current_episode,
                       NULL nick_name,
                       NULL desc_speciality,
                       NULL dt_register,
                       NULL id_doc_area,
                       NULL flg_status,
                       NULL dt_register_chr,
                       NULL id_professional,
                       NULL notes,
                       NULL id_pat_history_diagnosis,
                       NULL flg_detail,
                       NULL flg_external,
                       NULL flg_free_text,
                       NULL flg_reviewed,
                       NULL id_visit
                  FROM dual
                 WHERE 1 = 0;
        END IF;
    END;

    PROCEDURE open_cursor_if_closed(i_cursor IN OUT pk_summary_page.doc_area_val_past_med_cur) IS
    BEGIN
        IF NOT i_cursor%ISOPEN
        THEN
            OPEN i_cursor FOR
                SELECT NULL id_episode,
                       NULL dt_register,
                       NULL nick_name,
                       NULL desc_past_hist,
                       NULL desc_past_hist_all,
                       NULL flg_status,
                       NULL desc_status,
                       NULL flg_nature,
                       NULL desc_nature,
                       NULL flg_current_episode,
                       NULL flg_current_professional,
                       NULL flg_last_record,
                       NULL flg_last_record_prof,
                       NULL id_diagnosis,
                       NULL flg_outdated,
                       NULL flg_canceled,
                       NULL day_begin,
                       NULL month_begin,
                       NULL year_begin,
                       NULL onset,
                       NULL dt_register_chr,
                       NULL desc_flg_status,
                       NULL dt_register_order,
                       NULL dt_pat_history_diagnosis_tstz,
                       NULL flg_external,
                       NULL id_pat_history_diagnosis,
                       NULL desc_past_hist_short,
                       NULL id_professional,
                       NULL code_icd,
                       NULL flg_other,
                       NULL rank,
                       NULL status_diagnosis,
                       NULL icon_status,
                       NULL avail_for_select,
                       NULL default_new_status,
                       NULL default_new_status_desc,
                       NULL id_alert_diagnosis,
                       NULL dt_pat_history_diagnosis_rep,
                       NULL flg_free_text
                  FROM dual
                 WHERE 1 = 0;
        END IF;
    END;

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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL get_past_hist_medical_internal';
        IF NOT pk_past_history.get_past_hist_medical(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_current_episode   => i_current_episode,
                                                     i_scope             => i_scope,
                                                     i_scope_type        => i_scope_type,
                                                     i_flg_diag_call     => i_flg_diag_call,
                                                     o_doc_area_register => o_doc_area_register,
                                                     o_doc_area_val      => o_doc_area_val,
                                                     o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        open_cursor_if_closed(o_doc_area_register);
        open_cursor_if_closed(o_doc_area_val);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_medical',
                                              o_error);
            open_my_cursor(o_doc_area_val);
            open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END get_past_hist_medical;
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL get_past_hist_surgical_intern';
        IF NOT pk_past_history.get_past_hist_surgical(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_current_episode   => i_current_episode,
                                                      i_scope             => i_scope,
                                                      i_scope_type        => i_scope_type,
                                                      o_doc_area_register => o_doc_area_register,
                                                      o_doc_area_val      => o_doc_area_val,
                                                      o_error             => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_surgical',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
    END;
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL get_past_hist_cong_anom_intern';
        IF NOT pk_past_history.get_past_hist_cong_anom(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_current_episode   => i_current_episode,
                                                       i_scope             => i_scope,
                                                       i_scope_type        => i_scope_type,
                                                       o_doc_area_register => o_doc_area_register,
                                                       o_doc_area_val      => o_doc_area_val,
                                                       o_error             => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_cong_anom',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_area_register);
            RETURN FALSE;
        
    END get_past_hist_cong_anom;
    --
    /********************************************************************************************
    * Returns the query for the relevant notes summary page
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL get_past_hist_relev_notes_int';
        IF NOT pk_past_history.get_past_hist_relev_notes(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_current_episode   => i_id_episode,
                                                         i_scope             => i_id_patient,
                                                         i_scope_type        => pk_alert_constant.g_scope_type_patient,
                                                         i_doc_area          => i_doc_area,
                                                         o_doc_area_register => o_doc_area_register,
                                                         o_doc_area_val      => o_doc_area_val,
                                                         o_error             => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        pk_types.open_cursor_if_closed(o_doc_area_register);
        pk_types.open_cursor_if_closed(o_doc_area_val);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_past_hist_relev_notes',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            RETURN FALSE;
    END get_past_hist_relev_notes;
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
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL get_past_hist_relev_notes_int';
        IF NOT pk_past_history.get_ph_summary_list(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_episode      => i_episode,
                                                   i_patient      => i_patient,
                                                   i_doc_area     => i_doc_area,
                                                   o_past_history => o_past_history,
                                                   o_error        => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        pk_types.open_cursor_if_closed(o_past_history);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_ph_summary_list',
                                              o_error);
            pk_types.open_my_cursor(o_past_history);
            RETURN FALSE;
    END get_ph_summary_list;
    --    

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_past_history_api;
/
