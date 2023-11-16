/*-- Last Change Revision: $Rev: 1696220 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2015-05-04 12:11:26 +0100 (seg, 04 mai 2015) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_cdr_in IS

    g_error        VARCHAR2(1000 CHAR);
    g_owner        VARCHAR2(30 CHAR);
    g_package      VARCHAR2(30 CHAR);
    g_debug_enable BOOLEAN;
    g_exception EXCEPTION;

    /**
    * Get warning answers.
    * Information is retrieved from local workflow engine.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    * @param o_answers      answers cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/26
    */
    FUNCTION get_warning_answers
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_answers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_WARNING_ANSWERS';
        l_profile      profile_template.id_profile_template%TYPE;
        l_category     category.id_category%TYPE;
        l_actions      table_number;
        l_workflows    table_number;
        l_status_begin wf_status.id_status%TYPE;
        l_trans_tmp    t_coll_wf_transition;
        l_transitions  t_coll_wf_transition := t_coll_wf_transition();
        l_reason       VARCHAR2(4000);
    
        CURSOR c_act IS
            SELECT cdra.id_cdr_action, cdra.id_workflow
              FROM cdr_action cdra
             WHERE cdra.flg_available = pk_alert_constant.g_yes
               AND cdra.flg_warning = pk_alert_constant.g_yes
               AND cdra.id_workflow IS NOT NULL
             ORDER BY cdra.rank;
    BEGIN
        l_profile  := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        l_reason   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'GES_CDR_DIAG_T001');
    
        -- get action information
        g_error := 'OPEN c_act';
        OPEN c_act;
        FETCH c_act BULK COLLECT
            INTO l_actions, l_workflows;
        CLOSE c_act;
    
        FOR i IN 1 .. l_actions.count
        LOOP
            -- debug current workflow
            IF g_debug_enable
            THEN
                g_error := 'l_workflows(' || i || '): ' || l_workflows(i);
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            END IF;
        
            -- get begin status
            g_error := 'CALL pk_workflow.get_status_begin';
            IF NOT pk_workflow.get_status_begin(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_workflow  => l_workflows(i),
                                                o_status_begin => l_status_begin,
                                                o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- debug current begin status
            IF g_debug_enable
            THEN
                g_error := 'l_status_begin: ' || l_status_begin;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            END IF;
        
            -- get transitions
            g_error := 'CALL pk_workflow.get_transitions';
            IF NOT pk_workflow.get_transitions(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_workflow         => l_workflows(i),
                                               i_id_status_begin     => l_status_begin,
                                               i_id_category         => l_category,
                                               i_id_profile_template => l_profile,
                                               i_id_functionality    => NULL,
                                               i_param               => NULL,
                                               i_flg_auto_transition => NULL,
                                               o_transitions         => l_trans_tmp,
                                               o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_transitions := l_transitions MULTISET UNION ALL l_trans_tmp;
        END LOOP;
    
        g_error := 'OPEN o_actions';
        OPEN o_actions FOR
            SELECT cdra.id_cdr_action cdr_action_id,
                   cdra.flg_answer_notes action_notes_flg,
                   pk_message.get_message(i_lang, i_prof, cdra.code_answer_notes) action_notes_label
              FROM cdr_action cdra
             WHERE cdra.flg_available = pk_alert_constant.g_yes
               AND cdra.flg_warning = pk_alert_constant.g_yes
             ORDER BY cdra.rank;
    
        g_error := 'OPEN o_answers';
        OPEN o_answers FOR
            SELECT /*+dynamic_sampling(wts 2)*/
             row_number() over(ORDER BY cdra.id_cdr_action, wts.rank, cdraw.rank) id,
             cdra.id_cdr_action cdr_action_id,
             cdraw.id_cdr_answer answer_id,
             wts.desc_transition answer_label,
             cdraw.flg_req_notes answer_requires_notes,
             --
             cdra.id_cdr_action,
             wts.rank wts_rank,
             cdraw.rank cdraw_rank,
             pk_sysdomain.get_domain_val(i_lang => i_lang, i_code_domain => cdraw.code_domain) domain_val,
             pk_sysdomain.get_domain_desc(i_lang => i_lang, i_code_domain => cdraw.code_domain) domain_desc,
             cdraw.flg_other_domain flg_other_domain,
             l_reason domain_label
              FROM TABLE(l_transitions) wts
              JOIN cdr_answer cdraw
                ON wts.id_workflow = cdraw.id_workflow
               AND wts.id_status_begin = cdraw.id_status_begin
               AND wts.id_workflow_action = cdraw.id_workflow_action
               AND wts.id_status_end = cdraw.id_status_end
              JOIN cdr_action cdra
                ON wts.id_workflow = cdra.id_workflow
             WHERE wts.flg_visible = pk_alert_constant.g_yes
             ORDER BY cdra.id_cdr_action, wts.rank, cdraw.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_warning_answers;

BEGIN
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
    g_debug_enable := pk_alertlog.is_debug_enabled(i_object_name => g_package);
END pk_api_cdr_in;
/
