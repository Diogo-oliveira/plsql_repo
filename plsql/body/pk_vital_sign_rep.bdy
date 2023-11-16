/*-- Last Change Revision: $Rev: 2027862 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_vital_sign_rep AS

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
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_val_vs     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_GRID_ALL';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_pbl.get_epis_vs_grid_all(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_flg_view   => i_flg_view,
                                                      i_scope      => i_scope,
                                                      i_scope_type => i_scope_type,
                                                      i_interval   => i_interval,
                                                      i_dt_begin   => i_dt_begin,
                                                      i_dt_end     => i_dt_end,
                                                      o_val_vs     => o_val_vs,
                                                      o_error      => o_error)
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
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_GRID_LIST';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_pbl.get_epis_vs_grid_list(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_flg_view   => i_flg_view,
                                                       i_flg_screen => i_flg_screen,
                                                       i_scope      => i_scope,
                                                       i_scope_type => i_scope_type,
                                                       i_interval   => i_interval,
                                                       i_dt_begin   => i_dt_begin,
                                                       i_dt_end     => i_dt_end,
                                                       o_time       => o_time,
                                                       o_sign_v     => o_sign_v,
                                                       o_error      => o_error)
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
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_notes_vs OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT obj_name := 'GET_EPIS_VS_NOTES';
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'get the number of vital sign records';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_vital_sign_pbl.get_epis_vs_notes(i_lang     => i_lang,
                                                   i_episode  => i_episode,
                                                   i_prof     => i_prof,
                                                   i_flg_view => i_flg_view,
                                                   i_start_date => i_start_date,
                                                   i_end_date   => i_end_date,
                                                   o_notes_vs => o_notes_vs,
                                                   o_error    => o_error)
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
        IF NOT pk_vital_sign_pbl.get_visit_cancelled_vital_sign(i_lang          => i_lang,
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
        IF NOT pk_vital_sign_pbl.get_visit_vital_sign_read_hist(i_lang        => i_lang,
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
    /**********************************************************************************************
    * get the patient last BMI values
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PAT_LST_IMC_VALUES';
        l_dbg_msg   debug_msg;
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'pk_vital_sign.get_pat_lst_imc_values';
        IF NOT pk_vital_sign.get_pat_lst_imc_values(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_patient => i_patient,
                                                    o_lst_imc => o_lst_imc,
                                                    o_error   => o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_lst_imc);
            RETURN FALSE;
    END get_pat_lst_imc_values;
    /************************************************************************************************************
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'get_vs_read_attributes';
        l_dbg_msg   debug_msg;
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'pk_vital_sign.get_vs_read_attributes';
        IF NOT pk_vital_sign_core.get_vs_read_attributes(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_vital_sign_read => i_id_vital_sign_read,
                                                         o_cursor             => o_cursor,
                                                         o_error              => o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_vs_read_attributes;
    /********************************************************************************************
    * Obter todos os SVs activos registados num episódio.Se há + do q 1 leitura do mesmo SV, retorna o + recente.
      Retorna tb os nomes e IDs dos SVs q ñ têm leitura neste episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:S- Resumo;
                                                          H - Saída de turno;
                                                          V1 - Grelha completa;
                                                          V2 - Grelha reduzida;
                                                          V3 - Biometria;
                                                          T - Triagem;
    * @param o_sign_v           Detalhe dos Sinais vitais na triagem
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/06/29
    * @notes                    Para além de apresentar os sinais vitais activos(+ recentes) do episódio,
                                também serão listados os sinais vitais que não existam no episódio mas
                                que deverão ser visualizados tendo em conta o parâmetro I_FLG_VIEW.
    ********************************************************************************************/
    FUNCTION get_epis_vs_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'get_epis_vs_grid';
        l_dbg_msg   debug_msg;
        l_exception EXCEPTION;
        l_patient patient.id_patient%TYPE;
        l_visit   visit.id_visit%TYPE;
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        IF i_start_date IS NOT NULL
        THEN
            -- Convert start date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            -- Convert end date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        l_patient := pk_episode.get_id_patient(i_episode => i_episode);
        l_visit   := pk_episode.get_id_visit(i_episode => i_episode);
    
        g_error := 'CALL PK_VITAL_SIGN.GET_EPIS_VS_GRID';
        OPEN o_sign_v FOR
            SELECT /*+opt_estimate (table vs rows=1)*/
             vs.id_vital_sign,
             vs.id_vital_sign_read,
             vsr.id_vital_sign_desc,
             vs.value,
             vs.desc_unit_measure,
             vs.pain_descr,
             vs.name_vs,
             pk_date_utils.date_chr_short_read_tsz(i_lang, vs.dt_vital_sign_read, i_prof) dt_read,
             pk_date_utils.date_char_hour_tsz(i_lang, vs.dt_vital_sign_read, i_prof.institution, i_prof.software) hour_read,
             pk_date_utils.date_send_tsz(i_lang, vs.dt_vital_sign_read, i_prof) short_dt_read,
             vsr.id_prof_read,
             pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_read) prof_read,
             pk_prof_utils.get_name_signature(i_lang, i_prof, vsr.id_prof_cancel) prof_cancel,
             vsr.notes_cancel,
             pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', vsr.flg_state, i_lang) desc_status,
             pk_date_utils.date_char_tsz(i_lang, vsr.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
             vs.rank,
             i.abbreviation instit,
             pk_prof_utils.get_spec_signature(i_lang,
                                              i_prof,
                                              vsr.id_prof_read,
                                              vsr.dt_vital_sign_read_tstz,
                                              vsr.id_episode) desc_speciality,
             pk_prof_utils.get_spec_signature(i_lang, i_prof, vsr.id_prof_cancel, vsr.dt_cancel_tstz, vsr.id_episode) desc_speciality_cancel
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, l_patient, l_visit, i_flg_view)) vs
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = vs.id_vital_sign_read
              LEFT JOIN institution i
                ON i.id_institution = vsr.id_institution_read
             WHERE (l_start_date IS NULL OR vs.dt_vital_sign_read >= l_start_date)
               AND (l_end_date IS NULL OR vs.dt_vital_sign_read < l_end_date)
             ORDER BY vs.rank, vs.name_vs;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_sign_v);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_sign_v);
            RETURN FALSE;
    END get_epis_vs_grid;
BEGIN
    -- Initializes log context
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);

END pk_vital_sign_rep;
/
