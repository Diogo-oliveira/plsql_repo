/*-- Last Change Revision: $Rev: 2055814 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2023-02-24 15:43:04 +0000 (sex, 24 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_out IS

    g_exception         EXCEPTION;
    g_exception_np      EXCEPTION;
    g_exception_control EXCEPTION;

    g_error         VARCHAR2(2000 CHAR);
    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_action              Action identifier
     *
     * @return                         action description
     *
     * @author                         Bruno Rego
     * @version                        1.0
     * @since                          2011/11/03
    **********************************************************************************************/
    FUNCTION get_action_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN r_action.id_action%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_action.get_action_desc(i_lang => i_lang, i_prof => i_prof, i_id_action => i_id_action);
    END;

    /******************************************************************************************
    * This function returns the translation for workflow id_status
    *
    * @param i_lang                                Input language
    * @param i_prof                                Input professional
    * @param i_id_status                           Input workflow id_status
    *
    * Returns the translated status            
    *
    * @author                Bruno Rego
    * @version               V.2.6.1
    * @since                 2011/09/08
    ********************************************************************************************/
    FUNCTION get_status_translation
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN wf_status.id_status%TYPE
    ) RETURN VARCHAR2 IS
        l_status_desc VARCHAR2(1000 CHAR);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, code_status)
          INTO l_status_desc
          FROM wf_status
         WHERE id_status = i_id_status;
    
        RETURN l_status_desc;
    
    END get_status_translation;

    /* Public Function. Call ins_log function from T_TI_LOG package
    *
    * @param      i_lang                Language for translation
    * @param      i_prof                Profissional type
    * @param      i_id_episode          Episode indetification
    * @param      i_flg_status          Status flag
    * @param      i_id_record           Record indentifier
    * @param      i_flg_type            Type flag
    * @param      o_error               Error message
    *
    * @return     TRUE for success and FALSE for error
    *
    * @author     Rui Spratley
    * @version    2.6.1.2
    * @since      2011/07/26
    */
    FUNCTION ins_log
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN r_ti_log.flg_status%TYPE,
        i_id_record  IN r_ti_log.id_record%TYPE,
        i_flg_type   IN r_ti_log.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => i_id_episode,
                                i_flg_status => i_flg_status,
                                i_id_record  => i_id_record,
                                i_flg_type   => i_flg_type,
                                o_error      => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END ins_log;

    /********************************************************************************************
    * GET_ID_SHORTCUT                  Gets the shortcut associated to the given intern_name
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Shortcut internal name
    * @param o_id_shortcut             Shortcut id
    * @param o_error                   Error message
    * 
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION get_id_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_intern_name IN sys_shortcut.intern_name%TYPE,
        o_id_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_access.get_id_shortcut(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_intern_name         => i_intern_name,
                                         i_flg_validate_parent => pk_alert_constant.g_no,
                                         o_id_shortcut         => o_id_shortcut,
                                         o_error               => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_id_shortcut;

    /********************************************************************************************
    * update_grid_task                 Update grid task string
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_grid_task               grid_task rowtype
    * @param o_error                   Error message
    * 
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION update_grid_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => i_grid_task, o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END update_grid_task;

    /********************************************************************************************
    * delete_epis_grid_task            Delete grid task string
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_episode                 Episode indetification
    * @param o_error                   Error message
    * 
    * @return                          true or false on success or error
    *
    * @author                          Rui Spratley
    * @version                         2.6.1.2
    * @since                           2011/07/27
    *
    **********************************************************************************************/
    FUNCTION delete_epis_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => i_episode, o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END delete_epis_grid_task;

    /**************************************************************************
    * This function will call the CO_SIGN task register function              *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_prof_dest  CoSign profissional identifier                      *
    * @param i_episode    Episode identifier                                  *
    * @param i_id_task    Prescription identifier                             *
    * @param i_dt_reg     Date of cosign request                              *
    * @param i_flg_type   Type of cosign (default 'P')                        *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/07/28                                                     *
    **************************************************************************/
    FUNCTION set_co_sign_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_task       IN co_sign_task.id_task%TYPE,
        i_dt_reg        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_type      IN co_sign_task.flg_type%TYPE DEFAULT 'P',
        i_id_order_type IN order_type.id_order_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_co_sign.set_co_sign_task(i_lang          => i_lang,
                                           i_prof          => i_prof,
                                           i_prof_dest     => i_prof_dest,
                                           i_episode       => i_episode,
                                           i_id_task       => i_id_task,
                                           i_flg_type      => i_flg_type,
                                           i_dt_reg        => i_dt_reg,
                                           i_id_order_type => i_id_order_type,
                                           o_error         => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END set_co_sign_task;

    /**************************************************************************
    * This function will call the CO_SIGN task remove function                *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_episode    Episode identifier                                  *
    * @param i_id_task    Prescription identifier                             *
    * @param i_flg_type   Type of cosign (default 'P')                        *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/07/28                                                     *
    **************************************************************************/
    FUNCTION remove_co_sign_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_id_task  IN co_sign_task.id_task%TYPE,
        i_flg_type IN co_sign_task.flg_type%TYPE DEFAULT 'P',
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_co_sign.remove_co_sign_task(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_id_task  => i_id_task,
                                              i_flg_type => i_flg_type,
                                              o_error    => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END remove_co_sign_task;

    /********************************************************************************************
    * get_justif_list                  Get Justification List
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_grid_task               grid_task rowtype
    * @param o_error                   Error message
    * 
    * @return                          true or false on success or error
    *
    * @author                          Pedro Teixeira
    * @version                         2.6.1.2
    * @since                           2011/08/05
    *
    **********************************************************************************************/
    FUNCTION get_justif_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
        -- this function should either pass to PK_LIST or use new medication model
        OPEN o_info FOR
            SELECT ji.id_justification    data,
                   ji.justification_descr label,
                   NULL                   TYPE,
                   NULL                   SUBTYPE,
                   NULL                   rank,
                   NULL                   VALUE,
                   NULL                   unit,
                   NULL                   unit_desc
              FROM mi_justification ji, drug_instit_justification dij
             WHERE dij.id_institution = i_prof.institution
               AND dij.id_software = i_prof.software
               AND dij.flg_type = 'F'
               AND ji.id_justification = dij.id_drug_justification
               AND ji.vers = l_version
             ORDER BY dij.rank, label;
    
        RETURN TRUE;
    END;

    /**************************************************************************
    * This function will call the CO_SIGN professionals list function         *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param i_episode    Episode identifier                                  *
    * @param o_prof_list  List of professionals available for co-sign         *
    * @param o_error      Error message                                       *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/29                                                     *
    **************************************************************************/
    FUNCTION get_co_sign_prof_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_prof_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_co_sign_api.get_prof_list(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            o_prof_list  => o_prof_list,
                                            o_error      => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_co_sign_prof_list;

    /**************************************************************************
    * This function will call the CO_SIGN professionals list function
    *
    * @param i_lang       The ID of the user language
    * @param i_prof       The profissional array
    * @param i_episode    Episode identifier
    * @param o_prof_list  List of professionals available for co-sign
    * @param o_error      Error message
    *
    *
    * @author  Pedro Teixeira
    * @since   2013/10/21
    **************************************************************************/
    FUNCTION get_co_sign_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_co_sign_api.get_prof_list(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_episode    => i_id_episode,
                                            i_id_order_type => i_id_order_type,
                                            o_prof_list     => o_prof_list,
                                            o_error         => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_co_sign_prof_list;

    /**************************************************************************
    * This function will call the CO_SIGN contact type list function          *
    *                                                                         *
    * @param i_lang       The ID of the user language                         *
    * @param i_prof       The profissional array                              *
    * @param o_order_type List of order types available for co-sign           *
    * @param o_error      Error message                                       *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/29                                                     *
    **************************************************************************/
    FUNCTION get_co_sign_order_type_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_co_sign_api.get_order_type(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             o_order_type => o_order_type,
                                             o_error      => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_co_sign_order_type_list;

    /**************************************************************************
    * This function will call the pk_sample_text.get_sample_text function     *
    * that will return the list of sample text to use on text fields          *
    *                                                                         *
    * @param i_lang               The ID of the user language                 *
    * @param i_sample_text_type   Sample text type                            *
    * @param i_patient            The patient identifier                      *
    * @param i_prof               The profissional array                      *
    * @param o_sample_text        List of sample texts                        *
    * @param o_error              Error message                               *
    *                                                                         *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 1.0                                                            *
    * @since   2011/08/31                                                     *
    **************************************************************************/
    FUNCTION get_most_frequent_texts
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_sample_text.get_sample_text(i_lang             => i_lang,
                                              i_sample_text_type => i_sample_text_type,
                                              i_patient          => i_patient,
                                              i_prof             => i_prof,
                                              o_sample_text      => o_sample_text,
                                              o_error            => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_most_frequent_texts;

    /********************************************************************************************
     * Get list of action information for a specified set of id_action's.
     * Based on get_actions function.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_action              id action
     *
     * @return                         The icon Name
     *
     * @author                         Pedro Quinteiro
     * @version                        2.6.1
     * @since                          12/09/2011
    **********************************************************************************************/
    FUNCTION get_action_icon_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN action.id_action%TYPE
    ) RETURN action.icon%TYPE IS
        l_error t_error_out;
    BEGIN
        pk_alertlog.log_debug('GET_ACTION_ICON_NAME');
    
        RETURN pk_action.get_action_icon_name(i_lang => i_lang, i_prof => i_prof, i_id_action => i_id_action);
    
    END get_action_icon_name;

    /******************************************************************************
    * Get the id_visit  given a episode
    * @param i_episode                                  IN: episode id  
    *    
    * @param o_error                                    OUT: error
    *********************************************************************************/
    FUNCTION get_visit
    (
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN visit.id_visit%TYPE IS
    BEGIN
        RETURN pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
    
    END get_visit;

    /**
    * Updates the prescription identifier used in the CDR engine.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_presc_old    outdated prescription identifier
    * @param i_presc_new    updated prescription identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2?
    * @since                2011/09/28
    */
    PROCEDURE set_cdr_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_presc_old IN cdr_call_det.id_task_request%TYPE,
        i_presc_new IN cdr_call_det.id_task_request%TYPE,
        o_error     OUT t_error_out
    ) IS
    BEGIN
        pk_cdr_fo_core.set_prescription(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_presc_old => i_presc_old,
                                        i_presc_new => i_presc_new,
                                        o_error     => o_error);
    END set_cdr_prescription;

    /******************************************************************************
    * Get reports list
    * @param i_lang             IN language id
    * @param i_prof             IN  profissional (id, institution, software)   
    * @param i_episode          IN  episode
    * @param i_screen_name      IN  screen name
    * @param i_sys_button_prop  IN  sys_button_prop
    *
    * @param o_reports          OUT report list
    * @param o_error            OUT error
    *    
    * @return                    boolean
    *
    * @author                    Pedro Quinteiro
    * @version                   2.6.1.2
    * @since                     2011/10/07
    *********************************************************************************/
    FUNCTION get_reports_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN NUMBER,
        i_area_report     IN VARCHAR2,
        i_screen_name     IN VARCHAR2,
        i_sys_button_prop IN NUMBER,
        i_task_type       IN table_number,
        i_context         IN table_varchar,
        o_reports         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'get_reports_list';
    BEGIN
    
        IF NOT pk_print_tool.get_reports_list(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_episode         => i_episode,
                                              i_area_report     => i_area_report,
                                              i_screen_name     => i_screen_name,
                                              i_sys_button_prop => i_sys_button_prop,
                                              i_task_type       => i_task_type,
                                              i_context         => i_context,
                                              o_reports         => o_reports,
                                              o_error           => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END get_reports_list;

    /**
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area.
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author   Eduardo Lourenço
    * @version  2.4.4
    * @since    2009/01/27
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_cancel_reason.get_cancel_reason_list(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_area    => i_area,
                                                       o_reasons => o_reasons,
                                                       o_error   => o_error);
    
    END;

    /********************************************************************************************
    -- função antiga utilizada para temporariamente efectuar associação de diagnósticos
    -- a ser eliminada quando disponibilizada função pela equipa EDIS 
    ********************************************************************************************/
    FUNCTION get_diag_problem_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_DIAG_PROBLEM_LIST';
    
        c_differ pk_types.cursor_type;
    
        l_id_diagnosis       table_number := table_number();
        l_desc_diagnosis     table_varchar := table_varchar();
        l_code_icd           table_varchar := table_varchar();
        l_id_alert_diagnosis table_number := table_number();
    BEGIN
        g_error := 'pk_supplies_api_db.get_supplies_list';
        IF NOT pk_diagnosis.get_associated_diagnosis(i_lang   => i_lang,
                                                     i_prof   => i_prof,
                                                     i_epis   => i_id_episode,
                                                     o_differ => c_differ,
                                                     o_error  => o_error)
        THEN
            RAISE g_exception;
        ELSE
            ----------------------------------------------------
            g_error := 'FETCH c_differ';
            FETCH c_differ BULK COLLECT
                INTO l_id_diagnosis, l_desc_diagnosis, l_code_icd, l_id_alert_diagnosis;
            CLOSE c_differ;
        
            ----------------------------------------------------
            -- this code is to add in the future the problems list
            OPEN o_info FOR
                SELECT t1.column_value data,
                       t2.column_value label,
                       'MC' TYPE,
                       NULL SUBTYPE,
                       NULL rank,
                       NULL VALUE,
                       NULL unit,
                       NULL unit_desc
                  FROM (SELECT rownum rnum, column_value
                          FROM TABLE(l_id_diagnosis)) t1,
                       (SELECT rownum rnum, column_value
                          FROM TABLE(l_desc_diagnosis)) t2
                 WHERE t1.rnum = t2.rnum
                UNION ALL
                SELECT 1485 data,
                       pk_translation.get_translation(i_lang, 'DIAGNOSIS.CODE_DIAGNOSIS.1485') label,
                       'MC' TYPE,
                       NULL SUBTYPE,
                       NULL rank,
                       NULL VALUE,
                       NULL unit,
                       NULL unit_desc
                  FROM dual
                UNION ALL
                SELECT 1489 data,
                       pk_translation.get_translation(i_lang, 'DIAGNOSIS.CODE_DIAGNOSIS.1489') label,
                       'MC' TYPE,
                       NULL SUBTYPE,
                       NULL rank,
                       NULL VALUE,
                       NULL unit,
                       NULL unit_desc
                  FROM dual;
        END IF;
    
        -- ainda falta código para ir buscar os problemas (para já só diagnósticos)
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_diag_problem_list;

    /********************************************************************************************
    -- função antiga utilizada para temporariamente efectuar associação de diagnósticos
    -- a ser eliminada quando disponibilizada função pela equipa EDIS 
    ********************************************************************************************/
    FUNCTION set_diag_problem
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_diagnosis IN table_number,
        i_id_problems  IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'SET_DIAG_PROBLEM';
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END set_diag_problem;

    /********************************************************************************************
    * Obter lista dos profissionais da instituição (para medicação)
    *
    * @param  i_lang                        The language ID
    * @param  i_prof                        The professional array
    * @param  o_error                       The error object
    *
    * @return boolean
    *
    * @author Pedro Teixeira
    * @since  23/05/2010
    *
    ********************************************************************************************/
    FUNCTION get_prof_med_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_category IN table_varchar,
        o_prof     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_list.get_prof_med_list(i_lang     => i_lang,
                                         i_prof     => i_prof,
                                         i_category => i_category,
                                         o_prof     => o_prof,
                                         o_error    => o_error);
    END;

    /********************************************************************************************
    * This function returns the id_software associated to a type of episode in an institution
    *                                                                                                                                          
    * @param i_epis_type              Type of episode
    * @param i_institution            Institution ID                                                                                              
    * @return                         Software ID                                                        
    *                                                                                                                          
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2008/11/10                                                                                               
    ********************************************************************************************/
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN epis_type_soft_inst.id_epis_type%TYPE,
        i_institution IN epis_type_soft_inst.id_institution%TYPE
        
    ) RETURN epis_type_soft_inst.id_software%TYPE IS
    BEGIN
        RETURN pk_episode.get_soft_by_epis_type(i_epis_type => i_epis_type, i_institution => i_institution);
    
    END;

    /*******************************************************************************************************************************************
    * Gets all the scales available for any given timeline                  
    *                                                                                                                                          
    * @param I_LANG                   Language ID                                                                           
    * @param I_PROF                   Professional information array                                
    * @param ID_TL_TIMELINE           Timeline ID                                                                                           
    * @param O_tl_timeline            Contains the scales available in the given timeline
    * @param O_ERROR                  Devolução do erro                                                                                        
    *                                                                                                                                          
    * @return                         False if an error occurs, true otherwise                                                      
    *                                                                                                                                          
    * @author                         Nelson Canastro                                                                                          
    * @version                         1.0                                                                                                     
    * @since                          15/02/2011                                                                                               
    *******************************************************************************************************************************************/
    FUNCTION get_timescale_by_tl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_tl_timeline IN tl_scale_inst_soft_market.id_tl_timeline%TYPE,
        o_tl_scales      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_timeline_core.get_timescale_by_tl(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_tl_timeline => i_id_tl_timeline,
                                                    o_tl_scales      => o_tl_scales,
                                                    o_error          => o_error);
    END;

    /**
    * Gets actions available for a given status of a given workflow
    *
    * @param   I_LANG             Language associated to the professional executing the request
    * @param   I_PROF             Professional, institution and software ids
    * @param   I_ID_WORKFLOW      Workflow identifier
    * @param   I_ID_STATUS_BEGIN  Begin action state 
    * @param   I_PARAMS           Params table_varchar for validateing transitions    
    * @param   I_VALIDATE_TRANS   Validates the possible status transitions
    * @param   I_SHOW_DISABLE     Shows or hides the disable actions (either user has no access to them or they are not valid for the given status)
    * @param   O_ACTIONS          actions
    *
    * @value   I_VALIDATE_TRANS   {*} Y - Validates the possible status transitions {*} N - Ignores transition validation
    * @value   I_SHOW_DISABLE     {*} Y - Shows actions not enabled for the user/current status {*} N - Hides actions not enabled for the user/current status
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Nelson Canastro
    * @version 2.6
    * @since   14-01-2011
    */
    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin      IN wf_status.id_status%TYPE,
        i_params               IN table_varchar,
        i_validate_trans       IN VARCHAR2,
        i_show_disable         IN VARCHAR2,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_workflow.get_actions(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_id_workflow          => i_id_workflow,
                                       i_id_status_begin      => i_id_status_begin,
                                       i_params               => i_params,
                                       i_validate_trans       => i_validate_trans,
                                       i_show_disable         => i_show_disable,
                                       i_class_origin         => i_class_origin,
                                       i_class_origin_context => i_class_origin_context,
                                       o_actions              => o_actions);
    
    END;

    /********************************************************************************************
    * Get actions based on the multiple subject and workflow
    * the inactive records are dominant and overlap active records (for the same ID_ACTION)
    *
    * @param  i_lang              The language ID
    * @param  i_prof              The professional array
    * @param  i_subject           Action Subject
    * @param  i_id_workflow       Workflow ID
    * @param  i_id_status_begin   Workflow Status
    * @param  i_params
    * @param  i_validate_trans    Flag that indicates if trans is to be validated
    * @param  i_show_disable      Flag indicating if disabled status is to be shown
    * @param  o_actions           Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    FUNCTION get_actions_subject
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_subject         IN action.subject%TYPE,
        i_id_workflow     IN table_number,
        i_id_status_begin IN table_number,
        i_params          IN table_varchar,
        i_validate_trans  IN VARCHAR2,
        i_show_disable    IN VARCHAR2,
        i_force_inactive  IN VARCHAR2,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_workflow.get_actions_subject(i_lang            => i_lang,
                                               i_prof            => i_prof,
                                               i_subject         => i_subject,
                                               i_id_workflow     => i_id_workflow,
                                               i_id_status_begin => i_id_status_begin,
                                               i_params          => i_params,
                                               i_validate_trans  => i_validate_trans,
                                               i_show_disable    => i_show_disable,
                                               i_force_inactive  => i_force_inactive,
                                               o_actions         => o_actions,
                                               o_error           => o_error);
    
    END;

    /**
    * Checks if transition is available (id_workflow, i_id_status_begin, i_id_status_end)
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status_begin      Begin status identifier
    * @param   i_id_status_begin      End status identifier
    * @param   i_id_workflow_action   Action identifier   
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    * @param   o_flg_available        Returns transition availability: {*} Y - transition available {*} N - otherwise
    * @param   o_transition           Transition identifier   
    * @param   o_error                An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   27-03-2009
    */
    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_transition_config.id_workflow%TYPE,
        i_id_status_begin     IN wf_transition.id_status_begin%TYPE,
        i_id_status_end       IN wf_transition.id_status_end%TYPE,
        i_id_workflow_action  IN wf_transition.id_workflow_action%TYPE,
        i_id_category         IN wf_transition_config.id_category%TYPE,
        i_id_profile_template IN wf_transition_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_transition_config.id_functionality%TYPE,
        i_param               IN table_varchar,
        i_validate_trans      IN VARCHAR2 DEFAULT pk_alert_constant.get_yes,
        o_flg_available       OUT NOCOPY VARCHAR2,
        o_error               OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_workflow.check_transition(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_workflow         => i_id_workflow,
                                            i_id_status_begin     => i_id_status_begin,
                                            i_id_status_end       => i_id_status_end,
                                            i_id_workflow_action  => i_id_workflow_action,
                                            i_id_category         => i_id_category,
                                            i_id_profile_template => i_id_profile_template,
                                            i_id_functionality    => i_id_functionality,
                                            i_param               => i_param,
                                            i_validate_trans      => i_validate_trans,
                                            o_flg_available       => o_flg_available,
                                            o_error               => o_error);
    
    END;

    PROCEDURE get_act_wf_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_actions              IN table_number,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2 DEFAULT NULL,
        i_class_origin_context IN VARCHAR2 DEFAULT NULL,
        o_actions              OUT pk_types.cursor_type
    ) IS
    BEGIN
        pk_workflow.get_act_wf_list(i_lang                 => i_lang,
                                    i_prof                 => i_prof,
                                    i_actions              => i_actions,
                                    i_workflows            => i_workflows,
                                    i_class_origin         => i_class_origin,
                                    i_class_origin_context => i_class_origin_context,
                                    o_actions              => o_actions);
    
    END;

    /********************************************************************************************
    * Get the final state based on workflow action, workflow identifier and initial state
    * NOTE: this function ONLY works when one action have ONLY one transition
    *
    * @param  i_lang                      The language ID
    * @param  i_prof                      The professional array
    * @param  i_id_wf_action              Workflow ID
    * @param  i_id_workflow               Workflow Status
    * @param  i_id_status_begin           Status Begin
    * @param  o_id_status_end             Output cursor with the printed and faxed groups
    *
    *
    * @author Pedro Teixeira
    * @since  11/04/2011
    *
    ********************************************************************************************/
    PROCEDURE get_wf_trans_status_end
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_wf_action    IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_workflow     IN wf_workflow.id_workflow%TYPE,
        i_id_status_begin IN wf_status.id_status%TYPE,
        o_id_status_end   OUT wf_status.id_status%TYPE
    ) IS
    BEGIN
        pk_workflow.get_wf_trans_status_end(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_wf_action    => i_id_wf_action,
                                            i_id_workflow     => i_id_workflow,
                                            i_id_status_begin => i_id_status_begin,
                                            o_id_status_end   => o_id_status_end);
    
    END;

    FUNCTION get_actions_by_wf
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_workflow.get_actions_by_wf(i_lang                 => i_lang,
                                             i_prof                 => i_prof,
                                             i_workflows            => i_workflows,
                                             i_class_origin         => i_class_origin,
                                             i_class_origin_context => i_class_origin_context,
                                             o_actions              => o_actions);
    
    END;

    /**
    * Get status color
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    * @param   i_id_status            Status identifier
    * @param   i_id_category          Category identifier
    * @param   i_id_profile_template  Profile template identifier
    * @param   i_id_functionality     Professional functionality
    * @param   i_param                General parameter (for function evaluation)
    *
    * @RETURN  Status color
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_color
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN wf_status_workflow.id_workflow%TYPE,
        i_id_status           IN wf_status_workflow.id_status%TYPE,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_param               IN table_varchar
    ) RETURN VARCHAR2 IS
    
    BEGIN
        RETURN pk_workflow.get_status_color(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_workflow         => i_id_workflow,
                                            i_id_status           => i_id_status,
                                            i_id_category         => i_id_category,
                                            i_id_profile_template => i_id_profile_template,
                                            i_id_functionality    => i_id_functionality,
                                            i_param               => i_param);
    END;

    /**
    * Get the begining status of workflow
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identifier
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-04-2009
    */
    FUNCTION get_status_begin
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_workflow  IN wf_status_workflow.id_workflow%TYPE,
        o_status_begin OUT NOCOPY wf_status_workflow.id_status%TYPE,
        o_error        OUT NOCOPY t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_workflow.get_status_begin(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_id_workflow  => i_id_workflow,
                                            o_status_begin => o_status_begin,
                                            o_error        => o_error);
    END;

    /********************************************************************************************
    * Returns an array with all professsional from the same dep_clin_serv of the current professional
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    *
    *
    * @author                          Elisabete Bugalho
    * @version                         2.6.1.2
    * @since                           2011/10/10
    *
    **********************************************************************************************/
    FUNCTION get_prof_dcs_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
    
    BEGIN
        RETURN pk_prof_utils.get_prof_dcs_list(i_lang => i_lang, i_prof => i_prof);
    
    END get_prof_dcs_list;
    /********************************************************************************************
    * Returns problems
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_pat                     patient identifier
    * @param i_status                  flag status
    * @param i_type                    type
    * @param i_problem                 problem id
    * @param i_episode                 episode identifier
    * @param i_report                  report flag
    * @param i_dt_ini                  init date
    * @param i_dt_end                  end date
    *
    * @author                          Paulo Teixeira
    * @version                         2.6.1.2
    * @since                           2011/10/12
    *
    **********************************************************************************************/
    FUNCTION get_pat_problem_tf
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat     IN pat_history_diagnosis.id_patient%TYPE,
        i_status  IN table_varchar,
        i_type    IN VARCHAR2,
        i_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_episode IN pat_problem.id_episode%TYPE,
        i_report  IN VARCHAR2,
        i_dt_ini  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end  IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pk_problems.pat_problem_table
        PIPELINED IS
    BEGIN
    
        FOR row_i IN (SELECT *
                        FROM TABLE(pk_problems.get_pat_problem_tf(i_lang,
                                                                  i_prof,
                                                                  i_pat,
                                                                  i_status,
                                                                  i_type,
                                                                  i_problem,
                                                                  i_episode,
                                                                  i_report,
                                                                  i_dt_ini,
                                                                  i_dt_end)))
        LOOP
            PIPE ROW(row_i);
        END LOOP;
    
        RETURN;
    END get_pat_problem_tf;

    /** @headcom
    * Public Function. Returns market for given institution.
    *
    * @param      I_institution              ID of instituition
    *
    * @return     number
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2009/11/04
    */
    FUNCTION get_inst_mkt(i_id_institution IN institution.id_institution%TYPE) RETURN market.id_market%TYPE IS
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_id_institution);
    
        RETURN l_id_market;
    END get_inst_mkt;

    /**
    * List associations between allergies and products.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_allergies    allergy identifiers list
    * @param o_allg_prod    data cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/17
    */
    FUNCTION get_products
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_allergies IN table_number,
        o_allg_prod OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_allergy.get_products(i_lang      => i_lang,
                                       i_prof      => i_prof,
                                       i_allergies => i_allergies,
                                       o_allg_prod => o_allg_prod,
                                       o_error     => o_error);
    END get_products;

    /********************************************************************************************
    * Get id of the report for a specific market, institution, software and type of prescription
    *
    *
    * @author Pedro Teixeira
    * @since  23/12/2011
    *
    ********************************************************************************************/
    FUNCTION get_rep_prescription_match
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_presc_type          IN VARCHAR2,
        i_drug_type           IN VARCHAR2,
        i_id_product          IN table_varchar,
        i_id_product_supplier IN table_varchar,
        o_id_reports          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_REP_PRESCRIPTION_MATCH';
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_rep_prescription_match;

    /**
    * List associations between allergies and products.
    *
    * @param i_lang         language identifier
    * @param o_cursor    symptoms_list
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Quinteiro
    * @version               2.6.2
    * @since                2012/02/01
    */
    FUNCTION get_symptoms_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_symptoms_list';
    BEGIN
        RETURN pk_allergy.get_symptoms_list(i_lang => i_lang, o_cursor => o_cursor, o_error => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_symptoms_list;

    /**********************************************************************************************
    * DELETE_DRUG_PRESC_FIELD         Forces the deletion of DRUG_PRESC field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @version                        2.6.2
    * @since                          15/02/2012
    * @alteration                     
    **********************************************************************************************/
    FUNCTION grid_task_del_drug_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GRID_TASK_DEL_DRUG_PRESC';
    BEGIN
        RETURN pk_grid.delete_drug_presc_field(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_episode => i_id_episode,
                                               o_error      => o_error);
    END grid_task_del_drug_presc;

    /********************************************************************************************
    * validar se o perfil tem ou não permissão requisitar sem co-sign 
    
    * @param i_lang                   The language ID
    * @param o_prof                   Cursor containing the professional list 
    
    * @param i_flg_type               Devolve Y ou N                                      
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Sílvia Freitas
    * @since                          2007/08/30
    **********************************************************************************************/
    FUNCTION get_date_time_stamp_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_co_sign.get_date_time_stamp_req(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  o_flg_show => o_flg_show,
                                                  o_error    => o_error);
    
    END;

    /********************************************************************************************
    * Actualizar tabelas EA no delete_presc
    * @param i_lang                   The language ID
    * @param i_prof                   Cursor containing the professional list 
    * @param i_id_patient             patient
    * @param i_num_med    IN NUMBER,
    * @param i_desc_med   IN VARCHAR2,
    * @param i_code_med   IN VARCHAR2,
    * @param i_dt_med     IN TIMESTAMP WITH LOCAL TIME ZONE
    * 
    * @author                         Pedro Morais
    * @since                          2012/07/10
    **********************************************************************************************/
    PROCEDURE update_ea_for_deleted_rows
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_num_med    IN NUMBER,
        i_desc_med   IN VARCHAR2,
        i_code_med   IN VARCHAR2,
        i_dt_med     IN TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_rowids table_varchar;
    BEGIN
        g_error := 'call ts_viewer_ehr_ea.upd';
        ts_viewer_ehr_ea.upd(id_patient_in => i_id_patient,
                             num_med_in    => i_num_med,
                             desc_med_in   => i_desc_med,
                             desc_med_nin  => FALSE,
                             code_med_in   => i_code_med,
                             code_med_nin  => FALSE,
                             dt_med_in     => i_dt_med,
                             dt_med_nin    => FALSE,
                             rows_out      => l_rowids);
    END update_ea_for_deleted_rows;

    /**********************************************************************************************
    * Registers the consumption of supplies in the prescription administration
    * 
    * @i_lang               Language ID
    * @i_prof               Professional's info
    * @i_id_episode         Episode ID
    * @i_id_context         Context ID
    * @i_flg_context        Flag for context
    * @i_id_supply_workflow Workflow IDs
    * @i_supply             Supplies' IDs
    * @i_supply_set         Parent supply set (if applicable)
    * @i_supply_qty         Supply quantities
    * @i_flg_supply_type    Supply or supply Kit
    * @i_barcode_scanned    Barcode scanned
    * @i_deliver_needed     Deliver needed
    * @i_flg_cons_type      Consumption type
    * i_dt_expected_date    Expected return date
    * @o_error              Error info
    * 
    * @return               True on success, false on error
    * 
    * @author               Rita Lopes
    * @version              2.6.2
    * @since                2012/10/02
    **********************************************************************************************/
    FUNCTION create_sup_consumption
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        i_flg_context        IN supply_workflow.flg_context%TYPE,
        i_id_supply_workflow IN table_number,
        i_supply             IN table_number,
        i_supply_set         IN table_number,
        i_supply_qty         IN table_number,
        i_flg_supply_type    IN table_varchar,
        i_barcode_scanned    IN table_varchar,
        i_deliver_needed     IN table_varchar,
        i_flg_cons_type      IN table_varchar,
        i_notes              IN table_varchar,
        i_dt_expiration      IN table_varchar,
        i_flg_validation     IN table_varchar,
        i_lot                IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PK_SUPPLIES_API_DB.CREATE_SUP_CONSUMPTION');
        IF NOT pk_supplies_api_db.set_supply_consumption(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_id_episode         => i_id_episode,
                                                         i_id_context         => i_id_context,
                                                         i_flg_context        => i_flg_context,
                                                         i_id_supply_workflow => i_id_supply_workflow,
                                                         i_supply             => i_supply,
                                                         i_supply_set         => i_supply_set,
                                                         i_supply_qty         => i_supply_qty,
                                                         i_flg_supply_type    => i_flg_supply_type,
                                                         i_barcode_scanned    => i_barcode_scanned,
                                                         i_fixed_asset_number => NULL,
                                                         i_deliver_needed     => i_deliver_needed,
                                                         i_flg_cons_type      => i_flg_cons_type,
                                                         i_notes              => i_notes,
                                                         i_dt_expected_date   => NULL,
                                                         i_check_quantities   => pk_alert_constant.g_no,
                                                         i_dt_expiration      => i_dt_expiration,
                                                         i_flg_validation     => i_flg_validation,
                                                         i_lot                => i_lot,
                                                         o_error              => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END create_sup_consumption;

    /********************************************************************************************
    * Procedure to update task_timeline_ea with information regarding reconciliation information
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_EPISODE               The episode id
    * @param   I_ID_PATIENT               The patient id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             true or false, if error wasn't found or not
    *
    * @author                             Pedro Teixeira
    * @version                            2.6.2
    *
    **********************************************************************************************/
    FUNCTION update_task_tl_recon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN episode.id_patient%TYPE,
        i_id_presc        IN NUMBER,
        i_dt_req          IN episode.dt_begin_tstz%TYPE,
        i_id_prof_req     IN episode.id_prof_cancel%TYPE,
        i_id_institution  IN episode.id_institution%TYPE,
        i_event_type      IN VARCHAR2,
        i_id_tl_task      IN NUMBER,
        i_id_prev_tl_task IN NUMBER DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_ea_logic_medication.update_task_tl_recon(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_id_episode      => i_id_episode,
                                                           i_id_patient      => i_id_patient,
                                                           i_id_presc        => i_id_presc,
                                                           i_dt_req          => i_dt_req,
                                                           i_id_prof_req     => i_id_prof_req,
                                                           i_id_institution  => i_id_institution,
                                                           i_event_type      => i_event_type,
                                                           i_id_tl_task      => i_id_tl_task,
                                                           i_id_prev_tl_task => i_id_prev_tl_task,
                                                           o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END update_task_tl_recon;

    FUNCTION set_procedure_with_medication
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_intervention IN table_number,
        i_flg_time     IN interv_prescription.flg_time%TYPE,
        i_dt_begin     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_medication   IN NUMBER,
        i_notes        IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.SET_PROCEDURE_WITH_MEDICATION';
        IF NOT pk_procedures_external_api_db.set_procedure_with_medication(i_lang         => i_lang,
                                                                           i_prof         => i_prof,
                                                                           i_patient      => i_patient,
                                                                           i_episode      => i_episode,
                                                                           i_intervention => i_intervention,
                                                                           i_flg_time     => i_flg_time,
                                                                           i_dt_begin     => i_dt_begin,
                                                                           i_medication   => i_medication,
                                                                           i_notes        => i_notes,
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
                                              'SET_PROCEDURE_WITH_MEDICATION',
                                              o_error);
            RETURN FALSE;
    END set_procedure_with_medication;

    /********************************************************************************************
    * Returns a string with supplies info 
    *
    * @param   I_LANG                     language associated to the professional executing the request
    * @param   I_PROF                     professional, institution and software ids
    * @param   I_ID_CONTEXT               The context id
    * @param   I_FLG_CONTEXT              The flg context id
    * @param   O_ERROR                    error information
    *
    * @RETURN                             VARCHAR
    *
    * @author                             Rita Lopes
    * @version                            2.6.3
    *
    **********************************************************************************************/
    FUNCTION get_count_supplies_str_all
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_context               IN supply_context.id_context%TYPE,
        i_flg_context              IN supply_context.flg_context%TYPE,
        i_flg_filter_type          IN VARCHAR2 DEFAULT 'A',
        i_flg_status               IN VARCHAR2 DEFAULT NULL,
        i_flg_show_set_description IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_supplies_external_api_db.get_count_supplies_str_all(i_lang                     => i_lang,
                                                                      i_prof                     => i_prof,
                                                                      i_id_context               => i_id_context,
                                                                      i_flg_context              => i_flg_context,
                                                                      i_flg_filter_type          => i_flg_filter_type,
                                                                      i_flg_status               => i_flg_status,
                                                                      i_flg_show_set_description => i_flg_show_set_description);
    
    END get_count_supplies_str_all;

    /********************************************************************************************
    * Returns Y if current professional has cosign; N otherwise
    *
    * @param   i_lang                     language associated to the professional executing the request
    * @param   i_prof                     professional, institution and software ids
    *
    * @RETURN                             VARCHAR
    *
    * @author                             Rui Mendonça
    * @version                            2.6.3.1
    **********************************************************************************************/
    FUNCTION get_cosign_config
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_flg_show VARCHAR2(1 CHAR);
        l_error    t_error_out;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_COSIGN_CONFIG';
    BEGIN
    
        IF NOT pk_co_sign.get_date_time_stamp_req(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  o_flg_show => l_flg_show,
                                                  o_error    => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_flg_show;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
    END get_cosign_config;

    FUNCTION get_witness_prof_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_header_messages OUT pk_types.cursor_type,
        o_prof_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_template table_number;
    
    BEGIN
    
        l_prof_template := table_number();
    
        SELECT id_profile_template
          BULK COLLECT
          INTO l_prof_template
          FROM prof_profile_template ppt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution;
    
        OPEN o_prof_list FOR
            SELECT id_prof_witness AS prof_id,
                   pk_finger_print.get_desc_user(id_prof_witness, i_lang) AS prof_login,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(id_prof_witness, id_institution, 0),
                                                    id_prof_witness) AS prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    profissional(id_prof_witness, id_institution, 0),
                                                    id_prof_witness,
                                                    NULL,
                                                    NULL) AS prof_speciality,
                   pk_profphoto.get_prof_photo(profissional(id_prof_witness, id_institution, 0)) AS prof_photo
              FROM ((SELECT id_prof_witness, pw.id_institution
                       FROM prof_drug_witness_inst_dcs pw
                      WHERE pw.id_institution = i_prof.institution
                        AND decode(pw.id_software, 0, i_prof.software, pw.id_software) = i_prof.software
                        AND (pw.id_dep_clin_serv IN
                            (SELECT pdcs.id_dep_clin_serv
                                FROM prof_dep_clin_serv pdcs
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.flg_status = 'S'
                                 AND pdcs.id_institution = i_prof.institution) OR
                            pw.id_prof_template_witnessed IN
                            (SELECT column_value
                                FROM TABLE(l_prof_template)) OR pw.id_prof_witnessed = i_prof.id)
                     UNION ALL
                     SELECT id_prof_witness, pw.id_institution
                       FROM prof_drug_witness_inst_dcs pw
                      WHERE pw.id_institution = i_prof.institution
                        AND decode(pw.id_software, 0, i_prof.software, pw.id_software) = i_prof.software
                        AND pw.id_dep_clin_serv IS NULL
                        AND pw.id_prof_template_witnessed IS NULL
                        AND pw.id_prof_witnessed IS NULL) MINUS SELECT i_prof.id AS id_prof_witness, i_prof.institution
                    id_institution FROM dual)
             ORDER BY prof_name;
    
        OPEN o_header_messages FOR
            SELECT pk_message.get_message(i_lang, 'PRESCRIPTION_TITLE_001') AS wdw_main_title,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T036') AS wdw_header,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T037') AS wdw_text1,
                   pk_message.get_message(i_lang, 'DRUG_FLUIDS_T015') AS wdw_list_title,
                   pk_message.get_message(i_lang, 'PHARM_T009') || '|' ||
                   pk_message.get_message(i_lang, 'PRESCRIPTION_TITLE_002') AS wdw_list_subtitle,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_TITLE_005') AS wdw_auth_title,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T041') AS wdw_auth_opt1,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T042') AS wdw_auth_opt2,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T038') AS wdw_auth_2,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T039') AS wdw_auth_3,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T040') AS wdw_auth_4,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T043') AS wdw_auth_5,
                   pk_message.get_message(i_lang, 'COMMON_M025') AS bttn_cancel,
                   pk_message.get_message(i_lang, 'COMMON_M087') AS bttn_confirm,
                   pk_message.get_message(i_lang, 'COMMON_T013') AS wdw_auth_6,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_T044') AS wdw_auth_7,
                   pk_message.get_message(i_lang, 'PRESCRIPTION_REC_M030') AS wdw_search
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PRESCRIPTION_INT',
                                              'GET_WITNESS_PROF_LIST',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_prof_list);
            pk_types.open_my_cursor(o_header_messages);
            RETURN FALSE;
        
    END get_witness_prof_list;

    /********************************************************************************************
    * List all patient's response to treatment  
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_treat                  id_treatment (id prescription)
    * @param o_treat_manag            Patient's response to treatment 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013/06/05 
    *
    **********************************************************************************************/
    FUNCTION get_treat_manag_presc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_treatment IN treatment_management.id_treatment%TYPE,
        o_treat     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error t_error_out;
    BEGIN
    
        IF NOT pk_medical_decision.get_treat_manag_presc(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_treatment => i_treatment,
                                                         o_treat     => o_treat,
                                                         o_error     => l_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    END;

    FUNCTION get_list_prof_dcs
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
        l_error t_error_out;
    BEGIN
    
        RETURN pk_prof_utils.get_list_prof_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, o_error => l_error);
    
    END get_list_prof_dcs;

    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN NUMBER IS
    BEGIN
        RETURN pk_tools.get_prof_profile_template(i_prof => i_prof);
    
    END get_prof_profile_template;

    --*************************************************
    FUNCTION get_prof_login
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_login.get_prof_login(i_lang, i_prof_id);
    
    END get_prof_login;

    FUNCTION get_prof_photo(i_prof IN profissional) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_profphoto.get_prof_photo(i_prof);
    
    END get_prof_photo;

    /** @clone_contraindications
    * Public procedure. clones data from given medication Id to other medication ID
    *   Tables cloned:  CDR_INSTANCE, CDR_INST_PARAM, CDR_INST_PAR_VAL,
    *                   CDR_INST_PAR_ACTION, CDR_INST_PAR_ACT_VAL
    *
    * @param    i_prof                  info of professional used
    * @param    i_old_cds_product       id of old product ( already formatted )
    * @param    i_new_cds_product       id of new product ( already formatted )
    *
    * @author     Carlos Ferreira
    * @version    1.0
    * @since      2014/02/25
    */
    PROCEDURE clone_contraindications
    (
        i_prof            IN profissional,
        i_old_cds_product IN VARCHAR2,
        i_new_cds_product IN VARCHAR2
    ) IS
    BEGIN
    
        pk_cdr_interface.clone_contraindications(i_prof            => i_prof,
                                                 i_old_cds_product => i_old_cds_product,
                                                 i_new_cds_product => i_new_cds_product);
    
    END clone_contraindications;

    /*********************************************************************************************
    * Returns the institutions associated to a given market
    * 
    * @param         i_lang                user language
    * @param         i_id_market           Market ID
    *
    * @param         o_institution         institution ids
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Sofia Mendes
    * @version       2.6.3.13
    * @date          17-Mar-2014
    ********************************************************************************************/
    FUNCTION get_institutions_by_mkt
    (
        i_lang        IN language.id_language%TYPE,
        i_id_market   IN institution.id_market%TYPE,
        o_institution OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_utils.get_institutions_by_mkt(i_lang        => i_lang,
                                                i_id_market   => i_id_market,
                                                o_institution => o_institution,
                                                o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    END get_institutions_by_mkt;

    /*********************************************************************************************
    * Returns the institutions associated to a given market
    * 
    * @param         i_lang                user language
    * @param         i_prof                professional, institution and software ids
    * @param         i_id_patient          Patient ID
    * @param         i_id_episode          Episode ID
    * @param         i_barcode             Patient Barcode
    *
    * @param         o_summary             Validation description
    * @param         o_result              Validation result
    * @param         o_error               data structure containing details of the error occurred
    *
    * @return        boolean indicating the occurrence of an error (TRUE means no error)
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          25-Mar-2014
    ********************************************************************************************/
    FUNCTION validate_patient_barcode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_barcode    IN VARCHAR2,
        o_summary    OUT VARCHAR2,
        o_result     OUT VARCHAR2,
        o_patient    OUT patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_barcode.validate_patient_barcode(i_lang => i_lang,
                                                   
                                                   i_prof       => i_prof,
                                                   i_id_patient => i_id_patient,
                                                   i_id_episode => i_id_episode,
                                                   i_barcode    => i_barcode,
                                                   o_summary    => o_summary,
                                                   o_result     => o_result,
                                                   o_patient    => o_patient,
                                                   o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END validate_patient_barcode;

    /*********************************************************************************************
    * Returns the patient info
    * 
    * @param i_lang             The ID of the user language
    * @param i_id_pat           Patient ID
    * @param i_prof             The profissional array
    *
    * @param o_name             Patient name
    * @param o_nick_name        Patient nick name
    * @param o_gender           Patient gender
    * @param o_dt_birth         Patient date of birth
    * @param o_age              Patient current age
    * @param o_dt_deceased      Patient decease date
    * @param o_error            Error message
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_nick_name   OUT patient.nick_name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_dt_birth    OUT VARCHAR2,
        o_age         OUT VARCHAR2,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_patient.get_pat_info(i_lang        => i_lang,
                                       i_id_pat      => i_id_pat,
                                       i_prof        => i_prof,
                                       o_name        => o_name,
                                       o_nick_name   => o_nick_name,
                                       o_gender      => o_gender,
                                       o_dt_birth    => o_dt_birth,
                                       o_age         => o_age,
                                       o_dt_deceased => o_dt_deceased,
                                       o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_pat_info;

    /*********************************************************************************************
    * Returns the patient episode number
    * 
    * @param i_lang             The ID of the user language
    * @param i_id_episode       Episode ID
    * @param i_prof             The profissional array
    *
    * @param o_episode          Episode ID
    * @param o_error            Error message
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_epis_ext
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_episode    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_efectiv VARCHAR2(200 CHAR);
        l_dt_atend   VARCHAR2(200 CHAR);
    BEGIN
    
        IF NOT pk_episode.get_epis_ext(i_lang       => i_lang,
                                       i_id_episode => i_id_episode,
                                       i_prof       => i_prof,
                                       o_dt_efectiv => l_dt_efectiv,
                                       o_dt_atend   => l_dt_atend,
                                       o_episode    => o_episode,
                                       o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_epis_ext;

    /*********************************************************************************************
    * Returns the patient process
    * 
    * @param i_lang             The ID of the user language
    * @param i_prof             The profissional array
    * @param i_id_patient       Patient ID
    *
    * @author        Sérgio Cunha
    * @version       2.6.4
    * @date          2014/03/25
    ********************************************************************************************/
    FUNCTION get_process
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
    BEGIN
    
        RETURN pk_hea_prv_aux.get_process(i_lang              => i_lang,
                                          i_prof              => i_prof,
                                          i_id_patient        => i_id_patient,
                                          i_id_pat_identifier => NULL);
    
    END get_process;

    FUNCTION get_show_content_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_have_permission OUT sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_content_button_ux.get_show_content_button(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_task_type    => i_id_task_type,
                                                            o_have_permission => o_have_permission,
                                                            o_error           => o_error);
    
    END get_show_content_button;

    FUNCTION get_prof_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => i_prof_id);
    END get_prof_name;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION add_print_jobs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_print_list_areas IN table_number,
        i_context_data     IN table_clob,
        i_print_arguments  IN table_varchar,
        o_print_list_jobs  OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'ADD_PRINT_JOBS';
    
    BEGIN
    
        g_error := 'Call pk_pha_search.get_pat_criteria_inactive_clin';
        RETURN pk_print_list_db.add_print_jobs(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_patient          => i_patient,
                                               i_episode          => i_episode,
                                               i_print_list_areas => i_print_list_areas,
                                               i_context_data     => i_context_data,
                                               i_print_arguments  => i_print_arguments,
                                               o_print_list_jobs  => o_print_list_jobs,
                                               o_error            => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_print_jobs;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION remove_print_jobs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_print_list_area IN print_list_area.id_print_list_area%TYPE,
        i_context_data    IN CLOB,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'REMOVE_PRINT_JOBS';
    
        l_id_print_list_jobs table_number;
    BEGIN
        -- remove from print list (if exists)
        -- getting id_print_list_job related to this presc/medication
        g_error              := 'Call pk_print_list_db.get_similar_print_list_jobs from pk_api_pfh_out.remove_print_jobs';
        l_id_print_list_jobs := pk_print_list_db.get_similar_print_list_jobs(i_lang                   => i_lang,
                                                                             i_prof                   => i_prof,
                                                                             i_patient                => i_patient,
                                                                             i_episode                => i_episode,
                                                                             i_print_list_area        => nvl(i_print_list_area,
                                                                                                             pk_print_list_db.g_print_list_area_med),
                                                                             i_print_job_context_data => to_clob(i_context_data));
    
        -- if print list job exists, then delete it
        IF l_id_print_list_jobs IS NOT NULL
           AND l_id_print_list_jobs.count > 0
        THEN
        
            g_error := 'Call pk_print_list_db.set_print_jobs_cancel from pk_api_pfh_out.remove_print_jobs';
            IF NOT pk_print_list_db.set_print_jobs_cancel(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_id_print_list_job => l_id_print_list_jobs,
                                                          o_id_print_list_job => o_print_list_jobs,
                                                          o_error             => o_error)
            THEN
                RAISE g_exception_np;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END remove_print_jobs;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION cancel_pg_print_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_presc_list   IN table_number,
        o_print_list_jobs OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CANCEL_PG_PRINT_LIST';
    
        --l_id_print_list_jobs table_number;
        l_delim       VARCHAR2(1 CHAR) := '|';
        l_delim_presc VARCHAR2(1 CHAR) := ',';
    
        l_context_data_elements table_varchar := table_varchar();
        l_id_presc              table_number := table_number();
        l_context_intersect     table_number := table_number();
    
        CURSOR c_pl_context IS
            SELECT plcd.id_print_list_job, plcd.context_data
              FROM v_print_list_context_data plcd
             WHERE plcd.id_print_list_area = pk_print_list_db.g_print_list_area_med
               AND plcd.id_patient = i_id_patient
               AND plcd.id_episode = i_id_episode;
    BEGIN
        -- verify if input is valid
        IF nvl(cardinality(i_id_presc_list), 0) != 0
        THEN
            -- for each element in c_pl_context
            FOR l_pl_context IN c_pl_context
            LOOP
                IF l_pl_context.context_data IS NOT NULL
                THEN
                    -- split context data
                    l_context_data_elements := pk_utils.str_split_l(i_list  => l_pl_context.context_data,
                                                                    i_delim => l_delim);
                    l_id_presc              := table_number();
                
                    -- obtain presc ids
                    IF l_context_data_elements.count >= 2 -- at least two elements needed: id_workflow | list_of_id_prescs
                    THEN
                        l_id_presc := pk_utils.str_split_n(i_list  => l_context_data_elements(2),
                                                           i_delim => l_delim_presc); -- prescs separated by ','
                    END IF;
                
                    -- if context presc number is the same as input presc number verify id they are the same
                    IF cardinality(l_id_presc) = cardinality(i_id_presc_list)
                    THEN
                        l_context_intersect := table_number();
                        l_context_intersect := i_id_presc_list MULTISET INTERSECT l_id_presc;
                    
                        -- if presc lists are equal
                        IF cardinality(l_context_intersect) = cardinality(i_id_presc_list)
                        THEN
                            IF NOT pk_print_list_db.set_print_jobs_cancel(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_id_print_list_job => table_number(l_pl_context.id_print_list_job),
                                                                          o_id_print_list_job => o_print_list_jobs,
                                                                          o_error             => o_error)
                            THEN
                                RAISE g_exception_np;
                            ELSE
                                RETURN TRUE;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_pg_print_list;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_patient_scheds
    (
        i_id_institution IN NUMBER,
        i_id_patient     IN sch_group.id_patient%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_schedule.get_patient_scheds(i_lang       => 2,
                                              i_prof       => profissional(0, 1, 1),
                                              i_id_patient => i_id_patient,
                                              o_list       => o_list,
                                              o_error      => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_patient_scheds;

    FUNCTION get_prof_responsibles
    (
        i_id_institution IN NUMBER,
        i_id_patient     IN sch_group.id_patient%TYPE,
        o_prof_resp      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_hand_off.get_prof_responsibles(i_lang      => 2,
                                                 i_prof      => profissional(0, 1, 1),
                                                 i_scope     => 'P',
                                                 i_id_scope  => i_id_patient,
                                                 o_prof_resp => o_prof_resp,
                                                 o_error     => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    END get_prof_responsibles;

    /*********************************************************************************************
    *********************************************************************************************/
    FUNCTION get_medication_print_poput_opt
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_poput_opt OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_MEDICATION_PRINT_POPUT_OPT';
    
        l_sys_list_group sys_list_group.internal_name%TYPE := 'MEDICATION_PRINT_POPUT_OPT';
        l_default_option sys_list.internal_name%TYPE;
    BEGIN
        -- get default action
        IF NOT pk_print_list_db.get_print_list_def_option(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_print_list_area => pk_print_list_db.g_print_list_area_med,
                                                          o_default_option  => l_default_option,
                                                          o_error           => o_error)
        THEN
            l_default_option := 'SAVE';
        END IF;
    
        -- get popup list
        g_error := 'Open o_poput_opt in MEDICATION_PRINT_POPUT_OPT';
        OPEN o_poput_opt FOR
            SELECT desc_list desc_option,
                   flg_context val_option,
                   decode(sys_list_internal_name, l_default_option, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default
              FROM TABLE(CAST(pk_sys_list.tf_sys_list_values(i_lang          => i_lang,
                                                             i_prof          => i_prof,
                                                             i_internal_name => l_sys_list_group) AS t_table_sys_list)) tt
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_medication_print_poput_opt;

    /*********************************************************************************************
    * Sets episode 1st observation
    * 
    * @author        Sofia Mendes
    * @version       2.6.4
    * @date          2014/11/11
    ********************************************************************************************/
    FUNCTION set_first_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN epis_info.id_episode%TYPE,
        i_pat                 IN patient.id_patient%TYPE,
        i_prof                IN profissional,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_dt_last_interaction IN epis_info.dt_last_interaction_tstz%TYPE,
        i_dt_first_obs        IN epis_info.dt_first_obs_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_FIRST_OBS';
    BEGIN
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        RETURN pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_id_episode,
                                      i_pat                 => i_pat,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => i_dt_last_interaction,
                                      i_dt_first_obs        => i_dt_first_obs,
                                      o_error               => o_error);
    END set_first_obs;

    /********************************************************************************************
    * pk_api_pfh_out.get_vs_most_recent_value
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_VITAL_SIGN                         IN        NUMBER(22,24)
    * @param  I_SCOPE                                 IN        NUMBER
    * @param  I_SCOPE_TYPE                            IN        VARCHAR2
    * @param  I_DT_BEGIN                              IN        VARCHAR2
    * @param  I_DT_END                                IN        VARCHAR2
    * @param  O_INFO                                  OUT       REF CURSOR
    * @param  O_ERROR                                 OUT       T_ERROR_OUT
    *
    * @return  BOOLEAN
    *
    * @author      Pedro Miranda
    * @version     
    * @since       18/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'GET_VS_MOST_RECENT_VALUE';
    BEGIN
        g_error := 'CALL pk_vital_sign.GET_VS_MOST_RECENT_VALUE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_db_object_name);
        RETURN pk_vital_sign.get_vs_most_recent_value(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_vital_sign => i_id_vital_sign,
                                                      i_scope         => i_scope,
                                                      i_scope_type    => i_scope_type,
                                                      i_dt_begin      => i_dt_begin,
                                                      i_dt_end        => i_dt_end,
                                                      o_info          => o_info,
                                                      o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_most_recent_value;

    /********************************************************************************************
    * pk_api_pfh_out.get_vs_value_dt_reg
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_ID_VITAL_SIGN_READ                    IN        NUMBER(22,24)
    * @param  I_DT_VS_READ                            IN        TIMESTAMP WITH LOCAL TIME ZONE
    * @param  I_DT_REGISTRY                           IN        TIMESTAMP WITH LOCAL TIME ZONE
    * @param  O_INFO                                  OUT       REF CURSOR
    * @param  O_ERROR                                 OUT       T_ERROR_OUT
    *
    * @return  BOOLEAN
    *
    * @author      Sergio Cunha
    * @version     
    * @since       27/11/2014
    *
    ********************************************************************************************/
    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'GET_VS_VALUE_DT_REG';
    BEGIN
        g_error := 'CALL pk_vital_sign.get_vs_value_dt_reg';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_db_object_name);
        RETURN pk_vital_sign.get_vs_value_dt_reg(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_id_vital_sign_read => i_id_vital_sign_read,
                                                 i_dt_vs_read         => i_dt_vs_read,
                                                 i_dt_registry        => i_dt_registry,
                                                 o_info               => o_info,
                                                 o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_value_dt_reg;

    /********************************************************************************************
    * Convert unit measures
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_value             Value to convert
    * @param  i_unit_meas         Origin unit measure
    * @param  i_unit_meas_def     Target unit measure
    *
    * @return Converted value
    *
    * @author Jose Brito
    * @since  31/12/2014
    *
    ********************************************************************************************/
    FUNCTION get_unit_mea_conversion
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_value         IN vital_sign_read.value%TYPE,
        i_unit_meas     IN unit_measure_convert.id_unit_measure1%TYPE,
        i_unit_meas_def IN unit_measure.id_unit_measure%TYPE
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_UNIT_MEA_CONVERSION';
        l_error t_error_out;
    BEGIN
        RETURN pk_unit_measure.get_unit_mea_conversion(i_value         => i_value,
                                                       i_unit_meas     => i_unit_meas,
                                                       i_unit_meas_def => i_unit_meas_def);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_unit_mea_conversion;

    /********************************************************************************************
    * Get interventions aliases or descriptions
    *
    * @param i_lang                language id
    * @param i_prof                professional type
    * @param i_code_interv         
    * @param i_dep_clin_serv       
    *
    * @return                      VARCHAR2
    *
    * @author                      Rui Mendonça
    * @version                     2.6.5.1
    * @since                       2015/11/06
    ********************************************************************************************/
    FUNCTION get_alias_translation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_interv   IN intervention.code_intervention%TYPE,
        i_dep_clin_serv IN intervention_alias.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_procedures_api_db.get_alias_translation(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_code_interv   => i_code_interv,
                                                          i_dep_clin_serv => i_dep_clin_serv);
    
    END get_alias_translation;

    /********************************************************************************************
    * Get diagnosis description associated to the given id_epis_diagnosis
    *
    * @param  i_lang              Language ID
    * @param  i_prof              Professional info array
    * @param  i_id_epis_diagnosis Epis Diagnosis ID  
    *
    * @return Diagnosis description associated to the given id_epis_diagnosis
    *
    * @author Sofia Mendes
    * @since  07/11/2016
    *
    ********************************************************************************************/
    FUNCTION get_diagnosis_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DIAGNOSIS_DESC';
        l_error t_error_out;
        c_diags pk_types.cursor_type;
    
        l_id_epis_diagnosis      table_number := table_number();
        l_id_epis_diagnosis_hist table_number := table_number();
        l_id_diagnosis           table_number := table_number();
        l_desc_diagnosis         table_varchar := table_varchar();
        l_flg_type               table_varchar := table_varchar();
        l_type_desc              table_varchar := table_varchar();
        l_flg_status             table_varchar := table_varchar();
        l_status_desc            table_varchar := table_varchar();
        l_problem_status         table_varchar := table_varchar();
        l_notes                  table_varchar := table_varchar();
        l_general_notes          table_varchar := table_varchar();
        l_notes_cancel           table_varchar := table_varchar();
        l_flg_has_recent_date    table_varchar := table_varchar();
    
    BEGIN
        g_error := 'Call pk_diagnosis_core.get_epis_diag_list. i_id_epis_diagnosis: ' || i_id_epis_diagnosis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_diagnosis_core.get_epis_diag_list(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diag      => table_number(i_id_epis_diagnosis),
                                                    i_epis_diag_hist => table_number(NULL),
                                                    o_epis_diag      => c_diags,
                                                    o_error          => l_error)
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'FETCH c_differ';
        pk_alertlog.log_debug(g_error);
        FETCH c_diags BULK COLLECT
            INTO l_id_epis_diagnosis,
                 l_id_epis_diagnosis_hist,
                 l_id_diagnosis,
                 l_desc_diagnosis,
                 l_flg_type,
                 l_type_desc,
                 l_flg_status,
                 l_status_desc,
                 l_problem_status,
                 l_notes,
                 l_general_notes,
                 l_notes_cancel,
                 l_flg_has_recent_date;
        CLOSE c_diags;
    
        IF (l_desc_diagnosis IS NOT NULL AND l_desc_diagnosis.exists(1))
        THEN
            RETURN l_desc_diagnosis(1);
        ELSE
            RETURN NULL;
        END IF;
    
        /*ed.id_epis_diagnosis,
        ed.id_epis_diagnosis_hist,
        ed.id_diagnosis,
        pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                   i_prof                => i_prof,
                                   i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                   i_id_diagnosis        => d.id_diagnosis,
                                   i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                   i_code                => d.code_icd,
                                   i_flg_other           => d.flg_other,
                                   i_flg_std_diag        => ad.flg_icd9) diag_desc,
        ed.flg_type,
        pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_TYPE', ed.flg_type, i_lang) type_desc,
        ed.flg_status,
        pk_sysdomain.get_domain('EPIS_DIAGNOSIS.FLG_STATUS', ed.flg_status, i_lang) status_desc,
        ed.flg_add_problem problem_status,
        ed.notes,
        ed.general_notes,
        ed.notes_cancel,
        ed.flg_has_recent_data*/
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => l_error);
            RETURN NULL;
    END get_diagnosis_desc;

    /********************************************************************************************
    * Get the b_value from table inter_map.map according with the given arguments
    *
    * @param   i_a_system        IN VARCHAR2
    * @param   i_b_system        IN VARCHAR2
    * @param   i_a_value         IN VARCHAR2
    * @param   i_a_definition    IN VARCHAR2
    * @param   i_b_definition    IN VARCHAR2
    * @param   i_id_institution  IN NUMBER
    * @param   i_id_software     IN NUMBER
    * @param   o_b_value         OUT NOCOPY VARCHAR2
    * @param   o_error           OUT NOCOPY VARCHAR2
    *
    * @return                      BOOLEAN
    *
    * @author                      rui.mendonca
    * @version                     2.7.1.0
    * @since                       2017/04/12
    ********************************************************************************************/
    FUNCTION get_map_a_b
    (
        i_a_system       IN VARCHAR2,
        i_b_system       IN VARCHAR2,
        i_a_value        IN VARCHAR2,
        i_a_definition   IN VARCHAR2,
        i_b_definition   IN VARCHAR2,
        i_id_institution IN NUMBER,
        i_id_software    IN NUMBER,
        o_b_value        OUT NOCOPY VARCHAR2,
        o_error          OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_map.get_map_a_b(i_a_system       => i_a_system,
                                  i_b_system       => i_b_system,
                                  i_a_value        => i_a_value,
                                  i_a_definition   => i_a_definition,
                                  i_b_definition   => i_b_definition,
                                  i_id_institution => i_id_institution,
                                  i_id_software    => i_id_software,
                                  o_b_value        => o_b_value,
                                  o_error          => o_error);
    END get_map_a_b;

    /********************************************************************************************
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION grid_task_del_drug_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.delete_drug_req_field(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             o_error      => o_error);
    END grid_task_del_drug_req;

    /**********************************************************************************************
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION grid_task_upd_drug_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_drug_req   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.update_drug_req_field(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_drug_req   => i_drug_req,
                                             o_error      => o_error);
    END grid_task_upd_drug_req;

    /***************************************************************************************************************
    * Provides the bed description  of the active bed allocation
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_epis              ID_EPIS
    * @param      o_desc              Bed description (null if no allocation)
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Sofia Mendes
    * @version 2.7
    * @since   15-01-2018
    *
    ****************************************************************************************************/
    FUNCTION get_bed_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_desc  OUT pk_translation.t_desc_translation,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL TO PK_BMNG_PBL';
        IF NOT pk_bmng_pbl.get_bed_desc(i_lang  => i_lang,
                                        i_prof  => i_prof,
                                        i_epis  => i_epis,
                                        o_desc  => o_desc,
                                        o_error => o_error)
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
                                              'GET_BED_DESC',
                                              o_error);
            RETURN FALSE;
        
    END get_bed_desc;

    /********************************************************************************************
    * Function to get rank from grid_task string
    *
    * @param   i_grid_task_str   Grid Task String, ex.: 6|I|||DispensationPendingIcon|0xE8BE44|||||1
    *
    * @return  NUMBER
    *
    * @author          Pedro Teixeira
    * @since           15/01/2018
    ********************************************************************************************/
    FUNCTION get_rank_from_gt_string(i_grid_task_str IN VARCHAR2) RETURN NUMBER IS
        l_str_split table_varchar := table_varchar();
        l_ret       NUMBER;
    BEGIN
        l_str_split := pk_string_utils.str_split(i_list => i_grid_task_str, i_delim => '|');
        IF nvl(cardinality(l_str_split), 0) > 0
        THEN
            l_ret := to_number(l_str_split(l_str_split.last));
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_rank_from_gt_string;

    /********************************************************************************************
    * Get multichoice options by a multichoice type
    *
    * @author       Pedro Teixeira
    * @since        28/02/2018
    **********************************************************************************************/
    FUNCTION get_multichoice_options
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_multichoice_type    IN VARCHAR2,
        o_multichoice_options OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_MULTICHOICE_OPTIONS';
    BEGIN
        RETURN pk_api_multichoice.get_multichoice_options(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_multichoice_type    => i_multichoice_type,
                                                          o_multichoice_options => o_multichoice_options,
                                                          o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_multichoice_options;

    /********************************************************************************************
    * Function to get icon from grid_task string
    *
    * @param   i_grid_task_str   Grid Task String, ex.: 6|DI|20180321112600||UrgentIcon||||0xEBEBC8|20180321142638|
    *
    * @return  VARCHAR
    *
    * @author          CRISTINA.OLIVEIRA
    * @since           23/03/2018
    ********************************************************************************************/
    FUNCTION get_icon_from_gt_string(i_grid_task_str IN VARCHAR2) RETURN VARCHAR2 IS
        l_str_split table_varchar := table_varchar();
        l_ret       VARCHAR2(100);
    BEGIN
        l_str_split := pk_string_utils.str_split(i_list => i_grid_task_str, i_delim => '|');
        IF nvl(cardinality(l_str_split), 0) > 0
        THEN
            l_ret := l_str_split(5);
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_icon_from_gt_string;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_epis_department
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_EPIS_DEPARTMENTS';
    
        l_epis_department department.id_department%TYPE;
    BEGIN
        -----------------------------------------------
        SELECT dcs.id_department
          INTO l_epis_department
          FROM epis_info ei
          JOIN dep_clin_serv dcs
            ON ei.id_dep_clin_serv = dcs.id_dep_clin_serv
         WHERE ei.id_episode = i_id_episode;
    
        RETURN l_epis_department;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_department;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_inst_epis_departments
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_INST_EPIS_DEPARTMENTS';
        l_error t_error_out;
    
        l_departments     table_number := table_number();
        l_epis_department department.id_department%TYPE;
    BEGIN
        -----------------------------------------------
        IF NOT pk_bmng_core.get_institution_departments(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_institution => i_prof.institution,
                                                        o_deps        => l_departments,
                                                        o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -----------------------------------------------
        l_epis_department := get_epis_department(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    
        -----------------------------------------------
        OPEN o_department_list FOR
            SELECT d.id_department data,
                   pk_translation.get_translation(i_lang, dpt.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, d.code_department) label,
                   decode(d.id_department, l_epis_department, 'Y', 'N') flg_default
              FROM department d
              JOIN dept dpt
                ON dpt.id_dept = d.id_dept
              JOIN (SELECT column_value id_department
                      FROM TABLE(l_departments)) dl
                ON dl.id_department = d.id_department
             ORDER BY pk_translation.get_translation(i_lang, dpt.code_dept) || ' - ' ||
                      pk_translation.get_translation(i_lang, d.code_department);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_department_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_inst_epis_departments;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_dept_department_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        i_desc_type     IN VARCHAR2 DEFAULT NULL -- D -> Department; S -> Service; NULL -> Department ' - ' Service
    ) RETURN VARCHAR2 IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_DEPT_DEPARTMENT_DESC';
    
        l_dept_desc VARCHAR2(4000 CHAR);
    BEGIN
        -----------------------------------------------
        SELECT decode(i_desc_type,
                      NULL,
                      pk_translation.get_translation(i_lang, dpt.code_dept) || ' - ' ||
                      pk_translation.get_translation(i_lang, d.code_department),
                      'D',
                      pk_translation.get_translation(i_lang, d.code_department),
                      'S',
                      pk_translation.get_translation(i_lang, dpt.code_dept),
                      NULL)
          INTO l_dept_desc
          FROM department d
          JOIN dept dpt
            ON dpt.id_dept = d.id_dept
         WHERE d.id_department = i_id_department;
    
        RETURN l_dept_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dept_department_desc;

    FUNCTION get_nr_refill_from_review(i_refill_date_str IN VARCHAR2) RETURN NUMBER IS
        l_str_split table_varchar := table_varchar();
        l_ret       NUMBER;
    BEGIN
        l_str_split := pk_string_utils.str_split(i_list => i_refill_date_str, i_delim => '|');
        IF nvl(cardinality(l_str_split), 0) > 0
        THEN
            l_ret := to_number(l_str_split(l_str_split.first));
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_nr_refill_from_review;

    FUNCTION get_date_from_review(i_refill_date_str IN VARCHAR2) RETURN VARCHAR2 IS
        l_str_split table_varchar := table_varchar();
        l_ret       VARCHAR(100);
    BEGIN
        l_str_split := pk_string_utils.str_split(i_list => i_refill_date_str, i_delim => '|');
        IF nvl(cardinality(l_str_split), 0) > 0
        THEN
            l_ret := l_str_split(l_str_split.last);
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_date_from_review;

    FUNCTION get_previous_visit
    (
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN episode.id_visit%TYPE IS
    BEGIN
        RETURN pk_episode.get_previous_visit(i_id_episode => i_id_episode, i_id_epis_type => i_id_epis_type);
    
    END get_previous_visit;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_allergies_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_flg_show_msg          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_allergies             OUT pk_types.cursor_type,
        o_allergies_unawareness OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        RESULT BOOLEAN;
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PAT_ALLERGIES_ALL';
    
    BEGIN
    
        RESULT := pk_allergy.get_pat_allergies(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_patient      => i_patient,
                                               i_flg_show_msg => i_flg_show_msg,
                                               o_allergies    => o_allergies,
                                               o_error        => o_error);
    
        RESULT := pk_allergy.get_pat_allergy_unawareness(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_patient   => i_patient,
                                                         o_allergies => o_allergies_unawareness,
                                                         o_error     => o_error);
    
        RETURN RESULT;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 1,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_allergies_all;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_vs_value_unit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg      IN vital_sign_read.dt_vital_sign_read_tstz%TYPE DEFAULT NULL,
        o_vs_value        OUT VARCHAR2,
        o_vs_unit_measure OUT NUMBER,
        o_vs_um_desc      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_MULTICHOICE_OPTIONS';
    BEGIN
        RETURN pk_vital_sign.get_pat_vs_value_unit(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_vital_sign   => i_id_vital_sign,
                                                   i_patient         => i_patient,
                                                   i_dt_max_reg      => i_dt_max_reg,
                                                   o_vs_value        => o_vs_value,
                                                   o_vs_unit_measure => o_vs_unit_measure,
                                                   o_vs_um_desc      => o_vs_um_desc,
                                                   o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_vs_value_unit;

    /********************************************************************************
    ********************************************************************************/
    FUNCTION set_confirmed_epis_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_params            IN CLOB,
        o_id_epis_diagnosis OUT table_number,
        o_id_diagnosis      OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'SET_CONFIRMED_EPIS_DIAGNOSIS';
    BEGIN
    
        RETURN pk_diagnosis_form.set_confirmed_epis_diagnosis(i_lang              => i_lang,
                                                              i_prof              => i_prof,
                                                              i_params            => i_params,
                                                              o_id_epis_diagnosis => o_id_epis_diagnosis,
                                                              o_id_diagnosis      => o_id_diagnosis,
                                                              o_error             => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_confirmed_epis_diagnosis;

    PROCEDURE get_hand_off_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        io_hand_off_type IN OUT sys_config.value%TYPE
    ) IS
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => io_hand_off_type);
    END get_hand_off_type;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_sa_dispense_label_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_prof_validation     IN profissional,
        i_prof_print_label    IN profissional,
        o_inst_name           OUT VARCHAR2,
        o_inst_name_sa        OUT VARCHAR2,
        o_phone_num           OUT VARCHAR2,
        o_num_mec_val         OUT VARCHAR2,
        o_num_mec_print_label OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_sa_dispense_label_info';
    
    BEGIN
        SELECT pk_backoffice.get_inst_field(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_institution => i_prof.institution,
                                            i_field          => 'INST_NAME') inst_name,
               pk_backoffice.get_inst_field(i_lang           => 20,
                                            i_prof           => i_prof,
                                            i_id_institution => i_prof.institution,
                                            i_field          => 'INST_NAME') inst_name_sa,
               pk_backoffice.get_inst_field(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_id_institution => i_prof.institution,
                                            i_field          => 'PHONE_NUMBER') phone_num,
               pk_prof_utils.get_prof_inst_mec_num(i_lang       => i_lang,
                                                   i_prof       => i_prof_validation,
                                                   i_flg_active => pk_alert_constant.g_active) num_mec_val,
               pk_prof_utils.get_prof_inst_mec_num(i_lang       => i_lang,
                                                   i_prof       => i_prof_print_label,
                                                   i_flg_active => pk_alert_constant.g_active) num_mec_print_label
          INTO o_inst_name, o_inst_name_sa, o_phone_num, o_num_mec_val, o_num_mec_print_label
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_db_object_name,
                                                     o_error    => o_error);
    END get_sa_dispense_label_info;

    /********************************************************************************
    ********************************************************************************/
    FUNCTION get_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN VARCHAR2,
        i_patient          IN NUMBER,
        i_prof             IN profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_sample_text.get_sample_text(i_lang             => i_lang,
                                              i_sample_text_type => i_sample_text_type,
                                              i_patient          => i_patient,
                                              i_prof             => i_prof,
                                              o_sample_text      => o_sample_text,
                                              o_error            => o_error);
    END get_sample_text;

    /**********************************************************************************************
    * Get a set of professionals that are able to do cosign
    *
    * @param   i_lang            IN   language.id_language%TYPE
    * @param   i_prof            IN   profissional
    * @param   i_id_episode      IN   episode.id_episode%TYPE
    * @param   i_id_order_type   IN   order_type.id_order_type%TYPE
    * @param   o_prof_list       OUT  pk_types.cursor_type
    * @param   o_error           OUT  t_error_out
    *
    * @return  Boolean
    *
    * @author  rui.mendonca
    * @version PFH 2.7.4.0
    * @since   29/08/2018
    **********************************************************************************************/
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_co_sign.get_prof_list(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_id_episode    => i_id_episode,
                                        i_id_order_type => i_id_order_type,
                                        o_prof_list     => o_prof_list,
                                        o_error         => o_error);
    END get_prof_list;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION generate_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_barcode_type IN VARCHAR2,
        i_institution  IN NUMBER,
        i_software     IN NUMBER,
        o_barcode      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_barcode.generate_barcode(i_lang         => i_lang,
                                           i_barcode_type => i_barcode_type,
                                           i_institution  => i_institution,
                                           i_software     => i_software,
                                           o_barcode      => o_barcode,
                                           o_error        => o_error);
    END generate_barcode;

    FUNCTION get_room_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_desc  OUT pk_translation.t_desc_translation,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'INIT get_room_desc_by_id_bed';
        SELECT nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room))
          INTO o_desc
          FROM epis_info ei
          LEFT JOIN bed b
            ON b.id_bed = ei.id_bed
          LEFT JOIN room r
            ON r.id_room = b.id_room
         WHERE ei.id_episode = i_epis;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BED_DESC',
                                              o_error);
            RETURN FALSE;
        
    END get_room_desc;

    FUNCTION get_pat_name
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE IS
    BEGIN
    
        RETURN pk_patient.get_pat_name(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_patient  => i_patient,
                                       i_episode  => i_episode,
                                       i_schedule => i_schedule);
    
    END get_pat_name;

    FUNCTION grid_task_upd_disp_ivroom
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_disp_ivroom IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.update_disp_ivroom_field(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_episode  => i_id_episode,
                                                i_disp_ivroom => i_disp_ivroom,
                                                o_error       => o_error);
    END grid_task_upd_disp_ivroom;

    FUNCTION grid_task_upd_disp_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_disp_task  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.update_disp_task_field(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              i_disp_task  => i_disp_task,
                                              o_error      => o_error);
    END grid_task_upd_disp_task;

    FUNCTION grid_task_del_disp_ivroom
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.delete_disp_ivroom_field(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_id_episode,
                                                o_error      => o_error);
    END grid_task_del_disp_ivroom;

    FUNCTION grid_task_del_disp_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_grid.delete_disp_task_field(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_episode => i_id_episode,
                                              o_error      => o_error);
    END grid_task_del_disp_task;

    /******************************************************************************
    *********************************************************************************/
    FUNCTION get_pat_comp
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN alert.profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_flg_comp         OUT VARCHAR2,
        o_flg_special_comp OUT VARCHAR2,
        o_flg_plan_type    OUT VARCHAR2,
        o_flg_recm         OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'GET_PAT_COMP';
    BEGIN
    
        RETURN pk_adt.get_pat_comp(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_patient       => i_id_patient,
                                   i_id_episode       => i_id_episode,
                                   o_flg_comp         => o_flg_comp,
                                   o_flg_special_comp => o_flg_special_comp,
                                   o_flg_plan_type    => o_flg_plan_type,
                                   o_flg_recm         => o_flg_recm,
                                   o_error            => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_comp;

    /******************************************************************************
    *********************************************************************************/
    FUNCTION check_patient_rules
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_message_title   OUT VARCHAR2,
        o_message_text    OUT VARCHAR2,
        o_forward_button  OUT VARCHAR2,
        o_back_button     OUT VARCHAR2,
        o_flg_can_proceed OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'CHECK_PATIENT_RULES';
    BEGIN
    
        RETURN pk_adt.check_patient_rules(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_patient         => i_id_patient,
                                          i_episode         => i_id_episode,
                                          i_type            => i_type,
                                          o_flg_show        => o_flg_show,
                                          o_message_title   => o_message_title,
                                          o_message_text    => o_message_text,
                                          o_forward_button  => o_forward_button,
                                          o_back_button     => o_back_button,
                                          o_flg_can_proceed => o_flg_can_proceed,
                                          o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_patient_rules;

    FUNCTION check_patient_rules_ue
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_flg_show   OUT VARCHAR2,
        --o_message_title OUT VARCHAR2,
        o_message_text OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(30) := 'CHECK_PATIENT_RULES';
        l_pat_dt_birth VARCHAR2(200 CHAR);
        l_sns          pat_health_plan.num_health_plan%TYPE;
        lhpentity      VARCHAR2(1000 CHAR);
        lhpdesc        VARCHAR2(1000 CHAR);
        l_new_line     VARCHAR2(20 CHAR) := '<br><br>';
        l_idhp         pat_health_plan.id_health_plan%TYPE;
    BEGIN
    
        o_flg_show := pk_alert_constant.g_no;
    
        SELECT pk_date_utils.date_send(i_lang, p.dt_birth, i_prof) dt_birth
          INTO l_pat_dt_birth
          FROM patient p
         WHERE p.id_patient = i_id_patient;
    
        --Get national health number information 
        g_error := 'Call get_national_health_number - ' || i_id_patient || ' - ' || i_prof.institution;
        IF NOT pk_adt.get_national_health_number(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_patient      => i_id_patient,
                                                 o_hp_id_hp        => l_idhp,
                                                 o_num_health_plan => l_sns,
                                                 o_hp_entity       => lhpentity,
                                                 o_hp_desc         => lhpdesc,
                                                 o_error           => o_error)
        THEN
            pk_alertlog.log_warn(g_error);
        END IF;
    
        --Validate data >>>
        IF l_sns IS NOT NULL --Nº utente SNS
           AND l_pat_dt_birth IS NOT NULL
        THEN
            RETURN TRUE;
        ELSE
            o_flg_show := pk_alert_constant.g_yes;
        
            --Se não tem SNS
            IF l_sns IS NULL
            --OR l_valid_sns = pk_alert_constant.g_no
            THEN
                o_message_text := o_message_text || '<b>- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T015') ||
                                  '</b>'; --Mensagem utente SNS não foi preenchido ou inválido
            END IF;
            IF l_pat_dt_birth IS NULL
            THEN
                IF o_message_text IS NOT NULL
                THEN
                    o_message_text := o_message_text || l_new_line;
                END IF;
                o_message_text := o_message_text || '<b>- ' || pk_message.get_message(i_lang, 'CORE_MEDICATION_T019') ||
                                  '</b>'; --Mensagem data nascimento não foi preenchido
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_patient_rules_ue;

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT VARCHAR2(50) := 'GET_PAT_CRITERIA_ACTIVE_CLIN';
    BEGIN
    
        RETURN pk_pha_search.get_pat_criteria_active_clin(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_sys_btn_crit => i_id_sys_btn_crit,
                                                          i_crit_val        => i_crit_val,
                                                          o_pat             => o_pat,
                                                          o_error           => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_criteria_active_clin;

    FUNCTION get_pat_name_to_sort
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE IS
    BEGIN
    
        RETURN pk_patient.get_pat_name_to_sort(i_lang     => i_lang,
                                               i_prof     => i_prof,
                                               i_patient  => i_patient,
                                               i_episode  => i_episode,
                                               i_schedule => i_schedule);
    
    END get_pat_name_to_sort;

    FUNCTION get_supplies_by_context
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context_m  IN table_varchar,
        i_id_context_p  IN table_varchar,
        i_dep_clin_serv IN interv_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_supplies      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_supplies_api_db.get_supplies_by_context(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_context_m  => i_id_context_m,
                                                          i_id_context_p  => i_id_context_p,
                                                          i_dep_clin_serv => i_dep_clin_serv,
                                                          o_supplies      => o_supplies,
                                                          o_error         => o_error);
    END get_supplies_by_context;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_next_cpoe_date
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_dt_start OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end   OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN pk_cpoe.get_next_cpoe_date(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_episode  => i_episode,
                                          o_dt_start => o_dt_start,
                                          o_dt_end   => o_dt_end,
                                          o_error    => o_error);
    END get_next_cpoe_date;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_current_cpoe_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_dt_start   OUT cpoe_process.dt_cpoe_proc_start%TYPE,
        o_dt_end     OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_flg_status OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cpoe_process    cpoe_process.id_cpoe_process%TYPE;
        l_id_professional professional.id_professional%TYPE;
    BEGIN
        RETURN pk_cpoe.get_last_cpoe_info(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          o_cpoe_process    => l_cpoe_process,
                                          o_dt_start        => o_dt_start,
                                          o_dt_end          => o_dt_end,
                                          o_flg_status      => o_flg_status,
                                          o_id_professional => l_id_professional,
                                          o_error           => o_error);
    END get_current_cpoe_date;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_lab_test_result_param
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_analysis_param IN table_number,
        i_dt_result      IN VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_lab_tests_external_api_db.get_lab_test_result_param(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_patient        => i_patient,
                                                                      i_analysis_param => i_analysis_param,
                                                                      i_dt_result      => i_dt_result,
                                                                      o_list           => o_list,
                                                                      o_error          => o_error);
    END get_lab_test_result_param;

    FUNCTION get_lab_test_result_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_analysis_result_par IN analysis_result_par.id_analysis_result_par%TYPE,
        i_dt_analysis_result_par IN analysis_result_par.dt_analysis_result_par_tstz%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_lab_tests_external_api_db.get_lab_test_result_desc(i_lang                   => i_lang,
                                                                     i_prof                   => i_prof,
                                                                     i_id_analysis_result_par => i_id_analysis_result_par,
                                                                     i_dt_analysis_result_par => i_dt_analysis_result_par);
    END get_lab_test_result_desc;

    FUNCTION check_epis_out_on_pass_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_epis_out_on_pass.check_epis_out_on_pass_active(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_episode => i_id_episode);
    
    END check_epis_out_on_pass_active;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_patient_alerts_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_id_patient   IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN pk_alerts.get_patient_alerts_count(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_sys_alert => i_id_sys_alert,
                                                  i_id_patient   => i_id_patient);
    END get_patient_alerts_count;

    FUNCTION get_inst_epis_departments
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
        l_db_object_name CONSTANT VARCHAR2(200 CHAR) := 'GET_INST_EPIS_DEPARTMENTS';
    
        l_departments     table_number := table_number();
        l_epis_department department.id_department%TYPE;
    BEGIN
        -----------------------------------------------
        IF NOT pk_bmng_core.get_institution_departments(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_institution => i_prof.institution,
                                                        o_deps        => l_departments,
                                                        o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -----------------------------------------------
        --l_epis_department := get_epis_department(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
    
        -----------------------------------------------
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.label,
                                 domain_value  => t.data,
                                 order_rank    => NULL,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT d.id_department data,
                       pk_translation.get_translation(i_lang, dpt.code_dept) || ' - ' ||
                       pk_translation.get_translation(i_lang, d.code_department) label
                --decode(d.id_department, l_epis_department, 'Y', 'N') flg_default
                  FROM department d
                  JOIN dept dpt
                    ON dpt.id_dept = d.id_dept
                  JOIN (SELECT column_value id_department
                         FROM TABLE(l_departments)) dl
                    ON dl.id_department = d.id_department
                 ORDER BY upper(pk_translation.get_translation(i_lang, dpt.code_dept) || ' - ' ||
                                pk_translation.get_translation(i_lang, d.code_department))) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_db_object_name,
                                              o_error    => o_error);
            RETURN l_ret;
    END get_inst_epis_departments;

    FUNCTION get_requested_supplies_per_context
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN supply_request.flg_context%TYPE,
        i_id_context  IN supply_workflow.id_context%TYPE,
        o_supplies    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_supplies_external_api_db.get_requested_supplies_per_context(i_lang        => i_lang,
                                                                              i_prof        => i_prof,
                                                                              i_flg_context => i_flg_context,
                                                                              i_id_context  => i_id_context,
                                                                              o_supplies    => o_supplies,
                                                                              o_error       => o_error);
    
    END get_requested_supplies_per_context;

    FUNCTION get_default_supplies_req_cfg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_context_d   IN supply_request.flg_context%TYPE,
        i_id_context_d    IN supply_workflow.id_context%TYPE,
        i_id_context_m    IN table_varchar,
        i_id_context_p    IN table_varchar,
        i_flg_default_qty IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_supplies        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_supplies_external_api_db.get_default_supplies_req_cfg(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_flg_context_d   => i_flg_context_d,
                                                                        i_id_context_d    => i_id_context_d,
                                                                        i_id_context_m    => i_id_context_m,
                                                                        i_id_context_p    => i_id_context_p,
                                                                        i_flg_default_qty => i_flg_default_qty,
                                                                        o_supplies        => o_supplies,
                                                                        o_error           => o_error);
    
    END get_default_supplies_req_cfg;

    FUNCTION create_supply_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_supply            IN table_number,
        i_supply_set        IN table_number,
        i_supply_qty        IN table_number,
        i_dt_request        IN table_varchar,
        i_dt_return         IN table_varchar,
        i_id_context        IN supply_request.id_context%TYPE,
        i_flg_context       IN supply_request.flg_context%TYPE,
        i_supply_flg_status IN supply_request.flg_status%TYPE,
        i_lot               IN table_varchar DEFAULT NULL,
        i_barcode_scanned   IN table_varchar DEFAULT NULL,
        i_dt_expiration     IN table_varchar DEFAULT NULL,
        i_flg_validation    IN table_varchar DEFAULT NULL,
        o_supply_request    OUT supply_request.id_supply_request%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_supplies_api_db.create_supply_order';
        RETURN pk_supplies_api_db.create_supply_order(i_lang              => i_lang,
                                                      i_prof              => i_prof,
                                                      i_episode           => i_episode,
                                                      i_supply            => i_supply,
                                                      i_supply_set        => i_supply_set,
                                                      i_supply_qty        => i_supply_qty,
                                                      i_dt_request        => i_dt_request,
                                                      i_dt_return         => i_dt_return,
                                                      i_id_context        => i_id_context,
                                                      i_flg_context       => i_flg_context,
                                                      i_supply_flg_status => i_supply_flg_status,
                                                      i_lot               => i_lot,
                                                      i_barcode_scanned   => i_barcode_scanned,
                                                      i_dt_expiration     => i_dt_expiration,
                                                      i_flg_validation    => i_flg_validation,
                                                      o_supply_request    => o_supply_request,
                                                      o_error             => o_error);
    
    END create_supply_order;

    FUNCTION get_supply_workflow_lst
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_context        IN supply_request.flg_context%TYPE,
        i_id_context         IN supply_workflow.id_context%TYPE,
        o_supply_wokflow_lst OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external_api_db.get_supply_workflow_lst(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_flg_context        => i_flg_context,
                                                                   i_id_context         => i_id_context,
                                                                   o_supply_wokflow_lst => o_supply_wokflow_lst,
                                                                   o_error              => o_error);
    
    END get_supply_workflow_lst;

    FUNCTION get_supply_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'CALL pk_supplies_external_api_db.GET_SUPPLY_DESCRIPTION';
        RETURN pk_supplies_external_api_db.get_supply_description(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_supply_workflow => i_supply_workflow,
                                                                  i_flg_filter_type => i_flg_filter_type);
    END get_supply_description;

    FUNCTION update_supply_record
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_supply          IN table_number,
        i_supply_set      IN table_number,
        i_supply_qty      IN table_number,
        i_supply_lot      IN table_varchar,
        i_barcode_scanned IN table_varchar,
        i_dt_request      IN table_varchar,
        i_dt_expiration   IN table_varchar,
        i_flg_validation  IN table_varchar,
        i_flg_supply_type IN table_varchar,
        i_deliver_needed  IN table_varchar,
        i_flg_cons_type   IN table_varchar,
        i_flg_consumption IN table_varchar,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_supply_request  OUT supply_request.id_supply_request%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external_api_db.update_supply_record(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_episode         => i_episode,
                                                                i_supply_workflow => i_supply_workflow,
                                                                i_supply          => i_supply,
                                                                i_supply_set      => i_supply_set,
                                                                i_supply_qty      => i_supply_qty,
                                                                i_supply_lot      => i_supply_lot,
                                                                i_barcode_scanned => i_barcode_scanned,
                                                                i_dt_request      => i_dt_request,
                                                                i_dt_expiration   => i_dt_expiration,
                                                                i_flg_validation  => i_flg_validation,
                                                                i_flg_supply_type => i_flg_supply_type,
                                                                i_deliver_needed  => i_deliver_needed,
                                                                i_flg_cons_type   => i_flg_cons_type,
                                                                i_flg_consumption => i_flg_consumption,
                                                                i_id_context      => i_id_context,
                                                                i_flg_context     => i_flg_context,
                                                                o_supply_request  => o_supply_request,
                                                                o_error           => o_error);
    END update_supply_record;

    FUNCTION cancel_supply_order
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_context    IN supply_context.id_context%TYPE,
        i_flg_context   IN supply_context.flg_context%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN supply_request.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_supply_workflow table_number := table_number();
    BEGIN
    
        RETURN pk_supplies_external_api_db.cancel_supply_order(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_context    => i_id_context,
                                                               i_flg_context   => i_flg_context,
                                                               i_cancel_reason => i_cancel_reason,
                                                               i_cancel_notes  => i_cancel_notes,
                                                               o_error         => o_error);
    
    END cancel_supply_order;

    FUNCTION check_supplies_not_in_inicial_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN supply_request.flg_context%TYPE,
        i_id_context       IN supply_workflow.id_context%TYPE,
        i_id_cancel_reason IN supply_workflow.id_cancel_reason%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_supplies_external_api_db.check_supplies_not_in_inicial_status(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_flg_context      => i_flg_context,
                                                                                i_id_context       => i_id_context,
                                                                                i_id_cancel_reason => i_id_cancel_reason);
    
    END check_supplies_not_in_inicial_status;

    FUNCTION inactivate_records_by_context
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_supply_workflow IN table_number,
        i_id_context      IN supply_request.id_context%TYPE,
        i_flg_context     IN supply_request.flg_context%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_supplies_external_api_db.inactivate_records_by_context(i_lang            => i_lang,
                                                                         i_prof            => i_prof,
                                                                         i_episode         => i_episode,
                                                                         i_supply_workflow => i_supply_workflow,
                                                                         i_id_context      => i_id_context,
                                                                         i_flg_context     => i_flg_context,
                                                                         o_error           => o_error);
    END inactivate_records_by_context;

    FUNCTION update_nurse_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task_between%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_grid.update_nurse_task(i_lang => i_lang, i_grid_task => i_grid_task, o_error => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END update_nurse_task;

    FUNCTION get_supplies_descr_by_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_supply_workflow IN table_varchar,
        i_flg_filter_type IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2 IS
    BEGIN
    
        g_error := 'CALL pk_supplies_core.GET_COUNT_SUPPLIES_STR_ALL';
        RETURN pk_supplies_external_api_db.get_supplies_descr_by_id(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_supply_workflow => i_supply_workflow,
                                                                    i_flg_filter_type => i_flg_filter_type);
    
    END get_supplies_descr_by_id;

    FUNCTION get_process_end_date_per_task
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_request IN cpoe_process_task.id_task_request%TYPE,
        i_id_task_type    IN cpoe_process_task.id_task_type%TYPE,
        o_dt_end          OUT cpoe_process.dt_cpoe_proc_end%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_cpoe.get_process_end_date_per_task';
        RETURN pk_cpoe.get_process_end_date_per_task(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_task_request => i_id_task_request,
                                                     i_id_task_type    => i_id_task_type,
                                                     o_dt_end          => o_dt_end,
                                                     o_error           => o_error);
    
    END get_process_end_date_per_task;

    FUNCTION get_cpoe_mode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE DEFAULT NULL,
        o_flg_mode OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'CALL pk_cpoe.get_cpoe_mode';
        RETURN pk_cpoe.get_cpoe_mode(i_lang     => i_lang,
                                     i_prof     => i_prof,
                                     i_episode  => i_episode,
                                     o_flg_mode => o_flg_mode,
                                     o_error    => o_error);
    
    END get_cpoe_mode;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION check_area_create_permission
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN VARCHAR2,
        o_val     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          i_area    => i_area,
                                                          o_val     => o_val,
                                                          o_error   => o_error);
    END check_area_create_permission;

    FUNCTION get_responsibles_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat      IN category.flg_type%TYPE,
        i_hand_off_type IN sys_config.value%TYPE,
        i_my_patients   IN VARCHAR2 DEFAULT pk_alert_constant.get_no
    ) RETURN table_number IS
    BEGIN
    
        RETURN pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_episode    => i_id_episode,
                                                    i_prof_cat      => i_prof_cat,
                                                    i_hand_off_type => i_hand_off_type,
                                                    i_my_patients   => i_my_patients);
    END get_responsibles_id;

    FUNCTION get_med_info_button_url
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_product          IN VARCHAR2,
        i_id_product_supplier IN VARCHAR2,
        i_id_presc            IN NUMBER,
        o_url                 OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_info_button.get_med_info_button_url(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_product          => i_id_product,
                                                      i_id_product_supplier => i_id_product_supplier,
                                                      i_id_presc            => i_id_presc,
                                                      o_url                 => o_url,
                                                      o_error               => o_error);
    END get_med_info_button_url;

    FUNCTION check_pharm_info_stock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_product       IN VARCHAR2,
        i_id_supply_source IN NUMBER,
        o_info_stock       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_PHARM_INFO_STOCK';
        function_user_exeception EXCEPTION;
    
        -- FOR JSON structure
        i_table_table_ws pk_webservices.table_ws_attr;
    
        -- FOR JSON QUESTION
        l_json        json_object_t;
        l_json_string CLOB;
        l_json_status VARCHAR2(10 CHAR);
    
    BEGIN
    
        -- INSTITUTION / PROFISSIONAL / SOFTWARE
        i_table_table_ws('CONTEXT.ID_INSTITUTION') := anydata.convertvarchar2(i_prof.institution);
        i_table_table_ws('CONTEXT.ID_PROFESSIONAL') := anydata.convertvarchar2(i_prof.id);
        i_table_table_ws('CONTEXT.ID_SOFTWARE') := anydata.convertvarchar2(i_prof.software);
        --PRODUCT
        i_table_table_ws('ITEM_CODE') := anydata.convertvarchar2(i_id_product);
        i_table_table_ws('SUBSTORE') := anydata.convertvarchar2(i_id_supply_source); --id_presc_list_item (associated to id_presc_list=23) 
    
        -- LOG JSON SENT
        g_error := 'LOG JSON SENT';
        pk_alertlog.log_debug(lob_text        => to_clob('JSON SENT: ' || pk_webservices.to_json(i_table_table_ws)),
                              object_name     => g_package_name,
                              sub_object_name => l_func_name,
                              owner           => g_package_owner);
    
        -- CALL API WEBSERVICE
        g_error := 'CALL pk_webservices.call_ws';
        BEGIN
            l_json_string := pk_webservices.call_ws(i_ws_int_name    => 'STOCK_MEDICATION_INFO',
                                                    i_table_table_ws => i_table_table_ws);
        EXCEPTION
            WHEN OTHERS THEN
                g_error := 'ERRO API DOWN pk_webservices.call_ws';
                g_error := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'CDR_T110') ||
                           chr(10) || chr(10) || SQLERRM;
        END;
    
        -- LOG JSON RECEIVED
        g_error := 'LOG JSON RECEIVED';
        pk_alertlog.log_debug(lob_text        => to_clob('JSON RECEIVED: ' || l_json_string),
                              object_name     => g_package_name,
                              sub_object_name => l_func_name,
                              owner           => g_package_owner);
    
        g_error := 'pk_webservices.call_ws PASSED';
        l_json  := json_object_t(l_json_string);
    
        -- get status
        l_json_status := l_json.get_string('STATUS');
    
        -- error handling
        IF l_json_status != 'OK'
        THEN
            BEGIN
                g_error := l_json.get_string('MESSAGE.CODE');
                g_error := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => g_error);
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
            IF g_error IS NULL
            THEN
                g_error := 'UNEXPECTED ERROR WHEN OBTAINING JSON FROM INTERFACES';
            END IF;
            RAISE g_exception_control;
        END IF;
    
        g_error      := 'ERRO A TRATAR STOCK_INFO';
        o_info_stock := l_json.get_object('CONTENT').get_string('STOCK_INFO');
    
        RETURN TRUE;
    EXCEPTION
        WHEN function_user_exeception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END check_pharm_info_stock;

END pk_api_pfh_out;
/
