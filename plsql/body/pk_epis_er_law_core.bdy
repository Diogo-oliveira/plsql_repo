/*-- Last Change Revision: $Rev: 2027121 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_epis_er_law_core IS

    g_code_dom_flg_er_law_status CONSTANT sys_domain.code_domain%TYPE := 'EPIS_ER_LAW.FLG_ER_LAW_STATUS';

    g_ges_external_app   CONSTANT sys_config.id_sys_config%TYPE := 'APP_GES';
    g_ges_func_is_active CONSTANT sys_config.id_sys_config%TYPE := 'GES_FUNC_IS_ACTIVE';

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    FUNCTION create_epis_er_law_hist_rec
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN epis_er_law.id_episode%TYPE,
        o_epis_er_law OUT epis_er_law.id_epis_er_law%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_er_law_hist epis_er_law_hist%ROWTYPE;
    
    BEGIN
    
        g_error := 'GET ACTIVE RECORD';
        SELECT eel.id_epis_er_law,
               g_sysdate_tstz,
               eel.id_episode,
               eel.dt_activation,
               eel.dt_inactivation,
               eel.flg_er_law_status,
               eel.id_cancel_reason,
               eel.notes_cancel,
               eel.id_prof_create,
               eel.dt_create,
               eel.create_user,
               eel.create_time,
               eel.create_institution,
               eel.update_user,
               eel.update_time,
               eel.update_institution
          INTO l_epis_er_law_hist
          FROM epis_er_law eel
         WHERE eel.id_episode = i_episode;
    
        o_epis_er_law := l_epis_er_law_hist.id_epis_er_law;
    
        g_error := 'SAVE ACTIVE RECORD IN HIST';
        ts_epis_er_law_hist.ins(rec_in => l_epis_er_law_hist);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            --There is no active record for the given episode, so there is nothing to save in history
            o_epis_er_law := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_EPIS_ER_LAW_HIST_REC',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_epis_er_law_hist_rec;

    FUNCTION set_epis_er_law
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN epis_er_law.id_episode%TYPE,
        i_dt_activation     IN VARCHAR2,
        i_dt_inactivation   IN VARCHAR2,
        i_flg_er_law_status IN epis_er_law.flg_er_law_status%TYPE,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_epis_er_law       OUT epis_er_law.id_epis_er_law%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_er_law epis_er_law.id_epis_er_law%TYPE;
    
        l_rowids table_varchar := table_varchar();
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SAVE ACTIVE RECORD IN HISTORY';
        IF NOT create_epis_er_law_hist_rec(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_episode     => i_episode,
                                           o_epis_er_law => l_epis_er_law,
                                           o_error       => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_epis_er_law IS NOT NULL
        THEN
            g_error  := 'UPD ACTIVE RECORD';
            l_rowids := table_varchar();
            ts_epis_er_law.upd(id_epis_er_law_in     => l_epis_er_law,
                               id_episode_in         => i_episode,
                               id_episode_nin        => FALSE,
                               dt_activation_in      => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                      i_prof      => i_prof,
                                                                                      i_timestamp => i_dt_activation,
                                                                                      i_timezone  => NULL),
                               dt_activation_nin     => FALSE,
                               dt_inactivation_in    => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                      i_prof      => i_prof,
                                                                                      i_timestamp => i_dt_inactivation,
                                                                                      i_timezone  => NULL),
                               dt_inactivation_nin   => FALSE,
                               flg_er_law_status_in  => i_flg_er_law_status,
                               flg_er_law_status_nin => FALSE,
                               id_cancel_reason_in   => NULL,
                               id_cancel_reason_nin  => FALSE,
                               notes_cancel_in       => NULL,
                               notes_cancel_nin      => FALSE,
                               id_prof_create_in     => i_prof.id,
                               id_prof_create_nin    => FALSE,
                               dt_create_in          => g_sysdate_tstz,
                               dt_create_nin         => FALSE,
                               rows_out              => l_rowids);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_ER_LAW',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('ID_EPISODE',
                                                                          'DT_ACTIVATION',
                                                                          'DT_INACTIVATION',
                                                                          'FLG_ER_LAW_STATUS',
                                                                          'ID_CANCEL_REASON',
                                                                          'NOTES_CANCEL',
                                                                          'ID_PROF_CREATE',
                                                                          'DT_CREATE'));
        
        ELSE
            l_epis_er_law := ts_epis_er_law.next_key;
        
            g_error  := 'INS RECORD';
            l_rowids := table_varchar();
            ts_epis_er_law.ins(id_epis_er_law_in    => l_epis_er_law,
                               id_episode_in        => i_episode,
                               dt_activation_in     => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_timestamp => i_dt_activation,
                                                                                     i_timezone  => NULL),
                               dt_inactivation_in   => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_timestamp => i_dt_inactivation,
                                                                                     i_timezone  => NULL),
                               flg_er_law_status_in => i_flg_er_law_status,
                               id_prof_create_in    => i_prof.id,
                               dt_create_in         => g_sysdate_tstz,
                               rows_out             => l_rowids);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_ER_LAW',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        IF i_flg_er_law_status = pk_epis_er_law_core.g_flg_er_law_status_a
        THEN
            g_error := 'SET CARE STAGE TO IN_TREATMENT';
            IF NOT pk_patient_tracking.set_care_stage_in_treat(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_episode         => i_episode,
                                                               i_flg_triage_call => pk_alert_constant.g_no,
                                                               i_flg_er_law      => pk_alert_constant.g_yes,
                                                               o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL PK_IA_EVENT_COMMON.EPISODE_EMERGENCY_LAW_ACTIVE';
            pk_ia_event_common.episode_emergency_law_active(i_id_institution => i_prof.institution,
                                                            i_id_episode     => i_episode);
        ELSIF i_flg_er_law_status = pk_epis_er_law_core.g_flg_er_law_status_i
        THEN
            g_error := 'CALL PK_IA_EVENT_COMMON.EPISODE_EMERGENCY_LAW_INACTIVE';
            pk_ia_event_common.episode_emergency_law_inactive(i_id_institution => i_prof.institution,
                                                              i_id_episode     => i_episode);
        END IF;
    
        o_epis_er_law := l_epis_er_law;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_ER_LAW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_er_law;

    FUNCTION cancel_epis_er_law
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN epis_er_law.id_episode%TYPE,
        i_cancel_reason IN epis_er_law.id_cancel_reason%TYPE,
        i_cancel_notes  IN epis_er_law.notes_cancel%TYPE,
        i_flg_commit    IN BOOLEAN DEFAULT FALSE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_er_law epis_er_law.id_epis_er_law%TYPE;
    
        l_rowids table_varchar := table_varchar();
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SAVE ACTIVE RECORD IN HISTORY';
        IF NOT create_epis_er_law_hist_rec(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_episode     => i_episode,
                                           o_epis_er_law => l_epis_er_law,
                                           o_error       => o_error)
        THEN
            g_error := 'ERROR WHEN SAVING ACTIVE RECORD IN HISTORY';
            RAISE l_exception;
        END IF;
    
        g_error  := 'CANCEL CURRENT RECORD';
        l_rowids := table_varchar();
        ts_epis_er_law.upd(id_epis_er_law_in    => l_epis_er_law,
                           id_episode_in        => i_episode,
                           id_episode_nin       => FALSE,
                           id_cancel_reason_in  => i_cancel_reason,
                           id_cancel_reason_nin => FALSE,
                           notes_cancel_in      => i_cancel_notes,
                           notes_cancel_nin     => FALSE,
                           id_prof_create_in    => i_prof.id,
                           id_prof_create_nin   => FALSE,
                           dt_create_in         => g_sysdate_tstz,
                           dt_create_nin        => FALSE,
                           rows_out             => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ER_LAW',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE',
                                                                      'ID_CANCEL_REASON',
                                                                      'NOTES_CANCEL',
                                                                      'ID_PROF_CREATE',
                                                                      'DT_CREATE'));
    
        g_error := 'CALL PK_PATIENT_TRACKING.RESET_CARE_STAGE_ER_LAW';
        IF NOT pk_patient_tracking.reset_care_stage_er_law(i_lang    => i_lang,
                                                           i_prof    => i_prof,
                                                           i_episode => i_episode,
                                                           o_error   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL PK_IA_EVENT_COMMON.EPISODE_EMERGENCY_LAW_CANCEL';
        pk_ia_event_common.episode_emergency_law_cancel(i_id_institution => i_prof.institution,
                                                        i_id_episode     => i_episode);
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CANCEL_EPIS_ER_LAW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_epis_er_law;

    FUNCTION get_lst_epis_er_law
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN epis_er_law.id_episode%TYPE,
        o_lst_epis_er_law OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_area_er_law         CONSTANT doc_area.id_doc_area%TYPE := 698;
        l_code_lbl_dt_act            CONSTANT sys_message.code_message%TYPE := 'PROGRESS_NOTES_T129'; --Activation date / time
        l_code_lbl_dt_inact          CONSTANT sys_message.code_message%TYPE := 'PROGRESS_NOTES_T130'; --Inactivation date / time
        l_code_lbl_flg_er_law_status CONSTANT sys_message.code_message%TYPE := 'PROGRESS_NOTES_T138'; --Emergency law status
        l_code_lbl_canc_reas         CONSTANT sys_message.code_message%TYPE := 'PROGRESS_NOTES_T135'; --Cancelation reason
        l_code_lbl_canc_notes        CONSTANT sys_message.code_message%TYPE := 'PROGRESS_NOTES_T136'; --Cancellation notes
    
        l_current_record CONSTANT PLS_INTEGER := 0;
    
        l_msg_lbl_dt_act            sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => l_code_lbl_dt_act);
        l_msg_lbl_dt_inact          sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => l_code_lbl_dt_inact);
        l_msg_lbl_flg_er_law_status sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => l_code_lbl_flg_er_law_status);
        l_msg_lbl_canc_reas         sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => l_code_lbl_canc_reas);
        l_msg_lbl_canc_notes        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => l_code_lbl_canc_notes);
        l_outdated                  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_prof      => i_prof,
                                                                                            i_code_mess => 'EMERGENCY_LAW_T3');
        l_cancelled                 sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_prof      => i_prof,
                                                                                            i_code_mess => 'EMERGENCY_LAW_T4');
    
        l_id_visit visit.id_visit%TYPE;
    
    BEGIN
    
        g_error    := 'CALL PK_EPISODE.GET_ID_VISIT. I_EPISODE: ' || i_episode;
        l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        g_error := 'OPEN CURSOR O_LST_EPIS_ER_LAW';
        OPEN o_lst_epis_er_law FOR
            SELECT eel.id_epis_er_law,
                   eel.id_epis_er_law || l_current_record flask_key,
                   l_msg_lbl_dt_act label_dt_activation,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_activation, i_prof.institution, i_prof.institution) dt_activation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_activation, i_prof) dt_activation_send,
                   l_msg_lbl_dt_inact label_dt_inactivation,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_inactivation, i_prof.institution, i_prof.institution) dt_inactivation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_inactivation, i_prof) dt_inactivation_send,
                   l_msg_lbl_flg_er_law_status label_flg_er_law_status,
                   eel.flg_er_law_status,
                   pk_sysdomain.get_domain(g_code_dom_flg_er_law_status, eel.flg_er_law_status, i_lang) desc_flg_er_law_status,
                   pk_alert_constant.g_active flg_status,
                   decode(eel.id_cancel_reason, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                   eel.id_cancel_reason,
                   l_msg_lbl_canc_reas label_cancel_reason,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, eel.id_cancel_reason) cancel_reason,
                   l_msg_lbl_canc_notes label_notes_cancel,
                   eel.notes_cancel,
                   eel.dt_create,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_create, i_prof.institution, i_prof.institution) dt_create_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_create, i_prof) dt_create_send,
                   eel.id_prof_create,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eel.id_prof_create) name_prof_create,
                   pk_prof_utils.get_spec_sign_by_visit(i_lang, i_prof, eel.id_prof_create, eel.dt_create, l_id_visit) spec_prof_create,
                   l_id_doc_area_er_law id_doc_area,
                   CASE
                        WHEN eel.id_cancel_reason IS NULL THEN
                         NULL
                        ELSE
                         l_cancelled
                    END desc_status
              FROM epis_er_law eel
             WHERE eel.id_episode = i_episode
            UNION ALL
            SELECT eelh.id_epis_er_law,
                   eelh.id_epis_er_law || rownum flash_key,
                   l_msg_lbl_dt_act label_dt_activation,
                   pk_date_utils.date_char_tsz(i_lang, eelh.dt_activation, i_prof.institution, i_prof.institution) dt_activation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eelh.dt_activation, i_prof) dt_activation_send,
                   l_msg_lbl_dt_inact label_dt_inactivation,
                   pk_date_utils.date_char_tsz(i_lang, eelh.dt_inactivation, i_prof.institution, i_prof.institution) dt_inactivation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eelh.dt_inactivation, i_prof) dt_inactivation_send,
                   l_msg_lbl_flg_er_law_status label_flg_er_law_status,
                   eelh.flg_er_law_status,
                   pk_sysdomain.get_domain(g_code_dom_flg_er_law_status, eelh.flg_er_law_status, i_lang) desc_flg_er_law_status,
                   pk_alert_constant.g_outdated flg_status,
                   decode(eelh.id_cancel_reason, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                   eelh.id_cancel_reason,
                   l_msg_lbl_canc_reas label_cancel_reason,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, eelh.id_cancel_reason) cancel_reason,
                   l_msg_lbl_canc_notes label_notes_cancel,
                   eelh.notes_cancel,
                   eelh.dt_create,
                   pk_date_utils.date_char_tsz(i_lang, eelh.dt_create, i_prof.institution, i_prof.institution) dt_create_chr,
                   pk_date_utils.date_send_tsz(i_lang, eelh.dt_create, i_prof) dt_create_send,
                   eelh.id_prof_create,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eelh.id_prof_create) name_prof_create,
                   pk_prof_utils.get_spec_sign_by_visit(i_lang, i_prof, eelh.id_prof_create, eelh.dt_create, l_id_visit) spec_prof_create,
                   l_id_doc_area_er_law id_doc_area,
                   CASE
                       WHEN eelh.id_cancel_reason IS NULL THEN
                        l_outdated
                       ELSE
                        l_cancelled
                   END desc_status
              FROM epis_er_law_hist eelh
             WHERE eelh.id_episode = i_episode
             ORDER BY dt_create DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_LST_EPIS_ER_LAW',
                                              o_error);
            pk_types.open_my_cursor(o_lst_epis_er_law);
            RETURN FALSE;
    END get_lst_epis_er_law;

    FUNCTION get_epis_er_law
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_epis_er_law OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_EPIS_ER_LAW';
        OPEN o_epis_er_law FOR
            SELECT eel.id_epis_er_law,
                   eel.id_episode,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_activation, i_prof.institution, i_prof.institution) dt_activation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_activation, i_prof) dt_activation_send,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_inactivation, i_prof.institution, i_prof.institution) dt_inactivation_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_inactivation, i_prof) dt_inactivation_send,
                   eel.flg_er_law_status,
                   pk_sysdomain.get_domain(g_code_dom_flg_er_law_status, eel.flg_er_law_status, i_lang) desc_flg_er_law_status,
                   pk_date_utils.date_char_tsz(i_lang, eel.dt_create, i_prof.institution, i_prof.institution) dt_create_chr,
                   pk_date_utils.date_send_tsz(i_lang, eel.dt_create, i_prof) dt_create_send,
                   eel.id_prof_create,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eel.id_prof_create) name_prof_create,
                   pk_prof_utils.get_spec_sign_by_visit(i_lang,
                                                        i_prof,
                                                        eel.id_prof_create,
                                                        eel.dt_create,
                                                        pk_episode.get_id_visit(eel.id_episode)) spec_prof_create
              FROM epis_er_law eel
             WHERE eel.id_epis_er_law = i_epis_er_law;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_ER_LAW',
                                              o_error);
            pk_types.open_my_cursor(o_epis_er_law);
            RETURN FALSE;
    END get_epis_er_law;

    FUNCTION get_fast_track_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN epis_er_law.id_episode%TYPE,
        o_fast_track OUT fast_track.id_fast_track%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        BEGIN
            g_error := 'GET ID FAST TRACK OF EPIS: ' || i_episode;
            SELECT pk_epis_er_law_core.g_fast_track_er_law id_fast_track
              INTO o_fast_track
              FROM epis_er_law eel
             WHERE eel.id_episode = i_episode
               AND eel.flg_er_law_status = pk_epis_er_law_core.g_flg_er_law_status_a
               AND eel.id_cancel_reason IS NULL
               AND eel.dt_inactivation IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                o_fast_track := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FAST_TRACK_ID',
                                              o_error);
            RETURN FALSE;
    END get_fast_track_id;

    FUNCTION get_fast_track_id
    (
        i_episode    IN epis_er_law.id_episode%TYPE,
        i_fast_track IN fast_track.id_fast_track%TYPE
    ) RETURN fast_track.id_fast_track%TYPE IS
    
        l_fast_track fast_track.id_fast_track%TYPE;
    
        l_lang language.id_language%TYPE := 0;
        l_prof profissional := profissional(0, 0, 0);
    
        l_exception EXCEPTION;
        l_error     t_error_out;
    
    BEGIN
    
        IF i_fast_track IS NULL
        THEN
            g_error := 'CALL PK_EPIS_ER_LAW_CORE.GET_FAST_TRACK_ID';
            IF NOT pk_epis_er_law_core.get_fast_track_id(i_lang       => l_lang,
                                                         i_prof       => l_prof,
                                                         i_episode    => i_episode,
                                                         o_fast_track => l_fast_track,
                                                         o_error      => l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            g_error      := 'JUST RETURN ID_FAST_TRACK ' || i_fast_track;
            l_fast_track := i_fast_track;
        END IF;
    
        RETURN l_fast_track;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_fast_track_id;

    FUNCTION get_date_limits
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_er_law.id_episode%TYPE,
        o_limits  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_curr_dt_activ        epis_er_law.dt_activation%TYPE;
        l_curr_dt_inactiv      epis_er_law.dt_inactivation%TYPE;
        l_last_hist_dt_activ   epis_er_law.dt_activation%TYPE;
        l_last_hist_dt_inactiv epis_er_law.dt_inactivation%TYPE;
    
        l_dt_aux   epis_er_law.dt_activation%TYPE;
        l_dt_disch discharge.dt_med_tstz%TYPE;
    
        l_dt_activ_min   VARCHAR2(100 CHAR);
        l_dt_activ_max   VARCHAR2(100 CHAR);
        l_dt_inactiv_min VARCHAR2(100 CHAR);
        l_dt_inactiv_max VARCHAR2(100 CHAR);
        l_dt_default_max VARCHAR2(100 CHAR);
    
        l_exception EXCEPTION;
    
        FUNCTION get_dt_inactv_min RETURN VARCHAR2 IS
            l_dt_aux1 epis_er_law.dt_activation%TYPE;
        BEGIN
            IF l_curr_dt_activ > l_last_hist_dt_activ
               AND l_curr_dt_activ IS NOT NULL
               AND l_last_hist_dt_activ IS NOT NULL
            THEN
                l_dt_aux1 := l_curr_dt_activ;
            ELSIF l_curr_dt_activ <= l_last_hist_dt_activ
                  AND l_curr_dt_activ IS NOT NULL
                  AND l_last_hist_dt_activ IS NOT NULL
            THEN
                l_dt_aux1 := l_last_hist_dt_activ;
            ELSIF l_curr_dt_activ IS NULL
                  AND l_last_hist_dt_activ IS NOT NULL
            THEN
                l_dt_aux1 := l_last_hist_dt_activ;
            ELSIF l_curr_dt_activ IS NOT NULL
                  AND l_last_hist_dt_activ IS NULL
            THEN
                l_dt_aux1 := l_curr_dt_activ;
            ELSE
                l_dt_aux1 := NULL;
            END IF;
        
            RETURN pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => l_dt_aux1,
                                                   i_timezone  => NULL);
        END get_dt_inactv_min;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        BEGIN
            g_error := 'GET CURRENT DATES';
            SELECT eel.dt_activation, eel.dt_inactivation
              INTO l_curr_dt_activ, l_curr_dt_inactiv
              FROM epis_er_law eel
             WHERE eel.id_episode = i_episode
               AND eel.id_cancel_reason IS NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_curr_dt_activ   := NULL;
                l_curr_dt_inactiv := NULL;
        END;
    
        BEGIN
            g_error := 'GET LAST HIST DATES';
            SELECT t.dt_activation, t.dt_inactivation
              INTO l_last_hist_dt_activ, l_last_hist_dt_inactiv
              FROM (SELECT eelh.dt_activation,
                           eelh.dt_inactivation,
                           row_number() over(ORDER BY eelh.dt_create DESC) line_number
                      FROM epis_er_law_hist eelh
                     WHERE eelh.id_episode = i_episode
                       AND eelh.id_cancel_reason IS NULL) t
             WHERE t.line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_last_hist_dt_activ   := NULL;
                l_last_hist_dt_inactiv := NULL;
        END;
    
        g_error    := 'GET DISCH_DATE';
        l_dt_disch := pk_discharge.get_discharge_date(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_episode);
    
        g_error          := 'SET DEFAULT MAX DATE';
        l_dt_default_max := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_timestamp => nvl(l_dt_disch, g_sysdate_tstz),
                                                            i_timezone  => NULL);
    
        IF (l_curr_dt_activ IS NULL AND l_last_hist_dt_activ IS NULL)
           OR (l_curr_dt_inactiv IS NULL AND l_last_hist_dt_inactiv IS NULL)
        THEN
            g_error := 'SET ACT MIN DATE TO EPIS_BEGIN_DT';
            IF NOT pk_episode.get_epis_dt_begin(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                o_dt_begin   => l_dt_activ_min,
                                                o_error      => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            IF l_curr_dt_inactiv > l_last_hist_dt_inactiv
               AND l_curr_dt_inactiv IS NOT NULL
               AND l_last_hist_dt_inactiv IS NOT NULL
            THEN
                l_dt_aux := l_curr_dt_inactiv;
            ELSIF l_curr_dt_inactiv <= l_last_hist_dt_inactiv
                  AND l_curr_dt_inactiv IS NOT NULL
                  AND l_last_hist_dt_inactiv IS NOT NULL
            THEN
                l_dt_aux := l_last_hist_dt_inactiv;
            ELSIF l_curr_dt_inactiv IS NULL
                  AND l_last_hist_dt_inactiv IS NOT NULL
            THEN
                l_dt_aux := l_last_hist_dt_inactiv;
            ELSIF l_curr_dt_inactiv IS NOT NULL
                  AND l_last_hist_dt_inactiv IS NULL
            THEN
                l_dt_aux := l_curr_dt_inactiv;
            END IF;
        
            g_error        := 'SET ACT MIN DATE TO PREVIOUS DT_INACTV';
            l_dt_activ_min := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                              i_prof      => i_prof,
                                                              i_timestamp => l_dt_aux,
                                                              i_timezone  => NULL);
        END IF;
    
        l_dt_activ_max := l_dt_default_max;
    
        l_dt_inactiv_min := get_dt_inactv_min();
    
        IF l_dt_inactiv_min IS NOT NULL
        THEN
            l_dt_inactiv_max := l_dt_default_max;
        ELSE
            l_dt_inactiv_max := NULL;
        END IF;
    
        g_error := 'OPEN CURSOR O_LIMITS';
        OPEN o_limits FOR
            SELECT l_dt_activ_min   dt_activation_min,
                   l_dt_activ_max   dt_activation_max,
                   l_dt_inactiv_min dt_inactivation_min,
                   l_dt_inactiv_max dt_inactivation_max
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_limits);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_limits);
            RETURN FALSE;
    END get_date_limits;

    FUNCTION create_epis_ges_msg
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN epis_ges_msg.id_episode%TYPE,
        i_pat_history_diagnosis IN epis_ges_msg.id_pat_history_diagnosis%TYPE,
        i_epis_diagnosis        IN epis_ges_msg.id_epis_diagnosis%TYPE,
        i_flg_origin            IN epis_ges_msg.flg_origin%TYPE,
        i_flg_commit            IN BOOLEAN DEFAULT FALSE,
        o_epis_ges_msg          OUT epis_ges_msg.id_epis_ges_msg%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_ges_msg epis_ges_msg.id_epis_ges_msg%TYPE;
        l_diagnosis    diagnosis.id_diagnosis%TYPE;
        l_code_icd     diagnosis.code_icd%TYPE;
    
        l_ges_func_is_active sys_config.value%TYPE;
        l_inst_market        market.id_market%TYPE;
    
        l_external_call    EXCEPTION;
        l_validation_error EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error              := 'VERIFY IF GES FUNC IS ACTIVE';
        l_ges_func_is_active := nvl(pk_sysconfig.get_config(i_code_cf => g_ges_func_is_active, i_prof => i_prof),
                                    pk_alert_constant.g_no);
    
        IF l_ges_func_is_active = pk_alert_constant.g_yes
        THEN
            g_error       := 'CALL PK_UTILS.GET_INSTITUTION_MARKET';
            l_inst_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
        
            IF l_inst_market = pk_alert_constant.g_id_market_cl
            THEN
            
                IF i_pat_history_diagnosis IS NULL
                   AND i_epis_diagnosis IS NULL
                THEN
                    g_error := 'BOTH FIELDS (PAT_HISTORY_DIAGNOSIS AND EPIS_DIAGNOSIS) ARE EMPTY.';
                    RAISE l_validation_error;
                ELSIF i_pat_history_diagnosis IS NOT NULL
                      AND i_epis_diagnosis IS NOT NULL
                THEN
                    g_error := 'BOTH FIELDS (PAT_HISTORY_DIAGNOSIS AND EPIS_DIAGNOSIS) ARE FILLED.';
                    RAISE l_validation_error;
                END IF;
            
                IF i_epis_diagnosis IS NOT NULL
                THEN
                    SELECT ed.id_diagnosis
                      INTO l_diagnosis
                      FROM epis_diagnosis ed
                     WHERE ed.id_epis_diagnosis = i_epis_diagnosis;
                ELSIF i_pat_history_diagnosis IS NOT NULL
                THEN
                    BEGIN
                        SELECT phd.id_diagnosis
                          INTO l_diagnosis
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_pat_history_diagnosis = i_pat_history_diagnosis;
                    EXCEPTION
                        WHEN no_data_found THEN
                            --id_diagnosis of pat_history_diagnosis table is null 
                            --when it was registered one problem without any associated diagnosis
                            l_diagnosis := NULL;
                    END;
                END IF;
            
                IF l_diagnosis IS NOT NULL
                THEN
                    l_epis_ges_msg := seq_epis_ges_msg.nextval;
                
                    g_error := 'SAVE EPIS_GES_MSG';
                    ts_epis_ges_msg.ins(id_epis_ges_msg_in          => l_epis_ges_msg,
                                        dt_epis_ges_msg_in          => g_sysdate_tstz,
                                        id_episode_in               => i_episode,
                                        id_pat_history_diagnosis_in => i_pat_history_diagnosis,
                                        id_epis_diagnosis_in        => i_epis_diagnosis,
                                        flg_origin_in               => i_flg_origin,
                                        flg_msg_status_in           => pk_epis_er_law_core.g_ges_flg_msg_status_s,
                                        flg_status_in               => pk_epis_er_law_core.g_ges_flg_status_a,
                                        id_prof_create_in           => i_prof.id);
                
                    pk_ia_event_common.episode_ges_message_new(i_id_institution  => i_prof.institution,
                                                               i_id_epis_ges_msg => l_epis_ges_msg);
                
                ELSE
                    l_epis_ges_msg := NULL;
                END IF;
            
                o_epis_ges_msg := l_epis_ges_msg;
            
                IF i_flg_commit
                THEN
                    COMMIT;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_external_call THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_EPIS_GES_MSG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_epis_ges_msg;

    FUNCTION set_epis_ges_response
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_ges_msg IN epis_ges_msg.id_epis_ges_msg%TYPE,
        i_flg_commit   IN BOOLEAN DEFAULT FALSE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        r_epis_ges_msg epis_ges_msg%ROWTYPE;
    
    BEGIN
    
        BEGIN
            g_error := 'GET CURRENT ACTIVE RECORD';
            SELECT egm.*
              INTO r_epis_ges_msg
              FROM epis_ges_msg egm
             WHERE egm.id_epis_ges_msg = i_epis_ges_msg
               AND egm.flg_status = pk_epis_er_law_core.g_ges_flg_status_a
               AND egm.flg_msg_status = pk_epis_er_law_core.g_ges_flg_msg_status_s;
        
            g_error := 'SET CURRENT ACTIVE RECORD HAS OUTDATED';
            UPDATE epis_ges_msg egm
               SET egm.flg_status = pk_epis_er_law_core.g_ges_flg_status_o
             WHERE egm.id_epis_ges_msg = i_epis_ges_msg
               AND egm.flg_status = pk_epis_er_law_core.g_ges_flg_status_a;
        
            g_error := 'SET MSG HAS REPLIED';
            ts_epis_ges_msg.ins(id_epis_ges_msg_in          => i_epis_ges_msg,
                                dt_epis_ges_msg_in          => g_sysdate_tstz,
                                id_episode_in               => r_epis_ges_msg.id_episode,
                                id_pat_history_diagnosis_in => r_epis_ges_msg.id_pat_history_diagnosis,
                                id_epis_diagnosis_in        => r_epis_ges_msg.id_epis_diagnosis,
                                flg_origin_in               => r_epis_ges_msg.flg_origin,
                                flg_msg_status_in           => pk_epis_er_law_core.g_ges_flg_msg_status_r,
                                flg_status_in               => pk_epis_er_law_core.g_ges_flg_status_a,
                                id_prof_create_in           => i_prof.id);
        
            IF i_flg_commit
            THEN
                COMMIT;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                --We already received the answer so there is nothing to do
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_GES_RESPONSE',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_ges_response;

    FUNCTION set_epis_ges_alert
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_patient                 IN patient.id_patient%TYPE,
        i_total_unnot_pathologies IN NUMBER,
        i_flg_commit              IN BOOLEAN DEFAULT FALSE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_zero CONSTANT PLS_INTEGER := 0;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_external_call EXCEPTION;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF nvl(i_total_unnot_pathologies, l_zero) > l_zero
        THEN
            g_error                          := 'INSERT NEW SYS_ ID_PATIENT: ';
            l_sys_alert_event.id_sys_alert   := g_ges_sys_alert;
            l_sys_alert_event.id_software    := i_prof.software;
            l_sys_alert_event.id_institution := i_prof.institution;
            l_sys_alert_event.id_patient     := i_patient;
            l_sys_alert_event.id_record      := i_patient;
            l_sys_alert_event.dt_record      := g_sysdate_tstz;
            l_sys_alert_event.flg_visible    := pk_alert_constant.g_yes;
            l_sys_alert_event.replace1       := to_char(i_total_unnot_pathologies);
            l_sys_alert_event.id_visit       := -1;
            l_sys_alert_event.id_episode     := -1;
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE l_external_call;
            END IF;
        ELSE
            l_sys_alert_event.id_sys_alert := g_ges_sys_alert;
            l_sys_alert_event.id_record    := i_patient;
        
            g_error := 'DELETE SYS_ALERT';
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE l_external_call;
            END IF;
        END IF;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_external_call THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_EPIS_GES_ALERT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_ges_alert;

    FUNCTION get_total_unnot_path
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_patient patient.id_patient%TYPE;
    
    BEGIN
    
        BEGIN
            g_error := 'GET TOTAL UNNOTIFIED PATHOLOGIES';
            SELECT to_number(sae.replace1)
              INTO o_total_unnot_pathologies
              FROM sys_alert_event sae
             WHERE sae.id_sys_alert = g_ges_sys_alert
               AND sae.id_software = i_prof.software
               AND sae.id_institution = i_prof.institution
               AND sae.flg_visible = pk_alert_constant.g_yes
               AND sae.id_patient = (SELECT epis.id_patient
                                       FROM episode epis
                                      WHERE epis.id_episode = i_episode);
        EXCEPTION
            WHEN no_data_found THEN
                o_total_unnot_pathologies := 0;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TOTAL_UNNOT_PATH',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_total_unnot_path;

    FUNCTION get_ges_discharge_msg
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN epis_ges_msg.id_episode%TYPE,
        o_flg_type                OUT VARCHAR2,
        o_url                     OUT VARCHAR2,
        o_total_unnot_pathologies OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_type_n CONSTANT VARCHAR2(1) := 'N'; --No message to display
        l_flg_type_w CONSTANT VARCHAR2(1) := 'W'; --Warning message
        l_flg_type_c CONSTANT VARCHAR2(1) := 'C'; --Confirmation message
        l_flg_type_e CONSTANT VARCHAR2(1) := 'E'; --Error message
    
        l_total_sent_msg PLS_INTEGER;
        l_flg_show       VARCHAR2(1);
        l_button         VARCHAR2(1);
        l_msg_title      sys_message.desc_message%TYPE;
        l_msg            sys_message.desc_message%TYPE;
    
        l_external_call EXCEPTION;
    
    BEGIN
    
        g_error := 'COUNT TOTAL SENT MESSAGES';
        SELECT COUNT(*)
          INTO l_total_sent_msg
          FROM epis_ges_msg egm
         WHERE egm.flg_status = pk_epis_er_law_core.g_ges_flg_status_a
           AND egm.flg_msg_status = pk_epis_er_law_core.g_ges_flg_msg_status_s
           AND egm.id_episode = i_episode;
    
        IF l_total_sent_msg > 0
        THEN
            o_flg_type := l_flg_type_w;
        END IF;
    
        g_error := 'GET TOTAL UNNOTIFIED PATHOLOGIES';
        IF NOT pk_epis_er_law_core.get_total_unnot_path(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_episode                 => i_episode,
                                                        o_total_unnot_pathologies => o_total_unnot_pathologies,
                                                        o_error                   => o_error)
        THEN
            RAISE l_external_call;
        END IF;
    
        IF o_total_unnot_pathologies IS NULL
        THEN
            o_total_unnot_pathologies := 0;
        END IF;
    
        IF o_total_unnot_pathologies > 0
        THEN
            g_error := 'GET GES URL';
            IF NOT pk_ia_util_url.get_app_url_iav3(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_app_cfg   => g_ges_external_app,
                                                   i_episode   => i_episode,
                                                   i_patient   => pk_episode.get_epis_patient(i_lang, i_prof, i_episode),
                                                   o_url       => o_url,
                                                   o_flg_show  => l_flg_show,
                                                   o_button    => l_button,
                                                   o_msg_title => l_msg_title,
                                                   o_msg       => l_msg,
                                                   o_error     => o_error)
            THEN
                RAISE l_external_call;
            END IF;
        
            IF o_url = pk_alert_constant.g_no
               AND l_flg_show = pk_alert_constant.g_yes
            THEN
                o_flg_type := o_flg_type || l_flg_type_e;
            ELSE
                o_flg_type := o_flg_type || l_flg_type_c;
            END IF;
        END IF;
    
        IF o_flg_type IS NULL
        THEN
            o_flg_type := l_flg_type_n;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_external_call THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_GES_DISCHARGE_MSG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ges_discharge_msg;

    FUNCTION get_ges_url
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_url VARCHAR2(1000 CHAR);
    
        l_flg_show  VARCHAR2(1);
        l_button    VARCHAR2(1);
        l_msg_title sys_message.desc_message%TYPE;
        l_msg       sys_message.desc_message%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'GET GES URL';
        IF NOT pk_ia_util_url.get_app_url_iav3(i_lang      => i_lang,
                                               i_prof      => i_prof,
                                               i_app_cfg   => g_ges_external_app,
                                               i_episode   => NULL,
                                               i_patient   => i_patient,
                                               o_url       => l_url,
                                               o_flg_show  => l_flg_show,
                                               o_button    => l_button,
                                               o_msg_title => l_msg_title,
                                               o_msg       => l_msg,
                                               o_error     => l_error)
        THEN
            l_url := NULL;
        END IF;
    
        RETURN l_url;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ges_url;

    FUNCTION match_er_ges
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'UPD EPIS_ER_LAW';
    
        l_rowids := table_varchar();
        ts_epis_er_law.upd(id_episode_in => i_episode,
                           where_in      => 'id_episode = ' || i_episode_temp,
                           rows_out      => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ER_LAW',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPD EPIS_ER_LAW_HIST';
        ts_epis_er_law_hist.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        g_error := 'UPD EPIS_GES_MSG';
        ts_epis_ges_msg.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'MATCH_ER_GES',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END match_er_ges;

    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_create      epis_er_law.id_prof_create%TYPE;
        l_cancelled        VARCHAR2(1 CHAR);
        l_available_action VARCHAR2(1 CHAR);
    
        l_coll_acttions t_coll_action := t_coll_action();
    
    BEGIN
    
        g_error := 'GET ID_PROF_CREATE, FLG_STATUS AND CANCELLED';
        BEGIN
            SELECT eel.id_prof_create,
                   decode(eel.id_cancel_reason, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes)
              INTO l_prof_create, l_cancelled
              FROM epis_er_law eel
             WHERE eel.id_epis_er_law = i_id_epis_er_law;
        EXCEPTION
            WHEN no_data_found THEN
                l_prof_create := NULL;
                l_cancelled   := NULL;
        END;
    
        --options are available if emergency law is not cancelled
        --Only the professional that registered the emergency law can edit and cancel
        IF l_cancelled IS NOT NULL
           AND l_cancelled <> pk_alert_constant.g_yes
        THEN
            l_available_action := pk_alert_constant.g_active;
        ELSE
            l_available_action := pk_alert_constant.g_inactive;
        END IF;
    
        l_coll_acttions.extend;
        l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_edit,
                                                              id_parent   => NULL,
                                                              level_nr    => 1,
                                                              from_state  => NULL,
                                                              to_state    => NULL,
                                                              desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => 'EMERGENCY_LAW_T1'),
                                                              icon        => NULL,
                                                              flg_default => pk_alert_constant.g_no,
                                                              action      => 'EDIT',
                                                              flg_active  => l_available_action);
    
        l_coll_acttions.extend;
        l_coll_acttions(l_coll_acttions.last) := t_rec_action(id_action   => g_action_cancel,
                                                              id_parent   => NULL,
                                                              level_nr    => 1,
                                                              from_state  => NULL,
                                                              to_state    => NULL,
                                                              desc_action => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_code_mess => 'EMERGENCY_LAW_T2'),
                                                              icon        => NULL,
                                                              flg_default => pk_alert_constant.g_no,
                                                              action      => 'CANCEL',
                                                              flg_active  => l_available_action);
    
        g_error := 'Open o_action cursor';
        OPEN o_actions FOR
            SELECT id_action,
                   id_parent,
                   level_nr,
                   from_state,
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   flg_active,
                   action
              FROM TABLE(l_coll_acttions);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS',
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    FUNCTION get_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_er_law IN epis_er_law.id_epis_er_law%TYPE,
        o_description    OUT CLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sm_dt_activation   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROGRESS_NOTES_T129');
        l_sm_dt_inactivation sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROGRESS_NOTES_T130');
        l_sm_status          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PROGRESS_NOTES_T138');
    
        l_dt_activation   VARCHAR(4000 CHAR);
        l_dt_inactivation VARCHAR(4000 CHAR);
        l_status          sys_domain.desc_val%TYPE;
    
        l_description CLOB;
    
    BEGIN
    
        BEGIN
            SELECT l_sm_status || ': ' || t.status || chr(10) || l_sm_dt_activation || ': ' || t.dt_activation || CASE
                        WHEN t.dt_inactivation IS NOT NULL THEN
                         chr(10) || l_sm_dt_inactivation || ': ' || t.dt_inactivation
                    END
              INTO l_description
              FROM (SELECT pk_sysdomain.get_domain('EPIS_ER_LAW.FLG_ER_LAW_STATUS', eel.flg_er_law_status, i_lang) status,
                           pk_date_utils.date_char_tsz(i_lang, eel.dt_activation, i_prof.institution, i_prof.software) dt_activation,
                           pk_date_utils.date_char_tsz(i_lang, eel.dt_inactivation, i_prof.institution, i_prof.software) dt_inactivation
                      FROM epis_er_law eel
                     WHERE eel.id_epis_er_law = i_id_epis_er_law) t;
        EXCEPTION
            WHEN no_data_found THEN
                l_description := NULL;
        END;
    
        o_description := l_description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_description;

BEGIN

    g_sysdate_tstz := current_timestamp;

    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);

END pk_epis_er_law_core;
/
