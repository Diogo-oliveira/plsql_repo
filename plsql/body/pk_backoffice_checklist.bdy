/*-- Last Change Revision: $Rev: 2026770 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:50 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_checklist IS

    -- Private type declarations

    -- Private constant declarations
    g_detail_level_general CONSTANT VARCHAR2(1 CHAR) := 'G';
    g_detail_level_history CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations
    /**
    * Creates a new checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_inst                   Institution/facility
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist              Generated ID for checklist
    * @param   o_checklist_version      Generated ID for checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION create_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_inst                 IN institution.id_institution%TYPE,
        i_name                 IN checklist_version.name%TYPE,
        i_flg_type             IN checklist_version.flg_type%TYPE,
        i_profile_list         IN table_table_varchar,
        i_clin_service_list    IN table_number,
        i_item_list            IN table_varchar,
        i_item_profile_list    IN table_table_number,
        i_item_dependence_list IN table_table_varchar,
        o_cnt_creator          OUT checklist.flg_content_creator%TYPE,
        o_checklist            OUT checklist.id_checklist%TYPE,
        o_checklist_version    OUT checklist_version.id_checklist_version%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
    
        l_ret               BOOLEAN;
        l_checklist         checklist.id_checklist%TYPE;
        l_checklist_version checklist_version.id_checklist_version%TYPE;
        l_cnt_creator       checklist.flg_content_creator%TYPE;
        l_internal_name     checklist.internal_name%TYPE;
        l_content           checklist.id_content%TYPE;
    
    BEGIN
        --Backoffice will only create checklists for the institution
        l_cnt_creator := pk_checklist_core.g_chklst_flg_creator_inst;
        l_content     := NULL;
    
        --In checklist creation, the checklist name is also used as internal name
        --Internal name is concatenated with the instID in order to be possible create a checklist 
        -- with same name by different facilites in a multi-institution environment
        l_internal_name := 'CHK_INST_' || i_inst || '_' || i_name;
    
        g_error := 'Calling pk_checklist_core.create_checklist';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'create_checklist');
    
        l_ret := pk_checklist_core.create_checklist(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_content_creator      => l_cnt_creator,
                                                    i_internal_name        => l_internal_name,
                                                    i_content              => l_content,
                                                    i_name                 => i_name,
                                                    i_flg_type             => i_flg_type,
                                                    i_profile_list         => i_profile_list,
                                                    i_clin_service_list    => i_clin_service_list,
                                                    i_item_list            => i_item_list,
                                                    i_item_profile_list    => i_item_profile_list,
                                                    i_item_dependence_list => i_item_dependence_list,
                                                    o_checklist            => l_checklist,
                                                    o_checklist_version    => l_checklist_version,
                                                    o_error                => o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        g_error := 'Insert checklist_inst';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'create_checklist');
    
        INSERT INTO checklist_inst
            (flg_content_creator, internal_name, id_institution, id_checklist, flg_available, flg_status)
        VALUES
            (l_cnt_creator, l_internal_name, i_inst, l_checklist, pk_alert_constant.g_yes, pk_alert_constant.g_active);
    
        o_cnt_creator       := l_cnt_creator;
        o_checklist         := l_checklist;
        o_checklist_version := l_checklist_version;
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'create_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'create_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END create_checklist;

    /**
    * Updates definitions of a checklist creating a new version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_checklist              ID of checklist to be updated
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist_version      Generated ID for new checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    * @value   i_cnt_creator            {*} 'A' ALERT {*} 'I' Institution
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION update_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_checklist             IN checklist.id_checklist%TYPE,
        i_name                  IN checklist_version.name%TYPE,
        i_flg_type              IN checklist_version.flg_type%TYPE,
        i_profile_list          IN table_table_varchar,
        i_clin_service_list     IN table_number,
        i_item_list             IN table_varchar,
        i_item_profile_list     IN table_table_number,
        i_item_dependence_list  IN table_table_varchar,
        o_new_checklist_version OUT checklist_version.id_checklist_version%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        e_checklist_notfound  EXCEPTION;
        e_function_call_error EXCEPTION;
    
        l_ret               BOOLEAN;
        l_checklist_version checklist_version.id_checklist_version%TYPE;
        l_internal_name     checklist.internal_name%TYPE;
        l_cnt_creator       checklist.flg_content_creator%TYPE;
    BEGIN
    
        --Backoffice will only edit checklists for the institution
        l_cnt_creator := pk_checklist_core.g_chklst_flg_creator_inst;
    
        g_error := 'Get internal name';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'update_checklist');
        BEGIN
            SELECT chk.internal_name
              INTO l_internal_name
              FROM checklist chk
             WHERE chk.flg_content_creator = l_cnt_creator
               AND chk.id_checklist = i_checklist;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'Checklist not found (flg_content_creator=' || l_cnt_creator || ', id_checklist=' ||
                           i_checklist || ')';
                RAISE e_checklist_notfound;
            WHEN OTHERS THEN
                RAISE;
        END;
    
        l_ret := pk_checklist_core.update_checklist(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_content_creator       => l_cnt_creator,
                                                    i_internal_name         => l_internal_name,
                                                    i_name                  => i_name,
                                                    i_flg_type              => i_flg_type,
                                                    i_profile_list          => i_profile_list,
                                                    i_clin_service_list     => i_clin_service_list,
                                                    i_item_list             => i_item_list,
                                                    i_item_profile_list     => i_item_profile_list,
                                                    i_item_dependence_list  => i_item_dependence_list,
                                                    o_new_checklist_version => l_checklist_version,
                                                    o_error                 => o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        o_new_checklist_version := l_checklist_version;
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_checklist_notfound THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLERRM,
                                              i_sqlerrm  => NULL,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'update_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'update_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'update_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END update_checklist;

    /**
    * Cancels a checklist
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_cnt_creator   Checklist content creator 
    * @param   i_checklist     Checklist ID to cancel
    * @param   i_cancel_reason Cancel reason ID
    * @param   i_cancel_notes  Cancelation notes
    * @param   o_error         Error information
    *
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION cancel_checklist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_checklist     IN checklist.id_checklist%TYPE,
        i_cancel_reason IN checklist.id_cancel_reason%TYPE,
        i_cancel_notes  IN checklist.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_checklist_notfound  EXCEPTION;
        e_function_call_error EXCEPTION;
    
        l_ret           BOOLEAN;
        l_internal_name checklist.internal_name%TYPE;
        l_cnt_creator   checklist.flg_content_creator%TYPE;
    BEGIN
    
        --Backoffice will only cancel checklists for the institution
        l_cnt_creator := pk_checklist_core.g_chklst_flg_creator_inst;
    
        g_error := 'Get internal name';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'cancel_checklist');
        BEGIN
            SELECT chk.internal_name
              INTO l_internal_name
              FROM checklist chk
             WHERE chk.flg_content_creator = l_cnt_creator
               AND chk.id_checklist = i_checklist;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'Checklist not found (flg_content_creator=' || l_cnt_creator || ', id_checklist=' ||
                           i_checklist || ')';
                RAISE e_checklist_notfound;
            WHEN OTHERS THEN
                RAISE;
        END;
    
        l_ret := pk_checklist_core.cancel_checklist(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_content_creator => l_cnt_creator,
                                                    i_internal_name   => l_internal_name,
                                                    i_cancel_reason   => i_cancel_reason,
                                                    i_cancel_notes    => i_cancel_notes,
                                                    o_error           => o_error);
        IF l_ret = FALSE
        THEN
            RAISE e_function_call_error;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_checklist_notfound THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLERRM,
                                              i_sqlerrm  => NULL,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END cancel_checklist;

    /**
    * Gets detailed information about a checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_cnt_creator            Checklist content creator 
    * @param   i_checklist              Checklist ID
    * @param   i_detail_level           Detail level 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_detail_level {*} 'G' General {*} 'H' History
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-May-10
    */
    FUNCTION get_checklist_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_cnt_creator          IN checklist.flg_content_creator%TYPE,
        i_checklist            IN checklist.id_checklist%TYPE,
        i_detail_level         IN VARCHAR2,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        e_not_implemented     EXCEPTION;
    
        l_ret           BOOLEAN;
        l_internal_name checklist_version.internal_name%TYPE;
        l_version       checklist_version.version%TYPE;
    BEGIN
        IF i_detail_level = g_detail_level_general
        THEN
            g_error := 'Get current version for checklist';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => 'get_checklist_detail');
        
            SELECT internal_name, version
              INTO l_internal_name, l_version
              FROM v_checklist_version vchkv
             WHERE vchkv.flg_content_creator = i_cnt_creator
               AND vchkv.id_checklist = i_checklist;
        
            g_error := 'Get last checklist info';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => 'get_checklist_detail');
        
            l_ret := pk_checklist_core.get_checklist(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_content_creator      => i_cnt_creator,
                                                     i_internal_name        => l_internal_name,
                                                     i_version              => l_version,
                                                     o_checklist_info       => o_checklist_info,
                                                     o_profile_list         => o_profile_list,
                                                     o_clin_service_list    => o_clin_service_list,
                                                     o_item_list            => o_item_list,
                                                     o_item_profile_list    => o_item_profile_list,
                                                     o_item_dependence_list => o_item_dependence_list,
                                                     o_error                => o_error);
        
            IF l_ret = FALSE
            THEN
                RAISE e_function_call_error;
            END IF;
        
        ELSIF i_detail_level = g_detail_level_history
        THEN
            --Currently, the functionality to show history is not implemented
            g_error := 'Get checklist info from historical: Not implemented yet';
            RAISE e_not_implemented;
        ELSE
            g_error := 'Unexpected value for input parameter i_detail_level: ' || i_detail_level;
            RAISE e_not_implemented;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_checklist_detail',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_checklist_detail',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_checklist_detail;

    /**
    * Get a list of checklists in the facility
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility 
    * @param   o_list         Checklist list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   21-May-10
    */
    FUNCTION get_checklist_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Input arguments: i_prof = ' || i_prof.id || ', i_inst = ' || i_inst;
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'get_checklist_list');
    
        g_error := 'Open o_list';
        OPEN o_list FOR
            SELECT vchkv.flg_content_creator,
                   vchkv.internal_name,
                   vchkv.version,
                   vchkv.id_checklist,
                   vchkv.id_checklist_version,
                   (CASE vchkv.flg_use_translation
                       WHEN pk_alert_constant.g_yes THEN
                        pk_translation.get_translation(i_lang, vchkv.code_name)
                       ELSE
                        vchkv.name
                   END) name,
                   pk_utils.concat_table(CAST(MULTISET (SELECT s.name || ' - ' ||
                                                      pk_message.get_message(i_lang, pt.code_profile_template) profile_desc
                                                 FROM profile_template pt
                                                INNER JOIN checklist_prof_templ chkp
                                                   ON pt.id_profile_template = chkp.id_profile_template
                                                INNER JOIN software s
                                                   ON s.id_software = pt.id_software
                                                WHERE vchkv.id_checklist_version = chkp.id_checklist_version
                                                  AND vchkv.flg_content_creator = chkp.flg_content_creator
                                                  AND pt.flg_available = 'Y'
                                                  AND s.flg_viewer = 'N'
                                                ORDER BY profile_desc) AS table_varchar),
                                         ', ') checklist_profile,
                   chki.flg_status flg_checklist_inst_status,
                   chk.flg_status flg_checklist_status,
                   (CASE chk.flg_content_creator
                       WHEN pk_checklist_core.g_chklst_flg_creator_inst THEN
                        pk_alert_constant.g_yes
                       ELSE
                        pk_alert_constant.g_no
                   END) flg_editable,
                   (CASE chk.flg_content_creator
                       WHEN pk_checklist_core.g_chklst_flg_creator_inst THEN
                        pk_alert_constant.g_yes
                       ELSE
                        pk_alert_constant.g_no
                   END) flg_cancelable
              FROM checklist_inst chki
             INNER JOIN checklist chk
                ON chk.id_checklist = chki.id_checklist
               AND chk.flg_content_creator = chki.flg_content_creator
             INNER JOIN v_checklist_version vchkv
                ON chk.id_checklist = vchkv.id_checklist
               AND chk.flg_content_creator = vchkv.flg_content_creator
             WHERE chki.flg_available = pk_alert_constant.g_yes
               AND chk.flg_available = pk_alert_constant.g_yes
               AND chki.id_institution = i_inst
             ORDER BY flg_checklist_status, flg_checklist_inst_status, name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_checklist_list',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_checklist_list;

    /**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_checklist_version      Checklist version ID
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   04-Jun-10
    */
    FUNCTION get_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist_version.flg_content_creator%TYPE,
        i_checklist_version    IN checklist_version.id_checklist_version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_checklist_core.get_checklist(i_lang                 => i_lang,
                                               i_prof                 => i_prof,
                                               i_content_creator      => i_content_creator,
                                               i_checklist_version    => i_checklist_version,
                                               o_checklist_info       => o_checklist_info,
                                               o_profile_list         => o_profile_list,
                                               o_clin_service_list    => o_clin_service_list,
                                               o_item_list            => o_item_list,
                                               o_item_profile_list    => o_item_profile_list,
                                               o_item_dependence_list => o_item_dependence_list,
                                               o_error                => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_checklist',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_checklist_info);
            pk_types.open_my_cursor(o_profile_list);
            pk_types.open_my_cursor(o_clin_service_list);
            pk_types.open_my_cursor(o_item_list);
            pk_types.open_my_cursor(o_item_profile_list);
            pk_types.open_my_cursor(o_item_dependence_list);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_checklist;

    /**
    * Changes the status of a checklist in an institution to active/inactive
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_cnt_creator  Checklist content creator 
    * @param   i_checklist    Checklist ID 
    * @param   i_status       Status
    * @param   o_error        Error information
    *
    * @value   i_status       {*} 'A' Active {*} 'I' Inactive
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   21-May-10
    */
    FUNCTION set_checklist_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_cnt_creator IN checklist.flg_content_creator%TYPE,
        i_checklist   IN checklist.id_checklist%TYPE,
        i_status      IN checklist_inst.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_internal_name       checklist_inst.internal_name%TYPE;
    BEGIN
        g_error := 'Input arguments: i_prof = ' || i_prof.id || ', i_inst = ' || i_inst || ', i_cnt_creator = ' ||
                   i_cnt_creator || ', i_checklist = ' || i_checklist || ', i_status = ' || i_status;
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'set_checklist_status');
    
        g_error := 'Update checklist_inst';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'set_checklist_status');
    
        UPDATE checklist_inst ci
           SET ci.flg_status = i_status
         WHERE ci.flg_available = pk_alert_constant.g_yes
           AND ci.id_institution = i_inst
           AND ci.flg_content_creator = i_cnt_creator
           AND ci.id_checklist = i_checklist
        RETURNING ci.internal_name INTO l_internal_name;
    
        -- When a checklist is inactivated at Backoffice it should cancel blank instances of this checklist in FrontOffice
        IF i_status = pk_checklist_core.g_chki_flg_status_inactive
        THEN
            IF NOT pk_checklist_core.cancel_pat_checklist_empty(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_content_creator => i_cnt_creator,
                                                                i_internal_name   => l_internal_name,
                                                                i_inst            => i_inst,
                                                                o_error           => o_error)
            THEN
                RAISE e_function_call_error;
            END IF;
        END IF;
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'create_checklist',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_checklist_status',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_checklist_status;

    /**
    * Get a list of available software by institution that can use Checklists functionality
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   o_soft_list    A list of available software
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   07-Jun-10
    */
    FUNCTION get_software_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_soft_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_soft_list FOR
            SELECT s.id_software id,
                   s.name name,
                   pk_translation.get_translation(i_lang, s.code_software) subtitle,
                   REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') subtitle_no_br
              FROM software_institution si
             INNER JOIN software s
                ON s.id_software = si.id_software
             WHERE s.flg_mni = pk_alert_constant.g_yes
               AND si.id_institution = i_inst
               AND s.id_software != 26
               AND EXISTS (SELECT 0
                      FROM checklist_usage_permission chkup
                     WHERE chkup.id_software = s.id_software
                       AND chkup.flg_available = pk_alert_constant.g_available)
             ORDER BY name;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_software_list',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_software_list;

    /**
    * Get a list of available templates by software that can use Checklists functionality
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_soft         Software ID
    * @param   o_profile_list List of available profiles
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   07-Jun-10
    */
    FUNCTION get_template_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN institution.id_institution%TYPE,
        i_soft         IN software.id_software%TYPE,
        o_profile_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market market.id_market%TYPE;
    
    BEGIN
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_inst),
                   0)
          INTO l_market
          FROM dual;
    
        OPEN o_profile_list FOR
            SELECT t.id_profile_template,
                   pk_translation.get_translation(i_lang, t.code_profile_template) profile_template,
                   t.id_category,
                   t.id_parent
              FROM (SELECT pt.id_profile_template,
                           pt.code_profile_template,
                           ptm.id_market,
                           ptc.id_category,
                           pt.id_parent,
                           row_number() over(PARTITION BY pt.id_profile_template ORDER BY ptm.id_market DESC, pti.id_institution DESC) rn
                      FROM profile_template pt
                     INNER JOIN profile_template_inst pti
                        ON pt.id_profile_template = pti.id_profile_template
                     INNER JOIN profile_template_market ptm
                        ON pt.id_profile_template = ptm.id_profile_template
                     INNER JOIN profile_template_category ptc
                        ON pt.id_profile_template = ptc.id_profile_template
                     INNER JOIN checklist_usage_permission chkup
                        ON pt.id_software = chkup.id_software
                       AND ptc.id_category = chkup.id_category
                     WHERE pti.id_institution IN (i_inst, 0)
                       AND ptm.id_market IN (l_market, 0)
                       AND pt.id_software = i_soft
                       AND pt.flg_available = 'Y'
                       AND NOT EXISTS (SELECT 'X'
                              FROM profile_template pt2
                             WHERE pt2.id_profile_template_appr = pt.id_profile_template)) t
             WHERE t.rn = 1
             ORDER BY id_category, profile_template;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_template_list',
                                              o_error    => o_error);
            ROLLBACK;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_template_list;

    /**
    * Gets clinical services (specialties) that are defined to specific software in the institution
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_soft         List of software ID
    * @param   o_profile_list List of clinical services
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   10-Jun-10
    */
    FUNCTION get_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN institution.id_institution%TYPE,
        i_soft_list    IN table_number,
        o_clin_service OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Fech clinical services witch the profissional is allocated';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package,
                                       sub_object_name => 'get_prof_clin_serv_list');
        OPEN o_clin_service FOR
            SELECT DISTINCT cs.id_clinical_service,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                            cs.rank
              FROM dep_clin_serv dcs
             INNER JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             INNER JOIN department dp
                ON dp.id_department = dcs.id_department
             INNER JOIN dept dpt
                ON dpt.id_dept = dp.id_dept
             INNER JOIN software_dept sd
                ON dpt.id_dept = sd.id_dept
             INNER JOIN software_institution si
                ON si.id_software = sd.id_software
             INNER JOIN institution i
                ON i.id_institution = si.id_institution
               AND i.id_institution = dpt.id_institution
             WHERE sd.id_software IN (SELECT column_value
                                        FROM TABLE(i_soft_list))
               AND i.id_institution = i_inst
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cs.flg_available = pk_alert_constant.g_yes
               AND dp.flg_available = pk_alert_constant.g_yes
               AND dpt.flg_available = pk_alert_constant.g_yes
             ORDER BY cs.rank, desc_clin_serv;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_clin_serv_list',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_clin_serv_list;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_backoffice_checklist;
/
