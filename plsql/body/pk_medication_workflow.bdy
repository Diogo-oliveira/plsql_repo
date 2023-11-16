/*-- Last Change Revision: $Rev: 2027367 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:00 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_medication_workflow IS

    -- Author  : RUI.MARANTE
    -- Created : 06-01-2009 09:56:07
    -- Purpose : workflow management

    -- Private type declarations

    -- Private constant declarations
    g_pck_name CONSTANT VARCHAR2(30) := 'PK_MEDICATION_WORKFLOW';

    g_invalid_state CONSTANT NUMBER(1) := -1;

    -- Y|N (true|false)
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    -- Private variable declarations

    -- BEGIN ***** PRIVATE "SPECIAL" ***** Function and procedure implementations

    /********************************************************************************************
    * LOG
    *
    * @param  I_LANG      Preferred language ID
    * @param  I_PROF      Professional
    * @param  I_FUNC_NAME   Name of the method
    * @param  I_ERR_MSG   Error message (SQLERRM or user text message)
    *
    * @return         Composed text message
    *
    * @author Rui Marante
    * @version  0.1
    * @since  2009/01/06
    *********************************************************************************************/
    PROCEDURE wkflow_log
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_func_name IN VARCHAR2,
        i_err_msg   IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        /*
        insert into wfl_log (id_log, log_date, user_machine, prof, method, debug_info)
        values (seq_wfl_log_id.nextval, 
          sysdate, 
          sys_context('USERENV','HOST') || ' - ' || sys_context('USERENV','IP_ADDRESS'), 
          i_prof, 
          i_func_name, 
          'lang(' || i_lang || '); ERROR: ' || i_err_msg);
        */
    
        alertlog.pk_alertlog.log_debug(text            => 'lang(' || i_lang || '); ERROR: ' || i_err_msg,
                                       object_name     => g_pck_name,
                                       sub_object_name => i_func_name);
    
        COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END wkflow_log;

    FUNCTION wkflow_log
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_func_name IN VARCHAR2,
        i_err_msg   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_error VARCHAR2(2000) := '';
    BEGIN
    
        wkflow_log(i_lang, i_prof, i_func_name, i_err_msg);
    
        l_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_pck_name || '.' || i_func_name ||
                   ' / ' || i_err_msg;
        RETURN l_error;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('error on log function: ' || g_pck_name ||
                                 '.wkflow_log (trying to log message from: ' || g_pck_name || '.' || i_func_name || ')');
            RETURN 'error on log function: ' || g_pck_name || '.wkflow_log (trying to log message from: ' || g_pck_name || '.' || i_func_name || ')';
    END wkflow_log;

    /********************************************************************************************
    * TRACE
    *
    * @param  I_LANG      Preferred language ID
    * @param  I_PROF      Professional
    * @param  I_FUNC_NAME   Name of the method
    * @param  I_MSG     Message (user text message)
    *
    * @author Rui Marante
    * @version  0.1
    * @since  2009/01/08
    *********************************************************************************************/
    PROCEDURE wkflow_trace
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_func_name IN VARCHAR2,
        i_msg       IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        /*
        insert into wfl_log (id_log, log_date, user_machine, prof, method, debug_info)
        values (seq_wfl_log_id.nextval, 
          sysdate, 
          sys_context('USERENV','HOST') || ' - ' || sys_context('USERENV','IP_ADDRESS'), 
          i_prof, 
          i_func_name, 
          'lang(' || i_lang || '); TRACE: ' || i_msg);
        */
    
        alertlog.pk_alertlog.log_debug(text            => 'lang(' || i_lang || '); TRACE MSG: ' || i_msg,
                                       object_name     => g_pck_name,
                                       sub_object_name => i_func_name);
    
        COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            dbms_output.put_line('error on trace procedure: ' || g_pck_name ||
                                 '.wkflow_trace (trying to log message from: ' || g_pck_name || '.' || i_func_name || ')');
    END wkflow_trace;

    -- END ***** PRIVATE "SPECIAL" ***** Function and procedure implementations

    --*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****
    ----*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--***
    --*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****--*****

    -- Function and procedure implementations

    /********************************************************************************************
    * pk_medication_workflow.get_states_for_scope  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  I_SCOPE                         IN    NUMBER(3)
    * @param  O_STATES_CUR                    OUT   REF CURSOR
    * @param  O_ERROR                         OUT   VARCHAR2
    *
    * @return BOOLEAN
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_states_for_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN wfl_state_scope.id_scope%TYPE,
        o_states_cur OUT pk_types.cursor_type,
        o_error      OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_states_cur FOR
            SELECT a.id_state, a.state_name
              FROM wfl_state a
             WHERE a.scope = i_scope
             ORDER BY a.state_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := wkflow_log(i_lang, i_prof, 'get_states_for_scope', SQLERRM);
            pk_types.open_my_cursor(o_states_cur);
            RETURN FALSE;
    END get_states_for_scope;

    /********************************************************************************************
    * pk_medication_workflow.is_state_related  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  I_FROM_STATE                    IN    NUMBER(5)
    * @param  I_TO_STATE                      IN    NUMBER(5)
    *
    * @return BOOLEAN
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION is_state_related
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN wfl_state_relate.state%TYPE,
        i_to_state   IN wfl_state_relate.next_state%TYPE
    ) RETURN BOOLEAN IS
        l_count         NUMBER(1) := 0;
        l_transition_ok BOOLEAN := FALSE;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM wfl_state_relate a
         WHERE a.state = i_from_state
           AND a.next_state = i_to_state
           AND rownum = 1;
    
        l_transition_ok := (l_count = 1);
    
        wkflow_trace(i_lang      => i_lang,
                     i_prof      => i_prof,
                     i_func_name => 'is_state_related',
                     i_msg       => 'FROM STATE TO STATE: (' || to_char(i_from_state) || ') >>> (' ||
                                    to_char(i_to_state) || ') = ' || sys.diutil.bool_to_int(l_transition_ok));
    
        RETURN l_transition_ok;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(i_lang, i_prof, 'is_state_related', SQLERRM);
            RETURN FALSE;
    END is_state_related;

    /********************************************************************************************
    * pk_medication_workflow.get_states  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  I_FLG_TYPE                      IN    VARCHAR2
    * @param  I_GENERIC_NAME                  IN    VARCHAR2
    * @param  I_MARKET                        IN    NUMBER(24)
    *
    * @return NUMBER(5)
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_states
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN wfl_state_scope.flg_type%TYPE,
        i_generic_name IN wfl_state.generic_name%TYPE,
        i_market       IN wfl_state_scope.market%TYPE
    ) RETURN wfl_state.id_state%TYPE IS
        l_state wfl_state.id_state%TYPE;
    BEGIN
        BEGIN
            IF (i_flg_type IS NULL)
            THEN
                SELECT s.id_state
                  INTO l_state
                  FROM wfl_state s, wfl_state_scope ss
                 WHERE s.scope = ss.id_scope
                   AND ss.market = i_market
                   AND ss.flg_type IS NULL
                   AND s.generic_name = upper(i_generic_name)
                   AND rownum = 1;
            ELSE
                SELECT s.id_state
                  INTO l_state
                  FROM wfl_state s, wfl_state_scope ss
                 WHERE s.scope = ss.id_scope
                   AND ss.market = i_market
                   AND ss.flg_type = i_flg_type
                   AND s.generic_name = upper(i_generic_name)
                   AND rownum = 1;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                l_state := g_invalid_state;
        END;
    
        wkflow_trace(i_lang      => i_lang,
                     i_prof      => i_prof,
                     i_func_name => 'get_states',
                     i_msg       => 'i_flg_type=' || i_flg_type || ' i_generic_name=' || i_generic_name || ' i_market=' ||
                                    i_market);
    
        RETURN l_state;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(i_lang,
                       i_prof,
                       'get_states',
                       'i_flg_type=' || i_flg_type || ' i_generic_name=' || i_generic_name || ' i_market=' || i_market ||
                       ' err=' || SQLERRM);
            RAISE;
    END get_states;

    /********************************************************************************************
    * pk_medication_workflow.get_related_states  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  I_STATE                         IN    NUMBER(5)
    * @param  O_RELATED_STATES_CUR            OUT   REF CURSOR
    * @param  O_ERROR                         OUT   VARCHAR2
    *
    * @return BOOLEAN
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_related_states
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_state              IN wfl_state.id_state%TYPE,
        o_related_states_cur OUT pk_types.cursor_type,
        o_error              OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_related_states_cur FOR
            SELECT a.next_state id, b.state_name
              FROM wfl_state_relate a, wfl_state b
             WHERE a.next_state = b.id_state
               AND a.state = i_state
             ORDER BY b.state_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := wkflow_log(i_lang, i_prof, 'get_related_states', SQLERRM);
            pk_types.open_my_cursor(o_related_states_cur);
            RETURN FALSE;
    END get_related_states;

    /********************************************************************************************
    * pk_medication_workflow.get_scopes  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  O_SCOPES_CUR                    OUT   REF CURSOR
    * @param  O_ERROR                         OUT   VARCHAR2
    *
    * @return BOOLEAN
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_scopes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_scopes_cur OUT pk_types.cursor_type,
        o_error      OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_scopes_cur FOR
            SELECT a.id_scope, a.scope_name
              FROM wfl_state_scope a
             ORDER BY a.scope_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_error := wkflow_log(i_lang, i_prof, 'get_scopes', SQLERRM);
            pk_types.open_my_cursor(o_scopes_cur);
            RETURN FALSE;
    END get_scopes;

    /********************************************************************************************
    * pk_medication_workflow.get_actions  
    *
    * @param  I_LANG                          IN    NUMBER(6)
    * @param  I_PROF                          IN    PROFISSIONAL
    * @param  I_PROFILE                       IN    NUMBER(12)
    * @param  I_ACTIONS                       IN    TABLE_NUMBER
    * @param  O_ACTIONS                       OUT   REF CURSOR
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    PROCEDURE get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_profile IN profile_template.id_profile_template%TYPE,
        i_actions IN table_number,
        o_actions OUT pk_types.cursor_type
    ) IS
    BEGIN
        --actions
        OPEN o_actions FOR
            SELECT v3.id_action,
                   pk_translation.get_translation(i_lang, v3.code_translation) desc_action,
                   v3.icon,
                   v3.flg_type action_req_type,
                   v3.states from_state
              FROM (SELECT v4.id_action, v4.code_translation, v4.icon, v4.flg_type, pharmacy_tbl_states(v4.state) states
                      FROM (SELECT DISTINCT a.id_action, a.code_translation, a.icon, a.flg_type, sr.state
                              FROM (SELECT v1.action
                                      FROM (SELECT cpa.action
                                              FROM wfl_conf_profile_action cpa
                                             WHERE cpa.profile_templ = i_profile -- profile permissions
                                            UNION
                                            SELECT cpaa.action
                                              FROM wfl_conf_prof_action cpaa
                                             WHERE cpaa.professional = i_prof.id
                                               AND cpaa.flg_permission = 'A' --allow | professional permissions
                                            ) v1
                                    MINUS
                                    SELECT cpad.action
                                      FROM wfl_conf_prof_action cpad
                                     WHERE cpad.professional = i_prof.id
                                       AND cpad.flg_permission = 'D' --deny | professional permissions
                                    ) v2,
                                   wfl_action a,
                                   wfl_state_trans_action sta,
                                   wfl_state_relate sr
                             WHERE v2.action IN (SELECT column_value
                                                   FROM TABLE(i_actions)) --control which actions to show in diferent screens / functions
                               AND v2.action = a.id_action
                               AND a.flg_active = g_yes
                               AND a.id_action = sta.action(+)
                               AND sta.state_relation = sr.id_state_relation(+)
                               AND g_yes = sr.flg_active(+)) v4
                     GROUP BY v4.id_action, v4.code_translation, v4.icon, v4.flg_type) v3
             ORDER BY desc_action;
    
        wkflow_trace(i_lang      => i_lang,
                     i_prof      => i_prof,
                     i_func_name => 'get_actions',
                     i_msg       => 'i_profile=' || i_profile);
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(i_lang, i_prof, 'get_actions', SQLERRM);
            pk_types.open_my_cursor(o_actions);
            RAISE;
    END get_actions;

    /********************************************************************************************
    * checks if the professional has permissions to do the given action
    *
    * @param  I_LANG          Preferred language ID
    * @param  I_PROF          Professional
    * @param  I_ACTION        ID of action
    * @param  O_PERMS_OK        True if professional has permissions for the action
    * @param  O_FLG_CONF_PROF_ACTION  Flag A or D (Allow or Deny)
    * @param  O_ERROR         Error message
    *
    * @return             true or false on success or error
    *
    * @author Rui Marante
    * @version  0.1
    * @since  2009/01/08
    *********************************************************************************************/
    /*
    -- deprecated!
      procedure check_action_perms_for_prof
      (
        i_lang          in language.id_language%type,
        i_prof          in profissional,
        i_action        in wfl_conf_prof_action.action%type,
        o_perms_ok        out boolean,
        o_flg_conf_prof_action  out wfl_conf_prof_action.flg_permission%type,
        o_error         out varchar2
      ) is
        l_prof_category category.id_category%type;
        l_cat_perm_ok number(1) := 0;
        l_perm_allow  wfl_conf_prof_action.flg_permission%type := 'A'; --Allow
      begin
        o_perms_ok := false;
        o_flg_conf_prof_action := null;
    
        --check perms on wfl_conf_prof_action
        begin
          select a.flg_permission
          into o_flg_conf_prof_action
          from wfl_conf_prof_action a
          where a.action = i_action
            and a.professional = i_prof.id;
    
          o_perms_ok := (o_flg_conf_prof_action = l_perm_allow);
        exception
          when no_data_found then
            --the professional has no special permissions defined
            o_flg_conf_prof_action := null;
        end;
        
        if (o_flg_conf_prof_action is null) then
          begin
            --get prof category
            select a.id_category
            into l_prof_category
            from prof_cat a
            where a.id_professional = i_prof.id
              and a.id_institution = i_prof.institution;
              
            -- ******** falta acabar isto
            
            -- select *
            -- from wfl_conf_profile_action;
            
            -- ...
            
            -- o_perms_ok := (l_cat_perm_ok = 1);
    
          exception
            when no_data_found then
              --prof category not found
              null;
          end;
        end if;
    
        wkflow_trace(
            i_lang    => i_lang,
            i_prof    => i_prof,
            i_func_name => 'check_action_perms_for_prof',
            i_msg   => 'i_action=' || i_action || ' o_perms_ok=' || sys.diutil.bool_to_int(o_perms_ok));
    
      exception
        when others then
          o_perms_ok := false;
          o_flg_conf_prof_action := null;
          o_error := wkflow_log(i_lang, i_prof, 'check_action_perms_for_prof', SQLERRM);
                raise;
      end check_action_perms_for_prof;
    */

    /********************************************************************************************
    * pk_medication_workflow.get_id_state_from_old_flag  
    *
    * @param  I_SCOPE                         IN    NUMBER(3)
    * @param  I_OLD_FLAG                      IN    VARCHAR2
    *
    * @return VARCHAR2
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_id_state_from_old_flag
    (
        i_scope    IN wfl_state_scope.id_scope%TYPE,
        i_old_flag IN wfl_state.old_flg%TYPE
    ) RETURN VARCHAR2 IS
        l_id_state wfl_state.id_state%TYPE;
    BEGIN
        SELECT a.id_state
          INTO l_id_state
          FROM wfl_state a
         WHERE a.scope = i_scope
           AND a.old_flg = i_old_flag
           AND rownum = 1;
    
        RETURN l_id_state;
    
    EXCEPTION
        WHEN no_data_found THEN
            wkflow_log(0, profissional(0, 0, 0), 'get_id_state_from_old_flag', 'no_data_found');
            RETURN NULL;
        WHEN OTHERS THEN
            wkflow_log(0, profissional(0, 0, 0), 'get_id_state_from_old_flag', SQLERRM);
            RAISE;
    END get_id_state_from_old_flag;

    /********************************************************************************************
    * pk_medication_workflow.get_old_flag_from_state_id  
    *
    * @param  I_ID_STATE                      IN    NUMBER(5)
    *
    * @return VARCHAR2
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-06-19
    *
    ********************************************************************************************/
    FUNCTION get_old_flag_from_state_id(i_id_state IN wfl_state.id_state%TYPE) RETURN VARCHAR2 IS
        l_old_flag wfl_state.old_flg%TYPE;
    BEGIN
        SELECT a.old_flg
          INTO l_old_flag
          FROM wfl_state a
         WHERE a.id_state = i_id_state;
    
        RETURN l_old_flag;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(0, profissional(0, 0, 0), 'get_old_flag_from_state_id', SQLERRM);
            RAISE;
    END get_old_flag_from_state_id;

    /********************************************************************************************
    * pk_medication_workflow.get_state_translation  
    *
    * @param  I_LANG                          IN        NUMBER(6)
    * @param  I_ID_STATE                      IN        NUMBER(24)
    * @param  I_FLG_COMPLETE_TRANSL           IN        VARCHAR2
    *
    * @return VARCHAR2
    *
    * @author Rui Marante
    * @version  2.5.0.7.7.2
    * @since  2010-05-21
    *
    * @notes  
    *
    ********************************************************************************************/
    FUNCTION get_state_translation
    (
        i_lang                IN language.id_language%TYPE,
        i_id_state            IN wfl_state.id_state%TYPE,
        i_flg_complete_transl IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_transl pk_translation.t_desc_translation := NULL;
    BEGIN
        IF (i_flg_complete_transl = g_yes)
        THEN
            SELECT pk_translation.get_translation(i_lang, s.code_state_detail)
              INTO l_transl
              FROM wfl_state s
             WHERE s.id_state = i_id_state;
        ELSE
            SELECT pk_translation.get_translation(i_lang, s.code_state)
              INTO l_transl
              FROM wfl_state s
             WHERE s.id_state = i_id_state;
        END IF;
    
        RETURN l_transl;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(i_lang, profissional(0, 0, 0), 'get_state_translation', SQLERRM);
            RETURN NULL;
    END get_state_translation;

    --***************************************************************************************

    -- ***** CONFIGURATION FUNCTIONS!!!!!!!! *****

    /********************************************************************************************
    * pk_medication_workflow.conf_prep_without_validation  
    *
    * @param  I_ID_MARKET                     IN    NUMBER(24)
    * @param  I_SET_ON                        IN    VARCHAR2
    * @param  I_FLG_TYPE                      IN    VARCHAR2
    *
    * @author Rui Marante
    * @version  1.0
    * @since  2009-09-18
    *
    ********************************************************************************************/
    PROCEDURE conf_prep_without_validation
    (
        i_id_market IN market.id_market%TYPE,
        i_set_on    IN VARCHAR2 DEFAULT 'N', -- Y - activate  || N - deactivate
        i_flg_type  IN VARCHAR2 -- A | I | U 
    ) IS
        l_updated_rows NUMBER := 0;
        l_rows_total   NUMBER := 0;
        l_prof         profissional := profissional(0, 0, 0); --dummy prof
        l_lang         language.id_language%TYPE := 1; --dummy PT 
    BEGIN
        wkflow_trace(l_lang,
                     l_prof,
                     'conf_prep_without_validation',
                     'PARAMS: i_id_market=' || to_char(i_id_market) || ';i_set_on=' || i_set_on || '; i_flg_type=' ||
                     i_flg_type || ';');
    
        IF (i_set_on IN (g_yes, g_no))
        THEN
        
            --request > prepare > transport
            UPDATE wfl_state_relate a
               SET a.flg_active = i_set_on
             WHERE a.flg_active != i_set_on
               AND ((a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REQUESTED_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_EXECUTING_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REQUESTED_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_TERMINATED_ST', i_id_market)))
            RETURNING COUNT(1) INTO l_updated_rows;
        
            l_rows_total := l_updated_rows;
        
            --request > validate > prepare > validate (or reject) > transport
            UPDATE wfl_state_relate a
               SET a.flg_active = decode(i_set_on, g_yes, g_no, g_yes)
             WHERE a.flg_active != decode(i_set_on, g_yes, g_no, g_yes)
               AND ((a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REJECTED2PHARM_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_VALIDATED_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REJECTED2PHARM_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_WAITING_APPROV_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REJECTED2PHARM_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_VALIDATED_SIGN_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REQUESTED_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_VALIDATED_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REQUESTED_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_WAITING_APPROV_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_REQUESTED_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, i_flg_type, 'G_DRD_VALIDATED_SIGN_ST', i_id_market)) OR
                   (a.state = get_states(l_lang, l_prof, NULL, 'G_DRS_READYFORVALID_ST', i_id_market) AND
                   a.next_state = get_states(l_lang, l_prof, NULL, 'G_DRS_READYFORTRANSP_ST', i_id_market)))
            RETURNING COUNT(1) INTO l_updated_rows;
        
            l_rows_total := l_rows_total + l_updated_rows;
        
            wkflow_trace(l_lang,
                         l_prof,
                         'conf_prep_without_validation',
                         'ROWS UPDATED=' || to_char(l_rows_total) || ';');
        ELSE
            raise_application_error(-20001, 'INVALID PARAMETER: i_set_on has an invalid value! allowed values: Y | N');
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(l_lang, l_prof, 'conf_prep_without_validation', SQLERRM);
            RAISE;
    END conf_prep_without_validation;

    /********************************************************************************************
    * pk_medication_workflow.conf_default_workflow  
    *
    * @param  I_ID_MARKET                     IN    NUMBER(24)
    * @param  I_ID_DEFAULT_MARKET             IN    NUMBER(24)
    * @param  I_FORCE_UPDATE                  IN    VARCHAR2
    *
    * @author Rui Marante
    * @version  2.5.0.7.4
    * @since  2009-12-09
    *
    ********************************************************************************************/
    PROCEDURE conf_default_workflow
    (
        i_id_market         IN market.id_market%TYPE,
        i_id_default_market IN market.id_market%TYPE DEFAULT 1, --PT
        i_force_update      IN VARCHAR2 DEFAULT 'N' -- Y = force update of the workflow
    ) IS
        l_prof profissional := profissional(0, 0, 0); --dummy prof
        l_lang language.id_language%TYPE := 1; --dummy PT 
    
        l_scope_check       NUMBER(1) := 0;
        l_next_scope        wfl_state_scope.id_scope%TYPE;
        l_next_state        wfl_state.id_state%TYPE;
        l_next_state_relate wfl_state_relate.id_state_relation%TYPE;
    
        l_scope_delta        NUMBER;
        l_state_delta        NUMBER;
        l_state_delta2       NUMBER;
        l_state_relate_delta NUMBER;
    
        l_default_market wfl_state_scope.market%TYPE; --PT (PT market is used as default)
        l_force_update   VARCHAR2(1 CHAR) := 'N';
        l_upd_scope      wfl_state_scope.id_scope%TYPE;
        l_record_found   wfl_state.id_state%TYPE := NULL;
        l_from_state     wfl_state.id_state%TYPE := NULL;
        l_to_state       wfl_state.id_state%TYPE := NULL;
    
        --
        CURSOR scopes(i_market IN wfl_state_scope.market%TYPE) IS
            SELECT a.id_scope, a.scope_name, a.flg_type
              FROM wfl_state_scope a
             WHERE a.market = i_market
             ORDER BY a.id_scope;
    
        r_scope scopes%ROWTYPE;
    
        CURSOR states(i_scope IN wfl_state.scope%TYPE) IS
            SELECT a.id_state,
                   a.state_name,
                   a.state_desc,
                   a.flg_active,
                   a.old_flg,
                   a.code_state,
                   a.code_state_detail,
                   a.generic_name
              FROM wfl_state a
             WHERE a.scope = i_scope
             ORDER BY a.id_state;
    
        r_state states%ROWTYPE;
    
        CURSOR state_relations(i_scope IN wfl_state.scope%TYPE) IS
            SELECT wsr.id_state_relation,
                   wsr.flg_active,
                   wsr.rank,
                   ws1.generic_name      generic_name1,
                   ws2.generic_name      generic_name2
              FROM wfl_state_relate wsr
              LEFT JOIN wfl_state ws1
                ON (wsr.state = ws1.id_state)
              LEFT JOIN wfl_state ws2
                ON (wsr.next_state = ws2.id_state)
             WHERE ws1.scope = i_scope
                OR ws2.scope = i_scope
             ORDER BY wsr.id_state_relation;
    
        r_state_relation state_relations%ROWTYPE;
    
        CURSOR state_trans_actions(i_scope IN wfl_state.scope%TYPE) IS
            SELECT wsta.action, ws1.generic_name generic_name1, ws2.generic_name generic_name2
              FROM wfl_state_trans_action wsta
             INNER JOIN wfl_state_relate wsr
                ON (wsta.state_relation = wsr.id_state_relation)
              LEFT JOIN wfl_state ws1
                ON (wsr.state = ws1.id_state)
              LEFT JOIN wfl_state ws2
                ON (wsr.next_state = ws2.id_state)
             WHERE ws1.scope = i_scope
                OR ws2.scope = i_scope
             ORDER BY wsta.state_relation;
    
        r_state_trans_action state_trans_actions%ROWTYPE;
        --
    
        PROCEDURE clear_scope(i2_scope IN wfl_state_scope.id_scope%TYPE) IS
            l_row_count NUMBER := 0;
        BEGIN
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'BEGIN CLEAR SCOPE: scope=' || i2_scope);
            UPDATE wfl_state ws
               SET ws.flg_active = g_no
             WHERE ws.scope = i2_scope
            RETURNING COUNT(1) INTO l_row_count;
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'UPDATE WFL_STATE: ROWS=' || l_row_count);
        
            DELETE FROM wfl_state_detail wsd
             WHERE wsd.state IN (SELECT ws.id_state
                                   FROM wfl_state ws
                                  WHERE ws.scope = i2_scope)
            RETURNING COUNT(1) INTO l_row_count;
        
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'DELETE WFL_STATE_DETAIL: ROWS=' || l_row_count);
            DELETE FROM wfl_state_trans_action wsta
             WHERE wsta.state_relation IN (SELECT wsr.id_state_relation
                                             FROM wfl_state_relate wsr
                                            INNER JOIN wfl_state ws
                                               ON (wsr.state = ws.id_state)
                                            WHERE ws.scope = i2_scope
                                           UNION ALL
                                           SELECT wsr.id_state_relation
                                             FROM wfl_state_relate wsr
                                            INNER JOIN wfl_state ws
                                               ON (wsr.next_state = ws.id_state)
                                            WHERE ws.scope = i2_scope)
            RETURNING COUNT(1) INTO l_row_count;
            wkflow_trace(l_lang,
                         l_prof,
                         'CONF_DEFAULT_WORKFLOW',
                         'DELETE WFL_STATE_TRANS_ACTION: ROWS=' || l_row_count);
            DELETE FROM wfl_state_relate wsr1
             WHERE wsr1.id_state_relation IN (SELECT wsr.id_state_relation
                                                FROM wfl_state_relate wsr
                                               INNER JOIN wfl_state ws
                                                  ON (wsr.state = ws.id_state)
                                               WHERE ws.scope = i2_scope
                                              UNION ALL
                                              SELECT wsr.id_state_relation
                                                FROM wfl_state_relate wsr
                                               INNER JOIN wfl_state ws
                                                  ON (wsr.next_state = ws.id_state)
                                               WHERE ws.scope = i2_scope)
            RETURNING COUNT(1) INTO l_row_count;
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'DELETE WFL_STATE_RELATE: ROWS=' || l_row_count);
        
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'END CLEAR SCOPE: SCOPE=' || i2_scope);
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE;
        END clear_scope;
    
        FUNCTION get_state_id
        (
            i_scope              IN wfl_state.scope%TYPE,
            i_generic_state_name IN wfl_state.generic_name%TYPE
        ) RETURN wfl_state.id_state%TYPE IS
            l_state_id wfl_state.id_state%TYPE := NULL;
        BEGIN
            IF (i_generic_state_name IS NOT NULL)
            THEN
                SELECT ws.id_state
                  INTO l_state_id
                  FROM wfl_state ws
                 WHERE ws.scope = i_scope
                   AND ws.generic_name = i_generic_state_name;
            END IF;
        
            RETURN l_state_id;
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE;
        END get_state_id;
    
        FUNCTION get_state_relation_id
        (
            i_scope               IN wfl_state.scope%TYPE,
            i_generic_state_name1 IN wfl_state.generic_name%TYPE,
            i_generic_state_name2 IN wfl_state.generic_name%TYPE
        ) RETURN wfl_state_relate.id_state_relation%TYPE IS
            l_relation_id wfl_state_relate.id_state_relation%TYPE;
        BEGIN
            IF (i_generic_state_name1 IS NULL)
            THEN
                SELECT wsr.id_state_relation
                  INTO l_relation_id
                  FROM wfl_state_relate wsr
                 INNER JOIN wfl_state ws
                    ON (wsr.next_state = ws.id_state)
                 WHERE wsr.state IS NULL
                   AND ws.scope = i_scope
                   AND ws.generic_name = i_generic_state_name2;
            ELSE
                SELECT wsr.id_state_relation
                  INTO l_relation_id
                  FROM wfl_state_relate wsr
                 INNER JOIN wfl_state ws1
                    ON (wsr.state = ws1.id_state)
                 INNER JOIN wfl_state ws2
                    ON (wsr.next_state = ws2.id_state)
                 WHERE ws1.scope = i_scope
                   AND ws1.generic_name = i_generic_state_name1
                   AND ws2.scope = i_scope
                   AND ws2.generic_name = i_generic_state_name2;
            END IF;
        
            RETURN l_relation_id;
        
        EXCEPTION
            WHEN OTHERS THEN
                RAISE;
        END get_state_relation_id;
        --
    BEGIN
        l_default_market := i_id_default_market;
        l_force_update   := i_force_update;
    
        wkflow_trace(l_lang,
                     l_prof,
                     'CONF_DEFAULT_WORKFLOW',
                     'PARAMS: i_id_market=' || to_char(i_id_market) || '; i_id_default_market=' ||
                     to_char(i_id_default_market) || '; l_force_update=' || l_force_update || ';');
    
        SELECT COUNT(1)
          INTO l_scope_check
          FROM wfl_state_scope a
         WHERE a.market = i_id_market
           AND rownum = 1;
    
        IF (l_scope_check > 0)
        THEN
            IF (l_force_update = g_yes)
            THEN
                wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'FORCE UPDATE OF THE WORKFLOW!');
            ELSE
                raise_application_error(-20001, 'WORKFLOW FOR MARKET=' || to_char(i_id_market) || ' ALREADY EXISTS!');
            END IF;
        ELSE
            l_force_update := g_no;
        END IF;
    
        IF (l_force_update = g_no)
        THEN
        
            SELECT MAX(a.id_scope)
              INTO l_next_scope
              FROM wfl_state_scope a;
        
            l_scope_delta := l_next_scope + 200; --lag 200
        
            --WFL_STATE_SCOPE
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'WFL_STATE_SCOPE');
        
            INSERT INTO wfl_state_scope
                (id_scope, scope_name, market, flg_type)
                SELECT id_scope + l_scope_delta,
                       REPLACE(scope_name, '_' || i_id_default_market, '') || '_' || i_id_market,
                       i_id_market,
                       flg_type
                  FROM wfl_state_scope a
                 WHERE a.market = l_default_market
                 ORDER BY a.id_scope;
        
            SELECT MAX(a.id_state)
              INTO l_next_state
              FROM wfl_state a;
        
            l_state_delta := l_next_state + 1000; --lag 1000
        
            --WFL_STATE
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'WFL_STATE');
        
            INSERT INTO wfl_state
                (id_state,
                 state_name,
                 state_desc,
                 flg_active,
                 scope,
                 old_flg,
                 code_state,
                 code_state_detail,
                 generic_name)
                SELECT a.id_state + l_state_delta,
                       a.state_name,
                       a.state_desc,
                       a.flg_active,
                       a.scope + l_scope_delta,
                       a.old_flg,
                       a.code_state,
                       a.code_state_detail,
                       a.generic_name
                  FROM wfl_state a
                 WHERE a.scope IN (SELECT b.id_scope
                                     FROM wfl_state_scope b
                                    WHERE b.market = l_default_market)
                 ORDER BY a.id_state;
        
            --WFL_STATE_DETAIL
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'WFL_STATE_DETAIL');
        
            INSERT INTO wfl_state_detail
                (state,
                 prof_type,
                 icon_name,
                 icon_type,
                 icon_color,
                 icon_bg_color,
                 flg_color,
                 grid_timeout,
                 rank,
                 state_can_be_delayed)
                SELECT a.state + l_state_delta,
                       a.prof_type,
                       a.icon_name,
                       a.icon_type,
                       a.icon_color,
                       a.icon_bg_color,
                       a.flg_color,
                       a.grid_timeout,
                       a.rank,
                       a.state_can_be_delayed
                  FROM wfl_state_detail a
                 WHERE a.state IN (SELECT b.id_state
                                     FROM wfl_state b, wfl_state_scope c
                                    WHERE b.scope = c.id_scope
                                      AND c.market = l_default_market);
        
            SELECT MAX(a.id_state_relation)
              INTO l_next_state_relate
              FROM wfl_state_relate a;
        
            l_state_relate_delta := l_next_state_relate + 2000; --lag 2000
        
            --WFL_STATE_RELATE
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'WFL_STATE_RELATE');
        
            INSERT INTO wfl_state_relate
                (id_state_relation, state, next_state, flg_active, rank)
                SELECT a.id_state_relation + l_state_relate_delta,
                       a.state + l_state_delta,
                       a.next_state + l_state_delta,
                       a.flg_active,
                       a.rank
                  FROM wfl_state_relate a
                 WHERE a.state IN (SELECT b.id_state
                                     FROM wfl_state b, wfl_state_scope c
                                    WHERE b.scope = c.id_scope
                                      AND c.market = l_default_market)
                 ORDER BY a.id_state_relation;
        
            --WFL_STATE_TRANS_ACTION
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'WFL_STATE_TRANS_ACTION');
        
            INSERT INTO wfl_state_trans_action
                (state_relation, action)
                SELECT a.state_relation + l_state_relate_delta, a.action
                  FROM wfl_state_trans_action a
                 WHERE a.state_relation IN (SELECT b.id_state_relation
                                              FROM wfl_state_relate b, wfl_state c, wfl_state_scope d
                                             WHERE b.state = c.id_state
                                               AND c.scope = d.id_scope
                                               AND d.market = l_default_market);
        
        ELSIF (l_force_update = g_yes)
        THEN
        
            SELECT MAX(wsr.id_state_relation) + 2000
              INTO l_next_state_relate
              FROM wfl_state_relate wsr;
        
            l_state_delta2 := 1000;
        
            OPEN scopes(l_default_market);
            LOOP
                FETCH scopes
                    INTO r_scope;
                EXIT WHEN scopes%NOTFOUND;
            
                SELECT wsc.id_scope
                  INTO l_upd_scope
                  FROM wfl_state_scope wsc
                 WHERE wsc.market = i_id_market
                   AND REPLACE(wsc.scope_name, '_' || i_id_market, '') =
                       REPLACE(r_scope.scope_name, '_' || l_default_market, '');
                wkflow_trace(l_lang,
                             l_prof,
                             'CONF_DEFAULT_WORKFLOW',
                             'FORCE SCOPE: default_scope=' || r_scope.id_scope || '; new_scope=' || l_upd_scope);
            
                clear_scope(i2_scope => l_upd_scope);
            
                OPEN states(r_scope.id_scope);
                LOOP
                    FETCH states
                        INTO r_state;
                    EXIT WHEN states%NOTFOUND;
                    wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', 'FORCE STATE:' || r_state.generic_name);
                
                    l_record_found := NULL;
                
                    UPDATE wfl_state ws
                       SET ws.state_name        = r_state.state_name,
                           ws.state_desc        = r_state.state_desc,
                           ws.flg_active        = r_state.flg_active,
                           ws.old_flg           = r_state.old_flg,
                           ws.code_state        = r_state.code_state,
                           ws.code_state_detail = r_state.code_state_detail
                     WHERE ws.scope = l_upd_scope
                       AND ws.generic_name = r_state.generic_name
                    RETURNING ws.id_state INTO l_record_found;
                    wkflow_trace(l_lang,
                                 l_prof,
                                 'CONF_DEFAULT_WORKFLOW',
                                 'FORCE STATE UPDATED: l_record_found=' || l_record_found);
                
                    IF (l_record_found IS NULL)
                    THEN
                        --row not found, so insert
                    
                        SELECT MAX(ws.id_state) + l_state_delta2
                          INTO l_state_delta
                          FROM wfl_state ws;
                        --where ws.scope = r_scope.id_scope;
                    
                        --WFL_STATE
                        INSERT INTO wfl_state
                            (id_state,
                             state_name,
                             state_desc,
                             flg_active,
                             scope,
                             old_flg,
                             code_state,
                             code_state_detail,
                             generic_name)
                            SELECT l_state_delta,
                                   a.state_name,
                                   a.state_desc,
                                   a.flg_active,
                                   l_upd_scope,
                                   a.old_flg,
                                   a.code_state,
                                   a.code_state_detail,
                                   a.generic_name
                              FROM wfl_state a
                             WHERE a.id_state = r_state.id_state;
                    
                        l_record_found := l_state_delta;
                    
                        l_state_delta2 := 1;
                        wkflow_trace(l_lang,
                                     l_prof,
                                     'CONF_DEFAULT_WORKFLOW',
                                     'FORCE STATE NOT FOUND:' || r_state.generic_name || ' new id:' || l_state_delta);
                    END IF;
                
                    --WFL_STATE_DETAIL
                    INSERT INTO wfl_state_detail
                        (state,
                         prof_type,
                         icon_name,
                         icon_type,
                         icon_color,
                         icon_bg_color,
                         flg_color,
                         grid_timeout,
                         rank,
                         state_can_be_delayed)
                        SELECT l_record_found,
                               a.prof_type,
                               a.icon_name,
                               a.icon_type,
                               a.icon_color,
                               a.icon_bg_color,
                               a.flg_color,
                               a.grid_timeout,
                               a.rank,
                               a.state_can_be_delayed
                          FROM wfl_state_detail a
                         WHERE a.state = r_state.id_state;
                
                END LOOP; --states
                CLOSE states;
            
                --WFL_STATE_RELATE
                OPEN state_relations(r_scope.id_scope);
                LOOP
                    FETCH state_relations
                        INTO r_state_relation;
                    EXIT WHEN state_relations%NOTFOUND;
                
                    l_from_state := get_state_id(l_upd_scope, r_state_relation.generic_name1);
                    l_to_state   := get_state_id(l_upd_scope, r_state_relation.generic_name2);
                
                    INSERT INTO wfl_state_relate
                        (id_state_relation, state, next_state, flg_active, rank)
                    VALUES
                        (l_next_state_relate,
                         l_from_state,
                         l_to_state,
                         r_state_relation.flg_active,
                         r_state_relation.rank);
                
                    wkflow_trace(l_lang,
                                 l_prof,
                                 'CONF_DEFAULT_WORKFLOW',
                                 'FORCE RELATION: l_from_state=' || l_from_state || ' l_to_state=' || l_to_state ||
                                 ' l_next_state_relate=' || l_next_state_relate);
                
                    l_next_state_relate := l_next_state_relate + 1;
                
                END LOOP; --state relations
                CLOSE state_relations;
            
                OPEN state_trans_actions(r_scope.id_scope);
                LOOP
                    FETCH state_trans_actions
                        INTO r_state_trans_action;
                    EXIT WHEN state_trans_actions%NOTFOUND;
                
                    l_state_relate_delta := get_state_relation_id(l_upd_scope,
                                                                  r_state_trans_action.generic_name1,
                                                                  r_state_trans_action.generic_name2);
                
                    INSERT INTO wfl_state_trans_action
                        (state_relation, action)
                    VALUES
                        (l_state_relate_delta, r_state_trans_action.action);
                
                    wkflow_trace(l_lang,
                                 l_prof,
                                 'CONF_DEFAULT_WORKFLOW',
                                 'FORCE TRANS ACTION: l_state_relate_delta=' || l_state_relate_delta || ' action=' ||
                                 r_state_trans_action.action);
                
                END LOOP;
                CLOSE state_trans_actions;
            
            END LOOP; --scopes
            CLOSE scopes;
            wkflow_trace(l_lang, l_prof, 'CONF_DEFAULT_WORKFLOW', '***** END - OK! *****');
        ELSE
            raise_application_error(-20001, 'NO WORK DONE!');
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            wkflow_log(l_lang, l_prof, 'conf_default_workflow', SQLERRM);
            RAISE;
    END conf_default_workflow;

--***************************************************************************************
BEGIN
    -- Initialization
    NULL;

END pk_medication_workflow;
/
