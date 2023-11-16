/*-- Last Change Revision: $Rev: 2045949 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-09-22 16:26:56 +0100 (qui, 22 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_action IS

    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT p_action_cur,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table act rows=1)*/
             a.id_action,
             a.id_parent,
             a.level_nr "level",
             a.from_state,
             a.to_state,
             a.desc_action,
             a.icon,
             a.flg_default,
             a.flg_active,
             a.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT act.id_action,
                   act.id_parent,
                   act.level_nr,
                   act.to_state,
                   act.desc_action,
                   act.icon,
                   act.flg_default,
                   act.flg_active,
                   act.action,
                   rownum rank
              FROM (pk_action.tf_get_actions_base(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_subject    => i_subject,
                                                  i_from_state => i_from_state) act)
             ORDER BY act.level_nr, act.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    FUNCTION get_actions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_workflow          IN NUMBER,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2,
        o_actions              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   LEVEL l,
                   a.from_state,
                   a.to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   icon,
                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                   nvl((SELECT get_actions_exception(i_lang, i_prof, a.id_action)
                         FROM dual),
                       a.flg_status) flg_active,
                   concat(concat(a.flg_flash_action_type, '|'),
                           CASE
                               WHEN a.flg_flash_action_type IN ('M', 'D') THEN
                                a.flash_method_name
                               WHEN a.flg_flash_action_type IN ('T') THEN
                                (SELECT pk_navigation.get_screen_key(i_lang,
                                                                     i_prof,
                                                                     i_class_origin,
                                                                     i_class_origin_context,
                                                                     id_action)
                                   FROM dual)
                           END) action
              FROM action a
             WHERE a.id_workflow = i_id_workflow
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    FUNCTION get_actions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_workflow IN action.id_workflow%TYPE,
        i_subject     IN action.subject%TYPE,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   LEVEL l,
                   a.from_state,
                   a.to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   icon,
                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                   nvl((SELECT get_actions_exception(i_lang, i_prof, a.id_action)
                         FROM dual),
                       a.flg_status) flg_active,
                   concat(concat(a.flg_flash_action_type, '|'),
                           CASE
                               WHEN a.flg_flash_action_type IN ('M', 'D') THEN
                                a.flash_method_name
                               WHEN a.flg_flash_action_type IN ('T') THEN
                                NULL
                           END) action
            
              FROM action a
             WHERE a.id_workflow = i_id_workflow
               AND nvl2(i_subject, a.subject, '_N') = nvl(i_subject, '_N')
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_actions_to_execute
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_action  IN action.id_action%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT id_action,
                   to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   icon,
                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                   flg_status
              FROM action a, action_map am
             WHERE am.id_action_selected = i_action
               AND a.id_action = am.id_action_execute
             ORDER BY rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS_TO_EXECUTE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_to_execute;

    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_profile_template IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt, software s
             WHERE ppt.id_professional = i_prof.id
               AND ppt.id_software IN (i_prof.software, 0)
               AND ppt.id_institution IN (i_prof.institution, 0)
               AND ppt.id_profile_template = pt.id_profile_template
               AND pt.id_software = s.id_software
               AND s.flg_viewer = 'N';
    
        r_profile_template c_profile_template%ROWTYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error := 'GET PROFILE_TEMPLATE';
        OPEN c_profile_template;
        FETCH c_profile_template
            INTO r_profile_template;
    
        IF c_profile_template%FOUND
        THEN
            l_profile_template := r_profile_template.id_profile_template;
        END IF;
        CLOSE c_profile_template;
    
        g_error := 'GET CURSOR o_actions permissions';
        OPEN o_actions FOR
            SELECT aa.id_action,
                   aa.id_parent id_parent,
                   LEVEL,
                   aa.from_state,
                   aa.to_state,
                   aa.desc_action,
                   aa.icon,
                   decode(aa.flg_default, 'D', 'Y', 'N') flg_default,
                   nvl(get_actions_exception(i_lang, i_prof, aa.id_action), aa.flg_status) flg_active,
                   aa.internal_name action
              FROM (SELECT a.id_action,
                           a.id_parent id_parent,
                           a.from_state,
                           a.to_state,
                           pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                           a.icon,
                           a.flg_default,
                           a.flg_status,
                           a.internal_name,
                           a.rank
                      FROM action a
                      JOIN action_permission ap
                        ON a.id_action = ap.id_action
                      JOIN (SELECT MAX(ap1.id_institution) id_instit
                             FROM action a1, action_permission ap1
                            WHERE a1.subject = i_subject
                              AND nvl(a1.from_state, 0) = nvl(i_from_state, nvl(a1.from_state, 0))
                              AND a1.id_action = ap1.id_action
                              AND ap1.id_profile_template = l_profile_template) val_max
                        ON ap.id_institution = val_max.id_instit
                     WHERE a.subject = i_subject
                       AND nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
                       AND ap.id_profile_template = l_profile_template
                       AND ap.id_category = pk_prof_utils.get_id_category(i_lang, i_prof)
                       AND ap.id_software = (SELECT MAX(b.id_software)
                                               FROM action_permission b
                                              WHERE b.id_action = ap.id_action
                                                AND b.id_profile_template = ap.id_profile_template
                                                AND b.id_task_type = ap.id_task_type
                                                AND b.id_category = ap.id_category
                                                AND b.id_software = ap.id_software)) aa
            CONNECT BY PRIOR aa.id_action = aa.id_parent
             ORDER BY LEVEL, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS_PERMISSIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_permissions;

    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr "level",
                   a.from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   a.flg_default,
                   a.flg_active,
                   a.action
              FROM TABLE(pk_action.tf_get_actions_with_exceptions(i_lang, i_prof, i_subject, i_from_state)) a;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_with_exceptions;

    FUNCTION get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l "level",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT id_action,
                           id_parent,
                           LEVEL l,
                           to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           icon,
                           decode(flg_default, 'D', 'Y', 'N') flg_default,
                           nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                           internal_name action,
                           rank
                      FROM action a
                     WHERE subject IN (SELECT *
                                         FROM TABLE(i_subject))
                       AND from_state IN (SELECT *
                                            FROM TABLE(i_from_state))
                    CONNECT BY PRIOR id_action = id_parent
                     START WITH id_parent IS NULL)
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
             ORDER BY "level", rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_with_exceptions;

    FUNCTION get_actions_exception
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.id_action%TYPE
    ) RETURN VARCHAR2 IS
    
        tbl_state      table_varchar;
        l_action_state action.flg_status%TYPE := NULL;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET action_exception parametrization';
        --Max A/I = A - if more than one parametrization is found then show active (if applicable)
        SELECT flg_status
          BULK COLLECT
          INTO tbl_state
          FROM (SELECT ae.flg_status, row_number() over(PARTITION BY ae.id_action ORDER BY ae.id_software DESC) rn
                  FROM action_exception ae
                 WHERE ae.id_action = i_action
                   AND ((ae.id_category = pk_prof_utils.get_id_category(i_lang, i_prof) OR
                       ae.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof) OR
                       ae.id_profissional = i_prof.id))
                   AND ae.flg_available = pk_alert_constant.g_yes
                   AND ae.id_software IN (0, i_prof.software))
         WHERE rn = 1;
    
        IF tbl_state.count > 0
        THEN
            l_action_state := tbl_state(1);
        END IF;
    
        RETURN l_action_state;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS_EXCEPTION',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_actions_exception;

    FUNCTION get_cross_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l "level",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT id_action,
                           id_parent,
                           LEVEL l,
                           to_state,
                           pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                           icon,
                           decode(flg_default, 'D', 'Y', 'N') flg_default,
                           nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                           internal_name action,
                           a.from_state,
                           rank
                      FROM action a
                     WHERE subject = i_subject
                       AND from_state IN (SELECT *
                                            FROM TABLE(i_from_state))
                    CONNECT BY PRIOR id_action = id_parent
                     START WITH id_parent IS NULL)
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (SELECT COUNT(*)
                                          FROM TABLE(table_varchar() MULTISET UNION DISTINCT i_from_state))
             ORDER BY "level", rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CROSS_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_cross_actions;

    FUNCTION get_cross_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_task_type  IN task_type.id_task_type%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_from_state          table_varchar;
        l_id_category         NUMBER;
        l_id_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        g_error               := 'Filter duplicates';
        l_from_state          := SET(i_from_state);
        l_id_category         := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT MIN(id_action) id_action,
                   id_parent,
                   l "level",
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   MAX(flg_active) flg_active,
                   action,
                   MIN(rank) rank
              FROM (SELECT act.id_action,
                           act.id_parent,
                           act.l,
                           act.to_state,
                           act.desc_action,
                           act.icon,
                           act.flg_default,
                           act.flg_active,
                           act.action,
                           act.from_state,
                           act.rank,
                           rank() over(ORDER BY ap.id_institution DESC, ap.id_software DESC NULLS LAST) origin_rank
                      FROM (SELECT a.id_action,
                                   a.id_parent,
                                   LEVEL l,
                                   a.to_state,
                                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                                   a.icon,
                                   decode(flg_default, g_flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                                   nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                                   a.internal_name action,
                                   a.from_state,
                                   a. rank
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(l_from_state))
                            CONNECT BY PRIOR a.id_action = a.id_parent
                             START WITH a.id_parent IS NULL) act
                     INNER JOIN action_permission ap
                        ON ap.id_action = act.id_action
                     WHERE ap.id_profile_template = l_id_profile_template
                       AND ap.id_institution IN (0, i_prof.institution)
                       AND ap.id_software IN (0, i_prof.software)
                       AND ap.id_task_type = i_task_type
                       AND ap.id_category = l_id_category)
             WHERE origin_rank = 1
             GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
            HAVING COUNT(from_state) = (SELECT COUNT(*)
                                          FROM TABLE(table_varchar() MULTISET UNION DISTINCT l_from_state))
             ORDER BY "level", rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CROSS_ACTIONS_PERMISSIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_cross_actions_permissions;

    FUNCTION get_action_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN action.id_action%TYPE
    ) RETURN VARCHAR2 IS
    
        l_action_desc sys_message.desc_message%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        SELECT pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => code_action)
          INTO l_action_desc
          FROM action
         WHERE id_action = i_id_action;
    
        RETURN l_action_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTION_DESC',
                                              l_error);
            RAISE;
    END get_action_desc;

    FUNCTION get_action_flg_status
    (
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_to_state   IN action.to_state%TYPE
    ) RETURN action.flg_status%TYPE IS
    
        l_flg_status action.flg_status%TYPE;
    
    BEGIN
    
        SELECT a.flg_status
          INTO l_flg_status
          FROM action a
         WHERE a.subject = i_subject
           AND nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
           AND nvl(a.to_state, 0) = nvl(i_to_state, nvl(a.to_state, 0));
    
        RETURN l_flg_status;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_action_flg_status;

    FUNCTION get_action_rank
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_action IN action.rank%TYPE
    ) RETURN action.rank%TYPE IS
    
        l_rank action.rank%TYPE;
    
    BEGIN
    
        SELECT a.rank
          INTO l_rank
          FROM action a
         WHERE a.id_action = i_action;
    
        RETURN l_rank;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            RETURN 0;
    END get_action_rank;

    FUNCTION get_action_icon_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_action IN action.id_action%TYPE
    ) RETURN action.icon%TYPE IS
    
        l_icon action.icon%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        SELECT a.icon
          INTO l_icon
          FROM action a
         WHERE id_action = i_id_action;
    
        RETURN l_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTION_ICON_NAME',
                                              l_error);
            RETURN NULL;
    END get_action_icon_name;

    FUNCTION get_actions_by_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   LEVEL,
                   from_state,
                   to_state,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                   icon,
                   decode(flg_default, 'D', 'Y', 'N') flg_default,
                   nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                   internal_name action,
                   a.group_id
              FROM action a
             WHERE subject = i_subject
               AND nvl(from_state, 0) = nvl(i_from_state, nvl(from_state, 0))
            CONNECT BY PRIOR id_action = id_parent
             START WITH id_parent IS NULL
             ORDER BY LEVEL, group_id, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS_BY_GROUP',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_by_group;

    FUNCTION check_state_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_to_state   IN action.to_state%TYPE
    ) RETURN BOOLEAN IS
    
        l_action pk_types.cursor_type;
        l_flag   BOOLEAN := FALSE;
    
        action_exception EXCEPTION;
    
        l_id_action     action.id_action%TYPE;
        l_id_parent     action.id_parent%TYPE;
        l_level         NUMBER;
        l_from_state    action.from_state%TYPE;
        l_to_state      action.to_state%TYPE;
        l_desc_action   sys_message.code_message%TYPE;
        l_icon          action.icon%TYPE;
        l_flg_default   VARCHAR2(1);
        l_flg_status    action.flg_status%TYPE;
        l_internal_name action.internal_name%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'Execute function get_actions';
        IF get_actions(i_lang       => i_lang,
                       i_prof       => i_prof,
                       i_subject    => i_subject,
                       i_from_state => i_from_state,
                       o_actions    => l_action,
                       o_error      => l_error)
        THEN
            LOOP
                FETCH l_action
                    INTO l_id_action,
                         l_id_parent,
                         l_level,
                         l_from_state,
                         l_to_state,
                         l_desc_action,
                         l_icon,
                         l_flg_default,
                         l_flg_status,
                         l_internal_name;
                EXIT WHEN l_action%NOTFOUND;
            
                IF l_to_state = i_to_state
                THEN
                    l_flag := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        ELSE
            RAISE action_exception;
        END IF;
    
        RETURN l_flag;
    
    END check_state_actions;

    FUNCTION tf_get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        SELECT t_rec_action(a.id_action,
                            a.id_parent,
                            LEVEL,
                            a.from_state,
                            a.to_state,
                            a.desc_action,
                            a.icon,
                            a.flg_default,
                            a.internal_name,
                            a.flg_status)
          BULK COLLECT
          INTO l_table_actions
          FROM (SELECT a.id_action,
                       a.id_parent,
                       a.from_state,
                       a.to_state,
                       pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                       a.icon,
                       decode(a.flg_default, 'D', 'Y', 'N') flg_default,
                       a.internal_name,
                       nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_status,
                       a.rank
                  FROM action a
                 WHERE a.subject = i_subject) a
         WHERE nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
        CONNECT BY PRIOR a.id_action = a.id_parent
         START WITH a.id_parent IS NULL
         ORDER BY LEVEL, a.rank, a.desc_action;
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS',
                                              l_error);
            RETURN NULL;
    END tf_get_actions;

    FUNCTION tf_get_actions_by_wf_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_workflows            IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET collection o_actions';
        SELECT /*+opt_estimate(table a rows=1)*/
         t_rec_action(id_action,
                       id_parent,
                       LEVEL,
                       from_state,
                       to_state,
                       pk_message.get_message(i_lang, i_prof, code_action),
                       icon,
                       decode(flg_default, 'D', 'Y', 'N'),
                       concat(concat(a.flg_flash_action_type, '|'),
                              CASE
                                  WHEN a.flg_flash_action_type IN ('M', 'D') THEN
                                   a.flash_method_name
                                  WHEN a.flg_flash_action_type IN ('T') THEN
                                   (SELECT pk_navigation.get_screen_key(i_lang, i_prof, i_class_origin, i_class_origin_context, id_action)
                                      FROM dual)
                              END),
                       flg_status)
          BULK COLLECT
          INTO l_table_actions
          FROM action a
         WHERE a.id_workflow IN (SELECT column_value
                                   FROM TABLE(i_workflows))
        CONNECT BY PRIOR id_action = id_parent
         START WITH id_parent IS NULL
         ORDER BY LEVEL, rank, pk_message.get_message(i_lang, i_prof, code_action);
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS_BY_WF_COL',
                                              l_error);
            RETURN NULL;
    END tf_get_actions_by_wf_col;

    FUNCTION tf_get_actions_by_id_col
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_actions              IN table_number,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET collection o_actions';
        SELECT /*+opt_estimate(table t rows=1)*/
         t_rec_action(a.id_action,
                       id_parent,
                       LEVEL,
                       from_state,
                       to_state,
                       (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                          FROM dual),
                       icon,
                       decode(flg_default, 'D', 'Y', 'N'),
                       concat(concat(a.flg_flash_action_type, '|'),
                              CASE
                                  WHEN a.flg_flash_action_type IN ('M', 'D') THEN
                                   a.flash_method_name
                                  WHEN a.flg_flash_action_type IN ('T') THEN
                                   (SELECT pk_navigation.get_screen_key(i_lang, i_prof, i_class_origin, i_class_origin_context, a.id_action)
                                      FROM dual)
                              END),
                       flg_status)
          BULK COLLECT
          INTO l_table_actions
          FROM action a
          JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                 column_value id_action
                  FROM TABLE(i_actions) a) t
            ON t.id_action = a.id_action
        CONNECT BY PRIOR a.id_action = id_parent
         START WITH id_parent IS NULL
         ORDER BY LEVEL,
                  rank,
                  (SELECT pk_message.get_message(i_lang, i_prof, code_action)
                     FROM dual);
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS_BY_ID_COL',
                                              l_error);
            RETURN NULL;
    END tf_get_actions_by_id_col;

    FUNCTION tf_get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_profile  action_permission.id_profile_template%TYPE;
        l_category action_permission.id_category%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error    := 'GET PROFILE_TEMPLATE';
        l_profile  := pk_access.get_profile(i_prof).id_profile_template;
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET CURSOR o_actions permissions';
        SELECT t_rec_action(a.id_action,
                            a.id_parent,
                            LEVEL,
                            a.from_state,
                            a.to_state,
                            pk_message.get_message(i_lang, i_prof, a.code_action),
                            a.icon,
                            decode(a.flg_default, g_flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                            a.internal_name,
                            nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status))
          BULK COLLECT
          INTO l_table_actions
          FROM action a
          JOIN (SELECT rank() over(PARTITION BY ap.id_action ORDER BY ap.id_institution DESC, ap.id_software DESC, ap.id_category DESC, ap.id_profile_template DESC) precedence_level,
                       ap.*
                  FROM action_permission ap
                 WHERE ap.id_category IN (-1, l_category)
                   AND ap.id_profile_template IN (0, l_profile)
                   AND ap.id_institution IN (0, i_prof.institution)
                   AND ap.id_software IN (0, i_prof.software)
                   AND ap.flg_available = pk_alert_constant.g_yes) t
            ON (t.id_action = a.id_action)
         WHERE t.precedence_level = 1
           AND a.subject = i_subject
           AND nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
        CONNECT BY PRIOR a.id_action = a.id_parent;
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS_PERMISSIONS',
                                              l_error);
            RETURN t_coll_action();
    END tf_get_actions_permissions;

    FUNCTION tf_get_actions_permissions_wm
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_subject              IN action.subject%TYPE,
        i_from_state           IN action.from_state%TYPE,
        i_class_origin         IN VARCHAR2,
        i_class_origin_context IN VARCHAR2
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_profile  action_permission.id_profile_template%TYPE;
        l_category action_permission.id_category%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error    := 'GET PROFILE_TEMPLATE';
        l_profile  := pk_access.get_profile(i_prof).id_profile_template;
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET CURSOR o_actions permissions';
        SELECT t_rec_action(a.id_action,
                             a.id_parent,
                             LEVEL,
                             a.from_state,
                             a.to_state,
                             pk_message.get_message(i_lang, i_prof, a.code_action),
                             a.icon,
                             decode(a.flg_default, g_flg_default, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                             concat(concat(a.flg_flash_action_type, '|'),
                                    CASE
                                        WHEN a.flg_flash_action_type IN ('M', 'D') THEN
                                         a.flash_method_name
                                        WHEN a.flg_flash_action_type IN ('T') THEN
                                         (SELECT pk_navigation.get_screen_key(i_lang,
                                                                              i_prof,
                                                                              i_class_origin,
                                                                              i_class_origin_context,
                                                                              a.id_action)
                                            FROM dual)
                                    END),
                             t.flg_available)
          BULK COLLECT
          INTO l_table_actions
          FROM action a
          JOIN (SELECT rank() over(PARTITION BY ap.id_action ORDER BY ap.id_institution DESC, ap.id_software DESC, ap.id_category DESC, ap.id_profile_template DESC) precedence_level,
                       ap.*
                  FROM action_permission ap
                 WHERE ap.id_category IN (-1, l_category)
                   AND ap.id_profile_template IN (0, l_profile)
                   AND ap.id_institution IN (0, i_prof.institution)
                   AND ap.id_software IN (0, i_prof.software)
                   AND ap.flg_available = pk_alert_constant.g_yes) t
            ON (t.id_action = a.id_action)
         WHERE t.precedence_level = 1
           AND a.subject = i_subject
           AND nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
        CONNECT BY PRIOR a.id_action = a.id_parent;
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS_PERMISSIONS_WM',
                                              l_error);
            RETURN t_coll_action();
    END tf_get_actions_permissions_wm;

    FUNCTION tf_get_actions_with_exceptions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE
    ) RETURN t_coll_action IS
    
        l_table_actions t_coll_action;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        SELECT t_rec_action(a.id_action,
                            a.id_parent,
                            LEVEL,
                            a.from_state,
                            a.to_state,
                            a.desc_action,
                            a.icon,
                            a.flg_default,
                            a.internal_name,
                            a.flg_active)
          BULK COLLECT
          INTO l_table_actions
          FROM (SELECT a.id_action,
                       a.id_parent,
                       a.from_state,
                       a.to_state,
                       pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                       a.icon,
                       decode(a.flg_default, 'D', 'Y', 'N') flg_default,
                       a.internal_name,
                       nvl(get_actions_exception(i_lang, i_prof, a.id_action), a.flg_status) flg_active,
                       a.rank
                  FROM action a
                 WHERE a.subject = i_subject) a
         WHERE nvl(a.from_state, 0) = nvl(i_from_state, nvl(a.from_state, 0))
        CONNECT BY PRIOR a.id_action = a.id_parent
         START WITH a.id_parent IS NULL
         ORDER BY LEVEL, a.rank, a.desc_action;
    
        RETURN l_table_actions;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'TF_GET_ACTIONS_WITH_EXCEPTIONS',
                                              l_error);
            RETURN NULL;
    END tf_get_actions_with_exceptions;

    FUNCTION tf_get_actions_base
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar
    ) RETURN t_coll_action IS
        l_table_actions t_coll_action;
        l_error         t_error_out;
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
        SELECT t_rec_action(id_action   => xbase.id_action,
                            id_parent   => xbase.id_parent,
                            level_nr    => xbase.xlevel,
                            from_state  => xbase.from_state,
                            to_state    => xbase.to_state,
                            desc_action => xbase.desc_action,
                            icon        => xbase.icon,
                            flg_default => xbase.flg_default,
                            action      => xbase.action,
                            flg_active  => xbase.flg_active)
          BULK COLLECT
          INTO l_table_actions
          FROM (SELECT MIN(id_action) id_action,
                       id_parent,
                       l xlevel,
                       NULL from_state,
                       to_state,
                       desc_action,
                       icon,
                       flg_default,
                       action,
                       MAX(flg_active) flg_active
                --,MIN(rank) rank
                  FROM (SELECT id_action,
                               id_parent,
                               LEVEL l,
                               to_state,
                               pk_message.get_message(i_lang, i_prof, code_action) desc_action,
                               icon,
                               decode(flg_default, 'D', 'Y', 'N') flg_default,
                               nvl((SELECT pk_action.get_actions_exception(i_lang, i_prof, id_action)
                                     FROM dual),
                                   flg_status) flg_active,
                               internal_name action,
                               rank
                          FROM action a
                         WHERE a.subject IN (SELECT *
                                             FROM TABLE(i_subject))
                           AND a.from_state IN (SELECT tt.*
                                                FROM TABLE(i_from_state) tt
                                                union all
                                                select a.from_state from dual )
                        CONNECT BY PRIOR id_action = id_parent
                         START WITH id_parent IS NULL)
                 GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action) xbase;
    
        RETURN l_table_actions;
    
    END tf_get_actions_base;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_action;
/
