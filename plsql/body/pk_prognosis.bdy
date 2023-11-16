/*-- Last Change Revision: $Rev: 2054556 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-13 14:57:54 +0000 (sex, 13 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_prognosis IS

    FUNCTION set_epis_prognosis_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_EPIS_PROGNOSIS_HIST';
    
        l_epis_prognosis_hist_tc ts_epis_prognosis_hist.epis_prognosis_hist_tc;
    BEGIN
    
        g_error := 'GET EPIS_PROGNOSIS WITH ID_EPIS_PROGNOSIS ' || i_id_epis_prognosis;
        pk_alertlog.log_debug(g_error);
    
        SELECT ts_epis_prognosis_hist.next_key,
               g_sysdate_tstz,
               id_epis_prognosis,
               id_episode,
               flg_status,
               prognosis_notes,
               id_prof_create,
               dt_create,
               id_prof_last_update,
               dt_last_update,
               id_prof_cancel,
               id_cancel_reason,
               cancel_notes,
               dt_cancel,
               create_user,
               create_time,
               create_institution,
               update_user,
               update_time,
               update_institution,
               ep.id_prognosis
          BULK COLLECT
          INTO l_epis_prognosis_hist_tc
          FROM epis_prognosis ep
         WHERE ep.id_epis_prognosis = i_id_epis_prognosis;
    
        g_error := 'INSERT EPIS_PROGNOSIS_HIST ROW';
        pk_alertlog.log_debug(g_error);
        ts_epis_prognosis_hist.ins(rows_in => l_epis_prognosis_hist_tc, handle_error_in => TRUE);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_epis_prognosis_hist;

    FUNCTION set_epis_prognosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        i_id_prognosis      IN epis_prognosis.id_prognosis%TYPE,
        i_prognosis_notes   IN epis_prognosis.prognosis_notes%TYPE,
        o_id_epis_prognosis OUT epis_prognosis.id_epis_prognosis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_EPIS_PROGNOSIS';
    
        l_rowids  table_varchar;
        l_next_ep epis_prognosis.id_epis_prognosis%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_epis_prognosis IS NULL
        THEN
            l_next_ep := ts_epis_prognosis.next_key;
        
            g_error := 'CALL TS_EPIS_PROGNOSIS.INS WITH ID_EPIS_PROGNOSIS ' || l_next_ep;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_epis_prognosis.ins(id_epis_prognosis_in => l_next_ep,
                                  id_episode_in        => i_episode,
                                  flg_status_in        => g_status_active,
                                  id_prognosis_in      => i_id_prognosis,
                                  prognosis_notes_in   => i_prognosis_notes,
                                  id_prof_create_in    => i_prof.id,
                                  dt_create_in         => g_sysdate_tstz,
                                  --  handle_error_in      => TRUE,
                                  rows_out => l_rowids);
        
            g_error := 'PROCESS INSERT WITH ID_EPIS_PROGNOSIS ' || l_next_ep;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_PROGNOSIS', l_rowids, o_error);
        
            o_id_epis_prognosis := l_next_ep;
        ELSE
            g_error := 'CALL SET_EPIS_PROGNOSIS_HIST WITH ID_EPIS_PROGNOSIS ' || i_id_epis_prognosis;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_prognosis_hist(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_id_epis_prognosis => i_id_epis_prognosis,
                                           o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL TS_EPIS_PROGNOSIS.UPD WITH ID_EPIS_PROGNOSIS ' || i_id_epis_prognosis;
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_epis_prognosis.upd(id_epis_prognosis_in   => i_id_epis_prognosis,
                                  id_prognosis_in        => i_id_prognosis,
                                  prognosis_notes_in     => i_prognosis_notes,
                                  prognosis_notes_nin    => FALSE,
                                  id_prof_last_update_in => i_prof.id,
                                  dt_last_update_in      => g_sysdate_tstz,
                                  handle_error_in        => TRUE,
                                  rows_out               => l_rowids);
        
            g_error := 'PROCESS UPDATE WITH EPIS_PROGNOSIS ' || i_id_epis_prognosis;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_PROGNOSIS', l_rowids, o_error);
        
            o_id_epis_prognosis := i_id_epis_prognosis;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        
    END set_epis_prognosis;

    FUNCTION cancel_epis_prognosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_prognosis.cancel_notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_EPIS_PROGNOSIS';
        l_rowids table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL SET_EPIS_PROGNOSIS_HIST WITH ID_EPIS_PROGNOSIS ' || i_id_epis_prognosis;
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_prognosis_hist(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_id_epis_prognosis => i_id_epis_prognosis,
                                       o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL TS_EPIS_PROGNOSIS.UPD WITH ID_EPIS_PROGNOSIS ' || i_id_epis_prognosis;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_prognosis.upd(id_epis_prognosis_in => i_id_epis_prognosis,
                              flg_status_in        => g_status_cancelled,
                              id_prof_cancel_in    => i_prof.id,
                              id_prof_cancel_nin   => FALSE,
                              dt_cancel_in         => g_sysdate_tstz,
                              id_cancel_reason_in  => i_id_cancel_reason,
                              id_cancel_reason_nin => FALSE,
                              cancel_notes_in      => i_notes_cancel,
                              handle_error_in      => TRUE,
                              rows_out             => l_rowids);
    
        g_error := 'PROCESS UPDATE WITH EPIS_PROGNOSIS ' || i_id_epis_prognosis;
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_PROGNOSIS', l_rowids, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_epis_prognosis;

    FUNCTION get_prognosis_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_epis_prognosis    OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_epis_prognosis FOR
            SELECT ep.id_epis_prognosis,
                   ep.id_prognosis,
                   pk_multichoice.get_multichoice_option_desc(i_lang, i_prof, ep.id_prognosis) prognosis_desc,
                   ep.prognosis_notes
              FROM epis_prognosis ep
             WHERE ep.id_epis_prognosis = i_id_epis_prognosis;
        RETURN TRUE;
    END get_prognosis_notes;

    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_actions           OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ACTIONS';
    
        l_id_prof_create epis_prognosis.id_prof_create%TYPE;
    BEGIN
    
        g_error := 'GET EPIS_PROGNOSIS ID_PROF_CREATE ID_EPIS_PROGNOSIS: ' || i_id_epis_prognosis;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT ep.id_prof_create
          INTO l_id_prof_create
          FROM epis_prognosis ep
         WHERE ep.id_epis_prognosis = i_id_epis_prognosis;
    
        g_error := 'GET CURSOR o_actions';
        pk_alertlog.log_debug(g_error);
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table,t,scale_rows=2)*/
             id_action,
             id_parent,
             level_nr,
             from_state,
             to_state,
             desc_action,
             icon,
             flg_default,
             CASE
                  WHEN l_id_prof_create <> i_prof.id THEN
                   g_status_inactive
                  ELSE
                   g_status_active
              END flg_active,
             action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'PROGNOSIS_NOTES', NULL)) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    FUNCTION tf_prognosis_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) RETURN t_coll_prognosis_cda
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'TF_PROGNOSIS_CDA';
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        l_rec_prognosis_cda t_rec_prognosis_cda;
        l_error             t_error_out;
    BEGIN
        IF i_scope IS NULL
           OR i_scope_type IS NULL
        THEN
            g_has_error := TRUE;
            g_error     := 'SCOPE ID OR TYPE IS NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => l_error)
        THEN
            g_has_error := TRUE;
            RAISE g_exception;
        END IF;
    
        FOR l_rec_prognosis_cda IN (SELECT ep.id_epis_prognosis,
                                           ep.flg_status,
                                           pk_sysdomain.get_domain('EPIS_PROGNOSIS.FLG_STATUS', ep.flg_status, i_lang),
                                           decode(ep.id_prognosis,
                                                  NULL,
                                                  ep.prognosis_notes,
                                                  pk_multichoice.get_multichoice_option_desc(i_lang,
                                                                                             i_prof,
                                                                                             ep.id_prognosis) || ' ' ||
                                                  ep.prognosis_notes),
                                           pk_date_utils.date_send_tsz(i_lang, ep.dt_create, i_prof),
                                           ep.dt_create,
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       ep.dt_create,
                                                                       i_prof.institution,
                                                                       i_prof.software)
                                      FROM epis_prognosis ep
                                     INNER JOIN (SELECT e.id_episode
                                                  FROM episode e
                                                 WHERE e.id_episode = l_id_episode
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_episode
                                                UNION ALL
                                                SELECT e.id_episode
                                                  FROM episode e
                                                 WHERE e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_patient
                                                UNION ALL
                                                SELECT e.id_episode
                                                  FROM episode e
                                                 WHERE e.id_visit = l_id_visit
                                                   AND e.id_patient = l_id_patient
                                                   AND i_scope_type = pk_alert_constant.g_scope_type_visit) epi
                                        ON ep.id_episode = epi.id_episode)
        LOOP
            PIPE ROW(l_rec_prognosis_cda);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RETURN;
    END;

    FUNCTION get_prognosis_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE
    ) RETURN CLOB IS
    
        l_ret            CLOB;
        l_prognosis_desc VARCHAR2(200 CHAR);
        l_notes          epis_prognosis.prognosis_notes%TYPE;
    BEGIN
    
        SELECT pk_multichoice.get_multichoice_option_desc(i_lang, i_prof, ep.id_prognosis) prognosis_desc,
               ep.prognosis_notes
          INTO l_prognosis_desc, l_notes
          FROM epis_prognosis ep
         WHERE ep.id_epis_prognosis = i_id_epis_prognosis;
        IF l_prognosis_desc IS NOT NULL
        THEN
            l_ret := l_prognosis_desc;
        END IF;
        IF l_notes IS NOT NULL
        THEN
            IF l_ret IS NOT NULL
            THEN
                l_ret := l_ret || ': ' || l_notes;
            ELSE
                l_ret := l_notes;
            END IF;
        END IF;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prognosis_desc;

    PROCEDURE validate_job_tstz IS
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_p       TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_c       TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_f       TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_bool_p BOOLEAN;
        l_bool_c BOOLEAN;
        l_bool_f BOOLEAN;
    
        l_msg_p VARCHAR2(4000);
        l_msg_c VARCHAR2(4000);
        l_msg_f VARCHAR2(4000);
    
        k_mask CONSTANT VARCHAR2(0050) := 'dd-mm-yyyy hh24:mi:ss tzr';
    
        FUNCTION iif
        (
            i_bool  IN BOOLEAN,
            i_true  IN VARCHAR2,
            i_false IN VARCHAR2
        ) RETURN VARCHAR2 IS
        BEGIN
        
            IF i_bool
            THEN
                RETURN i_true;
            ELSE
                RETURN i_false;
            END IF;
        
        END iif;
    
        PROCEDURE show(i_text IN VARCHAR2) IS
        BEGIN
        
            pk_alertlog.log_debug(text            => i_text,
                                  object_name     => g_package_name,
                                  sub_object_name => 'VALIDATE_JOB_TSTZ');
            dbms_output.put_line(i_text);
        
        END show;
    
    BEGIN
    
        l_sysdate_tstz := current_timestamp;
        l_date_p       := l_sysdate_tstz + numtodsinterval(- '1', 'DAY');
        l_date_c       := l_sysdate_tstz;
        l_date_f       := l_sysdate_tstz + numtodsinterval('1', 'DAY');
    
        l_bool_p := l_date_p < l_sysdate_tstz;
        l_bool_c := l_date_c = l_sysdate_tstz;
        l_bool_f := l_date_f > l_sysdate_tstz;
    
        l_msg_p := to_char(l_date_p, k_mask) || '<' || to_char(l_sysdate_tstz, k_mask);
        l_msg_c := to_char(l_date_c, k_mask) || '=' || to_char(l_sysdate_tstz, k_mask);
        l_msg_f := to_char(l_date_f, k_mask) || '>' || to_char(l_sysdate_tstz, k_mask);
    
        l_msg_p := l_msg_p || '=' || iif(l_bool_p, 'Past true', 'Past false');
        l_msg_c := l_msg_c || '-' || iif(l_bool_c, 'Now true', 'Now false');
        l_msg_f := l_msg_f || '-' || iif(l_bool_f, 'Future true', 'Future false');
    
        show(l_msg_p);
        show(l_msg_c);
        show(l_msg_f);
    END validate_job_tstz;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
    g_sysdate_tstz := current_timestamp;
END pk_prognosis;
/
