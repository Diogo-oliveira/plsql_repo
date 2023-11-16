/*-- Last Change Revision: $Rev: 2026865 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_checklist_core IS

    -- Private type declarations

    -- Private constant declarations
    g_domain_chk_flg_status     CONSTANT sys_domain.code_domain%TYPE := 'CHECKLIST.FLG_STATUS';
    g_domain_chkv_flg_type      CONSTANT sys_domain.code_domain%TYPE := 'CHECKLIST_VERSION.FLG_TYPE';
    g_domain_pck_flg_status     CONSTANT sys_domain.code_domain%TYPE := 'PAT_CHECKLIST.FLG_STATUS';
    g_domain_pck_flg_prg_status CONSTANT sys_domain.code_domain%TYPE := 'PAT_CHECKLIST.FLG_PROGRESS_STATUS';
    g_domain_pck_flg_answer     CONSTANT sys_domain.code_domain%TYPE := 'CHECKLIST_ITEM_DEP.FLG_ANSWER';
    g_msg_default_content       CONSTANT sys_message.code_message%TYPE := 'FO_CHECKLIST_T030';
    g_msg_auto_cancelled        CONSTANT sys_message.code_message%TYPE := 'BO_CHECKLIST_M004';
    -- Specific cancel reason: Automatically cancelled
    g_cancel_reason_auto_cancelled CONSTANT cancel_reason.id_cancel_reason%TYPE := 3151;

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Returns a list of unanswered items of a patient's checklist
    *
    * @param   i_pat_checklist Association ID (patient's checklist instance)
    *
    * @return  Collection of unanswered items (Pipelined function)
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   13-Jul-10
    */
    FUNCTION get_unanswered_items(i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE) RETURN t_coll_tab_unanswered_item
        PIPELINED IS
        l_unanswered_item t_rec_unanswered_item;
        CURSOR c_unanswered_items IS
            SELECT chki.flg_content_creator, chki.id_checklist_item
              FROM checklist_item chki
             INNER JOIN pat_checklist pchk
                ON pchk.flg_content_creator = chki.flg_content_creator
               AND pchk.id_checklist_version = chki.id_checklist_version
             WHERE pchk.id_pat_checklist = i_pat_checklist
               AND NOT EXISTS (SELECT 0
                      FROM v_pat_checklist_det vpchk
                     WHERE vpchk.id_pat_checklist = pchk.id_pat_checklist
                       AND vpchk.flg_content_creator = chki.flg_content_creator
                       AND vpchk.id_checklist_item = chki.id_checklist_item
                       AND vpchk.flg_answer IS NOT NULL);
    
    BEGIN
        OPEN c_unanswered_items;
        LOOP
            FETCH c_unanswered_items
                INTO l_unanswered_item;
            EXIT WHEN c_unanswered_items%NOTFOUND;
            PIPE ROW(l_unanswered_item);
        END LOOP;
        CLOSE c_unanswered_items;
        RETURN;
    END get_unanswered_items;

    /**
    * Validate if a patient's checklist can be considered fully filled in
    *
    * i_pat_checklist         Association ID (patient's checklist instance)          
    *
    * @return  True: Checklist was completed; False: Checklist was not completed
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   13-Jul-10
    */
    FUNCTION is_checklist_completed(i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE) RETURN BOOLEAN IS
        l_completed     PLS_INTEGER;
        l_bln_completed BOOLEAN;
    BEGIN
        -- Conditions for a checklist be considered fully completed:
        -- (-) All items that have no dependency must have an answer.
        -- (-) All items that have dependencies must have an anwer if dependency condition is verified.
    
        BEGIN
            --Validating if any condition is not met
            SELECT 0
              INTO l_completed
              FROM dual
             WHERE EXISTS (
                    --Unanswered items that have no dependency
                    SELECT flg_content_creator, id_checklist_item
                      FROM TABLE(pk_checklist_core.get_unanswered_items(i_pat_checklist)) ui
                     WHERE NOT EXISTS (SELECT 0
                              FROM checklist_item_dep chkid
                             WHERE chkid.flg_content_creator = ui.flg_content_creator
                               AND chkid.id_checklist_item_targ = ui.id_checklist_item)
                    UNION ALL
                    --Unanswered items that have dependency and the dependency condition is verified
                    SELECT chkid.flg_content_creator, chkid.id_checklist_item_targ
                      FROM checklist_item_dep chkid
                     WHERE (chkid.flg_content_creator, chkid.id_checklist_item_targ) IN
                           (SELECT flg_content_creator, id_checklist_item
                              FROM TABLE(pk_checklist_core.get_unanswered_items(i_pat_checklist)))
                       AND EXISTS (SELECT 0
                              FROM v_pat_checklist_det vpchk
                             WHERE vpchk.id_pat_checklist = i_pat_checklist
                               AND vpchk.flg_content_creator = chkid.flg_content_creator
                               AND vpchk.id_checklist_item = chkid.id_checklist_item_src
                               AND vpchk.flg_answer = chkid.flg_answer));
        EXCEPTION
            WHEN no_data_found THEN
                l_completed := 1;
        END;
    
        IF l_completed = 1
        THEN
            l_bln_completed := TRUE;
        ELSE
            l_bln_completed := FALSE;
        END IF;
    
        RETURN l_bln_completed;
    
    END is_checklist_completed;

    /**
    * Return professional's profile template (including current and soap/default approach if available) within institution and software
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * s          
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jul-10
    */
    FUNCTION get_prof_profiles
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
        l_current_profile      profile_template.id_profile_template%TYPE;
        l_tab_profile_template table_number;
    BEGIN
        g_error           := 'Get current profile ID for professional';
        l_current_profile := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'Get related profiles (soap/default approach if available)';
        SELECT id_profile_template
          BULK COLLECT
          INTO l_tab_profile_template
          FROM (SELECT pt.id_profile_template
                  FROM profile_template pt
                 WHERE LEVEL <= 2
                   AND pt.flg_available = pk_alert_constant.g_yes
                 START WITH pt.id_profile_template = l_current_profile
                CONNECT BY PRIOR pt.id_profile_template_appr = pt.id_profile_template
                UNION
                SELECT pt.id_profile_template
                  FROM profile_template pt
                 WHERE LEVEL <= 2
                   AND pt.flg_available = pk_alert_constant.g_yes
                 START WITH pt.id_profile_template = l_current_profile
                CONNECT BY PRIOR pt.id_profile_template = pt.id_profile_template_appr);
    
        RETURN l_tab_profile_template;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_owner,
                                                  i_package  => g_package,
                                                  i_function => 'get_prof_profiles',
                                                  o_error    => l_error);
                RETURN table_number();
            END;
    END get_prof_profiles;

    /**
    * Get a clinical services (specialities) list to witch the profissional is allocated by sofware and institution
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   o_clin_service_list  Clinical services list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   10-Jun-10
    */
    FUNCTION get_prof_clin_serv_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_clin_service_list OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Fech clinical services witch the profissional is allocated';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_prof_clin_serv_list');
        SELECT DISTINCT cs.id_clinical_service
          BULK COLLECT
          INTO o_clin_service_list
          FROM prof_dep_clin_serv pdcs
         INNER JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
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
           AND i.id_institution = pdcs.id_institution
         WHERE sd.id_software = i_prof.software
           AND pdcs.flg_status = pk_alert_constant.g_status_selected
           AND pdcs.id_professional = i_prof.id
           AND i.id_institution = i_prof.institution
           AND dcs.flg_available = pk_alert_constant.g_yes
           AND cs.flg_available = pk_alert_constant.g_yes
           AND dp.flg_available = pk_alert_constant.g_yes
           AND dpt.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_clin_service_list := table_number();
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_prof_clin_serv_list',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_clin_serv_list;

    /**
    * Returns if exists a checklist identified by content creator & internal name
    *
    * @param   i_content_creator   Content creator
    * @param   i_internal_name     Checklist internal name
    *
    * @value   i_content_creator   {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    *
    * @return  True or False on exists or not a checklist
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jun-10
    */
    FUNCTION exist_checklist
    (
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE
    ) RETURN BOOLEAN IS
        l_exist_checklist VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        SELECT nvl((SELECT pk_alert_constant.g_yes
                     FROM checklist chk
                    WHERE chk.flg_content_creator = i_content_creator
                      AND chk.internal_name = i_internal_name),
                   pk_alert_constant.g_no)
          INTO l_exist_checklist
          FROM dual;
    
        RETURN(l_exist_checklist = pk_alert_constant.g_yes);
    
    END exist_checklist;

    /**
    * Returns if exists a checklist identified by content creator & checklist ID
    *
    * @param   i_content_creator   Content creator
    * @param   i_checklist         Checklist ID
    *
    * @value   i_content_creator   {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    *
    * @return  True or False on exists or not a checklist
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jun-10
    */
    FUNCTION exist_checklist
    (
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_checklist       IN checklist.id_checklist%TYPE
    ) RETURN BOOLEAN IS
        l_exist_checklist VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        SELECT nvl((SELECT pk_alert_constant.g_yes
                     FROM checklist chk
                    WHERE chk.flg_content_creator = i_content_creator
                      AND chk.id_checklist = i_checklist),
                   pk_alert_constant.g_no)
          INTO l_exist_checklist
          FROM dual;
    
        RETURN(l_exist_checklist = pk_alert_constant.g_yes);
    
    END exist_checklist;

    /**
    * Returns if exists a checklist identified by content creator, internal name and version
    *
    * @param   i_content_creator   Content creator
    * @param   i_internal_name     Checklist internal name
    * @param   i_version           Checklist version number
    *
    * @value   i_content_creator   {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    *
    * @return  True or False on exists or not a checklist
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   01-Jun-10
    */
    FUNCTION exist_checklist
    (
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE,
        i_version         IN checklist_version.version%TYPE
    ) RETURN BOOLEAN IS
        l_exist_checklist VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        SELECT nvl((SELECT pk_alert_constant.g_yes
                     FROM checklist_version chkv
                    WHERE chkv.flg_content_creator = i_content_creator
                      AND chkv.internal_name = i_internal_name
                      AND chkv.version = i_version),
                   pk_alert_constant.g_no)
          INTO l_exist_checklist
          FROM dual;
    
        RETURN(l_exist_checklist = pk_alert_constant.g_yes);
    
    END exist_checklist;
    /**
    * Creates a new checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_content                Content ID
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
    * @value   i_content_creator        {*} 'A' Checklist created by ALERT {*} 'I' Checklist created by Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-May-10
    */
    FUNCTION create_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist.flg_content_creator%TYPE,
        i_internal_name        IN checklist.internal_name%TYPE,
        i_content              IN checklist.id_content%TYPE,
        i_name                 IN checklist_version.name%TYPE,
        i_flg_type             IN checklist_version.flg_type%TYPE,
        i_profile_list         IN table_table_varchar,
        i_clin_service_list    IN table_number,
        i_item_list            IN table_varchar,
        i_item_profile_list    IN table_table_number,
        i_item_dependence_list IN table_table_varchar,
        o_checklist            OUT checklist.id_checklist%TYPE,
        o_checklist_version    OUT checklist_version.id_checklist_version%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_nonunique_checklist EXCEPTION;
    
        l_ret               BOOLEAN;
        l_checklist         checklist.id_checklist%TYPE;
        l_checklist_version checklist_version.id_checklist_version%TYPE;
    
    BEGIN
        --Validate if already exist a checklist with this internal name & content creator
        g_error := 'Validate checklist';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'create_checklist');
        IF exist_checklist(i_content_creator, i_internal_name)
        THEN
            RAISE e_nonunique_checklist;
        END IF;
    
        -- Creating a new checklist in CHECKLIST table
        g_error := 'Insert checklist';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'create_checklist');
        INSERT INTO checklist
            (id_checklist, flg_content_creator, internal_name, flg_available, flg_status, id_content)
        VALUES
            (seq_checklist.nextval,
             i_content_creator,
             i_internal_name,
             pk_alert_constant.g_yes,
             pk_checklist_core.g_chklst_flg_status_active,
             i_content)
        RETURNING id_checklist INTO l_checklist;
    
        g_error := 'Insert checklist_version';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'create_checklist');
    
        -- Creates 1st checklist version 
        l_ret := update_checklist(i_lang                  => i_lang,
                                  i_prof                  => i_prof,
                                  i_content_creator       => i_content_creator,
                                  i_internal_name         => i_internal_name,
                                  i_name                  => i_name,
                                  i_flg_type              => i_flg_type,
                                  i_profile_list          => i_profile_list,
                                  i_clin_service_list     => i_clin_service_list,
                                  i_item_list             => i_item_list,
                                  i_item_profile_list     => i_item_profile_list,
                                  i_item_dependence_list  => i_item_dependence_list,
                                  o_new_checklist_version => l_checklist_version,
                                  o_error                 => o_error);
    
        IF l_ret
        THEN
            o_checklist         := l_checklist;
            o_checklist_version := l_checklist_version;
        
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN e_nonunique_checklist THEN
            DECLARE
                l_warn_message VARCHAR2(1000 CHAR);
                l_warn_title   VARCHAR2(1000 CHAR);
            BEGIN
                l_warn_title   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'BO_CHECKLIST_T005');
                l_warn_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'BO_CHECKLIST_M003');
            
                pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                    i_sqlcode     => NULL,
                                                    i_sqlerrm     => NULL,
                                                    i_message     => NULL,
                                                    i_owner       => g_owner,
                                                    i_package     => g_package,
                                                    i_function    => 'create_checklist',
                                                    i_action_type => 'U',
                                                    i_action_msg  => l_warn_message,
                                                    i_msg_title   => l_warn_title,
                                                    o_error       => o_error);
            
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'create_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_checklist;

    /**
    * Updates definitions of a checklist (identified by content creator and internal name) creating a new version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
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
    * @value   i_content_creator            {*} 'A' ALERT {*} 'I' Institution
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
        i_content_creator       IN checklist.flg_content_creator%TYPE,
        i_internal_name         IN checklist.internal_name%TYPE,
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
        e_checklist_notfound EXCEPTION;
    
        l_rowid             ROWID;
        l_timestamp         TIMESTAMP WITH TIME ZONE;
        l_item_count        PLS_INTEGER;
        l_item_dep_targ     checklist_item_dep.id_checklist_item_targ%TYPE;
        l_item_dep_src      checklist_item_dep.id_checklist_item_targ%TYPE;
        l_checklist         checklist.id_checklist%TYPE;
        l_checklist_version checklist_version.id_checklist_version%TYPE;
    
        l_version checklist_version.version%TYPE;
    
        l_tab_item_id          table_number;
        l_tab_item_profiles    table_number;
        l_tab_item_subscripts  table_number;
        l_tab_item_dependence  table_varchar;
        l_tab_item_dep_answers table_varchar;
        l_tab_profile_id       table_number;
        l_tab_profile_write    table_varchar;
        l_tab_profile_default  table_varchar;
    
    BEGIN
        l_timestamp := current_timestamp;
    
        --Validate if already exist a checklist with this content creator & internal name
        g_error := 'Validate checklist';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
        IF NOT exist_checklist(i_content_creator, i_internal_name)
        THEN
            RAISE e_checklist_notfound;
        END IF;
    
        --Calculate version number
        g_error := 'Calculate version number';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
        SELECT chk.id_checklist, nvl(version, 0), vchkv.row_id
          INTO l_checklist, l_version, l_rowid
          FROM checklist chk
          LEFT JOIN v_checklist_version vchkv
            ON chk.id_checklist = vchkv.id_checklist
           AND chk.flg_content_creator = vchkv.flg_content_creator
         WHERE chk.flg_content_creator = i_content_creator
           AND chk.internal_name = i_internal_name;
    
        -- Make previous version outdated
        IF l_rowid IS NOT NULL
        THEN
            UPDATE checklist_version chkv
               SET chkv.dt_retire_time = l_timestamp
             WHERE chkv.rowid = l_rowid;
        
        END IF;
    
        -- Creating a new version
        g_error := 'Creating a new version';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
        l_version := l_version + 1;
    
        INSERT INTO checklist_version
            (id_checklist_version,
             flg_content_creator,
             internal_name,
             version,
             id_checklist,
             dt_checklist_version,
             flg_type,
             name,
             code_name,
             flg_use_translation,
             id_professional,
             dt_create_time,
             dt_retire_time)
        VALUES
            (seq_checklist_version.nextval,
             i_content_creator,
             i_internal_name,
             l_version,
             l_checklist,
             l_timestamp,
             i_flg_type,
             (CASE i_content_creator WHEN pk_checklist_core.g_chklst_flg_creator_inst THEN i_name END),
             (CASE i_content_creator WHEN pk_checklist_core.g_chklst_flg_creator_alert THEN
              'CHECKLIST_VERSION.CODE_NAME.' || seq_checklist_version.nextval END),
             (CASE i_content_creator WHEN pk_checklist_core.g_chklst_flg_creator_alert THEN pk_alert_constant.g_yes ELSE
              pk_alert_constant.g_no END),
             i_prof.id,
             l_timestamp,
             NULL)
        RETURNING id_checklist_version INTO l_checklist_version;
    
        --If content creator is ALERT (when this function is used internally to create content), then insert Checklist name into translation
        IF i_content_creator = pk_checklist_core.g_chklst_flg_creator_alert
        THEN
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => 'CHECKLIST_VERSION.CODE_NAME.' || l_checklist_version,
                                                   i_desc_trans => i_name);
        END IF;
    
        -- Saving speciality(es)  
        g_error := 'Insert checklist_clin_serv';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
    
        FORALL i IN i_clin_service_list.first .. i_clin_service_list.last
            INSERT INTO checklist_clin_serv
                (flg_content_creator, internal_name, version, id_checklist_version, id_clinical_service)
            VALUES
                (i_content_creator, i_internal_name, l_version, l_checklist_version, i_clin_service_list(i));
    
        --Preparing collections to be used by a forall
        g_error := 'Preparing info about authorized profiles';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
    
        l_tab_profile_id := table_number();
        l_tab_profile_id.extend(i_profile_list.count);
        l_tab_profile_write := table_varchar();
        l_tab_profile_write.extend(i_profile_list.count);
        l_tab_profile_default := table_varchar();
        l_tab_profile_default.extend(i_profile_list.count);
    
        FOR i IN i_profile_list.first .. i_profile_list.last
        LOOP
            l_tab_profile_id(i) := to_number(i_profile_list(i) (1));
            l_tab_profile_write(i) := i_profile_list(i) (2);
            l_tab_profile_default(i) := i_profile_list(i) (3);
        END LOOP;
    
        -- Saving authorized profiles for checklist
        g_error := 'Insert checklist_prof_templ';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
        FORALL i IN i_profile_list.first .. i_profile_list.last
            INSERT INTO checklist_prof_templ
                (flg_content_creator,
                 internal_name,
                 version,
                 id_checklist_version,
                 id_profile_template,
                 flg_write,
                 flg_default)
            VALUES
                (i_content_creator,
                 i_internal_name,
                 l_version,
                 l_checklist_version,
                 l_tab_profile_id(i),
                 l_tab_profile_write(i),
                 l_tab_profile_default(i));
    
        --This collection contains the subscripts of the item themselves
        l_item_count := i_item_list.count;
        SELECT LEVEL
          BULK COLLECT
          INTO l_tab_item_subscripts
          FROM dual
        CONNECT BY LEVEL <= l_item_count;
    
        --Saving checklist's items 
        g_error := 'Insert checklist_item';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
    
        FORALL i IN i_item_list.first .. i_item_list.last
            INSERT INTO checklist_item
                (flg_content_creator,
                 internal_name,
                 version,
                 item,
                 id_checklist_item,
                 id_checklist_version,
                 item_description,
                 code_item_description,
                 flg_use_translation,
                 rank)
            VALUES
                (i_content_creator,
                 i_internal_name,
                 l_version,
                 l_tab_item_subscripts(i),
                 seq_checklist_item.nextval,
                 l_checklist_version,
                 (CASE i_content_creator
                     WHEN pk_checklist_core.g_chklst_flg_creator_inst THEN
                      i_item_list(i)
                 END),
                 (CASE i_content_creator
                     WHEN pk_checklist_core.g_chklst_flg_creator_alert THEN
                      'CHECKLIST_ITEM.CODE_ITEM_DESCRIPTION.' || seq_checklist_item.nextval
                 END),
                 (CASE i_content_creator
                     WHEN pk_checklist_core.g_chklst_flg_creator_alert THEN
                      pk_alert_constant.g_yes
                     ELSE
                      pk_alert_constant.g_no
                 END),
                 l_tab_item_subscripts(i))
            RETURNING id_checklist_item BULK COLLECT INTO l_tab_item_id;
    
        --If content creator is ALERT (when this function is used internally to create content), then insert items descriptions into translation
        IF i_content_creator = pk_checklist_core.g_chklst_flg_creator_alert
        THEN
            FOR i IN l_tab_item_id.first .. l_tab_item_id.last
            LOOP
                pk_translation.insert_into_translation(i_lang       => i_lang,
                                                       i_code_trans => 'CHECKLIST_ITEM.CODE_ITEM_DESCRIPTION.' ||
                                                                       l_tab_item_id(i),
                                                       i_desc_trans => i_item_list(i));
            END LOOP;
        END IF;
    
        -- Saving authorized profiles for items
        g_error := 'Insert checklist_item_prof_templ';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
    
        FOR x IN i_item_profile_list.first .. i_item_profile_list.last
        LOOP
            -- Saving for each item a list of authorized profiles
            l_tab_item_profiles := i_item_profile_list(x);
            FORALL i IN l_tab_item_profiles.first .. l_tab_item_profiles.last
                INSERT INTO checklist_item_prof_templ
                    (flg_content_creator, internal_name, version, item, id_profile_template, id_checklist_item)
                VALUES
                    (i_content_creator,
                     i_internal_name,
                     l_version,
                     l_tab_item_subscripts(x),
                     l_tab_item_profiles(i),
                     l_tab_item_id(x));
        
        END LOOP;
    
        --Saving dependences between items
        g_error := 'Insert checklist_item_dep';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'update_checklist');
    
        --Iteration between items
        FOR x IN i_item_dependence_list.first .. i_item_dependence_list.last
        LOOP
            -- For each item we can have (or not, if an item has no dependency) a collection with info about dependences
            l_tab_item_dependence := i_item_dependence_list(x);
        
            IF l_tab_item_dependence IS NOT NULL
               AND l_tab_item_dependence.count > 0
            THEN
                --This collection has the info: [DepensOnItemNumber, answers... ] 
                -- Answers can be a set of a minimum of 1 to a manximum of 3 values: (Y)es, (N)o, Not (A)pplicable
                --Example "[4,Y,N,A]"  means: Item x(target) depends on item 4(source) if the answer is: Yes or No or NA 
            
                l_item_dep_targ        := l_tab_item_id(x);
                l_item_dep_src         := l_tab_item_id(l_tab_item_dependence(1));
                l_tab_item_dep_answers := l_tab_item_dependence MULTISET INTERSECT
                                          table_varchar(g_pchkd_flg_answer_yes,
                                                        g_pchkd_flg_answer_no,
                                                        g_pchkd_flg_answer_na);
            
                FORALL i IN l_tab_item_dep_answers.first .. l_tab_item_dep_answers.last
                    INSERT INTO checklist_item_dep
                        (flg_content_creator, id_checklist_item_src, id_checklist_item_targ, flg_answer)
                    VALUES
                        (i_content_creator, l_item_dep_src, l_item_dep_targ, l_tab_item_dep_answers(i));
            END IF;
        END LOOP;
    
        o_new_checklist_version := l_checklist_version;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_checklist_notfound THEN
            pk_alert_exceptions.raise_error(error_name_in => 'CHECKLIST_NOT_FOUND', text_in => 'No checklist found');
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
            RETURN FALSE;
    END update_checklist;

    /**
    * Cancels a checklist
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_content_creator    Checklist content creator
    * @param   i_internal_name      Checklist internal name
    * @param   i_cancel_reason      Cancel reason ID
    * @param   i_cancel_notes       Cancelation notes
    * @param   o_error              Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION cancel_checklist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE,
        i_cancel_reason   IN checklist.id_cancel_reason%TYPE,
        i_cancel_notes    IN checklist.cancel_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'cancel_checklist';
        e_checklist_notfound      EXCEPTION;
        e_checklist_cancel_failed EXCEPTION;
        e_function_call_error     EXCEPTION;
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
        l_timestamp := current_timestamp;
    
        --Validate if already exist a checklist with this content creator & internal name
        IF NOT exist_checklist(i_content_creator, i_internal_name)
        THEN
            RAISE e_checklist_notfound;
        END IF;
    
        UPDATE checklist chk
           SET chk.flg_status       = pk_checklist_core.g_chklst_flg_status_cancelled,
               chk.id_prof_cancel   = i_prof.id,
               chk.id_cancel_reason = i_cancel_reason,
               chk.dt_cancel_time   = l_timestamp,
               chk.cancel_notes     = i_cancel_notes
         WHERE chk.flg_content_creator = i_content_creator
           AND chk.internal_name = i_internal_name
           AND chk.id_prof_cancel IS NULL;
        IF SQL%ROWCOUNT = 0
        THEN
            RAISE e_checklist_cancel_failed;
        END IF;
    
        -- When a checklist is canceled at Backoffice it should cancel blank instances of this checklist in FrontOffice
        g_error := 'CALL cancel_pat_checklist_empty';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
        IF NOT cancel_pat_checklist_empty(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_content_creator => i_content_creator,
                                          i_internal_name   => i_internal_name,
                                          o_error           => o_error)
        THEN
            RAISE e_function_call_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_checklist_cancel_failed THEN
            pk_alert_exceptions.raise_error(error_name_in => 'CHECKLIST_CANCEL_FAILED',
                                            text_in       => 'Checklist was already canceled?');
            RETURN FALSE;
        
        WHEN e_checklist_notfound THEN
            pk_alert_exceptions.raise_error(error_name_in => 'CHECKLIST_NOT_FOUND', text_in => 'No checklist found');
            RETURN FALSE;
        
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_checklist;

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
        l_internal_name checklist_version.internal_name%TYPE;
        l_version       checklist_version.version%TYPE;
    BEGIN
    
        SELECT internal_name, version
          INTO l_internal_name, l_version
          FROM checklist_version chkv
         WHERE chkv.flg_content_creator = i_content_creator
           AND chkv.id_checklist_version = i_checklist_version;
    
        RETURN pk_checklist_core.get_checklist(i_lang                 => i_lang,
                                               i_prof                 => i_prof,
                                               i_content_creator      => i_content_creator,
                                               i_internal_name        => l_internal_name,
                                               i_version              => l_version,
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
                                              i_function => 'cancel_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_checklist;

    /**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_version                Version number (is not an ID)
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
        i_internal_name        IN checklist_version.internal_name%TYPE,
        i_version              IN checklist_version.version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_checklist_notfound EXCEPTION;
        l_tab_current_profiles table_number;
        l_default_content      sys_message.desc_message%TYPE;
    BEGIN
    
        --Validate if already exist a checklist with this content creator, internal name & version
        g_error := 'Validate checklist';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_checklist');
        IF NOT exist_checklist(i_content_creator, i_internal_name, i_version)
        THEN
            RAISE e_checklist_notfound;
        END IF;
    
        l_default_content := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_default_content);
    
        l_tab_current_profiles := get_prof_profiles(i_lang => i_lang, i_prof => i_prof);
    
        --Checklist information (name,type,author,etc..)    
        OPEN o_checklist_info FOR
            SELECT chkv.flg_content_creator,
                   chkv.internal_name,
                   chkv.id_checklist,
                   chkv.flg_type,
                   pk_sysdomain.get_domain_cached(i_lang, chkv.flg_type, g_domain_chkv_flg_type) desc_type,
                   chkv.version,
                   (CASE chkv.flg_use_translation
                       WHEN pk_alert_constant.g_yes THEN
                        pk_translation.get_translation(i_lang, chkv.code_name)
                       ELSE
                        chkv.name
                   END) name,
                   chkv.dt_checklist_version,
                   pk_date_utils.date_char_tsz(i_lang, chkv.dt_checklist_version, i_prof.institution, i_prof.software) dt_checklist_version_fmt,
                   pk_date_utils.date_send_tsz(i_lang, chkv.dt_checklist_version, i_prof) dt_checklist_version_str,
                   (CASE chkv.flg_content_creator
                       WHEN pk_checklist_core.g_chklst_flg_creator_alert THEN
                        l_default_content
                       ELSE
                        pk_prof_utils.get_name_signature(i_lang, i_prof, chkv.id_professional)
                   END) prof_version,
                   chk.flg_status,
                   pk_sysdomain.get_domain_cached(i_lang, chk.flg_status, g_domain_chk_flg_status) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, chk.id_prof_cancel) prof_cancel,
                   pk_date_utils.date_send_tsz(i_lang, chk.dt_cancel_time, i_prof) dt_cancel_time_str,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, chk.id_cancel_reason) cancel_reason,
                   chk.cancel_notes
              FROM checklist_version chkv
             INNER JOIN checklist chk
                ON chk.id_checklist = chkv.id_checklist
               AND chk.flg_content_creator = chkv.flg_content_creator
             WHERE chkv.flg_content_creator = i_content_creator
               AND chkv.internal_name = i_internal_name
               AND chkv.version = i_version;
    
        --Authorized profiles for checklist    
        OPEN o_profile_list FOR
            SELECT pt.id_software,
                   s.name desc_software,
                   pt.id_profile_template,
                   pk_message.get_message(i_lang, pt.code_profile_template) desc_profile_template,
                   chkp.flg_write,
                   chkp.flg_default
              FROM checklist_prof_templ chkp
             INNER JOIN profile_template pt
                ON pt.id_profile_template = chkp.id_profile_template
             INNER JOIN software s
                ON s.id_software = pt.id_software
             WHERE chkp.flg_content_creator = i_content_creator
               AND chkp.internal_name = i_internal_name
               AND chkp.version = i_version
               AND pt.flg_available = pk_alert_constant.g_yes
             ORDER BY pt.id_software, desc_profile_template;
    
        --Specialties where checklist is applicable
        OPEN o_clin_service_list FOR
            SELECT chkcs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv
              FROM checklist_clin_serv chkcs
             INNER JOIN clinical_service cs
                ON cs.id_clinical_service = chkcs.id_clinical_service
             WHERE chkcs.flg_content_creator = i_content_creator
               AND chkcs.internal_name = i_internal_name
               AND chkcs.version = i_version
               AND cs.flg_available = pk_alert_constant.g_yes;
    
        --Checklist items
        OPEN o_item_list FOR
            SELECT chki.id_checklist_item,
                   chki.item,
                   (CASE chki.flg_use_translation
                       WHEN pk_alert_constant.g_yes THEN
                        pk_translation.get_translation(i_lang, chki.code_item_description)
                       ELSE
                        chki.item_description
                   END) item_description,
                   chki.rank
              FROM checklist_item chki
             WHERE chki.flg_content_creator = i_content_creator
               AND chki.internal_name = i_internal_name
               AND chki.version = i_version
             ORDER BY rank;
    
        --Authorized profiles for checklist items
        OPEN o_item_profile_list FOR
            SELECT chkip.item,
                   pt.id_software,
                   s.name desc_software,
                   pt.id_profile_template,
                   decode((SELECT /*+ cardinality(t 2) */
                           0
                            FROM TABLE(l_tab_current_profiles) t
                           WHERE t.column_value = pt.id_profile_template),
                          NULL,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) current_profile,
                   pk_message.get_message(i_lang, pt.code_profile_template) desc_profile_template
              FROM checklist_item_prof_templ chkip
             INNER JOIN profile_template pt
                ON pt.id_profile_template = chkip.id_profile_template
             INNER JOIN software s
                ON s.id_software = pt.id_software
             WHERE chkip.flg_content_creator = i_content_creator
               AND chkip.internal_name = i_internal_name
               AND chkip.version = i_version
               AND pt.flg_available = pk_alert_constant.g_yes
             ORDER BY chkip.item, pt.id_software, desc_profile_template;
    
        --Dependences between checklist items
        OPEN o_item_dependence_list FOR
            SELECT chkis.item item_src, chkit.item item_targ, chkid.flg_answer
            
              FROM checklist_item_dep chkid
             INNER JOIN checklist_item chkis
                ON chkis.id_checklist_item = chkid.id_checklist_item_src
               AND chkis.flg_content_creator = chkid.flg_content_creator
             INNER JOIN checklist_item chkit
                ON chkit.id_checklist_item = chkid.id_checklist_item_targ
               AND chkit.flg_content_creator = chkid.flg_content_creator
             WHERE chkis.flg_content_creator = i_content_creator
               AND chkis.internal_name = i_internal_name
               AND chkis.version = i_version
               AND chkit.flg_content_creator = i_content_creator
               AND chkit.internal_name = i_internal_name
               AND chkit.version = i_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_checklist_notfound THEN
            pk_alert_exceptions.raise_error(error_name_in => 'CHECKLIST_NOT_FOUND', text_in => 'No checklist found');
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_checklist;

    /**
    * Associates a list of specific versions of checklists to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_tab_cnt_creator        List of Checklist content creator 
    * @param   i_tab_checklist_version  List of Checklist version ID to associate
    * @param   i_patient                Patient ID 
    * @param   i_episode                Episode ID
    * @param   o_tab_pat_checklist      List of created record IDs
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION set_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        o_tab_pat_checklist     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_array_size EXCEPTION;
        e_first_obs_error    EXCEPTION;
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
        l_timestamp := current_timestamp;
    
        IF i_tab_cnt_creator.count != i_tab_checklist_version.count
        THEN
            RAISE e_invalid_array_size;
        END IF;
    
        FORALL i IN i_tab_cnt_creator.first .. i_tab_cnt_creator.last
            INSERT INTO pat_checklist
                (id_pat_checklist,
                 flg_content_creator,
                 id_checklist_version,
                 id_patient,
                 dt_pat_checklist,
                 id_professional,
                 id_episode_start,
                 id_episode_end,
                 flg_status,
                 flg_progress_status)
            VALUES
                (seq_pat_checklist.nextval,
                 i_tab_cnt_creator(i),
                 i_tab_checklist_version(i),
                 i_patient,
                 l_timestamp,
                 i_prof.id,
                 i_episode,
                 NULL,
                 pk_checklist_core.g_pchk_flg_status_active,
                 pk_checklist_core.g_pchk_flg_prg_status_empty)
            RETURNING id_pat_checklist BULK COLLECT INTO o_tab_pat_checklist;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_timestamp,
                                      i_dt_first_obs        => l_timestamp,
                                      o_error               => o_error)
        THEN
            RAISE e_first_obs_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_invalid_array_size THEN
            pk_alert_exceptions.raise_error(error_name_in => 'Invalid input parameters',
                                            text_in       => 'i_tab_cnt_creator and i_tab_checklist_version must have same size');
            RETURN FALSE;
        
        WHEN e_first_obs_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_checklist;

    /**
    * Associates a list of specific versions of checklists to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_tab_cnt_creator        List of Checklist content creator 
    * @param   i_tab_checklist_version  List of Checklist version ID to associate
    * @param   i_patient                Patient ID 
    * @param   i_episode                Episode ID
    * @param   i_test                   Tests attempt to associate a checklist already associated (Y/N)
    * @param   o_tab_pat_checklist      List of created record IDs 
    * @param   o_flg_show               Set if a message is displayed or not
    * @param   o_msg_title              Message title
    * @param   o_msg                    Message body
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   2/11/2011
    */
    FUNCTION set_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_test                  IN VARCHAR2,
        o_tab_pat_checklist     OUT table_number,
        o_flg_show              OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        e_function_call_error EXCEPTION;
        l_exists   VARCHAR2(1 CHAR);
        l_list     table_varchar;
        l_continue BOOLEAN;
        l_msg      VARCHAR2(32767);
        l_code_title_exists CONSTANT sys_message.code_message%TYPE := 'FO_CHECKLIST_T005';
        l_code_msg_exists   CONSTANT sys_message.code_message%TYPE := 'FO_CHECKLIST_T032';
        l_function_name     CONSTANT VARCHAR2(30) := 'set_pat_checklist';
    BEGIN
        l_continue := TRUE;
    
        o_flg_show := pk_alert_constant.g_no;
    
        IF i_test = pk_alert_constant.g_yes
        THEN
            g_error := 'Check if checklists are already associated';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
            l_ret := exist_pat_checklist(i_lang                  => i_lang,
                                         i_prof                  => i_prof,
                                         i_patient               => i_patient,
                                         i_episode               => i_episode,
                                         i_tab_cnt_creator       => i_tab_cnt_creator,
                                         i_tab_checklist_version => i_tab_checklist_version,
                                         o_exists                => l_exists,
                                         o_list                  => l_list,
                                         o_error                 => o_error);
            IF l_ret = FALSE
            THEN
                RAISE e_function_call_error;
            END IF;
        
            IF l_exists = pk_alert_constant.g_yes
            THEN
                g_error := 'There is at least a checklist in the input list that is associated to patient';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
                o_flg_show  := pk_alert_constant.g_yes;
                o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_title_exists);
                l_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_exists);
                l_msg       := REPLACE(l_msg, '@1', pk_utils.concat_table(l_list, chr(10)));
                o_msg       := l_msg;
                l_continue  := FALSE;
            END IF;
        
        END IF;
    
        IF l_continue
        THEN
            g_error := 'Associates a list of checklists to patient';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
            l_ret := set_pat_checklist(i_lang                  => i_lang,
                                       i_prof                  => i_prof,
                                       i_tab_cnt_creator       => i_tab_cnt_creator,
                                       i_tab_checklist_version => i_tab_checklist_version,
                                       i_patient               => i_patient,
                                       i_episode               => i_episode,
                                       o_tab_pat_checklist     => o_tab_pat_checklist,
                                       o_error                 => o_error);
        
            IF l_ret = FALSE
            THEN
                RAISE e_function_call_error;
            END IF;
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_checklist;
    /**
    * Cancels a previous association of checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID to cancel
    * @param   i_cancel_reason  Cancel reason ID
    * @param   i_cancel_notes   Cancelation notes
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION cancel_pat_checklist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_cancel_reason IN pat_checklist.id_cancel_reason%TYPE,
        i_cancel_notes  IN pat_checklist.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_checklist_cancel_failed EXCEPTION;
        l_timestamp TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        l_timestamp := current_timestamp;
    
        --A checklist is cancelled if is empty
        --A checklist is interrupted(discontinued) if has answers
        UPDATE pat_checklist pchk
           SET pchk.flg_status          = CASE pchk.flg_progress_status
                                              WHEN pk_checklist_core.g_pchk_flg_prg_status_empty THEN
                                               pk_checklist_core.g_pchk_flg_status_cancelled
                                              ELSE
                                               pk_checklist_core.g_pchk_flg_status_interrupted
                                          END,
               pchk.id_prof_cancel      = i_prof.id,
               pchk.id_cancel_reason    = i_cancel_reason,
               pchk.dt_cancel_time      = l_timestamp,
               pchk.cancel_notes        = i_cancel_notes,
               pchk.dt_last_update      = l_timestamp,
               pchk.id_prof_last_update = i_prof.id
         WHERE pchk.id_pat_checklist = i_pat_checklist
           AND pchk.id_prof_cancel IS NULL;
        IF SQL%ROWCOUNT = 0
        THEN
            RAISE e_checklist_cancel_failed;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_checklist_cancel_failed THEN
            pk_alert_exceptions.raise_error(error_name_in => 'CHECKLIST_CANCEL_FAILED',
                                            text_in       => 'Checklist was already canceled?');
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'cancel_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_pat_checklist;

    /**
    * Gets a list of checklists for patient and where professional has authorization to visualize and/or fill them
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_patient        Patient ID 
    * @param   i_episode        Episode ID
    * @param   i_ignore_profile Ignore profissional's profile and returns all checklists for patient
    * @param   o_list           Checklist list
    * @param   o_error          Error information
    *
    * @value   i_ignore_profile {*} 'N' checklists where profissional's profile has authorization to visualize and/or fill (Default) {*} 'Y' ignore profissional's profile and return all checklists
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_ignore_profile IN VARCHAR2 DEFAULT 'N',
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_tab_current_profiles table_number;
        l_default              sys_message.desc_message%TYPE;
        l_code_default CONSTANT sys_message.code_message%TYPE := 'FO_CHECKLIST_T034';
    BEGIN
    
        -- Criteria to show linked checklists that are applicable to profissional's profile:
        -- Active checklists with progress status:  "Checklist blank" or "Checklist partially completed", independentelly from episode
        -- All checklists linked in current episode
        -- All checklists finished in current episode
        -- All checklists with answers done in current episode
    
        IF i_ignore_profile = pk_alert_constant.g_no
        THEN
            l_tab_current_profiles := get_prof_profiles(i_lang => i_lang, i_prof => i_prof);
            l_default              := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_default);
            l_default := CASE
                             WHEN l_default IS NULL THEN
                              NULL
                             ELSE
                              ' (' || l_default || ')'
                         END;
        
            OPEN o_list FOR
            --Current checklists linked to patient
                SELECT DISTINCT pchk.id_pat_checklist,
                                pchk.flg_content_creator,
                                pchk.id_checklist_version,
                                (CASE chkv.flg_use_translation
                                    WHEN pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation(i_lang, chkv.code_name)
                                    ELSE
                                     chkv.name
                                END) name,
                                chkv.flg_type,
                                pk_sysdomain.get_domain_cached(i_lang, chkv.flg_type, g_domain_chkv_flg_type) desc_type,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_professional) prof_request,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 pchk.id_professional,
                                                                 pchk.dt_pat_checklist,
                                                                 pchk.id_episode_start) prof_request_speciality,
                                pchk.dt_pat_checklist dt_request,
                                pk_date_utils.date_char_tsz(i_lang,
                                                            pchk.dt_pat_checklist,
                                                            i_prof.institution,
                                                            i_prof.software) dt_request_fmt,
                                pk_date_utils.date_send_tsz(i_lang, pchk.dt_pat_checklist, i_prof) dt_request_str,
                                pchk.flg_status,
                                pk_sysdomain.get_img(i_lang, g_domain_pck_flg_status, pchk.flg_status) status_icon,
                                pchk.flg_progress_status,
                                pk_sysdomain.get_img(i_lang, g_domain_pck_flg_prg_status, pchk.flg_progress_status) progress_status_icon,
                                decode(pchk.flg_status,
                                       pk_checklist_core.g_pchk_flg_status_active,
                                       pk_sysdomain.get_domain_cached(i_lang,
                                                                      pchk.flg_progress_status,
                                                                      g_domain_pck_flg_prg_status),
                                       pk_sysdomain.get_domain_cached(i_lang, pchk.flg_status, g_domain_pck_flg_status)) desc_status,
                                pchk.dt_last_update,
                                pk_date_utils.date_send_tsz(i_lang, pchk.dt_last_update, i_prof) dt_last_update_str,
                                pk_date_utils.date_char_tsz(i_lang,
                                                            pchk.dt_last_update,
                                                            i_prof.institution,
                                                            i_prof.software) dt_last_update_fmt,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_prof_last_update) prof_last_update_name,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 pchk.id_prof_last_update,
                                                                 pchk.dt_last_update,
                                                                 nvl(pchk.id_episode_end, pchk.id_episode_start)) prof_last_update_speciality,
                                (CASE chkp.flg_write
                                    WHEN pk_alert_constant.g_yes THEN
                                     CASE chkv.flg_type
                                         WHEN pk_checklist_core.g_chkv_flg_type_individual THEN
                                         -- An individual checklist can only be edited by the professional who started to fill in
                                          decode(nvl(pchk.id_prof_last_update, i_prof.id),
                                                 i_prof.id,
                                                 pk_alert_constant.g_yes,
                                                 pk_alert_constant.g_no)
                                         ELSE
                                          chkp.flg_write
                                     END
                                    ELSE
                                     chkp.flg_write
                                END) flg_can_write,
                                1 origin
                  FROM pat_checklist pchk
                 INNER JOIN checklist_version chkv
                    ON chkv.id_checklist_version = pchk.id_checklist_version
                   AND chkv.flg_content_creator = pchk.flg_content_creator
                 INNER JOIN checklist_prof_templ chkp
                    ON pchk.flg_content_creator = chkp.flg_content_creator
                   AND pchk.id_checklist_version = chkp.id_checklist_version
                
                 WHERE pchk.id_patient = i_patient
                   AND chkp.id_profile_template IN (SELECT /*+ cardinality (t 2) */
                                                     t.column_value
                                                      FROM TABLE(l_tab_current_profiles) t)
                   AND ((pchk.flg_status = pk_checklist_core.g_chklst_flg_status_active AND
                       pchk.flg_progress_status IN
                       (pk_checklist_core.g_pchk_flg_prg_status_empty,
                          pk_checklist_core.g_pchk_flg_prg_status_partial)) OR
                       (pchk.id_episode_start = i_episode OR pchk.id_episode_end = i_episode OR EXISTS
                        (SELECT '0'
                            FROM pat_checklist_det pchkd
                           WHERE pchkd.id_pat_checklist = pchk.id_pat_checklist
                             AND pchkd.id_episode = i_episode)))
                UNION ALL
                SELECT DISTINCT NULL id_pat_checklist,
                                chkv.flg_content_creator,
                                chkv.id_checklist_version,
                                (CASE chkv.flg_use_translation
                                    WHEN pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation(i_lang, chkv.code_name)
                                    ELSE
                                     chkv.name
                                END) || l_default name,
                                chkv.flg_type,
                                pk_sysdomain.get_domain_cached(i_lang, chkv.flg_type, g_domain_chkv_flg_type) desc_type,
                                NULL prof_request,
                                NULL prof_request_speciality,
                                NULL dt_request,
                                NULL dt_request_fmt,
                                NULL dt_request_str,
                                g_pchk_flg_status_active flg_status,
                                NULL status_icon,
                                g_pchk_flg_prg_status_new flg_progress_status,
                                pk_sysdomain.get_img(i_lang, g_domain_pck_flg_prg_status, g_pchk_flg_prg_status_empty) progress_status_icon,
                                NULL desc_status,
                                NULL dt_last_update,
                                NULL dt_last_update_str,
                                NULL dt_last_update_fmt,
                                NULL prof_last_update_name,
                                NULL prof_last_update_speciality,
                                chkp.flg_write flg_can_write,
                                2 origin
                  FROM v_checklist_version chkv
                 INNER JOIN checklist_prof_templ chkp
                    ON chkp.flg_content_creator = chkv.flg_content_creator
                   AND chkp.id_checklist_version = chkv.id_checklist_version
                 WHERE chkp.id_profile_template IN (SELECT /*+ cardinality (t 2) */
                                                     t.column_value
                                                      FROM TABLE(l_tab_current_profiles) t)
                   AND chkp.flg_default = pk_alert_constant.g_yes
                   AND chkp.flg_write = pk_alert_constant.g_yes
                   AND NOT EXISTS (SELECT 1
                          FROM pat_checklist pchk
                         WHERE chkv.id_checklist_version = pchk.id_checklist_version
                           AND chkv.flg_content_creator = pchk.flg_content_creator
                           AND pchk.id_patient = i_patient
                           AND ((pchk.flg_status = pk_checklist_core.g_chklst_flg_status_active AND
                               pchk.flg_progress_status IN
                               (pk_checklist_core.g_pchk_flg_prg_status_empty,
                                  pk_checklist_core.g_pchk_flg_prg_status_partial)) OR
                               (pchk.id_episode_start = i_episode OR pchk.id_episode_end = i_episode OR
                               EXISTS (SELECT '0'
                                          FROM pat_checklist_det pchkd
                                         WHERE pchkd.id_pat_checklist = pchk.id_pat_checklist
                                           AND pchkd.id_episode = i_episode))))
                   AND EXISTS (SELECT 1
                          FROM checklist_inst chki
                          JOIN checklist chk
                            ON chk.id_checklist = chki.id_checklist
                         WHERE chki.id_checklist = chkv.id_checklist
                           AND chki.flg_content_creator = chkv.flg_content_creator
                           AND chki.flg_available = pk_alert_constant.g_yes
                           AND chki.flg_status = pk_checklist_core.g_chklst_flg_status_active
                           AND chk.flg_available = pk_alert_constant.g_yes
                           AND chk.flg_status = pk_checklist_core.g_chklst_flg_status_active
                           AND chki.id_institution IN (0, i_prof.institution))
                 ORDER BY origin, flg_status, flg_progress_status, dt_last_update DESC, name;
        
        ELSE
        
            OPEN o_list FOR
                SELECT DISTINCT pchk.id_pat_checklist,
                                pchk.flg_content_creator,
                                pchk.id_checklist_version,
                                (CASE chkv.flg_use_translation
                                    WHEN pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation(i_lang, chkv.code_name)
                                    ELSE
                                     chkv.name
                                END) name,
                                chkv.flg_type,
                                pk_sysdomain.get_domain_cached(i_lang, chkv.flg_type, g_domain_chkv_flg_type) desc_type,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_professional) prof_request,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 pchk.id_professional,
                                                                 pchk.dt_pat_checklist,
                                                                 pchk.id_episode_start) prof_request_speciality,
                                pchk.dt_pat_checklist dt_request,
                                pk_date_utils.date_char_tsz(i_lang,
                                                            pchk.dt_pat_checklist,
                                                            i_prof.institution,
                                                            i_prof.software) dt_request_fmt,
                                pk_date_utils.date_send_tsz(i_lang, pchk.dt_pat_checklist, i_prof) dt_request_str,
                                pchk.flg_status,
                                pk_sysdomain.get_img(i_lang, g_domain_pck_flg_status, pchk.flg_status) status_icon,
                                pchk.flg_progress_status,
                                pk_sysdomain.get_img(i_lang, g_domain_pck_flg_prg_status, pchk.flg_progress_status) progress_status_icon,
                                decode(pchk.flg_status,
                                       pk_checklist_core.g_pchk_flg_status_active,
                                       pk_sysdomain.get_domain_cached(i_lang,
                                                                      pchk.flg_progress_status,
                                                                      g_domain_pck_flg_prg_status),
                                       pk_sysdomain.get_domain_cached(i_lang, pchk.flg_status, g_domain_pck_flg_status)) desc_status,
                                pchk.dt_last_update,
                                pk_date_utils.date_send_tsz(i_lang, pchk.dt_last_update, i_prof) dt_last_update_str,
                                pk_date_utils.date_char_tsz(i_lang,
                                                            pchk.dt_last_update,
                                                            i_prof.institution,
                                                            i_prof.software) dt_last_update_fmt,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_prof_last_update) prof_last_update_name,
                                pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 pchk.id_prof_last_update,
                                                                 pchk.dt_last_update,
                                                                 nvl(pchk.id_episode_end, pchk.id_episode_start)) prof_last_update_speciality,
                                pk_alert_constant.g_no flg_can_write
                  FROM pat_checklist pchk
                 INNER JOIN checklist_version chkv
                    ON chkv.id_checklist_version = pchk.id_checklist_version
                   AND chkv.flg_content_creator = pchk.flg_content_creator
                 WHERE pchk.id_patient = i_patient
                   AND ((pchk.flg_status = pk_checklist_core.g_chklst_flg_status_active AND
                       pchk.flg_progress_status IN
                       (pk_checklist_core.g_pchk_flg_prg_status_empty,
                          pk_checklist_core.g_pchk_flg_prg_status_partial)) OR
                       (pchk.id_episode_start = i_episode OR pchk.id_episode_end = i_episode OR EXISTS
                        (SELECT '0'
                            FROM pat_checklist_det pchkd
                           WHERE pchkd.id_pat_checklist = pchk.id_pat_checklist
                             AND pchkd.id_episode = i_episode)))
                 ORDER BY pchk.flg_status, pchk.flg_progress_status, pchk.dt_last_update DESC;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist_list',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_checklist_list;

    /**
    * Gets a list of available checklists for professional
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_filter_speciality Filter the list to only those checklist for specialties in which the professional is allocated
    * @param   o_list              Checklist list
    * @param   o_error             Error information
    *
    * @value   i_filter_speciality    {*} 'Y' filter by specialities  {*} 'N' Unfiltered
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_prof_checklist_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_filter_speciality IN VARCHAR2,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_tab_current_profiles table_number;
        l_clin_service_list    table_number;
        l_ret                  BOOLEAN;
    BEGIN
    
        g_error := 'Get professional profile';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_prof_checklist_list');
    
        l_tab_current_profiles := get_prof_profiles(i_lang => i_lang, i_prof => i_prof);
    
        IF i_filter_speciality = pk_alert_constant.g_yes
        THEN
        
            g_error := 'Get clinical services';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package,
                                  sub_object_name => 'get_prof_checklist_list');
            l_ret := get_prof_clin_serv_list(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             o_clin_service_list => l_clin_service_list,
                                             o_error             => o_error);
        
            IF l_ret = FALSE
            THEN
                RAISE e_function_call_error;
            END IF;
        
            g_error := 'Fetch a list of checklists for professional (filtered by specialty)';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package,
                                  sub_object_name => 'get_prof_checklist_list');
            --List of applicable checklists for institution & prof. profile based in following criteria:
            -- 1.Checklist is available in institution
            -- 2.Checklist is active in institution
            -- 3.Checklist is not canceled
            -- 4.Checklist is applicable for profile
            -- 5.Profile is authorized for edition
            -- 6.The profissional is allocated to at least one speciality that checklist is applicable
            OPEN o_list FOR
                SELECT DISTINCT vchkv.flg_content_creator,
                                vchkv.id_checklist_version,
                                (CASE vchkv.flg_use_translation
                                    WHEN pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation(i_lang, vchkv.code_name)
                                    ELSE
                                     vchkv.name
                                END) name,
                                vchkv.flg_type,
                                pk_sysdomain.get_domain_cached(i_lang, vchkv.flg_type, g_domain_chkv_flg_type) desc_type
                  FROM checklist_inst chki
                 INNER JOIN checklist chk
                    ON chk.id_checklist = chki.id_checklist
                   AND chk.flg_content_creator = chki.flg_content_creator
                 INNER JOIN v_checklist_version vchkv
                    ON chk.id_checklist = vchkv.id_checklist
                   AND chk.flg_content_creator = vchkv.flg_content_creator
                 INNER JOIN checklist_prof_templ chkp
                    ON vchkv.id_checklist_version = chkp.id_checklist_version
                   AND vchkv.flg_content_creator = chkp.flg_content_creator
                 WHERE chki.id_institution = i_prof.institution
                   AND chki.flg_available = pk_alert_constant.g_yes
                   AND chki.flg_status = pk_checklist_core.g_chklst_flg_status_active
                   AND chk.flg_status = pk_checklist_core.g_chklst_flg_status_active
                   AND chkp.id_profile_template IN (SELECT /*+ cardinality (t 2) */
                                                     t.column_value
                                                      FROM TABLE(l_tab_current_profiles) t)
                   AND chkp.flg_write = pk_alert_constant.g_yes
                   AND EXISTS (SELECT 0
                          FROM checklist_clin_serv chkcs
                         WHERE chkcs.id_checklist_version = vchkv.id_checklist_version
                           AND chkcs.flg_content_creator = vchkv.flg_content_creator
                           AND chkcs.id_clinical_service IN
                               (SELECT column_value
                                  FROM TABLE(l_clin_service_list)));
        ELSE
        
            g_error := 'Fetch a list of checklists for professional (unfiltered specialties)';
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package,
                                  sub_object_name => 'get_prof_checklist_list');
        
            --List of applicable checklists for institution & prof. profile based in following criteria:
            -- 1.Checklist is available in institution
            -- 2.Checklist is active in institution
            -- 3.Checklist is not canceled
            -- 4.Checklist is applicable for profile
            -- 5.Profile is authorized for edition
            OPEN o_list FOR
                SELECT DISTINCT vchkv.flg_content_creator,
                                vchkv.id_checklist_version,
                                (CASE vchkv.flg_use_translation
                                    WHEN pk_alert_constant.g_yes THEN
                                     pk_translation.get_translation(i_lang, vchkv.code_name)
                                    ELSE
                                     vchkv.name
                                END) name,
                                vchkv.flg_type,
                                pk_sysdomain.get_domain_cached(i_lang, vchkv.flg_type, g_domain_chkv_flg_type) desc_type
                  FROM checklist_inst chki
                 INNER JOIN checklist chk
                    ON chk.id_checklist = chki.id_checklist
                   AND chk.flg_content_creator = chki.flg_content_creator
                 INNER JOIN v_checklist_version vchkv
                    ON chk.id_checklist = vchkv.id_checklist
                   AND chk.flg_content_creator = vchkv.flg_content_creator
                 INNER JOIN checklist_prof_templ chkp
                    ON vchkv.id_checklist_version = chkp.id_checklist_version
                   AND vchkv.flg_content_creator = chkp.flg_content_creator
                 WHERE chki.id_institution = i_prof.institution
                   AND chki.flg_available = pk_alert_constant.g_yes
                   AND chki.flg_status = pk_checklist_core.g_chklst_flg_status_active
                   AND chk.flg_status = pk_checklist_core.g_chklst_flg_status_active
                   AND chkp.id_profile_template IN (SELECT /*+ cardinality (t 2) */
                                                     t.column_value
                                                      FROM TABLE(l_tab_current_profiles) t)
                   AND chkp.flg_write = pk_alert_constant.g_yes;
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
                                              i_function => 'get_prof_checklist_list',
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_prof_checklist_list',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_checklist_list;

    /**
    * Gets info about an associated checklist to patient, including info about association itself
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_pat_checklist_info     Information related to the association between checklist and patient(requested by,status,cancel info,etc.)
    * @param   o_answer_data            Answers given
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   25-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_pat_checklist_info   OUT pk_types.cursor_type,
        o_answer_data          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        e_function_call_error EXCEPTION;
        l_cnt_creator       checklist_version.flg_content_creator%TYPE;
        l_checklist_version checklist_version.id_checklist_version%TYPE;
        l_ret               BOOLEAN;
    BEGIN
    
        g_error := 'Gets checklist ID';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_pat_checklist');
        SELECT pchk.flg_content_creator, pchk.id_checklist_version
          INTO l_cnt_creator, l_checklist_version
          FROM pat_checklist pchk
         WHERE pchk.id_pat_checklist = i_pat_checklist;
    
        g_error := 'Gets checklist info';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_pat_checklist');
    
        l_ret := pk_checklist_core.get_checklist(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_content_creator      => l_cnt_creator,
                                                 i_checklist_version    => l_checklist_version,
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
    
        g_error := 'Gets answers given';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_pat_checklist');
        --Answers given
        OPEN o_answer_data FOR
            SELECT chki.item,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vpchkv.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    vpchkv.id_professional,
                                                    vpchkv.dt_pat_checklist_det,
                                                    vpchkv.id_episode) prof_speciality,
                   vpchkv.flg_answer,
                   pk_sysdomain.get_domain_cached(i_lang, vpchkv.flg_answer, g_domain_pck_flg_answer) answer,
                   vpchkv.dt_pat_checklist_det dt_answer,
                   pk_date_utils.date_char_tsz(i_lang, vpchkv.dt_pat_checklist_det, i_prof.institution, i_prof.software) dt_answer_fmt,
                   pk_date_utils.date_send_tsz(i_lang, vpchkv.dt_pat_checklist_det, i_prof) dt_answer_str,
                   vpchkv.notes
              FROM v_pat_checklist_det vpchkv
             INNER JOIN checklist_item chki
                ON chki.id_checklist_item = vpchkv.id_checklist_item
               AND chki.flg_content_creator = vpchkv.flg_content_creator
             WHERE vpchkv.id_pat_checklist = i_pat_checklist
             ORDER BY chki.rank;
    
        g_error := 'Gets info about checklist instance associated to patient';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'get_pat_checklist');
        OPEN o_pat_checklist_info FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_professional) prof_request,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pchk.id_professional,
                                                    pchk.dt_pat_checklist,
                                                    pchk.id_episode_start) prof_request_speciality,
                   pchk.dt_pat_checklist dt_request,
                   pk_date_utils.date_char_tsz(i_lang, pchk.dt_pat_checklist, i_prof.institution, i_prof.software) dt_request_fmt,
                   pk_date_utils.date_send_tsz(i_lang, pchk.dt_pat_checklist, i_prof) dt_request_str,
                   pchk.flg_progress_status,
                   pchk.flg_status,
                   decode(pchk.flg_status,
                          pk_checklist_core.g_pchk_flg_status_active,
                          pk_sysdomain.get_domain_cached(i_lang, pchk.flg_progress_status, g_domain_pck_flg_prg_status),
                          pk_sysdomain.get_domain_cached(i_lang, pchk.flg_status, g_domain_pck_flg_status)) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pchk.id_prof_cancel) prof_cancel,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    pchk.id_prof_cancel,
                                                    pchk.dt_cancel_time,
                                                    pchk.id_episode_start) prof_cancel_speciality,
                   pchk.dt_cancel_time,
                   pk_date_utils.date_char_tsz(i_lang, pchk.dt_cancel_time, i_prof.institution, i_prof.software) dt_cancel_time_fmt,
                   pk_date_utils.date_send_tsz(i_lang, pchk.dt_cancel_time, i_prof) dt_cancel_time_str,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, pchk.id_cancel_reason) cancel_reason,
                   pchk.cancel_notes
            
              FROM pat_checklist pchk
             WHERE pchk.id_pat_checklist = i_pat_checklist;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_function_call_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_checklist;

    /**
    * Saves answers given in an associated checklist to patient
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_pat_checklist  Association ID 
    * @param   i_episode        Episode ID
    * @param   i_tab_item       List of cheklist item ID
    * @param   i_tab_answer     List of answers given
    * @param   i_tab_notes      List of observations in answers given
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION set_pat_checklist_answer
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_checklist IN pat_checklist.id_pat_checklist%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_tab_item      IN table_number,
        i_tab_answer    IN table_varchar,
        i_tab_notes     IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        e_first_obs_error EXCEPTION;
        l_timestamp                TIMESTAMP WITH TIME ZONE;
        l_cnt_creator              pat_checklist.flg_content_creator%TYPE;
        l_checklist_version        pat_checklist.id_checklist_version%TYPE;
        l_flg_prg_status           pat_checklist.flg_progress_status%TYPE;
        l_patient                  pat_checklist.id_patient%TYPE;
        l_episode_end              pat_checklist.id_episode_end%TYPE;
        l_tab_current_item_answers table_number;
        l_tab_current_item_status  table_number;
        i                          PLS_INTEGER;
    
    BEGIN
        l_timestamp := current_timestamp;
    
        g_error := 'Obtain identification of associated checklist';
        SELECT pchk.flg_content_creator, pchk.id_checklist_version, pchk.id_patient
          INTO l_cnt_creator, l_checklist_version, l_patient
          FROM pat_checklist pchk
         WHERE pchk.id_pat_checklist = i_pat_checklist;
    
        g_error := 'Get previous answers that will be outdated';
        SELECT chki.id_checklist_item, vpchkd.del_status
          BULK COLLECT
          INTO l_tab_current_item_answers, l_tab_current_item_status
          FROM pat_checklist pchk
         INNER JOIN checklist_item chki
            ON pchk.id_checklist_version = chki.id_checklist_version
           AND pchk.flg_content_creator = chki.flg_content_creator
          LEFT JOIN v_pat_checklist_det vpchkd
            ON pchk.id_pat_checklist = vpchkd.id_pat_checklist
           AND chki.flg_content_creator = vpchkd.flg_content_creator
           AND chki.id_checklist_item = vpchkd.id_checklist_item
         WHERE pchk.id_pat_checklist = i_pat_checklist
           AND chki.id_checklist_item IN (SELECT column_value
                                            FROM TABLE(i_tab_item));
    
        g_error := 'Make previous answers as outdated';
        FORALL i IN l_tab_current_item_answers.first .. l_tab_current_item_answers.last
            UPDATE pat_checklist_det pchkd
               SET pchkd.dt_retire_time = l_timestamp
             WHERE pchkd.id_pat_checklist = i_pat_checklist
               AND pchkd.id_checklist_item = l_tab_current_item_answers(i)
               AND pchkd.del_status = l_tab_current_item_status(i);
    
        i := l_tab_current_item_status.first;
        WHILE i IS NOT NULL
        LOOP
        
            IF l_tab_current_item_status(i) IS NULL
            THEN
                --An answer without previous response: snapshots start at +10
                l_tab_current_item_status(i) := 10;
            ELSIF i_tab_answer(i) IS NULL
            THEN
                --A deleted answer: del_status is negative
                l_tab_current_item_status(i) := - (abs(l_tab_current_item_status(i)) + 1);
            ELSE
                --An updated answer: del_status is positive 
                l_tab_current_item_status(i) := abs(l_tab_current_item_status(i)) + 1;
            END IF;
            i := l_tab_current_item_status.next(i);
        END LOOP;
    
        g_error := 'Save new answers';
        FORALL i IN i_tab_item.first .. i_tab_item.last
            INSERT INTO pat_checklist_det
                (id_pat_checklist,
                 flg_content_creator,
                 id_checklist_item,
                 id_episode,
                 id_professional,
                 flg_answer,
                 dt_pat_checklist_det,
                 notes,
                 dt_create_time,
                 dt_retire_time,
                 del_status)
            VALUES
                (i_pat_checklist,
                 l_cnt_creator,
                 i_tab_item(i),
                 i_episode,
                 i_prof.id,
                 i_tab_answer(i),
                 l_timestamp,
                 i_tab_notes(i),
                 l_timestamp,
                 NULL,
                 l_tab_current_item_status(i));
    
        --Establish the progress status
        IF is_checklist_completed(i_pat_checklist) = TRUE
        THEN
            -- Checklist fully filled in
            l_flg_prg_status := g_pchk_flg_prg_status_complete;
            l_episode_end    := i_episode;
        ELSE
            -- Checklist partially filled in
            l_flg_prg_status := g_pchk_flg_prg_status_partial;
            l_episode_end    := NULL;
        END IF;
    
        --Updates the associated checklist with info about last update and progress status
        UPDATE pat_checklist pchk
           SET pchk.id_prof_last_update = i_prof.id,
               pchk.dt_last_update      = l_timestamp,
               pchk.flg_progress_status = l_flg_prg_status,
               pchk.id_episode_end      = l_episode_end
         WHERE pchk.id_pat_checklist = i_pat_checklist;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => l_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => l_timestamp,
                                      i_dt_first_obs        => l_timestamp,
                                      o_error               => o_error)
        THEN
            RAISE e_first_obs_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_first_obs_error THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => o_error.ora_sqlcode,
                                              i_sqlerrm  => o_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_checklist_answer;

    /**
    * Checks if within the active checklists that are associated to patient exists checklists indicated as input argument
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_patient                Patient ID 
    * @param   i_episode                Episode ID
    * @param   i_tab_cnt_creator        List of Checklist content creator 
    * @param   i_tab_checklist_version  List of Checklist version ID
    * @param   o_exists                 There is at least a checklist in the input list that is associated to patient(Y/N)
    * @param   o_list                   List of checklist's name that are already associated to patient
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.5
    * @since   2/11/2011
    */
    FUNCTION exist_pat_checklist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_tab_cnt_creator       IN table_varchar,
        i_tab_checklist_version IN table_number,
        o_exists                OUT VARCHAR2,
        o_list                  OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        e_invalid_array_size EXCEPTION;
    BEGIN
        IF i_tab_cnt_creator.count != i_tab_checklist_version.count
        THEN
            RAISE e_invalid_array_size;
        END IF;
    
        SELECT (CASE x.flg_use_translation
                   WHEN pk_alert_constant.g_yes THEN
                    pk_translation.get_translation(i_lang, x.code_name)
                   ELSE
                    x.name
               END) name
          BULK COLLECT
          INTO o_list
          FROM (SELECT DISTINCT pchk.flg_content_creator,
                                pchk.id_checklist_version,
                                chkv.flg_use_translation,
                                chkv.code_name,
                                chkv.name
                  FROM pat_checklist pchk
                 INNER JOIN checklist_version chkv
                    ON chkv.id_checklist_version = pchk.id_checklist_version
                   AND chkv.flg_content_creator = pchk.flg_content_creator
                 WHERE pchk.id_patient = i_patient
                   AND (pchk.flg_content_creator, pchk.id_checklist_version) IN
                       (SELECT c.column_value, v.column_value
                          FROM (SELECT rownum rown, column_value
                                  FROM TABLE(i_tab_cnt_creator)) c
                          JOIN (SELECT rownum rown, column_value
                                 FROM TABLE(i_tab_checklist_version)) v
                            ON c.rown = v.rown)
                   AND ((pchk.flg_status = pk_checklist_core.g_chklst_flg_status_active AND
                       pchk.flg_progress_status IN
                       (pk_checklist_core.g_pchk_flg_prg_status_empty, pk_checklist_core.g_pchk_flg_prg_status_partial)) OR
                       (pchk.id_episode_start = i_episode OR pchk.id_episode_end = i_episode OR EXISTS
                        (SELECT '0'
                            FROM pat_checklist_det pchkd
                           WHERE pchkd.id_pat_checklist = pchk.id_pat_checklist
                             AND pchkd.id_episode = i_episode)))) x;
    
        IF o_list.count = 0
        THEN
            o_exists := pk_alert_constant.g_no;
        ELSE
            o_exists := pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_invalid_array_size THEN
            pk_alert_exceptions.raise_error(error_name_in => 'Invalid input parameters',
                                            text_in       => 'i_tab_cnt_creator and i_tab_checklist_version must have same size');
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist',
                                              o_error    => o_error);
            RETURN FALSE;
    END exist_pat_checklist;

    /**************************************************************************
    * Saves answers given in an associated checklist to patient               *
    *                                                                         *
    * @param   i_lang               Professional preferred language           *
    * @param   i_prof               Professional identification and its       *
    *                               context (institution and software)        *
    * @param   i_pat_checklist      Association ID                            *
    * @param   i_episode            Episode ID                                *
    * @param   i_tab_item           List of cheklist item ID                  *
    * @param   i_tab_answer         List of answers given                     *
    * @param   i_tab_notes          List of observations in answers given     *
    * @param   i_cnt_creator        List of Checklist content creator         *
    * @param   i_checklist_version  List of Checklist version ID to associate *
    * @param   i_patient            Patient ID                                *
    * @param   o_tab_pat_checklist  List of created record IDs                *
    * @param   o_error              Error information                         *
    *                                                                         *
    * @return  True or False on success or error                              *
    *                                                                         *
    * @author  Gustavo Serrano                                                *
    * @version 2.6.0.5                                                        *
    * @since   15-Fev-11                                                      *
    **************************************************************************/
    FUNCTION set_pat_checklist_answer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat_checklist     IN pat_checklist.id_pat_checklist%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_tab_item          IN table_number,
        i_tab_answer        IN table_varchar,
        i_tab_notes         IN table_varchar,
        i_cnt_creator       IN pat_checklist.flg_content_creator%TYPE,
        i_checklist_version IN pat_checklist.id_checklist_version%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        o_tab_pat_checklist OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    
        l_pat_checklist pat_checklist.id_pat_checklist%TYPE;
        l_flg_show      VARCHAR2(1);
        l_msg_title     VARCHAR2(4000);
        l_msg           VARCHAR2(4000);
        l_error         t_error_out;
    
    BEGIN
    
        IF i_pat_checklist IS NULL
        THEN
            -- Inserir a nova checklist default caso i_pat_checklist vem a NULL (set_pat_checklist)
            g_error := 'Insert new default checklist: ' || i_cnt_creator || '\' || i_checklist_version;
            IF NOT set_pat_checklist(i_lang                  => i_lang,
                                     i_prof                  => i_prof,
                                     i_tab_cnt_creator       => table_varchar(i_cnt_creator),
                                     i_tab_checklist_version => table_number(i_checklist_version),
                                     i_patient               => i_patient,
                                     i_episode               => i_episode,
                                     i_test                  => pk_alert_constant.g_no,
                                     o_tab_pat_checklist     => o_tab_pat_checklist,
                                     o_flg_show              => l_flg_show,
                                     o_msg_title             => l_msg_title,
                                     o_msg                   => l_msg,
                                     o_error                 => l_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_pat_checklist := o_tab_pat_checklist(1);
        ELSE
            l_pat_checklist := i_pat_checklist;
        END IF;
    
        g_error := 'Insert default checklist answers for id_pat_checklist: ' || l_pat_checklist;
        IF NOT set_pat_checklist_answer(i_lang          => i_lang,
                                        i_prof          => i_prof,
                                        i_pat_checklist => l_pat_checklist,
                                        i_episode       => i_episode,
                                        i_tab_item      => i_tab_item,
                                        i_tab_answer    => i_tab_answer,
                                        i_tab_notes     => i_tab_notes,
                                        o_error         => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error.ora_sqlcode,
                                              i_sqlerrm  => l_error.ora_sqlerrm,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'set_pat_checklist_answer',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_pat_checklist_answer;

    /**
    * For a specific checklist cancels all empty & active instances that are associated to patients
     Used when a checklist have been inactivated/canceled in the BackOffice
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_internal_name          Checklist internal name
    * @param   i_inst                   Institution/facility where checklist is used. Default: NULL (All facilities)
    * @param   o_error                  Error information
    *
    * @value   i_content_creator        {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.1
    * @since   30-May-11
    */
    FUNCTION cancel_pat_checklist_empty
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_content_creator IN checklist.flg_content_creator%TYPE,
        i_internal_name   IN checklist.internal_name%TYPE,
        i_inst            IN institution.id_institution%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'cancel_pat_checklist_empty';
        l_timestamp    TIMESTAMP WITH TIME ZONE;
        l_cancel_notes sys_message.desc_message%TYPE;
    BEGIN
        l_timestamp := current_timestamp;
    
        /* When a checklist is canceled or inactivated at Backoffice it should cancel blank instances of this checklist in FrontOffice
        with a generic cancel reason: Automatically cancelled due to disabling or cancelling by system administrator in BACKOFFICE.*/
    
        g_error := 'Cancelling active and empty patient''s checklist instances (content_creator="' || i_content_creator ||
                   '" internal_name="' || i_internal_name || '")';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
    
        l_cancel_notes := pk_message.get_message(i_lang => i_lang, i_code_mess => g_msg_auto_cancelled);
    
        UPDATE pat_checklist pchk
           SET pchk.flg_status          = pk_checklist_core.g_pchk_flg_status_cancelled,
               pchk.id_prof_cancel      = i_prof.id,
               pchk.id_cancel_reason    = g_cancel_reason_auto_cancelled,
               pchk.cancel_notes        = l_cancel_notes,
               pchk.dt_cancel_time      = l_timestamp,
               pchk.dt_last_update      = l_timestamp,
               pchk.id_prof_last_update = i_prof.id
         WHERE pchk.id_pat_checklist IN (SELECT pchk.id_pat_checklist
                                           FROM pat_checklist pchk
                                          INNER JOIN episode e
                                             ON e.id_episode = pchk.id_episode_start
                                          INNER JOIN checklist_version chkv
                                             ON chkv.id_checklist_version = pchk.id_checklist_version
                                            AND chkv.flg_content_creator = pchk.flg_content_creator
                                          WHERE chkv.flg_content_creator = i_content_creator
                                            AND chkv.internal_name = i_internal_name
                                            AND pchk.flg_progress_status = pk_checklist_core.g_pchk_flg_prg_status_empty
                                            AND pchk.flg_status = pk_checklist_core.g_pchk_flg_status_active
                                            AND pchk.id_prof_cancel IS NULL
                                            AND (e.id_institution = i_inst OR i_inst IS NULL));
    
        g_error := 'Nº of cancelled checklists: ' || SQL%ROWCOUNT;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_function_name);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_pat_checklist_empty;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_checklist_core;
/
