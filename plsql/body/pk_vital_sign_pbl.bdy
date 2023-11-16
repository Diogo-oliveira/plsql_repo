/*-- Last Change Revision: $Rev: 2027860 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_vital_sign_pbl AS

    --
    -- PRIVATE CONSTANTS
    -- 
    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    /* Package name */
    g_package_name  VARCHAR2(32 CHAR);
    g_package_owner VARCHAR2(32 CHAR);

    --
    -- FUNCTIONS
    -- 

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_n_records              Number of collumns of registries
    * @param      o_n_vs                      Number of registries
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_patient      IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit        IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_n_records OUT PLS_INTEGER,
        o_n_vs         OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_N_RECORDS';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_vs_n_records(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_flg_view     => i_flg_view,
                                                   i_patient      => i_patient,
                                                   i_visit        => i_visit,
                                                   o_vs_n_records => o_vs_n_records,
                                                   o_n_vs         => o_n_vs,
                                                   o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            --
            o_vs_n_records := 0;
            o_n_vs         := 0;
            RETURN FALSE;
    END get_vs_n_records;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient
    *
    * @param      i_vital_sign                Vital sign id
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_n_records              Number of collumns of registries
    * @param      o_n_vs                      Number of registries
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_visit      IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_n_records(i_vital_sign => i_vital_sign,
                                                   i_patient    => i_patient,
                                                   i_visit      => i_visit);
    END get_vs_n_records;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_grid                   Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_short_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_patient  IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit    IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_grid  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VS_SHORT_GRID';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_vs_short_grid(i_lang     => i_lang,
                                                    i_prof     => i_prof,
                                                    i_flg_view => i_flg_view,
                                                    i_patient  => i_patient,
                                                    i_visit    => i_visit,
                                                    o_vs_grid  => o_vs_grid,
                                                    o_error    => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_vs_grid);
            RETURN FALSE;
    END get_vs_short_grid;

    /************************************************************************************************************
    * This function returns the vital sign information registered for one episode VISIT
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    *
    * @param      o_val_vs                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_val_vs            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_GRID_ALL';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_vs_grid_new(i_lang              => i_lang,
                                                  i_prof              => i_prof,
                                                  i_flg_view          => i_flg_view,
                                                  i_scope             => i_scope,
                                                  i_scope_type        => i_scope_type,
                                                  i_interval          => i_interval,
                                                  i_dt_begin          => i_dt_begin,
                                                  i_dt_end            => i_dt_end,
                                                  i_flg_use_soft_inst => i_flg_use_soft_inst,
                                                  o_val_vs            => o_val_vs,
                                                  o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END get_epis_vs_grid_all;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    *
    * @param      o_time                      Returns time collumns
    * @param      o_sign_v                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_view          IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_scope             IN NUMBER DEFAULT NULL,
        i_scope_type        IN VARCHAR2 DEFAULT NULL,
        i_interval          IN VARCHAR2 DEFAULT NULL,
        i_dt_begin          IN VARCHAR2 DEFAULT NULL,
        i_dt_end            IN VARCHAR2 DEFAULT NULL,
        i_flg_use_soft_inst IN VARCHAR2 DEFAULT pk_alert_constant.g_yes, -- flg inficating if get_vital_sign_records uses vs_soft_inst to retrieve records
        o_time              OUT pk_types.cursor_type,
        o_sign_v            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_GRID_LIST';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF NOT pk_vital_sign_core.get_vs_grid_list(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_flg_view          => i_flg_view,
                                                   i_flg_screen        => i_flg_screen,
                                                   i_scope             => i_scope,
                                                   i_scope_type        => i_scope_type,
                                                   i_interval          => i_interval,
                                                   i_dt_begin          => i_dt_begin,
                                                   i_dt_end            => i_dt_end,
                                                   i_flg_use_soft_inst => i_flg_use_soft_inst,
                                                   o_time              => o_time,
                                                   o_sign_v            => o_sign_v,
                                                   o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_vs_grid_list;

    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param o_notes_vs         Lista das notas dos sinais vitais do episódio
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/25
    ********************************************************************************************/
    FUNCTION get_epis_vs_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN vital_sign_read.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_notes_vs   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_NOTES';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_epis_vs_notes(i_lang       => i_lang,
                                                    i_episode    => i_episode,
                                                    i_prof       => i_prof,
                                                    i_flg_view   => i_flg_view,
                                                    i_start_date => i_start_date,
                                                    i_end_date   => i_end_date,
                                                    o_notes_vs   => o_notes_vs,
                                                    o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_notes_vs);
            RETURN FALSE;
    END get_epis_vs_notes;

    /************************************************************************************************************
    * This function returns all cancelled vital sign reads in a visit
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital sign read ID
    * @param        o_vsr_history            History Info
    * @param        o_error                  Error
    *
    * @author                                Luís Maia
    * @version                               2.6.1.0.1
    * @since                                 30-Nov-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_cancelled_vital_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_vsr_cancelled OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VISIT_CANCELLED_VITAL_SIGN';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get cancelled vital signs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_visit_cancelled_vital_sign(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_id_episode    => i_id_episode,
                                                                 o_vsr_cancelled => o_vsr_cancelled,
                                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vsr_cancelled);
            RETURN FALSE;
    END get_visit_cancelled_vital_sign;

    /************************************************************************************************************
    * This function returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital Sign read ID
    * @param        o_vsr_history            History information
    * @param        o_error                  List of changed columns 
    *
    * @author                                Luís Maia
    * @version                               2.6.1.0.1
    * @since                                 30-Nov-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_vital_sign_read_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_vsr_history OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_VISIT_VITAL_SIGN_READ_HIST';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get cancelled vital signs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_core.get_visit_vital_sign_read_hist(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_id_episode  => i_id_episode,
                                                                 o_vsr_history => o_vsr_history,
                                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vsr_history);
            RETURN FALSE;
    END get_visit_vital_sign_read_hist;

    /******************************************************************************************** 
    * check vital signs conflicts (used to check if predefined tasks can be requested or not) 
    * 
    * @param       i_lang              preferred language id for this professional 
    * @param       i_prof              professional id structure 
    * @param       i_episode           episode id  
    * @param       i_vital_signs       array of vital signs ids
    * @param       o_flg_conflict      array of vital signs conflicts indicators 
    * @param       o_error             error message 
    *
    * @return      boolean             true on success, otherwise false     
    ********************************************************************************************/
    FUNCTION check_vital_signs_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_vital_signs  IN table_number,
        o_flg_conflict OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_VITAL_SIGN_CORE.CHECK_VITAL_SIGNS_CONFLICT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_vital_sign_core.check_vital_signs_conflict(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_vital_signs  => i_vital_signs,
                                                             o_flg_conflict => o_flg_conflict,
                                                             o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END check_vital_signs_conflict;

    /******************************************************************************************** 
    * check vital signs conflicts (used to check if predefined tasks can be requested or not) 
    * 
    * @param       i_lang                  Preferred language id for this professional 
    * @param       i_prof                  Professional id structure 
    * @param       i_episode               Episode id  
    * @param       i_id_vital_sign_read    Vital sign read that should be cancelled
    * @param       i_id_cancel_reason      Cancel reason identifier 
    * @param       i_notes                 Cancel notes
    * @param       o_error                 Error message 
    *
    * @return      Boolean                 true on success, otherwise false    
    *
    * @author                              Luís Maia
    * @version                             2.6.1.7
    * @since                               04-Jan-2011
    ********************************************************************************************/
    FUNCTION cancel_epis_vs_read
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_notes              IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_VITAL_SIGN_CORE.CANCEL_EPIS_VS_READ';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_vital_sign_core.cancel_epis_vs_read(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_episode            => i_episode,
                                                      i_id_vital_sign_read => i_id_vital_sign_read,
                                                      i_id_cancel_reason   => i_id_cancel_reason,
                                                      i_notes              => i_notes,
                                                      o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END cancel_epis_vs_read;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    *
    * @author       Sergio Dias
    * @version      2.6.1
    * @since        18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE DEFAULT NULL,
        i_tb_attribute            IN table_number DEFAULT NULL,
        i_tb_free_text            IN table_clob DEFAULT NULL,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE DEFAULT NULL,
        i_notes_edit              IN CLOB DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_VITAL_SIGN.EDIT_VITAL_SIGN';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_id_vital_sign_read      => i_id_vital_sign_read,
                                             i_value                   => i_value,
                                             i_id_unit_measure         => i_id_unit_measure,
                                             i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                             i_dt_registry             => i_dt_registry,
                                             i_id_unit_measure_sel     => i_id_unit_measure_sel,
                                             i_tb_attribute            => i_tb_attribute,
                                             i_tb_free_text            => i_tb_free_text,
                                             i_id_edit_reason          => i_id_edit_reason,
                                             i_notes_edit              => i_notes_edit,
                                             o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END edit_vital_sign;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_id_unit_measure_sel     IN table_number DEFAULT NULL,
        i_tbtb_attribute          IN table_table_number DEFAULT NULL,
        i_tbtb_free_text          IN table_table_clob DEFAULT NULL,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE DEFAULT NULL,
        i_notes_edit              IN CLOB DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_VITAL_SIGN.EDIT_VITAL_SIGN';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_id_vital_sign_read      => i_id_vital_sign_read,
                                             i_value                   => i_value,
                                             i_id_unit_measure         => i_id_unit_measure,
                                             i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                             i_id_unit_measure_sel     => i_id_unit_measure_sel,
                                             i_tbtb_attribute          => i_tbtb_attribute,
                                             i_tbtb_free_text          => i_tbtb_free_text,
                                             i_id_edit_reason          => i_id_edit_reason,
                                             i_notes_edit              => i_notes_edit,
                                             o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    END edit_vital_sign;
    --
    /************************************************************************************************************
    * This function returns the last value registered by id_vital_sign, id_patient, date, used by CDS
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_patient             patient identifier
    * @param        i_id_vital_sign          vital sign identifier
    * @param        i_date                   filter date, bigger then  
    *
    * @param        o_info                   cursor out
    * @param        o_error                  error out
    *
    * @author                                Paulo Teixeira
    * @version                               2.6.3.14
    * @since                                 2014-03-25
    *
    * @dependencies                          CDS
    ************************************************************************************************************/
    FUNCTION get_last_vital_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_date          IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_LAST_VITAL_SIGN';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'PK_VITAL_SIGN_PBL.GET_LAST_VITAL_SIGN: ' || i_lang || '|' || i_prof.id || '|' ||
                     i_prof.institution || '|' || i_prof.software || '|' || i_id_patient || '|' || i_id_vital_sign || '|' ||
                     i_date;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
    
        OPEN o_info FOR
            SELECT t1.value,
                   t1.id_unit_measure,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_vs,
                   t1.dt_vital_sign_read_tstz
              FROM (SELECT row_number() over(ORDER BY t.dt_vital_sign_read_tstz DESC) rn,
                           t.value,
                           t.id_unit_measure,
                           t.id_vital_sign,
                           t.dt_vital_sign_read_tstz
                      FROM (SELECT nvl(vsr.value, vsr.id_vital_sign_desc) VALUE,
                                   vsr.id_unit_measure,
                                   vsr.dt_vital_sign_read_tstz,
                                   vsr.id_vital_sign
                              FROM vital_sign_read vsr
                             WHERE vsr.id_patient = i_id_patient
                               AND vsr.id_vital_sign = i_id_vital_sign
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND (i_date IS NULL OR vsr.dt_vital_sign_read_tstz >= i_date)) t) t1
              JOIN vital_sign vs
                ON vs.id_vital_sign = t1.id_vital_sign
             WHERE t1.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_last_vital_sign;
BEGIN
    -- Initializes log context
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);

END pk_vital_sign_pbl;
/
