/*-- Last Change Revision: $Rev: 2026602 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_access IS
    /*
    mapping service/bd fields
    subtitle = BUTTON_TEXT
    label 0 LABEL
    tooltip = TOOLTIP_TITLE 
    
    */

    k_active   CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_active;
    k_inactive CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_inactive;

    k_low_limit  CONSTANT NUMBER := -99999;
    k_high_limit  CONSTANT NUMBER := 99999;
    k_min_char   CONSTANT VARCHAR2(0050 CHAR) := '@';
    k_pat_age    CONSTANT VARCHAR2(0050 CHAR) := 'PAT_AGE';
    k_pat_gender CONSTANT VARCHAR2(0050 CHAR) := 'PAT_GENDER';

    k_yes   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    k_no    CONSTANT VARCHAR2(1 CHAR) := 'N';
    k_true  CONSTANT NUMBER(1) := 0;
    k_false CONSTANT NUMBER(1) := 1;

    k_first_row  CONSTANT NUMBER(1) := 1;
    k_short_mode CONSTANT VARCHAR2(10 CHAR) := 'SHORT';
    k_full_mode  CONSTANT VARCHAR2(10 CHAR) := 'FULL';

    k_elder_mode_sbp CONSTANT VARCHAR2(10 CHAR) := 'SBP';
    k_elder_mode_but CONSTANT VARCHAR2(10 CHAR) := 'BUTTON';

    k_deepnav_area       CONSTANT NUMBER(24) := 5;
    k_toolbar_area       CONSTANT NUMBER(24) := 3;
    k_toolbar_search     CONSTANT NUMBER(24) := 9;
    k_toolbar_area_right CONSTANT NUMBER(24) := 4;

    /**
    * Global para a preload_shortcuts - deixar aqui para ficar privada.
    */
    g_preloaded_shortcuts map_vnumber;

    FUNCTION get_pat_age(i_patient IN NUMBER) RETURN NUMBER;
    FUNCTION get_pat_gender(i_patient IN NUMBER) RETURN VARCHAR2;
    FUNCTION get_epis_type(i_episode IN NUMBER) RETURN NUMBER;
    FUNCTION is_viewer(i_software IN NUMBER) RETURN BOOLEAN;

    PROCEDURE open_my_cursor(i_cursor IN OUT c_shortcut) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_sys_application_area,
                   NULL btn_dest,
                   NULL screen_name,
                   NULL screen_area,
                   NULL flg_area,
                   NULL deepnav_id_sys_button_prop,
                   NULL btn_label,
                   NULL son_intern_name,
                   NULL btn_parent,
                   NULL btn_prop_parent,
                   NULL screen_area_parent,
                   NULL par_intern_name,
                   NULL id_sys_button_prop,
                   NULL exist_child,
                   NULL action,
                   NULL msg_copyright,
                   NULL flg_screen_mode,
                   CAST(NULL AS table_varchar) screen_params
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    FUNCTION iif
    (
        i_exp   IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_exp
        THEN
            l_return := i_true;
        ELSE
            l_return := i_false;
        END IF;
    
        RETURN l_return;
    
    END iif;

    -- ********************************************************************************
    FUNCTION is_viewer(i_software IN NUMBER) RETURN BOOLEAN IS
        tbl_flg table_varchar;
        l_flg   VARCHAR2(0100 CHAR);
        l_bool  BOOLEAN := FALSE;
    BEGIN
    
        SELECT flg_viewer
          BULK COLLECT
          INTO tbl_flg
          FROM software x
         WHERE x.id_software = i_software;
    
        IF tbl_flg.count > 0
        THEN
            l_flg := tbl_flg(1);
        
            l_bool := l_flg = k_yes;
        
        END IF;
    
        RETURN l_bool;
    
    END is_viewer;

    FUNCTION get_profile(i_prof IN profissional) RETURN profile_template%ROWTYPE IS
        l_row         profile_template%ROWTYPE;
        tbl_id        table_number;
        tbl_id_parent table_number;
    BEGIN
    
        IF is_viewer(i_prof.software)
        THEN
            SELECT pv.id_profile_template, pv.id_parent
              BULK COLLECT
              INTO tbl_id, tbl_id_parent
              FROM profile_template pv
              JOIN profile_template pt
                ON pt.id_templ_assoc = pv.id_profile_template
              JOIN prof_profile_template ppt
                ON ppt.id_profile_template = pt.id_profile_template
             WHERE pv.id_software = i_prof.software
               AND pv.flg_available = 'Y'
               AND pt.flg_available = 'Y'
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_professional = i_prof.id;
        
        ELSE
        
        SELECT prf.id_profile_template, prf.id_parent
          BULK COLLECT
          INTO tbl_id, tbl_id_parent
          FROM profile_template prf
          JOIN prof_profile_template ppt
            ON ppt.id_profile_template = prf.id_profile_template
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_software = i_prof.software
           AND ppt.id_institution = i_prof.institution
           AND id_templ_assoc IS NOT NULL;
    
        END IF;
    
        IF tbl_id.count > 0
        THEN
            l_row.id_profile_template := tbl_id(1);
            l_row.id_parent           := tbl_id_parent(1);
        END IF;
    
        RETURN l_row;
    
    END get_profile;

    FUNCTION get_string_action(i_action IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_sbp_action_elibrary        CONSTANT VARCHAR2(0200 CHAR) := 'launchExternalApplication(314)';
        k_sbp_action_scheduler       CONSTANT VARCHAR2(0200 CHAR) := 'launchExternalApplication(301)';
        k_sbp_action_pdms_backoffice CONSTANT VARCHAR2(0200 CHAR) := 'launchExternalApplication(54)';
        k_sbp_action_pdms            CONSTANT VARCHAR2(0200 CHAR) := 'launchExternalApplication(53)';
        k_sbp_action_url             CONSTANT VARCHAR2(0200 CHAR) := 'launchExternalUrl()';
        k_sbp_action_nextlevel       CONSTANT VARCHAR2(0200 CHAR) := '_global.app_access.deeperLevel';
    BEGIN
    
        CASE i_action
            WHEN 'LEXT0314' THEN
                l_return := k_sbp_action_elibrary;
            WHEN 'LEXT0301' THEN
                l_return := k_sbp_action_scheduler;
            WHEN 'LEXT0054' THEN
                l_return := k_sbp_action_pdms_backoffice;
            WHEN 'LEXT0053' THEN
                l_return := k_sbp_action_pdms;
            WHEN 'LEXTURL' THEN
                l_return := k_sbp_action_url;
            WHEN 'NXTLEVEL' THEN
                l_return := k_sbp_action_nextlevel;
            ELSE
                l_return := i_action;
        END CASE;
    
        RETURN l_return;
    END get_string_action;

    /**
    * Return array that maps a shortcut's inter_name to a id_shortcut.
    * If there's an alias, it overrides the intern_name
    * @param i_lang language id, for error message only
    * @param i_prof object with user info
    * @param i_screens table_varchar with screen names (sys_shortcut.intern_name)
    * @param i_scr_alias alias array to get the shortcut id. Each alias matches with the
    *        intern_name in the same position on the i_screens array
    * @param o_shortcuts map_vnumber which maps intern_name/alias to a number
    * @return false (error), true (all ok)
    */
    FUNCTION get_shortcuts_array
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_screens   IN table_varchar,
        i_scr_alias IN table_varchar DEFAULT NULL,
        o_shortcuts OUT map_vnumber,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_sh_row IS RECORD(
            intern_name     VARCHAR2(200 CHAR),
            id_sys_shortcut NUMBER);
        TYPE t_sh_rows IS TABLE OF t_sh_row INDEX BY BINARY_INTEGER;
        l_sh_rows t_sh_rows;
    
        l_prf profile_template%ROWTYPE;
    
    BEGIN
        l_prf := get_profile(i_prof);
    
        g_error := 'GET SHORTCUTS (' || pk_utils.concat_table(i_screens, ',') || ')';
        SELECT CAST(nvl(name_scrs.alias, name_scrs.name) AS VARCHAR2(200)) intern_name,
               (SELECT s.id_sys_shortcut
                  FROM sys_shortcut s
                 WHERE s.intern_name = name_scrs.name
                   AND s.id_software = i_prof.software
                   AND EXISTS (SELECT 0
                          FROM profile_templ_access pta
                         WHERE pta.id_profile_template = l_prf.id_parent
                           AND NOT EXISTS (SELECT 0
                                  FROM profile_templ_access p
                                 WHERE p.id_profile_template = l_prf.id_profile_template
                                   AND p.id_sys_button_prop = pta.id_sys_button_prop
                                   AND p.flg_add_remove = g_flg_type_remove)
                           AND pta.flg_add_remove = g_flg_type_add
                           AND pta.id_sys_shortcut = s.id_sys_shortcut
                           AND s.id_parent IS NULL
                        UNION ALL
                        SELECT 0
                          FROM profile_templ_access pta
                         WHERE pta.id_profile_template = l_prf.id_parent
                           AND NOT EXISTS (SELECT 0
                                  FROM profile_templ_access p
                                 WHERE p.id_profile_template = l_prf.id_profile_template
                                   AND p.id_sys_button_prop = pta.id_sys_button_prop
                                   AND p.flg_add_remove = g_flg_type_remove)
                           AND pta.flg_add_remove = g_flg_type_add
                           AND EXISTS (SELECT 0
                                  FROM sys_shortcut ss
                                 WHERE ss.id_sys_shortcut = pta.id_sys_shortcut
                                   AND ss.id_parent = s.id_sys_shortcut)
                        UNION ALL
                        SELECT 0
                          FROM profile_templ_access pta
                         WHERE pta.id_profile_template = l_prf.id_profile_template
                           AND pta.flg_add_remove = g_flg_type_add
                           AND pta.id_sys_shortcut = s.id_sys_shortcut
                           AND s.id_parent IS NULL
                        UNION ALL
                        SELECT 0
                          FROM profile_templ_access pta
                         WHERE pta.id_profile_template = l_prf.id_profile_template
                           AND pta.flg_add_remove = g_flg_type_add
                           AND EXISTS (SELECT 0
                                  FROM sys_shortcut ss
                                 WHERE ss.id_sys_shortcut = pta.id_sys_shortcut
                                   AND ss.id_parent = s.id_sys_shortcut))
                 GROUP BY s.id_sys_shortcut
                HAVING MIN(s.id_institution) IN(i_prof.institution, 0)) id_sys_shortcut
          BULK COLLECT
          INTO l_sh_rows
          FROM (SELECT name, alias
                  FROM (SELECT rownum rnum, column_value name
                          FROM TABLE(i_screens)) a
                  LEFT JOIN (SELECT rownum rnum, column_value alias
                              FROM TABLE(nvl(i_scr_alias, table_varchar()))) b
                    ON a.rnum = b.rnum) name_scrs;
    
        g_error := 'LOOP';
        FOR idx IN 1 .. l_sh_rows.count
        LOOP
            --pk_utils.put_line(idx || ' -> ' || l_sh_rows(idx).intern_name || ': ' || l_sh_rows(idx).id_sys_shortcut);
            o_shortcuts(l_sh_rows(idx).intern_name) := l_sh_rows(idx).id_sys_shortcut;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SHORTCUTS_ARRAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_shortcuts_array;

    /**
    * Preloads a few shortcuts into a global variable, which can be
    * accessed quickly and efficiently later. For more details see get_shortcuts_array.
    * NOTE: Calling this functions mutiple times does not accumulate.
    *       Previous shortcuts are erased.
    * @param i_lang language id, for error message only
    * @param i_prof object with user info
    * @param i_screens table_varchar with screen names (sys_shortcut.intern_name)
    * @param i_scr_alias alias array to get the shortcut id. Each alias matches with the
    *        intern_name in the same position on the i_screens array
    * @return false (error), true (all ok)
    */
    FUNCTION preload_shortcuts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_screens   IN table_varchar,
        i_scr_alias IN table_varchar DEFAULT NULL,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL GET_SHORTCUTS_ARRAY';
        RETURN get_shortcuts_array(i_lang, i_prof, i_screens, i_scr_alias, g_preloaded_shortcuts, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PRELOAD_SHORTCUTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END preload_shortcuts;

    FUNCTION preload_shortcuts
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER, --default null,
        i_episode   IN NUMBER, --default null
        i_screens   IN table_varchar,
        i_scr_alias IN table_varchar DEFAULT NULL,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_sbp    table_number;
        tbl_access t_tbl_access := t_tbl_access();
    BEGIN
    
        SELECT xmain.id_sys_button_prop
          BULK COLLECT
          INTO tbl_sbp
          FROM (SELECT sss.*
                  FROM (SELECT ss.*
                          FROM sys_shortcut ss
                         WHERE ss.intern_name IN ('ADMIN_DISCHARGE', 'PATIENT_ARRIVAL')
                           AND id_software = i_prof.software) sss
                CONNECT BY PRIOR sss.id_sys_shortcut = sss.id_parent
                 START WITH sss.id_parent IS NULL) xmain;
    
        tbl_access := pk_access.get_access(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_patient         => i_patient,
                                           i_episode         => i_episode,
                                           i_id_button_prop  => tbl_sbp,
                                           i_flg_visible_all => 'N');
        RETURN(tbl_access.count > 0);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PRELOAD_SHORTCUTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END preload_shortcuts;

    FUNCTION get_shortcut(i_intern_name sys_shortcut.intern_name%TYPE) RETURN sys_shortcut.id_sys_shortcut%TYPE IS
        /**
        * Returns a shortcut id, after being properly preloaded using preload_shortcuts
        * @param i_intern_name the name, or alias, of the shortcut
        * @return the shortcut id
        */
    BEGIN
        RETURN g_preloaded_shortcuts(i_intern_name);
    END get_shortcut;

    /******************************************************************************
       OBJECTIVO:   Atribuir ao profissional os acessos a botões parametrizados
              de acordo com o(s) template(s) de perfil que lhe estão atribuídos
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_PROF - ID do profissional
                 I_ID_DEP_CLIN_SERV - ID do departamento + serv. clínico
              Saida:   O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/02/23
      NOTAS:
    *********************************************************************************/
    FUNCTION set_prof_acc_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_template(i_id_profile_template IN NUMBER) IS
            SELECT pt.id_functionality, pt.id_sys_field
              FROM profile_templ_acc_func pt
             WHERE pt.id_profile_template = i_id_profile_template;
    
        l_seq   prof_access_field_func.id_prof_access_field_func%TYPE;
        l_count NUMBER(24);
        xprf    profile_template%ROWTYPE;
    
    BEGIN
        -- Percorre os acessos atribuídos aos perfis do prof.
        g_error := 'BEGIN LOOP';
        xprf    := get_profile(i_id_prof);
        FOR r_template IN c_template(xprf.id_profile_template)
        LOOP
        
            SELECT COUNT(*)
              INTO l_count
              FROM prof_access_field_func
             WHERE id_professional = i_id_prof.id
               AND id_functionality = r_template.id_functionality
               AND id_sys_field = nvl(r_template.id_sys_field, id_sys_field);
        
            g_found := l_count = 0;
        
            IF g_found
            THEN
                IF r_template.id_sys_field IS NOT NULL
                THEN
                    g_error := 'GET SEQ_PROF_ACCESS_FIELD_FUNC.NEXTVAL';
                    l_seq   := seq_prof_access_field_func.nextval;
                
                    g_error := 'INSERT';
                    INSERT INTO prof_access_field_func
                        (id_prof_access_field_func, id_professional, id_functionality, id_sys_field)
                    VALUES
                        (l_seq, i_id_prof.id, r_template.id_functionality, r_template.id_sys_field);
                
                ELSE
                    g_error := 'GET SEQ_PROF_FUNC.NEXTVAL';
                    l_seq   := seq_prof_func.nextval;
                
                    g_error := 'INSERT';
                    INSERT INTO prof_func
                        (id_prof_func, id_professional, id_functionality)
                    VALUES
                        (l_seq, i_id_prof.id, r_template.id_functionality);
                END IF;
            
                COMMIT;
            
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_PROF_ACC_FUNC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_prof_acc_func;

    /******************************************************************************
    OBJECTIVO:   Obter os botões aos quais o profissional tem acesso
           numa área aplicacional
    PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                    I_ID_PROF - ID do profissional
                  I_APPLICATION_AREA - ID da área aplicacional
                  I_ID_BUTTON - ID do botão destino do atalho, se for o caso
               Saida:   O_ACCESS - Botões aos quais o profissional tem acesso
                  O_SUB_BUTTON - Deep_navs do 1º botão
                  O_ERROR - erro
    
       CRIAÇÃO: CRS 2005/10/13
       NOTAS: O cursor O_ACCESS não inclui os deep navs, pq no caso de a função retornar
            vários botões c/ deep_nav, ñ se saberia quais mostrar.
          Os deep_navs do 1º botão são disponibilizados em O_SUB_BUTTON
     *********************************************************************************/
    FUNCTION get_prof_access_new
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        -- CMF ****
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        -- CMF ****
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        o_access           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_button_prop table_number := table_number();
        --l_bool          BOOLEAN;
        my_exception EXCEPTION;
    
        PROCEDURE process_error
        (
            i_code IN NUMBER,
            i_errm IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => i_code,
                                              i_sqlerrm  => i_errm,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_ACCESS_NEW',
                                              o_error    => o_error);
            pk_utils.undo_changes();
        
        END process_error;
    
    BEGIN
    
        g_error := 'call check_has_functionality function';
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Get all id_sys_button_prop from id_application_area';
        pk_alertlog.log_debug(g_error);
        SELECT id_sys_button_prop
          BULK COLLECT
          INTO tbl_button_prop
          FROM sys_button_prop x
         WHERE id_sys_application_area = i_application_area
           AND x.id_btn_prp_parent IS NULL;
    
        g_error := 'GET CURSOR';
        OPEN o_access FOR
            SELECT id_profile_templ_access,
                   id_sys_button,
                   nvl(pta_toolbar_level, sbp_toolbar_level) toolbar_level,
                   nvl(pta_position, sbp_position) position,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_icon) icon,
                   id_sys_screen_area,
                   sbp_flg_visible flg_visible,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_button) label,
                   intern_name_button,
                   screen_name,
                   coalesce(pk_message.get_message(i_lang, i_prof, code_button_text),
                            pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_title),
                            pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => sb_tooltip_title)) button_text,
                   sbp_flg_type flg_type,
                   pk_access.exist_child(i_lang, i_prof, i_patient, i_episode, i_application_area, id_sys_button_prop) exist_child,
                   sbp_flg_enabled flg_enabled,
                   id_sys_button_prop,
                   rank,
                   sub_rank,
                   id_software_context,
                   flg_cancel,
                   flg_content,
                   flg_create,
                   flg_detail,
                   flg_freq,
                   flg_help,
                   flg_no,
                   flg_ok,
                   flg_print,
                   flg_search,
                   flg_action,
                   flg_view,
                   flg_reset_context,
                   sb_tooltip_title,
                   sb_tooltip_desc,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_title) sbp_title,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => sb_tooltip_title) sb_title,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_desc) sbp_desc,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => sb_tooltip_desc) sb_desc,
                   ---
                   coalesce(pk_message.get_message(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_code_mess => code_tooltip_title),
                            pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => sb_tooltip_title)) tooltip_title,
                   coalesce(pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_desc),
                            pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => sb_tooltip_desc)) tooltip_desc,
                   rank2,
                   pk_access.get_string_action(sql_final.action) action,
                   flg_screen_mode,
                   pk_access.get_button_prop_params(id_sys_button_prop) screen_params,
                   --flg_info_button,
                   flg_global_shortcut
              FROM (SELECT *
                      FROM TABLE(pk_access.get_access(i_lang, i_prof, i_patient, i_episode, tbl_button_prop, k_no))) sql_final
             WHERE id_sys_screen_area != k_deepnav_area
               AND sbp_flg_visible = k_yes
             ORDER BY id_sys_screen_area,
                      --coalesce(pta_toolbar_level, sbp_toolbar_level, 0),
                      --coalesce(pta_position, sbp_position, 0),
                      rank2,
                      rank,
                      sub_rank,
                      id_sys_button_prop;
    
        g_error := 'End pk_access.get_prof_access_new';
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            process_error(i_code => SQLCODE, i_errm => SQLERRM);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            process_error(i_code => SQLCODE, i_errm => SQLERRM);
            RETURN FALSE;
        
    END get_prof_access_new;

    FUNCTION get_msg_copyright
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_msg  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        k_code_domain CONSTANT VARCHAR2(0050 CHAR) := 'SYS_BUTTON_PROP.CODE_MSG_COPYRIGHT';
        l_config VARCHAR2(1000 CHAR);
        l_return VARCHAR2(4000);
    BEGIN
    
        IF i_msg IS NOT NULL
        THEN
        
            l_config := pk_sysconfig.get_config(i_msg, i_prof.institution, i_prof.software);
            IF l_config != k_no
            THEN
            
                l_return := pk_sysdomain.get_domain(k_code_domain, i_msg, i_lang);
                l_return := pk_message.get_message(i_lang, i_prof, l_return);
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_msg_copyright;

    FUNCTION get_screen_name
    (
        i_action      IN VARCHAR2,
        i_screen_name IN VARCHAR2,
        i_count_child IN NUMBER
    ) RETURN VARCHAR2 IS
        l_action VARCHAR2(1000 CHAR);
        l_return VARCHAR2(4000);
    BEGIN
    
        l_action := nvl(i_action, '0');
    
        IF l_action = '0'
        THEN
            l_return := i_screen_name;
        
        ELSE
        
            IF i_count_child = 1
            THEN
                l_return := i_screen_name;
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_screen_name;

    FUNCTION get_action
    (
        i_action      IN VARCHAR2,
        i_count_child IN NUMBER
    ) RETURN VARCHAR2 IS
        b_action      BOOLEAN;
        b_count_child BOOLEAN;
        l_return      VARCHAR2(4000);
    
    BEGIN
    
        b_action      := nvl(i_action, '0') != '0';
        b_count_child := i_count_child NOT IN (0, 1);
        l_return      := NULL;
    
        IF b_action
           AND b_count_child
        THEN
            l_return := i_action;
        END IF;
    
        RETURN l_return;
    
    END get_action;

    FUNCTION check_func
    (
        i_flg_value           IN VARCHAR2,
        i_check_functionality IN VARCHAR2
    ) RETURN VARCHAR2 DETERMINISTIC IS
        b_flg_value  BOOLEAN;
        b_check_func BOOLEAN;
        l_return     VARCHAR2(1000 CHAR);
    BEGIN
    
        b_flg_value  := i_flg_value = k_active;
        b_check_func := i_check_functionality = k_yes;
    
        l_return := i_flg_value;
        IF b_flg_value
           AND b_check_func
        THEN
            l_return := k_inactive;
        END IF;
    
        RETURN l_return;
    
    END check_func;

    FUNCTION get_profile_template_tree
    (
        i_prof                IN profissional,
        i_id_profile_template IN NUMBER
    ) RETURN table_number IS
        l_prf table_number;
    BEGIN
    
        IF is_viewer(i_prof.software)
        THEN
        
            SELECT prf.id_profile_template
              BULK COLLECT
              INTO l_prf
              FROM profile_template prf
             START WITH prf.id_profile_template = i_id_profile_template
            CONNECT BY PRIOR prf.id_parent = prf.id_profile_template;
        
        ELSE
        
        SELECT prf.id_profile_template
          BULK COLLECT
          INTO l_prf
          FROM profile_template prf
         WHERE prf.id_templ_assoc IS NOT NULL
         START WITH prf.id_profile_template = i_id_profile_template
        CONNECT BY PRIOR prf.id_parent = prf.id_profile_template;
    
        END IF;
    
        RETURN l_prf;
    
    END get_profile_template_tree;

    /**
    * Get all accesses ( added or removed ) configured for given profile_template and all its parent profiles
    * excluding viewer profiles
    *
    * @param      i_lang                  Index language (id from DESC_LANG_X)
    * @param      i_prof                  Structure with id_professional, id_institution and id_software info.
    * @param      i_id_button_prop        id of sys_button_prop from TOP button ( sys_screen area = 3 )
    * @param      i_id_profile_template   id of profile_template configured for current user
    *
    *
    * @author                        Carlos Ferreira
    * @creation <b>version</b>       2.6.2
    * @creation <b>date</b>          2012/04/23
    */
    FUNCTION get_access_pta
    (
        i_prof                IN profissional,
        i_pat_age             IN NUMBER,
        i_pat_gender          IN VARCHAR2,
        i_epis_type           IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        t_tbl t_tbl_access;
    
        k_default_rank CONSTANT NUMBER(6) := 0;
        -- k_header is used to order exceptions rows from versioned row.
        -- Exception row are ALWAYS valued more than versioned one for a given sys_button_prop
        k_header CONSTANT VARCHAR2(0050) := 'LOWER_IDENTIFIER';
        k_prefix CONSTANT VARCHAR2(0010 CHAR) := 'PTA:';
    BEGIN
    
        ---
        SELECT t_rec_access(k_header,
                            pta_id_profile_template,
                            pta_flg_add_remove,
                            sb_id_sys_button,
                            sbp_id_sys_button_prop,
                            sb_code_icon,
                            sb_code_button,
                            sb_skin,
                            sb_intern_name_button,
                            sbp_id_sys_screen_area,
                            sbp_back_color,
                            sbp_border_color,
                            sbp_alpha,
                            sbp_screen_name,
                            sbp_action,
                            sbp_rank,
                            sbp_sub_rank,
                            sbp_flg_screen_mode,
                            sbp_code_tooltip_title,
                            sbp_code_tooltip_desc,
                            sbp_code_msg_copyright,
                            sbp_flg_reset_context,
                            pta_id_software_context,
                            pta_id_sys_shortcut,
                            pta_id_software,
                            pta_id_shortcut_pk,
                            pta_flg_cancel,
                            pta_flg_content,
                            pta_flg_create,
                            pta_flg_detail,
                            pta_flg_digital,
                            pta_flg_freq,
                            pta_flg_graph,
                            pta_flg_help,
                            pta_flg_no,
                            pta_flg_ok,
                            pta_flg_print,
                            pta_flg_search,
                            pta_flg_vision,
                            pta_flg_action,
                            nvl(pta_rank, k_default_rank),
                            pta_flg_view,
                            pta_flg_global_shortcut,
                            pta_flg_info_button,
                            pta_position,
                            sbp_position,
                            pta_toolbar_level,
                            sbp_toolbar_level,
                            sbp_flg_visible,
                            sb_flg_type,
                            sbp_flg_enabled,
                            sbp_code_button_text,
                            sb_code_tooltip_title,
                            sb_code_tooltip_desc,
                            0,
                            id_profile_templ_access,
                            age_min,
                            age_max,
                            gender,
                            id_epis_type)
          BULK COLLECT
          INTO t_tbl
          FROM ( select x03.* ,
                       dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                 from 
                 (SELECT xsql01.*
                --, dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                --1 my_rank
                  FROM (SELECT k_prefix || to_char(pta.id_profile_templ_access) id_profile_templ_access,
                               pta.id_profile_template pta_id_profile_template,
                               pta.flg_add_remove pta_flg_add_remove,
                               sb.id_sys_button sb_id_sys_button,
                               sbp.id_sys_button_prop sbp_id_sys_button_prop,
                               sb.code_icon sb_code_icon,
                               sb.code_button sb_code_button,
                               sb.skin sb_skin,
                               sb.intern_name_button sb_intern_name_button,
                               sbp.id_sys_screen_area sbp_id_sys_screen_area,
                               --sbp.back_color sbp_back_color,
                               NULL sbp_back_color,
                               --sbp.border_color sbp_border_color,
                               NULL sbp_border_color,
                               --sbp.alpha sbp_alpha,
                               NULL                    sbp_alpha,
                               sbp.screen_name         sbp_screen_name,
                               sbp.action              sbp_action,
                               sbp.rank                sbp_rank,
                               sbp.sub_rank            sbp_sub_rank,
                               sbp.flg_screen_mode     sbp_flg_screen_mode,
                               sbp.code_tooltip_title  sbp_code_tooltip_title,
                               sbp.code_tooltip_desc   sbp_code_tooltip_desc,
                               sbp.code_msg_copyright  sbp_code_msg_copyright,
                               sbp.flg_reset_context   sbp_flg_reset_context,
                               pta.id_software_context pta_id_software_context,
                               pta.id_sys_shortcut     pta_id_sys_shortcut,
                               pta.id_software         pta_id_software,
                               pta.id_shortcut_pk      pta_id_shortcut_pk,
                               pta.flg_cancel          pta_flg_cancel,
                               pta.flg_content         pta_flg_content,
                               pta.flg_create          pta_flg_create,
                               pta.flg_detail          pta_flg_detail,
                               --pta.flg_digital pta_flg_digital,
                               NULL         pta_flg_digital,
                               pta.flg_freq pta_flg_freq,
                               --pta.flg_graph pta_flg_graph,
                               NULL           pta_flg_graph,
                               pta.flg_help   pta_flg_help,
                               pta.flg_no     pta_flg_no,
                               pta.flg_ok     pta_flg_ok,
                               pta.flg_print  pta_flg_print,
                               pta.flg_search pta_flg_search,
                               --pta.flg_vision pta_flg_vision,
                               NULL                    pta_flg_vision,
                               pta.flg_action          pta_flg_action,
                               pta.rank                pta_rank,
                               pta.flg_view            pta_flg_view,
                               pta.flg_global_shortcut pta_flg_global_shortcut,
                               --pta.flg_info_button pta_flg_info_button,
                               NULL pta_flg_info_button,
                               pta.position pta_position,
                               sbp.position sbp_position,
                               pta.toolbar_level pta_toolbar_level,
                               sbp.toolbar_level sbp_toolbar_level,
                               sbp.flg_visible sbp_flg_visible,
                               sb.flg_type sb_flg_type,
                               sbp.flg_enabled sbp_flg_enabled,
                               sbp.code_button_text sbp_code_button_text,
                               sb.code_tooltip_title sb_code_tooltip_title,
                               sb.code_tooltip_desc sb_code_tooltip_desc,
                               --coalesce(pta.age_min, k_low_limit) age_min,
                               coalesce(pta.age_min, k_low_limit) age_min,
                               coalesce(pta.age_max, k_high_limit) age_max,
                               coalesce(pta.gender, k_min_char) gender,
                               coalesce(pta.id_epis_type, k_low_limit) id_epis_type
                          FROM sys_button_prop sbp
                          JOIN sys_button sb
                            ON sb.id_sys_button = sbp.id_sys_button
                          JOIN profile_templ_access pta
                            ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                         WHERE rownum > 0
                           AND pta.id_software = i_prof.software
                           AND pta.id_profile_template IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(pk_access.get_profile_template_tree(i_prof, i_id_profile_template)) t)
                           AND (sbp.id_btn_prp_parent IN (SELECT /*+ opt_estimate(table x1 rows=1) */
                                                           column_value
                                                            FROM TABLE(i_id_button_prop) x1) AND
                               i_flg_visible_all = k_sbp_visible)
                           AND sbp.flg_visible IN (i_flg_visible_all, k_sbp_visible)) xsql01
                UNION ALL
                SELECT xsql02.*
                --, dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                --1 my_rank
                  FROM (SELECT k_prefix || to_char(pta.id_profile_templ_access) id_profile_templ_access,
                               pta.id_profile_template pta_id_profile_template,
                               pta.flg_add_remove pta_flg_add_remove,
                               sb.id_sys_button sb_id_sys_button,
                               sbp.id_sys_button_prop sbp_id_sys_button_prop,
                               sb.code_icon sb_code_icon,
                               sb.code_button sb_code_button,
                               sb.skin sb_skin,
                               sb.intern_name_button sb_intern_name_button,
                               sbp.id_sys_screen_area sbp_id_sys_screen_area,
                               --sbp.back_color sbp_back_color,
                               --sbp.border_color sbp_border_color,
                               --sbp.alpha sbp_alpha,
                               NULL                    sbp_back_color,
                               NULL                    sbp_border_color,
                               NULL                    sbp_alpha,
                               sbp.screen_name         sbp_screen_name,
                               sbp.action              sbp_action,
                               sbp.rank                sbp_rank,
                               sbp.sub_rank            sbp_sub_rank,
                               sbp.flg_screen_mode     sbp_flg_screen_mode,
                               sbp.code_tooltip_title  sbp_code_tooltip_title,
                               sbp.code_tooltip_desc   sbp_code_tooltip_desc,
                               sbp.code_msg_copyright  sbp_code_msg_copyright,
                               sbp.flg_reset_context   sbp_flg_reset_context,
                               pta.id_software_context pta_id_software_context,
                               pta.id_sys_shortcut     pta_id_sys_shortcut,
                               pta.id_software         pta_id_software,
                               pta.id_shortcut_pk      pta_id_shortcut_pk,
                               pta.flg_cancel          pta_flg_cancel,
                               pta.flg_content         pta_flg_content,
                               pta.flg_create          pta_flg_create,
                               pta.flg_detail          pta_flg_detail,
                               --pta.flg_digital pta_flg_digital,
                               NULL         pta_flg_digital,
                               pta.flg_freq pta_flg_freq,
                               ---pta.flg_graph pta_flg_graph,
                               NULL           pta_flg_graph,
                               pta.flg_help   pta_flg_help,
                               pta.flg_no     pta_flg_no,
                               pta.flg_ok     pta_flg_ok,
                               pta.flg_print  pta_flg_print,
                               pta.flg_search pta_flg_search,
                               --pta.flg_vision pta_flg_vision,
                               NULL                    pta_flg_vision,
                               pta.flg_action          pta_flg_action,
                               pta.rank                pta_rank,
                               pta.flg_view            pta_flg_view,
                               pta.flg_global_shortcut pta_flg_global_shortcut,
                               --pta.flg_info_button pta_flg_info_button,
                               NULL pta_flg_info_button,
                               pta.position pta_position,
                               sbp.position sbp_position,
                               pta.toolbar_level pta_toolbar_level,
                               sbp.toolbar_level sbp_toolbar_level,
                               sbp.flg_visible sbp_flg_visible,
                               sb.flg_type sb_flg_type,
                               sbp.flg_enabled sbp_flg_enabled,
                               sbp.code_button_text sbp_code_button_text,
                               sb.code_tooltip_title sb_code_tooltip_title,
                               sb.code_tooltip_desc sb_code_tooltip_desc,
                               coalesce(pta.age_min, k_low_limit) age_min,
                               coalesce(pta.age_max, k_high_limit) age_max,
                               coalesce(pta.gender, k_min_char) gender,
                               coalesce(pta.id_epis_type, k_low_limit) id_epis_type
                          FROM sys_button_prop sbp
                          JOIN sys_button sb
                            ON sb.id_sys_button = sbp.id_sys_button
                          JOIN profile_templ_access pta
                            ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                         WHERE rownum > 0
                           AND pta.id_software = i_prof.software
                           AND pta.id_profile_template IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(pk_access.get_profile_template_tree(i_prof, i_id_profile_template)) t)
                           AND (sbp.id_sys_button_prop IN (SELECT /*+ opt_estimate(table x2 rows=1) */
                                                            column_value
                                                             FROM TABLE(i_id_button_prop) x2) AND
                               i_flg_visible_all != k_sbp_visible)
                           AND sbp.flg_visible IN (i_flg_visible_all, k_sbp_visible)) xsql02) x03
         WHERE 0 = 0
           --AND x03.age_min <= i_pat_age
           AND x03.age_min <= i_pat_age
           AND x03.age_max >= i_pat_age
           AND x03.id_epis_type IN (i_epis_type, k_low_limit)
           AND x03.gender IN (i_pat_gender, k_min_char)
           ) main_select
         WHERE 0 = 0
           AND main_select.my_rank = 1;
    
        RETURN t_tbl;
    
    END get_access_pta;

    /**
    * Get all accesses exceptions( added or removed ) configured for given profile_template and all its parent profiles
    * excluding viewer profiles for an institution.
    *
    * @param      i_lang                  Index language (id from DESC_LANG_X)
    * @param      i_prof                  Structure with id_professional, id_institution and id_software info.
    * @param      i_id_button_prop        id of sys_button_prop from TOP button ( sys_screen area = 3 )
    * @param      i_id_profile_template   id of profile_template configured for current user
    *
    *
    * @author                        Carlos Ferreira
    * @creation <b>version</b>       2.6.2
    * @creation <b>date</b>          2012/04/23
    */
    FUNCTION get_access_ptae
    (
        i_prof                IN profissional,
        i_pat_age             IN NUMBER,
        i_pat_gender          IN VARCHAR2,
        i_epis_type           IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        t_tbl t_tbl_access;
        --k_default_rank CONSTANT NUMBER(6) := 0;
        -- k_header is used to order exceptions rows from versioned row.
        -- Exception row are ALWAYS valued more than versioned one for a given sys_button_prop
        k_header CONSTANT VARCHAR2(0050) := 'HIGHER_IDENTIFIER';
        k_prefix CONSTANT VARCHAR2(0010 CHAR) := 'PTAE:';
    BEGIN
    
        SELECT t_rec_access(k_header,
                            pta_id_profile_template,
                            pta_flg_type, --pta.flg_add_remove,
                            sb_id_sys_button,
                            sbp_id_sys_button_prop,
                            sb_code_icon,
                            sb_code_button,
                            sb_skin,
                            sb_intern_name_button,
                            sbp_id_sys_screen_area,
                            sbp_back_color,
                            sbp_border_color,
                            sbp_alpha,
                            sbp_screen_name,
                            sbp_action,
                            sbp_rank,
                            sbp_sub_rank,
                            sbp_flg_screen_mode,
                            sbp_code_tooltip_title,
                            sbp_code_tooltip_desc,
                            sbp_code_msg_copyright,
                            sbp_flg_reset_context,
                            pta_id_software_context,
                            pta_id_sys_shortcut,
                            pta_id_software,
                            pta_id_shortcut_pk,
                            pta_flg_cancel,
                            pta_flg_content,
                            pta_flg_create,
                            pta_flg_detail,
                            pta_flg_digital,
                            pta_flg_freq,
                            pta_flg_graph,
                            pta_flg_help,
                            pta_flg_no,
                            pta_flg_ok,
                            pta_flg_print,
                            pta_flg_search,
                            pta_flg_vision,
                            pta_flg_action,
                            nvl(pta_rank, sbp_rank),
                            pta_flg_view,
                            pta_flg_global_shortcut,
                            pta_flg_info_button,
                            pta_position,
                            sbp_position,
                            pta_toolbar_level,
                            sbp_toolbar_level,
                            sbp_flg_visible,
                            sb_flg_type,
                            sbp_flg_enabled,
                            sbp_code_button_text,
                            sb_code_tooltip_title,
                            sb_code_tooltip_desc,
                            0,
                            id_profile_templ_access,
                            age_min,
                            age_max,
                            gender,
                            id_epis_type)
          BULK COLLECT
          INTO t_tbl
          FROM ( select x03.* ,
                       dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                 from 
                 (SELECT xsql01.*
                --, dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                --1 my_rank
                  FROM (SELECT k_prefix || to_char(pta.id_prof_templ_access_exception) id_profile_templ_access,
                               pta.id_profile_template pta_id_profile_template,
                               pta.flg_type pta_flg_type, --pta.flg_add_remove,
                               sb.id_sys_button sb_id_sys_button,
                               sbp.id_sys_button_prop sbp_id_sys_button_prop,
                               sb.code_icon sb_code_icon,
                               sb.code_button sb_code_button,
                               sb.skin sb_skin,
                               sb.intern_name_button sb_intern_name_button,
                               sbp.id_sys_screen_area sbp_id_sys_screen_area,
                               --sbp.back_color sbp_back_color,
                               --sbp.border_color sbp_border_color,
                               --sbp.alpha sbp_alpha,
                               NULL                    sbp_back_color,
                               NULL                    sbp_border_color,
                               NULL                    sbp_alpha,
                               sbp.screen_name         sbp_screen_name,
                               sbp.action              sbp_action,
                               sbp.rank                sbp_rank,
                               sbp.sub_rank            sbp_sub_rank,
                               sbp.flg_screen_mode     sbp_flg_screen_mode,
                               sbp.code_tooltip_title  sbp_code_tooltip_title,
                               sbp.code_tooltip_desc   sbp_code_tooltip_desc,
                               sbp.code_msg_copyright  sbp_code_msg_copyright,
                               sbp.flg_reset_context   sbp_flg_reset_context,
                               pta.id_software_context pta_id_software_context,
                               pta.id_sys_shortcut     pta_id_sys_shortcut,
                               pta.id_software         pta_id_software,
                               pta.id_shortcut_pk      pta_id_shortcut_pk,
                               pta.flg_cancel          pta_flg_cancel,
                               pta.flg_content         pta_flg_content,
                               pta.flg_create          pta_flg_create,
                               pta.flg_detail          pta_flg_detail,
                               --pta.flg_digital pta_flg_digital,
                               NULL         pta_flg_digital,
                               pta.flg_freq pta_flg_freq,
                               --pta.flg_graph pta_flg_graph,
                               NULL           pta_flg_graph,
                               pta.flg_help   pta_flg_help,
                               pta.flg_no     pta_flg_no,
                               pta.flg_ok     pta_flg_ok,
                               pta.flg_print  pta_flg_print,
                               pta.flg_search pta_flg_search,
                               --pta.flg_vision pta_flg_vision,
                               NULL                    pta_flg_vision,
                               pta.flg_action          pta_flg_action,
                               pta.rank                pta_rank,
                               pta.flg_view            pta_flg_view,
                               pta.flg_global_shortcut pta_flg_global_shortcut,
                               --pta.flg_info_button pta_flg_info_button,
                               NULL pta_flg_info_button,
                               pta.position pta_position,
                               sbp.position sbp_position,
                               pta.toolbar_level pta_toolbar_level,
                               sbp.toolbar_level sbp_toolbar_level,
                               sbp.flg_visible sbp_flg_visible,
                               sb.flg_type sb_flg_type,
                               sbp.flg_enabled sbp_flg_enabled,
                               sbp.code_button_text sbp_code_button_text,
                               sb.code_tooltip_title sb_code_tooltip_title,
                               sb.code_tooltip_desc sb_code_tooltip_desc,
                               coalesce(pta.age_min, k_low_limit) age_min,
                               coalesce(pta.age_max, k_high_limit) age_max,
                               coalesce(pta.gender, k_min_char) gender,
                               coalesce(pta.id_epis_type, k_low_limit) id_epis_type
                          FROM sys_button_prop sbp
                          JOIN sys_button sb
                            ON sb.id_sys_button = sbp.id_sys_button
                          JOIN profile_templ_access_exception pta
                            ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                         WHERE rownum > 0
                           AND pta.id_software = i_prof.software
                           AND pta.id_institution = i_prof.institution
                           AND pta.id_profile_template IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(pk_access.get_profile_template_tree(i_prof, i_id_profile_template)) t)
                           AND (sbp.id_btn_prp_parent IN (SELECT /*+ opt_estimate(table x1 rows=1) */
                                                           column_value
                                                            FROM TABLE(i_id_button_prop) x1) AND
                               i_flg_visible_all = k_sbp_visible)
                           AND sbp.flg_visible IN (i_flg_visible_all, k_sbp_visible)) xsql01
                UNION ALL
                SELECT xsql02.*
                  --, dense_rank() over(PARTITION BY sbp_id_sys_button_prop ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank
                --1 my_rank
                  FROM (SELECT k_prefix || to_char(pta.id_prof_templ_access_exception) id_profile_templ_access,
                               pta.id_profile_template pta_id_profile_template,
                               pta.flg_type pta_flg_type, --pta.flg_add_remove,
                               sb.id_sys_button sb_id_sys_button,
                               sbp.id_sys_button_prop sbp_id_sys_button_prop,
                               sb.code_icon sb_code_icon,
                               sb.code_button sb_code_button,
                               sb.skin sb_skin,
                               sb.intern_name_button sb_intern_name_button,
                               sbp.id_sys_screen_area sbp_id_sys_screen_area,
                               --sbp.back_color sbp_back_color,
                               --sbp.border_color sbp_border_color,
                               --sbp.alpha sbp_alpha,
                               NULL                    sbp_back_color,
                               NULL                    sbp_border_color,
                               NULL                    sbp_alpha,
                               sbp.screen_name         sbp_screen_name,
                               sbp.action              sbp_action,
                               sbp.rank                sbp_rank,
                               sbp.sub_rank            sbp_sub_rank,
                               sbp.flg_screen_mode     sbp_flg_screen_mode,
                               sbp.code_tooltip_title  sbp_code_tooltip_title,
                               sbp.code_tooltip_desc   sbp_code_tooltip_desc,
                               sbp.code_msg_copyright  sbp_code_msg_copyright,
                               sbp.flg_reset_context   sbp_flg_reset_context,
                               pta.id_software_context pta_id_software_context,
                               pta.id_sys_shortcut     pta_id_sys_shortcut,
                               pta.id_software         pta_id_software,
                               pta.id_shortcut_pk      pta_id_shortcut_pk,
                               pta.flg_cancel          pta_flg_cancel,
                               pta.flg_content         pta_flg_content,
                               pta.flg_create          pta_flg_create,
                               pta.flg_detail          pta_flg_detail,
                               --pta.flg_digital pta_flg_digital,
                               NULL         pta_flg_digital,
                               pta.flg_freq pta_flg_freq,
                               --pta.flg_graph pta_flg_graph,
                               NULL           pta_flg_graph,
                               pta.flg_help   pta_flg_help,
                               pta.flg_no     pta_flg_no,
                               pta.flg_ok     pta_flg_ok,
                               pta.flg_print  pta_flg_print,
                               pta.flg_search pta_flg_search,
                               --pta.flg_vision pta_flg_vision,
                               NULL                    pta_flg_vision,
                               pta.flg_action          pta_flg_action,
                               pta.rank                pta_rank,
                               pta.flg_view            pta_flg_view,
                               pta.flg_global_shortcut pta_flg_global_shortcut,
                               --pta.flg_info_button pta_flg_info_button,
                               NULL pta_flg_info_button,
                               pta.position pta_position,
                               sbp.position sbp_position,
                               pta.toolbar_level pta_toolbar_level,
                               sbp.toolbar_level sbp_toolbar_level,
                               sbp.flg_visible sbp_flg_visible,
                               sb.flg_type sb_flg_type,
                               sbp.flg_enabled sbp_flg_enabled,
                               sbp.code_button_text sbp_code_button_text,
                               sb.code_tooltip_title sb_code_tooltip_title,
                               sb.code_tooltip_desc sb_code_tooltip_desc,
                               coalesce(pta.age_min, k_low_limit) age_min,
                               coalesce(pta.age_max, k_high_limit) age_max,
                               coalesce(pta.gender, k_min_char) gender,
                               coalesce(pta.id_epis_type, k_low_limit) id_epis_type
                          FROM sys_button_prop sbp
                          JOIN sys_button sb
                            ON sb.id_sys_button = sbp.id_sys_button
                          JOIN profile_templ_access_exception pta
                            ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                         WHERE rownum > 0
                           AND pta.id_software = i_prof.software
                           AND pta.id_institution = i_prof.institution
                           AND pta.id_profile_template IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(pk_access.get_profile_template_tree(i_prof, i_id_profile_template)) t)
                           AND (sbp.id_sys_button_prop IN (SELECT /*+ opt_estimate(table x2 rows=1) */
                                                            column_value
                                                             FROM TABLE(i_id_button_prop) x2) AND
                               i_flg_visible_all != k_sbp_visible)
                           AND sbp.flg_visible IN (i_flg_visible_all, k_sbp_visible)) xsql02)  x03
         WHERE 0 = 0
           --AND x03.age_min <= i_pat_age
           AND x03.age_min <= i_pat_age
           AND x03.age_max >= i_pat_age
           AND x03.id_epis_type IN (i_epis_type, k_low_limit)
           AND x03.gender IN (i_pat_gender, k_min_char)
           ) main_select
         WHERE 0 = 0
           AND main_select.my_rank = 1;
    
        RETURN t_tbl;
    
    END get_access_ptae;

    /**
    * Merges the content of get_access_pta ( accesses versioned ) and get_access_ptae ( exceptions )
    *
    * @param      i_lang                  Index language (id from DESC_LANG_X)
    * @param      i_prof                  Structure with id_professional, id_institution and id_software info.
    * @param      i_id_button_prop        id of sys_button_prop from TOP button ( sys_screen area = 3 )
    * @param      i_id_profile_template   id of profile_template configured for current user
    *
    *
    * @author                        Carlos Ferreira
    * @creation <b>version</b>       2.6.2
    * @creation <b>date</b>          2012/04/23
    */
    FUNCTION get_access_pta_ptae
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        t_pta  t_tbl_access;
        t_ptae t_tbl_access;
        t_all  t_tbl_access;
    
        l_pat_age    NUMBER;
        l_pat_gender VARCHAR2(0010 CHAR);
        l_epis_type  NUMBER;
    
    BEGIN
    
        l_pat_age    := get_pat_age(i_patient);
        l_pat_gender := get_pat_gender(i_patient);
        l_epis_type  := get_epis_type(i_episode);
    
        l_pat_age := coalesce(l_pat_age, k_low_limit);
    
        t_pta  := get_access_pta(i_prof,
                                 l_pat_age,
                                 l_pat_gender,
                                 l_epis_type,
                                 i_id_button_prop,
                                 i_id_profile_template,
                                 i_flg_visible_all);
        t_ptae := get_access_ptae(i_prof,
                                  l_pat_age,
                                  l_pat_gender,
                                  l_epis_type,
                                  i_id_button_prop,
                                  i_id_profile_template,
                                  i_flg_visible_all);
    
        t_all := t_pta MULTISET UNION t_ptae;
    
        RETURN t_all;
    
    END get_access_pta_ptae;

    /**
    * This function aggregates the result of get_access_pta_ptae by id_sys_button_prop,
    * ordering the rows by id_profile_template ( it is assumed that child rows have a higher id then the parent row )
    * and data_origin ( which is the field that mark from which dataset , versioned or exceptions, the row belongs .
    * That is, Child profile_Template from a exception will be first than a versioned row for same/parent profile.
    *
    * @param      i_lang                  Index language (id from DESC_LANG_X)
    * @param      i_prof                  Structure with id_professional, id_institution and id_software info.
    * @param      i_id_button_prop        id of sys_button_prop from TOP button ( sys_screen area = 3 )
    * @param      i_id_profile_template   id of profile_template configured for current user
    *
    *
    * @author                        Carlos Ferreira
    * @creation <b>version</b>       2.6.2
    * @creation <b>date</b>          2012/04/23
    */
    FUNCTION get_agg_access
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN NUMBER,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        l_id_button_prop table_number := table_number(i_id_button_prop);
    BEGIN
    
        RETURN get_agg_access(i_prof, i_patient, i_episode, l_id_button_prop, i_id_profile_template, i_flg_visible_all);
    
    END get_agg_access;

    FUNCTION get_agg_access
    (
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN table_number,
        i_id_profile_template IN NUMBER,
        i_flg_visible_all     IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        l_prf             profile_template%ROWTYPE;
        t_tbl             t_tbl_access;
        l_current_profile NUMBER(24);
        l_parent_profile  NUMBER(24);
        k_first CONSTANT NUMBER(24) := 99;
        k_last  CONSTANT NUMBER(24) := 0;
    BEGIN
    
        l_prf             := get_profile(i_prof);
        l_current_profile := l_prf.id_profile_template;
        l_parent_profile  := l_prf.id_parent;
    
        SELECT t_rec_access(data_origin,
                            id_profile_template,
                            flg_add_remove,
                            id_sys_button,
                            id_sys_button_prop,
                            code_icon,
                            code_button,
                            skin,
                            intern_name_button,
                            id_sys_screen_area,
                            back_color,
                            border_color,
                            alpha,
                            screen_name,
                            action,
                            rank,
                            sub_rank,
                            flg_screen_mode,
                            code_tooltip_title,
                            code_tooltip_desc,
                            code_msg_copyright,
                            flg_reset_context,
                            id_software_context,
                            id_sys_shortcut,
                            id_software,
                            id_shortcut_pk,
                            flg_cancel,
                            flg_content,
                            flg_create,
                            flg_detail,
                            flg_digital,
                            flg_freq,
                            flg_graph,
                            flg_help,
                            flg_no,
                            flg_ok,
                            flg_print,
                            flg_search,
                            flg_vision,
                            flg_action,
                            rank2,
                            flg_view,
                            flg_global_shortcut,
                            flg_info_button,
                            pta_position,
                            sbp_position,
                            pta_toolbar_level,
                            sbp_toolbar_level,
                            sbp_flg_visible,
                            sbp_flg_type,
                            sbp_flg_enabled,
                            code_button_text,
                            sb_tooltip_title,
                            sb_tooltip_desc,
                            my_rank,
                            id_profile_templ_access,
                            age_min,
                            age_max,
                            flg_gender,
                            id_epis_type)
          BULK COLLECT
          INTO t_tbl
          FROM (SELECT /*+ opt_estimate(table t_agg rows=1) */
                 id_profile_templ_access,
                 data_origin,
                 id_profile_template,
                 flg_add_remove,
                 id_sys_button,
                 id_sys_button_prop,
                 code_icon,
                 code_button,
                 skin,
                 intern_name_button,
                 id_sys_screen_area,
                 back_color,
                 border_color,
                 alpha,
                 screen_name,
                 action,
                 rank,
                 sub_rank,
                 flg_screen_mode,
                 code_tooltip_title,
                 code_tooltip_desc,
                 code_msg_copyright,
                 flg_reset_context,
                 id_software_context,
                 id_sys_shortcut,
                 id_software,
                 id_shortcut_pk,
                 flg_cancel,
                 flg_content,
                 flg_create,
                 flg_detail,
                 flg_digital,
                 flg_freq,
                 flg_graph,
                 flg_help,
                 flg_no,
                 flg_ok,
                 flg_print,
                 flg_search,
                 flg_vision,
                 flg_action,
                 rank2,
                 flg_view,
                 flg_global_shortcut,
                 flg_info_button,
                 pta_position,
                 sbp_position,
                 pta_toolbar_level,
                 sbp_toolbar_level,
                 sbp_flg_visible,
                 sbp_flg_type,
                 sbp_flg_enabled,
                 code_button_text,
                 sb_tooltip_title,
                 sb_tooltip_desc,
                 age_min,
                 age_max,
                 flg_gender,
                 id_epis_type,
                 rank() over(PARTITION BY id_sys_button_prop ORDER BY decode(id_profile_template, l_current_profile, k_first, l_parent_profile, k_last) DESC, data_origin ASC) my_rank
                  FROM (SELECT *
                          FROM TABLE(pk_access.get_access_pta_ptae(i_prof,
                                                                   i_patient,
                                                                   i_episode,
                                                                   i_id_button_prop,
                                                                   i_id_profile_template,
                                                                   i_flg_visible_all))) t_agg);
    
        RETURN t_tbl;
    
    END get_agg_access;

    FUNCTION get_access
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_patient         IN NUMBER,
        i_episode         IN NUMBER,
        i_id_button_prop  IN table_number,
        i_flg_visible_all IN VARCHAR2 DEFAULT k_sbp_visible
    ) RETURN t_tbl_access IS
        l_check_functionality VARCHAR2(1 CHAR);
        l_prf                 profile_template%ROWTYPE;
        l_id_profile_template NUMBER(24);
    
        l_tbl t_tbl_access;
    BEGIN
    
        l_prf                 := get_profile(i_prof);
        l_id_profile_template := l_prf.id_profile_template;
    
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => g_view_only_profile);
        SELECT t_rec_access(data_origin,
                            id_profile_template,
                            flg_add_remove,
                            id_sys_button,
                            id_sys_button_prop,
                            code_icon, --code_icon icon,
                            code_button, --code_button label,
                            skin,
                            intern_name_button,
                            id_sys_screen_area,
                            back_color,
                            border_color,
                            alpha,
                            screen_name,
                            action,
                            rank,
                            sub_rank,
                            flg_screen_mode,
                            code_tooltip_title, -- code_tooltip_title tooltip_title,
                            code_tooltip_desc, -- code_tooltip_desc  tooltip_desc,
                            code_msg_copyright,
                            flg_reset_context,
                            id_software_context,
                            id_sys_shortcut,
                            id_software,
                            id_shortcut_pk,
                            check_func(flg_cancel, l_check_functionality), -- flg_cancel,
                            flg_content,
                            check_func(flg_create, l_check_functionality), -- flg_create,
                            flg_detail,
                            check_func(flg_digital, l_check_functionality), -- flg_digital,
                            check_func(flg_freq, l_check_functionality), -- flg_freq,
                            flg_graph,
                            flg_help,
                            check_func(flg_no, l_check_functionality), -- flg_no,
                            flg_ok,
                            flg_print,
                            check_func(flg_search, l_check_functionality), -- flg_search,
                            flg_vision,
                            check_func(flg_action, l_check_functionality), -- flg_action,
                            rank2,
                            flg_view,
                            flg_global_shortcut,
                            flg_info_button,
                            pta_position,
                            sbp_position,
                            pta_toolbar_level,
                            sbp_toolbar_level,
                            sbp_flg_visible,
                            sbp_flg_type,
                            sbp_flg_enabled,
                            code_button_text, -- code_button_text  button_text,
                            sb_tooltip_title, -- sb_tooltip_title  sb_tooltip_title,
                            sb_tooltip_desc, -- sb_tooltip_desc   sb_tooltip_desc,
                            my_rank,
                            id_profile_templ_access,
                            age_min,
                            age_max,
                            flg_gender,
                            id_epis_type)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT *
                  FROM TABLE(pk_access.get_agg_access(i_prof,
                                                      i_patient,
                                                      i_episode,
                                                      i_id_button_prop,
                                                      l_id_profile_template,
                                                      i_flg_visible_all))) sql_final
         WHERE sql_final.my_rank = k_first_row
           AND sql_final.flg_add_remove = g_flg_type_add
         ORDER BY rank2, rank, sub_rank;
    
        RETURN l_tbl;
    
    END get_access;

    /**
    * Get deep_navs that professional have access on a button or sub deep_navs inside a deep_nav
    * Fucntion will get only records that are meant to be accessed ( flg_add_remove = A ) and first in order of partitioning
    * of function get_agg_access
    * @param i_lang language id, for error message only
    * @param i_prof object with user info (Professional ID, Institution ID, Software ID)
    * @param i_id_button button to analyse
    * @param i_id_button_prop
    * @param i_application_area application area
    * @param o_sub_butt list deep_navs
    * @param o_parent returns info from the parent button
    *
    * @return false (error), true (ok)
    *
    * @author -
    * @version -
    * @since -
    *
    */
    FUNCTION get_prof_access_sub_butt_new
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN NUMBER,
        i_episode          IN NUMBER,
        i_id_button        IN sys_button.id_sys_button%TYPE,
        i_id_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        o_sub_butt         OUT pk_types.cursor_type,
        o_parent           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sys_button_prop  table_number := table_number(i_id_button_prop);
        l_elder               NUMBER;
        l_elder_button        NUMBER;
        l_id_button           NUMBER;
        l_id_application_area NUMBER;
    
        FUNCTION get_btn_prp_parent
        (
            i_num  IN NUMBER,
            i_mode IN VARCHAR2
        ) RETURN NUMBER IS
            l_return   NUMBER;
            tbl_return table_number;
        BEGIN
        
            SELECT CASE
                       WHEN i_mode = k_elder_mode_sbp THEN
                        sbp.id_btn_prp_parent
                       WHEN i_mode = k_elder_mode_but THEN
                        sbp.id_sys_button
                       ELSE
                        NULL
                   END
              BULK COLLECT
              INTO tbl_return
              FROM sys_button_prop sbp
             WHERE sbp.id_sys_button_prop = i_num;
        
            IF tbl_return.count > 0
            THEN
                l_return := tbl_return(1);
            END IF;
        
            RETURN l_return;
        
        END get_btn_prp_parent;
    
        --***************************************
        PROCEDURE fill_the_blanks IS
        BEGIN
        
            IF i_id_button IS NULL
               OR i_application_area IS NULL
            THEN
            
                SELECT sbp.id_sys_button, sbp.id_sys_application_area
                  INTO l_id_button, l_id_application_area
                  FROM sys_button_prop sbp
                 WHERE sbp.id_sys_button_prop = i_id_button_prop;
            
                l_id_button           := coalesce(i_id_button, l_id_button);
                l_id_application_area := coalesce(i_application_area, l_id_application_area);
            
            END IF;
        
        END fill_the_blanks;
    
    BEGIN
    
        g_error := 'CALL CHECK_HAS_FUNCTIONALITY FUNCTION';
        pk_alertlog.log_debug(g_error);
        --if profile has read only permission, so is necessary disable the flg_create, flg_action, flg_cancel
        --flg_search,flg_digital, flg_freq and flg_no in case if theses flag are actives
    
        l_elder        := get_btn_prp_parent(i_num => i_id_button_prop, i_mode => k_elder_mode_sbp);
        l_elder_button := get_btn_prp_parent(i_num => l_elder, i_mode => k_elder_mode_but);
    
        fill_the_blanks();
    
        g_error := 'GET CURSOR';
        OPEN o_sub_butt FOR
            SELECT id_profile_templ_access,
                   id_sys_button,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_icon) icon,
                   id_sys_screen_area,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_button) label,
                   intern_name_button,
                   screen_name,
                   pk_access.exist_child(i_lang,
                                         i_prof,
                                         i_patient,
                                         i_episode,
                                         l_id_application_area,
                                         id_sys_button_prop) exist_child,
                   id_sys_button_prop,
                   l_elder id_elder_button_prop,
                   l_elder_button id_elder_button,
                   rank,
                   sub_rank,
                   id_software_context,
                   flg_cancel,
                   flg_content,
                   flg_create,
                   flg_detail,
                   flg_freq,
                   flg_help,
                   flg_no,
                   flg_ok,
                   flg_print,
                   flg_search,
                   flg_action,
                   flg_view,
                   flg_reset_context,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_title) tooltip_title,
                   pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_tooltip_desc) tooltip_desc,
                   rank2,
                   pk_access.get_string_action(sql_final.action) action,
                   flg_screen_mode,
                   pk_access.get_button_prop_params(id_sys_button_prop) screen_params,
                   --skin,
                   --back_color,
                   --border_color,
                   --alpha,
                   --flg_digital,
                   --flg_graph,
                   --flg_vision,
                   --flg_search,
                   --flg_info_button,
                   flg_global_shortcut
              FROM (SELECT *
                      FROM TABLE(pk_access.get_access(i_lang, i_prof, i_patient, i_episode, l_id_sys_button_prop))) sql_final
             ORDER BY rank2, rank, sub_rank;
    
        OPEN o_parent FOR
            SELECT sbpparent.id_sys_button_prop, sbpparent.id_sys_button, sbpparent.id_sys_screen_area
              FROM sys_button_prop sbp
              JOIN sys_button_prop sbpparent
                ON sbp.id_btn_prp_parent = sbpparent.id_sys_button_prop
             WHERE sbp.id_sys_button_prop = i_id_button_prop;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_ACCESS_SUB_BUTT_NEW',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sub_butt);
            pk_types.open_my_cursor(o_parent);
            RETURN FALSE;
        
    END get_prof_access_sub_butt_new;

    /******************************************************************************
       OBJECTIVO: Obter os botões Parent do botão destino de um shortcut
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_PROF - profissional
             I_SHORT - ID do shortcut
            Saida:   O_ACCESS - Botões aos quais o profissional tem acesso
             O_ERROR - erro
    
      CRIAÇÃO: CRS 2006/02/21
      NOTAS:
    *********************************************************************************/
    FUNCTION get_shortcut_parent
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_parent OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_button_prop sys_button_prop.id_sys_button_prop%TYPE;
        l_parent_prop sys_button_prop.id_btn_prp_parent%TYPE;
        l_button      sys_button.id_sys_button%TYPE;
        l_loop        BOOLEAN;
        i             NUMBER := 1;
    
        CURSOR c_button
        (
            i_count               IN NUMBER,
            i_id_profile_template IN NUMBER
        ) IS
            SELECT ss.id_sys_button_prop, sb.id_btn_prp_parent, s.id_sys_button
              FROM sys_shortcut ss, sys_button_prop sb, profile_templ_access pta, sys_button s
             WHERE ss.id_sys_shortcut = i_short
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
               AND ((sb.id_sys_button_prop = ss.id_sys_button_prop AND nvl(ss.id_sys_button_prop, 0) != 0) OR
                   sb.id_sys_button_prop =
                   (SELECT id_sys_button_prop
                       FROM sys_shortcut
                      WHERE id_parent = i_short
                        AND id_software = i_prof.software
                        AND ((ss.id_institution = 0 AND (i_count = 0)) OR
                            (ss.id_institution = i_prof.institution AND (i_count > 0)))))
               AND pta.id_shortcut_pk = ss.id_shortcut_pk
               AND pta.id_profile_template =
                   (SELECT pt.id_parent
                      FROM profile_template pt
                     WHERE pt.id_profile_template = i_id_profile_template)
               AND NOT EXISTS (SELECT 0
                      FROM profile_templ_access p
                     WHERE p.id_profile_template = i_id_profile_template
                       AND p.id_sys_button_prop = sb.id_sys_button_prop
                       AND p.flg_add_remove = g_flg_type_remove)
               AND pta.flg_add_remove = g_flg_type_add
               AND s.id_sys_button = sb.id_sys_button
            UNION ALL
            SELECT ss.id_sys_button_prop, sb.id_btn_prp_parent, s.id_sys_button
              FROM sys_shortcut         ss,
                   sys_button_prop      sb,
                   profile_templ_access pta,
                   --                   prof_profile_template ppt,
                   sys_button s
             WHERE ss.id_sys_shortcut = i_short
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution) -- CRS 2006/05/18
               AND ((sb.id_sys_button_prop = ss.id_sys_button_prop AND nvl(ss.id_sys_button_prop, 0) != 0) OR
                   sb.id_sys_button_prop =
                   (SELECT id_sys_button_prop
                       FROM sys_shortcut
                      WHERE id_parent = i_short
                        AND id_software = i_prof.software
                           --AND SS.ID_INSTITUTION IN (0, I_PROF.INSTITUTION))) -- CRS 2006/05/18
                           -- CRS 2006/05/18
                        AND ((ss.id_institution = 0 AND (i_count = 0)) OR
                            (ss.id_institution = i_prof.institution AND (i_count > 0)))))
                  --AND PA.ID_SYS_SHORTCUT = SS.ID_SYS_SHORTCUT
               AND pta.id_shortcut_pk = ss.id_shortcut_pk -- CRS 2006/05/18
               AND i_id_profile_template = pta.id_profile_template
               AND pta.flg_add_remove = g_flg_type_add
               AND s.id_sys_button = sb.id_sys_button;
    
        CURSOR c_button_parent
        (
            l_prop                IN sys_button_prop.id_sys_button_prop%TYPE,
            i_id_profile_template IN NUMBER
        ) IS
            SELECT sb.id_sys_button_prop, sb.id_btn_prp_parent, s.id_sys_button
              FROM sys_button_prop sb, profile_templ_access pta, sys_button s
             WHERE sb.id_sys_button_prop = l_prop
               AND s.id_sys_button = sb.id_sys_button
               AND pta.id_sys_button_prop = sb.id_sys_button_prop
               AND pta.id_profile_template =
                   (SELECT pt.id_parent
                      FROM profile_template pt
                     WHERE pt.id_profile_template = i_id_profile_template)
               AND NOT EXISTS (SELECT 0
                      FROM profile_templ_access p
                     WHERE p.id_profile_template = i_id_profile_template
                       AND p.id_sys_button_prop = sb.id_sys_button_prop
                       AND p.flg_add_remove = g_flg_type_remove)
               AND pta.flg_add_remove = g_flg_type_add
            UNION ALL
            SELECT sb.id_sys_button_prop, sb.id_btn_prp_parent, s.id_sys_button
              FROM sys_button_prop sb, profile_templ_access pta, sys_button s
             WHERE sb.id_sys_button_prop = l_prop
               AND s.id_sys_button = sb.id_sys_button
               AND pta.id_sys_button_prop = sb.id_sys_button_prop
               AND pta.id_profile_template = i_id_profile_template
               AND pta.flg_add_remove = g_flg_type_add;
        l_count   NUMBER(24);
        r_profile profile_template%ROWTYPE;
    BEGIN
        o_parent := table_number(200);
    
        r_profile := get_profile(i_prof => i_prof);
        SELECT COUNT(1)
          INTO l_count
          FROM sys_shortcut
         WHERE id_institution = i_prof.institution
           AND id_software = i_prof.software
           AND id_parent = i_short;
    
        g_error := 'OPEN C_BUTTON';
        OPEN c_button(l_count, r_profile.id_profile_template);
        FETCH c_button
            INTO l_button_prop, l_parent_prop, l_button;
        g_found := c_button%FOUND;
        CLOSE c_button;
    
        g_error := 'GET O_PARENT(1)' || l_button;
        o_parent(i) := l_button;
        g_error := 'GET L_LOOP';
        IF g_found
           AND nvl(l_parent_prop, 0) != 0
        THEN
            l_loop := TRUE;
        END IF;
    
        WHILE l_loop
        LOOP
            g_error := 'OPEN C_BUTTON_PARENT';
            OPEN c_button_parent(l_parent_prop, r_profile.id_profile_template);
            FETCH c_button_parent
                INTO l_button_prop, l_parent_prop, l_button;
            g_found := c_button_parent%FOUND;
            CLOSE c_button_parent;
            i := i + 1;
            o_parent.extend;
            g_error := 'GET O_PARENT(' || i || ')';
            o_parent(i) := l_button;
        
            g_error := 'VALIDATE';
            IF g_found
               AND (nvl(l_parent_prop, 0) != 0)
            THEN
                l_loop := TRUE;
            ELSE
                l_loop := FALSE;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SHORTCUT_PARENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_shortcut_parent;

    /**
    * Returns first child of given button, ordered by rank
    *
    * @param i_lang                 Id da language
    * @param i_prof                 ID Professional, ID institution, ID software
    * @param i_application_area     Application area ID
    * @param i_id_button            id_sys_button_prop of given button
    *
    * @author                Rui Batista
    * @version               2.6.1
    * @since                 04-03-2011
    */
    FUNCTION get_first_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_episode   IN NUMBER,
        i_id_button IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER IS
        t_tbl t_tbl_access := t_tbl_access();
        l_prf profile_template%ROWTYPE;
    BEGIN
        g_error := 'GET CURSOR';
        l_prf   := get_profile(i_prof);
        t_tbl   := get_deepnav(i_lang, i_prof, i_patient, i_episode, i_id_button, l_prf.id_profile_template);
    
        IF t_tbl.count > 0
        THEN
            RETURN t_tbl(1).id_sys_button_prop;
        ELSE
            RETURN NULL;
        END IF;
    
    END get_first_child;

    /******************************************************************************
       OBJECTIVO: Verificar se o botão indicado tem "filhos" (deepnavs) e se o prof. tem acesso
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - profissional
                 I_APPLICATION_AREA - área aplicacional
                 I_ID_BUTTON - ID do botão q se quer verificar se tem "filhos"
              Saida:
    
      CRIAÇÃO: CRS 2005/10/13
      NOTAS:
    *********************************************************************************/
    FUNCTION exist_child
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN NUMBER,
        i_episode          IN NUMBER,
        i_application_area IN sys_application_area.id_sys_application_area%TYPE,
        i_id_button        IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN VARCHAR2 IS
    
        l_child  sys_button_prop.id_sys_button_prop%TYPE;
        l_exists VARCHAR2(1 CHAR);
    
    BEGIN
    
        --Get first child from the parent button, if exists
        l_child := get_first_child(i_lang      => i_lang,
                                   i_patient   => i_patient,
                                   i_episode   => i_episode,
                                   i_prof      => i_prof,
                                   i_id_button => i_id_button);
    
        l_exists := iif((nvl(l_child, 0) = 0), k_no, k_yes);
    
        RETURN l_exists;
    
    END exist_child;

    /******************************************************************************
       OBJECTIVO: Verificar se o botão indicado tem "pai" e se o prof. tem acesso
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_PROF - profissional
             I_APPLICATION_AREA - área aplicacional
             I_ID_BUTTON - ID do botão q se quer verificar se tem "filhos"
              Saida:
    
      CRIAÇÃO: CRS 2006/02/03
      NOTAS:
    *********************************************************************************/
    FUNCTION exist_parent(i_id_button IN sys_button_prop.id_sys_button_prop%TYPE) RETURN VARCHAR2 IS
        l_id   sys_button_prop.id_sys_button_prop%TYPE;
        l_char VARCHAR2(1 CHAR);
        tbl_id table_number;
    BEGIN
    
        g_error := 'GET CURSOR';
        SELECT sbp.id_btn_prp_parent
          BULK COLLECT
          INTO tbl_id
          FROM sys_button_prop sbp
         WHERE sbp.id_sys_button_prop = i_id_button;
    
        IF tbl_id.count > 0
        THEN
            l_id := tbl_id(1);
        END IF;
    
        l_char := iif((nvl(l_id, 0) = 0), k_yes, k_no);
    
        RETURN l_char;
    
    END exist_parent;

    FUNCTION get_id_sys_alert
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE
    ) RETURN table_number IS
        l_tbl table_number := table_number();
    BEGIN
    
        l_tbl := pk_alerts.get_id_sys_alert(i_prof => i_prof, i_id_profile => i_id_profile);
        RETURN l_tbl;
    
    END get_id_sys_alert;

    /**
    *  Set user alerts
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION set_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN department.id_department%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_alerts.set_prof_alerts(i_lang                => i_lang,
                                            i_id_prof             => i_id_prof,
                                            i_id_profile_template => i_id_profile_template,
                                            i_id_service          => i_id_service,
                                            o_error               => o_error);
    
        RETURN l_bool;
    
    END set_prof_alerts;

    /**
    *  Delete alerts from user accordingly to the profiles, software and institution been removed beeing removed.
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION del_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
        l_bool := pk_alerts.del_prof_alerts(i_lang, i_id_prof, i_id_profile_template, o_error);
    
        RETURN l_bool;
    
    END del_prof_alerts;

    FUNCTION check_has_prof_field
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN sys_functionality.intern_name_func%TYPE,
        o_val   OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        o_val   := pk_prof_utils.check_has_functionality(i_lang => i_lang, i_prof => i_prof, i_intern_name => i_field);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_HAS_PROF_FIELD',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_has_prof_field;

    /******************************************************************************
       OBJECTIVO:   Obter as funcionalidades activas de um campo às quais o profissional
              tem acesso
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_PROF - ID do profissional
                 I_FIELD - ID do campo
              Saida:   O_FUNC - Array de funcionalidades atribuídas ao profissional
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/02/24
      NOTAS:
    *********************************************************************************/
    FUNCTION get_prof_field_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_field   IN sys_field.id_sys_field%TYPE,
        o_func    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_func FOR
            SELECT sf.id_functionality, sf.intern_name_func
              FROM prof_access_field_func pa, sys_functionality sf
             WHERE pa.id_professional = i_id_prof.id
               AND pa.id_sys_field = i_field
               AND sf.id_functionality = pa.id_functionality
               AND sf.flg_available = k_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_FIELD_FUNC',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_func);
            RETURN FALSE;
    END get_prof_field_func;

    /******************************************************************************
       OBJECTIVO: Obter as funcionalidades activas a que tem acesso um prof. Mas
              esta função só retorna as funcionalidades não associadas a campos
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_PROF - ID do profissional
              Saida:   O_FUNC - Array de funcionalidades
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/03/22
      NOTAS:
    *********************************************************************************/
    FUNCTION get_prof_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_func    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'SET CURSOR';
        OPEN o_func FOR
            SELECT p.id_functionality, s.intern_name_func
              FROM prof_func p, sys_functionality s
             WHERE p.id_professional = i_id_prof.id
               AND p.id_institution = i_id_prof.institution
               AND s.id_functionality = p.id_functionality
               AND s.flg_available = g_func_available
               AND s.id_functionality NOT IN (SELECT pa.id_functionality
                                                FROM prof_access_field_func pa);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_FUNC',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_func;

    /******************************************************************************
       OBJECTIVO:   Verificar se o acesso a uma funcionalidade está atribuído ao
              profissional. Mas só verifica as funcionalidades não associadas a campos
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_PROF - ID do profissional
    
              Saida:   O_EXIST - Y / N
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/03/22
      NOTAS:
    *********************************************************************************/
    FUNCTION find_prof_func
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_func    IN prof_func.id_functionality%TYPE,
        o_exist   OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_char  VARCHAR2(1);
        l_count NUMBER(24);
    
    BEGIN
        g_error := 'GET CURSOR C_FUNC';
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_func
         WHERE id_functionality = i_func
           AND id_professional = i_id_prof.id
           AND id_institution = i_id_prof.institution
           AND id_functionality NOT IN (SELECT pa.id_functionality
                                          FROM prof_access_field_func pa);
    
        o_exist := iif(l_count > 0, k_yes, k_no);
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'FIND_PROF_FUNC',
                                              o_error    => o_error);
            RETURN FALSE;
    END find_prof_func;

    /******************************************************************************
       OBJECTIVO: Obter "as minhas salas" de um profissional
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_ID_PROF - ID do profissional
              Saida:   O_ROOM - Array de salas
                 O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/02/23
      NOTAS:
    *********************************************************************************/
    FUNCTION get_prof_room
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_room    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'SET CURSOR';
        OPEN o_room FOR
            SELECT id_room
              FROM prof_room
             WHERE id_professional = i_id_prof.id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_ROOM',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_prof_room;

    /******************************************************************************
       OBJECTIVO: Verificar se o botão indicado tem "filhos" (deepnavs) e se o prof. tem acesso
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - profissional
                 I_APPLICATION_AREA - área aplicacional
                 I_ID_BUTTON - ID do botão q se quer verificar se tem "filhos"
              Saida:
    
      CRIAÇÃO: CRS 2006/08/18
      NOTAS:
    *********************************************************************************/

    FUNCTION count_child
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_episode   IN NUMBER,
        i_id_button IN sys_button_prop.id_sys_button_prop%TYPE
    ) RETURN NUMBER IS
        l_ids t_tbl_access := t_tbl_access();
        l_prf profile_template%ROWTYPE;
    BEGIN
    
        l_prf := get_profile(i_prof);
        l_ids := get_deepnav(i_lang, i_prof, i_patient, i_episode, i_id_button, l_prf.id_profile_template);
    
        RETURN l_ids.count;
    
    END count_child;

    /**
    * Return all approaches to the software/profile that the user is authenticated.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    *
    * @param o_environment        Environment information (institution/software)
    * @param o_approaches         The approaches list
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION get_software_approaches
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_environment OUT pk_types.cursor_type,
        o_approaches  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(40 CHAR) := 'GET_SOFTWARE_APPROACHES';
    
        l_appr_code_domain      CONSTANT VARCHAR2(200 CHAR) := 'PROFILE_TEMPLATE.FLG_APPROACH';
        l_appr_code_domain_desc CONSTANT VARCHAR2(200 CHAR) := 'APPROACH';
    
        r_prf                   profile_template%ROWTYPE;
        l_prof_profile_template NUMBER(24);
    
        l_def_appr profile_template.id_profile_template%TYPE;
    BEGIN
        -- log input parameters information
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof));
    
        r_prf                   := get_profile(i_prof => i_prof);
        l_prof_profile_template := r_prf.id_profile_template;
    
        --get the default profile_template
        SELECT nvl(pt.id_profile_template_appr, pt.id_profile_template)
          INTO l_def_appr
          FROM profile_template pt
         WHERE (pt.id_profile_template = l_prof_profile_template OR
               pt.id_profile_template_appr = l_prof_profile_template)
           AND rownum <= 1;
    
        -- get the environment information
        g_error := 'GET PROF ENVIRONMENT';
        OPEN o_environment FOR
            SELECT pk_utils.get_institution_name(i_lang, i_prof.institution) institution,
                   pk_utils.get_software_name(i_lang, i_prof.software) software
              FROM dual;
    
        -- get the available approaches related to the given professional
        g_error := 'GET APPROACHES';
        OPEN o_approaches FOR
            SELECT pk_sysdomain.get_domain(l_appr_code_domain, pt.flg_approach, i_lang) appr_desc,
                   pk_sysdomain.get_domain(l_appr_code_domain_desc, pt.flg_approach, i_lang) appr_popup_desc,
                   pt.flg_approach appr_val,
                   decode(l_prof_profile_template,
                          pt.id_profile_template,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) appr_in_use,
                   pk_sysdomain.get_rank(i_lang, l_appr_code_domain, pt.flg_approach) appr_rank
              FROM profile_template pt
             WHERE (pt.id_profile_template = l_def_appr OR pt.id_profile_template_appr = l_def_appr)
               AND pt.id_software = i_prof.software
             ORDER BY appr_rank ASC;
    
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
            pk_types.open_my_cursor(o_approaches);
            pk_types.open_my_cursor(o_environment);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_software_approaches;

    /**
    *  Changes alerts from user accordingly to the profiles, software and institution.
    *
    * @param i_lang                    Language
    * @param i_id_prof                 Professional, institution, software ids.
    * @param i_id_profile_template_old Old Profile id for this user
    * @param i_id_profile_template_new New Profile id for this user
    * @param o_error                   Error message
    *
    * @return     boolean
    * @author     Paulo Teixeira
    * @version    0.1
    * @since      2010-08-17
    */
    FUNCTION change_prof_alerts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_prof                 IN profissional,
        i_id_profile_template_old IN profile_template.id_profile_template%TYPE,
        i_id_profile_template_new IN profile_template.id_profile_template%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_alerts.change_prof_alerts(i_lang                    => i_lang,
                                               i_id_prof                 => i_id_prof,
                                               i_id_profile_template_old => i_id_profile_template_old,
                                               i_id_profile_template_new => i_id_profile_template_new,
                                               o_error                   => o_error);
    
        RETURN l_bool;
    
    END change_prof_alerts;

    /**
    * Sets the approach of the authenticated professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_val_appr           The approach val to be used
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7.2
    * @since                 2009/07/31
    */
    FUNCTION set_prof_approach
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_val_appr IN profile_template.flg_approach%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_PROF_APPROACH';
    
        r_prf                   profile_template%ROWTYPE;
        l_prof_profile_template NUMBER(24);
    
        l_appr_profile_template profile_template.id_profile_template%TYPE;
        l_def_appr              profile_template.id_profile_template%TYPE;
    BEGIN
        -- log input parameters information
        pk_alertlog.log_info('i_lang: ' || i_lang || ' | i_prof: ' || pk_utils.to_string(i_prof) || ' | i_val_appr ' ||
                             i_val_appr);
    
        r_prf                   := get_profile(i_prof => i_prof);
        l_prof_profile_template := r_prf.id_profile_template;
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_prof IS NULL
           OR i_lang IS NULL
           OR i_val_appr IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        --get the default profile_template
        SELECT nvl(pt.id_profile_template_appr, pt.id_profile_template)
          INTO l_def_appr
          FROM profile_template pt
         WHERE (pt.id_profile_template = l_prof_profile_template OR
               pt.id_profile_template_appr = l_prof_profile_template)
           AND rownum <= 1;
    
        -- get the id_profile_template realated to the given approach
        g_error := 'GET APPROACH PROFILE_TEMPLATE';
        SELECT pt.id_profile_template
          INTO l_appr_profile_template
          FROM profile_template pt
         WHERE pt.id_software = i_prof.software
           AND (pt.id_profile_template = l_def_appr OR pt.id_profile_template_appr = l_def_appr)
           AND pt.flg_approach = i_val_appr;
    
        -- update the professional profile_template
        g_error := 'SET NEW PROF_PROFILE_TEMPLATE';
        IF NOT pk_prof_utils.set_prof_profile_template_nc(i_lang   => i_lang,
                                                          i_prof   => i_prof,
                                                          i_new_pt => l_appr_profile_template,
                                                          o_error  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL TO pk_access.SET_PROF_ALERTS';
        IF NOT change_prof_alerts(i_lang                    => i_lang,
                                  i_id_prof                 => i_prof,
                                  i_id_profile_template_old => l_prof_profile_template,
                                  i_id_profile_template_new => l_appr_profile_template,
                                  o_error                   => o_error)
        THEN
            RAISE g_exception;
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_utils.undo_changes;
            RETURN FALSE;
    END set_prof_approach;

    /**
    * Gets the command string for setting an action to call an external application in a sys_button_prop
    *
    * @param i_external_app       External application id
    *
    * @return                Correct command string to use on sys_button_prop
    *
    * @author                Fábio Oliveira
    * @version               2.6.0.2
    * @since                 01-Apr-2010
    */
    FUNCTION get_external_app_string(i_external_app IN NUMBER) RETURN VARCHAR2 IS
        l_command_name CONSTANT VARCHAR2(30 CHAR) := 'launchExternalApplication';
    BEGIN
        RETURN l_command_name || '(' || i_external_app || ')';
    END get_external_app_string;

    /**
    * Sets the action to call an external application in a sys_button_prop
    *
    * @param i_sys_button_prop   SYS_BUTTON_PROP id
    * @param i_external_app      External application id
    *
    * @author                Fábio Oliveira
    * @version               2.6.0.2
    * @since                 01-Apr-2010
    */

    PROCEDURE set_action_external_app
    (
        i_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_external_app    IN NUMBER
    ) IS
    BEGIN
        UPDATE sys_button_prop sbp
           SET sbp.action = get_external_app_string(i_external_app)
         WHERE sbp.id_sys_button_prop = i_sys_button_prop;
    END set_action_external_app;

    /**
    * Returns Child buttons of given buttons
    *
    * @param i_lang                 Id da language
    * @param i_id_sys_button_prop   id_sys_button_prop of given button
    * @param o_id_button_prop_child id_sys_button_prop of child button
    * @param o_id_button_child      id_sys_button of o_id_button_prop_child
    * @param o_id_screen_area       id_screen_area of o_id_button_prop_child
    * @param o_screen_name          screen_name of o_id_button_prop_child
    * @param o_error                Error token if applicable
    *
    * @author                Carlos Ferreira
    * @version               2.6.0.5
    * @since                 07-01-2011
    */

    FUNCTION get_first_child_button_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN NUMBER,
        i_episode              IN NUMBER,
        i_application_area     IN sys_application_area.id_sys_application_area%TYPE,
        i_id_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_prop_child OUT sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_child      OUT sys_button.id_sys_button%TYPE,
        o_id_screen_area       OUT sys_screen_area.id_sys_screen_area%TYPE,
        o_screen_name          OUT sys_button_prop.screen_name%TYPE,
        o_flg_screen_mode      OUT sys_button_prop.flg_screen_mode%TYPE,
        o_screen_params        OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_button_prop sys_button_prop.id_sys_button_prop%TYPE;
        r_id_sys_button_prop table_number; --sys_button_prop.id_sys_button_prop%type; --table_number_id := table_number_id();
    
        r_id_sys_button      table_number;
        r_id_sys_screen_area table_number;
        r_screen_name        table_varchar;
        r_rank               table_number;
        r_flg_screen_mode    table_varchar;
    
        l_criteria     NUMBER(6);
        l_row_selected NUMBER(6) := 0;
        l_func_name        CONSTANT VARCHAR2(0050 CHAR) := 'get_first_child_button_info';
        g_criteria_by_rank CONSTANT NUMBER(6) := 0;
        l_mode VARCHAR2(1 CHAR) := 'S';
    
        k_complete_function CONSTANT VARCHAR2(1 CHAR) := 'T';
        k_simple_function   CONSTANT VARCHAR2(1 CHAR) := 'S';
    
    BEGIN
    
        l_mode := k_simple_function;
        IF i_application_area IS NOT NULL
           AND i_prof.id IS NOT NULL
        THEN
            l_mode := k_complete_function;
        END IF;
    
        IF l_mode = k_complete_function
        THEN
            l_id_sys_button_prop := get_first_child(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_patient   => i_patient,
                                                    i_episode   => i_episode,
                                                    i_id_button => i_id_sys_button_prop);
        END IF;
    
        -- PARA JA É ZERO
        l_criteria := 0;
    
        g_error := 'GET ROWS FOR PROCESSING';
        pk_alertlog.log_debug(g_error);
        SELECT id_sys_button_prop, id_sys_button, id_sys_screen_area, screen_name, flg_screen_mode, rank
          BULK COLLECT
          INTO r_id_sys_button_prop, r_id_sys_button, r_id_sys_screen_area, r_screen_name, r_flg_screen_mode, r_rank
          FROM sys_button_prop
         WHERE (id_btn_prp_parent = i_id_sys_button_prop AND l_mode = k_simple_function)
            OR (id_sys_button_prop = l_id_sys_button_prop AND l_mode = k_complete_function)
         ORDER BY rank;
    
        g_error := 'Applying criteria:' || to_char(l_criteria);
        pk_alertlog.log_debug(g_error);
        -- Using criteria
        <<choose_criteria>>CASE l_criteria
            WHEN g_criteria_by_rank THEN
                l_row_selected := 1;
        END CASE choose_criteria;
    
        g_error := 'Applying values:' || r_id_sys_button_prop(l_row_selected);
        pk_alertlog.log_debug(g_error);
        o_id_button_prop_child := r_id_sys_button_prop(l_row_selected);
        o_id_button_child      := r_id_sys_button(l_row_selected);
        o_id_screen_area       := r_id_sys_screen_area(l_row_selected);
        o_screen_name          := r_screen_name(l_row_selected);
        o_screen_params        := get_button_prop_params(r_id_sys_button_prop(l_row_selected));
        o_flg_screen_mode      := r_flg_screen_mode(l_row_selected);
    
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_first_child_button_info;

    FUNCTION get_first_child_button_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_sys_button_prop   IN sys_button_prop.id_sys_button_prop%TYPE,
        i_patient              IN NUMBER,
        i_episode              IN NUMBER,
        o_id_button_prop_child OUT sys_button_prop.id_sys_button_prop%TYPE,
        o_id_button_child      OUT sys_button.id_sys_button%TYPE,
        o_id_screen_area       OUT sys_screen_area.id_sys_screen_area%TYPE,
        o_screen_name          OUT sys_button_prop.screen_name%TYPE,
        o_flg_screen_mode      OUT sys_button_prop.flg_screen_mode%TYPE,
        o_screen_params        OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_func_name CONSTANT VARCHAR2(0050 CHAR) := 'get_first_child_button_info';
        l_return BOOLEAN;
    BEGIN
    
        l_return := get_first_child_button_info
                    
                    (i_lang                 => i_lang,
                     i_prof                 => profissional(NULL, NULL, NULL),
                     i_patient              => i_patient,
                     i_episode              => i_episode,
                     i_application_area     => NULL,
                     i_id_sys_button_prop   => i_id_sys_button_prop,
                     o_id_button_prop_child => o_id_button_prop_child,
                     o_id_button_child      => o_id_button_child,
                     o_id_screen_area       => o_id_screen_area,
                     o_screen_name          => o_screen_name,
                     o_flg_screen_mode      => o_flg_screen_mode,
                     o_screen_params        => o_screen_params,
                     o_error                => o_error);
    
        RETURN l_return;
    
    END get_first_child_button_info;

    /**
    * Returns Child buttons of given grandparent button
    *
    * @param i_lang                 Id da language
    * @param i_prof                 ID Professional, ID institution, ID software
    * @param i_application_area     Application area ID
    * @param i_id_sys_button_prop   id_sys_button_prop of given button
    * @param o_id_button_prop_child id_sys_button_prop of child button
    * @param o_id_button_child      id_sys_button of o_id_button_prop_child
    * @param o_id_screen_area       id_screen_area of o_id_button_prop_child
    * @param o_screen_name          screen_name of o_id_button_prop_child
    * @param o_error                Error token if applicable
    *
    * @author                Carlos Ferreira
    * @version               2.6.0.5
    * @since                 10-01-2011
    */

    FUNCTION get_core_grandparent_btn_info
    (
        i_mode               IN VARCHAR2,
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN NUMBER,
        i_episode            IN NUMBER,
        i_application_area   IN sys_application_area.id_sys_application_area%TYPE,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_sql                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_level     CONSTANT NUMBER(1) := 3;
        l_func_name CONSTANT VARCHAR2(0050 CHAR) := 'get_core_grandparent_btn_info';
    
        l_id_sys_button_prop_g sys_button_prop.id_sys_button_prop%TYPE;
        l_id_sys_screen_area_g sys_screen_area.id_sys_screen_area%TYPE;
        l_screen_name_g        sys_button_prop.screen_name%TYPE;
        l_id_button_prop_child sys_button_prop.id_sys_button_prop%TYPE;
        l_id_button_child      sys_button.id_sys_button%TYPE;
        l_id_screen_area       sys_screen_area.id_sys_screen_area%TYPE;
        l_screen_name          sys_button_prop.screen_name%TYPE;
        l_flg_screen_mode      sys_button_prop.flg_screen_mode%TYPE;
        l_screen_params        table_varchar;
        l_ret                  BOOLEAN;
    
        CURSOR c_get_gfather IS
            SELECT sbp.id_sys_button_prop, sbp.id_sys_screen_area, sbp.screen_name
              FROM sys_button_prop sbp
             WHERE id_sys_button_prop IN (SELECT id_sys_button_prop
                                            FROM (SELECT id_sys_button_prop, LEVEL xlevel
                                                    FROM sys_button_prop
                                                  CONNECT BY PRIOR id_btn_prp_parent = id_sys_button_prop
                                                   START WITH id_sys_button_prop = i_id_sys_button_prop) xrows
                                           WHERE xlevel = l_level);
    
    BEGIN
    
        g_error := 'Selecting values:' || to_char(i_id_sys_button_prop);
        pk_alertlog.log_debug(g_error);
        OPEN c_get_gfather;
    
        FETCH c_get_gfather
            INTO l_id_sys_button_prop_g, l_id_sys_screen_area_g, l_screen_name_g;
        CLOSE c_get_gfather;
    
        --if l_id_sys_button_prop_g is not null  then
        IF l_id_sys_button_prop_g IS NOT NULL
        THEN
        
            g_error := 'Executing get_first_child_button_info:' || to_char(l_id_sys_button_prop_g);
            pk_alertlog.log_debug(g_error);
        
            CASE (i_mode)
                WHEN k_full_mode THEN
                
                    l_ret := get_first_child_button_info(i_lang,
                                                         i_prof,
                                                         i_patient,
                                                         i_episode,
                                                         i_application_area,
                                                         l_id_sys_button_prop_g,
                                                         l_id_button_prop_child,
                                                         l_id_button_child,
                                                         l_id_screen_area,
                                                         l_screen_name,
                                                         l_flg_screen_mode,
                                                         l_screen_params,
                                                         o_error);
                
                WHEN k_short_mode THEN
                    l_ret := get_first_child_button_info(i_lang,
                                                         i_patient,
                                                         i_episode,
                                                         l_id_sys_button_prop_g,
                                                         l_id_button_prop_child,
                                                         l_id_button_child,
                                                         l_id_screen_area,
                                                         l_screen_name,
                                                         l_flg_screen_mode,
                                                         l_screen_params,
                                                         o_error);
            END CASE;
        
            IF l_ret = FALSE
            THEN
                RETURN FALSE;
            END IF;
        
            -- changing context to transform into cursor
            g_error := 'Getting child to select:' || to_char(l_id_button_prop_child);
            pk_alertlog.log_debug(g_error);
            OPEN o_sql FOR
                SELECT l_id_sys_button_prop_g gfather_id_sys_button_prop,
                       l_id_sys_screen_area_g gfather_id_sys_screen_area,
                       l_screen_name_g        gfather_screen_name,
                       l_id_button_prop_child child_id_sys_button_prop,
                       l_id_button_child      child_id_sys_button,
                       l_id_screen_area       child_id_sys_screen_area,
                       l_screen_name          child_screen_name,
                       l_flg_screen_mode      flg_screen_mode,
                       l_screen_params        screen_params
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_sql);
        END IF;
    
        g_error := 'Execution of get_grandparent_button_info successfull';
        pk_alertlog.log_debug(g_error);
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
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sql);
        
            RETURN FALSE;
        
    END get_core_grandparent_btn_info;

    /**
    * Returns Child buttons of given grandparent button
    *
    * @param i_lang                 Id da language
    * @param i_id_sys_button_prop   id_sys_button_prop of given button
    * @param o_id_button_prop_child id_sys_button_prop of child button
    * @param o_id_button_child      id_sys_button of o_id_button_prop_child
    * @param o_id_screen_area       id_screen_area of o_id_button_prop_child
    * @param o_screen_name          screen_name of o_id_button_prop_child
    * @param o_error                Error token if applicable
    *
    * @author                Carlos Ferreira
    * @version               2.6.0.5
    * @since                 10-01-2011
    */
    FUNCTION get_grandparent_button_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN NUMBER,
        i_episode            IN NUMBER,
        i_application_area   IN sys_application_area.id_sys_application_area%TYPE,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_sql                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    
    BEGIN
        l_return := get_core_grandparent_btn_info(k_full_mode,
                                                  i_lang,
                                                  i_prof,
                                                  i_patient,
                                                  i_episode,
                                                  i_application_area,
                                                  i_id_sys_button_prop,
                                                  o_sql,
                                                  o_error);
    
        RETURN l_return;
    
    END get_grandparent_button_info;

    FUNCTION get_grandparent_button_info
    (
        i_lang               IN language.id_language%TYPE,
        i_patient            IN NUMBER,
        i_episode            IN NUMBER,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        o_sql                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return BOOLEAN;
    BEGIN
        l_return := get_core_grandparent_btn_info(k_short_mode,
                                                  i_lang,
                                                  profissional(0, 0, 0),
                                                  i_patient,
                                                  i_episode,
                                                  NULL,
                                                  i_id_sys_button_prop,
                                                  o_sql,
                                                  o_error);
        RETURN l_return;
    END get_grandparent_button_info;

    /**
    * Return true with successfull execution, false in case of error.
    *
    * @param i_lang     Id da language
    * @param i_prof     structure with id_professional, id_institution, id_software
    * @param i_short    id_sys_shortcut to process
    * @param o_access   cursor  with sys_button_prop information associated
    *                   with given shortcut. returns one row or nothing.
    * @param o_prt      cursor tha returns two rows:
                        deepnav id_sys_button and toolbar id_sys_button
                        ( sys_creen_area 5 and 3, in this order ).
    * @param o_error    Error token if applicable
    *
    * @author                Carlos Ferreira
    * @version               2.6.3.3
    * @since                 08-02-2013
    */
    FUNCTION get_shortcut
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_short   IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access  OUT c_shortcut,
        o_prt     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_SHORTCUT';
        l_found BOOLEAN;
        l_flag  NUMBER(24);
    
        l_prf       profile_template%ROWTYPE;
        t_sht       t_shortcut;
        tbl_profile table_number := table_number();
    
        CURSOR c_access
        (
            i_id_profile_template IN NUMBER,
            i_tbl_profile         IN table_number,
            i_pat_age             IN NUMBER,
            i_pat_gender          IN VARCHAR2,
            i_epis_type           IN NUMBER
        ) IS
            SELECT xmain.id_sys_application_area,
                   xmain.btn_dest,
                   xmain.screen_name,
                   xmain.screen_area,
                   xmain.flg_area,
                   xmain.deepnav_id_sys_button_prop,
                   xmain.btn_label,
                   xmain.son_intern_name,
                   xmain.btn_parent,
                   xmain.btn_prop_parent,
                   xmain.screen_area_parent,
                   xmain.par_intern_name,
                   xmain.id_sys_button_prop,
                   xmain.exist_child,
                   xmain.action,
                   xmain.msg_copyright,
                   xmain.flg_screen_mode,
                   xmain.screen_params
              FROM (SELECT decode(pta.id_profile_template, i_id_profile_template, 0, 99999) pta_rank,
                           pta.id_profile_template,
                           pta.id_sys_shortcut,
                           --dense_rank() over(PARTITION BY sst_id_sys_shortcut ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank,
                           dense_rank() over(PARTITION BY pta.id_sys_shortcut ORDER BY coalesce(pta.age_min, k_low_limit) DESC, coalesce(pta.gender, k_min_char) DESC, coalesce(pta.id_epis_type, k_low_limit) DESC) my_rank,
                           
                           xsql.*,
                           pta.age_min,
                           pta.id_epis_type,
                           pta.gender
                      FROM (SELECT btn.id_sys_application_area id_sys_application_area,
                                   btn.id_sys_button btn_dest,
                                   btn.screen_name screen_name,
                                   btn.id_sys_screen_area screen_area,
                                   saa.flg_area flg_area,
                                   sst.id_sys_button_prop deepnav_id_sys_button_prop,
                                   sst.id_sys_shortcut sst_id_sys_shortcut,
                                   pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => but.code_button) btn_label,
                                   but.intern_name_button son_intern_name,
                                   bt2.id_sys_button btn_parent,
                                   btn.id_btn_prp_parent btn_prop_parent,
                                   bt2.id_sys_screen_area screen_area_parent,
                                   bu2.intern_name_button par_intern_name,
                                   btn.id_btn_prp_parent id_sys_button_prop,
                                   pk_access.exist_child(i_lang,
                                                         i_prof,
                                                         i_patient,
                                                         i_episode,
                                                         btn.id_sys_application_area,
                                                         btn.id_sys_button_prop) exist_child,
                                   btn.action action,
                                   (SELECT pk_message.get_message(i_lang, i_prof, btn.code_msg_copyright)
                                      FROM dual) msg_copyright,
                                   btn.flg_screen_mode flg_screen_mode,
                                   pk_access.get_button_prop_params(sst.id_sys_button_prop) screen_params
                              FROM sys_shortcut sst
                              JOIN sys_button_prop btn
                                ON btn.id_sys_button_prop = sst.id_sys_button_prop
                              LEFT JOIN sys_button_prop bt2
                                ON bt2.id_sys_button_prop = btn.id_btn_prp_parent
                              JOIN sys_application_area saa
                                ON btn.id_sys_application_area = saa.id_sys_application_area
                              JOIN sys_button but
                                ON btn.id_sys_button = but.id_sys_button
                              LEFT JOIN sys_button bu2
                                ON bt2.id_sys_button = bu2.id_sys_button
                             WHERE ((sst.id_sys_shortcut = i_short) OR (sst.id_parent = i_short))
                               AND sst.id_software = i_prof.software
                               AND (sst.id_sys_button_prop, sst.id_shortcut_pk) IN
                                   (SELECT /*+ opt_estimate(table btn1 rows=1) */
                                     btn1.id_sys_button_prop, btn1.id_shortcut_pk
                                      FROM TABLE(pk_access.get_agg_access(i_prof,
                                                                          i_patient,
                                                                          i_episode,
                                                                          btn.id_sys_button_prop,
                                                                          i_id_profile_template,
                                                                          k_no)) btn1 --9721
                                     WHERE btn1.my_rank = k_first_row
                                       AND btn1.flg_add_remove = g_flg_type_add)) xsql
                      JOIN profile_templ_access pta
                        ON pta.id_sys_button_prop = xsql.deepnav_id_sys_button_prop
                       AND pta.id_profile_template IN (SELECT column_value
                                                         FROM TABLE(i_tbl_profile))
                     WHERE 0 = 0
                       AND coalesce(pta.age_min, k_low_limit) <= i_pat_age
                       AND coalesce(pta.id_epis_type, k_low_limit) IN (i_epis_type, k_low_limit)
                       AND coalesce(pta.gender, k_min_char) IN (i_pat_gender, k_min_char)) xmain
             WHERE xmain.my_rank = 1
             ORDER BY pta_rank, deepnav_id_sys_button_prop;
    
        l_pat_age    NUMBER;
        l_pat_gender VARCHAR2(0010 CHAR);
        l_epis_type  NUMBER;
    
    BEGIN
    
        l_pat_age    := get_pat_age(i_patient);
        l_pat_gender := get_pat_gender(i_patient);
        l_epis_type  := get_epis_type(i_episode);
    
        l_pat_age := coalesce(l_pat_age, k_low_limit);
    
        l_prf       := get_profile(i_prof => i_prof);
        tbl_profile := get_profile_template_tree(i_prof, l_prf.id_profile_template);
    
        --OPEN c_access(l_prf.id_profile_template, tbl_profile, l_pat_age, l_pat_gender, l_epis_type);
        OPEN c_access(l_prf.id_profile_template, tbl_profile, l_pat_age, l_pat_gender, l_epis_type);
        FETCH c_access
            INTO t_sht.id_sys_application_area,
                 t_sht.btn_dest,
                 t_sht.screen_name,
                 t_sht.screen_area,
                 t_sht.flg_area,
                 t_sht.deepnav_id_sys_button_prop,
                 t_sht.btn_label,
                 t_sht.son_intern_name,
                 t_sht.btn_parent,
                 t_sht.btn_prop_parent,
                 t_sht.screen_area_parent,
                 t_sht.par_intern_name,
                 t_sht.id_sys_button_prop,
                 t_sht.exist_child,
                 t_sht.action,
                 t_sht.msg_copyright,
                 t_sht.flg_screen_mode,
                 t_sht.screen_params;
        l_found := c_access%FOUND;
        CLOSE c_access;
    
        l_flag := iif(l_found, k_true, k_false);
    
        g_error := 'Transform Array to Cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_prt FOR
            SELECT *
              FROM (SELECT id_sys_button id_parent, id_sys_screen_area
                      FROM sys_button_prop
                     WHERE id_sys_screen_area IN (k_toolbar_area, k_toolbar_area_right, k_toolbar_search)
                     START WITH id_sys_button_prop = t_sht.deepnav_id_sys_button_prop
                    CONNECT BY PRIOR id_btn_prp_parent = id_sys_button_prop
                    UNION ALL
                    SELECT t_sht.btn_dest id_parent, t_sht.screen_area
                      FROM dual)
             ORDER BY id_sys_screen_area DESC;
    
        g_error := 'GET o_access';
        pk_alertlog.log_debug(g_error);
        OPEN o_access FOR
            SELECT t_sht.id_sys_application_area id_sys_application_area,
                   t_sht.btn_dest btn_dest,
                   t_sht.screen_name screen_name,
                   t_sht.flg_area flg_area,
                   t_sht.deepnav_id_sys_button_prop deepnav_id_sys_button_prop,
                   t_sht.btn_label btn_label,
                   t_sht.son_intern_name son_intern_name,
                   t_sht.btn_parent btn_parent,
                   t_sht.btn_prop_parent btn_prop_parent,
                   t_sht.screen_area screen_area,
                   t_sht.screen_area_parent screen_area_parent,
                   t_sht.par_intern_name par_intern_name,
                   t_sht.id_sys_button_prop id_sys_button_prop,
                   t_sht.exist_child exist_child,
                   pk_access.get_string_action(t_sht.action) action,
                   t_sht.msg_copyright msg_copyright,
                   t_sht.flg_screen_mode flg_screen_mode,
                   t_sht.screen_params screen_params
              FROM dual
             WHERE k_true = l_flag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            open_my_cursor(o_access);
            pk_types.open_my_cursor(o_prt);
            RETURN FALSE;
        
    END get_shortcut;

    FUNCTION get_shortcut
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access OUT c_shortcut,
        o_prt    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_shortcut(i_lang    => i_lang,
                            i_prof    => i_prof,
                            i_patient => NULL,
                            i_episode => NULL,
                            i_short   => i_short,
                            o_access  => o_access,
                            o_prt     => o_prt,
                            o_error   => o_error);
    
    END get_shortcut;

    FUNCTION get_shortcutx
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_short  IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access OUT c_shortcut,
        o_prt    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_SHORTCUT';
        l_found BOOLEAN;
        l_flag  NUMBER(24);
    
        l_prf       profile_template%ROWTYPE;
        t_sht       t_shortcut;
        tbl_profile table_number := table_number();
    
        CURSOR c_access
        (
            i_id_profile_template IN NUMBER,
            i_tbl_profile         IN table_number
        ) IS
            SELECT xmain.id_sys_application_area,
                   xmain.btn_dest,
                   xmain.screen_name,
                   xmain.screen_area,
                   xmain.flg_area,
                   xmain.deepnav_id_sys_button_prop,
                   xmain.btn_label,
                   xmain.son_intern_name,
                   xmain.btn_parent,
                   xmain.btn_prop_parent,
                   xmain.screen_area_parent,
                   xmain.par_intern_name,
                   xmain.id_sys_button_prop,
                   xmain.exist_child,
                   xmain.action,
                   xmain.msg_copyright,
                   xmain.flg_screen_mode,
                   xmain.screen_params
              FROM (SELECT decode(pta.id_profile_template, i_id_profile_template, 0, 99999) pta_rank,
                           pta.id_profile_template,
                           xsql.*
                      FROM (SELECT btn.id_sys_application_area id_sys_application_area,
                                   btn.id_sys_button btn_dest,
                                   btn.screen_name screen_name,
                                   btn.id_sys_screen_area screen_area,
                                   saa.flg_area flg_area,
                                   sst.id_sys_button_prop deepnav_id_sys_button_prop,
                                   pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => but.code_button) btn_label,
                                   but.intern_name_button son_intern_name,
                                   bt2.id_sys_button btn_parent,
                                   btn.id_btn_prp_parent btn_prop_parent,
                                   bt2.id_sys_screen_area screen_area_parent,
                                   bu2.intern_name_button par_intern_name,
                                   btn.id_btn_prp_parent id_sys_button_prop,
                                   pk_access.exist_child(i_lang,
                                                         i_prof,
                                                         NULL,
                                                         NULL,
                                                         btn.id_sys_application_area,
                                                         btn.id_sys_button_prop) exist_child,
                                   btn.action action,
                                   (SELECT pk_message.get_message(i_lang, i_prof, btn.code_msg_copyright)
                                      FROM dual) msg_copyright,
                                   btn.flg_screen_mode flg_screen_mode,
                                   pk_access.get_button_prop_params(sst.id_sys_button_prop) screen_params
                              FROM sys_shortcut sst
                              JOIN sys_button_prop btn
                                ON btn.id_sys_button_prop = sst.id_sys_button_prop
                              LEFT JOIN sys_button_prop bt2
                                ON bt2.id_sys_button_prop = btn.id_btn_prp_parent
                              JOIN sys_application_area saa
                                ON btn.id_sys_application_area = saa.id_sys_application_area
                              JOIN sys_button but
                                ON btn.id_sys_button = but.id_sys_button
                              LEFT JOIN sys_button bu2
                                ON bt2.id_sys_button = bu2.id_sys_button
                             WHERE ((sst.id_sys_shortcut = i_short) OR (sst.id_parent = i_short))
                               AND sst.id_software = i_prof.software
                               AND (sst.id_sys_button_prop, sst.id_shortcut_pk) IN
                                   (SELECT /*+ opt_estimate(table btn1 rows=1) */
                                     btn1.id_sys_button_prop, btn1.id_shortcut_pk
                                      FROM TABLE(pk_access.get_agg_access(i_prof,
                                                                          NULL,
                                                                          NULL,
                                                                          btn.id_sys_button_prop,
                                                                          i_id_profile_template,
                                                                          k_no)) btn1 --9721
                                     WHERE btn1.my_rank = k_first_row
                                       AND btn1.flg_add_remove = g_flg_type_add)) xsql
                      JOIN profile_templ_access pta
                        ON pta.id_sys_button_prop = xsql.deepnav_id_sys_button_prop
                       AND pta.id_profile_template IN (SELECT column_value
                                                         FROM TABLE(i_tbl_profile))) xmain
             ORDER BY pta_rank, deepnav_id_sys_button_prop;
    
    BEGIN
    
        g_error := 'OPEN c_profile_template';
    
        l_prf       := get_profile(i_prof => i_prof);
        tbl_profile := get_profile_template_tree(i_prof, l_prf.id_profile_template);
    
        OPEN c_access(l_prf.id_profile_template, tbl_profile);
        FETCH c_access
            INTO t_sht.id_sys_application_area,
                 t_sht.btn_dest,
                 t_sht.screen_name,
                 t_sht.screen_area,
                 t_sht.flg_area,
                 t_sht.deepnav_id_sys_button_prop,
                 t_sht.btn_label,
                 t_sht.son_intern_name,
                 t_sht.btn_parent,
                 t_sht.btn_prop_parent,
                 t_sht.screen_area_parent,
                 t_sht.par_intern_name,
                 t_sht.id_sys_button_prop,
                 t_sht.exist_child,
                 t_sht.action,
                 t_sht.msg_copyright,
                 t_sht.flg_screen_mode,
                 t_sht.screen_params;
        l_found := c_access%FOUND;
        CLOSE c_access;
    
        l_flag := iif(l_found, k_true, k_false);
    
        g_error := 'Transform Array to Cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_prt FOR
            SELECT *
              FROM (SELECT id_sys_button id_parent, id_sys_screen_area
                      FROM sys_button_prop
                     WHERE id_sys_screen_area IN (k_toolbar_area, k_toolbar_area_right, k_toolbar_search)
                     START WITH id_sys_button_prop = t_sht.deepnav_id_sys_button_prop
                    CONNECT BY PRIOR id_btn_prp_parent = id_sys_button_prop
                    UNION ALL
                    SELECT t_sht.btn_dest id_parent, t_sht.screen_area
                      FROM dual)
             ORDER BY id_sys_screen_area DESC;
    
        g_error := 'GET o_access';
        pk_alertlog.log_debug(g_error);
        OPEN o_access FOR
            SELECT t_sht.id_sys_application_area id_sys_application_area,
                   t_sht.btn_dest btn_dest,
                   t_sht.screen_name screen_name,
                   t_sht.flg_area flg_area,
                   t_sht.deepnav_id_sys_button_prop deepnav_id_sys_button_prop,
                   t_sht.btn_label btn_label,
                   t_sht.son_intern_name son_intern_name,
                   t_sht.btn_parent btn_parent,
                   t_sht.btn_prop_parent btn_prop_parent,
                   t_sht.screen_area screen_area,
                   t_sht.screen_area_parent screen_area_parent,
                   t_sht.par_intern_name par_intern_name,
                   t_sht.id_sys_button_prop id_sys_button_prop,
                   t_sht.exist_child exist_child,
                   t_sht.action                     action,
                   t_sht.msg_copyright msg_copyright,
                   t_sht.flg_screen_mode flg_screen_mode,
                   t_sht.screen_params screen_params
              FROM dual
             WHERE k_true = l_flag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            open_my_cursor(o_access);
            pk_types.open_my_cursor(o_prt);
            RETURN FALSE;
        
    END get_shortcutx;

    FUNCTION get_screen_name_by_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_short       IN sys_shortcut.id_sys_shortcut%TYPE,
        o_screen_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_SCREEN_NAME_BY_SHORTCUT';
        l_profile_template profile_template.id_profile_template%TYPE;
        r_prf              profile_template%ROWTYPE;
    BEGIN
        g_error            := 'OPEN c_profile_template';
        r_prf              := get_profile(i_prof => i_prof);
        l_profile_template := r_prf.id_profile_template;
    
        g_error := 'GET o_access';
        SELECT screen_name
          INTO o_screen_name
          FROM (SELECT sbp1.screen_name
                  FROM sys_button_prop sbp1
                  JOIN sys_application_area saa
                    ON saa.id_sys_application_area = sbp1.id_sys_application_area
                  JOIN sys_button sb
                    ON sb.id_sys_button = sbp1.id_sys_button
                  JOIN (SELECT sb.id_sys_application_area, ss.id_sys_button_prop, sb.id_btn_prp_parent, ss.id_institution
                         FROM sys_shortcut ss
                         JOIN sys_button_prop sb
                           ON sb.id_sys_button_prop = ss.id_sys_button_prop
                        WHERE ((ss.id_sys_shortcut = i_short AND nvl(ss.id_sys_button_prop, 0) != 0) OR
                              ss.id_parent = i_short)
                          AND ss.id_software = i_prof.software
                          AND ss.id_institution IN (0, i_prof.institution)
                          AND EXISTS (SELECT 0
                                 FROM profile_templ_access pta
                                WHERE pta.flg_add_remove = g_flg_type_add
                                  AND pta.id_profile_template =
                                      (SELECT pt.id_parent
                                         FROM profile_template pt
                                        WHERE pt.id_profile_template = l_profile_template)
                                  AND NOT EXISTS (SELECT 0
                                         FROM profile_templ_access p
                                        WHERE p.id_profile_template = l_profile_template
                                          AND p.id_sys_button_prop = sb.id_sys_button_prop
                                          AND p.flg_add_remove = g_flg_type_remove)
                                  AND pta.id_shortcut_pk = ss.id_shortcut_pk -- CRS 2006/05/18
                                  AND pta.id_sys_button_prop = sb.id_sys_button_prop
                               UNION ALL
                               SELECT 0
                                 FROM profile_templ_access pta
                                WHERE pta.flg_add_remove = g_flg_type_add
                                  AND pta.id_profile_template = l_profile_template
                                     -- LG 2007-03-12, APENAS RETORNA SHORTCUTS PARA OS QUAIS TEM ACESSO AO BOTÃO
                                  AND pta.id_shortcut_pk = ss.id_shortcut_pk -- CRS 2006/05/18
                                  AND pta.id_sys_button_prop = sb.id_sys_button_prop)) aux
                    ON sbp1.id_sys_button_prop = aux.id_sys_button_prop
                  LEFT JOIN sys_button_prop sbp2
                    ON sbp2.id_sys_button_prop = aux.id_btn_prp_parent
                 WHERE NOT EXISTS (SELECT 1
                          FROM profile_templ_access_exception ptae
                         WHERE ptae.id_profile_template = l_profile_template
                           AND ptae.id_sys_button_prop = sbp1.id_sys_button_prop
                           AND ptae.flg_type = g_flg_type_remove
                           AND ptae.id_software IN (i_prof.software, 0)
                           AND ptae.id_institution IN (i_prof.institution, 0))
                
                -- EXCEPTIONS
                UNION ALL
                SELECT sbp1.screen_name
                  FROM sys_button_prop sbp1
                  JOIN sys_application_area saa
                    ON saa.id_sys_application_area = sbp1.id_sys_application_area
                  JOIN sys_button sb
                    ON sb.id_sys_button = sbp1.id_sys_button
                  JOIN (SELECT sb.id_sys_application_area, ss.id_sys_button_prop, sb.id_btn_prp_parent, ss.id_institution
                         FROM sys_shortcut ss
                         JOIN sys_button_prop sb
                           ON sb.id_sys_button_prop = ss.id_sys_button_prop
                        WHERE ((ss.id_sys_shortcut = i_short AND nvl(ss.id_sys_button_prop, 0) != 0) OR
                              ss.id_parent = i_short)
                          AND ss.id_software = i_prof.software
                          AND ss.id_institution IN (0, i_prof.institution)
                          AND EXISTS (SELECT 0
                                 FROM profile_templ_access_exception pta
                                WHERE pta.flg_type = g_flg_type_add
                                  AND pta.id_profile_template = l_profile_template
                                  AND pta.id_software IN (i_prof.software, 0)
                                  AND pta.id_institution IN (i_prof.institution, 0)
                                  AND pta.id_shortcut_pk = ss.id_shortcut_pk
                                  AND pta.id_sys_button_prop = sb.id_sys_button_prop)) aux
                    ON sbp1.id_sys_button_prop = aux.id_sys_button_prop
                  LEFT JOIN sys_button_prop sbp2
                    ON sbp2.id_sys_button_prop = aux.id_btn_prp_parent);
    
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_screen_name_by_shortcut;

    FUNCTION get_button_prop_params(i_id_sys_button_prop sys_button_prop.id_sys_button_prop%TYPE) RETURN table_varchar IS
        l_params table_varchar := table_varchar();
    BEGIN
        g_error := 'CALL GET_BUTTON_PROP_PARAMS';
    
        SELECT sbpp.param_name || '|' || sbpp.param_value
          BULK COLLECT
          INTO l_params
          FROM sys_button_prop_param sbpp
         WHERE id_sys_button_prop = i_id_sys_button_prop;
    
        RETURN l_params;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_button_prop_params;

    /********************************************************************************************
    * GET_ID_SHORTCUT                  Gets the shortcut associated to the given intern_name
    *
    * @param i_lang                    language associated to the professional executing the request
    * @param i_prof                    professional, software and institution ids
    * @param i_intern_name             Shortcut internal name
    * @param i_flg_validate_parent     Y-returns only the shortcuts with id_parent = null. N-do not validate the id_parent
    * @param o_id_shortcut             Shortcut id
    * @param o_error                   Error message
    *
    * @return                          true or false on success or error
    *
    * @author                          Sofia Mendes
    * @version                         2.5.1.4
    * @since                           25-Mar-2011
    *
    **********************************************************************************************/
    FUNCTION get_id_shortcut
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_intern_name         IN sys_shortcut.intern_name%TYPE,
        i_flg_validate_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_id_shortcut         OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_short_transfer(i_intern_name sys_shortcut.intern_name%TYPE) IS
            SELECT a.id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = i_intern_name
               AND a.id_software = i_prof.software
               AND ((a.id_parent IS NULL AND i_flg_validate_parent = pk_alert_constant.g_yes) OR
                   (i_flg_validate_parent = pk_alert_constant.g_no))
               AND a.id_institution IN (i_prof.institution, 0)
             ORDER BY id_institution DESC;
    
        l_error t_error_out;
    BEGIN
        g_error := 'OPEN CURSOR c_short_transfer. i_intern_name: ' || i_intern_name;
        pk_alertlog.log_debug(g_error);
        OPEN c_short_transfer(i_intern_name);
        FETCH c_short_transfer
            INTO o_id_shortcut;
        CLOSE c_short_transfer;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_SHORTCUT',
                                              l_error);
            RETURN FALSE;
    END get_id_shortcut;

    /********************************************************************************************
    * set_button_text                  sets text/title for a sys_button_prop. REturned on
    *                                  function get_prof_access_new on cursor o_access.button_text .
    * @param i_lang                    language associated to the professional executing the request
    * @param i_id_sys_button_prop      id of sys_button_prop to configure
    * @param i_text                    text associated with given sys_button_prop
    *
    * @author                          Carlos Ferreira
    * @version                         2.6.2.1.7
    * @since                           12-09-2012
    *
    **********************************************************************************************/
    PROCEDURE set_button_text
    (
        i_lang               IN NUMBER,
        i_id_sys_button_prop IN NUMBER,
        i_text               IN VARCHAR2
    ) IS
    
        k_code_nomenclature CONSTANT VARCHAR2(0100 CHAR) := 'SYS_BUTTON_PROP.CODE_BUTTON_TEXT.';
        l_code VARCHAR2(100 CHAR);
    BEGIN
    
        l_code := k_code_nomenclature || TRIM(to_char(i_id_sys_button_prop));
    
        pk_message.insert_into_sys_message(i_lang         => i_lang,
                                           i_code_message => l_code,
                                           i_desc_message => i_text,
                                           i_flg_type     => 'T');
    
    END set_button_text;

    FUNCTION get_deepnav
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_patient             IN NUMBER,
        i_episode             IN NUMBER,
        i_id_button_prop      IN NUMBER,
        l_id_profile_template IN NUMBER
    ) RETURN t_tbl_access IS
        k_first_row CONSTANT NUMBER(1) := 1;
        t_tbl t_tbl_access;
    BEGIN
    
        SELECT t_rec_access(data_origin,
                            id_profile_template,
                            flg_add_remove,
                            id_sys_button,
                            id_sys_button_prop,
                            code_icon,
                            code_button,
                            skin,
                            intern_name_button,
                            id_sys_screen_area,
                            back_color,
                            border_color,
                            alpha,
                            screen_name,
                            action,
                            rank,
                            sub_rank,
                            flg_screen_mode,
                            code_tooltip_title,
                            code_tooltip_desc,
                            code_msg_copyright,
                            flg_reset_context,
                            id_software_context,
                            id_sys_shortcut,
                            id_software,
                            id_shortcut_pk,
                            flg_cancel,
                            flg_content,
                            flg_create,
                            flg_detail,
                            flg_digital,
                            flg_freq,
                            flg_graph,
                            flg_help,
                            flg_no,
                            flg_ok,
                            flg_print,
                            flg_search,
                            flg_vision,
                            flg_action,
                            rank2,
                            flg_view,
                            flg_global_shortcut,
                            flg_info_button,
                            pta_position,
                            sbp_position,
                            pta_toolbar_level,
                            sbp_toolbar_level,
                            sbp_flg_visible,
                            sbp_flg_type,
                            sbp_flg_enabled,
                            code_button_text,
                            sb_tooltip_title,
                            sb_tooltip_desc,
                            my_rank,
                            id_profile_templ_access,
                            age_min,
                            age_max,
                            flg_gender,
                            id_epis_type)
          BULK COLLECT
          INTO t_tbl
          FROM TABLE(pk_access.get_agg_access(i_prof, i_patient, i_episode, i_id_button_prop, l_id_profile_template))
         WHERE my_rank = k_first_row
           AND flg_add_remove = g_flg_type_add
         ORDER BY rank2, rank, sub_rank;
    
        RETURN t_tbl;
    
    END get_deepnav;

    FUNCTION verify_shortcut
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN NUMBER,
        i_episode  IN NUMBER,
        i_shortcut sys_shortcut.id_sys_shortcut%TYPE
    ) RETURN NUMBER IS
        l_cnt NUMBER := 0;
        l_prf profile_template%ROWTYPE;
    BEGIN
        l_prf := pk_access.get_profile(i_prof => i_prof);
    
        SELECT COUNT(*)
          INTO l_cnt
          FROM sys_shortcut sst
          JOIN sys_button_prop btn2
            ON btn2.id_sys_button_prop = sst.id_sys_button_prop
         WHERE ((sst.id_sys_shortcut = i_shortcut) OR (sst.id_parent = i_shortcut))
           AND sst.id_software = i_prof.software
           AND (sst.id_sys_button_prop, sst.id_shortcut_pk) IN (SELECT btn.id_sys_button_prop, btn.id_shortcut_pk
                                                                  FROM TABLE(pk_access.get_agg_access(i_prof,
                                                                                                      i_patient,
                                                                                                      i_episode,
                                                                                                      btn2.id_sys_button_prop,
                                                                                                      l_prf.id_profile_template,
                                                                                                      k_no)) btn --9721
                                                                );
    
        RETURN l_cnt;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END verify_shortcut;
    /********************************************************************************************
    * Get all alert id by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_serv_sys_alert
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN table_number IS
        ret_tbl table_number := table_number();
    BEGIN
    
        ret_tbl := pk_alerts.get_serv_sys_alert(i_id_prof             => i_id_prof,
                                                i_id_profile_template => i_id_profile_template,
                                                i_service             => i_service);
    
        RETURN ret_tbl;
    
    END get_serv_sys_alert;

    /********************************************************************************************
    * Get all No alerts configuration flg by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    * @param i_service                Service ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_no_alert_validation
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN VARCHAR2 IS
        l_no_alert VARCHAR2(1);
    BEGIN
    
        l_no_alert := pk_alerts.get_no_alert_validation(i_id_prof             => i_id_prof,
                                                        i_id_profile_template => i_id_profile_template,
                                                        i_service             => i_service);
    
        RETURN l_no_alert;
    
    END get_no_alert_validation;

    FUNCTION chk_sbp_shortcut
    (
        i_id_profile_template IN NUMBER,
        i_id_sys_button_prop  IN NUMBER,
        i_id_sys_shortcut     IN NUMBER,
        i_id_shortcut_pk      IN NUMBER,
        i_id_software         IN NUMBER
    ) RETURN VARCHAR2 DETERMINISTIC IS
        l_count NUMBER(24);
        l_bool  BOOLEAN;
        k_err_b_chk_if_shortcut_exist CONSTANT VARCHAR2(1000 CHAR) := 'ID_SYS_SHORTCUT/ID_SHORTCUT_PK:BAD MATCH';
        k_err_b_chk_shortcut_data     CONSTANT VARCHAR2(1000 CHAR) := 'ID_SYS_BUTTON_PROP/ID_SHORTCUT_PK:BAD MATCH';
        k_err_b_profile_template      CONSTANT VARCHAR2(1000 CHAR) := 'ID_SOFTWARE/ID_PROFILE_TEMPLATE:BAD MATCH';
    
        l_error VARCHAR2(1000 CHAR);
    
        -- **********************************************
        FUNCTION chk_if_shortcut_exist
        (
            i_id_sys_shortcut IN NUMBER,
            i_id_shortcut_pk  IN NUMBER,
            i_id_software     IN NUMBER
        ) RETURN BOOLEAN IS
            l_count NUMBER(24);
            l_bool  BOOLEAN := FALSE;
        BEGIN
        
            -- validar se o shortcut existe
        
            IF i_id_sys_shortcut IS NOT NULL
               AND i_id_sys_shortcut IS NOT NULL
            THEN
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM sys_shortcut
                 WHERE (id_sys_shortcut = i_id_sys_shortcut OR id_parent = i_id_sys_shortcut)
                   AND id_software = i_id_software
                   AND id_shortcut_pk = i_id_shortcut_pk;
            
                l_bool := l_count > 0;
            
            ELSE
                l_bool := TRUE;
            END IF;
        
            RETURN l_bool;
        
        END chk_if_shortcut_exist;
        -- ############################################
    
        -- **********************************************
        FUNCTION chk_shortcut_data
        (
            i_id_sys_button_prop IN NUMBER,
            i_id_shortcut_pk     IN NUMBER
        ) RETURN BOOLEAN IS
            l_count NUMBER(24);
            l_bool  BOOLEAN := FALSE;
        BEGIN
        
            IF i_id_shortcut_pk IS NOT NULL
            THEN
                -- Validar se sbp esta configurado para shortcut correcto
                SELECT COUNT(1)
                  INTO l_count
                  FROM sys_shortcut
                 WHERE id_sys_button_prop = i_id_sys_button_prop
                   AND id_shortcut_pk = i_id_shortcut_pk;
            
                l_bool := l_count > 0;
            
            ELSE
                l_bool := TRUE;
            END IF;
        
            RETURN l_bool;
        
        END chk_shortcut_data;
        -- ############################################
    
        -- ********************************************
        FUNCTION chk_profile
        (
            i_id_profile_template IN NUMBER,
            i_id_software         IN NUMBER
        ) RETURN BOOLEAN IS
            l_count NUMBER(24);
            l_bool  BOOLEAN := FALSE;
        BEGIN
        
            IF i_id_software != 0
            THEN
                SELECT COUNT(1)
                  INTO l_count
                  FROM profile_template
                 WHERE id_profile_template = i_id_profile_template
                   AND id_software = i_id_software;
            
                l_bool := l_count > 0;
            
            ELSE
                l_bool := TRUE;
            END IF;
        
            RETURN l_bool;
        
        END chk_profile;
        -- ############################################
    
    BEGIN
    
        <<b_validation>>
        FOR i IN 1 .. 3
        LOOP
        
            CASE i
                WHEN 1 THEN
                    l_error := k_err_b_chk_if_shortcut_exist;
                    l_bool  := chk_if_shortcut_exist(i_id_sys_shortcut, i_id_shortcut_pk, i_id_software);
                WHEN 2 THEN
                    l_error := k_err_b_chk_shortcut_data;
                    l_bool  := chk_shortcut_data(i_id_sys_button_prop, i_id_shortcut_pk);
                WHEN 3 THEN
                    l_error := k_err_b_profile_template;
                    l_bool  := chk_profile(i_id_profile_template, i_id_software);
            END CASE;
        
            IF NOT l_bool
            THEN
                EXIT b_validation;
            END IF;
        
        END LOOP b_validation;
    
        IF NOT l_bool
        THEN
            RETURN l_error;
        END IF;
    
        RETURN k_yes;
    
    END chk_sbp_shortcut;
    /**********************************************************************************************
    * get_sys_shortcut
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_button_prop     sys_button_prop.id_sys_button_prop%TYPE
    * @param i_screen_name    sys_button_prop.screen_name%TYPE
    * @param o_id_sys_shortcut        id_sys_shortcut
    * @param o_error                     error message
    *
    * @return                         boolean
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.3
    * @since                          2014/03/11
    **********************************************************************************************/
    FUNCTION get_sys_shortcut
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_button_prop IN sys_button_prop.id_sys_button_prop%TYPE,
        i_screen_name        IN sys_button_prop.screen_name%TYPE,
        o_id_sys_shortcut    OUT profile_templ_access.id_sys_shortcut%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_SYS_SHORTCUT';
        tbl_id                       table_number;
        l_id                         NUMBER(24);
        l_id_sys_shortcut            profile_templ_access.id_sys_shortcut%TYPE;
        l_id_profile_template        profile_template.id_profile_template%TYPE;
        l_id_profile_template_parent profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'get l_id_profile_template_parent';
        IF i_id_sys_button_prop IS NOT NULL
           OR i_screen_name IS NOT NULL
        THEN
        
            l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        
            SELECT pt.id_parent
              INTO l_id_profile_template_parent
              FROM profile_template pt
             WHERE pt.id_profile_template = l_id_profile_template;
        
            g_error := 'pk_child.get_sys_shortcut';
            <<lup_thru_profiles>>
            FOR i IN 1 .. 2
            LOOP
            
                CASE i
                    WHEN 1 THEN
                        l_id := l_id_profile_template;
                    WHEN 2 THEN
                        l_id := l_id_profile_template_parent;
                END CASE;
            
                SELECT pta.id_sys_shortcut
                  BULK COLLECT
                  INTO tbl_id
                  FROM sys_button_prop sbp
                  JOIN profile_templ_access pta
                    ON pta.id_sys_button_prop = sbp.id_sys_button_prop
                   AND pta.flg_add_remove = pk_alert_constant.g_active
                 WHERE sbp.screen_name = nvl(i_screen_name, sbp.screen_name)
                   AND sbp.id_sys_button_prop = nvl(i_id_sys_button_prop, sbp.id_sys_button_prop)
                   AND pta.id_profile_template = l_id
                   AND pta.id_sys_shortcut IS NOT NULL
                   AND rownum = 1;
            
                IF tbl_id.count > 0
                THEN
                    l_id_sys_shortcut := tbl_id(1);
                    EXIT lup_thru_profiles;
                END IF;
            
            END LOOP lup_thru_profiles;
        
        END IF;
    
        o_id_sys_shortcut := l_id_sys_shortcut;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            o_id_sys_shortcut := NULL;
            RETURN FALSE;
    END get_sys_shortcut;

    -- ********* CMF
    FUNCTION get_epis_type(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_episode table_number;
        l_return    NUMBER;
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
        
            SELECT id_epis_type
              BULK COLLECT
              INTO tbl_episode
              FROM episode
             WHERE id_episode = i_episode;
        
            IF tbl_episode.count > 0
            THEN
                l_return := tbl_episode(1);
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_epis_type;

    FUNCTION get_pat_info
    (
        i_patient IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_curr_year    NUMBER;
        l_pat_year     NUMBER;
        tbl_pat_year   table_varchar;
        tbl_pat_gender table_varchar;
        l_return       VARCHAR2(4000);
        k_mask_year CONSTANT VARCHAR2(4 CHAR) := 'YYYY';
    BEGIN
    
        l_curr_year := to_char(current_timestamp, k_mask_year);
    
        IF i_patient IS NOT NULL
        THEN
            SELECT to_number(to_char(dt_birth, k_mask_year)), gender
              BULK COLLECT
              INTO tbl_pat_year, tbl_pat_gender
              FROM patient
             WHERE id_patient = i_patient;
        
            CASE i_mode
                WHEN k_pat_age THEN
                
                    IF tbl_pat_year.count > 0
                    THEN
                        l_pat_year := to_number(tbl_pat_year(1));
                        l_return   := l_curr_year - l_pat_year;
                    END IF;
                WHEN k_pat_gender THEN
                    IF tbl_pat_gender.count > 0
                    THEN
                        l_return := tbl_pat_gender(1);
                    END IF;
                ELSE
                    l_return := NULL;
            END CASE;
        
        END IF;
    
        RETURN l_return;
    
    END get_pat_info;

    FUNCTION get_pat_age(i_patient IN NUMBER) RETURN NUMBER IS
        l_return NUMBER;
    BEGIN
    
        l_return := to_number(get_pat_info(i_patient, k_pat_age));
    
        RETURN l_return;
    END get_pat_age;

    FUNCTION get_pat_gender(i_patient IN NUMBER) RETURN VARCHAR2 IS
        l_return VARCHAR2(0010 CHAR);
    BEGIN
    
        l_return := get_pat_info(i_patient, k_pat_gender);
    
        RETURN l_return;
    END get_pat_gender;

    FUNCTION get_shortcuts_array
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_episode   IN NUMBER,
        i_screens   IN table_varchar,
        i_scr_alias IN table_varchar DEFAULT NULL,
        o_shortcuts OUT map_vnumber,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_sh_row IS RECORD(
            intern_name     VARCHAR2(200 CHAR),
            id_sys_shortcut NUMBER);
    
        TYPE t_sh_rows IS TABLE OF t_sh_row INDEX BY BINARY_INTEGER;
        l_sh_rows t_sh_rows;
    
        l_prf   profile_template%ROWTYPE;
        tbl_pta t_tbl_access := t_tbl_access();
    
        --**********************************
    
        CURSOR ss_cur(i_screen_name IN VARCHAR2) IS
            SELECT LEVEL nivel, sss.*
              FROM (SELECT ss.*
                      FROM sys_shortcut ss
                     WHERE ss.intern_name = i_screen_name
                       AND id_software = i_prof.software) sss
            CONNECT BY PRIOR sss.id_sys_shortcut = sss.id_parent
             START WITH sss.id_parent IS NULL;
        l_shcut_level_1 NUMBER;
        b_flag_success  BOOLEAN := TRUE;
        b_flag          BOOLEAN := TRUE;
    
    BEGIN
    
        <<lup_thru_screens>>
        FOR i IN 1 .. i_screens.count
        LOOP
        
            o_shortcuts(i_screens(i)) := NULL;
            <<lup_thru_scut_screen>>
            FOR ss_c IN ss_cur(i_screens(i))
            LOOP
            
                IF ss_c.nivel = 1
                THEN
                    l_shcut_level_1 := ss_c.id_sys_shortcut;
                END IF;
            
                tbl_pta := pk_access.get_access(i_lang,
                                                i_prof,
                                                i_patient,
                                                i_episode,
                                                table_number(ss_c.id_sys_button_prop),
                                                'N');
                b_flag  := tbl_pta.count > 0;
                IF b_flag
                THEN
                    o_shortcuts(i_screens(i)) := l_shcut_level_1;
                    EXIT lup_thru_scut_screen;
                END IF;
            
            END LOOP lup_thru_scut_screen;
        
            b_flag_success := b_flag_success AND b_flag;
        
        END LOOP;
    
        --RETURN b_flag_success;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SHORTCUTS_ARRAY',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_shortcuts_array;

    FUNCTION get_shortcut_html
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_episode IN NUMBER,
        i_short   IN sys_shortcut.id_sys_shortcut%TYPE,
        o_access  OUT pk_types.cursor_type,
        o_prt     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_SHORTCUT';
        l_found BOOLEAN;
        l_flag  NUMBER(24);
    
        l_prf       profile_template%ROWTYPE;
        t_sht       t_shortcut;
        tbl_profile table_number := table_number();
    
        CURSOR c_access
        (
            i_id_profile_template IN NUMBER,
            i_tbl_profile         IN table_number,
            i_pat_age             IN NUMBER,
            i_pat_gender          IN VARCHAR2,
            i_epis_type           IN NUMBER
        ) IS
            SELECT xmain.id_sys_application_area,
                   xmain.btn_dest,
                   xmain.screen_name,
                   xmain.screen_area,
                   xmain.flg_area,
                   xmain.deepnav_id_sys_button_prop,
                   xmain.btn_label,
                   xmain.son_intern_name,
                   xmain.btn_parent,
                   xmain.btn_prop_parent,
                   xmain.screen_area_parent,
                   xmain.par_intern_name,
                   xmain.id_sys_button_prop,
                   xmain.exist_child,
                   xmain.action,
                   xmain.msg_copyright,
                   xmain.flg_screen_mode,
                   xmain.screen_params
              FROM (SELECT decode(pta.id_profile_template, i_id_profile_template, 0, 99999) pta_rank,
                           pta.id_profile_template,
                           pta.id_sys_shortcut,
                           --dense_rank() over(PARTITION BY sst_id_sys_shortcut ORDER BY age_min DESC, gender DESC, id_epis_type DESC) my_rank,
                           dense_rank() over(PARTITION BY pta.id_sys_shortcut ORDER BY coalesce(pta.age_min, k_low_limit) DESC, coalesce(pta.gender, k_min_char) DESC, coalesce(pta.id_epis_type, k_low_limit) DESC) my_rank,
                           
                           xsql.*,
                           pta.age_min,
                           pta.id_epis_type,
                           pta.gender
                      FROM (SELECT btn.id_sys_application_area id_sys_application_area,
                                   btn.id_sys_button btn_dest,
                                   btn.screen_name screen_name,
                                   btn.id_sys_screen_area screen_area,
                                   saa.flg_area flg_area,
                                   sst.id_sys_button_prop deepnav_id_sys_button_prop,
                                   sst.id_sys_shortcut sst_id_sys_shortcut,
                                   pk_message.get_message(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_code_mess => but.code_button) btn_label,
                                   but.intern_name_button son_intern_name,
                                   bt2.id_sys_button btn_parent,
                                   btn.id_btn_prp_parent btn_prop_parent,
                                   bt2.id_sys_screen_area screen_area_parent,
                                   bu2.intern_name_button par_intern_name,
                                   btn.id_btn_prp_parent id_sys_button_prop,
                                   pk_access.exist_child(i_lang,
                                                         i_prof,
                                                         i_patient,
                                                         i_episode,
                                                         btn.id_sys_application_area,
                                                         btn.id_sys_button_prop) exist_child,
                                   btn.action action,
                                   (SELECT pk_message.get_message(i_lang, i_prof, btn.code_msg_copyright)
                                      FROM dual) msg_copyright,
                                   btn.flg_screen_mode flg_screen_mode,
                                   pk_access.get_button_prop_params(sst.id_sys_button_prop) screen_params
                              FROM sys_shortcut sst
                              JOIN sys_button_prop btn
                                ON btn.id_sys_button_prop = sst.id_sys_button_prop
                              LEFT JOIN sys_button_prop bt2
                                ON bt2.id_sys_button_prop = btn.id_btn_prp_parent
                              JOIN sys_application_area saa
                                ON btn.id_sys_application_area = saa.id_sys_application_area
                              JOIN sys_button but
                                ON btn.id_sys_button = but.id_sys_button
                              LEFT JOIN sys_button bu2
                                ON bt2.id_sys_button = bu2.id_sys_button
                             WHERE ((sst.id_sys_shortcut = i_short) OR (sst.id_parent = i_short))
                               AND sst.id_software = i_prof.software
                               AND (sst.id_sys_button_prop, sst.id_shortcut_pk) IN
                                   (SELECT /*+ opt_estimate(table btn1 rows=1) */
                                     btn1.id_sys_button_prop, btn1.id_shortcut_pk
                                      FROM TABLE(pk_access.get_agg_access(i_prof,
                                                                          i_patient,
                                                                          i_episode,
                                                                          btn.id_sys_button_prop,
                                                                          i_id_profile_template,
                                                                          k_no)) btn1 --9721
                                     WHERE btn1.my_rank = k_first_row
                                       AND btn1.flg_add_remove = g_flg_type_add)) xsql
                      JOIN profile_templ_access pta
                        ON pta.id_sys_button_prop = xsql.deepnav_id_sys_button_prop
                       AND pta.id_profile_template IN (SELECT column_value
                                                         FROM TABLE(i_tbl_profile))
                     WHERE 0 = 0
                       AND coalesce(pta.age_min, k_low_limit) <= i_pat_age
                       AND coalesce(pta.id_epis_type, k_low_limit) IN (i_epis_type, k_low_limit)
                       AND coalesce(pta.gender, k_min_char) IN (i_pat_gender, k_min_char)) xmain
             WHERE xmain.my_rank = 1
             ORDER BY pta_rank, deepnav_id_sys_button_prop;
    
        l_pat_age    NUMBER;
        l_pat_gender VARCHAR2(0010 CHAR);
        l_epis_type  NUMBER;
    
    BEGIN
    
        l_pat_age    := get_pat_age(i_patient);
        l_pat_gender := get_pat_gender(i_patient);
        l_epis_type  := get_epis_type(i_episode);
    
        l_pat_age := coalesce(l_pat_age, k_low_limit);
    
        l_prf       := get_profile(i_prof => i_prof);
        tbl_profile := get_profile_template_tree(i_prof, l_prf.id_profile_template);
    
        --OPEN c_access(l_prf.id_profile_template, tbl_profile, l_pat_age, l_pat_gender, l_epis_type);
        OPEN c_access(l_prf.id_profile_template, tbl_profile, l_pat_age, l_pat_gender, l_epis_type);
        FETCH c_access
            INTO t_sht.id_sys_application_area,
                 t_sht.btn_dest,
                 t_sht.screen_name,
                 t_sht.screen_area,
                 t_sht.flg_area,
                 t_sht.deepnav_id_sys_button_prop,
                 t_sht.btn_label,
                 t_sht.son_intern_name,
                 t_sht.btn_parent,
                 t_sht.btn_prop_parent,
                 t_sht.screen_area_parent,
                 t_sht.par_intern_name,
                 t_sht.id_sys_button_prop,
                 t_sht.exist_child,
                 t_sht.action,
                 t_sht.msg_copyright,
                 t_sht.flg_screen_mode,
                 t_sht.screen_params;
        l_found := c_access%FOUND;
        CLOSE c_access;
    
        l_flag := iif(l_found, k_true, k_false);
    
        g_error := 'Transform Array to Cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_prt FOR
            SELECT *
              FROM (SELECT id_sys_button id_parent, id_sys_screen_area
                      FROM sys_button_prop
                     WHERE id_sys_screen_area IN (k_toolbar_area, k_toolbar_area_right, k_toolbar_search)
                     START WITH id_sys_button_prop = t_sht.deepnav_id_sys_button_prop
                    CONNECT BY PRIOR id_btn_prp_parent = id_sys_button_prop
                    UNION ALL
                    SELECT t_sht.btn_dest id_parent, t_sht.screen_area
                      FROM dual)
             ORDER BY id_sys_screen_area DESC;
    
        g_error := 'GET o_access';
        pk_alertlog.log_debug(g_error);
        OPEN o_access FOR
            SELECT t_sht.id_sys_application_area id_sys_application_area,
                   t_sht.btn_dest btn_dest,
                   t_sht.screen_name screen_name,
                   t_sht.flg_area flg_area,
                   t_sht.deepnav_id_sys_button_prop deepnav_id_sys_button_prop,
                   t_sht.btn_label btn_label,
                   t_sht.son_intern_name son_intern_name,
                   t_sht.btn_parent btn_parent,
                   t_sht.btn_prop_parent btn_prop_parent,
                   t_sht.screen_area screen_area,
                   t_sht.screen_area_parent screen_area_parent,
                   t_sht.par_intern_name par_intern_name,
                   t_sht.id_sys_button_prop id_sys_button_prop,
                   t_sht.exist_child exist_child,
                   pk_access.get_string_action(t_sht.action) action,
                   t_sht.msg_copyright msg_copyright,
                   t_sht.flg_screen_mode flg_screen_mode,
                   t_sht.screen_params screen_params
              FROM dual
             WHERE k_true = l_flag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            --open_my_cursor(o_access);
            pk_types.open_my_cursor(o_access);
            pk_types.open_my_cursor(o_prt);
            RETURN FALSE;
        
    END get_shortcut_html;

BEGIN
    g_func_available  := k_yes;
    g_field_available := k_yes;

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_access;
/
